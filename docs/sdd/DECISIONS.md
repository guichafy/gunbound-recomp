# Registro de decisões

Todas as decisões abaixo foram consolidadas em 2026-10-11. Não são exigências
imutáveis: registrar substituição e motivo se uma solicitação futura as alterar.

| ID / status | Decisão e motivo | Consequência |
|---|---|---|
| ADR-001 — adotada | Godot 4.7.2 + GDScript + Compatibility; usuário já conhece Godot e engine atende a família de plataformas exigida | Mac primeiro; outras plataformas exigem exportação e QA próprios |
| ADR-002 — adotada | Primeiro modo é treino offline 1×1 contra CPU, para validar sozinho uma partida completa | Não criar servidor, conta, matchmaking ou infraestrutura online agora |
| ADR-003 — adotada | Retirar ranking desta entrega, por instrução explícita posterior do usuário | Manter apelido, XP, nível e vitórias locais; ranking volta ao refinamento online |
| ADR-004 — adotada | Aprendizado a partir do produto final; usuário pediu execução e protótipo funcional | Documentar a solução entregue; aprovações intermediárias da entrega inicial dispensadas, sem ampliar escopo futuro |
| ADR-005 — adotada | Física customizada em passo fixo e compartilhada com previsão da CPU | Uma fonte para balística e colisão; alterações precisam preservar equivalência |
| ADR-006 — adotada | Terreno por máscara de pixels, crateras e raycast DDA | Simplicidade para 2D destrutível; resolução 2 px e fragmentos suspensos são limites atuais |
| ADR-007 — adotada | Turnos por disponibilidade acumulada, com atraso por arma/veículo | Uma ação rápida pode manter iniciativa; não impor alternância estrita |
| ADR-008 — adotada | CPU busca ângulo/força e aplica erro por dificuldade, sem se deslocar | Partida funcional com IA simples; navegação e tática ficam para refino |
| ADR-009 — adotada | Perfil JSON local com gravação temporária e IDs recentes de recompensa | Sem backend; perfil editável pelo usuário, sem promessa de antifraude online |
| ADR-010 — adotada | Arte original via GPT Images, explicitamente autorizada | PNGs e prompts preservados; não usar sprites, mapas ou marca Gunbound |
| ADR-011 — adotada | Executável/PCK internos ASCII, título visível com acento | Corrige selo inválido observado; reexportar sempre pelo script que normaliza e assina |
| ADR-012 — adotada | Git local na `main`; documentação SDD e `AGENTS.md` como entrada para futuras sessões | Fonte/arte/docs no commit; builds/templates/cache ignorados; remoto não definido |
| ADR-013 — adotada em 0.2 | Usuário aprovou o pacote de refinamento com “implementa”; referência visual/técnica dos vídeos/OpenBound | Adaptar HUD e comportamentos em Godot; pacote principal de texturas ausente, nenhum código/asset do fork incorporado |
| ADR-014 — adotada em 0.2 | Mira relativa ao corpo/apoio, com conversão única em `MatchModel` | CPU, canhão e voo concordam; não usar a velocidade sem inclinação para prever o tiro |
| ADR-015 — adotada em 0.2 | Carga crescente com auto-disparo a 100%; pausa cancela sem disparar | Substitui oscilação da força; soltura tardia não duplica tiro |
| ADR-016 — adotada em 0.2 | Animação em `BattleArt`, sem alteração de colisão/posição física | Usa PNG original com transformações/efeitos; sem spritesheets oficiais |
| ADR-017 — adotada em 0.2 | Fila previsão somente após arma conhecida; painel evita vida/identificação de ator vivo | Ordem e custo vêm do modelo; evita informação falsa e sobreposição em crateras |
| ADR-018 — pedido atual, integração pendente | Usuário solicitou os assets/mobiles reais do fork, incluindo Bigfoot | Substitui a restrição artística de ADR-010 para a próxima integração. Pacote externo recebido via Drive e validado; usar sprites reais, sem substitutos gerados |
| ADR-019 — recebimento de assets | Manter pacote original e extração em `.tools/source-assets/`, com checksum/inventário; copiar só recursos utilizados ao integrar | Download de 813 arquivos validado; nenhum binário de cliente/servidor baixado ou executado; jogo ainda 0.2.0 nesta etapa |
| ADR-020 — Bigfoot visual 0.3 | Pedido atual prioriza Bigfoot com sprites reais; integrar atlas/piloto/animações/projéteis como terceiro veículo | PNGs intactos, FPS/offsets do fork, filtro nearest. Vida 1100/movimento 90; armas/física continuam protótipo, sem equivalência integral |
| ADR-021 — pose de tiro | Recuo usa arma registrada; carga reinicia ciclo ao trocar seleção | Evita SS mudar para S1 após turno curto e herdar relógio de outra carga; regressões RED→GREEN |

## Achados resolvidos na revisão inicial

- Ajuda após resultado retirava as ações finais: fechamento agora restaura resultado.
- Colisão por amostragem podia perder canto de célula: substituída por travessia DDA.
- Previsão ignorava o atirador por toda a trajetória: janela de 0,15 s agora é
  compartilhada com o disparo real.
- Barra de vida herdava altura mínima do tema: dimensão ajustada após estilização.
- Áudio headless imediato deixava objetos de playback pendentes: testes de cena
  usam áudio mudo; o aplicativo mantém os efeitos sintetizados.

Esses ajustes têm regressões nos testes. A revisão foi da implementação inicial;
não representa uma nova revisão independente desta documentação.

## Ajuste visual 0.3.1

ADR-022 — adotada: reduzir Bigfoot/piloto juntos, mantendo os pixels originais,
contato com chão e offsets relativos. Escala de arena 60 (antes 80), menu 180
(antes 230). Ajuste de apresentação em REQ-19; regras de colisão/combate preservadas.

## Mage 0.4

ADR-023 — adotada: substituir Carapaça por Mage com atlas/piloto/efeitos/sons
originais. Reutilizar leitor base de atlas sem mudar quadros ou escala Bigfoot.
Dados de combate próprios do Mage consultados pelo modelo, HUD e CPU.

ADR-024 — adotada: manter SS=200 conforme construtor executado do fork, embora
constante SS=300 não seja utilizada lá; EMP antes do dano. Delays750/900/1300
normalizados÷7,5. HP/escudo/regen/mira/hélice seguem dados originais; balística e
regras de desbloqueio SS continuam adaptadas à arena atual. Sem alegar clone
completo nem ampliar para resistência/clima/itens/rede.

ADR-025 — adotada após revisão0.4: prever salvas com o mesmo avanço real sobre
máscara/atores isolados. Prever componentes separadamente no terreno inicial
perdia impactos após o primeiro abrir cratera; fixture com parede de2px verifica
passagem do segundo laser e ausência de mutação do modelo vivo (RED→GREEN).

## Ataques Bigfoot 0.5

ADR-026 — adotada: substituir armas genéricas Bigfoot pelos padrões do emitter
C# (T1 sequencial4, T2 duas rajadas de3 com força±4, SS sequencial8). Danos/raios,
limites por tiro e proporções de delay seguem fonte; gravidade/força/vento da
arena e desbloqueio SS permanecem adaptações explícitas. Substitui a ressalva
sobre armas genéricas Bigfoot de ADR-020/023 para este veículo.

ADR-027 — adotada: tempo de espera separado de idade de voo; previsão executa
mesmo lançamento/voo em cópias isoladas, até12s após último spawn. Nenhuma bomba
pendente aparece, colide ou permite encerrar o voo prematuramente.

ADR-028 — adotada: T2 usa efeito Armor/Flame2 porque essa é a chamada executada
no C#; não o método Bigfoot2 não utilizado. SS imagem tem20 quadros reais; não
ler os10 quadros excedentes solicitados na referência. Proveniência registrada.

## Assets HD 0.6

ADR-029 — adotada: GPT Images integrado conforme solicitação explícita, aparência
clássica confirmada, derivados separados em assets/hd. Substitui somente a
apresentação padrão dos originais de ADR-020/023/028; fontes, áudio, offsets e
combate continuam preservados. Escopo inclui apenas assets já usados, não todos
os628 PNGs do pacote. Não ampliar mobiles ou gameplay por esta solicitação.

ADR-030 — adotada: atlas de quadros chave remasterizados mantêm duração/estados
antigos, com seleção proporcional. Há menos quadros distintos: custo explícito
da geração, não prometer recuperação pixel a pixel das centenas de quadros.
Imagens maiores de seleção evitam ampliar células pequenas do atlas da arena.
Originais disponíveis como fallback automático se o derivado estiver ausente.

ADR-031 — adotada: catálogo de recortes de alpha>8/255 remove influência de ruído
quase invisível no enquadramento. Apenas metadados de recorte; PNGs gerados e
originais permanecem intactos. Destino acompanha alpha footprint original para
manter o contato com terreno e geometria existente. SHA256/dimensões/prompts
registrados; Full HD validado no framebuffer, não inferido pelo prompt.

## Correção de animação 0.6.1

ADR-032 — adotada: substitui ADR-030 somente para render dos mobiles/piloto.
Quadros GPT variam anatomia e estado (Bigfoot moving com clarão); ajuste pelo
alpha original comprimia carro ao incluir aura. Cinco peças constantes HD com
pivôs fixos, relógio contínuo e piloto constante evitam regenerar identidade
a cada quadro. Originais/antigos HD preservados. Rodas acumulam fase de viagem,
não reiniciam no repouso. Morte articulada/fade é adaptação, não restauração.

ADR-033 — adotada: recortes de peças seguem intervalos transparentes reais,
porque o gerador extrapolou células iguais. HDSheet informa catalog_valid;
rig incompleto/sem catálogo retorna conjunto integral original. Não mistura
carro original com piloto HD. Catalogo não altera pixels. Tiros/Fx e demais
consumidores de ADR-031 permanecem inalterados.

## Piloto e tiros 0.6.2

ADR-034 — adotada: figura sentada completa GPT Images substitui cabeça/corpo
independentes de ADR-032, preservando anatomia e apoio dos quadris. Animação por
transformações leves; imagens antigas preservadas.

ADR-035 — adotada: seis cabeças constantes com efeitos separados substituem
quatro fases dos tiros de ADR-030/031. Bigfoot aponta à direita na fonte: usar
ângulo da velocidade, sem PI; chama sempre atrás. Laser segue trail real sem
repetir cabeças. Escala/aspecto fixos eliminam deformação entre fases.

ADR-036 — adotada: crossfade/envelope de impactos e EMP constante substituem
enquadramento quadro a quadro de ADR-031. Catálogo válido obrigatório para Fx,
EMP, cabeças e chamas; fallback original em dados inválidos. Offset da câmera
é apenas visual. Mecânica, sons e duração original preservados.

## Composição 0.6.3

ADR-037 — adotada após feedback: piloto unido de0.6.2 corrigiu anatomia, mas
escala relativa/encaixe permaneciam incorretos. Substituir altura29 e assentos
anteriores pela relação44px de piloto nativo/hulls49/46. Recalibrar canhão e
rodas, preservar aspecto também das peças do veículo e sobreposição natural.
Não gerar novos sprites nem alterar tiros aprovados. Testes temporais anteriores
não mediam proporção relativa; adicionar regressão e comparação GPU original/HD.

## Perfil e roster0.6.4

ADR-038 — adotada: ocultar perna distante no mestre GPT Images. Ordem de camadas
não resolve sobreposição dentro de um PNG inteiro. Novo pilot_side preserva
pilot_seated e registro do assento, com4px extra embaixo para evitar corte;
sem máscara por código. Substitui mestre ativo de ADR-034, proporção ADR-037 mantida.

ADR-039 — adotada por solicitação explícita: remover Escaravelho do jogo ativo.
Preservar IDs Mage1/Bigfoot2 em Dictionary e separar slots UI, normalizar ID
antigo/inválido para Bigfoot. CPU sempre outro mobile. Remover armas/render
exclusivos e excluir PNGs scarab/tortoise do pacote, mantendo histórico no Git.
Substitui roster de3 do baseline. Não reindexar mobiles nem alterar progresso.

## Identidade 0.7

ADR-040 — adotada por solicitação explícita: renomear o projeto para
"Gunbound Recomp" na versão0.7.0 (marco da nova identidade, escolhida pelo
usuário sobre manter0.6.4). Nome visível com espaço; internos ASCII
`GunboundRecomp`/bundle `com.local.gunboundrecomp`/assinatura `GREC` preservam
a normalização de ADR-011. Perfis: usuário optou por começar do zero na pasta
nova `app_userdata/Gunbound Recomp`, sem migração. Documentos históricos
mantêm o nome "Brisa de Aço"; não rebatizar o passado registrado.

ADR-041 — adotada: consolidar o harness em `scripts/check.sh` — uma entrada
para as14suites headless, com log por suite em `.tools/check-logs/`, resumo
consolidado e código de saída!=0 em falha. `--quick` omite partidas longas;
`GODOT=` permite binário alternativo. Suites continuam executáveis isoladas.

## Mapa Miramo Town 0.8

ADR-042 — adotada por solicitação explícita: primeiro mapa original do
OpenBound, Miramo Town A (escolha do usuário), em arena fixa 1280×800 (escolha
do usuário sobre câmera rolante). A colisão deriva do alpha original do
`ForegroundA.png` reamostrado para a grade 640×400 existente; o PNG HD gerado
por GPT Images é apenas visual e recebe a máscara original como alpha. Crateras
seguem `Topography.CreateErosion` (anel escurecido ×0,4). Spawns sorteados pelo
`rng` da partida, um por metade, da lista de `Map.cs`. Terreno procedural
permanece como fallback e para fixtures de teste. Substitui o terreno procedural
de REQ-11 como arena padrão. Detalhes em MAP_0_8.md.

ADR-043 — adotada: geração em blocos sobrepostos. O gerador não produz a faixa
3,9:1 com ganho de resolução em uma só imagem; três blocos 3:2 do foreground e
dois 2:3 do fundo são costurados por `scripts/build_map_hd.py` (feather linear).
Blocos brutos preservados intactos em `source/` com `.gdignore`; o script é
determinístico e registra SHA-256 em `manifest.json`.

## Câmera, vento, clima e Thor 0.9

ADR-044 — adotada por solicitação explícita: câmera rolante em escala nativa
1:1. Substitui a arena fixa e o recorte/escala de ADR-042 (colisão continua pelo
alpha original). Mundo = ForegroundA inteiro; visual HD aplicado no retângulo
do recorte; corte na linha do HUD removido (a câmera mostra a base). Arrasto
manual + seguimento amortecido 1/25.

ADR-045 — adotada: vento 2D do OpenBound (força/ângulo, perturbação por rodada,
clima Wind). Adaptação: sorteio de Wind na largada. Fator 1,3 px/s² por ponto
de força mantém o máximo anterior.

ADR-046 — adotada: clima e Thor vivem no modelo e no laço de voo comum; a
previsão da CPU sempre simula em cópias. Rodada = 2 turnos totais. Fórmulas
copiadas do código (Weakness com fatores do Force). Arte/sons originais.

ADR-047 — adotada por decisão do usuário: não implementar outros mapas nem HD
novo de mapa nesta etapa.

ADR-048 — adotada por escolha do usuário após revisão: o preset original do
Miramo A tem peso 0 para Thor/Espelho/Fraqueza/Ignorância, então o Thor nunca
apareceria. O menu ganha "Clima: original do mapa / todos os efeitos"; o modo
"todos" usa pesos iguais para os 10 tipos (Thor incluído). Padrão continua o
preset original, fiel ao Map.cs.

## HUD original de batalha 0.10

ADR-049 — adotada por solicitação explícita: o console de batalha próprio
(painéis "Armas/Mira/Força/DISPARAR", fila de iniciativa, bússola desenhada,
relógio em texto, barras de vida ProgressBar) é substituído pelo HUD do
OpenBound: barra de ação, botões S1/S2/SS, Options/SkipTurn, barras de força e
movimento, ângulos atual/anterior, previsão de clima na barra, Delayboard,
bússola, TurnTimer, mira, barra de vida, nome e dano flutuante. Layout copiado
dos offsets do C# na tela virtual 800×500 com fator 1,6; a área do mundo passa
de 1280×670 para 1280×664 (substitui o `VIEW_SIZE` de ADR-044).

ADR-050 — adotada por escolha do usuário: carga do tiro igual ao original
(0→100, passo 2 a cada 0,04 s; soltar ou encher dispara). Substitui a carga
15→100 a 65/s e o clique que definia a força; o seletor da barra só marca.

ADR-051 — adotada por escolha do usuário: arte do HUD em HD via GPT Images
(3× o original, ≥ Full HD), recortada de folhas de referência com layout fixo e
alfa do original. Controles sem equivalente no original (mover, virar,
disparar, passar com mouse/toque) ficam como botões pequenos fora da barra.

ADR-052 — adotada por solicitação explícita (0.10.1): ESC/Options abre o
`PopupGameOptions` original em vez da pausa própria (substitui essa parte de
ADR-049). Aplica só o que existe no jogo: SFX (escala o volume dos efeitos),
Scroll Speed (multiplicador do arrasto da câmera; 50 = comportamento atual) e
Background on/off. Aiming Mode, Mouse Speed, BGM e Interface são desenhados
desabilitados. Adaptações: o popup pausa o treino (o original online não
pausa); a pausa própria fica em P e no extra "PAUSA" do popup; o Accept grava
as opções em arquivo próprio ao lado do perfil, como o
`ConfigFileManager.OverwriteGameServerSettings` do original, sem tocar no
progresso. No C# lançado Scroll/Background estavam desativados
("Pre-release deactivation"); aqui ficam ativos porque o pedido os inclui.

## Performance e limites 0.11

ADR-053 — adotada por solicitação explícita: a busca da CPU roda numa thread
do `WorkerThreadPool` sobre um retrato do estado do início do turno, em vez
de um único frame de 90–314 ms. Sorteios de arma e de erro ficam na thread
principal (mesma ordem de RNG); a grade só lê o retrato. Plano idêntico ao
`choose_cpu_shot` síncrono. O fatiamento em frames foi testado e descartado
(atrasava o disparo da CPU de ~1,9 s para ~3,3 s). Não reduzir a grade sem
nova decisão (mudaria a IA).

ADR-054 — adotada por solicitação explícita de implementar os limites: BGM
com as 12 faixas originais `LevelScene/Theme*` (≈17 MB a mais no app), faixa
aleatória ao iniciar e ao terminar cada uma, volume pelo slider BGM (padrão
50). Menu sem música. Substitui o "BGM desabilitado" de ADR-052.

ADR-055 — adotada por pedido explícito: o popup de opções ganha derivados HD
3× por GPT Images (Codex `image_gen`), como o HUD de ADR-051. Aiming Mode,
Mouse Speed, skins e Consolas continuam como limite (sem implementação no
original, cursor do sistema, só skin Blue no pacote, fonte proprietária).

## Modo de mira 0.12

ADR-056 — adotada por solicitação explícita: o rádio Aiming Mode liga o modo
Drag (tiro por arraste do mouse, comportamento do GunBound original segundo
guias de jogadores; o OpenBound não o implementa). Padrão Slice, idêntico ao
comportamento anterior. Força = deslocamento horizontal / 640 px; tremor ±2 a
cada 0,04 s quando o cursor não avança (RNG próprio, amplitude adaptada);
clique sem arraste cancela; sem disparo automático a 100 no Drag (exceção à
invariante da carga). Espaço continua ativo nos dois modos. Botão direito/meio
olha o mapa. Mouse Speed desabilitado com TODO (escalará o arraste); skins:
só Blue, por decisão do usuário. Substitui "Aiming Mode desabilitado" de
ADR-052/055.

## Reorganização SOLID

ADR-057 — adotada por solicitação explícita de aplicar o plano de arquitetura.
Sem mudança de regra de combate, de mira ou de roster. O Match segue a única
fachada de turno, dano e resultado. Armas e limites saem de ramos por ID e
vão para `mobiles.gd`. A previsão copia só a lista de `flight_snapshot.gd` (a cópia usa
`get_script().new()`: `load()` numa thread da CPU trava o importador).
Dano e agenda ficam em módulos chamados pelo Match. A cena delega mira, câmera
e overlays e injeta a máscara em `start`. Papéis nomeados `PLAYER` e `CPU`; o
treino continua 1×1, sem rede. Seeds 81–90 devem permanecer iguais.

## Itens de batalha 0.13

ADR-058 — adotada por solicitação explícita: itens do OpenBound na batalha
(REQ-35..37, ITEMS_0_13.md). Custos de delay originais ÷ 7,5 (conversão de
Mage/Bigfoot), cobrados no uso. Um item por turno; uso desabilita SS no turno;
Ignorância trava a barra; clique fora do turno agenda o uso. Adaptações: os
efeitos de turno terminam também ao passar/esgotar o tempo (no C# Attack/Dig
só voltam no caminho do tiro); Energy Up limitado à vida máxima; teclas F1–F6
como extra; carga padrão Dual, Teleport, Power Up, Energy Up 1 gravada com as
opções. CPU não usa itens neste corte (seeds 81–90 preservadas). Arte nova em
HD por GPT Images (Codex), originais preservados com fallback.

## Shop de avatar — especificação aprovada

ADR-059 — decisões confirmadas pelo usuário: portar cabeça/corpo/óculos/
bandeira do Shop C# em worktree da main, usar Gold/Cash com saldo inicial de
teste sem dinheiro real e incluir distribuição dos oito atributos com efeitos
no combate. Proposta AVATAR_SHOP.md (REQ-38..41). A troca do servidor pelo
perfil local é compatível com o treino offline vigente. Aprovado pelo usuário em 2026-10-12:
1.000 por moeda, orçamento min((nível local−1)×10,180), gênero/equipamento
separados e preview nos mobiles existentes. Ranking permanece retirado;
ItemDelay requer integração do trabalho de itens fora deste worktree.
Nenhuma regra nova implementada nesta preparação.

Auditoria para o plano: Gold do resultado 1×1 usa as constantes de XP4/1
no fluxo C# apesar das constantes Gold10/5; Popularity multiplica o acumulado
após cada tiro; branch2000 repete condição1000 e é inalcançável. O plano
reproduz os caminhos executados, documentando essas peculiaridades. Empate
mantém XP local e propõe Gold de resultado0 no fluxo existente do protótipo.

ADR-059 — implementada no worktree como0.14.0. Os PNGs originais e identidade
composta foram preservados; currículo de pontos usa nível local, sem ranking.
O renderer usa grade real dos atlas e limita recorte feminino à altura27px,
conservando pivô declarado. Transações de perfil2 incluem rollback; seção
Shop inválida não é tratada como ausência de perfil legado.

Auditoria final confirmou ângulo Gold central+180 pela diferença de convenções
entre Crosshair/Projectile C#. Duração/clima/boomer só agregam impactos com dano;
boomer/backward apenas entradas inimigas. Candidato de falha no export .gd não
se reproduziu no Godot4.7.2 (smoke PCK passou antes da alteração); removido gate
redundante por robustez. Três achados Important reais reproduzidos/corrigidos.
ItemDelay é limite assumido pela especificação aprovada, sem importar código
não commitado de outra tarefa. Branch/worktree mantidos; aplicativo0.14.0
exportado para validação local, sem integrar main nem publicar.

ADR-060 — correção por relato do usuário no inventory.png. O avatar equipado
usa o centro Body original, não o registro dos quadris do mestre HD. A montagem
é calculada da configuração existente do MobileSprite (RiderPivot idle,
contact_y−pivot_y e hull_width), transmitida ao rig. Todas as peças compartilham
escala e transform; poses seguem movimento contínuo do chassis. O chassis
passa a cobrir a parte inferior do avatar equipado, como a ordem de profundidade
original. Isso substitui a adaptação arbitrária do assento usada no caminho
AvatarArt da0.14.0; o piloto legado0.6.4 mantém as camadas anteriores. Sem
mudanças de modelo/perfil/PNG. Evidências AVATAR_MOUNT_FIX.md, regressão24 eGPU.

ADR-061 — pedido do usuário: aumentar qualidade dos avatares e aproximar dos
mobiles HD.13peças visíveis em5folhas GPT Images,1254×1254RGBA, mantendo originais,
IDs/preços e registro do avatar0.14.1. Peças constantes evitam deformar anatomia
entre quadros gerados. Relógio e deslocamentos vêm dos quadros originais;
adaptação não restaura todos os gestos/olhos. Recortes/catalogo/hashes permitem
fallback e reprodução. Retratos compartilham as peças da arena. O pivô
normalizado é preservado ao conter cada imagem com aspecto uniforme na caixa
nativa. Source bruto fica fora do export; catalog.json e folhas finais entram.
Substitui o limite “sem HD novo” da entrega0.14.0/0.14.1 para avatares.

ADR-062 — solicitação explícita de integrar todo worktree à main. Itens0.13 e
Shop/HD0.14.2 coexistem na0.14.3. Match.start recebe loadout7º e atributos8º,
sem interpretar arrays ambiguamente. Attack persistente e bonus item somam
antes de subtrair defesa e truncar; Dig também soma. ItemDelay atua no custo
original do item, mantendo AttackDelay independente. Snapshot/previsão usam
os mesmos shell builders e dados copiados; dano climático anexado ao Teleport
entra na contabilidade de Gold. Substitui o limite ItemDelay sem uso real de
ADR-059/061. Suite combinada1584+10partidas e revisão independente sem bugs
importantes. Integração local, sem publicação; worktree isolado preservado.
ADR-063 — correção0.14.4 a pedido do usuário. O centro do bbox da silhueta de
cada quadro não representa o pivô de uma peça constante HD: gerava saltos
independentes de até16px. Registrar todas as peças na caixa de referência e
animar o conjunto em transform contínuo substitui os deslocamentos por quadro
da ADR-061. Metadados originais permanecem preservados para fallback/diagnóstico.
Relógio do piloto independente do pose_age; histórico visual por ator mistura
geometria por0,14s, incluindo interrupções. Física/tempo real das ações iguais.
Na loja, Experimentar é temporário para não possuídos; Vestir equipa e salva
possuídos, com rollback e confirmação. Compra continua separada de equipar.
Critérios/evidências em AVATAR_SMOOTH_0_14_4.md; main local e app assinado,
sem publicação. Gestos/olhos do original continuam limitação do HD constante.

## ADR-066 — paridade de combate dos mobiles com o C#

Pedido explícito de corrigir escudo, regeneração e os demais desvios achados
contra o OpenBound, numa worktree da `main`. Regeneração de escudo passa a
valer para todos os mobiles a cada turno. O SS segue a trava de quatro turnos
próprios e abre no primeiro. O dano volta à fórmula inversa do `CalculateDamage`,
com a caixa real de cada mobile. Queda curta deixa de tirar vida. O roteiro
para os próximos portes fica na skill `gunbound-mobile-port`. Não se cria
tabela de resistências: o C# não aplica os arquétipos de ataque no dano.

## ADR-065 — item some no uso e aura UsingItem

Pedido do usuário: no turno próprio, ao selecionar um item (ou já tê-lo
marcado), o slot esvazia e o mobile recebe a animação de item do Gunbound.
O OpenBound guardava o botão ativado até o `GrantTurn` seguinte
(`removeItemFromBarAction`). Aqui o botão sai na hora do `use_item` e a
barra recompacta; marcar durante o turno adversário continua válido e o
consumo, com a mesma saída do slot, ocorre no início do turno próprio.
A barra segue travada até esse próximo turno. A pose `using_item` permanece
20 quadros a 19 fps. O rig HD não troca anatomia: diamantes e feixes verdes
dos quadros Bigfoot 234–253 e Mage 243–262 viram uma camada separada a 4×,
com o pivô e o contato do atlas. O brilho de carga na boca do canhão não
entra nessa pose. GPT Images não entregou alfa utilizável; as folhas vêm de
`scripts/build_using_item_fx.py`. Fallback é o recorte original.

## ADR-064 — composição clássica do Avatar Shop

A foto enviada pelo usuário orienta o layout3×3, substituindo a adaptação5×5
da ADR-059. C# continua fonte de catálogo/preços/mecânicas; contém15 registros
e não os nove avatares da imagem. Inventário lateral equipa itens possuídos;
atributos ficam em painel modal sem mudar regras. UI recomposta com sprites
originais e controles; HD aprovado mantém aspecto/pivôs/rig da ADR-063.

## ADR-066 — fidelidade das regras OpenBound e interface Shop HD

Auditoria solicitada pelo usuário compara código C# e Godot, preservando
adaptações aprovadas ADR-063/064 (Vestir persistido e grade3×3). Catálogo,
preços, ordem dos atributos e intervalos/FPS dos botões vêm do original;
transação offline mantém validação/rollback em vez de reproduzir falhas C#.
Popup passa a mostrar retrato/preços/categoria e centraliza moeda única.
Regenerar UI raster consumida com GPT Images, mestres constantes/registro
nativo/fallback; anatomia HD aprovada e combate preservados. Plano e
matriz de diferenças em AVATAR_SHOP_PARITY_0_14_6.md.

## ADR-067 — preço integrado à moldura e informação de efeito real

Retirar ColorRect de preço que cobre os detalhes do card. ShopCardStyle
compõe painel branco, faixa azul e acabamento inferior a partir da própria
textura HD/nativa, conservando bordas/cantos/rebites. Retrato126×66 deixa
linha para “Cosmético · sem bônus” e tooltip: melhorias via Atributos.
AvatarMetadata C# não tem bônus por peça; imagem externa não autoriza
inventar números/regras. Perfil/combate/PNG/anatomia permanecem preservados.

## ADR-068 — centro nítido da faixa de preços

Validação do usuário: o fundo dos preços ainda parece borrado. A faixa da
ADR-067 esticava a linha nativa75..76 (4px HD) para27px lógicos, ampliando
ruído/variações da textura. Substituir somente o centro desse recorte por
retângulo vetorial azul uniforme, desenhado no próprio StyleBox. Laterais,
borda branca e acabamento inferior/rebites preservados. Isso substitui a
extração da tira para o preenchimento central da ADR-067; nenhum novo PNG,
modificador, alteração de perfil ou reanimação necessária. Conferir GPU
FullHD/versão nativa, suites de loja e aplicativo reexportado/assinado/PCK.

## ADR-069 — Nak com dados do cliente original sobre o OpenBound

Pedido do usuário: novo mobile Nak "com base no OpenBound". O fork C# só tem
metadados (HP 1100, proteção 35, mira 10–50°, delays 760/910/1310), sons,
miras, retrato e RiderPivot; não há classe, flipbook, folha nem projéteis. O
usuário indicou jglim/gunbound-server e autorizou baixar o cliente original de
jglim/gunbound-launcher; GunBound-Decomp documenta o formato. Decisões: ID 3
sem alterar 1/2 nem o par 1↔2 da CPU (Nak contra Mage); arte original extraída
por leitor próprio (blocos LZHUF de 4 KB) e flipbook do `tank3.epa` com o mesmo
mapeamento que o fork usa para Bigfoot/Mage; dano/raio do characterdata
(200/30, 350/35, 360/35, escolha do usuário); S2 e SS revertidos do código
ofuscado: S2 entra no chão com `vy` ÷ 2, sobe com o dobro da gravidade sem vento
e explode no primeiro pixel livre; SS ignora terreno. Vento comum (sem fator por
tiro). Desenho espelhado: o Nak atira pela cauda. RiderPivot cru do fork recebe
(+5, +4), média do registro de Bigfoot/Mage. HD adiado pelo usuário; Nak fica
fora do rig HD até lá. Substitui a primeira versão deste ADR, que inventava
números e uma gravidade invertida 3×.
