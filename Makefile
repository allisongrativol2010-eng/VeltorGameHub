
# ==========================================
# VELTOR GAME HUB — PS4 HOMEBREW
# OpenOrbis SDK
# ==========================================

TITLE       := Veltor GameHub
VERSION     := 1.00
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB0000

# OpenOrbis SDK
SDK         := /lib/OpenOrbisSDK
BIN         := $(SDK)/bin/linux

# Ferramentas
CXX         := clang++
LD          := ld.lld

CREATE_EBOOT := $(BIN)/create-eboot
PKGTOOL      := $(BIN)/PkgTool.Core
CREATE_GP4   := /tmp/create-gp4

# Diretórios e arquivos
BUILD_DIR   := x64/Debug
OBJECT      := $(BUILD_DIR)/main.o
ELF         := $(BUILD_DIR)/VeltorGameHub.elf
EBoot       := eboot.bin
GP4         := pkg.gp4
PKG         := VeltorGameHub.pkg

# Flags de compilação
CXXFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-c \
	-isysroot $(SDK) \
	-isystem $(SDK)/include \
	-isystem $(SDK)/include/c++/v1

# Flags de linkedição
LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(SDK)/link.x \
	--eh-frame-hdr \
	-L$(SDK)/lib

LIBS := -lc -lkernel -lc++

# ==========================================
# ALVO PADRÃO
# ==========================================

.PHONY: all clean check-tools

all: $(PKG)

# ==========================================
# VERIFICAÇÃO DAS FERRAMENTAS
# ==========================================

check-tools:
	@test -x "$(CXX)" || { echo "ERRO: clang++ não encontrado"; exit 1; }
	@test -x "$(LD)" || { echo "ERRO: ld.lld não encontrado"; exit 1; }
	@test -x "$(CREATE_EBOOT)" || { echo "ERRO: create-eboot não encontrado"; exit 1; }
	@test -x "$(PKGTOOL)" || { echo "ERRO: PkgTool.Core não encontrado"; exit 1; }
	@test -x "$(CREATE_GP4)" || { echo "ERRO: create-gp4 não encontrado em /tmp/create-gp4"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "ERRO: crt1.o não encontrado"; exit 1; }
	@test -f main.cpp || { echo "ERRO: main.cpp não encontrado"; exit 1; }
	@test -f sce_sys/icon0.png || { echo "ERRO: sce_sys/icon0.png não encontrado"; exit 1; }

# ==========================================
# COMPILAÇÃO
# ==========================================

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJECT): main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

# ==========================================
# GERAÇÃO DO ELF
# ==========================================

$(ELF): $(OBJECT) check-tools
	$(LD) $(OBJECT) -o $(ELF) $(LDFLAGS) \
		$(SDK)/lib/crt1.o \
		$(LIBS)
	@echo "=== ELF gerado ==="
	@file "$(ELF)"
	@ls -lh "$(ELF)"

# ==========================================
# GERAÇÃO DO EBOOT
# ==========================================

$(EBoot): $(ELF)
	@echo "=== Gerando FSELF ==="
	$(CREATE_EBOOT) -in=$(ELF) -out=$(EBoot)
	@test -s "$(EBoot)" || { echo "ERRO: eboot.bin não foi gerado"; exit 1; }

# ==========================================
# PARAM.SFO
# ==========================================

sce_sys/param.sfo:
	@test -f sce_sys/param.sfo || { echo "ERRO: crie o arquivo sce_sys/param.sfo"; exit 1; }

# ==========================================
# GERAÇÃO DO GP4
# ==========================================

$(GP4): $(EBoot) sce_sys/param.sfo check-tools
	$(CREATE_GP4) -out=$(GP4) \
		--content-id=$(CONTENT_ID) \
		--files "eboot.bin sce_sys/param.sfo sce_sys/icon0.png"

# ==========================================
# EMPACOTAMENTO PKG
# ==========================================

$(PKG): $(GP4)
	$(PKGTOOL) --build $(GP4) $(PKG)
	@test -s "$(PKG)" || { echo "ERRO: PKG não foi gerado"; exit 1; }
	@echo "=========================================="
	@echo "PACOTE GERADO: $(PKG)"
	@ls -lh "$(PKG)"
	@echo "=========================================="

# ==========================================
# LIMPEZA
# ==========================================

clean:
	rm -rf $(BUILD_DIR) $(EBoot) $(GP4) $(PKG)
