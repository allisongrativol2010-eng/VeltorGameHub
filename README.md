# Veltor GameHub (PS4 Homebrew)

Projeto inicial de homebrew para PlayStation 4 usando a OpenOrbis PS4 Toolchain.

## Estado atual
- Estrutura inicial de compilação OpenOrbis.
- Metadados de aplicativo gerados no build.
- Ícone gerado durante o workflow.
- GitHub Actions para compilar e publicar o `.pkg` como artefato.
- Código inicial de teste; ainda não é uma interface completa de biblioteca de jogos.

## Compilação automática
1. Envie os arquivos deste ZIP para a raiz do repositório `VeltorGameHub`.
2. Abra a aba **Actions**.
3. Selecione **Build Veltor GameHub PKG** e execute **Run workflow**, ou faça push na branch `main`.
4. Se a execução terminar com sucesso, abra a execução e baixe o artefato `VeltorGameHub-pkg`.

## Identificadores
- TITLE_ID: `VLTG00001`
- CONTENT_ID: `IV0000-VLTG00001_00-VELTORGAMEHUB0000`

## Observação
A compilação de um PKG não garante que ele rode em qualquer PS4. Instalação e execução dependem do firmware e do ambiente de homebrew. Este projeto não inclui assinatura oficial da Sony.
