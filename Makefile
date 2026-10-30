
# ==================================================
# VELTOR GAME HUB — PS4 HOMEBREW
# OpenOrbis Toolchain
# ==================================================

TITLE       := Veltor GameHub
VERSION     := 1.00
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB0000

# SDK
SDK         := /lib/OpenOrbisSDK
BIN         := $(SDK)/bin/linux

# Ferramentas
CXX         := clang++
LD          := ld.lld
CREATE_EBOOT := $(BIN)/create-eboot
PKGTOOL      := $(BIN)/PkgTool.Core
CREATE_GP4   := /tmp/create-gp4

# Arquivos
BUILD_DIR   := x64/Debug
OBJECT      := $(BUILD_DIR)/main.o
ELF         := $(BUILD_DIR)/VeltorGameHub.elf
EBOOT       := eboot.bin
GP4         := pkg.gp4
PKG         := VeltorGameHub.pkg

# Compilação
CXXFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-c \
	-isysroot $(SDK) \
	-isystem $(SDK)/include \
	-isystem $(SDK)/include/c++/v1

# Linkedição
LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(SDK)/link.x \
	--eh-frame-hdr \
	-L$(SDK)/lib

LIBS := -lc -lkernel -lc++

# ==================================================
# ALVO PRINCIPAL
# ==================================================

.PHONY: all clean check-tools

all: $(PKG)

# ==================================================
# VERIFICAÇÃO DAS FERRAMENTAS
# ==================================================

check-tools:
	@echo "=== Verificando ferramentas ==="
	@command -v $(CXX) >/dev/null 2>&1 || { echo "ERRO: clang++ não encontrado no PATH"; exit 1; }
	@command -v $(LD) >/dev/null 2>&1 || { echo "ERRO: ld.lld não encontrado no PATH"; exit 1; }
	@test -x "$(CREATE_EBOOT)" || { echo "ERRO: create-eboot não encontrado"; exit 1; }
	@test -x "$(PKGTOOL)" || { echo "ERRO: PkgTool.Core não encontrado"; exit 1; }
	@test -x "$(CREATE_GP4)" || { echo "ERRO: create-gp4 não encontrado em /tmp/create-gp4"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "ERRO: crt1.o não encontrado"; exit 1; }
	@test -f "$(SDK)/link.x" || { echo "ERRO: link.x não encontrado"; exit 1; }
	@test -f main.cpp || { echo "ERRO: main.cpp não encontrado"; exit 1; }
	@test -f sce_sys/icon0.png || { echo "ERRO: sce_sys/icon0.png não encontrado"; exit 1; }
	@test -f sce_sys/param.sfo || { echo "ERRO: sce_sys/param.sfo não encontrado"; exit 1; }
	@echo "Todas as ferramentas foram encontradas."

# ==================================================
# DIRETÓRIO DE BUILD
# ==================================================

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ==================================================
# COMPILAÇÃO DO C++
# ==================================================

$(OBJECT): main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

# ==================================================
# GERAÇÃO DO ELF
# ==================================================

$(ELF): $(OBJECT) check-tools
	$(LD) $(OBJECT) -o $(ELF) $(LDFLAGS) \
		$(SDK)/lib/crt1.o \
		$(LIBS)
	@echo "=== ELF gerado ==="
	@file "$(ELF)"
	@ls -lh "$(ELF)"

# ==================================================
# GERAÇÃO DO EBOOT / FSELF
# ==================================================

$(EBOOT): $(ELF)
	@echo "=== Gerando FSELF ==="
	$(CREATE_EBOOT) -in=$(ELF) -out=$(EBOOT)
	@test -s "$(EBOOT)" || { echo "ERRO: eboot.bin não foi gerado"; exit 1; }
	@echo "EBOOT gerado com sucesso."

# ==================================================
# GP4
# ==================================================

$(GP4): $(EBOOT)
	@echo "=== Gerando GP4 ==="
	$(CREATE_GP4) -out=$(GP4) \
		--content-id=$(CONTENT_ID) \
		--files "eboot.bin sce_sys/param.sfo sce_sys/icon0.png"
	@test -s "$(GP4)" || { echo "ERRO: arquivo GP4 não foi gerado"; exit 1; }

# ==================================================
# PACOTE PKG
# ==================================================

$(PKG): $(GP4)
	@echo "=== Gerando PKG ==="
	$(PKGTOOL) --build $(GP4) $(PKG)
	@test -s "$(PKG)" || { echo "ERRO: PKG não foi gerado"; exit 1; }
	@echo "=========================================="
	@echo "BUILD CONCLUÍDO"
	@echo "Arquivo: $(PKG)"
	@ls -lh "$(PKG)"
	@echo "=========================================="

# ==================================================
# LIMPEZA
# ==================================================

clean:
	rm -rf $(BUILD_DIR) $(EBOOT) $(GP4) $(PKG)
