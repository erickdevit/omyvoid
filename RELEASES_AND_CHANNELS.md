# Releases e canais do Omyvoid

## Plataforma inicial

A série `0.1` suporta exclusivamente Void Linux `x86_64-glibc`, UEFI, Btrfs e Limine. Legacy BIOS e Secure Boot não fazem parte dessa série.

## Canais

| Canal | Branch | Tag | Uso |
|---|---|---|---|
| Desenvolvimento | `dev` | `vX.Y.Z-dev.N` | Implementação e integração |
| Candidato | `rc` | `vX.Y.Z-rc.N` | Congelamento para validação |
| Estável | `main` | `vX.Y.Z` | Release promovida |

O desenvolvimento começa em `0.1.0-dev.1`. Tags são imutáveis e uma promoção reutiliza o mesmo commit aprovado, sem reconstruir fontes diferentes.

## Artefatos

Cada release publica no GitHub e no Cloudflare R2:

- `omyvoid-X.Y.Z-x86_64.iso`
- `omyvoid-X.Y.Z-x86_64.iso.sha256`
- `omyvoid-X.Y.Z-x86_64.iso.minisig`
- repositório XBPS assinado e seu índice
- chave pública usada para verificar a assinatura

O workflow de release executa em um runner Void Linux self-hosted, valida os testes automatizados, constrói o repositório offline e a ISO, publica no R2 e baixa novamente os artefatos para conferir checksum e assinatura.

## Atualizações

`omyvoid update` cria um snapshot da raiz, atualiza índices e pacotes com XBPS, aplica migrações e reconstrói UKIs e o menu Limine. `/home`, `/var/log` e `/var/cache/xbps` não fazem parte dos snapshots da raiz.

Nenhum workflow promove automaticamente uma versão estável: a promoção e a criação da tag final exigem ação explícita do mantenedor.
