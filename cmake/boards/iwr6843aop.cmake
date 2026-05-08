include_guard(GLOBAL)

set(MMWAVE_BOARD_DEFINE "AOP" CACHE STRING "Board define passed to TI compiler")
set(MMWAVE_EXTRA_DEFINES
    XWR68XX_AOP_ANTENNA_PATTERN
    USE_2D_AOA_DPU
    AOP
    CACHE STRING "Board-specific preprocessor defines"
)
