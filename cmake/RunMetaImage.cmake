foreach(_var MMWAVE_SDK_PACKAGES OUTPUT_IMAGE SHMEM_ALLOC MSS_IMAGE RADARSS_IMAGE)
    if(NOT DEFINED ${_var})
        message(FATAL_ERROR "${_var} is required")
    endif()
endforeach()

set(_out2rprc "${MMWAVE_SDK_PACKAGES}/scripts/ImageCreator/out2rprc/out2rprc.exe")
set(_multicore "${MMWAVE_SDK_PACKAGES}/scripts/ImageCreator/multicore_image_generator/MulticoreImageGen.exe")
set(_crc_multi "${MMWAVE_SDK_PACKAGES}/scripts/ImageCreator/crc_multicore_image/crc_multicore_image.exe")
set(_crc_append "${MMWAVE_SDK_PACKAGES}/scripts/ImageCreator/append_bin_crc/gen_bincrc32.exe")

foreach(_tool _out2rprc _multicore _crc_multi _crc_append)
    if(NOT EXISTS "${${_tool}}")
        message(FATAL_ERROR "ImageCreator tool not found: ${${_tool}}")
    endif()
endforeach()

get_filename_component(_out_dir "${OUTPUT_IMAGE}" DIRECTORY)
get_filename_component(_mss_name "${MSS_IMAGE}" NAME_WE)
set(_mss_rprc "${_out_dir}/${_mss_name}.rprc.bin")
set(_tmp_image "${OUTPUT_IMAGE}.tmp")
file(REMOVE "${OUTPUT_IMAGE}" "${_mss_rprc}" "${_tmp_image}")

execute_process(
    COMMAND "${_out2rprc}" "${MSS_IMAGE}" "${_mss_rprc}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "out2rprc failed for MSS image with exit code ${_result}")
endif()

set(_image_args LE 37 "${SHMEM_ALLOC}" "${OUTPUT_IMAGE}" 0x35510000 "${_mss_rprc}")

if(EXISTS "${RADARSS_IMAGE}")
    list(APPEND _image_args 0xb5510000 "${RADARSS_IMAGE}")
endif()

if(DEFINED DSS_IMAGE AND NOT DSS_IMAGE STREQUAL "NULL" AND EXISTS "${DSS_IMAGE}")
    get_filename_component(_dss_name "${DSS_IMAGE}" NAME_WE)
    set(_dss_rprc "${_out_dir}/${_dss_name}.rprc.bin")
    file(REMOVE "${_dss_rprc}")
    execute_process(
        COMMAND "${_out2rprc}" "${DSS_IMAGE}" "${_dss_rprc}"
        RESULT_VARIABLE _result
    )
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "out2rprc failed for DSS image with exit code ${_result}")
    endif()
    list(APPEND _image_args 0xd5510000 "${_dss_rprc}")
endif()

execute_process(
    COMMAND "${_multicore}" ${_image_args}
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "MulticoreImageGen failed with exit code ${_result}")
endif()

execute_process(
    COMMAND "${_crc_multi}" "${OUTPUT_IMAGE}" "${_tmp_image}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "crc_multicore_image failed with exit code ${_result}")
endif()

execute_process(
    COMMAND "${_crc_append}" "${OUTPUT_IMAGE}"
    RESULT_VARIABLE _result
)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "gen_bincrc32 failed with exit code ${_result}")
endif()

file(REMOVE "${_mss_rprc}" "${_tmp_image}")
if(DEFINED _dss_rprc)
    file(REMOVE "${_dss_rprc}")
endif()

if(NOT EXISTS "${OUTPUT_IMAGE}")
    message(FATAL_ERROR "Metaimage was not generated: ${OUTPUT_IMAGE}")
endif()
