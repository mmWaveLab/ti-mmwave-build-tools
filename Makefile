IMAGE ?= ti-mmwave-build-tools:linux-smoke
SDK_FULL_IMAGE ?= meowpas/ti-mmwave-sdk:03.06.02
TI_ROOT ?= /opt/ti
HOST_TI_ROOT ?= $(TI_ROOT)

.PHONY: docker-build docker-shell sdk-image sdk-image-smoke sdk-profile-validate install-profile-validate cmake-portability github-actions-smoke project-docker project-native doctor test ci docker-cmake native-cmake benchmark flash-list flash-doctor flash-dry-run flash package clean

docker-build:
	docker build -t $(IMAGE) .

docker-shell:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/docker-shell.sh

sdk-image:
	SDK_FULL_IMAGE=$(SDK_FULL_IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/build-sdk-image.sh

sdk-image-smoke:
	SDK_FULL_IMAGE=$(SDK_FULL_IMAGE) scripts/sdk-image-smoke.sh

sdk-profile-validate:
	SDK_FULL_IMAGE=$(SDK_FULL_IMAGE) PROFILE_VALIDATION_JOBS=$(or $(PROFILE_VALIDATION_JOBS),all) DEMO_PROFILES="$(DEMO_PROFILES)" scripts/validate-demo-profiles.sh

install-profile-validate:
	SDK_FULL_IMAGE=$(SDK_FULL_IMAGE) INSTALL_VALIDATION_JOBS=$(or $(INSTALL_VALIDATION_JOBS),auto) DEMO_PROFILES="$(DEMO_PROFILES)" scripts/validate-install-profiles.sh

cmake-portability:
	scripts/validate-cmake-portability.sh

github-actions-smoke:
	scripts/github-actions-smoke.sh

project-docker:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) PROJECT=$(PROJECT) scripts/cmake-build-project.sh

project-native:
	TI_ROOT=$(TI_ROOT) PROJECT=$(PROJECT) scripts/native-build-project.sh

doctor:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/doctor.sh

test:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/test.sh

ci:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/ci.sh

docker-cmake:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/cmake-build-xwr68xx-sdk-demo.sh

native-cmake:
	TI_ROOT=$(TI_ROOT) scripts/native-cmake-build-xwr68xx-sdk-demo.sh

benchmark:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/benchmark.sh

flash-list:
	scripts/flash-list.sh

flash-doctor:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) scripts/flash-doctor.sh

flash-dry-run:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) scripts/flash-dry-run.sh

flash:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) CONFIRM_FLASH=$(CONFIRM_FLASH) scripts/flash.sh

package:
	ARTIFACT_DIR=$$(pwd)/artifacts REPORT_DIR=$$(pwd)/reports scripts/package-artifacts.sh

clean:
	scripts/clean.sh
