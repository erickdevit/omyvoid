# Omyvoid

Omyvoid porta a experiência do Omybuntu/Omarchy para o Void Linux `x86_64-glibc`. O projeto usa apenas XBPS, runit, Btrfs, dracut e Limine como base de instalação, serviços, armazenamento e boot.

> Estado: `0.1.0-dev.1`. O código está em desenvolvimento; ainda não há uma release estável ou ISO indicada para máquinas de produção.

## Arquitetura

- Instalador TUI para apagar um disco ou instalar no espaço livre ao lado do Windows.
- UEFI obrigatório, Secure Boot desativado e `/boot` FAT32 de 2 GiB.
- Raiz Btrfs obrigatória, opcionalmente dentro de LUKS2/Argon2id.
- Subvolumes `@`, `@home`, `@log`, `@xbps` e `@snapshots`, com `noatime,compress=zstd`.
- Limine e UKIs produzidas por dracut; GRUB não é instalado.
- Até cinco snapshots da raiz pelo Snapper, inicializáveis com OverlayFS e restauráveis sem alterar `/home`, `/var/log` ou o cache XBPS.
- Serviços de sistema e usuário supervisionados pelo runit; áudio PipeWire/WirePlumber e sessão Hyprland iniciada pelo SDDM.
- ISO live offline baseada no `void-mklive`, finalizada com Limine e `xorriso` para UEFI x86_64.

## Interfaces

```text
omyvoid install
omyvoid update
omyvoid pkg restricted install <pacote>
omyvoid snapshot create|list|restore|undo
omyvoid boot refresh|repair
omyvoid recovery
```

## Instalação sobre Void base

A instalação por script aceita somente um Void Linux `x86_64-glibc` limpo, iniciado em UEFI, com Secure Boot desativado. A raiz já precisa ser Btrfs e `/boot` precisa ser uma partição FAT32. O preflight encerra antes de alterar o sistema quando essas condições não são atendidas.

Durante o desenvolvimento:

```bash
OMYVOID_REF=dev bash -c "$(curl -fsSL https://raw.githubusercontent.com/erickdevit/omyvoid/dev/boot.sh)"
```

Para uma instalação em disco vazio ou dual boot, inicie a ISO e execute `omyvoid install`. LUKS é selecionado por padrão, mas pode ser desativado. Não é criada partição swap; zram é habilitado por padrão.

## Boot e recuperação

O arquivo canônico é `/boot/limine.conf`. As UKIs ficam em `/boot/EFI/Linux`, o executável do Limine em `/boot/EFI/Omyvoid`, e `/boot/EFI/BOOT/BOOTX64.EFI` funciona como fallback removível. O menu apresenta o sistema atual, fallback/recuperação, snapshots e carregadores EFI detectados.

`omyvoid update` cria um snapshot antes de executar a atualização XBPS e reconstrói as UKIs e o menu. A mídia live fornece `omyvoid recovery` para desbloquear LUKS, montar a raiz Btrfs, restaurar ou desfazer snapshots e reparar o boot.

## Pacotes e distribuição

Pacotes oficiais vêm dos repositórios Void, nonfree e multilib. Hyprland vem do Blackhole-VL. Integrações próprias são publicadas no repositório XBPS assinado do Omyvoid. Aplicativos restritos são compilados a partir de templates `xbps-src` com `XBPS_ALLOW_RESTRICTED=yes`; Flatpak, Snap, AppImage e instaladores binários avulsos não fazem parte do produto.

Builds de desenvolvimento e releases são produzidos em runner Void Linux self-hosted. A ISO, o repositório XBPS, checksums e assinaturas serão publicados no GitHub e no Cloudflare R2.

## Desenvolvimento

```bash
./test/run.sh
cargo test --manifest-path installer/Cargo.toml
shellcheck bin/omyvoid* install/**/*.sh test/*.sh
```

O build completo da ISO deve ser executado em Void Linux:

```bash
install/iso/build-iso.sh
```

Consulte [AGENTS.md](AGENTS.md) para estilo e convenções e [CONTRIBUTING.md](CONTRIBUTING.md) para o fluxo de contribuição.

## Procedência

O histórico começa com um snapshot sem histórico anterior do [Omybuntu](https://github.com/erickdevit/omybuntu), commit `9e89dd355c48ef74eeead1ccf5a677d15293c826`. O Omybuntu, por sua vez, porta o [Omarchy](https://github.com/basecamp/omarchy). Detalhes e atribuições adicionais estão em [NOTICE](NOTICE).

## Licença

O código original deste repositório é distribuído sob a [licença MIT](LICENSE). Componentes e recursos de terceiros permanecem sob suas respectivas licenças.
