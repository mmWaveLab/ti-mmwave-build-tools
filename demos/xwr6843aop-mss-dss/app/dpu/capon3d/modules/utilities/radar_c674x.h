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

#ifndef _RADARDEMO_C674X_H
#define _RADARDEMO_C674X_H

#include <source/ti/common/swpform.h>

#ifndef _TMS320C6600

static inline __float2_t _complex_conjugate_mpysp(__float2_t x, __float2_t y)
{
    float zreal, zimg;
    zreal = _hif2(x) * _hif2(y) + _lof2(x) * _lof2(y);
    zimg  = _hif2(x) * _lof2(y) - _lof2(x) * _hif2(y);
    return (_ftof2(zreal, zimg));
}

static inline __float2_t _complex_mpysp(__float2_t x, __float2_t y)
{
    float zreal, zimg;
    zreal = _hif2(x) * _hif2(y) - _lof2(x) * _lof2(y);
    zimg  = _hif2(x) * _lof2(y) + _lof2(x) * _hif2(y);
    return (_ftof2(zreal, zimg));
}

static inline __float2_t _daddsp(__float2_t x, __float2_t y)
{
    float zreal, zimg;
    zreal = _hif2(x) + _hif2(y);
    zimg  = _lof2(x) + _lof2(y);
    return (_ftof2(zreal, zimg));
}
static inline __float2_t _dintsp(int64_t x)
{
    int32_t zreal, zimg;
    zreal = (int32_t)_hill(x);
    zimg  = (int32_t)_loll(x);
    return (_ftof2((float)zreal, (float)zimg));
}


static inline __float2_t _dsubsp(__float2_t x, __float2_t y)
{
    float zreal, zimg;
    zreal = _hif2(x) - _hif2(y);
    zimg  = _lof2(x) - _lof2(y);
    return (_ftof2(zreal, zimg));
}

static inline __float2_t _dmpysp(__float2_t x, __float2_t y)
{
    float zreal, zimg;
    zreal = _hif2(x) * _hif2(y);
    zimg  = _lof2(x) * _lof2(y);
    return (_ftof2(zreal, zimg));
}


static inline __float2_t _dinthsp(int32_t input)
{
#if 1
    float zreal, zimg;
    zreal = (float)_ext(input, 0, 16);
    zimg  = (float)_ext(input, 16, 16);
    return (_ftof2(zreal, zimg));
#else
    int64_t lltemp;
    float   zreal, zimg;
    lltemp = _cmpy(input, 0x00010001);
    zreal  = (float)_hill(lltemp);
    zimg   = (float)_loll(lltemp);
    return (_ftof2(zreal, zimg));

#endif
}

static inline int32_t _dspinth(__float2_t input)
{
    int32_t zreal, zimg;
    zreal = _spint(_hif2(input));
    zimg  = _spint(_lof2(input));
    return (_pack2(zreal, zimg));
}

static inline int64_t _dspint(__float2_t input)
{
    int32_t zreal, zimg;
    zreal = _spint(_hif2(input));
    zimg  = _spint(_lof2(input));
    return (_itoll(zreal, zimg));
}
static inline int64_t _davg2(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _avg2(_hill(x), _hill(y));
    zlo = _avg2(_loll(x), _loll(y));
    return (_itoll(zhi, zlo));
}

static inline int64_t _dssub2(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _ssub2(_hill(x), _hill(y));
    zlo = _ssub2(_loll(x), _loll(y));
    return (_itoll(zhi, zlo));
}
static inline int64_t _dsadd2(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _sadd2(_hill(x), _hill(y));
    zlo = _sadd2(_loll(x), _loll(y));
    return (_itoll(zhi, zlo));
}

static inline int64_t _dadd(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _hill(x) + _hill(y);
    zlo = _loll(x) + _loll(y);
    return (_itoll(zhi, zlo));
}

static inline int64_t _dcmpyr1(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _cmpyr1(_hill(x), _hill(y));
    zlo = _cmpyr1(_loll(x), _loll(y));
    return (_itoll(zhi, zlo));
}

static inline int64_t _dshl2(int64_t x, int32_t y)
{
    int32_t zhi, zlo;
    zhi = _sshl(_hill(x), y);
    zlo = _sshl(_loll(x), y);
    return (_itoll(zhi, zlo));
}

static inline int64_t _dshr2(int64_t x, int32_t y)
{
    int32_t zhi, zlo;
    zhi = _shr2(_hill(x), y);
    zlo = _shr2(_loll(x), y);
    return (_itoll(zhi, zlo));
}

static inline int64_t _dsadd(int64_t x, int64_t y)
{
    int32_t zreal, zimg;
    zreal = _hill(x) + _hill(y);
    zimg  = _loll(x) + _loll(y);
    return (_itoll(zreal, zimg));
}

static inline int64_t _dssub(int64_t x, int64_t y)
{
    int32_t zreal, zimg;
    zreal = _hill(x) - _hill(y);
    zimg  = _loll(x) - _loll(y);
    return (_itoll(zreal, zimg));
}


static inline int64_t _dshl(int64_t x, int32_t y)
{
    int32_t zhi, zlo;
    zhi = _sshl(_hill(x), y);
    zlo = _sshl(_loll(x), y);
    return (_itoll(zhi, zlo));
}

static inline _dcmpgt2(int64_t x, int64_t y)
{
    int32_t zhi, zlo;
    zhi = _cmpgt2(_hill(x), _hill(y));
    zlo = _cmpgt2(_loll(x), _loll(y));
    return ((zhi << 2) | zlo);
}

static inline _dxpnd2(int32_t x)
{
    int32_t zhi, zlo;
    zhi = _xpnd2(x >> 2);
    zlo = _xpnd2(x & 0x3);
    return (_itoll(zhi, zlo));
}


#endif


#endif //_RADARDEMO_C674X_H
