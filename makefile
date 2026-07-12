ARCHS := arm64
TARGET := iphone:clang:16.5:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
INSTALL_TARGET_PROCESSES := app

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := app

Trash_SRC = $(wildcard Trash/*.mm) $(wildcard Trash/*.m)

HUD_SRC = $(wildcard HUD/*.mm) $(wildcard HUD/*.m)

Lottie_SRC = $(wildcard LottieB64/*.mm) $(wildcard LottieB64/*.m)

$(APPLICATION_NAME)_USE_MODULES := 0

$(APPLICATION_NAME)_FILES += $(wildcard sources/*.mm sources/*.m)

# $(APPLICATION_NAME)_FILES += $(Trash_SRC)

# $(APPLICATION_NAME)_FILES += $(HUD_SRC)

$(APPLICATION_NAME)_FILES += $(Lottie_SRC)

$(APPLICATION_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -Wno-unused-function -Wno-unused-variable -Wno-unused-value -Wno-module-import-in-extern-c -Wunused-but-set-variable -Wno-error=missing-noescape -Wno-error=objc-dictionary-duplicate-keys -Wno-error -Wno-unused-property-ivar -Wno-implicit-function-declaration

# [แก้ไข] เปลี่ยนพาร์ทค้นหา Framework และ Header ไปที่โฟลเดอร์ deps
$(APPLICATION_NAME)_CFLAGS += -Iheaders -Isources -IENCRYPT -IHUD -ILottieB64 -F./deps -I./deps/ffmpegkit.framework/Headers

$(APPLICATION_NAME)_STRIP = 1

$(APPLICATION_NAME)_CCFLAGS += -std=c++17 -fno-rtti -DNDEBUG -Wall -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-unused-function -fvisibility=hidden -IENCRYPT -fbracket-depth=1024

# [แก้ไข] เปลี่ยน -F. เป็น -F./deps เพื่อให้ลิงก์ผ่านโฟลเดอร์ deps
$(APPLICATION_NAME)_LDFLAGS += -lstdc++ -undefined dynamic_lookup -F./deps -Wl,-rpath,@executable_path/Frameworks

$(APPLICATION_NAME)_FRAMEWORKS += UIKit Foundation CoreGraphics QuartzCore Security AVFoundation AudioToolbox CoreMedia MobileCoreServices SystemConfiguration ImageIO WebKit UniformTypeIdentifiers PhotosUI CoreText

# ประกาศเพิ่ม EXTRA_FRAMEWORKS เพื่อดึง ffmpegkit และ lottie เข้ามาลิงก์ตอนบิลด์
$(APPLICATION_NAME)_EXTRA_FRAMEWORKS += ffmpegkit Lottie

$(APPLICATION_NAME)_CODESIGN_FLAGS += -Slayout/entitlements.plist
$(APPLICATION_NAME)_RESOURCE_DIRS = ./layout/Resources

BUILD_NUMBER := $(shell date +%y%m%d%H%M)

include $(THEOS_MAKE_PATH)/application.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	@echo "[*] Updating Build Number to $(BUILD_NUMBER)..."
	@sed -i '' 's/<string>1<\/string>/<string>$(BUILD_NUMBER)<\/string>/g' $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/Info.plist
	
	@echo "[*] Copying all FFmpegKit frameworks from deps into App Bundle..."
	@mkdir -p $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/Frameworks
	
	# [แก้ไข] ดึงไฟล์ .framework ทั้ง 8 ตัวจากโฟลเดอร์ deps เข้าไปในแอปพลิเคชันโดยตรง
	@cp -a ./deps/*.framework $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/Frameworks/
	
	@echo "[*] Cleaning developer headers and modules inside app bundle..."
	# [แก้ไข] ล้าง Headers และ Modules ของทุก Framework ที่ถูกก๊อปปี้เข้าไปเพื่อประหยัดพื้นที่แอปและลดไฟล์ขยะ
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/Frameworks/*.framework/Headers
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/Frameworks/*.framework/Modules

after-package::
	@rm -rf Payload
	@mkdir -p Payload
	@cp -r .theos/_/Applications/$(APPLICATION_NAME).app Payload/
	@chmod 755 Payload/$(APPLICATION_NAME).app/$(APPLICATION_NAME)
	@zip -rq $(APPLICATION_NAME).ipa Payload
	@rm -rf Payload
	@mkdir -p packages
	@mv $(APPLICATION_NAME).ipa packages/
	@echo "[*] Success: packages/$(APPLICATION_NAME).ipa"
