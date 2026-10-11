# Hand-off — Brisa de Aço 0.6.0

## Entrega atual 0.6.0: assets HD

Pedido: melhorar Bigfoot, tiros e assets importados com GPT Images. Preferência
confirmada: aparência clássica com detalhes mais nítidos. REQ-19/12/20; plano
em `HD_ASSETS_0_6.md`. Sete PNGs separados em `assets/hd`: Bigfoot/Mage4×8,
piloto4×2, tiros4×6, efeitos6×6, heroes2×1 eEMP1254×1254. Seleção usa heroes;
arena60/menu180 preservados. Originais PNG/MP3/JSON comparados byte a byte com
Git, nenhum alterado. Sons, combate, terreno e progresso permanecem os atuais.

`hd_sheet.gd` alinha a figura à área visível do quadro original, filtro linear.
`mobile_sprite.gd.hd_frame` converte estado antigo a4 quadros chave, preservando
duração/índices originais; saúde baixa modula cor. Tiros têm4 fases/Fx6; MageSS
usa fonte maior girando com o efeito. Menos imagens distintas por animação:
não anunciar recuperação exata dos419 quadros ou equivalência artística total.
Ausência de derivado/quadro usa original automaticamente.

Prompts/ferramenta em `assets/hd/GENERATION.json`; dimensões/hashes/recortes em
`atlas_regions.json`. Alpha1/255 fora da figura deformava enquadramento:
catálogo considera alpha>8/255 somente para recorte, sem editar PNGs. Regenerar
por `scripts/catalog_hd_assets.py` (Python+Pillow) depois de trocar derivado.
JSON normaliza números em int; preset inclui explicitamente esse arquivo.

Validação: **439 checks**, zero falhas (251 anteriores+188 HD). Dez partidas
naturais seeds81–90 mantiveram17/10/8/7/10/8/15/9/11/20 tiros, zero falhas;
modelos de combate sem diff. RED→GREEN para suporte HD, ruído, heroes eEMP.
CenaMage15/Bigfoot14 repetidas após EMP final. Perfis isolados nos testes.
App/ZIP0.6.0 Universal reexportados, assinatura profunda/estrita válida e
runtime nativo sem erros. PCK sozinho em projeto vazio validou derivados,
JSON de recortes e salvas4/6/8, zero falhas.

16 capturas GPU em `docs/hd`, framebuffer1920×1080, cena1280×800 escalada1,35
com margem96px. Resolução lógica/exportação não mudaram. Script exige efeito
do mobile/arma antes de salvar impacto; primeiras capturas MageT1/SS tinham
chegado à CPU sem explosão e foram rejeitadas. Mage usa força65 na captura
natural corrigida. Não houve teste manual completo; usuário avalia arte/fluidez.
Revisão independente aprovou a implementação e os impactos corrigidos de Mage
T1/SS, sem achados pendentes. Commit/tag local v0.6.0.

```sh
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
python3 scripts/build_macos.py
```

Versionamento local; sem remoto, push ou publicação. Próximo passo: usuário
validar aparência, animações e uso funcional. Seções abaixo são histórico.

## Entrega anterior 0.5.0: ataques Bigfoot

Pedido atual: identificar no C# e assets os tiros T1/T2/SS e reproduzir as
salvas próprias do Bigfoot. Requisitos03–09/19; plano e dados exatos em
`BIGFOOT_ATTACKS_0_5.md`. Bigfoot mantém arena60/menu180. Mage preservado.

- T1:4 bombas, intervalos0,2s, dispersão local+3/−3/0/0°.
- T2:duas rajadas de3 em0,2/0,4s, força−4/0/+4 pontos por rajada.
- SS:8 bombas, intervalos0,125s, dispersão T1 repetida.
- Dano por bomba90/70/90 e raio25; delays770/920/1320÷7,5; mira18–40° eSS23–35°.
- Bullet1/2/3, explosões e seis sons originais. T2 usa Armor/Flame2 como a chamada
  C# executada; SS imagem tem20 quadros, não os30 solicitados no fork.

`bigfoot_attacks.gd` guarda dados/emitter. `spawn_at`/`launched`/`flight_elapsed`
separam espera e voo; bombas pendentes não envelhecem, aparecem ou colidem.
Todo turno espera a salva acabar. CPU executa o mesmo avanço e agendamento em
cópias isoladas, incluindo crateras/mortes, até12s após o último lançamento.
`shot_velocity` aplica dispersão depois de limitar mira base; força T2 pode
chegar11–104% após ajuste, sem comprimir variantes nas bordas. HUD muda limites
por tiro e bloqueia sinais do slider ao ajustar faixa, evitando sobrescrever
mira com thumb antigo. Pausa congela pendentes/voo; reinício limpa a salva.

Validação **251 checks**, zero falhas: anteriores181 +56 ataques +14 cena.
Dez partidas naturais seeds81–90 concluíram com17/10/8/7/10/8/15/9/11/20 tiros;
87–88 Bigfoot jogador,89–90 Bigfoot adversárioCPU. Teste Mage de escudo agora usa
Escaravelho para isolar o Pulso145; fila de cena usa ready215 para ficar entre
novos delays Bigfoot. São fixtures atualizadas por mudança intencional de perfil.
Revisão independente aprovada: dados/assets conferidos por hash e72 cenários
adicionais de previsão versus voo, incluindo bordas, direções e deltas.

Capturas GPU reais: `docs/bigfoot-{t1,t2,ss}.png`, `*-impact.png` e
`bigfoot-t2-pending.png`; capturas antigas de menu/arena/carga/movimento/tiro
atualizadas. Sem validação manual completa de áudio/mouse. Balística mundial,
resistências, clima/Thor, itens e regenHP35 não foram portados. SS continua
terceiro turno próprio/um uso por partida. Não anunciar equivalência integral.

App/ZIP **0.5.0 Universal arm64/x86_64** reexportados por `build_macos.py`,
assinatura profunda/estrita válida. Runtime independente iniciou sem erros;
PCK carregado sozinho em projeto vazio com perfil isolado validou salvas4/6/8,
quadros/piloto, efeitos e12 streams de áudio Bigfoot/Mage, zero falhas.
Commit/tag local `v0.5.0`; nenhum remoto/push/publicação.

Novos comandos:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_bigfoot_attacks.gd
```

Perfis isolados em `.tools/`. Próximo passo: usuário validar T1/T2/SS, mouse,
áudio/volume, pausa e fim de partida conforme `docs/VALIDACAO.md`. Demais mobiles
ou rede/ranking/mobile exigem nova solicitação. Seções abaixo são histórico.

## Entrega anterior 0.4.0: Mage

Pedido: implementar o outro veículo como Mage do Gunbound com os assets recebidos.
Mage substitui Carapaça (índice 1), selecionável e adversário do Bigfoot padrão.
Bigfoot mantém escala de arena 60/menu 180. Fonte/escopo em `MAGE_0_4.md`; REQ-19
avança com Mage, sem concluir ataques oficiais do Bigfoot ou os demais mobiles.

Mage usa atlas/piloto/offsets, lasers/orbe, efeitos e seis sons originais. PNGs,
MP3s e JSON intactos, hashes/avisos em `assets/openbound/`. `mobile_sprite.gd`
compartilha leitor de atlas; `mage_sprite.gd` traz dados e efeitos específicos.
Vida 760, escudo 220, regeneração 20 por turno próprio até 220 + HP perdido,
mira 15–50°. Tiro 1: laser 150; tiro 2: dois lasers helicoidais de 200; SS: orbe
200 com EMP zerando escudos próximos. Dano/raios/delays no plano. SS usa valor
executado do fork (200, apesar da constante 300 não usada). Delays normalizados
por 7,5; força/gravidade/vento e desbloqueio SS mantêm adaptações do protótipo.
Não declarar reprodução integral do cliente Gunbound.

`weapon_rules/aim_limits` abastecem modelo, CPU, fila e HUD. Hélice usa
`Combat.sample_position`; `hit_pos` guarda collider físico real. Salvas previstas
executam o mesmo voo em cópias de máscara/atores, incluindo crateras e mortes,
sem imagens GPU. Revisão encontrou divergência quando o primeiro laser abre
passagem para o segundo; corrigida e revisada com regressão RED→GREEN da parede.
HUD mostra escudo, limites reais de mira e nomes de arma. Pausa congela hélice e
quadros; carga da CPU segue plano/arma. Morte Mage completa antes do resultado.

Validação fresca: **181 checks** (40 + 28 modelos, 13 + 21 cena, 28 Bigfoot,
36 Mage e 15 cena Mage), zero falhas. Oito partidas naturais seeds 81–88 concluíram
em **24/10/8/17/17/8/29/19 tiros**. Revisão independente aprovada após correção.
Capturas GPU em `docs/mage-{menu,arena,charge,s2,ss,impact}.png`; Bigfoot capturas
atualizadas com Mage adversário. Impacto Mage é fixture visual controlada; partidas
naturais são evidência separada. Não houve teste manual completo de mouse.

App/ZIP **0.4.0 Universal arm64/x86_64** reexportados pelo script. Assinatura
profunda/estrita válida; runtime independente headless iniciou sem erros. O
runtime release não aceita `--script`; a validação detalhada do PCK foi feita
carregando somente o pacote exportado em projeto vazio, com perfil isolado: JSON,
seis áudios, estado Mage e disparo carregados, zero falhas. Avisos incluídos.
Versionamento local com tag `v0.4.0`; nenhum remoto/push/publicação.

Novos comandos, além das suites anteriores:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_mage.gd
```

Perfis de teste/captura isolados em `.tools/`. Aplicativo e ZIP nos caminhos do
baseline abaixo; usuário deve validar funcionalmente seguindo `docs/VALIDACAO.md`.
Próximo passo é feedback da entrega, sem ampliar rede/ranking/mobile ou demais
mobiles automaticamente. Seções abaixo preservam evidências e limites históricos.

## Ajuste anterior 0.3.1: Bigfoot menor

Pedido do usuário: diminuir o carro e realizar versionamento. Bigfoot e piloto
reduzidos juntos de 80 para 60 unidades visuais na arena (25%) e de 230 para 180
na prévia do menu. Não houve alteração de PNG, regras, colisão ou perfil.
Capturas `docs/bigfoot-*.png` atualizadas. Passaram os 28 checks Bigfoot existentes;
novos testes de constantes de estilo não foram necessários. Aplicativo/ZIP 0.3.1
reexportados; assinatura e execução independente verificadas. Commit local da
mudança; nenhum remoto/push. Os 130 checks e oito partidas abaixo são evidência
da integração 0.3.0 anterior, não uma nova execução integral neste ajuste visual.

## Integração 0.3.0: Bigfoot com sprites originais

Bigfoot foi integrado como terceira opção, selecionada inicialmente no menu.
Atlas, piloto padrão masculino, offsets por quadro e projéteis são os originais
do pacote recebido, sem alterar PNGs. Arquivos usados em `assets/openbound/`;
leitor `scripts/bigfoot_sprite.gd`, poses em `battle_art.gd`. Capturas GPU reais:
`docs/bigfoot-menu.png`, `bigfoot-arena.png`, `bigfoot-moving.png`,
`bigfoot-charge.png` e `bigfoot-firing.png`. Fonte/avisos e hashes preservados.

Plano em `BIGFOOT_0_3.md`. 130 verificações (40+28 modelos, 13+21 cena, 28 Bigfoot)
passaram; oito partidas seeds 81–88 concluíram, incluindo duas Bigfoot. Revisão
independente encontrou troca de quadros SS após turno rápido; corrigida com
RED→GREEN. Trocar arma durante carga também reinicia seu próprio ciclo. JSON do
piloto e avisos de referência incluídos no pacote. App/ZIP 0.3.0 Universal exportado.

Esta é a integração visual Bigfoot. Armas ainda mantêm dano, quantidade, atraso
e balística do protótipo; salvas 4/6/8, resistências, áudio específico e outros
mobiles não foram portados. Vida 1100 e movimento 90. Não anunciar reprodução
completa de Gunbound. Usuário ainda precisa validar funcionalmente no aplicativo.

Novo teste: Godot `--headless --path . --script tests/test_bigfoot.gd`.
Nova captura: Godot `--path . --script tests/capture_bigfoot.gd` (perfil isolado).
Demais comandos do baseline abaixo continuam válidos; `test_matches` agora joga
oito partidas. Próximo passo: feedback visual/funcional e ataques/próximos mobiles
conforme nova solicitação. Textos sobre a entrega 0.2 abaixo são histórico.

## Histórico do pedido e recebimento de assets

O usuário pediu copiar e integrar Bigfoot e outros mobiles reais do fork
informado, substituindo a aproximação visual por maior fidelidade. Nova auditoria
das duas branches/releases e do pipeline confirma ausência do pacote: 803 fontes
referidas por `Content.mgcb`, todas ausentes. Código/metadados Bigfoot existem;
pixels dos sprites e projéteis não. Ver `ORIGINAL_ASSETS.md`.

O usuário forneceu a pasta Drive; **Game Assets.rar já está baixado, extraído e
validado** em `.tools/source-assets/`. Conteúdo em `.tools/source-assets/content/`;
manifesto em `.tools/source-assets/manifest.json`. São 813 arquivos, incluindo os
dez mobiles reais, projéteis, efeitos e áudio; todos os 803 assets referidos pelo
pipeline estão disponíveis. RAR íntegro e 628 PNGs verificados, sem imagens inválidas.
Detalhes e checksum em `ORIGINAL_ASSETS.md`. Não pedir novamente o pacote.

Próximo trabalho: integrar spritesheets e regras por mobile, começando por Bigfoot.
Versão executável permanece 0.2.0; não anunciar integração ou novo build antes de
implementar e verificar. Não gerar substitutos visuais nem usar a restrição de
arte original do baseline como veto ao pedido. Os downloads ficam fora do Git;
copiar para `assets/openbound/` somente os recursos usados na implementação.

## Estado atual: refinamento 0.2 entregue

Em 2026-10-11, após `c530e23`, o usuário solicitou melhorias de mecânica,
animações e design a partir de três vídeos e do fork Chafy-Studio/_OpenBound.
Pesquisa registrada em `GUNBOUND_REFERENCES.md`; design/execução em
`REFINEMENT_0_2.md`. O usuário aprovou com “implementa”. Versão 0.2.0 implementada,
testada, revisada e reexportada; próxima etapa é feedback funcional do usuário.

O pacote principal de sprites não está no fork. Nenhum código/asset do OpenBound
foi incorporado; a proposta utiliza nossa arte original e adapta comportamentos.
Aplicativo e ZIP locais agora são 0.2.0. A pesquisa está em `.tools/`, fora do Git.

Mudanças: console azul metálico, armas 1/2/SS, força graduada e marcador anterior,
fila prevista, bússola, movimento que vira, apoio inclinado afetando mira e
auto-disparo a 100%. `battle_art.gd` cuida de repouso/movimento/carga/recuo/dano/
destruição e clarão/detritos/fumaça. Animações por código sobre PNGs originais.
Pausa cancela carga sem atirar e congela animação. Perfil e nome do app preservados.

Verificação desta versão: 40 + 28 modelos, 13 + 21 cena = **102**, zero falhas;
seis partidas seeds 81–86 com **24, 10, 10, 17, 6 e 7 tiros**, zero falhas.
Revisão independente encontrou sobreposição de vida após cratera, corrigida com
RED→GREEN. A fila espera a arma da CPU e muda de posição para proteger a vida.
Build Universal 0.2.0, assinatura profunda/estrita válida, executável independente
headless encerrou com código 0. Capturas GPU atualizadas, incluindo `charge.png`.
Não foi realizada validação manual completa de mouse; o roteiro continua pendente.

Comandos adicionais da versão atual, além dos três do baseline abaixo:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement_scene.gd
```

Commits desta entrega são obtidos em `git log`; nenhum push/remoto foi criado.

## Histórico do baseline 0.1 (preservado)

Atualizado em 2026-10-11. Protótipo entregue; aguardando feedback funcional do
usuário. Esta sessão acrescenta SDD e o primeiro snapshot Git, sem mudar o jogo.

## Retomar em uma nova sessão

1. Ler este documento, `SPEC.md`, `DESIGN.md`, `TASKS.md` e `DECISIONS.md`.
2. Conferir `git status`, `git log -5 --oneline` e a solicitação atual do usuário.
3. Consultar requisitos `REQ-*` antes de mudar comportamento; ler o código afetado.
4. Priorizar feedback funcional. Sem nova solicitação, não começar o roadmap.
5. Atualizar especificação, tarefas, decisões e este hand-off ao concluir mudanças.

## O que existe

Jogo 2D original offline 1×1: dois veículos, três armas, vento, terreno destrutível,
vida, dano e quedas, turnos por atraso, CPU com três dificuldades, pausa, ajuda,
resultado/revanche/menu e perfil local. PNGs gerados com GPT Images e efeitos
visuais/sonoros originais. Ranking foi retirado explicitamente.

O aplicativo macOS Universal foi entregue e aberto no computador na sessão
inicial. Fonte é o projeto Godot; aplicativo e ZIP são artefatos locais ignorados.

| Caminho | Uso |
|---|---|
| `project.godot` | Importar no Godot e executar com F5 |
| `scenes/main.tscn` | Cena principal; executar com F6 |
| `builds/Brisa de Aco.app` | Aplicativo local independente |
| `builds/Brisa-de-Aco-macOS.zip` | Pacote local da entrega |
| `docs/VALIDACAO.md` | Roteiro de aceitação funcional pelo usuário |
| `docs/APRENDIZADO.md` | Explicação da implementação para aprender com o resultado |
| `docs/ART.md` | Prompts e origem das imagens |

## Ambiente e checkout novo

Ambiente validado: macOS, Godot **4.7.2.stable.official.ed1daf0bf** em
`/Applications/Godot.app`, GDScript, renderer Compatibility. Python 3 é usado
apenas no empacotamento. Sem dependências Node.js. Outros alvos não foram testados.

Git local na branch `main`, sem remoto na consolidação. Identidade já configurada
no ambiente foi utilizada; não foi criada configuração global nova. O snapshot
contém código, UIDs/import settings, arte, evidências e documentação. Exclui
`.godot/`, `.tools/`, `builds/`, temporários e arquivos locais de credenciais.

Depois de clonar/copiar uma revisão em outro diretório, prepare a pasta usada
pelos testes e importe recursos antes de rodar os scripts:

```sh
mkdir -p .tools
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

Execute a partir da raiz. Em outras máquinas, ajuste o caminho do Godot;
comandos de pacote e assinatura abaixo são exclusivos do macOS.

## Verificações

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
```

Evidência inicial: 40 verificações de modelos + 13 da cena, zero falhas; seis
partidas naturais de modelos, seeds 81–86, encerradas em 10–28 tiros. Os testes
de partidas deixam a IA controlar ambos os atores; não simulam um humano usando
mouse. Testes de cena exercitam handlers reais de input e usam áudio mudo.
Todos os perfis de teste são isolados em `.tools/`, sem conceder XP ao jogador.

As mesmas suites foram reexecutadas na consolidação Git/SDD; consultar o registro
ao final deste hand-off. A revisão independente inicial confirmou as correções
registradas em `DECISIONS.md`.

Capturas de QA em `docs/menu.png`, `arena.png`, `impact.png`, `result.png`.
São renders reais; a captura de resultado usa vitória controlada, não comprova
término natural. Partidas naturais são verificadas separadamente na suite.

Limite da validação inicial: Computador conseguiu ler captura, mas recusou
interação de mouse como `noWindowsAvailable`. Não alegar teste manual completo
do aplicativo por mouse. Ainda falta o relato do usuário sobre uso funcional.

## Reproduzir o aplicativo

O exportador requer `.tools/macos.zip`, não versionado. No computador original
esse arquivo está disponível. Em um checkout novo, baixar o pacote oficial
`Godot_v4.7.2-stable_export_templates.tpz` na
[release Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable),
extrair `templates/macos.zip` e colocá-lo em `.tools/macos.zip`. Não confundir
esse template com o editor. Os presets debug/release apontam para esse arquivo.

```sh
python3 scripts/build_macos.py
codesign --verify --deep --strict --verbose=2 'builds/Brisa de Aco.app'
open 'builds/Brisa de Aco.app'
```

O script exporta, normaliza executável/PCK para `BrisaDeAco`, inclui avisos de
licença Godot, assina ad-hoc, verifica e cria ZIP. Não publicar uma exportação
direta sem essa normalização: foi necessário corrigir assinatura inválida com
nomes internos acentuados. Pacote não notarizado nem publicado; teste local.
Mudanças no código só chegam ao aplicativo depois de reexportar.

## Progresso do jogador e limites

Perfil real no Mac:
`~/Library/Application Support/Godot/app_userdata/Brisa de Aço/profile.json`.
Não apagar, migrar ou usar esse perfil em testes. Sem conta, ranking ou nuvem.

Limites: um mapa, dois veículos, CPU não se move, sprites estáticos com efeitos
por código, terreno de 2 px e fragmentos suspensos. Balanceamento provisório.
Não há protocolos online, builds Windows/Linux ou interface mobile implementados.

O próximo passo é validar a entrega com o usuário e registrar feedback.

## Registro desta consolidação — 2026-10-11

- `test_runner.gd`: 40 verificações, zero falhas, código de saída 0.
- `test_scene.gd`: 13 verificações, zero falhas, código de saída 0.
- `test_matches.gd`: seis partidas, zero falhas, código de saída 0; tiros por
  seed 81–86: 18, 10, 10, 28, 10, 10.
- Assinatura do aplicativo existente: `valid on disk` e
  `satisfies its Designated Requirement` na verificação profunda/estrita.
- Links locais da documentação principal/SDD e os 12 IDs de requisitos conferidos.
- Exclusões Git conferidas para cache, template, build e credenciais locais.

Nenhum comportamento do jogo foi alterado nesta consolidação. Não houve novo
build nem nova validação manual por mouse; o aplicativo é o da entrega inicial.
O commit inicial registra o snapshot completo. Consulte `git log` para obter sua
identificação e `git status` para detectar alterações posteriores.
