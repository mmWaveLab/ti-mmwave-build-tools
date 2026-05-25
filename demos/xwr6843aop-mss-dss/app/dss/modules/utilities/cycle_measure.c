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

#include <dpu/capon3d/modules/utilities/cycle_measure.h>
#include <time.h>

#ifdef _TMS320C6X
#define L1PConfRegAddr  0x1840020
#define L1DConfRegAddr  0x1840040
#define L2ConfRegAddr   0x1840000
#define L1DWBINVRegAddr 0x1845044

void cache_setL1PSize(int cacheConf)
{
    *((int *)L1PConfRegAddr) &= 0xFFFFFFF8;
    *((int *)L1PConfRegAddr) |= cacheConf;
}

void cache_setL1DSize(int cacheConf)
{
    *((int *)L1DConfRegAddr) &= 0xFFFFFFF8;
    *((int *)L1DConfRegAddr) |= cacheConf;
}

void cache_setL2Size(int cacheConf)
{
    *((int *)L2ConfRegAddr) &= 0xFFFFFFF8;
    *((int *)L2ConfRegAddr) |= cacheConf;
}

void cache_wbInvAllL2Wait()
{
    *((int *)L1DWBINVRegAddr) |= 0x1;
#ifdef _TMS320C6600
    asm(" MFENCE");
    asm(" NOP 4");
    asm(" NOP 4");
    asm(" NOP 4");
    asm(" NOP 4");
#endif
}


void startClock()
{
    TSCL = 0;
}


int ranClock()
{
    return (TSCL);
}

double getCPUTime()
{
    return 0;
}

void cache_setMar(unsigned int *baseAddr, unsigned int byteSize, unsigned int value)
{
    unsigned int           maxAddr;
    unsigned int           firstMar, lastMar;
    unsigned int           marNum;
    volatile unsigned int *marBase = (unsigned int *)MAR;

    /* caculate the maximum address */
    maxAddr = (unsigned int)baseAddr + (byteSize - 1);

    /* range of MAR's that need to be modified */
    firstMar = (unsigned int)baseAddr >> 24;
    lastMar  = (unsigned int)maxAddr >> 24;

    /* write back invalidate all cached entries */
    cache_wbInvAllL2Wait();

    /* loop through the number of MAR registers affecting the address range */
    for (marNum = firstMar; marNum <= lastMar; marNum++)
    {
        /* set the MAR registers to the specified value */
        marBase[marNum] = value;
    }
}

#else
#ifdef _WIN32
int ranClock()
{
    int x1;
    x1 = (int)__rdtsc();

    return (x1);
}


void cache_setL1PSize(int cacheConf)
{
}

void cache_setL1DSize(int cacheConf)
{
}

void cache_setL2Size(int cacheConf)
{
}

void cache_wbInvAllL2Wait()
{
}

void startClock()
{
}

void cache_setMar(unsigned int *baseAddr, unsigned int byteSize, unsigned int value)
{
}


/**
 * Returns the amount of CPU time used by the current process, in miliseconds
 */
double getCPUTime()
{
    FILETIME createTime;
    FILETIME exitTime;
    FILETIME kernelTime;
    FILETIME userTime;
    if (GetProcessTimes(GetCurrentProcess(),
                        &createTime,
                        &exitTime,
                        &kernelTime,
                        &userTime) != -1)
    {
        SYSTEMTIME userSystemTime;
        if (FileTimeToSystemTime(&userTime, &userSystemTime) != -1)
            return (double)userSystemTime.wSecond * 1000.0 +
                (double)userSystemTime.wMilliseconds;
    }
    return 0;
}


void touch(
    void *m, /* Pointer to vector  */
    int   num_bytes /* Length of vector in bytes      */
)
{
    return;
}


#endif
#endif
