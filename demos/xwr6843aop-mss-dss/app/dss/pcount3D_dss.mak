###################################################################################
# 3D People Tracking DSS
###################################################################################
.PHONY: dssDemo dssDemoClean

vpath %.c ./dss \
          ./dss/modules/caponBF2D/src \
          ./dss/modules/detection/CFAR/src \
          ./dss/modules/postProcessing/matrixFunc/src \
          ./dss/modules/utilities

PCOUNT3D_DSS_COMMON_DEFS = \
	--define=SOC_XWR68XX \
	--define=SUBSYS_DSS \
	--define=PLATFORMES2 \
	--define=MMWAVE_L3RAM_NUM_BANK=6 \
	--define=MMWAVE_SHMEM_TCMA_NUM_BANK=0 \
	--define=MMWAVE_SHMEM_TCMB_NUM_BANK=0 \
	--define=MMWAVE_SHMEM_BANK_SIZE=0x20000 \
	--define=MMWAVE_L3_CODEMEM_SIZE=0x100 \
	--define=MMWAVE_MSSUSED_L3RAM_SIZE=0x90000 \
	--define=DOWNLOAD_FROM_CCS \
	--define=DebugP_ASSERT_ENABLED \
	--define=_LITTLE_ENDIAN \
	--define=OBJDET_NO_RANGE \
	--define=GTRACK_3D \
	--define=WALL_MOUNT_CONFIG \
	--define=APP_RESOURCE_FILE="<pcount3D_hwres.h>"

DSS_PCOUNT3D_STD_LIBS = $(C674_COMMON_STD_LIB) \
	-llibcrc_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibmailbox_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-ldsplib.ae64P \
	-lmathlib.$(C674_LIB_EXT) \
	-llibmathutils.$(C674_LIB_EXT) \
	-llibmmwavealg_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibsoc_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibosal_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibmmwavelink_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibmmwave_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibedma_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibadcbuf_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibcbuff_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibhsiheader_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibdpm_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT) \
	-llibdpedma_hwa_$(MMWAVE_SDK_DEVICE_TYPE).$(C674_LIB_EXT)

DSS_PCOUNT3D_LOC_LIBS = $(C674_COMMON_LOC_LIB) \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/crc/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/mailbox/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/alg/mmwavelib/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/mathutils/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/soc/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/osal/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/mmwavelink/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/mmwave/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/edma/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/adcbuf/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/cbuff/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/hsiheader/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/dpm/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/datapath/dpedma/lib \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/lib \
	-i$(C674x_MATHLIB_INSTALL_PATH)/packages/ti/mathlib/lib \
	-i$(C674x_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/lib

DSS_PCOUNT3D_CFG_PREFIX = pcount3D_dss
DSS_PCOUNT3D_CFG       = $(DSS_PCOUNT3D_CFG_PREFIX).cfg
DSS_PCOUNT3D_ROV_XS    = $(DSS_PCOUNT3D_CFG_PREFIX)_$(C674_XS_SUFFIX).rov.xs
DSS_PCOUNT3D_CONFIGPKG = pcount3D_configPkg_dss_$(MMWAVE_SDK_DEVICE_TYPE)
DSS_PCOUNT3D_MAP       = 3D_people_track_6843_dss.map
DSS_PCOUNT3D_OUT       = 3D_people_track_6843_dss.$(C674_EXE_EXT)
DSS_PCOUNT3D_CMD       = dss/pcount3D_dss_linker.cmd
DSS_PCOUNT3D_SOURCES   = \
	copyTranspose.c \
	dss_main.c \
	objectdetection.c \
	radarProcess.c \
	cycle_measure.c \
	radarOsal_malloc.c \
	RADARDEMO_aoaEst2DCaponBF.c \
	RADARDEMO_aoaEst2DCaponBF_DopplerEst.c \
	RADARDEMO_aoaEst2DCaponBF_angleEst.c \
	RADARDEMO_aoaEst2DCaponBF_bpmDecoding.c \
	RADARDEMO_aoaEst2DCaponBF_heatmapEst.c \
	RADARDEMO_aoaEst2DCaponBF_rnEstInv.c \
	RADARDEMO_aoaEst2DCaponBF_staticHeatMapEst.c \
	RADARDEMO_aoaEst2DCaponBF_staticRemoval.c \
	RADARDEMO_aoaEst2DCaponBF_utils.c \
	RADARDEMO_detectionCFAR.c \
	RADARDEMO_detectionCFAR_priv.c \
	MATRIX_cholesky.c \
	MATRIX_cholesky_dat.c

DSS_PCOUNT3D_DEPENDS = $(addprefix $(PLATFORM_OBJDIR)/, $(DSS_PCOUNT3D_SOURCES:.c=.$(C674_DEP_EXT)))
DSS_PCOUNT3D_OBJECTS = $(addprefix $(PLATFORM_OBJDIR)/, $(DSS_PCOUNT3D_SOURCES:.c=.$(C674_OBJ_EXT)))

pcount3DDssRTSC:
	@echo 'Configuring DSS RTSC packages...'
	$(XS) --xdcpath="$(XDCPATH)" xdc.tools.configuro $(C674_XSFLAGS) -o $(DSS_PCOUNT3D_CONFIGPKG) dss/$(DSS_PCOUNT3D_CFG)
	@echo 'Finished configuring DSS packages'
	@echo ' '

dssDemo: BUILD_CONFIGPKG=$(DSS_PCOUNT3D_CONFIGPKG)
dssDemo: C674_CFLAGS += --cmd_file=$(BUILD_CONFIGPKG)/compiler.opt \
	-i. \
	-idss \
	-idss/modules/caponBF2D/src \
	-idss/modules/detection/CFAR/src \
	-i$(C674x_MATHLIB_INSTALL_PATH)/packages \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages \
	-i$(C674x_DSPLIB_INSTALL_PATH)/packages \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/src/DSP_fft16x16_imre/c64P \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/src/DSP_fft32x32/c64P \
	$(PCOUNT3D_DSS_COMMON_DEFS)
dssDemo: buildDirectories pcount3DDssRTSC $(DSS_PCOUNT3D_OBJECTS)
	$(C674_LD) $(C674_LDFLAGS) $(DSS_PCOUNT3D_LOC_LIBS) $(DSS_PCOUNT3D_STD_LIBS) \
	-l$(DSS_PCOUNT3D_CONFIGPKG)/linker.cmd --map_file=$(DSS_PCOUNT3D_MAP) $(DSS_PCOUNT3D_OBJECTS) \
	$(PLATFORM_C674X_LINK_CMD) $(DSS_PCOUNT3D_CMD) $(PCOUNT3D_DSS_COMMON_DEFS) $(C674_LD_RTS_FLAGS) -o $(DSS_PCOUNT3D_OUT)
	$(COPY_CMD) $(DSS_PCOUNT3D_CONFIGPKG)/package/cfg/$(DSS_PCOUNT3D_ROV_XS) $(DSS_PCOUNT3D_ROV_XS)
	@echo 'Built DSS for 3D People Tracking'

dssDemoClean:
	@echo 'Cleaning 3D People Tracking DSS objects'
	@rm -f $(DSS_PCOUNT3D_OBJECTS) $(DSS_PCOUNT3D_MAP) $(DSS_PCOUNT3D_OUT) $(DSS_PCOUNT3D_DEPENDS) $(DSS_PCOUNT3D_ROV_XS)
	@$(DEL) $(DSS_PCOUNT3D_CONFIGPKG)
	@$(DEL) $(PLATFORM_OBJDIR)

-include $(DSS_PCOUNT3D_DEPENDS)
