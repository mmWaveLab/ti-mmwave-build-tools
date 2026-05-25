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
 *   @file  height_detection.c
 *
 *   @brief
 *      Implements height detection algorithm for each track
 */


#ifdef HEIGHT_DETECTION_ENABLED

/**************************************************************************
 *************************** Include Files ********************************
 **************************************************************************/
#include <dpu/trackerproc_overhead/trackerproc.h>
#include <dpu/trackerproc_overhead/includes/height_detection.h>
void compute_heights(
    heightDet_Target       *targetIDs,
    heightDet_alphaFilter  *heightDetAlphaFilterHandle,
    heightDet_PointCloud   *pointCloud,
    heightDet_TargetHeight *tHeight,
    heightDet_TargetIndex  *targetIndex,
    uint16_t                tNum,
    uint16_t                mNum,
    float                   sensorElevationTiltRad,
    float                   sensorHeightMeter)
{

    float    range, elev, sinElev, cosElev;
    uint16_t topPointsCount, trackCount, pointNum;

    float   *max_height_list_per_track;
    float   *min_height_list_per_track;
    int16_t *record_idx_per_track_max_list;
    int16_t *record_idx_per_track_min_list;
    uint8_t  insertionPointMax, insertionPointMin, bottomUpBufferCounter;
    float    candidate_z_val;
    float    maxZAvg, minZAvg;
    uint8_t  numValidMaxMeasurements, numValidMinMeasurements;

    Tracker_history *Tracker_history_buf = heightDetAlphaFilterHandle->Tracker_history_buf;
    // Array of points, 1st dimension is the track, 2nd dimension is the points, always kept in ascending order of elevation
    float **selected_max_height_point = heightDetAlphaFilterHandle->selected_max_height_point;
    // Array of points, 1st dimension is the track, 2nd dimension is the points, always kept in descending order of elevation
    float **selected_min_height_point = heightDetAlphaFilterHandle->selected_min_height_point;
    // Index where the selected_max_height_points are in the trackerProcObj
    int16_t **record_idx_max_list = heightDetAlphaFilterHandle->record_idx_max_list;
    // Index where the selected_min_height_points are in the trackerProcObj
    int16_t **record_idx_min_list = heightDetAlphaFilterHandle->record_idx_min_list;

    uint16_t maxNumTracks = heightDetAlphaFilterHandle->maxNumTracks;
    uint16_t topNPoints   = heightDetAlphaFilterHandle->topNPoints;

    for (trackCount = 0; trackCount < maxNumTracks; trackCount++)
    {
        for (topPointsCount = 0; topPointsCount < topNPoints; topPointsCount++)
        {
            selected_max_height_point[trackCount][topPointsCount] = -5; // Initialize outside of reasonable range so first points will overwrite it
            selected_min_height_point[trackCount][topPointsCount] = 10; // Initialize outside of reasonable range so first points will overwrite it

            record_idx_max_list[trackCount][topPointsCount] = -1; // Leftover negative numbers mean the list wasn't populated completely because target indexes are only positive
            record_idx_min_list[trackCount][topPointsCount] = -1; // Leftover negative numbers mean the list wasn't populated completely because target indexes are only positive
        }
    }

    for (pointNum = 0; pointNum < mNum; pointNum++) // For each detected point
    {
        if (targetIndex[pointNum] < GTRACK_NUM_TRACKS_MAX) // If the point is assigned to a track
        {
            /* Hold pointers to the correct locations for the current track in the idx/val min/max arrays for easy access */
            max_height_list_per_track     = selected_max_height_point[targetIndex[pointNum]];
            min_height_list_per_track     = selected_min_height_point[targetIndex[pointNum]];
            record_idx_per_track_max_list = record_idx_max_list[targetIndex[pointNum]];
            record_idx_per_track_min_list = record_idx_min_list[targetIndex[pointNum]];

            insertionPointMax = topNPoints; // Index where the new point will be inserted in the max list
            insertionPointMin = topNPoints; // Index where the new point will be inserted in the min list

            elev  = pointCloud[pointNum].elevation - sensorElevationTiltRad; // Extract elevation
            range = pointCloud[pointNum].range; // Extract range
            gtrack_sincosd(elev * RAD2DEGREE, &sinElev, &cosElev); // Compute sin(elev) and cos(elev)
            if (fabs(sinElev) > 1)
            {
                sinElev = 0;
            }
            candidate_z_val = range * sinElev + sensorHeightMeter; // z = rsin(elev) + height

            /*While the height of the incoming point is greater than the height of the points on the current maximum list, find where to insert it*/
            while (insertionPointMax > 0)
            {
                if (candidate_z_val > max_height_list_per_track[insertionPointMax - 1])
                {
                    insertionPointMax--;
                }
                else
                {
                    break;
                }
            }

            if (insertionPointMax != topNPoints) // If the new point gets added to the maximum list
            {
                bottomUpBufferCounter = topNPoints - 1; // Overwrite the maximum list from the bottom up to preserve order
                while (bottomUpBufferCounter > insertionPointMax)
                {
                    max_height_list_per_track[bottomUpBufferCounter]     = max_height_list_per_track[bottomUpBufferCounter - 1]; // Overwrite elements to "pop" final item from list
                    record_idx_per_track_max_list[bottomUpBufferCounter] = record_idx_per_track_max_list[bottomUpBufferCounter - 1];
                    bottomUpBufferCounter--;
                }
                max_height_list_per_track[insertionPointMax]     = candidate_z_val; // Insert new point at correct position to maintain sorted order
                record_idx_per_track_max_list[insertionPointMax] = pointNum; // Insert new point at correct position to maintain sorted order
            }

            /* While the height of the incoming point is greater than the height of the points on the current minimum list */
            while (insertionPointMin > 0)
            {
                if (candidate_z_val < min_height_list_per_track[insertionPointMin - 1])
                {
                    insertionPointMin--;
                }
                else
                {
                    break;
                }
            }

            if (insertionPointMin != topNPoints)
            { // If the new point gets added to the minimum list
                bottomUpBufferCounter = topNPoints - 1; // Overwrite the maximum list from the bottom up to preserve order
                while (bottomUpBufferCounter > insertionPointMin)
                {
                    min_height_list_per_track[bottomUpBufferCounter]     = min_height_list_per_track[bottomUpBufferCounter - 1]; // Overwrite elements to pop final item from list
                    record_idx_per_track_min_list[bottomUpBufferCounter] = record_idx_per_track_min_list[bottomUpBufferCounter - 1];
                    bottomUpBufferCounter--;
                }
                min_height_list_per_track[insertionPointMin]     = candidate_z_val; // Insert new point at correct position to maintain sorted order
                record_idx_per_track_min_list[insertionPointMin] = pointNum; // Insert new point at correct position to maintain sorted order
            }
        }
    }

    uint32_t currentTrack = 0;

    /* For each track, loop through all the min/max points in it to estimate its height*/
    for (trackCount = 0; trackCount < tNum; trackCount++)
    {
        currentTrack = targetIDs[trackCount].tid;

        /* Hold pointers to the correct locations for the current track in the idx/val min/max arrays for easy access*/
        max_height_list_per_track     = selected_max_height_point[currentTrack];
        min_height_list_per_track     = selected_min_height_point[currentTrack];
        record_idx_per_track_max_list = record_idx_max_list[currentTrack];
        record_idx_per_track_min_list = record_idx_min_list[currentTrack];

        maxZAvg = 0;
        minZAvg = 0;

        numValidMaxMeasurements = 0; // Count how many measurements we get for each track since we may not have topNPoints for max and min
        numValidMinMeasurements = 0;

        /* Based off the points in the record_idx_min/max lists, populate the points */
        for (topPointsCount = 0; topPointsCount < topNPoints; topPointsCount++)
        {
            if (record_idx_per_track_max_list[topPointsCount] != -1) // Ignore blank values when there aren't enough points
            {
                ++numValidMaxMeasurements;
                maxZAvg = maxZAvg + max_height_list_per_track[topPointsCount];
            }
            else
            {
                max_height_list_per_track[topPointsCount] = -1;
            }
            if (record_idx_per_track_min_list[topPointsCount] != -1)
            {
                ++numValidMinMeasurements;
                minZAvg = minZAvg + min_height_list_per_track[topPointsCount];
            }
            else
            {
                min_height_list_per_track[topPointsCount] = -1;
            }
        }

        if (numValidMaxMeasurements > 0)
        {
            maxZAvg = maxZAvg / numValidMaxMeasurements;
            if (maxZAvg < 0)
            {
                maxZAvg = 0;
            }
            Tracker_history_buf->Z_HIS[currentTrack].maxZ = maxZAvg;
        }

        if (numValidMinMeasurements > 0)
        {
            minZAvg = minZAvg / numValidMinMeasurements;
            if (minZAvg < 0)
            {
                minZAvg = 0;
            }
            Tracker_history_buf->Z_HIS[currentTrack].minZ = minZAvg;
        }

        /* Update the tracker if we get valid measurements. Otherwise, just keep the measurements from the previous round.*/
        if ((numValidMinMeasurements > 0) && (numValidMaxMeasurements > 0))
        {
            Tracker_history_buf->Z_HIS[currentTrack].maxZ_est = Tracker_history_buf->Z_HIS[currentTrack].maxZ_est * (HEIGHT_DETECTION_ALPHA) + Tracker_history_buf->Z_HIS[currentTrack].maxZ * (1 - HEIGHT_DETECTION_ALPHA);
            Tracker_history_buf->Z_HIS[currentTrack].minZ_est = Tracker_history_buf->Z_HIS[currentTrack].minZ_est * (HEIGHT_DETECTION_ALPHA) + Tracker_history_buf->Z_HIS[currentTrack].minZ * (1 - HEIGHT_DETECTION_ALPHA);
        }

        /* Fill the tHeight structure to be sent out via TLV */
        tHeight[trackCount].tid  = currentTrack;
        tHeight[trackCount].maxZ = Tracker_history_buf->Z_HIS[currentTrack].maxZ_est;
        tHeight[trackCount].minZ = Tracker_history_buf->Z_HIS[currentTrack].minZ_est;
    }
}
#endif
