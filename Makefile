SHIMS := $(shell pwd)/shims

ifneq ($(CMAKE_TOOLCHAIN_FILE),)
  CROSS_PREFIX := $(shell grep -F 'set(cross_prefix ' $(CMAKE_TOOLCHAIN_FILE) | cut -d' ' -f2 | cut -d')' -f1)
  CMAKE_CXX_FLAGS := -DCMAKE_CXX_FLAGS="-I$(SHIMS) -I$(shell grep -F 'set(toolchain_dir ' $(CMAKE_TOOLCHAIN_FILE) | cut -d' ' -f2 | cut -d')' -f1)/include"
  CMAKE_EXE_LINKER_FLAGS := -DCMAKE_EXE_LINKER_FLAGS="-L$(shell grep -F 'set(toolchain_dir ' $(CMAKE_TOOLCHAIN_FILE) | cut -d' ' -f2 | cut -d')' -f1)/lib"
  CC = $(CROSS_PREFIX)gcc
  CXX = $(CROSS_PREFIX)g++
  ifneq ($(findstring mingw,$(CROSS_PREFIX)),)
    SUFFIX := .exe
    ARCHFLAGS := -static-libgcc -static-libstdc++
    ARCHFLAGS2 := -municode $(ARCHFLAGS)
	CMAKE_CXX_STANDARD_LIBRARIES := -DCMAKE_CXX_STANDARD_LIBRARIES="-lz -lwldap32 -lws2_32 -lcrypt32 -lkernel32 -luser32"
	EXTRA_TARGETS := bin/libwinpthread-1.dll
	SYSDIR := $(shell grep -F 'set(CMAKE_PREFIX_PATH ${toolchain_dir}' $(CMAKE_TOOLCHAIN_FILE) | cut -d';' -f2 | cut -d')' -f1)
  endif
  CMAKE_EXTRA = && cmake . $(CMAKE_CXX_FLAGS) $(CMAKE_EXE_LINKER_FLAGS) $(CMAKE_CXX_STANDARD_LIBRARIES)
endif

STRIP = $(CROSS_PREFIX)strip
AR = $(CROSS_PREFIX)ar

all: 3dstool bannertool ctrtool makerom $(EXTRA_TARGETS)

.PHONY: 3dstool bannertool ctrltool makerom clean distclean cross

3dstool: bin/3dstool$(SUFFIX)
bannertool: bin/bannertool$(SUFFIX)
ctrtool: bin/ctrtool$(SUFFIX)
makerom: bin/makerom$(SUFFIX)

bin/bannertool$(SUFFIX):
	$(MAKE) -C bannertool CC=$(CC) CXX=$(CXX) LDFLAGS="-static-libgcc -static-libstdc++"
	install -Dm755 bannertool/bannertool.elf bin/bannertool$(SUFFIX)
	$(STRIP) bin/bannertool$(SUFFIX)

bin/ctrtool$(SUFFIX):
	ARCHFLAGS="$(ARCHFLAGS2)" CC=$(CC) CXX=$(CXX) INC=-I$(SHIMS) $(MAKE) -C Project_CTR/ctrtool deps PROJECT_PLATFORM=foo ARFLAGS=cr
	ARCHFLAGS="$(ARCHFLAGS2)" CC=$(CC) CXX=$(CXX) INC=-I$(SHIMS) $(MAKE) -C Project_CTR/ctrtool PROJECT_PLATFORM=foo ARFLAGS=cr
	install -Dm755 -t bin Project_CTR/ctrtool/bin/ctrtool$(SUFFIX)
	$(STRIP) bin/ctrtool$(SUFFIX)

bin/makerom$(SUFFIX):
	ARCHFLAGS="$(ARCHFLAGS)" CC=$(CC) CXX=$(CXX) INC=-I$(SHIMS) $(MAKE) -C Project_CTR/makerom deps PROJECT_PLATFORM=foo ARFLAGS=cr
	ARCHFLAGS="$(ARCHFLAGS)" CC=$(CC) CXX=$(CXX) INC=-I$(SHIMS) $(MAKE) -C Project_CTR/makerom PROJECT_PLATFORM=foo ARFLAGS=cr
	install -Dm755 -t bin Project_CTR/makerom/bin/makerom$(SUFFIX)
	$(STRIP) bin/makerom$(SUFFIX)

bin/3dstool$(SUFFIX):
	cd 3dstool && cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$(CMAKE_TOOLCHAIN_FILE) $(CMAKE_EXTRA)
	cmake --build 3dstool
	install -Dm755 -t bin 3dstool/bin/Release/3dstool$(SUFFIX)
	$(STRIP) bin/3dstool$(SUFFIX)

bin/libwinpthread-1.dll:
	mkdir bin
	cp $(SYSDIR)/lib/libwinpthread-1.dll bin

clean:
	rm -f bannertool/bannertool.elf
	$(MAKE) -C Project_CTR/ctrtool clean clean_deps
	$(MAKE) -C Project_CTR/makerom clean clean_deps
	-cmake --build 3dstool --target clean
	rm -rf bin

distclean: clean
	git submodule foreach git clean -dfx
