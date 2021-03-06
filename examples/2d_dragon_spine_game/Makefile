# This Makefile uses castle-engine build tool for most operations.
# See https://github.com/castle-engine/castle-engine/wiki/Build-Tool .

MODE:=debug

.PHONY: compile
compile:
	castle-engine --mode=$(MODE)  compile $(CASTLE_ENGINE_TOOL_OPTIONS)

.PHONY: clean
clean:
	castle-engine clean

.PHONY: win32
win32:
	castle-engine --mode=$(MODE) package --os=win32 --cpu=i386

.PHONY: linux
linux:
	castle-engine --mode=$(MODE) package --os=linux --cpu=i386

.PHONY: src
src:
	castle-engine --mode=$(MODE) package-source

.PHONY: android
android:
	castle-engine --mode=$(MODE) package --target=android --fast
	castle-engine install --target=android
	castle-engine run --target=android

.PHONY: android-release
android-release:
	castle-engine clean
	$(MAKE) android MODE=release

.PHONY: ios
ios:
	castle-engine --mode=$(MODE) package --target=iOS --fast

.PHONY: ios-release
ios-release:
	castle-engine clean
	$(MAKE) ios MODE=release

# nx -------------------------------------------------------------------------

NX_OUTPUT_PATH:=d:/tmp/dragon_spine/

.PHONY: nx1
nx1:
	mkdir -p $(NX_OUTPUT_PATH)
	castle-engine package --mode=$(MODE) --target=nintendo-switch --output=$(NX_OUTPUT_PATH) --fast

.PHONY: nx2
nx2:
	mkdir -p $(NX_OUTPUT_PATH)
	castle-engine compile --mode=$(MODE) --target=nintendo-switch --output=$(NX_OUTPUT_PATH)
