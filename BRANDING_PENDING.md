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

## Pendências reservadas ao mantenedor

### Wordmark do instalador online

`boot.sh` ainda mantém um bloco ASCII embutido que não usa o `logo.txt`
canônico. O mantenedor decidirá a forma final e fará a substituição.

### Conjunto de wallpapers do tema Omyvoid

O contrato atual do produto e o teste automatizado esperam dois wallpapers no
tema Omyvoid, mas o diretório contém quatro arquivos:

- `InRescue.png`;
- `omyvoid-icon.png`;
- `omyvoid.png`;
- `omyvoidBackground.png`.

`omyvoid-icon.png` e `omyvoid.png` possuem atualmente o mesmo conteúdo. O
mantenedor decidirá quais dois ativos permanecerão e alinhará o gerador, a
documentação e os testes com essa decisão.

### Higiene do gerador

O bytecode `tools/branding/__pycache__/generate_assets.cpython-312.pyc` está
rastreado pelo Git, e `.gitignore` ainda não ignora caches Python. A limpeza será
feita junto da próxima rodada de branding para evitar misturar uma alteração de
identidade com o trabalho de infraestrutura da ISO.

## Verificação ao concluir

- Conferir `logo.svg`, `logo.txt`, `icon.txt`, Waybar, scripts, screensaver,
  Plymouth, SDDM e Limine.
- Confirmar que `boot.sh` apresenta o wordmark aprovado.
- Confirmar o número e os nomes definitivos dos wallpapers.
- Executar `tools/branding/generate_assets.py` e verificar que ele não recria
  ativos removidos.
- Executar `test/omyvoid-iso-test.sh`.
- Manter os temas `Yaru-*` intactos como exceção aprovada.
