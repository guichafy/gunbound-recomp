# Integração de assets originais — solicitação em andamento

Data: 2026-10-11. O usuário solicitou copiar e integrar os assets reais do fork
Chafy-Studio/_OpenBound, incluindo Bigfoot e outros mobiles, para maior fidelidade.
Esta solicitação altera a direção artística do próximo trabalho; não deve ser
substituída por novas imagens geradas ou por renomear os veículos atuais.

Status: **pacote externo baixado, extraído e validado; integração no jogo pendente**.
O jogo permanece 0.2.0; nenhum mobile original foi integrado e nenhuma nova
exportação foi feita nesta etapa de recebimento.

## Pacote recebido — 2026-10-11

O usuário forneceu a [pasta OpenBound no Google Drive](https://drive.google.com/drive/folders/120agUFRkAARqZNHYxB7NS86VtrPstx-K).
Baixado `Game Assets.rar`, ID `1TpiMowBz1eHOJoqKco2zVm8ulLRj46O9`:

- Arquivo local: `.tools/source-assets/Game Assets.rar`, **118.291.332 bytes**.
- SHA-256: `59fb907b50eb51247b8da768dea3c2e4c33e55e848c9f0109ee3bf6c123a5bdd`.
- Conteúdo extraído: `.tools/source-assets/content/`, **813 arquivos**,
  121.006.200 bytes: 628 PNGs, 176 MP3s, 8 `.spritefont` e 1 `.otf`.
- Manifesto local: `.tools/source-assets/manifest.json`, com dimensões e inventário.
- `unrar t` terminou com código 0; caminhos do arquivo conferidos antes da
  extração; todos os 628 PNGs passaram na leitura/verificação de imagem.
- **Todos os 803 arquivos citados pelo `Content.mgcb` do fork estão presentes.**
  A dependência de arquivos externos foi resolvida; não perguntar novamente pelo pacote.

Spritesheets de mobiles: **Armor, Bigfoot, Dragon, Ice, Knight, Lightning,
Mage, RaonLauncher, Trico e Turtle**. Também há `Random` e duas spritesheets de
minas Raon; esses três conjuntos não devem ser contados como novos veículos.
Bigfoot tem atlas RGBA **2580×3120**, com transparência e quadros de 129×130;
o PNG foi inspecionado visualmente sem alterar seus pixels.

O pacote e a cópia extraída permanecem em `.tools/`, ignorados pelo Git. Quando
integrar, copiar apenas arquivos utilizados para `assets/openbound/`, preservando
os originais e registrando fonte/avisos. Não executar binários de outros pacotes
do Drive; apenas o arquivo de assets foi baixado.

O download pelo navegador encontrou falha na transferência; o mesmo arquivo
público foi obtido pelo endpoint de download do Drive, com tamanho correspondente
ao informado na pasta. Nenhuma conexão de conta Google foi necessária.

## Auditoria anterior do fork (histórico)

Fonte: [Chafy-Studio/_OpenBound](https://github.com/Chafy-Studio/_OpenBound),
`master` em `cb2fc197dd6b0498390219750ca6251bf0582d63`.

- API GitHub: árvore recursiva completa, sem truncamento, 412 arquivos.
- Duas branches: `master` e uma atualização dependabot de System.Drawing.Common.
  Nenhuma tem os spritesheets de mobiles; releases do fork vazias.
- `OpenBound/Content/` contém apenas `Content.mgcb`.
- O pipeline cita **803 fontes de assets; todas ausentes** na cópia desse commit.
- Há 20 PNGs de ferramentas/interface e um JPG do launcher. A imagem
  `NonPlayable.png` foi inspecionada: são indicadores numéricos, não mobiles.
- Bigfoot tem código de veículo/projéteis e `RiderPivot.json`, mas não as imagens.
- [README](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/README.md)
  informa que o pacote principal de texturas é externo e não compartilhado ali.

Relatório local resumido: `.tools/openbound-asset-audit.json`. Cópia de pesquisa:
`.tools/reference-openbound/`; ambos ignorados pelo Git. A consulta do histórico
de `OpenBound/Content/` retornou a inclusão do pipeline, não os sprites referidos.

## Arquivos esperados para Bigfoot

Dentro do pacote `OpenBound/Content/`:

```text
Graphics/Tank/Bigfoot/CharacterSpritesheet.png
Graphics/Tank/Bigfoot/Bullet1.png
Graphics/Tank/Bigfoot/Bullet2.png
Graphics/Tank/Bigfoot/Bullet3.png
Graphics/Special Effects/Tank/Bigfoot/Flame1.png
Graphics/Special Effects/Tank/Bigfoot/Flame2.png
Graphics/Special Effects/Tank/Bigfoot/Flame3.png
```

Também são referidos oito sons Bigfoot e seis máscaras de mira aliada/inimiga.
Para os demais mobiles, procurar `Graphics/Tank/<Mobile>/CharacterSpritesheet.png`
e os projéteis correspondentes. Um pacote completo ou caminho local é preferível
a imagens isoladas; poderá incluir arquivos compilados `.xnb` em vez dos PNGs.

## Informações técnicas já localizadas

`MobileFlipbook.cs` define tamanho de quadro Bigfoot 129×130, pivô (75,88) e
intervalos de repouso, movimento, carga, tiro, dano, queda e morte. Isso descreve
como consumir imagens existentes; não contém seus pixels. Dimensões do atlas e
ordem real de quadros precisam ser conferidas quando o arquivo estiver disponível.

`BigfootProjectile.cs` descreve S1 com quatro projéteis sequenciais, S2 com seis
e SS com oito, cada um com alterações/atrasos próprios. `Parameter.cs` define
dano, raio, massa e influência do vento por tiro. O comportamento não corresponde
às três armas genéricas atuais e exigirá regras por mobile, testadas com CPU/voo.

O código traz GPL-3.0-or-later e autoria de Carlos H.M.S.; o README trata as
texturas separadamente. Preservar avisos e registrar proveniência dos arquivos
efetivamente incorporados. Não foi copiado código ou asset para o jogo nesta auditoria.

## Retomada após obter o pacote

1. Usuário informa pasta/ZIP no Mac ou link direto; não é necessária outra
   confirmação da intenção de usar os assets reais.
2. Inventariar e inspecionar os arquivos; conferir atlas, transparência, pivôs,
   estados, projéteis e sons, sem sobrescrever os PNGs do baseline.
3. Definir a primeira integração com Bigfoot e os outros mobiles efetivamente
   disponíveis; atualizar design/plano SDD com os dados reais.
4. Implementar animação por quadros e armas por mobile, preservando física
   compartilhada, iniciativa, colisão, pausa e perfil. Não anunciar fidelidade
   completa sem validar as regras específicas e a apresentação.
5. Executar testes pertinentes, revisão, captura GPU e nova exportação/assinatura.

Pendência atual: integrar os arquivos recebidos e as regras de cada mobile ao
Godot. Não construir um Bigfoot fictício com a aparência dos veículos atuais:
os sprites e metadados originais agora estão disponíveis localmente.
