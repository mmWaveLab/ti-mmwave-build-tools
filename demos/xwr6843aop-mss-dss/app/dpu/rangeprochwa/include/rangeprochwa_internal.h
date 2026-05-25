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

/**
 *   @file  rangeprochwa_internal.h
 *
 *   @brief
 *      rangeProcHWA internal definitions.
 */

/**************************************************************************
 *************************** Include Files ********************************
 **************************************************************************/
#ifndef DPU_RANGEPROCHWA_INTERNAL_H
#define DPU_RANGEPROCHWA_INTERNAL_H

/* Standard Include Files. */
#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#include <ti/utils/cycleprofiler/cycle_profiler.h>
#include <dpu/rangeprochwa/rangeproc_common.h>
#include <dpu/rangeprochwa/include/rangeproc_internal.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief
     *  RangeProcHWA DPU Object
     *
     * @details
     *  The structure is used to hold RangeProcHWA internal data object
     *
     *  \ingroup DPU_RANGEPROC_INTERNAL_DATA_STRUCTURE
     */
    typedef struct rangeProcHWAObj_t
    {
        DPU_RangeProcHWA_InitParams initParms;

        /*! @brief     Data path common parameters used in rangeProc */
        rangeProc_dpParams params;

        /*! @brief      EDMA Handle */
        EDMA_Handle edmaHandle;

        /*! @brief     RangeProc HWA configuration */
        DPU_RangeProcHWA_HwaConfig hwaCfg;

        /*! @brief     RangeProc HWA data input paramset trigger */
        uint8_t dataInTrigger[2];

        /*! @brief     RangeProc HWA data output paramset trigger */
        uint8_t dataOutTrigger[2];

        /*! @brief     EDMA done semaphore */
        SemaphoreP_Handle edmaDoneSemaHandle;

        /*! @brief     HWA Processing Done semaphore Handle */
        SemaphoreP_Handle hwaDoneSemaHandle;

        /*! @brief      Data in interleave or non-interleave mode */
        DPIF_RXCHAN_INTERLEAVE interleave;

        /*! @brief      DC range signature calibration counter */
        uint32_t dcRangeSigCalibCntr;

        /*! @brief     Calibrate DC (zero) range signature Configuration */
        DPU_RangeProc_CalibDcRangeSigCfg calibDcRangeSigCfg;

        /*! @brief     Rada Cube layout */
        rangeProcRadarCubeLayoutFmt radarCubeLayout;

        /*! @brief     ADC data buffer RX channel offset - fixed for all channels */
        uint16_t rxChanOffset;

        /*! @brief      Pointer to ADC buffer */
        cmplx16ImRe_t *ADCdataBuf;

        /*! @brief      Pointer to Radar Cube buffer */
        cmplx16ImRe_t *radarCubebuf;

        /*! @brief      Pointer to DC range signal mean buffer */
        cmplx32ImRe_t *dcRangeSigMean;

        /*! @brief     DC range calibration scratch buffer size */
        uint32_t dcRangeSigMeanSize;

        /*! @brief      HWA Memory address */
        uint32_t hwaMemBankAddr[4];

        /*! @brief     DMA channel trigger after HWA processing is done */
        uint8_t calibDcNumLog2AvgChirps;

        /*! @brief     DMA data out Signature channel */
        uint8_t dataOutSignatureChan;

        /*! @brief     rangeProc DPU is in processing state */
        bool inProgress;

        /*! @brief     Total number of rangeProc DPU processing */
        uint32_t numProcess;

        /*! @brief     Total number of data output EDMA done interrupt */
        uint32_t numEdmaDataOutCnt;
    } rangeProcHWAObj;

#ifdef __cplusplus
}
#endif

#endif
