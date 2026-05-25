###################################################################################
# 3D People Tracking demo level makefile
###################################################################################
ifeq ($(CCS_MAKEFILE_BASED_BUILD), 1)
ifeq ($(OS),Windows_NT)
include $(MMWAVE_SDK_INSTALL_PATH)/scripts/windows/setenv.mak
else
include $(MMWAVE_SDK_INSTALL_PATH)/scripts/unix/setenv.mak
endif
endif

include $(MMWAVE_SDK_INSTALL_PATH)/ti/common/mmwave_sdk.mak
include ./mss/pcount3D_mss.mak
include ./dss/pcount3D_dss.mak

PEOPLE_TRACK_DEMO_BIN = 3D_people_track_6843_demo.bin

.PHONY: all clean

clean: mssDemoClean dssDemoClean
	@$(DEL) $(PEOPLE_TRACK_DEMO_BIN)

all: mssDemo dssDemo
	@$(GENERATE_METAIMAGE) $(PEOPLE_TRACK_DEMO_BIN) $(SHMEM_ALLOC) $(MSS_PCOUNT3D_OUT) $(XWR68XX_RADARSS_IMAGE_BIN) $(DSS_PCOUNT3D_OUT)

help:
	@echo '****************************************************************************************'
	@echo '* Makefile targets for the xWR6843AOP 3D People Tracking demo'
	@echo 'all            -> Builds MSS, DSS, and the flashable metaimage'
	@echo 'clean          -> Cleans MSS, DSS, and metaimage outputs'
	@echo 'mssDemo        -> Builds the MSS image'
	@echo 'mssDemoClean   -> Cleans MSS image output'
	@echo 'dssDemo        -> Builds the DSS image'
	@echo 'dssDemoClean   -> Cleans DSS image output'
	@echo '****************************************************************************************'

