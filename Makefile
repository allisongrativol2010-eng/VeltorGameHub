
# ==================================================
# VELTOR GAME HUB - PS4 HOMEBREW
# OpenOrbis SDK v0.5.1
# ==================================================

TITLE       := Veltor GameHub
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB0000

SDK := /lib/OpenOrbisSDK
BIN := $(SDK)/bin/linux

CXX          := clang++
LD           := ld.lld
CREATE_EBOOT := $(BIN)/create-eboot
PKGTOOL      := $(BIN)/PkgTool.Core
CREATE_GP4   := /tmp/create-gp4

BUILD_DIR := x64/Debug
OBJECT    := $(BUILD_DIR)/main.o
ELF       := $(BUILD_DIR)/VeltorGameHub.elf
EBOOT     := eboot.bin
GP4       := pkg.gp4
PKG       := VeltorGameHub.pkg

CXXFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-c \
	-isysroot $(SDK) \
	-isystem $(SDK)/include \
	-isystem $(SDK)/include/c++/v1

# Mantém a configuração de linkedição atual para diagnóstico.
# Não adiciona opções especulativas ao linker.
LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(SDK)/link.x \
	--eh-frame-hdr \
	-L$(SDK)/lib

LIBS := -lc -lkernel -lc++

.PHONY: all clean check-tools

all: $(PKG)

check-tools:
	@echo "=== Verificando ferramentas ==="
	@command -v $(CXX) >/dev/null 2>&1 || { echo "ERRO: clang++ não encontrado"; exit 1; }
	@command -v $(LD) >/dev/null 2>&1 || { echo "ERRO: ld.lld não encontrado"; exit 1; }
	@test -x "$(CREATE_EBOOT)" || { echo "ERRO: create-eboot não encontrado"; exit 1; }
	@test -x "$(PKGTOOL)" || { echo "ERRO: PkgTool.Core não encontrado"; exit 1; }
	@test -x "$(CREATE_GP4)" || { echo "ERRO: create-gp4 não encontrado"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "ERRO: crt1.o não encontrado"; exit 1; }
	@test -f "$(SDK)/link.x" || { echo "ERRO: link.x não encontrado"; exit 1; }
	@test -f main.cpp || { echo "ERRO: main.cpp não encontrado"; exit 1; }
	@test -s sce_sys/icon0.png || { echo "ERRO: icon0.png ausente ou vazio"; exit 1; }
	@test -s sce_sys/param.sfo || { echo "ERRO: param.sfo ausente ou vazio"; exit 1; }
	@echo "Todas as ferramentas e arquivos foram encontrados."

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJECT): main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(ELF): $(OBJECT) | check-tools
	@echo "=== Gerando ELF ==="
	$(LD) $(OBJECT) -o $(ELF) $(LDFLAGS) \
		$(SDK)/lib/crt1.o \
		$(LIBS)
	@test -s "$(ELF)" || { echo "ERRO: ELF não foi gerado"; exit 1; }
	@echo "=== ELF gerado ==="
	@ls -lh "$(ELF)"

$(EBOOT): $(ELF)
	@echo "=== Gerando EBOOT / FSELF ==="
	$(CREATE_EBOOT) -in=$(ELF) -out=$(EBOOT)
	@test -s "$(EBOOT)" || { echo "ERRO: eboot.bin não foi gerado"; exit 1; }
	@echo "EBOOT gerado com sucesso."

$(GP4): $(EBOOT) | check-tools
	@echo "=== Gerando GP4 ==="
	$(CREATE_GP4) -out=$(GP4) \
		--content-id=$(CONTENT_ID) \
		--files "eboot.bin sce_sys/param.sfo sce_sys/icon0.png"
	@test -s "$(GP4)" || { echo "ERRO: GP4 não foi gerado"; exit 1; }
	@echo "GP4 gerado com sucesso."

$(PKG): $(GP4)
	@echo "=== Empacotando PKG ==="
	$(PKGTOOL) --build $(GP4) $(PKG)
	@test -s "$(PKG)" || { echo "ERRO: PKG não foi gerado"; exit 1; }
	@echo "=========================================="
	@echo "BUILD CONCLUÍDO"
	@echo "Arquivo: $(PKG)"
	@ls -lh "$(PKG)"
	@echo "=========================================="

clean:
	rm -rf $(BUILD_DIR) $(EBOOT) $(GP4) $(PKG)
