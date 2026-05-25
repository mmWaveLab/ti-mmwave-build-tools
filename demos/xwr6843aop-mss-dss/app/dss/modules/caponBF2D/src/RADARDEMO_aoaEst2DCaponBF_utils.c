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

#ifdef _TMS320C6X
#include "c6x.h"
#endif
#include <dpu/capon3d/modules/utilities/radar_commonMath.h>

#ifndef _GENTWIDDLE_FFTFLOAT
#define _GENTWIDDLE_FFTFLOAT

#ifdef _TMS320C6600 // C66x

void tw_gen_float(float *w, int n)
{
    int          i, j, k;
    const double PI = 3.141592654;

    for (j = 1, k = 0; j <= n >> 2; j = j << 2)
    {
        for (i = 0; i < n >> 2; i += j)
        {
#ifdef _LITTLE_ENDIAN
            w[k]     = (float)sindp_i(2 * PI * divdp_i((double)i, (double)n));
            w[k + 1] = (float)cosdp_i(2 * PI * divdp_i((double)i, (double)n));
            w[k + 2] = (float)sindp_i(4 * PI * divdp_i((double)i, (double)n));
            w[k + 3] = (float)cosdp_i(4 * PI * divdp_i((double)i, (double)n));
            w[k + 4] = (float)sindp_i(6 * PI * divdp_i((double)i, (double)n));
            w[k + 5] = (float)cosdp_i(6 * PI * divdp_i((double)i, (double)n));
#else
            w[k]     = (float)cosdp_i(2 * PI * divdp_i((double)i, (double)n));
            w[k + 1] = (float)-sindp_i(2 * PI * divdp_i((double)i, (double)n));
            w[k + 2] = (float)cosdp_i(4 * PI * divdp_i((double)i, (double)n));
            w[k + 3] = (float)-sindp_i(4 * PI * divdp_i((double)i, (double)n));
            w[k + 4] = (float)cosdp_i(6 * PI * divdp_i((double)i, (double)n));
            w[k + 5] = (float)-sindp_i(6 * PI * divdp_i((double)i, (double)n));
#endif
            k += 6;
        }
    }
}
#else // C674x

void tw_gen_float(float *w, int n)
{
    int          i, j, k;
    double       x_t, y_t, theta1, theta2, theta3;
    const double PI = 3.141592654;
    // double invn;

    for (j = 1, k = 0; j <= n >> 2; j = j << 2)
    {
        for (i = 0; i < n >> 2; i += j)
        {
            theta1   = 2 * PI * divdp_i((double)i, (double)n);
            x_t      = cosdp_i(theta1);
            y_t      = sindp_i(theta1);
            w[k]     = (float)x_t;
            w[k + 1] = (float)y_t;

            theta2   = 4 * PI * divdp_i((double)i, (double)n);
            x_t      = cosdp_i(theta2);
            y_t      = sindp_i(theta2);
            w[k + 2] = (float)x_t;
            w[k + 3] = (float)y_t;

            theta3   = 6 * PI * divdp_i((double)i, (double)n);
            x_t      = cosdp_i(theta3);
            y_t      = sindp_i(theta3);
            w[k + 4] = (float)x_t;
            w[k + 5] = (float)y_t;
            k += 6;
        }
    }
}
#endif

#endif //_GENTWIDDLE_FFTFLOAT
