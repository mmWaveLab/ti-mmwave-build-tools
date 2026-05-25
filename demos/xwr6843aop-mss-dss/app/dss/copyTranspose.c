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

#include <dpu/capon3d/include/copyTranspose.h>

#if 0
uint32_t copyTranspose(uint32_t * src, uint32_t * dest, uint32_t size, int32_t offset, uint32_t stride, uint32_t pairs)
{
	int32_t i, j, k;
	j = 0;
	for(i = 0; i < (int32_t)size; i++)
	{
		for (k = 0; k < (int32_t)pairs; k++)
		{
			dest[j+k+i*offset] = src[pairs * i + k];
		}
		j += (int32_t)stride;
	}
	return(1);
}
#else

// for optimization purposes specific for 3D capon people counting, will ignore offset and pair parameter.
uint32_t copyTranspose(uint32_t *RESTRICT src, uint32_t *RESTRICT dest, uint32_t size, int32_t offset, uint32_t stride, uint32_t pairs)
{
    int32_t            i;
    int32_t            sizeOver4;
    uint64_t *RESTRICT input, lltemp1;
    uint32_t *RESTRICT output;
    uint32_t *RESTRICT input1;

    sizeOver4 = (int32_t)(size >> 2);
    input     = (uint64_t *)src;
    output    = dest;

    for (i = 0; i < sizeOver4; i++)
    {
        lltemp1 = _amem8(input++);
        *output = _loll(lltemp1);
        output += stride;
        *output = _hill(lltemp1);
        output += stride;
        lltemp1 = _amem8(input++);
        *output = _loll(lltemp1);
        output += stride;
        *output = _hill(lltemp1);
        output += stride;
    }

    input1 = (uint32_t *)src;
    i      = i * 4;
    for (; i < (int32_t)size; i++)
    {
        *output = input1[i];
        output += stride;
    }

    return (1);
}

#endif
