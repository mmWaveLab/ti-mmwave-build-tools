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

#ifndef _RADAROSALMALLOC_H
#define _RADAROSALMALLOC_H


#include <source/ti/common/swpform.h>
#ifdef _TMS320C6X
#include "c6x.h"
#include <stdlib.h>
#include <string.h>
#endif

typedef enum
{
    RADARMEMOSAL_HEAPTYPE_LL2 = 0, /**< Heap ID of heap in local L2 */
    RADARMEMOSAL_HEAPTYPE_DDR_CACHED, /**< Heap ID of heap in cached DDR*/
    RADARMEMOSAL_HEAPTYPE_LL1, /**< Heap ID of heap in local L1 */
    RADARMEMOSAL_HEAPTYPE_HSRAM, /**< Heap ID of heap in HSRAM */
    RADARMEMOSAL_HEAPTYPE_MAXNUMHEAPS
    /**< max Heap type */
} radarMemOsal_HeapType;


#define RADARMEMOSAL_FAIL (1)
#define RADARMEMOSAL_PASS (0)

typedef struct
{
    radarMemOsal_HeapType heapType; /**< type of heap */
    int8_t               *heapAddr; /**< Physical base address of heap */
    uint32_t              heapSize; /**< Total size of heap in bytes */
    int8_t               *scratchAddr; /**< Physical base address of scratch from this heap */
    uint32_t              scratchSize; /**< Total size of scratch in bytes */
} radarOsal_heapConfig;
typedef struct
{
    radarMemOsal_HeapType heapType; /**< type of heap */
    int8_t               *heapAddr; /**< Physical base address of heap */
    uint32_t              heapSize; /**< Total size of heap in bytes */
    uint32_t              heapAllocOffset; /**< Heap alloc offset, only valid for L2 heap */
    int8_t               *scratchAddr; /**< Physical base address of scratch from this heap */
    uint32_t              maxScratchSizeUsed; /**< maximum size of the scratch memory requested */
    uint32_t              scratchSize; /**< Total size of scratch in bytes */
} radarOsal_heapObj;

/*!
   \fn     radarOsal_memInit
   \brief   OSAL function for heap memory structure initialization.

   \return    RADAROSAL_FAIL if heap init failed, RADAROSAL_PASS if heap init passed.
   \pre       none
   \post      none
 */
extern int32_t radarOsal_memInit(radarOsal_heapConfig *config, uint8_t numHeap);

/*!
   \fn     radarOsal_memDeInit
   \brief   OSAL function for heap memory structure de-initialization.

   \return    RADAROSAL_FAIL if heap deinit failed, RADAROSAL_PASS if heap deinit passed.
   \pre       none
   \post      none
 */
extern int32_t radarOsal_memDeInit(void);

/*!
   \fn     radarOsal_memAlloc
   \brief   OSAL function for memory allocation.

   \param[in]    memoryType
               input radarMemOsal heap type. Definition of the types depends on used platform/OS.

   \param[in]    scratchFlag
               Input flag to indicate whether request memory is a scratch that can be shared across modules. 1 for scratch memory request, and 0 otherwise.

   \param[in]    size
               Request memory size in number of bytes.

   \param[in]    alignment
               Request memory alignment in number of bytes. Alignment has to be power of 2. Alignment = 1 for no alignment requirement.

   \return    NULL if malloc failed, void pointer if malloc passed.
   \pre       none
   \post      none
 */
extern void *radarOsal_memAlloc(uint8_t memoryType, uint8_t scratchFlag, uint32_t size, uint16_t alignment);

/*!
   \fn     radarOsal_memFree
   \brief   OSAL function for memory free.

   \param[in]    ptr
               input poointer to be freed.

   \param[in]    size
               Size of the memory to be freed, in number of bytes .

   \return    none.
   \pre       none
   \post      none
 */
extern void radarOsal_memFree(void *ptr, uint32_t size);


/*!
   \fn     radarOsal_memFree
   \brief   OSAL function to print memory usage for DEMO modules.

   \return    none.
 */
extern void radarOsal_printHeapStats();

#endif //_RADAROSALMALLOC_H
