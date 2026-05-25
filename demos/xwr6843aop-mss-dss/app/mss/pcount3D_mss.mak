###################################################################################
# 3D People Tracking MSS
###################################################################################
.PHONY: mssDemo mssDemoClean

vpath %.c ./common \
          ./mss \
          .

PCOUNT3D_COMMON_DEFS = \
	--define=SOC_XWR68XX \
	--define=SUBSYS_MSS \
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
	--define=TRACKERPROC_EN \
	--define=GTRACK_3D \
	--define=WALL_MOUNT_CONFIG \
	--define=HEIGHT_DETECTION_ENABLED \
	--define=APP_RESOURCE_FILE="<pcount3D_hwres.h>"

MSS_PCOUNT3D_STD_LIBS = $(R4F_COMMON_STD_LIB) \
	-llibosal_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibesm_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibgpio_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibsoc_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibpinmux_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibcrc_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibuart_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibmailbox_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibmmwavelink_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibmmwave_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibadcbuf_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibdma_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibedma_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibcli_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibhwa_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibdpm_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibmathutils.$(R4F_LIB_EXT) \
	-llibcbuff_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibhsiheader_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibdpedma_hwa_$(MMWAVE_SDK_DEVICE_TYPE).$(R4F_LIB_EXT) \
	-llibgtrack3D.$(R4F_LIB_EXT)

MSS_PCOUNT3D_LOC_LIBS = $(R4F_COMMON_LOC_LIB) \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/osal/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/esm/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/gpio/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/soc/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/pinmux/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/crc/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/uart/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/mailbox/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/mmwavelink/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/mmwave/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/adcbuf/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/dma/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/edma/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/cli/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/hwa/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/control/dpm/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/mathutils/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/drivers/cbuff/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/hsiheader/lib \
	-i$(MMWAVE_SDK_INSTALL_PATH)/ti/datapath/dpedma/lib \
	-i./dpu/trackerproc_overhead/packages/ti/alg/gtrack/lib

MSS_PCOUNT3D_CFG_PREFIX = pcount3D_mss
MSS_PCOUNT3D_CFG       = $(MSS_PCOUNT3D_CFG_PREFIX).cfg
MSS_PCOUNT3D_ROV_XS    = $(MSS_PCOUNT3D_CFG_PREFIX)_$(R4F_XS_SUFFIX).rov.xs
MSS_PCOUNT3D_CONFIGPKG = pcount3D_configPkg_mss_$(MMWAVE_SDK_DEVICE_TYPE)
MSS_PCOUNT3D_MAP       = 3D_people_track_6843_mss.map
MSS_PCOUNT3D_OUT       = 3D_people_track_6843_mss.$(R4F_EXE_EXT)
MSS_PCOUNT3D_CMD       = mss/pcount3D_mss_linker.cmd
MSS_PCOUNT3D_SOURCES   = \
	mmwdemo_rfparser.c \
	mmwdemo_adcconfig.c \
	mss_main.c \
	pcount3D_cli.c \
	tracker_utils.c \
	trackerproc_3d.c \
	height_detection.c \
	objdetrangehwa.c \
	rangeprochwa.c

MSS_PCOUNT3D_DEPENDS = $(addprefix $(PLATFORM_OBJDIR)/, $(MSS_PCOUNT3D_SOURCES:.c=.$(R4F_DEP_EXT)))
MSS_PCOUNT3D_OBJECTS = $(addprefix $(PLATFORM_OBJDIR)/, $(MSS_PCOUNT3D_SOURCES:.c=.$(R4F_OBJ_EXT)))

pcount3DMssRTSC:
	@echo 'Configuring MSS RTSC packages...'
	$(XS) --xdcpath="$(XDCPATH)" xdc.tools.configuro $(R4F_XSFLAGS) -o $(MSS_PCOUNT3D_CONFIGPKG) mss/$(MSS_PCOUNT3D_CFG)
	@echo 'Finished configuring MSS packages'
	@echo ' '

mssDemo: BUILD_CONFIGPKG=$(MSS_PCOUNT3D_CONFIGPKG)
mssDemo: R4F_CFLAGS += --cmd_file=$(BUILD_CONFIGPKG)/compiler.opt \
	-i. \
	-imss \
	-icommon \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/src/DSP_fft16x16_imre/c64P \
	-i$(C64Px_DSPLIB_INSTALL_PATH)/packages/ti/dsplib/src/DSP_fft32x32/c64P \
	$(PCOUNT3D_COMMON_DEFS)
mssDemo: buildDirectories pcount3DMssRTSC $(MSS_PCOUNT3D_OBJECTS)
	$(R4F_LD) $(R4F_LDFLAGS) $(MSS_PCOUNT3D_LOC_LIBS) $(MSS_PCOUNT3D_STD_LIBS) \
	-l$(MSS_PCOUNT3D_CONFIGPKG)/linker.cmd --map_file=$(MSS_PCOUNT3D_MAP) $(MSS_PCOUNT3D_OBJECTS) \
	$(PLATFORM_R4F_LINK_CMD) $(MSS_PCOUNT3D_CMD) $(PCOUNT3D_COMMON_DEFS) $(R4F_LD_RTS_FLAGS) -o $(MSS_PCOUNT3D_OUT)
	$(COPY_CMD) $(MSS_PCOUNT3D_CONFIGPKG)/package/cfg/$(MSS_PCOUNT3D_ROV_XS) $(MSS_PCOUNT3D_ROV_XS)
	@echo 'Built MSS for 3D People Tracking'

mssDemoClean:
	@echo 'Cleaning 3D People Tracking MSS objects'
	@rm -f $(MSS_PCOUNT3D_OBJECTS) $(MSS_PCOUNT3D_MAP) $(MSS_PCOUNT3D_OUT) $(MSS_PCOUNT3D_DEPENDS) $(MSS_PCOUNT3D_ROV_XS)
	@$(DEL) $(MSS_PCOUNT3D_CONFIGPKG)
	@$(DEL) $(PLATFORM_OBJDIR)

-include $(MSS_PCOUNT3D_DEPENDS)
