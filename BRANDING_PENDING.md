# Pendências de branding

Estado registrado em 3 de agosto de 2026.

Este arquivo reúne exclusivamente as pendências de identidade visual que serão
tratadas pelo mantenedor. Agentes e contribuidores não devem alterar esses itens
sem uma solicitação explícita do mantenedor.

## Decisões concluídas

- O símbolo canônico é a forma reduzida do Void presente em `logo.svg`, sem o
  texto "Void" no centro.
- O wordmark textual é `OMYVOID`.
- A paleta Osaka Jade e o tema do Limine permanecem como definidos em
  `BRANDING.md`.
- Os temas de ícones `Yaru-*` são uma exceção deliberada à remoção de elementos
  herdados do Ubuntu. Eles devem ser preservados e não são uma pendência.
- Os ativos canônicos já aprovados não devem ser regenerados ou substituídos por
  agentes sem autorização explícita.
- O wordmark ASCII embutido em `boot.sh` foi atualizado para corresponder ao `logo.txt` canônico (`OMYVOID`).
- A regra aprovada continua sendo oferecer exatamente dois wallpapers no tema
  Omyvoid.
- Os arquivos de bytecode Python (`__pycache__/` e `*.pyc`) foram removidos do controle de versão e adicionados ao `.gitignore`.

## Pendências reservadas ao mantenedor

- O diretório `themes/omyvoid/backgrounds/` contém atualmente `omyvoid.png`,
  `InRescue.png`, `omyvoid - icon.png` e `omyvoid-text.png`. O mantenedor deve
  decidir quais dois são os ativos finais e alinhar
  `tools/branding/generate_assets.py`; os agentes não devem remover ou alterar
  esses arquivos.

## Verificação ao concluir

- Conferir `logo.svg`, `logo.txt`, `icon.txt`, Waybar, scripts, screensaver,
  Plymouth, SDDM e Limine.
- Confirmar que `boot.sh` apresenta o wordmark aprovado.
- Confirmar o número e os nomes definitivos dos wallpapers.
- Executar `tools/branding/generate_assets.py` e verificar que ele não recria
  ativos removidos.
- Executar `test/omyvoid-iso-test.sh`.
- Manter os temas `Yaru-*` intactos como exceção aprovada.
