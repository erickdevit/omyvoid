# Handoff para continuar no Antigravity

Estado registrado em 3 de agosto de 2026. A branch de trabalho é `dev` e estava
sincronizada com `origin/dev` no commit `d6ceb66` antes deste handoff. Não foi
gerada nenhuma ISO.

## O que já está pronto

- Porte base para Void `x86_64-glibc`, XBPS e runit.
- Instalador TUI com UEFI, Btrfs obrigatório, LUKS2 opcional e dual boot.
- Limine, UKIs, dracut, snapshots Snapper e recuperação.
- Repositório complementar fechado em quatro pacotes: `elephant`,
  `omyvoid-limine-entry-tool`, `omyvoid-limine-snapper-sync` e
  `omyvoid-dracut-snapshot`.
- GitHub Actions e GitLab CI/CD definidos, com validação isolada e runners
  separados para pacotes e release.
- Environment GitHub `release` limitado a `dev`, `rc`, `main` e tags `v*`.
- ShellCheck aprovado em 441 scripts; Rustfmt, Clippy e 11 testes Rust aprovados.
- Templates XBPS aprovados em todas as regras funcionais do `xlint`.
  `release/xlint-xbps-template.sh` ignora somente a regra upstream de tabs porque
  o `AGENTS.md` exige dois espaços.
- `.gitlab-ci.yml` aprovado por JSON Schema e pela cadeia `needs` nos cenários
  `dev` e tag de release.

## O que falta antes da primeira ISO

1. Resolver o bloqueio de cobrança do GitHub. A execução
   `30831329252` foi recusada antes do checkout:
   `https://github.com/erickdevit/omyvoid/actions/runs/30831329252`.
2. Executar novamente o job hospedado `test` depois do desbloqueio.
3. Cadastrar um host Void com o label `omyvoid-builder` e construir os quatro
   pacotes:

   ```bash
   release/ci-prepare-void.sh packages
   release/build-xbps-repo.sh build/repository
   release/inspect-xbps-repo.sh build/repository
   ```

4. Cadastrar um segundo host Void isolado com o label `omyvoid-release`. Não
   usar esse runner para pull requests.
5. Resolver o conjunto final de wallpapers. Atualmente existem quatro arquivos
   em `themes/omyvoid/backgrounds/`, mas o contrato anterior exige exatamente
   dois. Esta decisão é exclusiva do mantenedor; consultar
   `BRANDING_PENDING.md` e alinhar também `tools/branding/generate_assets.py`.
6. Rodar `test/ci.sh` em Void após a decisão dos wallpapers.
7. Gerar e inspecionar a ISO manualmente. Esta etapa permanece com o mantenedor:

   ```bash
   release/ci-prepare-void.sh builder
   install/iso/build-iso.sh
   release/inspect-iso.sh "build/omyvoid-$(cat version)-x86_64.iso"
   ```

## Infraestrutura ainda não configurada

- GitHub: zero runners, zero secrets e zero variables.
- Adicionar um aprovador diferente do executor ao environment `release`.
- Cadastrar chaves XBPS/Minisign e credenciais/URLs do Cloudflare R2 conforme
  `REMOTE_REPOSITORY_SETUP.md`.
- Criar ou conectar o projeto GitLab; atualmente só existe o remote GitHub
  `origin`.
- Cadastrar no GitLab os runners `omyvoid-builder` e `omyvoid-release`, as
  variables protegidas e as três chaves do tipo File.
- Criar as branches `rc` e `main` e as proteções somente depois de uma CI verde.

## Pendências que não bloqueiam a ISO genérica

- Paridade física das famílias Intel, AMD, NVIDIA, ASUS, Framework, Surface,
  Apple T2, Dell, Lenovo e demais hardwares herdados.
- Integrações de hardware sem pacote Void/Omyvoid equivalente estão listadas em
  `CURRENT_STATUS.md`.
- `CONTRIBUTING.md` menciona um Code of Conduct ainda inexistente.

## Arquivos de referência

- `CURRENT_STATUS.md`: auditoria detalhada e estado de prontidão.
- `REMOTE_REPOSITORY_SETUP.md`: configuração completa de GitHub, GitLab,
  runners, assinatura e R2.
- `BRANDING_PENDING.md`: decisões visuais reservadas ao mantenedor.
- `AGENTS.md`: regras obrigatórias para alterações e commits.
- `release/README.md`: fluxo de promoção e publicação.

Não alterar o README público com informações temporárias deste handoff e não
modificar branding sem uma solicitação explícita do mantenedor.
