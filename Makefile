
TITLE       := Veltor GameHub
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB0000

SDK := /lib/OpenOrbisSDK
BIN := $(SDK)/bin/linux

CXX := clang++
LD  := ld.lld

BUILD_DIR := x64/Debug
OBJECT    := $(BUILD_DIR)/main.o
ELF       := $(BUILD_DIR)/VeltorGameHub.elf

EBOOT := eboot.bin
GP4   := pkg.gp4
PKG   := VeltorGameHub.pkg

CXXFLAGS := \
	-cc1 \
	-triple x86_64-pc-freebsd-elf \
	-munwind-tables \
	-I$(SDK)/include \
	-I$(SDK)/include/c++/v1 \
	-fuse-init-array \
	-debug-info-kind=limited \
	-debugger-tuning=gdb \
	-emit-obj

LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(SDK)/link.x \
	--eh-frame-hdr \
	-L$(SDK)/lib \
	-lc \
	-lkernel \
	-lc++ \
	$(SDK)/lib/crt1.o

.PHONY: all clean check-tools

all: $(ELF)

check-tools:
	@echo "===== VERIFICANDO SDK ====="
	@command -v $(CXX) >/dev/null 2>&1 || { echo "clang++ não encontrado"; exit 1; }
	@command -v $(LD) >/dev/null 2>&1 || { echo "ld.lld não encontrado"; exit 1; }
	@test -f "$(SDK)/link.x" || { echo "link.x não encontrado"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "crt1.o não encontrado"; exit 1; }
	@test -f main.cpp || { echo "main.cpp não encontrado"; exit 1; }
	@echo "SDK verificado."

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJECT): main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(ELF): $(OBJECT) | check-tools
	@echo "===== GERANDO ELF ====="
	$(LD) $(OBJECT) -o $(ELF) $(LDFLAGS)
	@test -s "$(ELF)" || { echo "Falha ao gerar ELF"; exit 1; }
	@echo "ELF gerado."
	@ls -lh "$(ELF)"

clean:
	rm -rf $(BUILD_DIR) $(EBOOT) $(GP4) $(PKG) VeltorGameHub.oelf
