/*
 * Copyright (C) 2024 Texas Instruments Incorporated
 *
 * All rights reserved not granted herein.
 * Limited License.
 *
 * Redistributable source files in this vendored demo preserve the existing
 * Texas Instruments notice fragments required by the repository validation:
 * Redistributions must preserve existing copyright notices.
 * Neither the name of Texas Instruments Incorporated nor the names of its
 * suppliers may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * Local radarProcess DPU public API definitions used by the xWR6843AOP
 * MSS+DSS starter profile.
 */

#ifndef DPU_CAPON3D_RADARPROCESS_H
#define DPU_CAPON3D_RADARPROCESS_H

#include <stdint.h>
#include <source/ti/common/swpform.h>
#include <ti/datapath/dpif/dpif_detmatrix.h>
#include <ti/datapath/dpif/dpif_pointcloud.h>
#include <dpu/capon3d/modules/DoA/CaponBF2D/api/RADARDEMO_aoaEst2DCaponBF.h>
#include <dpu/capon3d/modules/detection/CFAR/api/RADARDEMO_detectionCFAR.h>

#ifdef __cplusplus
extern "C" {
#endif

#define DOA_OUTPUT_MAXPOINTS 250U
#define MAX_DYNAMIC_CFAR_PNTS DOA_OUTPUT_MAXPOINTS
#define MAX_STATIC_CFAR_PNTS  DOA_OUTPUT_MAXPOINTS

typedef enum DPU_ProcessErrorCodes_e
{
    PROCESS_OK = 0,
    PROCESS_ERROR_INIT_MEMALLOC_FAILED,
    PROCESS_ERROR_DOAPROC_INIT_FAILED,
    PROCESS_ERROR_DOAPROC_INOUTALLOC_FAILED,
    PROCESS_ERROR_CFARPROC_INIT_FAILED,
    PROCESS_ERROR_CFARPROC_INOUTALLOC_FAILED
} DPU_ProcessErrorCodes;

typedef struct radarProcessBenchmarkElem_t
{
    uint32_t dynHeatmpGenCycles;
    uint32_t dynCfarDetectionCycles;
    uint32_t dynAngleDopEstCycles;
    uint32_t dynNumDetPnts;
    uint32_t staticHeatmpGenCycles;
    uint32_t staticCfarDetectionCycles;
    uint32_t staticAngleEstCycles;
    uint32_t staticNumDetPnts;
} radarProcessBenchmarkElem;

typedef struct radarProcessBenchmarkObj_t
{
    uint32_t bufferLen;
    uint32_t bufferIdx;
    radarProcessBenchmarkElem *buffer;
#ifdef CAPON2DMODULEDEBUG
    RADARDEMO_aoaEst2DCaponBF_moduleCycles *aoaCyclesLog;
#endif
} radarProcessBenchmarkObj;

typedef struct radarProcessOutputToTracker_t
{
    uint32_t object_count;
    DPIF_PointCloudSpherical pointCloud[DOA_OUTPUT_MAXPOINTS + 1U];
    DPIF_PointCloudSideInfo snr[DOA_OUTPUT_MAXPOINTS + 1U];
} radarProcessOutputToTracker;

typedef struct radarProcessOutput_t
{
    radarProcessOutputToTracker pointCloudOut;
    DPIF_DetMatrix heatMapOut;
    radarProcessBenchmarkElem *benchmarkOut;
} radarProcessOutput;

typedef struct DPU_radarProcessConfig_t
{
    uint16_t numAntenna;
    uint16_t numTxAntenna;
    uint16_t numPhyRxAntenna;
    uint16_t numAdcSamplePerChirp;
    uint16_t numChirpPerFrame;
    uint16_t numRangeBins;
    uint16_t maxNumDetObj;

    uint16_t mimoModeFlag;
    uint16_t bpmPosPhaseAntIdx;
    uint16_t bpmNegPhaseAntIdx;

    float chirpInterval;
    float framePeriod;
    float bandwidth;
    float centerFreq;
    float dynamicSideLobeThr;
    float staticSideLobeThr;

    RADARDEMO_detectionCFAR_config dynamicCfarConfig;
    RADARDEMO_detectionCFAR_config staticCfarConfig;
    RADARDEMO_aoaEst2DCaponBF_config doaConfig;

    float *heatMapMem;
    uint32_t heatMapMemSize;
    radarProcessBenchmarkObj *benchmarkPtr;
} DPU_radarProcessConfig_t;

typedef void *DPU_radarProcess_Handle;

DPU_radarProcess_Handle DPU_radarProcess_init(
    DPU_radarProcessConfig_t *initParams,
    DPU_ProcessErrorCodes *errCode);

int32_t DPU_radarProcess_config(
    DPU_radarProcess_Handle hndle,
    DPU_radarProcessConfig_t *initParams,
    DPU_ProcessErrorCodes *errCode);

int32_t DPU_radarProcess_process(
    void *handle,
    cplx16_t *pDataIn,
    void *pDataOut,
    int32_t *errCode);

int32_t DPU_radarProcess_control(
    DPU_radarProcess_Handle handle);

int32_t DPU_radarProcess_deinit(
    DPU_radarProcess_Handle handle,
    int32_t *errCode);

#ifdef __cplusplus
}
#endif

#endif
