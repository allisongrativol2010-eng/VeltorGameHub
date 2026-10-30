
TITLE        := Veltor GameHub
VERSION      := 1.00
TITLE_ID     := VLTG00001
CONTENT_ID   := IV0000-VLTG00001_00-VELTORGAMEHUB0000

SDK          := /lib/OpenOrbisSDK
BIN          := $(SDK)/bin/linux
BUILD_DIR    := x64/Debug

CXX          := clang++
LD           := ld.lld
CREATE_EBOOT := $(BIN)/create-eboot
PKGTOOL      := $(BIN)/PkgTool.Core
CREATE_GP4   := $(BIN)/create-gp4

OBJ          := $(BUILD_DIR)/main.o
ELF          := $(BUILD_DIR)/VeltorGameHub.elf

CXXFLAGS     := --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables -c \
                -isysroot $(SDK) \
                -isystem $(SDK)/include \
                -isystem $(SDK)/include/c++/v1

LDFLAGS      := -m elf_x86_64 -pie --script $(SDK)/link.x \
                --eh-frame-hdr -L$(SDK)/lib

LIBS         := -lc -lkernel -lc++

.PHONY: all clean check-tools

all: $(CONTENT_ID).pkg

check-tools:
	@test -x "$(CREATE_EBOOT)" || { echo "ERRO: create-eboot não encontrado"; exit 1; }
	@test -x "$(PKGTOOL)" || { echo "ERRO: PkgTool.Core não encontrado"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "ERRO: crt1.o não encontrado"; exit 1; }
	@test -x "$(CREATE_GP4)" || { echo "ERRO: create-gp4 não existe nesta imagem Docker. O workflow precisa disponibilizá-lo."; exit 1; }
	@test -f sce_sys/icon0.png || { echo "ERRO: falta sce_sys/icon0.png no projeto"; exit 1; }

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ): main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

eboot.bin: $(OBJ) check-tools
	$(LD) $(OBJ) -o $(ELF) $(LDFLAGS) $(SDK)/lib/crt1.o $(LIBS)
	$(CREATE_EBOOT) -in=$(ELF) -out=eboot.bin

sce_sys/param.sfo: Makefile check-tools
	mkdir -p sce_sys
	$(PKGTOOL) sfo_new $@
	$(PKGTOOL) sfo_setentry $@ APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKGTOOL) sfo_setentry $@ APP_VER --type Utf8 --maxsize 8 --value "$(VERSION)"
	$(PKGTOOL) sfo_setentry $@ ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ CATEGORY --type Utf8 --maxsize 4 --value "gd"
	$(PKGTOOL) sfo_setentry $@ CONTENT_ID --type Utf8 --maxsize 48 --value "$(CONTENT_ID)"
	$(PKGTOOL) sfo_setentry $@ DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ TITLE --type Utf8 --maxsize 128 --value "$(TITLE)"
	$(PKGTOOL) sfo_setentry $@ TITLE_ID --type Utf8 --maxsize 12 --value "$(TITLE_ID)"
	$(PKGTOOL) sfo_setentry $@ VERSION --type Utf8 --maxsize 8 --value "$(VERSION)"

pkg.gp4: eboot.bin sce_sys/param.sfo check-tools
	$(CREATE_GP4) -out=$@ --content-id=$(CONTENT_ID) --files eboot.bin sce_sys/param.sfo sce_sys/icon0.png

$(CONTENT_ID).pkg: pkg.gp4
	$(PKGTOOL) pkg_build $< .

clean:
	rm -rf "$(BUILD_DIR)" eboot.bin pkg.gp4 "$(CONTENT_ID).pkg" sce_sys/param.sfo
