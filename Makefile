
TITLE       := Veltor GameHub
VERSION     := 1.00
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB0000

TOOLCHAIN   := /lib/OpenOrbisSDK
LIBS        := -lc -lkernel -lc++

PROJDIR     := VeltorGameHub
INTDIR      := x64/Debug
CXXFILE     := main.cpp
OBJ         := $(INTDIR)/main.o
ELF         := $(INTDIR)/$(PROJDIR).elf
OELF        := $(INTDIR)/$(PROJDIR).oelf

CXX         := clang++
LD          := ld.lld
CDIR        := linux

CXXFLAGS    := --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables -c -isysroot $(TOOLCHAIN) -isystem $(TOOLCHAIN)/include -isystem $(TOOLCHAIN)/include/c++/v1
LDFLAGS     := -m elf_x86_64 -pie --script $(TOOLCHAIN)/link.x --eh-frame-hdr -L$(TOOLCHAIN)/lib

FSELF       := $(TOOLCHAIN)/bin/$(CDIR)/create-fself
PKGTOOL     := $(TOOLCHAIN)/bin/$(CDIR)/PkgTool.Core
CREATEGP4   := $(TOOLCHAIN)/bin/$(CDIR)/create-gp4

.PHONY: all clean check-tools

all: $(CONTENT_ID).pkg

check-tools:
	@test -x "$(FSELF)" || (echo "ERRO: create-fself ausente: $(FSELF)"; exit 1)
	@test -x "$(PKGTOOL)" || (echo "ERRO: PkgTool.Core ausente: $(PKGTOOL)"; exit 1)
	@test -x "$(CREATEGP4)" || (echo "ERRO: create-gp4 ausente: $(CREATEGP4)"; exit 1)
	@test -f "$(TOOLCHAIN)/lib/crt1.o" || (echo "ERRO: crt1.o ausente"; exit 1)
	@test -f "sce_sys/icon0.png" || (echo "ERRO: sce_sys/icon0.png ausente"; exit 1)

$(INTDIR):
	mkdir -p $(INTDIR)

$(OBJ): $(CXXFILE) | $(INTDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

eboot.bin: $(OBJ) check-tools
	$(LD) $(OBJ) -o $(ELF) $(LDFLAGS) $(LIBS) $(TOOLCHAIN)/lib/crt1.o
	$(FSELF) -in=$(ELF) -out=$(OELF) --eboot "eboot.bin" --paid 0x3800000000000011
	cp $(OELF) eboot.bin

sce_sys/param.sfo: Makefile
	mkdir -p sce_sys
	$(PKGTOOL) sfo_new $@
	$(PKGTOOL) sfo_setentry $@ APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKGTOOL) sfo_setentry $@ APP_VER --type Utf8 --maxsize 8 --value '$(VERSION)'
	$(PKGTOOL) sfo_setentry $@ ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ CATEGORY --type Utf8 --maxsize 4 --value 'gd'
	$(PKGTOOL) sfo_setentry $@ CONTENT_ID --type Utf8 --maxsize 48 --value '$(CONTENT_ID)'
	$(PKGTOOL) sfo_setentry $@ DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry $@ TITLE --type Utf8 --maxsize 128 --value '$(TITLE)'
	$(PKGTOOL) sfo_setentry $@ TITLE_ID --type Utf8 --maxsize 12 --value '$(TITLE_ID)'
	$(PKGTOOL) sfo_setentry $@ VERSION --type Utf8 --maxsize 8 --value '$(VERSION)'

pkg.gp4: eboot.bin sce_sys/param.sfo check-tools
	$(CREATEGP4) -out $@ --content-id=$(CONTENT_ID) --files eboot.bin sce_sys/param.sfo sce_sys/icon0.png

$(CONTENT_ID).pkg: pkg.gp4
	$(PKGTOOL) pkg_build $< .

clean:
	rm -rf $(CONTENT_ID).pkg pkg.gp4 eboot.bin sce_sys/param.sfo $(INTDIR)
