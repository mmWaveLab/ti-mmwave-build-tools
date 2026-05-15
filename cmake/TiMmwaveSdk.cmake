include(CMakeParseArguments)

function(ti_mmwave_to_cmake_path OUT_VAR INPUT_PATH)
    file(TO_CMAKE_PATH "${INPUT_PATH}" _converted)
    set(${OUT_VAR} "${_converted}" PARENT_SCOPE)
endfunction()

function(ti_mmwave_first_existing OUT_VAR)
    foreach(_candidate IN LISTS ARGN)
        if(_candidate AND EXISTS "${_candidate}")
            set(${OUT_VAR} "${_candidate}" PARENT_SCOPE)
            return()
        endif()
    endforeach()
    set(${OUT_VAR} "" PARENT_SCOPE)
endfunction()

function(ti_mmwave_find_tools)
    set(TI_ROOT "C:/ti" CACHE PATH "Root folder containing TI SDK/tool installs")
    set(MMWAVE_SDK_ROOT "${TI_ROOT}/mmwave_sdk_03_06_02_00-LTS" CACHE PATH "mmWave SDK root")
    set(MMWAVE_SDK_PACKAGES "${MMWAVE_SDK_ROOT}/packages" CACHE PATH "mmWave SDK packages folder")
    set(R4F_CODEGEN_ROOT "${TI_ROOT}/ti-cgt-arm_16.9.6.LTS" CACHE PATH "TI ARM codegen root")
    set(C674_CODEGEN_ROOT "${TI_ROOT}/ti-cgt-c6000_8.3.3" CACHE PATH "TI C674 codegen root")
    set(XDC_ROOT "${TI_ROOT}/xdctools_3_50_08_24_core" CACHE PATH "XDCtools root")
    set(BIOS_ROOT "${TI_ROOT}/bios_6_73_01_01" CACHE PATH "SYS/BIOS root")
    set(DSPLIB_C64PX_ROOT "${TI_ROOT}/dsplib_c64Px_3_4_0_0" CACHE PATH "C64Px DSPLIB root")
    set(MATHLIB_C674X_ROOT "${TI_ROOT}/mathlib_c674x_3_1_2_1" CACHE PATH "C674x MATHLIB root")

    set(R4F_CC "${R4F_CODEGEN_ROOT}/bin/armcl.exe" CACHE FILEPATH "TI ARM compiler")
    set(C674_CC "${C674_CODEGEN_ROOT}/bin/cl6x.exe" CACHE FILEPATH "TI C674 compiler")
    set(XS_EXE "${XDC_ROOT}/xs.exe" CACHE FILEPATH "XDC xs executable")
    set(GENERATE_METAIMAGE "${MMWAVE_SDK_PACKAGES}/scripts/windows/generateMetaImage.bat" CACHE FILEPATH "mmWave SDK metaimage script")
    set(RADARSS_IMAGE "${MMWAVE_SDK_ROOT}/firmware/radarss/xwr6xxx_radarss_rprc.bin" CACHE FILEPATH "RadarSS RPRC image")

    foreach(_required MMWAVE_SDK_PACKAGES R4F_CC XS_EXE GENERATE_METAIMAGE RADARSS_IMAGE)
        if(NOT EXISTS "${${_required}}")
            message(FATAL_ERROR "${_required} not found: ${${_required}}")
        endif()
    endforeach()

    set(TI_ROOT "${TI_ROOT}" PARENT_SCOPE)
    set(MMWAVE_SDK_ROOT "${MMWAVE_SDK_ROOT}" PARENT_SCOPE)
    set(MMWAVE_SDK_PACKAGES "${MMWAVE_SDK_PACKAGES}" PARENT_SCOPE)
    set(R4F_CODEGEN_ROOT "${R4F_CODEGEN_ROOT}" PARENT_SCOPE)
    set(C674_CODEGEN_ROOT "${C674_CODEGEN_ROOT}" PARENT_SCOPE)
    set(XDC_ROOT "${XDC_ROOT}" PARENT_SCOPE)
    set(BIOS_ROOT "${BIOS_ROOT}" PARENT_SCOPE)
    set(DSPLIB_C64PX_ROOT "${DSPLIB_C64PX_ROOT}" PARENT_SCOPE)
    set(MATHLIB_C674X_ROOT "${MATHLIB_C674X_ROOT}" PARENT_SCOPE)
    set(R4F_CC "${R4F_CC}" PARENT_SCOPE)
    set(C674_CC "${C674_CC}" PARENT_SCOPE)
    set(XS_EXE "${XS_EXE}" PARENT_SCOPE)
    set(GENERATE_METAIMAGE "${GENERATE_METAIMAGE}" PARENT_SCOPE)
    set(RADARSS_IMAGE "${RADARSS_IMAGE}" PARENT_SCOPE)
endfunction()

function(ti_mmwave_common_env OUT_VAR)
    set(_env
        "MMWAVE_SDK_INSTALL_PATH=${MMWAVE_SDK_PACKAGES}"
        "MMWAVE_SDK_DEVICE=${MMWAVE_SDK_DEVICE}"
        "MMWAVE_SDK_DEVICE_TYPE=${MMWAVE_SDK_DEVICE_TYPE}"
    )
    set(${OUT_VAR} ${_env} PARENT_SCOPE)
endfunction()

function(ti_mmwave_add_rtsc OUT_STAMP CORE CFG OUT_DIR)
    file(MAKE_DIRECTORY "${OUT_DIR}")
    ti_mmwave_common_env(_env)
    if(CORE STREQUAL "mss")
        set(_target "ti.targets.arm.elf.R4Ft")
        set(_platform "ti.platforms.cortexR:IWR68XX:false:200")
        set(_codegen "${R4F_CODEGEN_ROOT}")
    else()
        set(_target "ti.targets.elf.C674")
        set(_platform "ti.platforms.c6x:IWR68XX:false:600")
        set(_codegen "${C674_CODEGEN_ROOT}")
    endif()

    set(_stamp "${OUT_DIR}/rtsc.stamp")
    add_custom_command(
        OUTPUT "${_stamp}"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${OUT_DIR}/configPkg"
        COMMAND "${CMAKE_COMMAND}"
            "-DXS_EXE=${XS_EXE}"
            "-DBIOS_PACKAGES=${BIOS_ROOT}/packages"
            "-DMMWAVE_SDK_PACKAGES=${MMWAVE_SDK_PACKAGES}"
            "-DMMWAVE_SDK_DEVICE=${MMWAVE_SDK_DEVICE}"
            "-DMMWAVE_SDK_DEVICE_TYPE=${MMWAVE_SDK_DEVICE_TYPE}"
            "-DCFG_FILE=${CFG}"
            "-DOUT_DIR=${OUT_DIR}/configPkg"
            "-DTARGET_NAME=${_target}"
            "-DPLATFORM_NAME=${_platform}"
            "-DCODEGEN_ROOT=${_codegen}"
            "-DCORE=${CORE}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/RunConfiguro.cmake"
        COMMAND "${CMAKE_COMMAND}" -E touch "${_stamp}"
        DEPENDS "${CFG}"
        WORKING_DIRECTORY "${OUT_DIR}"
        VERBATIM
        COMMENT "Configuring ${CORE} SYS/BIOS package"
    )
    set(${OUT_STAMP} "${_stamp}" PARENT_SCOPE)
endfunction()

function(ti_mmwave_add_compile_objects OUT_VAR CORE OUT_DIR)
    set(options)
    set(oneValueArgs CONFIG_STAMP)
    set(multiValueArgs SOURCES FLAGS INCLUDES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    file(MAKE_DIRECTORY "${OUT_DIR}/obj")
    set(_objects)
    foreach(_src IN LISTS ARG_SOURCES)
        if(NOT EXISTS "${_src}")
            message(FATAL_ERROR "Source not found: ${_src}")
        endif()
        get_filename_component(_name "${_src}" NAME_WE)
        if(CORE STREQUAL "mss")
            set(_obj "${OUT_DIR}/obj/${_name}.oer4f")
            set(_cc "${R4F_CC}")
        else()
            set(_obj "${OUT_DIR}/obj/${_name}.oe674")
            set(_cc "${C674_CC}")
        endif()

        set(_include_flags)
        foreach(_inc IN LISTS ARG_INCLUDES)
            list(APPEND _include_flags "-i${_inc}")
        endforeach()

        add_custom_command(
            OUTPUT "${_obj}"
            COMMAND "${_cc}" -c ${ARG_FLAGS} ${_include_flags} "${_src}" "--output_file=${_obj}"
            DEPENDS "${_src}" "${ARG_CONFIG_STAMP}"
            WORKING_DIRECTORY "${OUT_DIR}"
            VERBATIM
            COMMENT "Compiling ${CORE}: ${_name}"
        )
        list(APPEND _objects "${_obj}")
    endforeach()
    set(${OUT_VAR} ${_objects} PARENT_SCOPE)
endfunction()

function(ti_mmwave_add_mss_image)
    set(options)
    set(oneValueArgs TARGET OUTPUT CONFIG LINKER)
    set(multiValueArgs SOURCES INCLUDES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_filename_component(_out_dir "${ARG_OUTPUT}" DIRECTORY)
    ti_mmwave_add_rtsc(_rtsc_stamp mss "${ARG_CONFIG}" "${_out_dir}")
    set(MMWAVE_APP_RESOURCE_FILE "<ti/demo/xwr68xx/mmw/mmw_res.h>" CACHE STRING "APP_RESOURCE_FILE macro value")
    set(MMWAVE_BOARD_DEFINE "ISK" CACHE STRING "Board define passed to TI compiler")
    if(NOT DEFINED MMWAVE_EXTRA_DEFINES)
        set(MMWAVE_EXTRA_DEFINES)
    endif()
    set(_flags
        -mv7R4 --code_state=16 --float_support=VFPv3D16 --abi=eabi -me
        --define=SUBSYS_MSS
        --define=SOC_XWR68XX
        "--define=${MMWAVE_BOARD_DEFINE}"
        --define=_LITTLE_ENDIAN
        --define=DebugP_ASSERT_ENABLED
        --define=DebugP_LOG_ENABLED
        "--define=MMWAVE_L3RAM_NUM_BANK=${MMWAVE_L3RAM_NUM_BANK}"
        "--define=MMWAVE_SHMEM_TCMA_NUM_BANK=${MMWAVE_SHMEM_TCMA_NUM_BANK}"
        "--define=MMWAVE_SHMEM_TCMB_NUM_BANK=${MMWAVE_SHMEM_TCMB_NUM_BANK}"
        "--define=MMWAVE_SHMEM_BANK_SIZE=${MMWAVE_SHMEM_BANK_SIZE}"
        "--define=APP_RESOURCE_FILE=${MMWAVE_APP_RESOURCE_FILE}"
        -g -O3 --display_error_number --diag_warning=225 --diag_wrap=off
        --little_endian --preproc_with_compile --gen_func_subsections --enum_type=int
        "--cmd_file=${_out_dir}/configPkg/compiler.opt"
        "-i${MMWAVE_SDK_PACKAGES}"
        "-i${R4F_CODEGEN_ROOT}/include"
    )
    if(MMWAVE_DOWNLOAD_FROM_CCS)
        list(APPEND _flags --define=DOWNLOAD_FROM_CCS)
    endif()
    foreach(_define IN LISTS MMWAVE_EXTRA_DEFINES)
        list(APPEND _flags "--define=${_define}")
    endforeach()

    ti_mmwave_add_compile_objects(_objects mss "${_out_dir}"
        CONFIG_STAMP "${_rtsc_stamp}"
        FLAGS ${_flags}
        INCLUDES ${ARG_INCLUDES}
        SOURCES ${ARG_SOURCES}
    )

    set(_lib_paths
        "-i${R4F_CODEGEN_ROOT}/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/control/mmwave/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/control/mmwavelink/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/control/dpm/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/adcbuf/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/crc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/dma/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/edma/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/esm/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/gpio/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/hwa/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/mailbox/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/osal/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/pinmux/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/qspi/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/qspiflash/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/soc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/uart/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/utils/cli/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/utils/mathutils/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpu/rangeproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/dopplerproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/cfarcaproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/aoa2dproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/staticclutterproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpedma/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/cbuff/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/utils/hsiheader/lib"
    )
    set(_libs
        -llibosal_xwr68xx.aer4f -llibesm_xwr68xx.aer4f -llibgpio_xwr68xx.aer4f
        -llibsoc_xwr68xx.aer4f -llibpinmux_xwr68xx.aer4f -llibcrc_xwr68xx.aer4f
        -llibuart_xwr68xx.aer4f -llibmailbox_xwr68xx.aer4f -llibmmwavelink_xwr68xx.aer4f
        -llibmmwave_xwr68xx.aer4f -llibadcbuf_xwr68xx.aer4f -llibdma_xwr68xx.aer4f
        -llibedma_xwr68xx.aer4f -llibcli_xwr68xx.aer4f -llibhwa_xwr68xx.aer4f
        -llibdpm_xwr68xx.aer4f -llibmathutils.aer4f -llibcbuff_xwr68xx.aer4f
        -llibhsiheader_xwr68xx.aer4f -llibrangeproc_hwa_xwr68xx.aer4f
        -llibdopplerproc_hwa_xwr68xx.aer4f -llibcfarcaproc_hwa_xwr68xx.aer4f
        -llibaoa2dproc_hwa_xwr68xx.aer4f -llibstaticclutterproc_xwr68xx.aer4f
        -llibdpedma_hwa_xwr68xx.aer4f -llibqspi_xwr68xx.aer4f
        -llibqspiflash_xwr68xx.aer4f -lrtsv7R4_T_le_v3D16_eabi.lib -llibc.a
    )

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        COMMAND "${R4F_CC}"
            -mv7R4 --code_state=16 --float_support=VFPv3D16 --abi=eabi -me -g
            --display_error_number --diag_warning=225 --diag_wrap=off -z
            --reread_libs --warn_sections --rom_model --unused_section_elimination
            "--define=MMWAVE_L3RAM_NUM_BANK=${MMWAVE_L3RAM_NUM_BANK}"
            "--define=MMWAVE_SHMEM_TCMA_NUM_BANK=${MMWAVE_SHMEM_TCMA_NUM_BANK}"
            "--define=MMWAVE_SHMEM_TCMB_NUM_BANK=${MMWAVE_SHMEM_TCMB_NUM_BANK}"
            "--define=MMWAVE_SHMEM_BANK_SIZE=${MMWAVE_SHMEM_BANK_SIZE}"
            ${_lib_paths}
            "-l${_out_dir}/configPkg/linker.cmd"
            "--map_file=${_out_dir}/${ARG_TARGET}.map"
            ${_objects}
            "${MMWAVE_SDK_PACKAGES}/ti/platform/xwr68xx/r4f_linker.cmd"
            "${ARG_LINKER}"
            ${_libs}
            "-o=${ARG_OUTPUT}"
        DEPENDS ${_objects} "${ARG_LINKER}" "${_rtsc_stamp}"
        WORKING_DIRECTORY "${_out_dir}"
        VERBATIM
        COMMENT "Linking MSS image"
    )
    add_custom_target(${ARG_TARGET} DEPENDS "${ARG_OUTPUT}")
endfunction()

function(ti_mmwave_add_dss_image)
    set(options)
    set(oneValueArgs TARGET OUTPUT CONFIG LINKER)
    set(multiValueArgs SOURCES INCLUDES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT EXISTS "${C674_CC}")
        message(FATAL_ERROR "C674 compiler not found: ${C674_CC}")
    endif()

    get_filename_component(_out_dir "${ARG_OUTPUT}" DIRECTORY)
    ti_mmwave_add_rtsc(_rtsc_stamp dss "${ARG_CONFIG}" "${_out_dir}")
    set(MMWAVE_APP_RESOURCE_FILE "<ti/demo/xwr68xx/mmw/mmw_res.h>" CACHE STRING "APP_RESOURCE_FILE macro value")
    if(NOT DEFINED MMWAVE_EXTRA_DEFINES)
        set(MMWAVE_EXTRA_DEFINES)
    endif()
    set(_flags
        -mv6740 --abi=eabi --gcc -g -O3 -mf3 -mo
        --define=SUBSYS_DSS --define=SOC_XWR68XX "--define=${MMWAVE_BOARD_DEFINE}"
        --define=_LITTLE_ENDIAN --display_error_number --define=DebugP_ASSERT_ENABLED
        --define=DebugP_LOG_ENABLED --diag_warning=225 --diag_wrap=off --preproc_with_compile
        "--define=MMWAVE_L3RAM_NUM_BANK=${MMWAVE_L3RAM_NUM_BANK}"
        "--define=MMWAVE_SHMEM_BANK_SIZE=${MMWAVE_SHMEM_BANK_SIZE}"
        "--define=APP_RESOURCE_FILE=${MMWAVE_APP_RESOURCE_FILE}"
        "--cmd_file=${_out_dir}/configPkg/compiler.opt"
        "-i${MMWAVE_SDK_PACKAGES}"
        "-i${C674_CODEGEN_ROOT}/include"
        "-i${MATHLIB_C674X_ROOT}/packages"
        "-i${DSPLIB_C64PX_ROOT}/packages/ti/dsplib/src/DSP_fft16x16_imre/c64P"
        "-i${DSPLIB_C64PX_ROOT}/packages/ti/dsplib/src/DSP_fft32x32/c64P"
    )
    foreach(_define IN LISTS MMWAVE_EXTRA_DEFINES)
        list(APPEND _flags "--define=${_define}")
    endforeach()

    ti_mmwave_add_compile_objects(_objects dss "${_out_dir}"
        CONFIG_STAMP "${_rtsc_stamp}"
        FLAGS ${_flags}
        INCLUDES ${ARG_INCLUDES}
        SOURCES ${ARG_SOURCES}
    )

    set(_lib_paths
        "-i${C674_CODEGEN_ROOT}/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/osal/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/soc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/crc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/mailbox/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/drivers/edma/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/alg/mmwavelib/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/control/dpm/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/utils/mathutils/lib"
        "-i${MATHLIB_C674X_ROOT}/packages/ti/mathlib/lib"
        "-i${DSPLIB_C64PX_ROOT}/packages/ti/dsplib/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/dopplerproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/cfarcaproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpc/dpu/aoaproc/lib"
        "-i${MMWAVE_SDK_PACKAGES}/ti/datapath/dpedma/lib"
    )
    set(_libs
        -llibosal_xwr68xx.ae674 -libsoc_xwr68xx.ae674 -llibcrc_xwr68xx.ae674
        -llibmailbox_xwr68xx.ae674 -ldsplib.ae64P -llibmmwavealg_xwr68xx.ae674
        -lmathlib.ae674 -llibedma_xwr68xx.ae674 -llibdpm_xwr68xx.ae674
        -llibmathutils.ae674 -llibcfarcaproc_dsp_xwr68xx.ae674
        -llibdopplerproc_dsp_xwr68xx.ae674 -llibaoaproc_dsp_xwr68xx.ae674
        -llibdpedma_hwa_xwr68xx.ae674 -lrts6740_elf.lib
    )

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        COMMAND "${C674_CC}"
            -mv6740 --abi=eabi -g --define=SOC_XWR68XX "--define=${MMWAVE_BOARD_DEFINE}"
            --display_error_number --diag_warning=225 --diag_wrap=off -z
            --reread_libs --warn_sections --ram_model "--define=MMWAVE_L3RAM_NUM_BANK=${MMWAVE_L3RAM_NUM_BANK}"
            "--define=MMWAVE_SHMEM_BANK_SIZE=${MMWAVE_SHMEM_BANK_SIZE}"
            ${_lib_paths}
            "-l${_out_dir}/configPkg/linker.cmd"
            "--map_file=${_out_dir}/${ARG_TARGET}.map"
            ${_objects}
            "${MMWAVE_SDK_PACKAGES}/ti/platform/xwr68xx/c674x_linker.cmd"
            "${ARG_LINKER}"
            ${_libs}
            "-o=${ARG_OUTPUT}"
        DEPENDS ${_objects} "${ARG_LINKER}" "${_rtsc_stamp}"
        WORKING_DIRECTORY "${_out_dir}"
        VERBATIM
        COMMENT "Linking DSS image"
    )
    add_custom_target(${ARG_TARGET} DEPENDS "${ARG_OUTPUT}")
endfunction()

function(ti_mmwave_add_metaimage)
    set(options)
    set(oneValueArgs TARGET OUTPUT MSS_IMAGE DSS_IMAGE)
    set(multiValueArgs DEPENDS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_filename_component(_out_dir "${ARG_OUTPUT}" DIRECTORY)
    set(_file_deps "${ARG_MSS_IMAGE}" "${RADARSS_IMAGE}")
    if(NOT ARG_DSS_IMAGE STREQUAL "NULL")
        list(APPEND _file_deps "${ARG_DSS_IMAGE}")
    endif()
    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        COMMAND "${CMAKE_COMMAND}"
            "-DMMWAVE_SDK_PACKAGES=${MMWAVE_SDK_PACKAGES}"
            "-DOUTPUT_IMAGE=${ARG_OUTPUT}"
            "-DSHMEM_ALLOC=${MMWAVE_SHMEM_ALLOC}"
            "-DMSS_IMAGE=${ARG_MSS_IMAGE}"
            "-DRADARSS_IMAGE=${RADARSS_IMAGE}"
            "-DDSS_IMAGE=${ARG_DSS_IMAGE}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/RunMetaImage.cmake"
        DEPENDS ${_file_deps}
        WORKING_DIRECTORY "${_out_dir}"
        VERBATIM
        COMMENT "Generating flashable metaimage"
    )
    add_custom_target(${ARG_TARGET} DEPENDS "${ARG_OUTPUT}")
    if(ARG_DEPENDS)
        add_dependencies(${ARG_TARGET} ${ARG_DEPENDS})
    endif()
endfunction()
