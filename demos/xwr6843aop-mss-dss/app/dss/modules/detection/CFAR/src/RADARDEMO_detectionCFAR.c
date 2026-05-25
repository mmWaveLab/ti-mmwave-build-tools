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


#include <dpu/capon3d/modules/detection/CFAR/api/RADARDEMO_detectionCFAR.h>
#include "RADARDEMO_detectionCFAR_priv.h"
#include <math.h>
#include <stdio.h>

#define DEBUG(_x)                       //_x
#define GTRACK_NOMINAL_ALLOCATION_RANGE 6.0f /* Range for allocation SNR scaling */
#define GTRACK_MAX_SNR_RANGE            2.5f /* Range for SNR maximum */
#define GTRACK_FIXED_SNR_RANGE          1.0f /* Range for SNR fixed */
#define GTRACK_MAX_SNR_RATIO            GTRACK_NOMINAL_ALLOCATION_RANGE / GTRACK_MAX_SNR_RANGE
#define GTRACK_MAX_SNR_RATIO_P3         GTRACK_MAX_SNR_RATIO *GTRACK_MAX_SNR_RATIO *GTRACK_MAX_SNR_RATIO

#ifdef _TMS320C6X
#include "c6x.h"
#endif


/*!
   \fn     RADARDEMO_detectionCFAR_create

   \brief   Create and initialize RADARDEMO_detectionCFAR module.

   \param[in]    moduleConfig
               Pointer to input configurations structure for RADARDEMO_detectionCFAR module.

   \param[in]    errorCode
               Output error code.

   \ret     void pointer to the module handle. Return value of NULL indicates failed module creation.

   \pre       none

   \post      none


 */

void *RADARDEMO_detectionCFAR_create(
    IN RADARDEMO_detectionCFAR_config     *moduleConfig,
    OUT RADARDEMO_detectionCFAR_errorCode *errorCode)

{
    RADARDEMO_detectionCFAR_handle *handle;

    *errorCode = RADARDEMO_DETECTIONCFAR_NO_ERROR;

    /* Check error configurations */
    /* unsupported CFAR type */
    if (moduleConfig->cfarType >= RADARDEMO_DETECTIONCFAR_NOT_SUPPORTED)
        *errorCode = RADARDEMO_DETECTIONCFAR_CFARTYPE_NOTSUPPORTED;

    /* unsupported input type */
    if (moduleConfig->inputType >= RADARDEMO_DETECTIONCFAR_INPUTTYPE_NOT_SUPPORTED)
        *errorCode = RADARDEMO_DETECTIONCFAR_CFARINPUTTYPE_NOTSUPPORTED;

    /* Unsupported CFAR-OS window size */
    if ((moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CFAROS) && (moduleConfig->searchWinSizeRange != 16))
        *errorCode = RADARDEMO_DETECTIONCFAR_CFAROSWINSIZE_NOTSUPPORTED;

    /* incorrect CFAR-CASO window setting */
    if ((moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CASOCFAR) && (moduleConfig->searchWinSizeDoppler == 0))
        *errorCode = RADARDEMO_DETECTIONCFAR_CFARCASOWINSIZE_NOTSUPPORTED;

    if (*errorCode > RADARDEMO_DETECTIONCFAR_NO_ERROR)
        return (NULL);

    handle = (RADARDEMO_detectionCFAR_handle *)radarOsal_memAlloc((uint8_t)RADARMEMOSAL_HEAPTYPE_LL2, 0, sizeof(RADARDEMO_detectionCFAR_handle), 1);
    if (handle == NULL)
    {
        *errorCode = RADARDEMO_DETECTIONCFAR_FAIL_ALLOCATE_HANDLE;
        return (handle);
    }

    handle->fft1DSize              = moduleConfig->fft1DSize;
    handle->fft2DSize              = moduleConfig->fft2DSize;
    handle->cfarType               = (uint8_t)moduleConfig->cfarType;
    handle->rangeRes               = moduleConfig->rangeRes;
    handle->dopplerRes             = moduleConfig->dopplerRes;
    handle->searchWinSizeRange     = moduleConfig->searchWinSizeRange;
    handle->guardSizeRange         = moduleConfig->guardSizeRange;
    handle->searchWinSizeDoppler   = moduleConfig->searchWinSizeDoppler;
    handle->guardSizeDoppler       = moduleConfig->guardSizeDoppler;
    handle->maxNumDetObj           = moduleConfig->maxNumDetObj;
    handle->leftSkipSize           = moduleConfig->leftSkipSize;
    handle->rightSkipSize          = moduleConfig->rightSkipSize;
    handle->enableSecondPassSearch = moduleConfig->enableSecondPassSearch;
    handle->dopplerSearchRelThr    = moduleConfig->dopplerSearchRelThr;
    handle->log2MagFlag            = moduleConfig->log2MagFlag;
    handle->angleDim1              = moduleConfig->angleDim1;
    handle->angleDim2              = moduleConfig->angleDim2;


    /* parse CA-CFAR types */
    if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CAVGCFAR)
        handle->caCfarType = RADARDEMO_DETECTIONCFAR_CFAR_CAVG;
    if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CASOCFAR)
        handle->caCfarType = RADARDEMO_DETECTIONCFAR_CFAR_CASO;
    if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CACCCFAR)
        handle->caCfarType = RADARDEMO_DETECTIONCFAR_CFAR_CACC;
    if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CAGOCFAR)
        handle->caCfarType = RADARDEMO_DETECTIONCFAR_CFAR_CAGO;

    /* parse CFAR settings */
    if ((moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_RA_CASOCFAR) || (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_RA_CASOCFARV2))
    {
        handle->caCfarType           = RADARDEMO_DETECTIONCFAR_RA_CFAR_CASO;
        handle->leftSkipSizeAzimuth  = moduleConfig->leftSkipSizeAzimuth;
        handle->rightSkipSizeAzimuth = moduleConfig->rightSkipSizeAzimuth;
    }

    /* parse CFAR threshold settings */
    handle->relThr      = moduleConfig->K0;
    handle->dynamicFlag = moduleConfig->dynamicFlag;

    /* allocate memory for CFAR threshold values based on range and doppler sizes */
    if (handle->dynamicFlag)
    {
        handle->rangeThreArray   = (float *)radarOsal_memAlloc((uint8_t)RADARMEMOSAL_HEAPTYPE_LL1, 0, moduleConfig->fft1DSize * sizeof(float), 8);
        handle->dopplerThreArray = (float *)radarOsal_memAlloc((uint8_t)RADARMEMOSAL_HEAPTYPE_LL1, 0, moduleConfig->fft2DSize * sizeof(float), 8);
    }

#ifdef USE_TABLE_FOR_K0
    if (moduleConfig->K0 == 0.f)
    {
        int32_t i, j, k;
        ;
        if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CAVGCFAR)
        {
            j = (int32_t)floor(9.5f + log10(moduleConfig->pfa)) - 1;
            if (j < 0)
                j = 0;
            i              = (handle->searchWinSizeRange >> 2) - 1;
            handle->relThr = rltvThr_CFARCA[i * 7 + j];
        }
        else if (moduleConfig->cfarType == RADARDEMO_DETECTIONCFAR_CFAROS)
        {
            j              = (int32_t)floor(7.5f + log10(moduleConfig->pfa)) - 1;
            i              = (handle->searchWinSizeRange >> 2) - 1;
            k              = ((3 * (2 * handle->searchWinSizeRange)) >> 2) - 2;
            handle->relThr = rltvThr_CFAROS[i][k * 5 + j];
        }
    }
#endif

    handle->scratchPad = (int32_t *)radarOsal_memAlloc(RADARMEMOSAL_HEAPTYPE_LL2, 1, handle->fft1DSize * (sizeof(float) + sizeof(int16_t)) + 100 * sizeof(float), 1);
    if (handle->scratchPad == NULL)
    {
        *errorCode = RADARDEMO_DETECTIONCFAR_FAIL_ALLOCATE_LOCALINSTMEM;
    }
    return ((void *)handle);
}

/*!
   \fn     RADARDEMO_detectionCFAR_dynamic

   \brief   Calculates arrays of scalars for the range and azimuth to dynamically set CFAR thresholds.

   \param[in]    detectionCFARInst
               Pointer to input detection handle.


 */

extern int32_t RADARDEMO_detectionCFAR_dynamic(
    IN void *handle)

{
    // For detection method 1
    RADARDEMO_detectionCFAR_handle *detectionCFARInst;
    uint32_t                        rangeIdx, dopplerIdx;
    float                           dopplerPolyScalar;
    float                           rangeEst;
    float                           snrRatio;
    float                           snrRatio3;
    float                           snrThreMax;
    float                           snrThreFixed;
    float                           snrThreMin;
    uint32_t                        range_size;
    uint32_t                        doppler_size;

    detectionCFARInst = (RADARDEMO_detectionCFAR_handle *)handle;
    range_size        = detectionCFARInst->fft1DSize;
    doppler_size      = detectionCFARInst->fft2DSize;
    snrThreMax        = GTRACK_MAX_SNR_RATIO_P3 * detectionCFARInst->relThr;
    snrThreFixed      = snrThreMax / 3.0f;
    snrThreMin        = 3.99;

    for (rangeIdx = 0; rangeIdx < range_size; rangeIdx++)
    {
        // The estimated range for the range bin of interest
        rangeEst = (float)rangeIdx * detectionCFARInst->rangeRes;

        if (rangeEst < GTRACK_FIXED_SNR_RANGE)
        {
            detectionCFARInst->rangeThreArray[rangeIdx] = snrThreFixed;
        }
        else
        {
            snrRatio  = GTRACK_NOMINAL_ALLOCATION_RANGE / rangeEst;
            snrRatio3 = snrRatio * snrRatio * snrRatio;

            if (rangeEst < GTRACK_MAX_SNR_RANGE) // When range is greater than GTRACK_FIXED_SNR_RANGE and less than GTRACK_MAX_SNR_RANGE the SNR floor linearly increases
            {
                detectionCFARInst->rangeThreArray[rangeIdx] = (rangeEst - GTRACK_FIXED_SNR_RANGE) * (snrThreMax - snrThreFixed) / (GTRACK_MAX_SNR_RANGE - GTRACK_FIXED_SNR_RANGE) + snrThreFixed;
            }
            else // When range is greater than GTRACK_MAX_SNR_RANGE the SNR floor decreases exponetially at a power of 3
            {
                detectionCFARInst->rangeThreArray[rangeIdx] = snrRatio3 * detectionCFARInst->relThr;
                if (detectionCFARInst->rangeThreArray[rangeIdx] < snrThreMin) // At far distances we do not let the threshold go lower than snrThreMin
                {
                    detectionCFARInst->rangeThreArray[rangeIdx] = snrThreMin;
                }
            }
        }
    }

    // In the azimuth direction (doppler) the SNR floor follows a polynomial shape similar to a cosine
    for (dopplerIdx = 0; dopplerIdx < doppler_size; dopplerIdx++)
    {
        dopplerPolyScalar                               = CFARarray_poly(dopplerIdx, doppler_size);
        detectionCFARInst->dopplerThreArray[dopplerIdx] = dopplerPolyScalar;
    }

    return (range_size * doppler_size);
}

/*!
   \fn     RADARDEMO_detectionCFAR_delete

   \brief   Delete RADARDEMO_detectionCFAR module.

   \param[in]    handle
               Module handle.

   \pre       none

   \post      none


 */

void RADARDEMO_detectionCFAR_delete(
    IN void *handle)
{
    RADARDEMO_detectionCFAR_handle *detectionCFARInst;

    detectionCFARInst = (RADARDEMO_detectionCFAR_handle *)handle;

    radarOsal_memFree(detectionCFARInst->scratchPad, detectionCFARInst->fft1DSize * (sizeof(float) + sizeof(int16_t)) + 100 * sizeof(float));
    radarOsal_memFree(detectionCFARInst, sizeof(RADARDEMO_detectionCFAR_handle));
}


/*!
   \fn     RADARDEMO_detectionCFAR_run

   \brief   Range processing, always called per chirp per antenna.

   \param[in]    handle
               Module handle.

   \param[in]    detectionCFARInput
               Input signal, with dimension [fft2DSize][fft1DSize]. Must be aligned to 8-byte boundary.

   \param[out]    estOutput
               Estimation output from CFAR module.

   \ret error code

   \pre       none

   \post      none


 */

RADARDEMO_detectionCFAR_errorCode RADARDEMO_detectionCFAR_run(
    IN void                            *handle,
    IN RADARDEMO_detectionCFAR_input   *detectionCFARInput,
    OUT RADARDEMO_detectionCFAR_output *estOutput)

{
    RADARDEMO_detectionCFAR_handle   *detectionCFARInst;
    RADARDEMO_detectionCFAR_errorCode errorCode = RADARDEMO_DETECTIONCFAR_NO_ERROR;

    detectionCFARInst = (RADARDEMO_detectionCFAR_handle *)handle;

    if (detectionCFARInput == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if (estOutput == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if (estOutput->rangeInd == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if (estOutput->dopplerInd == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType < RADARDEMO_DETECTIONCFAR_RA_CASOCFAR)
    {
        if (estOutput->rangeEst == NULL)
            errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
        if (estOutput->dopplerEst == NULL)
            errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    }
    if (estOutput->snrEst == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if (estOutput->noise == NULL)
        errorCode = RADARDEMO_DETECTIONCFAR_INOUTPTR_NOTCORRECT;
    if (errorCode > RADARDEMO_DETECTIONCFAR_NO_ERROR)
        return (errorCode);

    if ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_CFAROS)
    {
        estOutput->numObjDetected = RADARDEMO_detectionCFAR_OS(
            detectionCFARInput->heatmapInput,
            detectionCFARInst,
            estOutput->rangeInd,
            estOutput->dopplerInd,
            estOutput->rangeEst,
            estOutput->dopplerEst,
            estOutput->snrEst,
            estOutput->noise);
    }
    else if (((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_CASOCFAR) || ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_CACCCFAR) || ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_CAGOCFAR) || ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_CAVGCFAR))
    {
        estOutput->numObjDetected = RADARDEMO_detectionCFAR_CAAll(
            detectionCFARInput->heatmapInput,
            detectionCFARInst,
            estOutput->rangeInd,
            estOutput->dopplerInd,
            estOutput->rangeEst,
            estOutput->dopplerEst,
            estOutput->rangeVar,
            estOutput->dopplerVar,
            estOutput->snrEst,
            estOutput->noise);
    }
    else if ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_RA_CASOCFAR)
    {
        // reuse doppler index output to store azimuth index for now.
        detectionCFARInput->enableSecondPass = detectionCFARInst->enableSecondPassSearch;
        estOutput->numObjDetected            = RADARDEMO_detectionCFAR_raCAAll(
            detectionCFARInput->heatmapInput,
            detectionCFARInst,
            estOutput->rangeInd,
            estOutput->dopplerInd,
            estOutput->snrEst,
            estOutput->noise,
            detectionCFARInput->azMaxPerRangeBin,
            detectionCFARInput->sidelobeThr,
            detectionCFARInput->enableSecondPass,
            detectionCFARInput->enable_neighbour_check);
    }
    else if ((RADARDEMO_detectionCFAR_Type)detectionCFARInst->cfarType == RADARDEMO_DETECTIONCFAR_RA_CASOCFARV2)
    {
        // reuse doppler index output to store azimuth index for now.
        detectionCFARInput->enableSecondPass = detectionCFARInst->enableSecondPassSearch;
        estOutput->numObjDetected            = RADARDEMO_detectionCFAR_raCAAll_ver2(
            detectionCFARInput->heatmapInput,
            detectionCFARInst,
            estOutput->rangeInd,
            estOutput->dopplerInd,
            estOutput->snrEst,
            estOutput->noise,
            detectionCFARInput->azMaxPerRangeBin,
            detectionCFARInput->sidelobeThr,
            detectionCFARInput->enableSecondPass,
            detectionCFARInput->enable_neighbour_check);
    }
    return (errorCode);
}
