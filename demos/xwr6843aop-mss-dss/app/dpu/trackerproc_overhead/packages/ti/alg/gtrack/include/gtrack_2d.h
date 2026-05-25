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

#ifdef GTRACK_2D
#ifndef GTRACK_2D_H__
#define GTRACK_2D_H__

#ifdef __cplusplus
extern "C"
{
#endif


    /**
     * @brief
     *  GTRACK Measurement vector
     * @details
     *  The structure defines tracker measurement vector format
     */
    typedef struct
    {
        /**  @brief   Range, m */
        float range;
        /**  @brief   Angle, rad */
        float angle;
        /**  @brief   Radial velocity, m/s */
        float doppler;
    } GTRACK_measurement_vector;

    /**
     * @brief
     *  GTRACK position
     * @details
     *  The structure defines a position in cartesian space
     */
    typedef struct
    {
        /**  @brief   Target lateral position, m */
        float posX;
        /**  @brief   Targte horizontal position, m */
        float posY;
    } GTRACK_cartesian_position;

    /**
     * @brief
     *  GTRACK State vector, 2DV configuration
     * @details
     *  The structure defines tracker state vector format when target position and velocity are tracked
     */
    typedef struct
    {
        /**  @brief   Target lateral position, m */
        float posX;
        /**  @brief   Targte horizontal position, m */
        float posY;
        /**  @brief   Target lateral velocity, m/s */
        float velX;
        /**  @brief   Target horizontal velocity, m/s */
        float velY;
    } GTRACK_state_vector_pos_vel;

    /**
     * @brief
     *  GTRACK State vector, 2DA configuration
     * @details
     *  The structure defines tracker state vector format when target position, velocity and acceleration are tracked
     */
    typedef struct
    {
        /**  @brief   Target lateral position, m */
        float posX;
        /**  @brief   Targte horizontal position, m */
        float posY;
        /**  @brief   Target lateral velocity, m/s */
        float velX;
        /**  @brief   Target horizontal velocity, m/s */
        float velY;
        /**  @brief   Target lateral acceleration, m/s2 */
        float accX;
        /**  @brief   Target horizontal acceleration, m/s2 */
        float accY;
    } GTRACK_state_vector_pos_vel_acc;

#ifdef __cplusplus
}
#endif

#endif
#endif
