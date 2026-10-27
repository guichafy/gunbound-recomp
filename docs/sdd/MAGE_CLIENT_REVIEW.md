# Revisão Mage: assets, força, relógios e clima

REQ-04/05/07/08/09/19/20/44/45. Pedido de27/10/2026 baseado na revisão
Aduka: revisar e corrigir T1/T2/SS, recursos, potência, emissão/voo e interação
com Tempo (clima, vento e seus elementos), mantendo montagem, avatares e HD.
Sem nova arte, perfil real, versão, exportação, commit ou publicação.

## Fonte e matriz inicial

GunBound.gme SHA256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
base400000, VAx86LE32. graphics.xfs SHA256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Ghidra12.2/JDK26 direto, projeto isolado builds/ghidra-mage-audit;
extratos em .tools/mage-audit. Sem executar cliente Windows.

| Comportamento | Consumidor/fonte | Contrato / decisão |
|---|---|---|
| Emissão |488ac0/EPA|1/2/1 no tick1; confirmar MainAction, som e fases, conservar se corretos|
| Força |LUTs/ballistics/characterdata row25/40|P1..450, gravidade90; vento congelado no lançamento; preservar contrato aprovado|
| Laser |47ebc0/4a6200/4a4950/LaserEffect.xtf|onda13px, fases0/180, avanço40, faixa16colunas; auditar ordem e raster|
| Tornado |4572b0/4a4950/483ff0|conserva24.8, piso horizontal200, duas inversões, saída3, aceleração retoma próximo tick; substituir C#|
| Force/eletricidade |455cc0→4510f0/451030|amostra física, Force20..100 por tick separado do poder; ponte de colunas offline explícita|
| Dano/cratera |41da80/45db20/4e4970|base200/186/380, dimensão66/54/60, aspecto143/134/130; atributos e passes inteiros; confirmar antes do porte|
| EMP |48d8e0→425ac0→48de60|retira escudo antes do blast, distância estrita contra origem−10; raio150, conferir flags/contexto|
| Demais elementos/calendário |WeatherContact/Weather|preservar bridges identificadas até prova específica; não anunciar paridade integral|
| Corpo/piloto/impactos/áudio |tank2/bullet2p/flame/ssflame2/EPA/PCM|comparar pixels, pivôs, duração e consumidor, sem substituir assets corretos|

## Plano de implementação e validação

- [x] Fechar ASM/ABI e consumidores, preservar extratos essenciais e hashes.
- [x] Escrever oráculos independentes e regressões RED de clima, dano/EMP,
  contato no laser e fronteiras temporais. Testar dois sentidos, mínima/máxima
  força, vento horizontal/vertical e itens Dual/Dual+/Teleport/Thunder.
- [x] Portar só divergências comprovadas em MageCombat e laço comum; reutilizar
  aritmética/contato comum comprovados no mesmo PE, sem mudar outros mobiles.
  Dados pré-aquecidos no principal; máscara e estado profundamente copiados.
- [x] Conferir assets/sons originais e sequência GPU1920×1080 temporal com
  T1/T2/SS, dois sentidos, tornado, pausa30quadros e retomada; arena real/HUD.
- [x] Harness completo (modelos, cenas,29partidas), revisão técnica e logs.
  Atualizar SPEC/DESIGN/ADR/TASKS/HANDOFF com resultados, bridges e pendências.

## Limites de aceitação

Captura Godot é validação do porte. Estática não substitui execução original;
PCM idêntico não comprova escuta. Muzzle/apoio, calendário climático, itens e
proteção de voo12s permanecem bridges quando não fechados nesta revisão.

## Contrato portado — ADR-126

`MageCombat` pré-aquece `original/combat_native.json` no principal. Cada
componente usa poder200/186/380, dimensão66/54/60 e aspecto143/134/130,
flags100. MainAction488ac0 passa divisor1/2/1 ao spawner/41da80:
`poder += trunc(3*Attack/divisor)`,
`dimensão += trunc(trunc(Dig/2)/divisor)`. Valores negativos de equipamento
conservam IDIV para zero. Bônus de item offline segue passe separado;
nenhum atributo é somado novamente pelo antigo `Damage.blast` neste caminho.

Colisão455cc0/458920/458a00 usa stride8/refino1, terreno antes de ator,
coordenadas inteiras e AABB comum45d640. T2 varre entre pontos deslocados
da hélice, não entre carriers. Crateras usam scanlines nativas e máscara
original1px, copiada profundamente na previsão; apoio/grade comum preservados.
Dano45db20 usa queda linear, aspectos e passes inteiros de elemento/defesa
já isolados no núcleo compartilhado da revisão Aduka.

EMP48d8e0 chama425ac0: distância estrita150px do hotspot do ator menos10Y,
sem offset de inclinação adicional; esgota escudo antes de48de60→450eb0.
O evento de escudo continua na apresentação/Gold, sem converter esse escudo
em dano deHP nem absorver nele a explosão normal posterior. Flags/contextos
sem equivalente no treino permanecem explicitamente fora da alegação.

T1/T2/SS compartilham a aritmética de tornado comprovada. Apenas o T2 testa
X do ponto da onda:4a5b8c..5bbc publica onda em+f54, usado por4a5d35..5db1.
A revisão independente reproduziu o erro anterior com carrier91/contato86
para coluna90..110; testes também cobrem carrier131/onda133 e o inverso.
Duas inversões e saída3 conservam velocidade; só há piso |vx|200/256px/tick.
Vento e gravidade congelados no lançamento voltam a acelerar no tick seguinte
à terceira saída. Force20..100 acumula uma vez por tick, +8, aplicado como
metade num passe próprio; não altera o poder base. Eletricidade conserva a
rota de choque offline e autoria existente.

## Auditoria audiovisual e revisão

Assets existentes estavam corretos:489quadros (410corpo,15SS,17T1,17T2,
30EMP) comparados pixel a pixel, RiderPivot e EPA conferidos. LaserEffect
256×256/16×16 veio do XTFARGB4444 e também foi conferido por bytes; T1/T2
mantêm ribbons nativos, seções8px, fases0/180,13px/40graus e cores ciano/rosa.
SS usa bullet2p e ssflame2; flame23 ausente não é inventado.21fire/22blast
foram comparados comoPCM com sound.xfs. Nenhum PNG/pivô/asset original,
avatar ou equipamento foi substituído nesta revisão.

Ghidra12.2/JDK26:01..03 OK;04 trouxe MainAction e SS mas não reconheceu
as entradas47ebc0/4a6200. Depois de confirmar os ponteiros nas vtables do
mesmo PE,05 indicou só essas duas entradas e passou. O manifesto parcial04
não é anunciado como completo.18extratos essenciaisC/ASM e hashes em
`docs/mage-review/native-proof.json`; binário permaneceu intacto.

Revisão independente encontrou o P2 de borda do tornado do T2; regressões
RED2→GREEN e revisão final semP1/P2 restantes no delta. Não houve alteração
de regras dos outros mobiles nesta tarefa; trabalho Lightning simultâneo
foi separado na validação final, sem reverter seus arquivos no workspace.

## Validação e limites

A consolidação final do harness fica no registro abaixo. Intermediários nos
logs locais; a primeira rodada completa passou29partidas, mas apontou três
fixtures antigas (`test_runner`, `test_refinement`, `test_attributes`). Elas
usavam máscara alterada apósstart sem sincronizar1px ou esperavam a caixa/
Dig C# antiga. Corrigidas as fixtures com terrenos/alvo/expectativas nativas,
4221checks dirigidos passaram, incluindo4054 da nova suíte Mage.
SS+item é recusado como antes; a cópia da previsão não cobra `ss_lock`, então
o teste iguala somente esse débito de turno antes de comparar todo combate.

Poder1..450/gravidade90, emissão1/2/1 no tick1, EPA/sons, escudo/Gold,
itens e forças dos demais mobiles preservados onde não há delta comprovado.
Carregamento temporal uniforme3s segue decisão aprovada; não reproduz todos
os modos legados. Fraqueza, Mirror, Random, Protection, calendário/posições
de clima e choques elétricos ainda usam bridges offline/C# identificadas.
Geometria/limites de colunas offline, muzzle38px/origem convertida/apoio,
ativação de itens e guarda de voo12s também não são paridade integral.
Sem execução Windows, escuta humana, mouse ou aceite visual do usuário.
Sem app/PCK/ZIP novo, versão, commit ou push nesta tarefa.


GPU final: `capture_mage_review.gd`, M4Pro/gl_compatibility,480quadros
1920×1080, relógio60Hz (8s de vídeo). Seis painéis de voo real mostram
T1/T2/SS sem coluna e com vento(27,−12)/tornado/Force, nos dois sentidos;
impactos1/2/1 em cada sentido/cenário. Ambas pausas30quadros idênticas e
retomada inspecionadas. Captura/escrita49,588s, não medição de performance60FPS.
`capture_mage_game.gd` conferiu sala, arena Miramo/HUD, três tiros reais,
pausa30 e retomada por arma, com perfil de teste e som mudo. Logs GPU finais
sem erros de script/recursos. Clipes/imagens/manifestos em `docs/mage-review`.


Validação estável em `/private/tmp/mage-validation-20261027/project`: cópia
da base local Aduka mais apenas o deltaMage, scripts/fixtures próprios,
assets/cache importado compartilhados e logs isolados. O trabalhoLightning
simultâneo em arquivos comuns foi excluído somente dessa cópia, sem reverter
o workspace. Hashes/base em `verification-snapshot.json`. Após ligar o novo
stride parametrizadoLightning (padrão8), o workspace também passou6839checks
nas suítesMage/MageClientAnimation/AdukaWeather. A mudançaLightning não é
validada integralmente nem atribuída à entregaMage.

Na cópia temporária, a primeira suíte de botões não encontrou seuPNG de
referência emdocs e terminou582checks/0, comSCRIPTERROR. A pasta de referências
foi reanexada e a suíte inteira repetida:596/0,exit0/log semerro. O log parcial
não foi apagado nem classificado como aprovado. OverrideCA local, quando
presente, fica somente na cópia de teste; nenhum pacote é exportado.


### Fechamento observado

Validação consolidada: **20598checksGodot +48testesPython +29partidas,
87suítes aprovadas**, parse de scripts/capturas aprovado.13seeds e16mobiles
terminaram sem falhas, com101s/101s nesta execução. O `check.sh` completo
isolado terminouexit1 apenas peloPNG de referência de botões ausente no
início; reanexada a referência, a suíte completa596/0 foi repetida comexit0.
Não se afirma exit0 para aquele comando completo. A consolidação automática
substitui somente essa entrada pela repetição integral, exige todas as87
suítes/29partidas e preserva os hashes de ambos os logs. Resultado em
`docs/mage-review/verification.json`; logs `.tools/mage-audit/isolated-full-
harness.log`, `isolated-buttons-recheck.log` e `final-check-logs/`.

No workspace integrado durante a revisãoLightning, a regressão dirigida
final também passou6839checks/0. MageCombat, catálogoMobiles e novos testes
foram conferidos por hash com a cópia estável; arquivos originaisMage/PNG/
import intactos. `git diff --check` limpo. Aceite visual/escuta humana pendentes.
