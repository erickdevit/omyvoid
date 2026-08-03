# Configuração de CI/CD, repositórios remotos e distribuição

Este documento descreve o bootstrap do GitHub Actions, GitLab CI/CD, runners
Void, repositório XBPS e Cloudflare R2 do Omyvoid. Não armazene chaves privadas
ou tokens neste repositório.

## Estado inicial confirmado

- Repositório: `https://github.com/erickdevit/omyvoid`.
- Visibilidade: pública.
- Branch padrão: `dev`.
- Remote local: `origin` configurado e sincronizado.
- Workflows GitHub CI e Release: registrados e ativos.
- Runners self-hosted GitHub: não cadastrados.
- Secrets e variables: não cadastrados.
- Environment GitHub `release`: criado, limitado a `dev`, `rc`, `main` e tags
  `v*`, ainda sem aprovadores.
- Proteções de branch: não configuradas.
- Pipeline GitLab: definido em `.gitlab-ci.yml`; o projeto/remote GitLab ainda
  precisa ser criado ou conectado pelo mantenedor.

## 1. Preparar o host Void

Use um Void Linux `x86_64-glibc` dedicado à build. O usuário do runner não deve
ser root e deve possuir espaço suficiente para `void-packages`, cache XBPS,
rootfs e ISO.

Instale inicialmente:

```bash
sudo xbps-install -Syu
sudo xbps-install -Sy \
  base-devel bash cargo curl git github-cli glab jq limine minisign mtools \
  rclone ripgrep rsync shellcheck sudo xtools xorriso
```

Confirme os comandos exigidos:

```bash
for command in cargo gh git glab jq mcopy mformat minisign rclone rsync \
  shellcheck sudo xbps-install xbps-rindex xlint xorriso; do
  command -v "$command" || echo "Ausente: $command"
done

test -f /usr/share/limine/BOOTX64.EFI
```

O fluxo já executa Rust, `xbps-src`, indexação, montagem da mídia e assinatura
como usuário comum. Somente `void-mklive`, que exige mounts e chroot, é chamado
com `sudo`. Em CI essa elevação usa modo não interativo e falha antes do build se
o runner não estiver preparado.

## 2. Cadastrar os runners GitHub

A validação de pushes e pull requests usa `ubuntu-latest` com o container Void
oficial `ghcr.io/void-linux/void-glibc-full:latest`. Código de pull requests não
é executado nos hosts privilegiados.

Cadastre dois runners separados para as etapas que exigem estado persistente ou
privilégio:

- `omyvoid-builder`: compila os quatro pacotes XBPS como usuário comum;
- `omyvoid-release`: host isolado para build manual/tag, onde somente o estágio
  `void-mklive` recebe root.

No GitHub, abra:

`Settings > Actions > Runners > New self-hosted runner`

Escolha Linux x64 e execute no host Void os comandos fornecidos pelo GitHub.
No runner de pacotes, adicione os labels:

```text
void-linux,x86_64,omyvoid-builder
```

O conjunto final de labels deve conter:

```text
self-hosted,void-linux,x86_64,omyvoid-builder
```

No runner de release, use:

```text
self-hosted,void-linux,x86_64,omyvoid-release
```

Como o Void usa runit, supervisione `run.sh` com um serviço próprio em vez de
depender de uma unidade systemd. O serviço deve executar o runner como seu
usuário não privilegiado e manter logs sob socklog ou outro destino controlado.

Considerando um runner instalado em `/opt/omyvoid-actions-runner` e pertencente
ao usuário `omyvoid-builder`, um serviço mínimo pode usar:

```bash
sudo install -d -m 0755 /etc/sv/omyvoid-actions-runner
sudo tee /etc/sv/omyvoid-actions-runner/run >/dev/null <<'EOF'
#!/bin/sh
exec 2>&1
cd /opt/omyvoid-actions-runner
exec chpst -u omyvoid-builder:omyvoid-builder ./run.sh
EOF
sudo chmod 0755 /etc/sv/omyvoid-actions-runner/run
sudo ln -snf /etc/sv/omyvoid-actions-runner /var/service/omyvoid-actions-runner
```

O runner `omyvoid-builder` não precisa de sudo: prepare as dependências no host
antes de iniciar o serviço e mantenha o usuário do runner sem permissão de
elevação. O runner `omyvoid-release` executa código de montagem da ISO como root
por exigência do `void-mklive`; trate-o como host descartável, não execute outros
workloads nele e permita somente branches/tags protegidas ou jobs aprovados no
environment `release`.
Não associe o label `omyvoid-release` a um runner usado por pull requests.

Depois do cadastro, confirme:

```bash
gh api repos/erickdevit/omyvoid/actions/runners \
  --jq '.runners[] | {name,status,busy,labels:[.labels[].name]}'
```

O job de validação não depende desses runners. O job `packages` aguarda
`omyvoid-builder`; o workflow Release aguarda `omyvoid-release`.

## 3. Cadastrar os runners GitLab

O job `validate` usa uma imagem OCI Void e deve rodar em um runner Docker
compartilhado ou dedicado, sem acesso aos hosts de release. Para pacotes e ISO,
cadastre runners Void shell separados e bloqueados ao projeto com as tags:

```text
void-linux,x86_64,omyvoid-builder
void-linux,x86_64,omyvoid-release
```

Desative “Run untagged jobs” nesses dois runners. Marque o runner de release
como protected e proteja `dev`, `rc`, `main` e as tags `v*`. O job `iso:dev` é
manual e usa o environment `development`; o job `release` só existe para tags
SemVer e usa `resource_group: production` para impedir duas publicações
simultâneas.

## 4. Criar as branches de promoção

Depois que a primeira CI em `dev` estiver verde, crie `rc` e `main` a partir do
commit aprovado:

```bash
git fetch origin
git push origin origin/dev:refs/heads/rc
git push origin origin/dev:refs/heads/main
```

Mantenha `dev` como branch padrão durante o desenvolvimento inicial. A promoção
deve seguir `dev -> rc -> main`, sem builds diferentes para o mesmo número de
versão.

## 5. Configurar regras de branch

Após existir ao menos uma execução de CI concluída, crie rulesets para `rc` e
`main`:

- exigir pull request;
- impedir force-push e exclusão;
- exigir a verificação do job de testes;
- exigir branch atualizada antes do merge;
- restringir bypass ao mantenedor;
- exigir tags assinadas para releases estáveis, quando a política de assinatura
  estiver pronta.

No GitLab, proteja `rc`, `main` e `v*`, exija merge request e torne `validate` e
`packages` obrigatórios depois que os runners estiverem verdes.

## 6. Bootstrap do repositório XBPS Omyvoid

O repositório complementar deve conter inicialmente:

- `omyvoid-limine-entry-tool`;
- `omyvoid-limine-snapper-sync`;
- `omyvoid-dracut-snapshot`;
- `elephant` 2.22.0, incluindo os oito providers usados pelo Walker.

Essa lista é fechada para a primeira ISO: são quatro pacotes. Os templates
ficam no próprio repositório Git do Omyvoid em `xbps-src/srcpkgs`; os arquivos
`.xbps` e `x86_64-repodata` produzidos são o repositório binário publicado no R2.
Não é necessário criar um segundo repositório Git.

Antes da publicação remota:

1. executar `xlint` em todos os templates;
2. construir os pacotes com `release/build-xbps-repo.sh`;
3. inspecionar `x86_64-repodata` e consultar cada pacote com `xbps-query`;
4. definir a política de chave RSA do XBPS;
5. assinar o índice e os pacotes somente na etapa de release.

Valide localmente no Void:

```bash
release/build-xbps-repo.sh build/repository
release/inspect-xbps-repo.sh build/repository
```

O `xbps-rindex` lê a senha da chave RSA por `XBPS_PASSPHRASE`; GitHub e GitLab
expõem essa variável apenas nos jobs protegidos de release. Para o Minisign,
gere uma chave exclusiva de CI sem senha (`minisign -G -W`) e proteja o conteúdo
no cofre de secrets da plataforma, pois o Minisign não oferece entrada de senha
não interativa equivalente.

## 7. Preparar Cloudflare R2 e DNS

Crie um bucket exclusivo e preserve a estrutura esperada pelo projeto:

```text
current/
releases/<versao>/
```

O repositório XBPS deve ser publicamente acessível por uma URL estável. A
configuração atual espera:

```text
https://packages.omyvoid.org/current
```

Configure `packages.omyvoid.org` como domínio público do bucket. O publisher
sincroniza o índice e os pacotes em `current/`, de modo que
`https://packages.omyvoid.org/current` contenha diretamente
`x86_64-repodata` e os arquivos `.xbps`. O domínio de downloads pode apontar
para o mesmo bucket e servir os artefatos em `releases/<versao>/`.

Crie uma credencial R2 limitada ao bucket Omyvoid, com permissão apenas para
listar, gravar, substituir e ler os objetos necessários à publicação e
verificação.

## 8. Cadastrar secrets e variables no GitHub

Os nomes consumidos pelo workflow são:

```text
OMYVOID_XBPS_SIGNING_KEY
OMYVOID_XBPS_PASSPHRASE
OMYVOID_MINISIGN_SECRET_KEY
OMYVOID_MINISIGN_PUBLIC_KEY
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_ACCOUNT_ID
R2_BUCKET
```

A variable pública é:

```text
OMYVOID_R2_PUBLIC_URL
OMYVOID_XBPS_PUBLIC_URL
```

Cadastre valores pelo GitHub CLI sem colocá-los no histórico ou na linha de
comando:

```bash
gh secret set OMYVOID_XBPS_SIGNING_KEY < /caminho/privado/omyvoid-xbps.pem
gh secret set OMYVOID_MINISIGN_SECRET_KEY < /caminho/privado/omyvoid-minisign.key
gh secret set OMYVOID_MINISIGN_PUBLIC_KEY < /caminho/privado/omyvoid-minisign.pub

gh secret set R2_ACCESS_KEY_ID
gh secret set R2_SECRET_ACCESS_KEY
gh secret set R2_ACCOUNT_ID
gh secret set R2_BUCKET

gh variable set OMYVOID_R2_PUBLIC_URL --body 'https://downloads.omyvoid.org'
gh variable set OMYVOID_XBPS_PUBLIC_URL --body 'https://packages.omyvoid.org/current'
```

O environment `release` já foi criado e limitado às branches de promoção e tags
de versão. Cadastre ao menos um usuário ou time diferente do executor como
aprovador e mova os secrets para esse environment se quiser impedir publicação
sem aprovação manual.
Cadastre `OMYVOID_XBPS_PASSPHRASE` quando a chave RSA estiver criptografada. Para
a primeira ISO local não assinada, secrets e R2 não são necessários.

## 9. Cadastrar variables no GitLab

Em `Settings > CI/CD > Variables`, cadastre como protected e masked quando o
tipo permitir:

```text
OMYVOID_XBPS_PASSPHRASE
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_ACCOUNT_ID
R2_BUCKET
```

Cadastre como variables públicas protegidas:

```text
OMYVOID_R2_PUBLIC_URL=https://downloads.omyvoid.org
OMYVOID_XBPS_PUBLIC_URL=https://packages.omyvoid.org/current
```

As chaves devem ser variables do tipo File, protected, com estes nomes:

```text
OMYVOID_XBPS_SIGNING_KEY_FILE
OMYVOID_MINISIGN_SECRET_KEY_FILE
OMYVOID_MINISIGN_PUBLIC_KEY_FILE
```

O GitLab usa `CI_JOB_TOKEN` por meio de `GLAB_ENABLE_CI_AUTOLOGIN` para criar a
Release e associa links permanentes aos artefatos já verificados no R2.

## 10. Ordem segura para a primeira ISO

1. Obter o job `validate` verde no container Void.
2. Colocar `omyvoid-builder` online e obter o repositório de quatro pacotes.
3. Consultar o repositório com `release/inspect-xbps-repo.sh`.
4. Colocar o runner isolado `omyvoid-release` online.
5. O mantenedor executa manualmente o builder sem chaves de release.
6. Inspecionar a ISO com `release/inspect-iso.sh`.
7. Realizar a validação externa definida pelo mantenedor.
8. Somente então cadastrar chaves, publicar o repositório XBPS e testar o R2.
9. Criar `rc` e `main` quando o artefato de desenvolvimento estiver apto à
   promoção.
