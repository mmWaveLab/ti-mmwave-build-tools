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

#ifndef _RADARPROCESS_INTERNAL_H
#define _RADARPROCESS_INTERNAL_H


#include <source/ti/common/swpform.h>
#include <dpu/capon3d/radarProcess.h>
#include <dpu/capon3d/include/copyTranspose.h>

#if defined(_WIN32) || defined(CCS)
#include <stdio.h>
#endif


/**
 *  \def  _processInstance_
 *
 *  \brief   DPU instance structure definition.
 *
 *  \sa
 */

typedef struct _processInstance_
{
    float framePeriod; /**<Frame period*/
    void *dynamicCFARInstance; /**<dynamic CFAR handle*/
    void *staticCFARInstance; /**<static CFAR handle*/
    void *aoaInstance; /**<2D capon handle*/

    float *localHeatmap; /**<pointer to heatmap memory*/

    float **dynamicHeatmapPtr; /**<2D pointer to heatmap memory for dynamic scene, in [angle][range] format as CFAR input*/
    float **staticHeatmapPtr; /**<2D pointer to heatmap memory for static scene, in [angle][range] format as CFAR input*/
    float  *perRangeBinMax; /**<per range bin max value from heatmap, for CFAR input*/

    int8_t staticProcEnabled; /**<static processing enabled, if set to 1*/

    uint32_t frameCounter; /**<the counter which tracks the number of frames processed*/

    uint8_t  fineMotionProcEnabled; /**<fine motion detection processing enabled, if set to 1*/
    uint16_t fineMotionNumFramesProc; /**<number of frames to be processed in fine motion detection mode*/
    uint16_t fineMotionProcCycle; /**<frame cycle of the fine motion processing mode*/
    uint16_t fineMotionCurrFrameIdx; /**<pointer index of the current frame in the fine motion radar cube*/
    uint8_t  fineMotionActive; /**<fine motion is currently being processed*/
    uint16_t fineMotionDopplerThrIdx; /**<fine motion points Doppler threshold, points with higher than this Doppler bin (+/-) are ignored*/

    RADARDEMO_detectionCFAR_input  *detectionCFARInput; /**<CFAR input*/
    RADARDEMO_detectionCFAR_output *detectionCFAROutput; /**<CFAR output*/

    uint16_t mimoModeFlag; /**<Flag for MIMO mode: 0 -- SIMO, 1 -- TDM MIMO, 2 -- BPM MIMO*/
    uint16_t bpmPosPhaseAntIdx; /**<Index of TX Antenna in BPM mode with positive phase (only 2 TX BPM is supported) */
    uint16_t bpmNegPhaseAntIdx; /**<Index of TX Antenna in BPM mode with negative phase (only 2 TX BPM is supported) */

    RADARDEMO_aoaEst2DCaponBF_input  *aoaInput; /**<2D capon input*/
    RADARDEMO_aoaEst2DCaponBF_output *aoaOutput; /**<2D capon output*/

    RADARDEMO_detectionCFAR_errorCode   cfarErrorCode; /**<CFAR error code*/
    RADARDEMO_aoaEst2DCaponBF_errorCode aoaBFErrorCode; /**<2D capon error code*/
    float                               dynamicSideLobeThr; /**<dynamic CFAR sidelobe relative threshold*/
    float                               staticSideLobeThr; /**<static CFAR sidelobe relative threshold*/

    uint32_t heatMapMemSize; /**< heatmap size, output from the init function -- in case to be used in framework. */
    float   *tempHeatMapOut; /**<heatmap output per range bin, to be transposed and stored to final heatmap buffer*/
    cplxf_t *static_information; /**< Zero doppler samples for the range bins, for all the antennas, arranged in ant x rangeBin format.*/
    int32_t  numRangeBins; /**<range FFT size*/
    int32_t  DopplerFFTSize; /**<Doppler FFT size*/
    int32_t  numChirpsPerFrame; /**<number of chirps per frame*/
    int32_t  numAdcSamplePerChirp; /**<number of ADC saples per chirps*/
    int32_t  nRxAnt; /**<number of total virtual RX antennas*/
    int32_t  maxNumDetObj; /**<max number of detected points per frame*/
    int32_t  numDynAngleBin; /**<number of angle bins for dynamic range-angle heatmap*/
    int32_t  numStaticAngleBin; /**<number of angle bins for static range-angle heatmap*/
    int32_t  numAzimuthBin; /**<number of azimuth bins for 2D capon*/
    int32_t  numElevationBin; /**<number of elevation bins for 2D capon*/
    float    rangeRes; /**<range interbin resolution*/
    float    dopplerRes; /**<Doppler interbin resolution*/
    uint8_t  dopplerOversampleFactor; /**<Doppler FFT oversample factor, currently un-used -- heardcoded to 1*/
    uint8_t  scaleDopCfarOutCFAR; /**<Doppler output scale to accommondate FFT oversample factor, currently un-used -- heardcoded to 1*/
    uint8_t  cfarRangeSkipLeft; /**<range domain left side skip samples for CAFR*/
    uint8_t  cfarRangeSkipRight; /**<range domain right side skip samples for CAFR*/

    radarProcessBenchmarkObj *benchmarkPtr;
} radarProcessInstance_t;


#endif // _RADARPROCESS_INTERNAL_H

/* Nothing past this point */
