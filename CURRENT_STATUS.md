# Estado atual do porte Omyvoid

Relatório de auditoria atualizado em 3 de agosto de 2026, sobre o commit
`0b82c4e` da branch `dev`.

## Decisão atual

O porte possui a fundação necessária para entrar na rodada de preparação da
primeira ISO de desenvolvimento, mas a árvore ainda não produz uma ISO com
sucesso. Os bloqueadores de bootstrap listados abaixo devem ser resolvidos antes
da primeira execução do builder.

Este relatório não inclui os testes destrutivos em QEMU nem a validação física da
matriz de hardware. Esses testes permanecem sob responsabilidade do mantenedor,
conforme definido anteriormente.

## Estado do repositório remoto

- O repositório público `erickdevit/omyvoid` já existe.
- `origin` aponta para `https://github.com/erickdevit/omyvoid.git`.
- A branch local `dev` acompanha `origin/dev` e está sincronizada.
- `dev` é a branch padrão do GitHub.
- A CI está registrada, mas sua primeira execução permanece na fila porque não
  há runner self-hosted cadastrado.
- Não há secrets, variables, environments, regras de proteção ou rulesets.
- O arquivo `.github/workflows/release.yml` está no remoto, mas ainda não aparece
  como workflow registrado pela API do GitHub. O arquivo passou na validação
  sintática do `actionlint`; os únicos avisos foram os labels customizados do
  runner ainda inexistente.

As etapas de configuração estão documentadas em
`REMOTE_REPOSITORY_SETUP.md`.

## Componentes implementados

- Instalador TUI em Rust para apagar disco e instalar ao lado do Windows.
- UEFI, ESP FAT32 de 2 GiB, Btrfs obrigatório e LUKS2/Argon2id opcional.
- Subvolumes `@`, `@home`, `@log`, `@xbps` e `@snapshots`.
- Limine, UKIs, dracut, hooks de kernel e fallback EFI.
- Snapper, retenção de cinco snapshots, OverlayFS temporário, restauração e
  desfazer restauração.
- Recovery live para LUKS, Btrfs, UKIs e Limine.
- runit para serviços de sistema e usuário.
- PipeWire, WirePlumber, SDDM e Hyprland.
- CLI com 326 comandos e metadados válidos.
- Scripts de build do repositório XBPS, inspeção da ISO e publicação no R2.

## Bloqueadores da primeira ISO

### Privilégios do builder

`install/iso/build-iso.sh` exige usuário comum porque `xbps-src` não pode ser
executado como root, mas chama `mklive.sh` sem elevação. O `void-mklive` atual
exige root. O fluxo precisa separar a construção dos pacotes, feita como usuário
comum, da geração da mídia, executada com os privilégios estritamente
necessários.

### Bootstrap do repositório XBPS

O builder sempre consulta `https://packages.omyvoid.org/current`, inclusive
quando o repositório complementar local já foi construído. Como o domínio ainda
não está publicado, a sincronização do XBPS falha. Durante o bootstrap da
primeira ISO, o repositório remoto precisa ser opcional quando o repositório local
estiver disponível.

### Pacote Elephant

`elephant` consta no manifesto base, mas não está disponível nos repositórios
Void ou Blackhole-VL. A decisão atual é empacotá-lo no repositório Omyvoid caso a
integração continue necessária. O template precisa ser adicionado a `xbps-src`,
ao builder do repositório e aos testes antes da primeira ISO.

### Testes vermelhos

- `test/omyvoid-iso-test.sh` falha porque existem quatro wallpapers onde o
  contrato atual espera dois. A decisão visual pertence ao mantenedor e está em
  `BRANDING_PENDING.md`.
- `test/omyvoid-cli-test.sh` ainda espera que `omyvoid install` sem argumentos
  apresente apenas o grupo de software opcional. A interface pública atual abre
  corretamente o instalador do sistema; o teste e a skill precisam documentar a
  coexistência com `omyvoid install <subcomando>`.

## Resultados da auditoria automatizada

- ShellCheck: aprovado.
- Sintaxe dos scripts Bash: aprovada.
- `omyvoid commands --check`: aprovado para 326 comandos.
- Teste de atualização e seleção de tags: aprovado.
- `cargo fmt --check`: aprovado.
- `cargo clippy --locked --all-targets -- -D warnings`: aprovado.
- Testes Rust: 11 aprovados, nenhuma falha.
- Suíte `test/run.sh`: reprovada pelas duas inconsistências descritas acima.
- `xlint`, build real dos pacotes e build da ISO: ainda não executados em Void.

Os testes de Limine, snapshots, recovery e estrutura ISO existentes são
majoritariamente estáticos. Eles comprovam a presença da implementação, mas não
substituem a execução real dos fluxos.

## Branding

Os temas `Yaru-*` são uma exceção aprovada e devem permanecer. As demais
pendências de branding foram retiradas da fila de implementação dos agentes e
registradas em `BRANDING_PENDING.md` para execução exclusiva do mantenedor.

## Matriz de hardware

A estrutura de detecção foi preservada, mas ainda existem integrações com nomes
de pacotes sem equivalente disponível no Void/Omyvoid, incluindo
`linux-oem-24.04`, `asusctl`, pacotes Apple T2, `qmk-hid`, drivers Tuxedo,
Motorcomm YT6801, Intel IPU7 e o pacote do touchpad háptico Dell.

Essas lacunas não precisam bloquear a primeira ISO genérica depois que os
bloqueadores de bootstrap forem resolvidos, mas impedem considerar completa a
paridade de hardware herdada.

## Documentação e arquivos para agentes

- `AGENTS.md` é a instrução global do repositório e cobre estilo, scripts,
  comandos, i18n, porte e commits.
- O projeto fornece uma skill própria em `default/omyvoid-skill/SKILL.md`.
- `install/config/omyvoid-ai-skill.sh` disponibiliza a skill para Agents, Claude,
  Codex e Pi.
- A skill precisa diferenciar explicitamente o instalador do sistema de seus
  subcomandos de software opcional.
- `CONTRIBUTING.md` menciona um Code of Conduct ainda inexistente.
- A documentação do runner não lista todas as dependências da build/release.

## Próximo marco

O próximo marco técnico é uma build manual não assinada da primeira ISO `dev` em
um runner Void. Para alcançá-lo:

1. cadastrar e preparar o runner Void;
2. corrigir a separação de privilégios do builder;
3. tornar o repositório remoto opcional durante o bootstrap;
4. empacotar o Elephant, caso confirmado como necessário;
5. alinhar os testes de CLI e aguardar o mantenedor concluir o branding;
6. construir e validar o repositório XBPS local;
7. gerar a ISO e executar `release/inspect-iso.sh`.
