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

#ifndef _SWPFORM_H_
#define _SWPFORM_H_

#ifdef INLINE
#undef INLINE
#endif

#ifdef RESTRICT
#undef RESTRICT
#endif

#ifdef IN
#undef IN
#endif

#ifdef OUT
#undef OUT
#endif

#ifdef INOUT
#undef INOUT
#endif

#if defined(__TI_COMPILER_VERSION__)
/******************/
/* C6000 compiler */
/******************/
#if defined(_TMS320C6X)

#if defined(__cplusplus)
/* c++ specific */

#include <inttypes.h> /* c99 types - cinttypes not available on c6000 compiler */
#define INLINE   static inline
#define RESTRICT restrict
#include <cstddef>
#include <climits>
#include <cfloat.h>
#include <ciso646>

#else
/* c specific */

#include <inttypes.h> /* c99 types */
#include <stdbool.h> /* _Bool type */
// typedef unsigned int _Bool;     /* c99 types */
// typedef _Bool bool;             /* c99 types */
#define true 1 /* c99 types */
#define false 0 /* c99 types */
#define __bool_true_false_are_defined 1 /* c99 types */
#define INLINE                        static inline
#define RESTRICT                      restrict
#include <stddef.h>
#include <limits.h>
#include <float.h>
#include <iso646.h>

#endif

#include <c6x.h> /* get access to global registers */

/* various macros */
#define IN
#define OUT
#define INOUT

#else

//#error Target shall be C6x
#define _LITTLE_ENDIAN
/* various macros */
#define IN
#define OUT
#define INOUT
#endif

#elif defined(__GNUC__)
/****************/
/* GNU compiler */
/****************/

#if defined(__cplusplus)
/* c++ specific */

#if defined(__GXX_EXPERIMENTAL_CXX0X__)

#include <cinttypes> /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef long long          int40_t; /* c99 types */
typedef unsigned long long uint40_t; /* c99 types */
typedef int40_t            int_least40_t; /* c99 types */
typedef uint40_t           uint_least40_t; /* c99 types */
typedef int40_t            int_fast40_t; /* c99 types */
typedef uint40_t           uint_fast40_t; /* c99 types */
#define INT40_MAX        0x7fffffffff /* c99 types */
#define INT40_MIN        (-INT40_MAX - 1) /* c99 types */
#define UINT40_MAX       0xffffffffff /* c99 types */
#define INT_LEAST40_MAX  INT40_MAX /* c99 types */
#define INT_LEAST40_MIN  INT40_MIN /* c99 types */
#define UINT_LEAST40_MAX UINT40_MAX /* c99 types */
#define INT_FAST40_MAX   INT40_MAX /* c99 types */
#define INT_FAST40_MIN   INT40_MIN /* c99 types */
#define UINT_FAST40_MAX  UINT40_MAX /* c99 types */
#define INT40_C(value)   ((int_least40_t)(value)) /* c99 types */
#define UINT40_C(value)  ((uint_least40_t)(value)) /* c99 types */
#endif

#else

#error Please enable C++0X compilation

#endif

#define INLINE   static __inline__
#define RESTRICT __restrict__
#include <cstddef>
#include <climits>
#include <cfloat>
#include <ciso646>

#else
/* c specific */

#if (__STDC_VERSION__ >= 199901L)

#include <inttypes.h> /* c99 types */
#include <stdbool.h> /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef long long          int40_t; /* c99 types */
typedef unsigned long long uint40_t; /* c99 types */
typedef int40_t            int_least40_t; /* c99 types */
typedef uint40_t           uint_least40_t; /* c99 types */
typedef int40_t            int_fast40_t; /* c99 types */
typedef uint40_t           uint_fast40_t; /* c99 types */
#define INT40_MAX        0x7fffffffff /* c99 types */
#define INT40_MIN        (-INT40_MAX - 1) /* c99 types */
#define UINT40_MAX       0xffffffffff /* c99 types */
#define INT_LEAST40_MAX  INT40_MAX /* c99 types */
#define INT_LEAST40_MIN  INT40_MIN /* c99 types */
#define UINT_LEAST40_MAX UINT40_MAX /* c99 types */
#define INT_FAST40_MAX   INT40_MAX /* c99 types */
#define INT_FAST40_MIN   INT40_MIN /* c99 types */
#define UINT_FAST40_MAX  UINT40_MAX /* c99 types */
#define INT40_C(value)   ((int_least40_t)(value)) /* c99 types */
#define UINT40_C(value)  ((uint_least40_t)(value)) /* c99 types */
#endif

#else

#error Please enable C99 compilation (ISO/IEC 9899:1999 standard)

#endif

#define INLINE   static inline
#define RESTRICT restrict
#include <stddef.h>
#include <limits.h>
#include <float.h>
#include <iso646.h>

#endif

/* intrinsics */
#include <C6xSimulator.h>

/* various macros */
#ifdef BIG_ENDIAN_HOST
#define _BIG_ENDIAN
#endif
#ifdef LITTLE_ENDIAN_HOST
#define _LITTLE_ENDIAN
#endif
#define IN
#define OUT
#define INOUT
#define _nassert(expr)

#elif defined(_MSC_VER)
/**********************/
/* Microsoft compiler */
/**********************/

#if defined(__cplusplus)
/* c++ specific */

typedef unsigned int     uintptr_t; /* c99 types - windows in mostly 32-bit */
typedef int              intptr_t; /* c99 types - windows is mostly 32-bit */
typedef unsigned char    uint8_t; /* c99 types */
typedef unsigned short   uint16_t; /* c99 types */
typedef unsigned int     uint32_t; /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef unsigned __int64 uint40_t; /* c99 types */
#endif
typedef unsigned __int64 uint64_t; /* c99 types */
typedef char             int8_t; /* c99 types */
typedef short            int16_t; /* c99 types */
typedef int              int32_t; /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef __int64          int40_t; /* c99 types */
#endif
typedef __int64          int64_t; /* c99 types */
#define INLINE static __inline
#define RESTRICT
#include <cstddef>
#include <climits>
#include <ciso646.h>
#include <cfloat.h>

#else
/* c specific */

// typedef unsigned int uintptr_t; /* c99 types - windows in mostly 32-bit */
// typedef int intptr_t;           /* c99 types - windows is mostly 32-bit */
typedef unsigned char    uint8_t; /* c99 types */
typedef unsigned short   uint16_t; /* c99 types */
typedef unsigned int     uint32_t; /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef unsigned __int64 uint40_t; /* c99 types */
#endif
typedef unsigned __int64 uint64_t; /* c99 types */
typedef char             int8_t; /* c99 types */
typedef short            int16_t; /* c99 types */
typedef int              int32_t; /* c99 types */
#ifdef __TI_40BIT_LONG__
typedef __int64          int40_t; /* c99 types */
#endif
typedef __int64          int64_t; /* c99 types */
typedef unsigned int     _Bool; /* c99 types */
// typedef _Bool bool;             /* c99 types */
//#define true 1
//#define false 0
#define __bool_true_false_are_defined 1
#define INLINE                        static __inline
#define RESTRICT
#include <stddef.h>
#include <limits.h>
#include <float.h>
#include <iso646.h>

#endif

/* intrinsics */
#include <C6xSimulator.h>

/* various macros */
#ifdef BIG_ENDIAN_HOST
#define _BIG_ENDIAN
#endif
#ifdef LITTLE_ENDIAN_HOST
#define _LITTLE_ENDIAN
#endif
#define IN
#define OUT
#define INOUT
#define _nassert(expr)

#else

#error Unkwown compiler

#endif

#include <source/ti/common/cplx_types.h>

#endif /* _SWPFORM_H_ */
