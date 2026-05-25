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
 * Local RangeProc compatibility definitions used by the xWR6843AOP MSS+DSS
 * starter profile.
 */

#ifndef DPU_RANGEPROC_COMMON_H
#define DPU_RANGEPROC_COMMON_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Maximum number of range bins covered by the DC range signature compensation
 * buffer. This matches the fixed positive/negative DC bin window used by the
 * demo configuration path.
 */
#define DPU_RANGEPROC_SIGNATURE_COMP_MAX_BIN_SIZE 32U

typedef struct DPU_RangeProc_CalibDcRangeSigCfg_t
{
    /*! @brief Enable DC range signature calibration and compensation. */
    uint16_t enabled;

    /*! @brief Negative range-bin index included in compensation. */
    int16_t negativeBinIdx;

    /*! @brief Positive range-bin index included in compensation. */
    int16_t positiveBinIdx;

    /*! @brief Number of chirps used to average the DC range signature. */
    uint16_t numAvgChirps;
} DPU_RangeProc_CalibDcRangeSigCfg;

typedef struct DPU_RangeProc_stats_t
{
    /*! @brief DPU processing time in CPU cycles. */
    uint32_t processingTime;

    /*! @brief Time spent waiting for hardware completion in CPU cycles. */
    uint32_t waitTime;
} DPU_RangeProc_stats;

typedef struct rangeProc_dpParams_t
{
    uint8_t  numTxAntennas;
    uint8_t  numRxAntennas;
    uint8_t  numVirtualAntennas;
    uint16_t numChirpsPerChirpEvent;
    uint16_t numAdcSamples;
    uint16_t numRangeBins;
    uint16_t numChirpsPerFrame;
    uint16_t numDopplerChirps;
    uint16_t fftOutputDivShift;
    uint16_t numLastButterflyStagesToScale;
    uint8_t  fineMotionProcEnabled;
    uint16_t fineMotionNumFramesProc;
} rangeProc_dpParams;

#ifdef __cplusplus
}
#endif

#endif
