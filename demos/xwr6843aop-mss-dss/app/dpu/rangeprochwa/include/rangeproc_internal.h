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
 * Local RangeProc internal compatibility definitions used by the xWR6843AOP
 * MSS+DSS starter profile.
 */

#ifndef DPU_RANGEPROC_INTERNAL_H
#define DPU_RANGEPROC_INTERNAL_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum rangeProcRadarCubeLayoutFmt_e
{
    rangeProc_dataLayout_RANGE_DOPPLER_TxAnt_RxAnt = 0,
    rangeProc_dataLayout_TxAnt_DOPPLER_RxAnt_RANGE = 1
} rangeProcRadarCubeLayoutFmt;

#ifdef __cplusplus
}
#endif

#endif
