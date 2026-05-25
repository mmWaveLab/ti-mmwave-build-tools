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
 * Local complex-number type definitions used by the xWR6843AOP MSS+DSS
 * starter profile.
 */

#ifndef SOURCE_TI_COMMON_CPLX_TYPES_H
#define SOURCE_TI_COMMON_CPLX_TYPES_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cplx16_t_
{
    int16_t real;
    int16_t imag;
} cplx16_t;

typedef struct cplx32_t_
{
    int32_t real;
    int32_t imag;
} cplx32_t;

typedef struct cplxf_t_
{
    float real;
    float imag;
} cplxf_t;

#ifdef __cplusplus
}
#endif

#endif
