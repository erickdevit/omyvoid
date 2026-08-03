# Estado atual do porte Omyvoid

Relatório de auditoria atualizado em 3 de agosto de 2026 para o estado atual da
branch `dev`.

## Decisão atual

O código está preparado para o mantenedor iniciar a primeira build de ISO de
desenvolvimento. O bootstrap do repositório complementar e a separação de
privilégios foram resolvidos: Rust e XBPS rodam como usuário comum e somente
`void-mklive` recebe root. A árvore ainda precisa de uma construção real em Void
para comprovar os quatro pacotes e o fluxo completo da mídia.

Este relatório não inclui os testes destrutivos em QEMU nem a validação física da
matriz de hardware. Esses testes permanecem sob responsabilidade do mantenedor,
conforme definido anteriormente.

## Estado do repositório remoto

- O repositório público `erickdevit/omyvoid` já existe.
- `origin` aponta para `https://github.com/erickdevit/omyvoid.git`.
- A branch local `dev` acompanha `origin/dev`.
- `dev` é a branch padrão do GitHub.
- A validação de pull requests foi movida para `ubuntu-latest` com o container
  Void glibc oficial; ela não depende de runner privilegiado.
- Os jobs de pacotes e release usam runners separados, respectivamente
  `omyvoid-builder` e `omyvoid-release`; nenhum deles está cadastrado.
- Não há secrets, variables, regras de proteção de branch ou rulesets.
- O environment GitHub `release` existe e aceita somente `dev`, `rc`, `main` e
  tags `v*`; ainda não há aprovadores cadastrados.
- Os workflows GitHub CI e Release estão registrados e ativos.
- A execução `30829810675` do job hospedado foi recusada antes do primeiro passo
  porque a conta GitHub está bloqueada por uma pendência de cobrança. Não houve
  checkout, teste, build de pacote nem build de ISO nessa execução.
- O GitLab CI/CD está definido em `.gitlab-ci.yml`, mas nenhum projeto remoto ou
  runner GitLab foi configurado neste ambiente.

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
- CI/CD equivalente para GitHub e GitLab, com validação isolada, pacote XBPS,
  ISO de desenvolvimento manual, release por tag e links duráveis no R2.
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

## Pendências operacionais da primeira ISO

### Runners

Ainda é necessário cadastrar um runner Void `omyvoid-builder` para pacotes e um
runner Void isolado `omyvoid-release` para a ISO. A separação evita expor o host
que executa `void-mklive` como root a código de pull requests.

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
do job de validação no container Void.

## Resultados da auditoria automatizada

- Sintaxe dos scripts Bash alterados: aprovada.
- Workflows GitHub aprovados pelo `actionlint` 1.7.12 e todos os YAMLs aprovados
  por parser independente.
- `omyvoid commands --check`: aprovado para 313 comandos.
- `test/omyvoid-iso-test.sh`: aprovado integralmente.
- Contratos estáticos de GitHub/GitLab CI/CD: implementados.
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
- A documentação diferencia validação isolada, package builder e release runner,
  incluindo as dependências e variables exigidas no GitHub e GitLab.

## Próximo marco

O próximo marco técnico é a build manual não assinada da primeira ISO `dev`, que
será executada pelo mantenedor. Antes dela:

1. regularizar a cobrança do GitHub e obter o job de validação verde no
   container Void;
2. cadastrar `omyvoid-builder` e construir os quatro pacotes com `xbps-src`;
3. consultar cada pacote com `release/inspect-xbps-repo.sh`;
4. cadastrar o runner isolado `omyvoid-release`;
5. o mantenedor gera a ISO usando o repositório complementar local;
6. executar `release/inspect-iso.sh`.
