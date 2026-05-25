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

/**
 *   @file  height_detection.h
 *
 *   @brief
 *      Declares Height Detection Functions and Constants
 */

#ifdef HEIGHT_DETECTION_ENABLED

#ifndef HEIGHT_DETECTION_H
#define HEIGHT_DETECTION_H

#include <dpu/trackerproc_overhead/trackerproc.h>

#define HEIGHT_DETECTION_ALPHA 0.95
#define SELECT_POINT_NUMBER    2
#define PI                     3.14159265358979323846f
#define RAD2DEGREE             57.2957795f // (180.f/PI)

/**
 * @brief
 *  Target Information for each track
 *
 * @details
 *  ID, position, velocity, acceleration, error covariance and other statistics for each track
 */
/* Compatible with trackerProc_Target_t */
typedef struct heightDet_Target_t
{
    /*! @brief   tracking ID */
    uint32_t tid;
    /*! @brief   Detected target X coordinate, in m */
    float posX;
    /*! @brief   Detected target Y coordinate, in m */
    float posY;
    /*! @brief   Detected target Z coordinate, in m */
    float posZ;
    /*! @brief   Detected target X velocity, in m/s */
    float velX;
    /*! @brief   Detected target Y velocity, in m/s */
    float velY;
    /*! @brief   Detected target Z velocity, in m/s */
    float velZ;
    /*! @brief   Detected target X acceleration, in m/s2 */
    float accX;
    /*! @brief   Detected target Y acceleration, in m/s2 */
    float accY;
    /*! @brief   Detected target Z acceleration, in m/s2 */
    float accZ;
    /*! @brief   Target Error covarience matrix, [4x4 float], in row major order, range, azimuth, elev, doppler */
    float ec[16];
    /*! @brief   Gating function gain */
    float g;
    /*! @brief   Tracker confidence metric*/
    float confidenceLevel;
} heightDet_Target;


/*!
 * @brief
 * Structure holds the message body for the Point Cloud
 *
 * @details
 * A copy of the trackerProc_Point_t in trackerproc.h
 */
/* Compatible with GTRACK_measurementPoint */
typedef struct heightDet_PointCloud_t
{
    /*! @brief Detected point range, in m */
    float range;
    /*! @brief Detected point azimuth, in rad */
    float azimuth;
    /*! @brief Detected point elevation, in rad */
#ifdef GTRACK_3D
    float elevation;
#endif
    float doppler;
    /*! @brief Range detection SNR, linear */
    float snr;
} heightDet_PointCloud;

/*!
 * @brief
 * The outputs of the alpha filter than does height detection
 *
 * @details
 * Estiamted minima/maxima for a single track
 */
typedef struct Z_history_value_t
{
    /*! @brief   Estimated maximum Z coordinate from previous frame, in m */
    float maxZ;
    /*! @brief   Estimated minimum Z coordinate from previous frame, in m */
    float minZ;
    /*! @brief   Estimated maximum Z coordinate, in m */
    float maxZ_est;
    /*! @brief   Estimated minimum Z coordinate, in m */
    float minZ_est;
} Z_history_value;

/*!
 * @brief
 * Alpha filter outputs for each track
 *
 * @details
 * A of Z_history_value assigned to the track number trackerID
 */
typedef struct Tracker_history_t
{
    uint8_t         *trackerID;
    Z_history_value *Z_HIS;
} Tracker_history;

/*!
 * @brief
 * Holds the memory needed to runthe height detection algorithm
 *
 * @details
 * Holds the maximum/minimum points for each track, their indices in the
 * point cloud array and the outputs to the alpha filter detection
 */
typedef struct heightDet_alphaFilter_t
{

    Tracker_history *Tracker_history_buf; // History buffer for the tracker heights over multiple frames

    float **selected_max_height_point; // Array of points, 1st dimension is the track, 2nd dimension is the points, always kept in ascending order of elevation
    float **selected_min_height_point; // Array of points, 1st dimension is the track, 2nd dimension is the points, always kept in descending order of elevation

    int16_t **record_idx_max_list; // Index where the selected_max_height_points are in the trackerProcObj
    int16_t **record_idx_min_list; // Index where the selected_min_height_points are in the trackerProcObj

    uint16_t maxNumTracks; // Maximum number of tracks provided by the cfg file
    uint16_t topNPoints; // In each iteration of the alpha filter, average the values from the top N points

} heightDet_alphaFilter;

/*!
 * @brief
 * Holds the output data format of trackid, minimum and maximum z values
 *
 * @details
 * Sent up to the UART for output
 */
typedef struct heightDet_TargetHeight_t
{
    /*! @brief   tracking ID */
    uint32_t tid;
    /*! @brief   Detected maximum Z coordinate, in m */
    float maxZ;
    /*! @brief   Detected minimum Z coordinate, in m */
    float minZ;
} heightDet_TargetHeight;

typedef uint8_t  heightDet_TargetIndex;
typedef uint32_t heightDet_TargetIDs;

void compute_heights(heightDet_Target *targetIDs, heightDet_alphaFilter *heightDetHandle, heightDet_PointCloud *pointCloud, heightDet_TargetHeight *tHeight, heightDet_TargetIndex *targetIndex, uint16_t tNum, uint16_t mNum, float sensorElevationTiltRad, float sensorHeightMeter);

#endif
#endif
