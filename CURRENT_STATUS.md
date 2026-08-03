# Estado atual do porte Omyvoid

Relatório de auditoria atualizado em 3 de agosto de 2026 para o estado atual da
branch `dev`.

## Decisão atual

O porte possui a fundação necessária para a primeira ISO de desenvolvimento. O
bootstrap do repositório complementar foi resolvido no código, porém a árvore
ainda precisa de uma construção real em Void para comprovar os quatro pacotes e
o fluxo completo da mídia. A separação de privilégios do builder continua sendo
o bloqueador conhecido anterior a essa execução.

Este relatório não inclui os testes destrutivos em QEMU nem a validação física da
matriz de hardware. Esses testes permanecem sob responsabilidade do mantenedor,
conforme definido anteriormente.

## Estado do repositório remoto

- O repositório público `erickdevit/omyvoid` já existe.
- `origin` aponta para `https://github.com/erickdevit/omyvoid.git`.
- A branch local `dev` acompanha `origin/dev`.
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
- CLI com 313 comandos e metadados válidos.
- Repositório XBPS complementar definido com exatamente quatro pacotes:
  `elephant`, `omyvoid-limine-entry-tool`, `omyvoid-limine-snapper-sync` e
  `omyvoid-dracut-snapshot`.
- Scripts de build, indexação, assinatura, inspeção da ISO e publicação do
  repositório/ISO no R2.
- Chromium como navegador base, com suporte opcional a conta Google preservado
  do Omarchy e exibido condicionalmente no menu de serviços.

## Aplicativos opcionais removidos

Foram retiradas as opções sem pacote aprovado: Ollama, Brave, Edge, Zen,
Heroic, Minecraft, NordVPN, Moonlight, ONCE, Sunshine, Zed e Cursor. Os
instaladores e removedores correspondentes não fazem mais parte da CLI e esses
itens não aparecem nos menus. Google Chrome também foi substituído por Chromium
em instalação, navegador padrão, políticas e integração de tema.

Essa remoção não altera a matriz de hardware herdada, que continua registrada
separadamente abaixo.

## Bloqueadores da primeira ISO

### Privilégios do builder

`install/iso/build-iso.sh` exige usuário comum porque `xbps-src` não pode ser
executado como root, mas chama `mklive.sh` sem elevação. O `void-mklive` atual
exige root. O fluxo precisa separar a construção dos pacotes, feita como usuário
comum, da geração da mídia, executada com os privilégios estritamente
necessários.

### Construção real do repositório

O template do Elephant 2.22.0 foi adicionado e compila o serviço e os oito
providers usados pelo Omyvoid: `desktopapplications`, `websearch`,
`providerlist`, `files`, `symbols`, `calc`, `clipboard` e `menus`. O builder e a
CI exigem os quatro pacotes do repositório.

Ainda faltam `xlint` e uma construção real com `xbps-src` em Void
`x86_64-glibc`. O host Windows atual não fornece as ferramentas XBPS/Go do
ambiente de destino, portanto a validade binária dos plugins Go só poderá ser
confirmada no runner Void.

### Testes que dependem do runner Void

O contrato da CLI foi alinhado: `omyvoid install` abre o instalador do sistema e
`omyvoid install <subcomando>` continua instalando software opcional. A skill do
projeto documenta as duas formas.

No host atual, o teste estrutural da ISO passou integralmente. O teste da CLI
passou por todos os contratos até a etapa Python; a continuação não é executável
de forma confiável pelo Python Windows contra scripts MSYS. A suíte completa,
`shellcheck`, `xlint`, Rust e o build XBPS permanecem como validação obrigatória
do runner Void.

## Resultados da auditoria automatizada

- Sintaxe dos scripts Bash alterados: aprovada.
- `omyvoid commands --check`: aprovado para 313 comandos.
- `test/omyvoid-iso-test.sh`: aprovado integralmente.
- Teste da CLI: aprovado até a etapa que exige interoperabilidade Python/MSYS.
- `shellcheck`, `xlint`, Rust, build real dos pacotes e build da ISO: pendentes
  no runner Void.

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
- A skill diferencia explicitamente o instalador do sistema de seus subcomandos
  de software opcional.
- `CONTRIBUTING.md` menciona um Code of Conduct ainda inexistente.
- A documentação do runner não lista todas as dependências da build/release.

## Próximo marco

O próximo marco técnico é uma build manual não assinada da primeira ISO `dev` em
um runner Void. Para alcançá-lo:

1. cadastrar e preparar o runner Void;
2. corrigir a separação de privilégios do builder;
3. executar `xlint` e construir os quatro pacotes com `xbps-src`;
4. consultar cada pacote no índice local;
5. executar a suíte completa e os testes Rust no Void;
6. gerar a ISO usando apenas o repositório complementar local;
7. executar `release/inspect-iso.sh`.
