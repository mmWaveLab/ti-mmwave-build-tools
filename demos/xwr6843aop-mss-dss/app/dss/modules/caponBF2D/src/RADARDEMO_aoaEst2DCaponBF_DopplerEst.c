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

#include "RADARDEMO_aoaEst2DCaponBF_priv.h"

/*!
 *   \fn     RADARDEMO_aoaEst2DCaponBF_dopperEstInput
 *
 *   \brief   Calculate the beam forming output for doppler estimation, for the current range bin and angle bins.
 *
 *   \param[in]    nRxAnt
 *               number of antenna
 *
 *   \param[in]    nChirps
 *               number of chirps
 *
 *   \param[in]    inputAntSamples
 *              Input 1D FFT results for the current range bin.
 *              Must be aligned to 8-byte boundary.
 *
 *   \param[in]    steeringVec
 *              steering vector for beamforming for the current azimuth bin.
 *
 *   \param[in]    bweights
 *               Beam filter coefficients for the detection.
 *
 *   \param[out]    bfOutput
 *               Beamforming output for the current range bin and azimuth bin.
 *               Must be in the order of real0, imag0, real1, imag1... as required by DSP LIB single precision floating-point FFT.
 *               Must be aligned to 8-byte boundary.
 *
 *   \ret       none
 *
 *   \pre       none
 *
 *   \post      none
 *
 *
 */
void RADARDEMO_aoaEst2DCaponBF_dopperEstInput(
    IN int32_t          nRxAnt,
    IN int32_t          nChirps,
    IN cplx16_t        *inputAntSamples,
    IN cplxf_t         *bweights,
    OUT float *RESTRICT bfOutput)
{
    int32_t           chirpIdx, i;
    __float2_t        f2temp, f2temp1, bw;
    int32_t *RESTRICT inPtr;

#ifdef _TMS320C6X
    _nassert(nChirps % 8 == 0);
#endif
    inPtr = (int32_t *)&inputAntSamples[0];
    bw    = _amem8_f2(&bweights[0]);
#ifdef _TMS320C6X
#pragma UNROLL(2);
#endif
    for (chirpIdx = 0; chirpIdx < nChirps; chirpIdx++)
    {
        f2temp                             = _complex_conjugate_mpysp(bw, _dinthsp(_amem4(&inPtr[chirpIdx])));
        _amem8_f2(&bfOutput[2 * chirpIdx]) = _ftof2(_lof2(f2temp), _hif2(f2temp));
    }

    for (i = 1; i < nRxAnt; i++)
    {
        inPtr = (int32_t *)&inputAntSamples[i * nChirps];
        bw    = _amem8_f2(&bweights[i]);
#ifdef _TMS320C6X
#pragma UNROLL(2);
#endif
        for (chirpIdx = 0; chirpIdx < nChirps; chirpIdx++)
        {
            f2temp                             = _complex_conjugate_mpysp(bw, _dinthsp(_amem4(&inPtr[chirpIdx])));
            f2temp1                            = _amem8_f2(&bfOutput[2 * chirpIdx]);
            _amem8_f2(&bfOutput[2 * chirpIdx]) = _daddsp(f2temp1, _ftof2(_lof2(f2temp), _hif2(f2temp)));
        }
    }
}
