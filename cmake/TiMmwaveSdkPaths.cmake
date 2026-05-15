set(TI_ROOT "$ENV{TI_ROOT}" CACHE PATH "TI SDK/tool root")
if(NOT TI_ROOT)
  set(TI_ROOT "/opt/ti" CACHE PATH "TI SDK/tool root" FORCE)
endif()

set(MMWAVE_SDK_ROOT "${TI_ROOT}/mmwave_sdk_03_06_02_00-LTS" CACHE PATH "mmWave SDK root")
set(MMWAVE_SDK_PACKAGES "${MMWAVE_SDK_ROOT}/packages" CACHE PATH "mmWave SDK packages folder")
set(R4F_CODEGEN_ROOT "${TI_ROOT}/ti-cgt-arm_16.9.6.LTS" CACHE PATH "TI ARM CGT root")
set(C674_CODEGEN_ROOT "${TI_ROOT}/ti-cgt-c6000_8.3.3" CACHE PATH "TI C6000 CGT root")
set(XDC_ROOT "${TI_ROOT}/xdctools_3_50_08_24_core" CACHE PATH "XDCtools root")
set(BIOS_ROOT "${TI_ROOT}/bios_6_73_01_01" CACHE PATH "SYS/BIOS root")
set(DSPLIB_C64PX_ROOT "${TI_ROOT}/dsplib_c64Px_3_4_0_0" CACHE PATH "C64Px DSPLIB root")
set(DSPLIB_C674X_ROOT "${TI_ROOT}/dsplib_c674x_3_4_0_0" CACHE PATH "C674x DSPLIB root")
set(MATHLIB_C674X_ROOT "${TI_ROOT}/mathlib_c674x_3_1_2_1" CACHE PATH "C674x MATHLIB root")

set(R4F_CC "${R4F_CODEGEN_ROOT}/bin/armcl" CACHE FILEPATH "TI ARM compiler")
set(C674_CC "${C674_CODEGEN_ROOT}/bin/cl6x" CACHE FILEPATH "TI C674 compiler")
set(XS_EXE "${XDC_ROOT}/xs" CACHE FILEPATH "XDC xs executable")
set(GENERATE_METAIMAGE "${MMWAVE_SDK_PACKAGES}/scripts/unix/generateMetaImage.sh" CACHE FILEPATH "mmWave SDK Linux metaimage script")
set(RADARSS_IMAGE "${MMWAVE_SDK_ROOT}/firmware/radarss/xwr6xxx_radarss_rprc.bin" CACHE FILEPATH "RadarSS RPRC image")

set(TI_MMWAVE_REQUIRED_PATHS
  "${MMWAVE_SDK_PACKAGES}"
  "${GENERATE_METAIMAGE}"
  "${RADARSS_IMAGE}"
  "${R4F_CC}"
  "${C674_CC}"
  "${XS_EXE}"
  "${BIOS_ROOT}/packages"
  "${DSPLIB_C64PX_ROOT}/packages"
  "${DSPLIB_C674X_ROOT}/packages"
  "${MATHLIB_C674X_ROOT}/packages"
)

foreach(path IN LISTS TI_MMWAVE_REQUIRED_PATHS)
  if(NOT EXISTS "${path}")
    message(FATAL_ERROR "Required TI SDK path not found: ${path}")
  endif()
endforeach()
