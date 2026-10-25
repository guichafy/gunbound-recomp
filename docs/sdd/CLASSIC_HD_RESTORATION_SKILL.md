# Skill de restauração clássica — REQ-12/19/20

Pedido de 25/10/2026: melhorar `gunbound-classic-hd` com o prompt de
restauração fornecido pelo usuário e validar com imagens de `assets/classic`.
A imagem fonte é a única referência visual. Prioridade: identidade/silhueta,
geometria/registro, paleta/sombreamento, detalhes/contornos, resolução.
Fidelidade prevalece sobre nitidez. O alvo é 4× cada dimensão, quando suportado.

## Plano e critérios antes da implementação

1. Avaliar o comportamento da skill atual em contexto independente.
2. Substituir o padrão de reconstrução/2.5D por restauração conservadora;
   guardar o prompt completo e explicitar limites de geração, alpha e atlas.
3. Validar três fontes completas, sem recortar nem remontar o atlas:
   `lobby/back.png` (800×600 → 3200×2400),
   `lobby/b_gamelist_create.png` (428×45 → 1712×180; quatro estados) e
   `room/b_ready_mobile02.png` (315×47 → 1260×188; cinco estados).
4. Conferir dimensões/aspecto reais, alpha, composição, texto e estados.
   Métricas não comprovam fidelidade sem inspeção visual. Rejeitar os
   candidatos que violarem o contrato; não esticar/recortar para esconder erro.
5. Verificar estrutura, referências e comportamento da skill revisada;
   sincronizar a cópia instalada e registrar resultados observados.

Originais, `.png.import`, arte HD aprovada e mudanças locais preexistentes
permanecem. Os candidatos são experimentais e ficam fora do runtime. Esta
tarefa não integra assets ao jogo, não altera versão, não reexporta app,
não faz commit nem envia mudanças ao remoto.

## Baseline observado

Uma avaliação independente da skill antiga propôs “Reconstrua [...] volumes
suaves e detalhes nítidos”. As dimensões e estados foram identificados, mas
o vocabulário ainda autoriza modificar volume/detalhes. A referência antiga
também prescreve uma segunda imagem de acabamento, materiais e iluminação
2.5D. Esses pontos conflitam com a fonte visual única do pedido atual.

## Resultados observados

Geração integrada `image_gen.imagegen`, modo de edição: três chamadas com
o prompt integral e somente a respectiva fonte visual. Prompt e contrato
efetivamente enviados: `docs/classic-hd-restoration/prompts.json`. PNGs brutos
e relatórios JSON com hashes: subpastas `raw/` e `reports/`. `.gdignore`
mantém esses ensaios fora da importação Godot.

| Fonte | Alvo 4× | Retornado | Resultado |
|---|---|---|---|
| Lobby | 3200×2400 | 1448×1086 RGBA | Rejeitado: resolução e aparência/alpha |
| CREATE, quatro estados | 1712×180 | 2170×725 RGB | Rejeitado: aspecto, resolução e padding |
| Mage, cinco estados | 1260×188 | 2048×768 RGB | Rejeitado: aspecto, resolução e padding |

Inspeção visual: lobby ganhou linhas finas em janelas originalmente vazias,
contraste e gradações diferentes. Seus buracos transparentes viraram grandes
áreas escuras: só2989pixels alpha0, nenhum alpha255,1569539semitransparentes
no resultado; a fonte tem224675pixels alpha0 e255325pixels alpha255, sem
semitransparência. CREATE preservou quatro botões, porém alterou cores das letras
(amarelo/azul em vez de branco/azul), proporção dos elementos e espaço externo.
Mage conservou cinco blocos coloridos, mas adicionou margem vertical e mudou
o desenho/sombreamento do sprite; não é equivalência por pixel. Nenhum bruto
foi recortado, esticado ou aplicado ao jogo. O prompt sozinho não garantiu
fidelidade. Os três resultados não representam uma entrega HD aceita.

## Verificação da skill

- Prompt original preservado integralmente em `references/restoration-prompt.txt`.
  O padrão antigo de referência dupla/2.5D/materiais/luz foi substituído.
- Avaliação independente posterior resolveu cinco cenários: restauração,
  tamanho/aspecto errado, alpha opaco, estados duplicados e tremor de rig
  existente. Exit0 do checker não autoriza aceite visual.
- A revisão reproduziu dois problemas do checker: alpha128→255 e alpha0→8
  não falhavam. Dois testes novos falharam antes da correção. Agora o contrato
  conservador compara todos os bytes alpha com a fonte ampliada em nearest;
  limiar8 é apenas diagnóstico de suporte, não tolerância de opacidade.
- `python3 -m unittest discover -s skills/gunbound-classic-hd/tests -v`:
  **9 testes aprovados** (dimensões/aspecto, grade, opacidade, furos, halo,
  RGB oculto e diferença entre células). Não edita os assets. Métricas RGB
  são diagnóstico; frames, texto e aparência exigem revisão visual.
- `quick_validate.py`: estrutura aprovada. Referências/UI revisadas.
- Cópia instalada em `/Users/guichafy/.codex/skills/gunbound-classic-hd`
  sincronizada (9arquivos); hashes/bytes idênticos à cópia do repositório,
  links locais válidos e9testes executados também na instalação, todos aprovados.
  Backup anterior em `.tools/skill-backups/gunbound-classic-hd-before-restoration-2026-10-25`.

O fluxo anterior de rig/efeito aprovado permanece disponível e explicitamente
separado da restauração integral. Não houve teste Godot/partidas/GPU nesta
tarefa: runtime e arte ativa não foram alterados. Nenhum app foi reexportado.
Aceite do usuário para qualquer futura arte/integração permanece pendente.

## Novo ensaio CREATE — contrato antes da mudança

Pedido posterior: ajustar a skill e repetir com CREATE até entregar ampliação
4× sem margens extras ou mudanças nas cores. REQ-12/19/20 e ADR-099.
Fonte continua `assets/classic/lobby/b_gamelist_create.png`, 428×45 RGBA opaco,
quatro estados de107×45. Saída deve ser1712×180, células428×180 nas posições
originais multiplicadas por4.

Plano: reforçar o verificador com comparação RGBA em resolução integral,
pois a média RGB reduzida pode esconder mudanças de cor/subpixels; testar
mudança de um pixel, estados trocados e alterações que se anulam na média.
Repetir a execução no método definido com o usuário, inspecionar a saída e
guardar fonte/hash, procedimento, bruto e relatório. A alternativa de
repetição de pixels garante preservação exata, mas não cria detalhes novos.
Arte ativa e runtime permanecem fora desta tarefa.

### Execução e resultado do CREATE

Nova tentativa integrada por IA: `raw/create-retry.png`,2164×726RGB,
rejeitada por dimensão/aspecto. A inspeção mostra margens verticais e letras
com amarelo excessivo. Prompt completo em `create-retry-prompt.txt` e
checagem em `reports/create-retry.json`, sob `docs/classic-hd-restoration`.

O usuário respondeu explicitamente: “Sim, priorizar preservação exata dos
pixels (recomendado)”. Com essa escolha foi executado `upscale_exact.py`,
nearest em fator inteiro4, sobre o arquivo fonte completo. Entrega:
`docs/classic-hd-restoration/output/create-4x.png`,1712×180RGBA opaco.
É ampliação determinística, mantendo o aspecto pixelado; não é detalhe
reconstruído por IA nem restauração neural.

`reports/create-4x-exact.json`: contrato técnico aprovado, quatro células
428×180 nas posições0/428/856/1284; zero alterações RGBA/alpha por célula.
`pixel_replication_verified=true`. O status genérico mantém revisão visual
separada da comprovação de pixels. PNG inspecionado no visualizador; aceite
visual do usuário ainda não registrado e integração não solicitada.

Verificação independente por enumeração de coordenadas, sem resize:
**308160pixels comparados, zero divergências; mesmas648cores RGBA**. Fonte
permanece com o hash registrado no primeiro ensaio. Relatório completo em
`reports/create-4x-independent.json`. Sem margens/corte/remontagem ou alteração
de paleta. Fonte e estados ampliados correspondem em cada quadrado4×4.

Skill agora oferece o procedimento reutilizável quando repetição de pixels
for pedida/aceita. Checker ganhou `--exact-pixels`: além do alpha, detecta
mudança de um pixel RGB e mudanças que se anulam na média nativa. Três testes
falharam antes da implementação desse modo. Helper também teve três testes
falhando antes da implementação. Suíte atual: **15testes aprovados**.

Revisão independente posterior, em agente separado, confirmou os308160pixels
e648cores, quatro estados, ausência de padding e inspeção visual, sem problemas
concretos. Cópia instalada sincronizada:11arquivos idênticos, links válidos,
estrutura aprovada em ambas as cópias e15testes aprovados também na instalação.
Backup pré-mudança em `.tools/skill-backups/gunbound-classic-hd-before-create-exact-2026-10-25`.
Nenhum asset ativo, runtime, perfil, versão ou aplicativo foi modificado.

## Lote dos demais botões — plano antes da execução

Pedido seguinte de25/10/2026, REQ-12/19/20: aplicar a mesma repetição exata4×
aos demais botões. Inventário do `assets/classic/manifest.json`:42atlas de
botões, sendo41novos e o CREATE anterior. As cinco imagens estáticas
(fundos/painéis/preenchimento) não são botões.

Plano: conferir inventário contra todos os PNGs `b_*`; guardar hashes de
todos os arquivos de `assets/classic` (incluindo importações e manifest).
Executar o helper existente em41atlas, sem recortar/remontar estados; copiar
o CREATE já conferido para completar o conjunto. Saídas novas em
`assets/hd/classic/buttons_4x/{lobby,room}`, com catálogo de dimensões,
estados, registro de origem e hashes. Cada arquivo deve ter dimensões e
células multiplicadas por4, sem novas cores/alpha/padding.

Verificar cada atlas pelo checker `--exact-pixels` e por enumeração
independente de coordenadas de todos os pixels. Conferir paleta, ordem,
limites de quadros e preservação integral das fontes. Relatórios em
`docs/classic-hd-restoration/reports/buttons-4x`. Inspecionar amostras do lote.
Esta entrega produz derivados; não modifica cena, runtime, versão ou app.

### Resultado do lote

41atlas novos ampliados pelo helper existente; CREATE anterior copiado sem
regeneração. Conjunto final: **42PNGs,197estados,19atlas de lobby e23de sala**.
Arquivos em `assets/hd/classic/buttons_4x/{lobby,room}`. `catalog.json`
registra escala4, dimensões, células/regiões, ordem dos estados, registro
original completo, hashes de fonte/saída e ferramentas utilizadas.

Checker exato aprovado nos42atlas, sem falhas. Enumeração independente de
coordenadas conferiu **8087792pixels RGBA, zero divergências**; todas as
paletas por arquivo são idênticas às fontes. Cada pixel de saída corresponde
à fonte `[x//4,y//4]`; isso preserva o alinhamento dos197estados sem recorte,
remontagem ou margens novas.95arquivos de origem (PNGs, importações e manifest)
foram conferidos por SHA-256 antes/depois, todos intactos.

Relatórios individuais e `summary.json` em
`docs/classic-hd-restoration/reports/buttons-4x`. Inspeção de amostras:
START, canal1, Friends e Dragon. É ampliação pixelada exata; não cria detalhes.
Revisão visual integral pelo usuário e uso no runtime não foram presumidos.

Pacote `docs/classic-hd-restoration/classic-buttons-4x.zip`:42PNGs+catálogo,
43entradas, CRC íntegro e hashes dos42PNGs iguais aos do catálogo.
Não houve alteração de código/skill, testes Godot/GPU novos ou reexportação.

## Ensaio de nitidez no EXIT — pedido posterior

O usuário pediu avaliar melhoria de imagem além da repetição exata antes de
executar qualquer lote. O teste usa EXIT do lobby como referência; começa
pelo estado normal107×45 para avaliar acabamento, separado do atlas ativo.
Objetivo: reduzir degraus nas curvas/contornos e limpar as transições de cor,
preservando desenho clássico, proporções, texto EXIT e posição do ícone.
É restauração visual experimental; altera pixels e não equivale à cópia exata.

Prévia/prompts/registro em `docs/exit-restoration-preview`. Referência original
e atlas4× ativo permanecem intactos. Duas tentativas por IA foram preservadas:
1940×811 com alteração do amarelo/ícone, e1934×813 com faixa preta superior
adicionada de109px e geometria diferente. Não foram aceitas para produção.

O usuário escolheu explicitamente testar suavização conservadora. Novo
`exit-4x-bicubic.png`: **1712×180, quatro estados de428×180**, normal/hover/
pressionado/desabilitado. Cada quadro107×45 foi ampliado isoladamente com
Pillow BICUBIC e colocado na mesma posição4×, evitando mistura com o estado
vizinho. Alpha opaco preservado, sem margens novas; cores vizinhas interpoladas.
Não é preservação exata de pixels nem detalhe reconstruído por IA.

`bicubic-report.json`: dimensão/grade/alpha aprovados, quatro células,
`pixel_replication_verified=false` como esperado. A comparação permite
examinar os quatro estados na mesma escala e alternar a divisão antes/depois;
seletor e slider conferidos no navegador. `reference.json` registra origem,
hashes, dimensões e método. Hashes da fonte e do atlas ativo permanecem iguais.
Aceite visual do acabamento e qualquer lote/integração continuam pendentes.
Sem alteração de runtime ou aplicativo.
