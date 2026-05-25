/*
 * Copyright (C) 2024 Texas Instruments Incorporated
 *
 * All rights reserved not granted herein.
 * Limited License.
 *
 * Texas Instruments Incorporated grants a world-wide, royalty-free,
 * non-exclusive license under copyrights and patents it now or hereafter
 * owns or controls to make, have made, use, import, offer to sell and sell ("Utilize")
 * this software subject to the terms herein.  With respect to the foregoing patent
 * license, such license is granted  solely to the extent that any such patent is necessary
 * to Utilize the software alone.  The patent license shall not apply to any combinations which
 * include this software, other than combinations with devices manufactured by or for TI ("TI Devices").
 * No hardware patent is licensed hereunder.
 *
 * Redistributions must preserve existing copyright notices and reproduce this license (including the
 * above copyright notice and the disclaimer and (if applicable) source code license limitations below)
 * in the documentation and/or other materials provided with the distribution
 *
 * Redistribution and use in binary form, without modification, are permitted provided that the following
 * conditions are met:
 *
 *	* No reverse engineering, decompilation, or disassembly of this software is permitted with respect to any
 *     software provided in binary form.
 *	* any redistribution and use are licensed by TI for use only with TI Devices.
 *	* Nothing shall obligate TI to provide you with source code for the software licensed and provided to you in object code.
 *
 * If software source code is provided to you, modification and redistribution of the source code are permitted
 * provided that the following conditions are met:
 *
 *   * any redistribution and use of the source code, including any resulting derivative works, are licensed by
 *     TI for use only with TI Devices.
 *   * any redistribution and use of any object code compiled from the source code and any resulting derivative
 *     works, are licensed by TI for use only with TI Devices.
 *
 * Neither the name of Texas Instruments Incorporated nor the names of its suppliers may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * DISCLAIMER.
 *
 * THIS SOFTWARE IS PROVIDED BY TI AND TI'S LICENSORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL TI AND TI'S LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**************************************************************************
 *************************** Include Files ********************************
 **************************************************************************/
#include <stdint.h>
#include <string.h>
#include <stdio.h>

/* mmWave SDK Include Files: */
#include <ti/drivers/soc/soc.h>
#include <ti/common/sys_common.h>
#include <ti/drivers/osal/DebugP.h>
#include <ti/drivers/osal/MemoryP.h>
#include <ti/utils/mathutils/mathutils.h>
#include <ti/utils/cycleprofiler/cycle_profiler.h>
#include <ti/control/dpm/dpm.h>
#include <xdc/runtime/System.h>

/* C674x mathlib */
/* Suppress the mathlib.h warnings
 *  #48-D: incompatible redefinition of macro "TRUE"
 *  #48-D: incompatible redefinition of macro "FALSE"
 */
//#pragma diag_push
//#pragma diag_suppress 48
//#include <ti/mathlib/mathlib.h>
//#pragma diag_pop

/*! This is supplied at command line when application builds this file. This file
 * is owned by the application and contains all resource partitioning, an
 * application may include more than one DPC and also use resources outside of DPCs.
 * The resource definitions used by this object detection DPC are prefixed by DPC_OBJDET_ */
#include APP_RESOURCE_FILE

#include <ti/control/mmwavelink/mmwavelink.h>

/* Obj Det instance etc */
#include <dpc/capon3d/include/objectdetectioninternal.h>
#include <dpc/capon3d/objectdetection.h>

/* 
 * 这个文件实现的是 Object Detection DPC。
 * 在 TI 的分层里：
 * - DPM 负责调度和跨域框架
 * - DPC 负责“一整条处理链”的生命周期
 * - DPU 负责链条里的具体算法单元
 *
 * 本文件关注的是 DPC 这一层：初始化、配置、启动、执行、停止，以及把结果
 * 打包回 DPM。真正的算法重活主要在 DPU_radarProcess_process 里。 */


//#define DBG_DPC_OBJDET

#ifdef DBG_DPC_OBJDET
ObjDetObj *gObjDetObj;
#endif

/**************************************************************************
 ************************** Local Definitions **********************************
 **************************************************************************/

/**
@}
*/
/*! Maximum Number of objects that can be detected in a frame */
#define DPC_OBJDET_MAX_NUM_OBJECTS DOA_OUTPUT_MAXPOINTS

/**************************************************************************
 ************************** Local Functions Prototype **************************
 **************************************************************************/

static DPM_DPCHandle DPC_ObjectDetection_init(
    DPM_Handle   dpmHandle,
    DPM_InitCfg *ptrInitCfg,
    int32_t     *errCode);

static int32_t DPC_ObjectDetection_execute(
    DPM_DPCHandle handle,
    DPM_Buffer   *ptrResult);

static int32_t DPC_ObjectDetection_ioctl(
    DPM_DPCHandle handle,
    uint32_t      cmd,
    void         *arg,
    uint32_t      argLen);

static int32_t DPC_ObjectDetection_start(DPM_DPCHandle handle);
static int32_t DPC_ObjectDetection_stop(DPM_DPCHandle handle);
static int32_t DPC_ObjectDetection_deinit(DPM_DPCHandle handle);
static void    DPC_ObjectDetection_frameStart(DPM_DPCHandle handle);
int32_t        DPC_ObjectDetection_dataInjection(DPM_DPCHandle handle, DPM_Buffer *ptrBuffer);

/**************************************************************************
 ************************** Local Functions *******************************
 **************************************************************************/

/**
 *  @b Description
 *  @n
 *      Sends Assert
 *
 *  @retval
 *      Not Applicable.
 */
void _DPC_Objdet_Assert(DPM_Handle handle, int32_t expression, const char *file, int32_t line)
{
    DPM_DPCAssert fault;

    if (!expression)
    {
        /* 把断言现场打包后回传给 DPM，再由上层 MSS 统一处理。 */
        fault.lineNum = (uint32_t)line;
        fault.arg0    = 0U;
        fault.arg1    = 0U;
        strncpy(fault.fileName, file, (DPM_MAX_FILE_NAME_LEN - 1));

        /* Report the fault to the DPM entities */
        DPM_ioctl(handle,
                  DPM_CMD_DPC_ASSERT,
                  (void *)&fault,
                  sizeof(DPM_DPCAssert));
    }
}


/**
 *  @b Description
 *  @n
 *      DPC data injection function registered with DPM. This is invoked on reception
 *      of the data injection from DPM.
 *
 *  @param[in]  handle      DPM's DPC handle
 *  @param[in]  ptrBuffer   Buffer for data injected
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Not applicable
 */
int32_t DPC_ObjectDetection_dataInjection(DPM_DPCHandle handle, DPM_Buffer *ptrBuffer)
{
    ObjDetObj *objDetObj = (ObjDetObj *)handle;

    /* Notify the DPM Module that the DPC is ready for execution */
    /* 数据注入到位后，通知 DPM 可以调度 execute 了。 */

    // DebugP_log1("ObjDet DPC: DPC_ObjectDetection_dataInjection, handle = 0x%x\n", (uint32_t)handle);
    DebugP_assert(DPM_notifyExecute(objDetObj->dpmHandle, handle, true) == 0);

    return 0;
}

/**
 *  @b Description
 *  @n
 *      Sub-frame reconfiguration, used when switching sub-frames. Invokes the
 *      DPU configuration using the configuration that was stored during the
 *      pre-start configuration so reconstruction time is saved  because this will
 *      happen in real-time.
 *  @param[in]  objDetObj Pointer to DPC object
 *  @param[in]  subFrameIndx Sub-frame index.
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 *
 * \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 */
static int32_t DPC_ObjDetDSP_reconfigSubFrame(ObjDetObj *objDetObj, uint8_t subFrameIndx)
{
    int32_t retVal = 0;
    /* 多子帧模式下切换到下一个子帧时，在这里重配各 DPU 的运行参数。
     * 当前工程里大部分逻辑被裁掉了，保留的是这个“切换钩子”。 */
    // SubFrameObj *subFrmObj;

    // subFrmObj = &objDetObj->subFrameObj[subFrameIndx];

    // retVal = DPU_CFARCAProcDSP_config(subFrmObj->dpuCFARCAObj, &subFrmObj->dpuCfg.cfarCfg);
    if (retVal != 0)
    {
        goto exit;
    }

exit:
    return (retVal);
}

/**
 *  @b Description
 *  @n
 *      Function to initialize all DPUs used in the DPC chain
 *
 *  @param[in] objDetObj        Pointer to sub-frame object
 *  @param[in] numSubFrames     Number of sub-frames
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static inline int32_t DPC_ObjDetDSP_initDPU(
    ObjDetObj *objDetObj,
    uint8_t    numSubFrames)
{
    int32_t retVal = 0;
    /* 这里本该初始化链内所有 DPU。当前 demo 里主要 DPU 在 pre-start 阶段
     * 按子帧创建，所以这里是一个轻量占位函数。 */

    return (retVal);
}

/**
 *  @b Description
 *  @n
 *      Function to de-initialize all DPUs used in the DPC chain
 *
 *  @param[in] objDetObj        Pointer to sub-frame object
 *  @param[in] numSubFrames     Number of sub-frames
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static inline int32_t DPC_ObjDetDSP_deinitDPU(
    ObjDetObj *objDetObj,
    uint8_t    numSubFrames)
{
    int32_t retVal = 0;

    /* 销毁链内算法实例前，先把 radar OSAL 管理的堆状态回收。 */
    radarOsal_memDeInit();

    return (retVal);
}

/**
 *  @b Description
 *  @n
 *     对某个子帧执行 pre-start 配置，把这条处理链里会用到的 DPU 都按该子帧参数
 *     配好。这里做的是“启动前装配”，不是实际处理一帧数据。
 *
 *  内存管理说明：
 *  1. 需要跨子帧长期保留的 Core Local Memory
 *     （例如 range DPU 的 DC 校准缓冲）会通过 MemoryP_alloc 分配。
 *  2. 只需要在单个子帧内保留、供 DPU 调用之间复用的 Core Local Memory
 *     （例如 DPIF_* 类型内存），或者仅用于某次 DPU 调用内部的 scratch 私有临时区，
 *     都从 DPC_ObjectDetection_init 时传入的 Core Local RAM 配置中分配。
 *  3. L3 内存只从 DPC_ObjectDetection_init 时传入的 L3 RAM 配置中分配。
 *     当前没有需要跨子帧长期保留的 L3 缓冲，也没有需要在 DPU process 调用内部
 *     使用的 L3 scratch 缓冲。
 *
 *  @param[in]  subFrameObj     Pointer to sub-frame object
 *  @param[in]  commonCfg       Pointer to pre-start common configuration
 *  @param[in]  preStartCfg     Pointer to pre-start configuration of the sub-frame
 *  @param[in]  edmaHandle      Pointer to array of EDMA handles for the device, this
 *                              can be distributed among the DPUs, the actual EDMA handle used
 *                              in DPC is determined by definition in application resource file
 *  @param[in]  L3ramObj        Pointer to L3 RAM memory pool object
 *  @param[in]  CoreL2RamObj    Pointer to Core Local L2 memory pool object
 *  @param[in]  CoreL1RamObj    Pointer to Core Local L1 memory pool object
 *  @param[out] L3RamUsage      Net L3 RAM memory usage in bytes as a result of allocation
 *                              by the DPUs.
 *  @param[out] CoreL2RamUsage  Net Local L2 RAM memory usage in bytes
 *  @param[out] CoreL1RamUsage  Net Core L1 RAM memory usage in bytes
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 */
static int32_t DPC_ObjDetDSP_preStartConfig(
    SubFrameObj                     *subFrameObj,
    DPC_ObjectDetection_PreStartCfg *preStartCfg)
{
    int32_t                     retVal = 0;
    DPC_ObjectDetection_DynCfg *dynCfg;
    DPIF_RadarCube              radarCube;
    DPU_ProcessErrorCodes       procErrorCode;

    dynCfg = &preStartCfg->dynCfg;
    /* 先取出这次 pre-start 附带的动态配置。
     * 这份 dynCfg 是上层已经按当前子帧准备好的算法参数集合。 */
    /* pre-start 是每个子帧的“真正配置入口”。
     * 这里会把上层下发的动态参数固化下来，准备 radarCube 和 radarProcess DPU。 */

    /* Save configs to object. We need to pass this stored config (instead of
       the input arguments to this function which will be in stack) to
       the DPU config functions inside of this function b·ecause the DPUs
       have pointers to dynamic configurations which are later going to be
       reused during re-configuration (intra sub-frame or inter sub-frame)
     */
    /* 把 dynCfg 拷贝进 subFrameObj，而不是直接引用函数入参。
     * 原因是 preStartCfg 在函数返回后会失效，但后面的 DPU 仍需要长期引用这些配置，
     * 尤其是在子帧内重配或跨子帧切换时。 */
    subFrameObj->dynCfg = *dynCfg;

    /* L3 allocations */
    /* L3 - radar cube */
    /* 先根据 range bin 数、chirp 数、天线数估算 radarCube 所需总字节数。 */
    radarCube.dataSize = dynCfg->caponChainCfg.numRangeBins * dynCfg->caponChainCfg.numChirpPerFrame *
        dynCfg->caponChainCfg.numAntenna * sizeof(cplx16_t);
    if (dynCfg->caponChainCfg.doaConfig.fineMotionProcCfg.fineMotionProcEnabled)
    {
        /* fine motion 模式下会额外保留一份时序信息，因此 radarCube 翻倍。 */
        radarCube.dataSize = 2 * radarCube.dataSize;
    }
    DebugP_log1("ObjDet DPC: DPC_ObjDetDSP_preStartConfig, radarCubeFormat = %d\n", dynCfg->radarCubeFormat);
    if (preStartCfg->shareMemCfg.shareMemEnable == true)
    {
        /* 这个 DPC 不自己申请 radarCube，而是要求上游 rangeHWA 链通过共享内存交进来。 */
        if ((preStartCfg->shareMemCfg.radarCubeMem.addr != NULL) &&
            (preStartCfg->shareMemCfg.radarCubeMem.size == radarCube.dataSize))
        {
            /* Use assigned radar cube address */
            /* 如果共享内存地址和大小都合法，就直接复用上游已经分配好的 radarCube。 */
            radarCube.data = preStartCfg->shareMemCfg.radarCubeMem.addr;
        }
        else
        {
            /* 共享内存配置不匹配，说明上游提供的 radarCube 条件不满足，配置失败。 */
            retVal = DPC_OBJECTDETECTION_EINVAL__COMMAND;
            goto exit;
        }
#ifdef RADARDEMO_AOARADARCUDE_RNGCHIRPANT
        if (subFrameObj->dynCfg.radarCubeFormat != DPIF_RADARCUBE_FORMAT_2)
        {
            /* 如果编译路径要求特定 radarCube 格式，这里做格式保护检查。 */
            retVal = DPC_OBJECTDETECTION_EINVAL_CUBE;
            goto exit;
        }
#endif
    }
    else
    {
        /* 这个 DPC 当前依赖共享 radarCube；如果没开共享内存，直接报错退出。 */
        retVal = DPC_OBJECTDETECTION_EINVAL_CUBE;
        goto exit;
    }

    /* Only supported radar Cube format in this DPC */
    /* 本 DPC 内部只支持这种 radarCube 数据格式。 */
    radarCube.datafmt   = DPIF_RADARCUBE_FORMAT_3;
    /* 后面的 radarProcess DPU 就从这个 dataIn 指针读取 radarCube。 */
    subFrameObj->dataIn = radarCube.data;

    /* 真正的 DSP 算法入口对象在这里创建。 */
    /* 这里把 caponChainCfg 传给 DPU_radarProcess_init，生成当前子帧专属的
     * radarProcess 句柄。后续 execute 就会拿这个句柄去实际处理数据。 */
    subFrameObj->dpuCaponObj = DPU_radarProcess_init(&subFrameObj->dynCfg.caponChainCfg, &procErrorCode);
    if (procErrorCode > PROCESS_OK)
    {
        /* DPU 初始化失败，说明 DSP 算法链对象没建起来，整个 pre-start 配置失败。 */
        retVal = DPC_OBJECTDETECTION_EINTERNAL;
        DebugP_log1("DPC config error %d\n", procErrorCode);
        goto exit;
    }

    // printf("DPC configuration done!\n");
    DebugP_log0("DPC config done\n");
    /* Report RAM usage */
    /* 打印堆统计，便于确认 L1/L2/L3 内存分配是否合理。 */
    radarOsal_printHeapStats();

exit:
    /* retVal == 0 表示当前子帧的 pre-start 配置成功，可以进入后续 start/execute。 */
    return retVal;
}

/**
 *  @b Description
 *  @n
 *      DPC frame start function registered with DPM. This is invoked on reception
 *      of the frame start ISR from the RF front-end. This API is also invoked
 *      when application issues @ref DPC_OBJDET_IOCTL__TRIGGER_FRAME to simulate
 *      a frame trigger (e.g for unit testing purpose).
 *
 *  @param[in]  handle DPM's DPC handle
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Not applicable
 */
static void DPC_ObjectDetection_frameStart(DPM_DPCHandle handle)
{
    ObjDetObj *objDetObj = (ObjDetObj *)handle;

    /* 记录帧起始时间，后续用来统计整帧处理时延。 */
    objDetObj->stats->frameStartTimeStamp = Cycleprofiler_getTimeStamp();

    // DebugP_log2("ObjDet DPC: Frame Start, frameIndx = %d, subFrameIndx = %d\n",
    //             objDetObj->stats.frameStartIntCounter, objDetObj->subFrameIndx);

    /* Check if previous frame (sub-frame) processing has completed */
    /* 如果上一个子帧还没处理完就来了新帧，这里会触发断言。 */
    DPC_Objdet_Assert(objDetObj->dpmHandle, (objDetObj->interSubFrameProcToken == 0));
    objDetObj->interSubFrameProcToken++;

    /* Increment interrupt counter for debugging purpose */
    if (objDetObj->subFrameIndx == 0)
    {
        objDetObj->stats->frameStartIntCounter++;
    }

    return;
}

/**
 *  @b Description
 *  @n
 *      DPC's (DPM registered) start function which is invoked by the
 *      application using DPM_start API.
 *
 *  @param[in]  handle  DPM's DPC handle
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static int32_t DPC_ObjectDetection_start(DPM_DPCHandle handle)
{
    ObjDetObj *objDetObj;
    int32_t    retVal = 0;

    objDetObj = (ObjDetObj *)handle;
    DebugP_assert(objDetObj != NULL);

    /* start 代表前面攒下来的 pre-start 配置已经正式生效。 */
    objDetObj->stats->frameStartIntCounter = 0;

    /* Start marks consumption of all pre-start configs, reset the flag to check
     * if pre-starts were issued only after common config was issued for the next
     * time full configuration happens between stop and start */
    objDetObj->isCommonCfgReceived = false;

    /* App must issue export of last frame after stop which will switch to sub-frame 0,
     * so start should always see sub-frame indx of 0, check */
    DebugP_assert(objDetObj->subFrameIndx == 0);

    if (objDetObj->numSubframes > 1U)
    {
        /* Pre-start cfgs for sub-frames may have come in any order, so need
         * to ensure we reconfig for the current (0) sub-frame before starting */
        /* 多子帧下，真正启动前先确保当前子帧 0 的配置已经切到位。 */
        DPC_ObjDetDSP_reconfigSubFrame(objDetObj, objDetObj->subFrameIndx);
    }
    DebugP_log0("ObjDet DPC: Start done\n");
    return (retVal);
}

/**
 *  @b Description
 *  @n
 *      DPC's (DPM registered) stop function which is invoked by the
 *      application using DPM_stop API.
 *
 *  @param[in]  handle  DPM's DPC handle
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static int32_t DPC_ObjectDetection_stop(DPM_DPCHandle handle)
{
    ObjDetObj *objDetObj;

    objDetObj = (ObjDetObj *)handle;
    DebugP_assert(objDetObj != NULL);

    /* We can be here only after complete frame processing is done, which means
     * processing token must be 0 and subFrameIndx also 0  */
    /* 停机点要求处理链完全空闲，不允许半帧状态下强停。 */
    DebugP_assert((objDetObj->interSubFrameProcToken == 0) && (objDetObj->subFrameIndx == 0));

    DebugP_log0("ObjDet DPC: Stop done\n");
    return (0);
}

/**
 *  @b Description
 *  @n
 *      DPC's (DPM registered) execute function which is invoked by the application
 *      in the DPM's execute context when the DPC issues DPM_notifyExecute API from
 *      its registered @ref DPC_ObjectDetection_frameStart API that is invoked every
 *      frame interrupt.
 *
 *  @param[in]  handle       DPM's DPC handle
 *  @param[out]  ptrResult   Pointer to the result
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
int32_t DPC_ObjectDetection_execute(
    DPM_DPCHandle handle,
    DPM_Buffer   *ptrResult)
{
    ObjDetObj                              *objDetObj;
    SubFrameObj                            *subFrmObj;
    DPC_ObjectDetection_ProcessCallBackCfg *processCallBack;
    int32_t                                 procErrorCode;


    radarProcessOutput *result;
    int32_t             retVal = 0;
    volatile uint32_t   startTime;
    int32_t             i;

    objDetObj = (ObjDetObj *)handle;
    DebugP_assert(objDetObj != NULL);
    DebugP_assert(ptrResult != NULL);

    /* execute 是这条 DPC 的核心，一次调用对应一次子帧处理。 */
    DebugP_log1("ObjDet DPC: Processing sub-frame %d\n", objDetObj->subFrameIndx);

    processCallBack = &objDetObj->processCallBackCfg;

    objDetObj->executeResult->subFrameIdx = objDetObj->subFrameIndx;
    result                                = &objDetObj->executeResult->objOut;

    /* 找到当前子帧的运行上下文，包括 radarCube 输入和 DPU 句柄。 */
    subFrmObj = &objDetObj->subFrameObj[objDetObj->subFrameIndx];

    if (processCallBack->processInterFrameBeginCallBackFxn != NULL)
    {
        /* 把“即将开始帧间处理”的事件回调给上层，用于统计和配套动作。 */
        (*processCallBack->processInterFrameBeginCallBackFxn)(objDetObj->subFrameIndx);
    }

    // DebugP_log0("ObjDet DPC: Range Proc Output Ready\n");

    startTime = Cycleprofiler_getTimeStamp();
    /* 真正的算法主干就在这一句。
     * 输入是 radarCube，输出是点云/目标检测结果和 benchmark 信息。 */
    DPU_radarProcess_process(subFrmObj->dpuCaponObj, subFrmObj->dataIn, result, &procErrorCode);
    if (procErrorCode > PROCESS_OK)
    {
        retVal = -1;
        goto exit;
    }

    DebugP_log0("ObjDet DPC: Frame Proc Done\n");

    objDetObj->stats->interFrameEndTimeStamp = Cycleprofiler_getTimeStamp();
    /* benchmarkOut 来自下层 DPU，用于拆分各阶段耗时。 */
    memcpy(&(objDetObj->stats->subFrbenchmarkDetails), result->benchmarkOut, sizeof(radarProcessBenchmarkElem));
    objDetObj->stats->interFrameExecTimeInUsec  = (uint32_t)((float)(objDetObj->stats->interFrameEndTimeStamp - objDetObj->stats->frameStartTimeStamp) * _rcpsp((float)DSP_CLOCK_MHZ));
    objDetObj->stats->activeFrameProcTimeInUsec = (uint32_t)((float)(objDetObj->stats->interFrameEndTimeStamp - startTime) * _rcpsp((float)DSP_CLOCK_MHZ));


    /* populate DPM_resultBuf - first pointer and size are for results of the processing */
    /* 把结果和统计信息挂到 DPM_Buffer 里，交回上层 MSS。 */
    ptrResult->ptrBuffer[0] = (uint8_t *)objDetObj->executeResult;
    ptrResult->size[0]      = sizeof(DPC_ObjectDetection_ExecuteResult);

    ptrResult->ptrBuffer[1] = (uint8_t *)objDetObj->stats;
    ptrResult->size[1]      = sizeof(DPC_ObjectDetection_Stats);


    /* clear rest of the result */
    for (i = 2; i < DPM_MAX_BUFFER; i++)
    {
        ptrResult->ptrBuffer[i] = NULL;
        ptrResult->size[i]      = 0;
    }

exit:

    return retVal;
}


/**
 *  @b Description
 *  @n
 *      DPC IOCTL commands configuration API which will be invoked by the
 *      application using DPM_ioctl API
 *
 *  @param[in]  handle   DPM's DPC handle
 *  @param[in]  cmd      Capture DPC specific commands
 *  @param[in]  arg      Command specific arguments
 *  @param[in]  argLen   Length of the arguments which is also command specific
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static int32_t DPC_ObjectDetection_ioctl(
    DPM_DPCHandle handle,
    uint32_t      cmd,
    void         *arg,
    uint32_t      argLen)
{
    ObjDetObj   *objDetObj;
    SubFrameObj *subFrmObj;
    int32_t      retVal = 0;

    /* Get the DSS MCB: */
    objDetObj = (ObjDetObj *)handle;
    DebugP_assert(objDetObj != NULL);


    /* Process the commands. Process non sub-frame specific ones first
     * so the sub-frame specific ones can share some code. */
    /* 这里处理的是“链外对 DPC 的控制命令”，不是算法执行本身。 */
    if ((cmd < DPC_OBJDET_IOCTL__STATIC_PRE_START_CFG) || (cmd > DPC_OBJDET_IOCTL__MAX))
    {
        retVal = DPM_EINVCMD;
    }
    else if (cmd == DPC_OBJDET_IOCTL__TRIGGER_FRAME)
    {
        /* 手工触发一帧，通常用于测试路径。 */
        DPC_ObjectDetection_frameStart(handle);
    }
    else if (cmd == DPC_OBJDET_IOCTL__STATIC_PRE_START_COMMON_CFG)
    {
        /* 先记录“共有多少个子帧”，后面的 per-subframe pre-start 才有意义。 */
        objDetObj->numSubframes        = *(uint8_t *)arg;
        objDetObj->isCommonCfgReceived = true;
        // DebugP_log1("ObjDet DPC: Pre-start Config IOCTL processed common config (numSubframes = %d)\n", objDetObj->numSubframes);
    }
    else if (cmd == DPC_OBJDET_IOCTL__DYNAMIC_EXECUTE_RESULT_EXPORTED)
    {
        DPC_ObjectDetection_ExecuteResultExportedInfo *inp;

        DebugP_assert(argLen == sizeof(DPC_ObjectDetection_ExecuteResultExportedInfo));

        inp = (DPC_ObjectDetection_ExecuteResultExportedInfo *)arg;

        /* input sub-frame index must match current sub-frame index */
        /* MSS 确认本帧结果已经消费完毕后，DPC 才允许进入下一子帧。 */
        DebugP_assert(inp->subFrameIdx == objDetObj->subFrameIndx);

        /* Reconfigure all DPUs resources for next sub-frame as EDMA and scrach buffer
         * resources overlap across sub-frames */
        if (objDetObj->numSubframes > 1)
        {
            /* Next sub-frame */
            objDetObj->subFrameIndx++;
            if (objDetObj->subFrameIndx == objDetObj->numSubframes)
            {
                objDetObj->subFrameIndx = 0;
            }

            /* 切到下一子帧前重配共享资源。 */
            DPC_ObjDetDSP_reconfigSubFrame(objDetObj, objDetObj->subFrameIndx);
        }
        DebugP_log0("ObjDet DPC: received ack from MSS for output data\n");

        /* mark end of processing of the frame/sub-frame by the DPC and the app */
        /* token 归零表示本帧处理链和上层消费都结束了。 */
        objDetObj->interSubFrameProcToken--;
    }
    else
    {
        uint8_t subFrameNum;

        /* First argument is sub-frame number */
        DebugP_assert(arg != NULL);
        subFrameNum = *(uint8_t *)arg;
        subFrmObj   = &objDetObj->subFrameObj[subFrameNum];

        switch (cmd)
        {
            /* Related to pre-start configuration */
            case DPC_OBJDET_IOCTL__STATIC_PRE_START_CFG:
            {
                DPC_ObjectDetection_PreStartCfg *cfg;

                /* Pre-start common config must be received before pre-start configs
                 * are received. */
                if (objDetObj->isCommonCfgReceived == false)
                {
                    // DebugP_log0("ObjDet DPC IOCTL: false isCommonCfgReceived\n");
                    retVal = DPC_OBJECTDETECTION_PRE_START_CONFIG_BEFORE_PRE_START_COMMON_CONFIG;
                    goto exit;
                }

                DebugP_assert(argLen == sizeof(DPC_ObjectDetection_PreStartCfg));

                cfg = (DPC_ObjectDetection_PreStartCfg *)arg;

                // DebugP_log4("ObjDet DPC IOCTL: function called with cfg = 0x%x, subFrmObj = 0x%x, cmd = %d, subFrameNum = %d\n", (uint32_t )arg, (uint32_t )subFrmObj, cmd, *(uint8_t *)arg);
                /* 真正把某个子帧的 radarCube / caponChain / shareMem 配进 DPC。 */
                retVal = DPC_ObjDetDSP_preStartConfig(subFrmObj,
                                                      cfg);
                if (retVal != 0)
                {
                    goto exit;
                }


                DebugP_log1("ObjDet DPC: Pre-start Config IOCTL processed (subFrameIndx = %d)\n", subFrameNum);
                break;
            }

            default:
            {
                /* Error: This is an unsupported command */
                retVal = DPM_EINVCMD;
                break;
            }
        }
    }

exit:
    return retVal;
}

/**
 *  @b Description
 *  @n
 *      DPC's (DPM registered) initialization function which is invoked by the
 *      application using DPM_init API. Among other things, this API allocates DPC instance
 *      and DPU instances (by calling DPU's init APIs) from the MemoryP osal
 *      heap. If this API returns an error of any type, the heap is not guaranteed
 *      to be in the same state as before calling the API (i.e any allocations
 *      from the heap while executing the API are not guaranteed to be deallocated
 *      in case of error), so any error from this API should be considered fatal and
 *      if the error is of _ENOMEM type, the application will
 *      have to be built again with a bigger heap size to address the problem.
 *
 *  @param[in]  dpmHandle   DPM's DPC handle
 *  @param[in]  ptrInitCfg  Handle to the framework semaphore
 *  @param[out] errCode     Error code populated on error
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static DPM_DPCHandle DPC_ObjectDetection_init(
    DPM_Handle   dpmHandle,
    DPM_InitCfg *ptrInitCfg,
    int32_t     *errCode)
{
    ObjDetObj                      *objDetObj = NULL;
    DPC_ObjectDetection_InitParams *dpcInitParams;
    radarOsal_heapConfig            heapconfig[3];

    *errCode = 0;
    /* init 阶段创建 ObjDetObj，并把 DPM 侧传来的内存池和回调保存下来。 */

    // DebugP_log0("DPC: DPC_ObjectDetection_init\n");
    if ((ptrInitCfg == NULL) || (ptrInitCfg->arg == NULL))
    {
        *errCode = DPC_OBJECTDETECTION_EINVAL;
        goto exit;
    }

    if (ptrInitCfg->argSize != sizeof(DPC_ObjectDetection_InitParams))
    {
        *errCode = DPC_OBJECTDETECTION_EINVAL__INIT_CFG_ARGSIZE;
        goto exit;
    }

    dpcInitParams = (DPC_ObjectDetection_InitParams *)ptrInitCfg->arg;

    /*Set up heap and mem osal*/
    {
        /* 把 L3 / LL2 / LL1 三类内存池注册给 radar OSAL，后面 DPU 会按类型分配。 */
        memset(heapconfig, 0, sizeof(heapconfig));
        heapconfig[RADARMEMOSAL_HEAPTYPE_DDR_CACHED].heapType    = RADARMEMOSAL_HEAPTYPE_DDR_CACHED;
        heapconfig[RADARMEMOSAL_HEAPTYPE_DDR_CACHED].heapAddr    = (int8_t *)dpcInitParams->L3HeapCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_DDR_CACHED].heapSize    = dpcInitParams->L3HeapCfg.size;
        heapconfig[RADARMEMOSAL_HEAPTYPE_DDR_CACHED].scratchAddr = (int8_t *)dpcInitParams->L3ScratchCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_DDR_CACHED].scratchSize = dpcInitParams->L3ScratchCfg.size;

        heapconfig[RADARMEMOSAL_HEAPTYPE_LL2].heapType    = RADARMEMOSAL_HEAPTYPE_LL2;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL2].heapAddr    = (int8_t *)dpcInitParams->CoreL2HeapCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL2].heapSize    = dpcInitParams->CoreL2HeapCfg.size;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL2].scratchAddr = (int8_t *)dpcInitParams->CoreL2ScratchCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL2].scratchSize = dpcInitParams->CoreL2ScratchCfg.size;

        heapconfig[RADARMEMOSAL_HEAPTYPE_LL1].heapType    = RADARMEMOSAL_HEAPTYPE_LL1;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL1].heapAddr    = (int8_t *)dpcInitParams->CoreL1HeapCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL1].heapSize    = dpcInitParams->CoreL1HeapCfg.size;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL1].scratchAddr = (int8_t *)dpcInitParams->CoreL1ScratchCfg.addr;
        heapconfig[RADARMEMOSAL_HEAPTYPE_LL1].scratchSize = dpcInitParams->CoreL1ScratchCfg.size;
        if (radarOsal_memInit(&heapconfig[0], 3) == RADARMEMOSAL_FAIL)
        {
            *errCode = DPC_OBJECTDETECTION_MEMINITERR;
            goto exit;
        }
    }


    objDetObj = MemoryP_ctrlAlloc(sizeof(ObjDetObj), 0);

#ifdef DBG_DPC_OBJDET
    gObjDetObj = objDetObj;
#endif

    System_printf("ObjDet DPC: objDetObj address = (ObjDetObj     *) 0x%x\n", (uint32_t)objDetObj);

    if (objDetObj == NULL)
    {
        *errCode = DPC_OBJECTDETECTION_ENOMEM;
        goto exit;
    }

    /* Initialize memory */
    memset((void *)objDetObj, 0, sizeof(ObjDetObj));

    /* Copy over the DPM configuration: */
    /* 保存一份 DPM 初始化描述，便于后续查询本链上下文。 */
    memcpy((void *)&objDetObj->dpmInitCfg, (void *)ptrInitCfg, sizeof(DPM_InitCfg));

    objDetObj->dpmHandle = dpmHandle;
    objDetObj->socHandle = ptrInitCfg->socHandle;

    objDetObj->processCallBackCfg = dpcInitParams->processCallBackCfg;

    /* 执行结果和统计信息放在 DDR 缓存区，便于和 MSS 共享。 */
    objDetObj->executeResult = (DPC_ObjectDetection_ExecuteResult *)radarOsal_memAlloc(RADARMEMOSAL_HEAPTYPE_DDR_CACHED, 0, sizeof(DPC_ObjectDetection_ExecuteResult), 1);
    objDetObj->stats         = (DPC_ObjectDetection_Stats *)radarOsal_memAlloc(RADARMEMOSAL_HEAPTYPE_DDR_CACHED, 0, sizeof(DPC_ObjectDetection_Stats), 1);

    *errCode = DPC_ObjDetDSP_initDPU(objDetObj, RL_MAX_SUBFRAMES);
    // printf ("DPC init done!\n");

exit:
    if (*errCode != 0)
    {
        if (objDetObj != NULL)
        {
            MemoryP_ctrlFree(objDetObj, sizeof(ObjDetObj));
            objDetObj = NULL;
        }
    }

    return ((DPM_DPCHandle)objDetObj);
}

/**
 *  @b Description
 *  @n
 *      DPC's (DPM registered) de-initialization function which is invoked by the
 *      application using DPM_deinit API.
 *
 *  @param[in]  handle  DPM's DPC handle
 *
 *  \ingroup DPC_OBJDET__INTERNAL_FUNCTION
 *
 *  @retval
 *      Success -   0
 *  @retval
 *      Error   -   <0
 */
static int32_t DPC_ObjectDetection_deinit(DPM_DPCHandle handle)
{
    ObjDetObj *objDetObj = (ObjDetObj *)handle;
    int32_t    retVal    = 0;

    if (handle == NULL)
    {
        retVal = DPC_OBJECTDETECTION_EINVAL;
        goto exit;
    }

    /* 先收尾链内 DPU / heap，再释放 ObjDetObj 控制块。 */
    retVal = DPC_ObjDetDSP_deinitDPU(objDetObj, RL_MAX_SUBFRAMES);

    MemoryP_ctrlFree(handle, sizeof(ObjDetObj));

exit:
    return (retVal);
}

/**************************************************************************
 ************************* Global Declarations ****************************
 **************************************************************************/

/** @addtogroup DPC_OBJDET__GLOBAL
 @{ */

/**
 * @brief   Global used to register Object Detection DPC in DPM
 */
DPM_ProcChainCfg gDPC_ObjectDetectionCfg = {
    DPC_ObjectDetection_init, /* DPC 初始化入口 */
    DPC_ObjectDetection_start, /* DPC 启动入口 */
    DPC_ObjectDetection_execute, /* 每帧/子帧执行入口 */
    DPC_ObjectDetection_ioctl, /* 配置命令入口 */
    DPC_ObjectDetection_stop, /* DPC 停止入口 */
    DPC_ObjectDetection_deinit, /* DPC 反初始化入口 */
    DPC_ObjectDetection_dataInjection, /* 数据注入通知入口 */
    NULL, /* 本链未使用 chirp available 回调 */
    DPC_ObjectDetection_frameStart /* 帧开始通知入口 */
};

/* @} */
