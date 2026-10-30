
TITLE       := Veltor GameHub
TITLE_ID    := VLTG00001
CONTENT_ID  := IV0000-VLTG00001_00-VELTORGAMEHUB000

SDK      := /lib/OpenOrbisSDK
CXX      := clang++
LD       := ld.lld

BUILD_DIR := x64/Debug
OBJECT   := $(BUILD_DIR)/main.o
ELF      := $(BUILD_DIR)/VeltorGameHub.elf

.PHONY: all clean check-tools

all: $(ELF)

check-tools:
	@echo "===== VALIDANDO OPENORBIS SDK ====="
	@command -v $(CXX) >/dev/null 2>&1 || { echo "ERRO: clang++ não encontrado"; exit 1; }
	@command -v $(LD) >/dev/null 2>&1 || { echo "ERRO: ld.lld não encontrado"; exit 1; }
	@test -f "$(SDK)/link.x" || { echo "ERRO: link.x não encontrado"; exit 1; }
	@test -f "$(SDK)/lib/crt1.o" || { echo "ERRO: crt1.o não encontrado"; exit 1; }
	@test -d "$(SDK)/include" || { echo "ERRO: includes não encontrados"; exit 1; }
	@test -f main.cpp || { echo "ERRO: main.cpp não encontrado"; exit 1; }
	@echo "SDK validado."

$(BUILD_DIR):
	mkdir -p $@

$(OBJECT): main.cpp | $(BUILD_DIR) check-tools
	@echo "===== COMPILANDO main.cpp ====="
	$(CXX) -cc1 -triple x86_64-pc-freebsd-elf -munwind-tables \
		-I$(SDK)/include -I$(SDK)/include/c++/v1 \
		-fuse-init-array -debug-info-kind=limited \
		-debugger-tuning=gdb -emit-obj -o $@ $<
	@test -s "$@" || { echo "ERRO: objeto não foi gerado"; exit 1; }

$(ELF): $(OBJECT)
	@echo "===== LINKANDO ELF PS4 ====="
	$(LD) $(OBJECT) -o $@ -m elf_x86_64 -pie \
		--script $(SDK)/link.x --eh-frame-hdr \
		-L$(SDK)/lib -lc -lkernel -lc++ $(SDK)/lib/crt1.o
	@test -s "$@" || { echo "ERRO: ELF não foi gerado"; exit 1; }
	@echo "ELF gerado:"
	@ls -lh "$@"

clean:
	rm -rf $(BUILD_DIR) eboot.bin VeltorGameHub.oelf pkg.gp4 pkg-output VeltorGameHub.pkg
