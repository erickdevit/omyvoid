# Publicação do Omyvoid

O código é desenvolvido em `dev`, congelado em `rc` e promovido para `main` somente por ação explícita do mantenedor. Este repositório automatiza testes, build, assinatura, publicação e verificação dos artefatos; a decisão de promoção permanece manual.

## Configuração dos runners

A validação comum roda em um container Void oficial, tanto no GitHub quanto no
GitLab. Pacotes usam um runner Void não privilegiado com o rótulo/tag
`omyvoid-builder`; ISO e publicação usam um runner isolado
`omyvoid-release`. Instale as dependências por
`release/ci-prepare-void.sh` e configure os segredos:

- `OMYVOID_XBPS_SIGNING_KEY`: chave RSA PEM do índice e dos pacotes XBPS.
- `OMYVOID_XBPS_PASSPHRASE`: senha da chave XBPS, quando usada.
- `OMYVOID_MINISIGN_SECRET_KEY`: conteúdo da chave secreta Minisign.
- `OMYVOID_MINISIGN_PUBLIC_KEY`: chave pública Minisign.
- `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ACCOUNT_ID` e `R2_BUCKET`.
- variável `OMYVOID_R2_PUBLIC_URL` para a origem pública de downloads.
- variável `OMYVOID_XBPS_PUBLIC_URL` para o índice público XBPS, normalmente
  `https://packages.omyvoid.org/current`.

## Fluxo

1. Atualize `version` usando SemVer, por exemplo `0.1.0-dev.2`.
2. Execute CI na branch `dev`.
3. Para publicar um artefato de desenvolvimento, acione manualmente o workflow `release` sem criar tag estável.
4. Crie uma tag `vX.Y.Z-rc.N` a partir da branch `rc` para um candidato.
5. Quando o mantenedor decidir promover, avance `main` para o mesmo commit e crie a tag assinada `vX.Y.Z`.

O workflow recusa tags incompatíveis com o conteúdo do arquivo `version`. Depois
do upload, baixa a ISO, checksum, assinatura e índice XBPS pelas URLs públicas do
R2 e verifica os artefatos antes de criar a GitHub Release.

O GitLab segue os mesmos estágios em `.gitlab-ci.yml`: `validate`, `packages`,
`iso:dev` manual e `release` para tags. A configuração operacional completa,
incluindo variables do tipo File no GitLab, está em
`REMOTE_REPOSITORY_SETUP.md`.
