# Omyvoid ${RELEASE_VERSION}

Imagem Omyvoid para Void Linux `x86_64-glibc`, UEFI, Btrfs e Limine.

## Requisitos

- computador x86_64 iniciado em UEFI;
- Secure Boot desativado;
- backup verificado antes de alterar partições.

## Verificação

```bash
sha256sum --check ${RELEASE_FILE}.sha256
minisign -Vm ${RELEASE_FILE} -P '${RELEASE_MINISIGN_PUBLIC_KEY}'
```

Baixe os arquivos pelo GitHub Release ou pela origem pública do Cloudflare R2. Os dois locais devem conter bytes idênticos.

## Instalação

Grave a ISO verificada em uma mídia, inicie em UEFI e selecione o instalador no Limine. A instalação pode apagar o disco selecionado; LUKS é habilitado por padrão.

## Problemas conhecidos

${RELEASE_KNOWN_ISSUES}
