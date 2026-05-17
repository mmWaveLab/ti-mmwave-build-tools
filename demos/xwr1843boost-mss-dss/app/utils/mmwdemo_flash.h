/**
 *   @file  mmwdemo_flash.h
 *
 *   @brief
 *      This is used to abstract the mmWave demo QSPI flash API definitions.
 *
 *  \par
 *  NOTE:
 *      (C) Copyright 2020 Texas Instruments, Inc.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MMWAVEDEMO_FLASH_H
#define MMWAVEDEMO_FLASH_H

#include <ti/demo/utils/mmwdemo_error.h>

#ifdef __cplusplus
extern "C" {
#endif


/***********************************************************************************************
 * mmwDemo Flash module error
 ***********************************************************************************************/

/**
 * @brief   Error Code: Invalid variable
 */
#define MMWDEMO_FLASH_EINVAL     								             (MMWAVE_ERRNO_MMWDEMO_FLASH_BASE-1)

/**
 * @brief   Error Code: receive error when accessing QSPI interface
 */
#define MMWDEMO_FLASH_EINVAL__QSPI        								(MMWAVE_ERRNO_MMWDEMO_FLASH_BASE-2)

/**
 * @brief   Error Code: receive error when accessing QSPI Flash
 */
#define MMWDEMO_FLASH_EINVAL__QSPIFLASH       						(MMWAVE_ERRNO_MMWDEMO_FLASH_BASE-3)

/***********************************************************************************************
 * Flash API: to access QSPI Flash from mmw Demo
 ***********************************************************************************************/
extern int32_t mmwDemo_flashInit(void);
extern int32_t mmwDemo_flashRead(uint32_t flashAddr, uint32_t *readBuf, uint32_t size);
extern int32_t mmwDemo_flashWrite(uint32_t flashAddr, uint32_t *writeBuf, uint32_t size);
extern int32_t mmwDemo_flashEraseOneSector(uint32_t flashAddr);
extern int32_t mmwDemo_flashSetReadMode(void);

#ifdef __cplusplus
}
#endif

#endif /* MMWAVEDEMO_FLASH_H */


