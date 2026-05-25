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

#include <dpu/capon3d/modules/DoA/CaponBF2D/src/RADARDEMO_aoaEst2DCaponBF_priv.h>
#define DEBUG(_x) //_x

#ifdef _TMS320C6X
#include "c6x.h"
#endif


/*!
 *   \fn     RADARDEMO_aoaEst2DCaponBF_bpmDecoding
 *
 *   \brief   Per range bin, decode the BPM from the input signal.
 *
 *   \param[in]    nRxAnt
 *               number of antenna
 *
 *   \param[in]    nChirps
 *               number of input chirps
 *
 *   \param[in]    bpmPosPhaseAntIdx
 *               index of TX Antenna in BPM mode with positive phase (only 2 TX BPM is supported)
 *
 *   \param[in]    bpmNegPhaseAntIdx
 *               index of TX Antenna in BPM mode with negative phase (only 2 TX BPM is supported)
 *
 *   \param[in/out]    inputAntSamples
 *               input samples from radar cube (1D FFT output) for the current (one) range bin to be processed.
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
void RADARDEMO_aoaEst2DCaponBF_bpmDecoding(
    IN int32_t      nRxAnt,
    IN int32_t      nChirps,
    IN int32_t      bpmPosPhaseAntIdx,
    IN int32_t      bpmNegPhaseAntIdx,
    INOUT cplx16_t *inputAntSamples)
{
#ifdef RADARDEMO_AOARADARCUDE_RNGCHIRPANT
    int32_t            antIdx, chirpIdx, tdmAntIdx;
    cplx16_t *RESTRICT input1;
    cplx16_t *RESTRICT input2;
    cplx16_t *RESTRICT input3;
    cplx16_t *RESTRICT input4;
    cplx16_t *RESTRICT input5;
    cplx16_t *RESTRICT input6;
    int64_t            intAdd, intSub;

#ifdef _TMS320C6X
    _nassert(nRxAnt % 4 == 0);
    _nassert(nRxAnt / 4 == 3); /* Only 3TX is supported */
    _nassert(nChirps % 8 == 0);
#endif

    antIdx    = 0;
    tdmAntIdx = 3 - bpmPosPhaseAntIdx - bpmNegPhaseAntIdx; /* Supporting 3TX with 2TX BPM and 1TX TDM */

    input1 = (cplx16_t *)&inputAntSamples[antIdx + 4 * bpmPosPhaseAntIdx]; /* RX1 of 1st BPM TX */
    input2 = (cplx16_t *)&inputAntSamples[antIdx + 4 * bpmNegPhaseAntIdx]; /* RX1 of 2nd BPM TX */
    input3 = (cplx16_t *)&inputAntSamples[antIdx + 2 + 4 * bpmPosPhaseAntIdx]; /* RX3 of 1st BPM TX */
    input4 = (cplx16_t *)&inputAntSamples[antIdx + 2 + 4 * bpmNegPhaseAntIdx]; /* RX3 of 2nd BPM TX */
    input5 = (cplx16_t *)&inputAntSamples[antIdx + 4 * tdmAntIdx]; /* RX1 of TDM TX */
    input6 = (cplx16_t *)&inputAntSamples[antIdx + 2 + 4 * tdmAntIdx]; /* RX3 of TDM TX */

    for (chirpIdx = 0; chirpIdx < nRxAnt * nChirps; chirpIdx += nRxAnt)
    {
        intAdd                    = _dsadd2(_amem8(&input1[chirpIdx]), _amem8(&input2[chirpIdx]));
        intSub                    = _dssub2(_amem8(&input1[chirpIdx]), _amem8(&input2[chirpIdx]));
        _amem8(&input1[chirpIdx]) = intAdd;
        _amem8(&input2[chirpIdx]) = intSub;

        intAdd                    = _dsadd2(_amem8(&input3[chirpIdx]), _amem8(&input4[chirpIdx]));
        intSub                    = _dssub2(_amem8(&input3[chirpIdx]), _amem8(&input4[chirpIdx]));
        _amem8(&input3[chirpIdx]) = intAdd;
        _amem8(&input4[chirpIdx]) = intSub;

        intAdd                    = _dsadd2(_amem8(&input5[chirpIdx]), _amem8(&input5[chirpIdx]));
        _amem8(&input5[chirpIdx]) = intAdd;
        intAdd                    = _dsadd2(_amem8(&input6[chirpIdx]), _amem8(&input6[chirpIdx]));
        _amem8(&input6[chirpIdx]) = intAdd;
    }

#endif
}
