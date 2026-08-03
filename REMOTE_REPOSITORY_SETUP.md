# Configuração do repositório remoto e distribuição

Este documento descreve o bootstrap do GitHub, runner Void, repositório XBPS e
Cloudflare R2 do Omyvoid. Não armazene chaves privadas ou tokens neste
repositório.

## Estado inicial confirmado

- Repositório: `https://github.com/erickdevit/omyvoid`.
- Visibilidade: pública.
- Branch padrão: `dev`.
- Remote local: `origin` configurado e sincronizado.
- Workflow CI: registrado e aguardando runner.
- Runner self-hosted: não cadastrado.
- Secrets e variables: não cadastrados.
- Proteções de branch: não configuradas.

## 1. Preparar o host Void

Use um Void Linux `x86_64-glibc` dedicado à build. O usuário do runner não deve
ser root e deve possuir espaço suficiente para `void-packages`, cache XBPS,
rootfs e ISO.

Instale inicialmente:

```bash
sudo xbps-install -Syu
sudo xbps-install -Sy \
  base-devel bash cargo curl git github-cli jq limine minisign mtools rclone \
  ripgrep rsync shellcheck xtools xorriso
```

Confirme os comandos exigidos:

```bash
for command in cargo git jq mcopy mformat minisign rclone rsync \
  shellcheck xbps-install xbps-rindex xlint xorriso; do
  command -v "$command" || echo "Ausente: $command"
done

test -f /usr/share/limine/BOOTX64.EFI
```

O fluxo de build ainda precisa ser ajustado para executar `xbps-src` como usuário
comum e apenas o estágio `void-mklive` com privilégios elevados.

## 2. Cadastrar o runner self-hosted

No GitHub, abra:

`Settings > Actions > Runners > New self-hosted runner`

Escolha Linux x64 e execute no host Void os comandos fornecidos pelo GitHub.
Durante `config.sh`, adicione os labels:

```text
void-linux,x86_64,omyvoid-builder
```

O conjunto final de labels deve conter:

```text
self-hosted,void-linux,x86_64,omyvoid-builder
```

Como o Void usa runit, supervisione `run.sh` com um serviço próprio em vez de
depender de uma unidade systemd. O serviço deve executar o runner como seu
usuário não privilegiado e manter logs sob socklog ou outro destino controlado.

Considerando o runner instalado em `/opt/omyvoid-actions-runner` e pertencente ao
usuário `omyvoid-builder`, um serviço mínimo pode usar:

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

Não conceda `sudo` irrestrito e sem senha ao usuário do runner. Depois da
separação de privilégios do builder, autorize somente o wrapper root necessário
ao `void-mklive`, com caminho e argumentos controlados pelo administrador.

Depois do cadastro, confirme:

```bash
gh api repos/erickdevit/omyvoid/actions/runners \
  --jq '.runners[] | {name,status,busy,labels:[.labels[].name]}'
```

A execução de CI atualmente enfileirada deve começar automaticamente quando um
runner com todos os labels ficar online.

## 3. Criar as branches de promoção

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

## 4. Configurar regras de branch

Após existir ao menos uma execução de CI concluída, crie rulesets para `rc` e
`main`:

- exigir pull request;
- impedir force-push e exclusão;
- exigir a verificação do job de testes;
- exigir branch atualizada antes do merge;
- restringir bypass ao mantenedor;
- exigir tags assinadas para releases estáveis, quando a política de assinatura
  estiver pronta.

Não torne o job `packages` obrigatório para `main` enquanto ele continuar
condicionado apenas a `dev` ou execução manual.

## 5. Bootstrap do repositório XBPS Omyvoid

O repositório complementar deve conter inicialmente:

- `omyvoid-limine-entry-tool`;
- `omyvoid-limine-snapper-sync`;
- `omyvoid-dracut-snapshot`;
- `elephant`, se a dependência for confirmada.

Antes da publicação remota:

1. adicionar e validar o template do Elephant;
2. executar `xlint` em todos os templates;
3. construir os pacotes com `release/build-xbps-repo.sh`;
4. inspecionar `x86_64-repodata` e consultar cada pacote com `xbps-query`;
5. definir a política de chave RSA do XBPS;
6. assinar o índice e os pacotes somente na etapa de release.

Uma chave privada protegida por senha exige que o workflow consiga fornecer a
senha ao `xbps-rindex` sem prompt. O fluxo atual ainda não implementa essa
entrada. Não cadastre uma chave com senha antes de ajustar esse ponto, pois a
release poderá ficar bloqueada esperando interação.

## 6. Preparar Cloudflare R2 e DNS

Crie um bucket exclusivo e preserve a estrutura esperada pelo projeto:

```text
repository/current/
releases/<versao>/
```

O repositório XBPS deve ser publicamente acessível por uma URL estável. A
configuração atual espera:

```text
https://packages.omyvoid.org/current
```

Configure o domínio público do R2 de modo que essa URL contenha diretamente
`x86_64-repodata` e os arquivos `.xbps`, ou altere o código para usar a URL real
definida para o bucket.

Crie uma credencial R2 limitada ao bucket Omyvoid, com permissão apenas para
listar, gravar, substituir e ler os objetos necessários à publicação e
verificação.

## 7. Cadastrar secrets e variable

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
```

Cadastre `OMYVOID_XBPS_PASSPHRASE` somente depois de implementar o consumo não
interativo da senha. Para a primeira ISO local não assinada, secrets e R2 ainda
não são necessários.

## 8. Ordem segura para a primeira ISO

1. Colocar o runner Void online.
2. Corrigir os bloqueadores locais descritos em `CURRENT_STATUS.md`.
3. Obter uma CI verde em `dev`.
4. Executar manualmente o builder sem chaves de release.
5. Inspecionar a ISO com `release/inspect-iso.sh`.
6. Realizar a validação externa definida pelo mantenedor.
7. Somente então cadastrar chaves, publicar o repositório XBPS e testar o R2.
8. Criar `rc` e `main` quando o artefato de desenvolvimento estiver apto à
   promoção.
