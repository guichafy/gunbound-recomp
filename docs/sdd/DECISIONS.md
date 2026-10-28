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

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

A foto enviada pelo usuário orienta o layout3×3, substituindo a adaptação5×5
da ADR-059. C# continua fonte de catálogo/preços/mecânicas; contém15 registros
e não os nove avatares da imagem. Inventário lateral equipa itens possuídos;
atributos ficam em painel modal sem mudar regras. UI recomposta com sprites
originais e controles; HD aprovado mantém aspecto/pivôs/rig da ADR-063.

## ADR-066 — fidelidade das regras OpenBound e interface Shop HD

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Auditoria solicitada pelo usuário compara código C# e Godot, preservando
adaptações aprovadas ADR-063/064 (Vestir persistido e grade3×3). Catálogo,
preços, ordem dos atributos e intervalos/FPS dos botões vêm do original;
transação offline mantém validação/rollback em vez de reproduzir falhas C#.
Popup passa a mostrar retrato/preços/categoria e centraliza moeda única.
Regenerar UI raster consumida com GPT Images, mestres constantes/registro
nativo/fallback; anatomia HD aprovada e combate preservados. Plano e
matriz de diferenças em AVATAR_SHOP_PARITY_0_14_6.md.

## ADR-067 — preço integrado à moldura e informação de efeito real

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Retirar ColorRect de preço que cobre os detalhes do card. ShopCardStyle
compõe painel branco, faixa azul e acabamento inferior a partir da própria
textura HD/nativa, conservando bordas/cantos/rebites. Retrato126×66 deixa
linha para “Cosmético · sem bônus” e tooltip: melhorias via Atributos.
AvatarMetadata C# não tem bônus por peça; imagem externa não autoriza
inventar números/regras. Perfil/combate/PNG/anatomia permanecem preservados.

## ADR-068 — centro nítido da faixa de preços

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Validação do usuário: o fundo dos preços ainda parece borrado. A faixa da
ADR-067 esticava a linha nativa75..76 (4px HD) para27px lógicos, ampliando
ruído/variações da textura. Substituir somente o centro desse recorte por
retângulo vetorial azul uniforme, desenhado no próprio StyleBox. Laterais,
borda branca e acabamento inferior/rebites preservados. Isso substitui a
extração da tira para o preenchimento central da ADR-067; nenhum novo PNG,
modificador, alteração de perfil ou reanimação necessária. Conferir GPU
FullHD/versão nativa, suites de loja e aplicativo reexportado/assinado/PCK.

## ADR-069 — estado coerente e posicionamento da loja

Revisão contra C#: usuário escolheu abas acima dos cards e rodapé na ordem
Experimentar/Vestir→Comprar→Presente. Preservar grade3×3/lista lateral;
alinhar legendas em áreas separadas do ícone, com hitbox incluindo o texto.
Crop Miramo com proporção nativa, em vez de esticar imagem. Seleção ausente
da página filtrada deve limpar ações; save falho ao vestir deve preservar
seleção/equipamento/prévia e mostrar erro, incluindo clique pela grade.
Não adicionar bônus por peça, novos assets/rig nem alterações de combate.

## ADR-070 — loja Full HD orientada pelo vídeo

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Pedido19/10/2026 substitui a composição4:3 da loja pela adaptação16:9 da
referência em vídeo: avatar sozinho/alternância mobile, grade3×3 e inventário
compacto. Preservar as correções transacionais0.14.9; retratos e rig mantêm
aspecto e âncoras. Fundo regenerado separado dos controles e textos. Imagens
com atributos por peça não autorizam inventar bônus no catálogo C# atual.
Geometria do layout antigo em ADR-064/069 é substituída; demais contratos
permanecem. Ordem do rodapé segue resposta específica do usuário.

Resposta explícita: seguir o vídeo, Presente→Comprar→Experimentar. Substitui
a ordem do rodapé da ADR-069.


Implementação0.15: a Window usa pixels físicos enquanto a loja está aberta e
restaura stretch1280×800 na saída. Inspeção do PCK identificou um retrato
nativo60×56 compartilhado pelos slots vazios No Goggles/No Flag; regenerá-lo
como miniatura de apresentação, sem adicioná-lo às peças vestíveis do rig.


## ADR-071 — design do cliente XFS

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Pedido20/10/2026 adota jglim/gunbound-server + launcher/graphics.xfs como fonte.
Usar frames store_* comprovados pela captura do cliente, não avatarmode antigo.
Preservar800×600 em FullHD, com catálogo à esquerda, inventário à direita,
Try/Buy abaixo da grade e ações do inventário à direita. Substitui ADR-070
quanto ao layout/ordem; preço vetorial uniforme preserva correção de blur.

## ADR-072 — catálogo e modificadores XFS

Após esclarecimento explícito do usuário, integrar562registros/479compráveis,
preços e bônus reais. A interpretação anterior de somente design foi rejeitada.
Namespaces separados e migração por identidade preservam compras/progresso;
Pilot Goggle antigo1 corresponde ao XFS2. Kappa fica legado. Atributos do piloto
mais equipamento são limitados a50por atributo, com negativos, copiados no
start e compartilhados com previsão. Substitui restrição a cosméticos C# das
ADR-067/069/070 para o catálogo XFS. Sem rede/contas neste corte.

## ADR-073 — controle e migração HD completa

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

Usuário apontou a diferença entre miniatura regenerada e peça vestida nativa.
Registrar miniatura, base, efeito e QA separadamente para todos os562registros.
550têm peças/629camadas; padrões vazios e place holders recebem N/A com motivo.
Masters anatômicos constantes e efeitos separados conservam rig/animação
aprovada; arte só gerada não conta como componente validado. Arte original,
brutos e prompts preservados. AVATAR_HD_MIGRATION.md define o critério550/550.

Concluído na0.17:37lotes/38atlas,629camadas e532miniaturas novas,18miniaturas
anteriores. Controle exige captura com os hashes atuais da arte, registro e
renderer, mais auditoria do uso efetivo nos550registros. Mestres constantes
acompanham rig/poses/pausa; não equivalem a redesenhar todos os quadros nativos.
Recortes de partículas e reparos individuais têm decisões reproduzíveis no
ledger, sem alterar brutos.12N/A mantêm motivo explícito. App/PCK validado.

## ADR-074 — Nak com dados do cliente original sobre o OpenBound

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
números e uma gravidade invertida 3×. Publicado como ADR-069 no PR #1;
renumerado para ADR-074 na integração à main, pois a loja local já usava 069–073.

## ADR-075 — estado anatômico compartilhado por cabeça e efeito

**Substituída pela ADR-130** quanto à composição/arte ativa da loja e ao uso
ativo do HD de avatares; arquivos e histórico preservados.

20/10/2026. Em0.17 o gerador escolheu o maior L dentre todos os quadros, mesmo
quando a cabeça vinha de Normal11–21. Great Devil Head combina luz frontal
com cabeça lateral. Preparação passa a selecionar Normal na cabeça e sua luz;
arte defeituosa é regenerada, preservando fontes/brutos anteriores. O fallback
respeita as faixas Normal/Staring da categoria. Metadados e QA devem comprovar
o estado, além do registro constante. AVATAR_EFFECT_ALIGNMENT.md.

O pedido de finalizar o PR1 com arte HD substitui o adiamento de HD do Nak na
ADR-074; anatomia estável e efeitos próprios, sem mudanças de regras. NAK_HD.md.

## ADR-076 — regras de batalha: original comprovado, depois C#

Substituída parcialmente pela ADR-084 em 24/10/2026: balística C#, carga
adaptada e piso de força 15 deixam de ser o alvo aprovado. A implementação
da física original ainda está pendente; demais decisões deste ADR permanecem.

Pedido de 20/10/2026: auditar a batalha contra o OpenBound C# e o cliente
original Thor's Hammer ([BATTLE_RULES_AUDIT.md](BATTLE_RULES_AUDIT.md)).
Política escolhida pelo usuário: quando a engenharia reversa comprova a regra
original, ela prevalece; nos demais casos, vale o C#.

A evidência principal vem de `ComputeTurnDelay`/`CommitTurnDelay` do
GunBound-Decomp. O delay é `[28] + custo do tiro [30/31/32] + segundos gastos
× [29]` do `characterdata.dat`. `base + custo` reproduz o `DelayPresets` do C#
em 12 dos 16 mobiles. O Nak do C# (760/910/1310) é a linha de outro mobile.

Escolhas do usuário:
- abertura sorteada;
- tempo gasto entra no delay do tiro, com turno de 30 s;
- passe = 200, sem termo de tempo (o termo fixo `[34]` = 200 não foi atribuído
  a um caminho e fica como hipótese);
- Nak 770/920/1320;
- Mage 730/30;
- delays de item do `itemdata.dat`;
- balística com os números do C# (196, massa 14, vento 1,2).

Substitui:
- as adaptações de gravidade/força/vento do ADR-024 e do ADR-026;
- as regras de baseline do SPEC "Jogador começa" e "Passar custa 80";
- os custos de Teleport, Dual+, Energy Up 2, Change Wind e Bunge do ADR-058;
- os delays do Nak do ADR-074;
- HP 760 e regeneração 20 do Mage (ADR-066);
- a exigência de seeds 81–90 idênticas (ADR-057/058): as partidas de
  referência mudam com esta decisão e passam a ter novos valores registrados.

Não muda: empate por morte dupla, empate de iniciativa a favor do outro,
passe sem trava de SS, dano C# (ADR-066) e clima. A balística original em
ponto fixo e o dano original seguem sem engenharia reversa; ficam como
pendência.

Complemento (auditoria 0.18.1): o tempo gasto vale para o jogador. A CPU
cobra um tempo fixo de 2 s por tiro (`TurnTable.CPU_THINK_SECONDS`) no lugar
do relógio real, porque a duração da busca no worker depende da máquina e
tornava a ordem de turnos não reproduzível com a mesma seed. A fila do HUD
antes da escolha da CPU passa a vir de `TurnTable.current_order`, com o mesmo
desempate a favor do outro (o `game.gd` antes desempatava a favor do ativo).

Complemento (0.18.2): o modelo congela `turn_time` da CPU entre
`begin_cpu_plan` e `finish_cpu_plan` (`cpu_thinking`). A busca não consome o
turno de 30 s, então a CPU não passa por tempo esgotado em máquina lenta; a
espera de apresentação depois da escolha continua contando.

## ADR-077 — deriva do vento na queda pela intenção do C#

21/10/2026, decisão do usuário. `Movement.ApplyGravity` (Movement.cs:170–193;
Parameter.cs:123–126) cai `int(GravitySpeed)` px por passo, com
`GravitySpeed` começando em 3 e somando 0,15, e soma `wind.x / 45` a um
acumulador. O código literal zera esse acumulador quando o mobile **não**
colide (troca de condição) e de novo ao passar de 1, o que torna a deriva
irregular. O protótipo anterior acumulava por pixel caído e também zerava.

Decisão: seguir a intenção. `Match.drift_fall` itera por passos de gravidade e
aplica `wind.x / 45` uma vez por passo, sem acumulador nem reset; parede ou
terreno sólido no próximo x bloqueia o empurrão do passo. Vento 35 numa queda
de 100 px (24 passos) desloca ≈ 18,7 px. Substitui a deriva por pixel da
paridade de MOBILE_PARITY.md (REQ-42). Teste: `test_mobile_parity`.

## ADR-078 — aura ligada ao contorno real do chifre

Substituída pela ADR-079: o usuário rejeitou a perda de brilho/animação.

Usuário confirmou aura pulsante externa e rejeitou a luz afastada. O halo é
derivado em memória do ouro da própria peça HD, na janela fixa do chifre,
e compartilha sua origem/escala; fica atrás da anatomia. Sem centros alpha
por quadro e sem mover a peça. Outros19efeitos/combate/perfil preservados.
Aceite: pontos reais do ouro coincidem com a máscara, comparação GPU nos dois
sentidos e pausa. HORN_AURA_FIX.md.

## ADR-079 — preservar o brilho e corrigir somente sua curva

Substituída pela ADR-082: a faixa curvada continuou fora do formato do chifre.

Substitui ADR-078 após rejeição explícita do usuário: o halo da0.18.3 ficou
imperceptível no tamanho real da loja. Restaurar textura L, composição sobre
o chifre, opacidade e pulsação anteriores. Corrigir curva por uma malha UV
constante, medida nos pixels da cabeça e da luz, sem gerar outra aparência.
Teste deve medir variação visível no tamanho da prévia, além de encaixe,
sentidos/inclinação e pausa. Sem mudanças nos demais19efeitos ou regras.

## ADR-080 — saldo alto de teste e concessão única no perfil existente

Usuário pediu999.999.999 Gold e Cash no perfil padrão para comprar/vestir todos
os avatares e solicitou commit/push. Padrão vale para novos perfis; inicialização
do jogo aplica a mesma quantia uma única vez a carteiras existentes válidas,
com marcador persistido e rollback em falha. Não reabastecer a cada abertura
nem perder progresso/posses. Plano: testar padrão, concessão/reload/rollback,
comprar e vestir os479registros compráveis em perfil isolado, regressões e PCK
exportado. Itens N/A/indisponíveis e preços originais continuam sob suas regras.

## ADR-081 — revisão de qualidade sem mudar regras

Pedido do usuário: analisar a Spec e o código (SOLID, repetição, code smells)
e executar todos os pontos P1–P4 de `QUALITY_REVIEW.md`. Decisões: refatorar
atrás das fachadas existentes (`Match`, `game.gd`), mantendo os métodos usados
pelos testes; provar ausência de mudança de combate com golden master de 26
partidas (eventos + campos do ator) além das seeds 81–93; versão em fonte única
(`application/config/version`), lida pelo menu e gravada no Info.plist pelo
`build_macos.py`; apresentação por mobile num catálogo próprio
(`mobile_looks.gd`), separado de `mobiles.gd` para o modelo não conhecer
scripts de desenho; delays guardados na unidade original do C# e convertidos uma
vez (`delay_units.gd`). Tipagem completa de ator/projétil adiada (motivos no
plano): fábricas de estado no lugar. Nak sem aura UsingItem até haver arte.

## ADR-082 — brilho do chifre a partir do L clássico

Substitui ADR-079. Usuário pediu refazer o brilho do Great Devil Head a partir
do clássico: posição e formato iguais aos da baixa resolução. O L original
(`mh00071l`) é a silhueta do próprio chifre, embranquecida e desenhada por
cima: núcleo 187/255 sobre o chifre inteiro (contorno incluso) e borda de ~4 px
nativos. Uma luz gerada à parte (meia-lua 0.18.0/0.18.4) nunca coincide com o
chifre HD, mesmo curvada. Decisão: derivar a luz da máscara de ouro do mestre HD
(componente principal, sulcos fechados, contorno incluso) com o perfil medido
no clássico, assada em `great_devil_horn_light.png` por
`scripts/build_devil_horn_light.py`, sem nova geração GPT Images. Registro
`overlay_base`: mesma origem e escala da cabeça, margem de 20 px para a borda,
opacidade do material 1 (o PNG carrega o alfa clássico). Pulsação e relógio
anteriores mantidos. Masters, originais e os outros 19 efeitos preservados.

## ADR-083 — roster dos 16 mobiles do cliente

Pedido: implementar todos os mobiles do cliente clássico, no padrão atual,
com as características originais, e entregar com testes e build. IDs 1 Mage,
2 Bigfoot e 3 Nak não mudam (o 0 continua fora). Os IDs 4–16 seguem a ordem
do cliente a partir do Armor. Números de vida, escudo, mira, delay e tempo
saem do `characterdata.dat` decodificado. Dano e raio seguem a leitura já
usada no Nak. Arte de `graphics.xfs`, sem HD novo. Onde o OpenBound tem a
classe do tiro, o voo especial entra no laço comum (`classic_flight.gd`).
Onde não tem (Boomer, JD, A.Sate, Grub, Knight e o Aduka), o tiro é
o projétil comum com os números da tabela, até a simulação do cliente desses
tiros ser portada. A loja de avatares não entra nesta decisão.

Correção posterior: `tank14.img`, `tank15.img` e `tank16.img` são Dragon,
Knight e Aduka. Os nomes Kalsiddon e J.Frog não correspondem a esses arquivos
nem a estes 16 registros. O menu desenha o atlas numa escala única (casco 60,
a mesma largura do combate), com o pé opaco do quadro parado no chão.

## ADR-084 — física, carga e força mínima do cliente original

24/10/2026. **Decisão aprovada pelo usuário e implementada na0.20.0.**
Contrato e resultados em `BATTLE_FIDELITY_0_20.md` e
`CLASSIC_BALLISTICS_0_20.md`. As formulações futuras abaixo preservam o
registro da decisão anterior ao código; não indicam porte ainda pendente.
Respostas às três escolhas do plano de fidelidade: (1) seguir a física
original; (2) adotar carga original de 3 segundos; (3) reproduzir a força
mínima original. Substitui a escolha de balística C# e preservação do piso
15 da ADR-076, além da carga de 2 segundos de REQ-28.

O porte seguirá as regras comprovadas do cliente Thor's Hammer: velocidade
e gravidade por mobile, vento quantizado, aceleração fixada no lançamento,
ordem de integração original e estados próprios dos tiros, incluindo Boomer.
O plano propõe ponto fixo com 8 bits fracionários e passo de 20 Hz, com
apresentação suave independente da colisão. A implementação deve validar
truncamentos e limites nativos da força, sem trocar o piso 15 por outro
percentual arbitrário. Barra, Drag/Slice, CPU e disparo real devem usar os
mesmos limites e conversões; carga completa leva 3 segundos.

A alteração muda mira, alcance, tempo de voo, busca da CPU e referências
das partidas. Preservar o baseline anterior e justificar novas referências
com fixtures independentes do cliente. Colisão refinada e tiros ainda não
comprovados continuam investigação, sem promessa de paridade integral.
Demais decisões de agenda, cobrança fixa de 2 s da CPU, perfil, roster e
arte HD aprovada permanecem. Plano: [BATTLE_FIDELITY_PLAN.md](BATTLE_FIDELITY_PLAN.md).


## ADR-085 — escopo comprovado e fronteiras da fidelidade0.20

24/10/2026. Registra as escolhas da implementação do plano aprovado, sem
ampliar o escopo da ADR-084. Tarefas1–7 entregam minas/fábrica, física comum,
mira, Boomer e apresentação; tarefa8 entrega pesquisa48tiros e próximos
planos. Original comprovado continua prevalecendo sobre C#, mas pesquisa
parcial não autoriza dano ou mecanismos inventados.

Decisões: manter a colisão varrida/caixas, dano/cratera, tornado e adaptações
existentes enquanto seus portes nativos não estiverem fechados; registrar
essa fronteira em vez de chamar a partida de emulação integral. Aceleração
FP nasce no lançamento e todos os consumidores de combate usam a mesma
simulação/snapshot. Interpolação e animação não alimentam colisão.

MainAction/EPA comprovados definem48timelines, componentes e grupos de som.
Turtle usa WaterEffect e suprime a cabeça Armor; Dragon S1/S2 permanece sem
corpo, com partículas, e bullet14c/cl pertence aos filhos SS. Arquivos de som
Knight151blast e Aduka23blast ausentes permanecem silêncio explícito, sem
substituto inventado. Recursos flame/ssflame são estágios separados; somente
caminhos já comprovados são ativados. Dados/fontes preservados.

A ponte visual de Armor/Turtle espelha open/hold existente sem mudar combate;
Boomer mantém sua máquinaFP própria. Contato opaco pré-calculado elimina a
dependência de PNG cru no PCK; ASate muda de0 para−3 por medir o alpha real,
com deslocamento visual3px declarado para QA. Não altera hitbox nem pose física.

Consequência: há melhoria funcional e audiovisual verificável, com gates de
revisão e harness final aprovados. QA GPU tem limite de resolução; escuta
pendente. App assinado e PCK passaram nas assertivas, com ressalvas ambientais
do export/smoke registradas separadamente. Próximos portes seguem `BATTLE_MOBILE_FAMILY_PLANS.md`.


## ADR-086 — reparo Turtle por estágio comprovado, sem porte numérico integral

24/10/2026, implementado na 0.20.1 por solicitação de correção dos tiros.
Substitui parcialmente a ponte visual Turtle da ADR-085: manter o pai voando no
último quadro change não reproduz o encerramento da EPA. A leitura estática
comprova tick 44→dez ticks change→seis filhos/remoção do pai. Essa topologia entra
no laço comum real/previsão; divisão não é explosão e impacto no tick 44 não
pode antecipá-la. Valores atuais de dano, raio, velocidade e dispersão dos
filhos continuam adaptações. Armor e Boomer conservam contratos próprios.

WaterEffect usa oito colunas completas, alpha nativo e uma seção transversal
por amostra, compartilhada pelos segmentos vizinhos. Interpolação altera
somente cópias visuais; hold estabiliza os endpoints de apresentação. Filhos
usam bullet12c. Impacto do pai normal compõe flame123+ssflame12; pai em change
e filhos usam flame123, com child/ss_state preservados no evento/efeito.

Revisão independente fechou três P2 com regressões RED→GREEN; captura temporal
GPU 1920×1080/60 FPS observou faixa contínua e estágios corretos. Não implica
paridade completa da física especial, nem execução do cliente original,
QA de áudio ou input manual. Resultado detalhado em `TURTLE_ANIMATION_FIX.md`;
HUD, mira, carga, trava SS, perfil, originais e fonte C# preservados.


## ADR-087 — onda Turtle T2 e raster conforme o cliente

24/10/2026 (America/Sao_Paulo). Implementado na 0.20.2 após o usuário apontar que o T2 ainda não
se movia como o original. Substitui a órbita T2 mantida na ADR-086, preservando
T1/SS e o restante da entrega anterior. Seguir instruções/LUTs comprovadas do
PE em vez da aproximação contínua do C#: fase 0/180, amplitude 1000, avanço 5,
crescimento por dez ticks e decaimento até avanço/amplitude zero.

Separar a trajetória central da onda. Heading pré-aceleração calcula o ponto
de colisão; heading pós-aceleração orienta as seções de meia largura 10.
Mesmo laço real/previsão e estado privado por projétil; interpolação só visual.
Quads T2 podem se cruzar em tiros legais de força mínima ou sob Tornado.
Usar os dois triângulos explícitos do raster original, sem ear-clipping;
preservar draw_polygon no T1. O reparo foi reproduzido em RED e revalidado.

Gates de revisão e harness final aprovados, com captura temporal Full HD
inspecionada. Isso fecha a onda ordinária do T2, sem alegar paridade nativa
de tornado, colisão refinada, dano/cratera ou combate integral. Cliente
original não executado; aceite visual do T2 posteriormente confirmado pelo usuário
(“Agora funcionou”); escuta e mouse sem validação registrada.
Contrato e evidências em `TURTLE_T2_FIDELITY.md`.

## ADR-088 — aprendizado reutilizável do porte e preservação visual

Após o aceite visual do T2 (“Agora funcionou”), o usuário solicitou uma skill
para reescrever o cliente GunBound no Godot e autorizou REA do binário
client-side para obter informações e ajustar a implementação. Consolidar
o método em `skills/gunbound-client-port/SKILL.md`, complementando as skills
de mobile C# e arte clássica HD existentes. Fontes jglim/gunbound-launcher
e jglim/gunbound-server são referências distintas: cliente/recursos e
emulação de servidor, respectivamente. Conferir build e proveniência;
análise estática não equivale a executar o cliente original.

Preservar os 16 mobiles e avatares/equipamentos atuais, incluindo o HD
aprovado. Modernização visual fica para etapa posterior solicitada pelo
usuário. A skill ensina separar estado, colisão e apresentação; comprovar
aritmética/ordem/LUTs; reconstruir raster/UV/registro; e aceitar por fixtures
independentes, regressões e sequência GPU, com limites explícitos.
Isso não expande o protótipo para rede nem declara os especiais restantes
portados. Nenhuma regra de combate, arte ou versão muda nesta consolidação.


## ADR-089 — restauração original de Bigfoot e Mage

24/10/2026. Solicitação explícita substitui parcialmente ADR-088/REQ-20:
usar arte original dos dois mobiles como no restante do elenco. Extrair
tank2/tank5 e EPA pelo pipeline clássico em subpastas novas; conservar os
derivados HD e fontes anteriores. Avatares e equipamentos continuam com a
aparência atual, montados no RiderPivot nativo. Não alterar combate/perfil.
Mage T1/T2 continuam com S1T/S2T originais do OpenBound e composição existente
(adaptação); SS usa bullet2p/ssflame2. Bigfoot passa a usar flame52 do cliente
no T2, substituindo visualmente o Flame2 Armor do fork. Escala e contato
seguem os demais mobiles clássicos. Registro: ORIGINAL_MAGE_BIGFOOT.md.


## ADR-090 — tiros e poses acompanham a restauração original

Feedback após0.20.3 substitui a composição S1T/S2T conservada naADR-089:
Mage usa a faixa LaserEffect.xtf com16colunas, seções±8 e ondaT2 nativa
13px/40°/fases0/180; estado privado no laço real/previsão. EPA rege os
tempos das poses dos dois mobiles; sem rotação/fade/rastro genérico extra.
Não altera dano, avatares, perfil ou os16IDs. Limites e fonte em
MAGE_BIGFOOT_ANIMATION_PORT.md; não declara dano/colisão/tornado integrais.

## ADR-089 — catálogo clássico identificado pelo código do servidor

O `avatar.xfs` da versão 280 já estava byte a byte igual ao TestClient do
launcher, com 562 registros. Faltava a identidade que o `gunbound-server` usa
na loja e no avatar equipado. O índice `classic.json` guarda arquivo, slot,
preço, status e texto CP949 de cada registro, sem apagar peça nem inventar
avatar de cliente mais novo.

O WORD usa o id nos 15 bits baixos e o bit 15 para masculino. O terceiro byte
do DWORD é o slot corpo/cabeça/olho/bandeira. Os quatro WORDs equipados seguem
essa ordem: o conjunto do usuário `amigos` fecha com Rocker Suit, Rocker Hair,
Dizzy Glasses e Bazooka, e o comentário “head, body, eye, flag” fica
substituído por essa evidência. Bandeira vazia é o WORD 0 nos dois gêneros.
Love Cupid (id 143) não existe nesta versão e não é criado.

A categoria interna da loja continua cabeça/corpo/óculos/bandeira. Mudá-la
reapontaria equipamento já salvo. `ff.dat` vazio e os dois frames `ff00001`
não viram item. Legado OpenBound permanece no namespace antigo.

Na `main`, ADR-082 já é o brilho do chifre e REQ-45 já é o roster dos 16
mobiles. Este catálogo usa ADR-089 e REQ-46.

Nota de integração: ADR-089 foi usado independentemente pela restauração de
Bigfoot/Mage e pelo catálogo clássico de avatares. Ambos os registros e suas
referências foram preservados neste merge; distinguir pelo título.

## ADR-091 — Ghidra headless na skill de porte

24/10/2026. Por solicitação do usuário, adotar Ghidra headless diretamente
como caminho preferencial da gunbound-client-port, com runner Python3 e
exportador Java incluídos na skill. Perfil/cache/projeto isolados, origem
fixada por hash, entradas explícitas quando comprovadas, referências/bytes/
ASM/pseudocódigo e falhas observáveis. REA/MCP continua utilizável quando
compatível: a6.7.0 instalada aceita12.1.x e recusa12.2, embora a12.2 direta
funcione. Não alterar a política do provedor nem configuração global.

O export não é tradução automática para GDScript nem prova de paridade
integral. Aritmética/ABI/FPU, despacho, unidades, relógios e consumidores
precisam de prova, seguida de fixtures independentes, execução/previsão e
QA apropriado. Preservar elenco, avatares, perfil e limites offline.
Plano/validação: GHIDRA_SKILL_VALIDATION.md. Sem nova regra/arte/build.

## ADR-092 — sala inicial no lugar do cartão de treino

24/10/2026. A tela de entrada passa a ser a sala 1×1. Iniciar dispara o treino
com o ajuste gravado. O menu Configurações da partida agrupa apelido,
dificuldade e clima, e só os aplica ao aceitar. Mobile e itens permanecem em
botões da sala: a grade dos 16 aplica no clique; itens seguem o
PopupSelectItem. Opções de som, rolagem e fundo continuam no popup já
existente. O mapa segue Miramo Town A, sem setas. Não muda regra de combate,
elenco, perfil nem o fluxo da loja.

## ADR-093 — mobile da máquina escolhido na sala

24/10/2026. O treino pode fixar o mobile da CPU. O botão CPU da sala abre a
mesma grade dos 16 e aplica no clique. Sem escolha, `Match.start` continua
com `Mobiles.opponent` (1↔2, Nak contra Mage, os demais contra Mage). A
escolha vale para as partidas seguintes até outra troca. Os dois lados podem
usar o mesmo mobile. Não altera dificuldade, itens da CPU nem o pareamento
usado pelos testes que não passam esse id.

## ADR-095 — mobile da sala no tamanho nativo

25/10/2026. A sala desenhava o casco a 180 px, três vezes a arte clássica, e o
resultado ficava pixelado. O menu passa a usar largura 60, a mesma da arena,
com o ponto de contato sobre a placa do lugar. O palco tem a altura do
sprite mais a placa, e a placa do mapa acompanha essa faixa; o céu acima
permanece livre. A animação de espera anda em pixels inteiros. A arena, o
HUD e o filtro da cena não mudam. Quando houver folha HD dessa vista, o
tamanho pode subir sem reaproveitar este aumento.

## ADR-094 — efeitos próprios ASate/JD/Aduka/Raon

25/10/2026, REQ-04/05/07/08/09/19/44/45. O pedido atual substitui as
aproximações dessas famílias no catálogo0.19/0.20. ASate usa guia, Ion e
1/3/6 filhos; JD usa cristal fixo de atração T2 e repulsão/dano SS; Aduka
aciona Thor fora do clima correspondente, com tabelas/laser próprios; Raon
usa carrier e ondas T1 nativos e minas com autoria/estado/clocks separados.
Estado e emissão pertencem ao passo comum real/previsão, nunca ao renderer.

Nenhum guia de ASate/Aduka ou pouso de mina Raon recebe dano compensatório.
Preservam-se ações anexas de item/clima no guia, uma vez. Mina SS conclui
antes de agendar o próximo ator; S2 resolve sua agenda antes do input do
dono. Apenas um cristal JD por dono. Predição inclui Thor e plantio no
contrato de candidato da CPU. Originais, avatares, HD e perfil preservados.

Fontes ASM/tabelas e limites por comportamento estão nos quatro registros
CLASSIC_FIX e no plano SPECIAL_MOBILES_CLASSIC_FIX. Dano/colisão comum,
apoio/parede, posicionamento inicial do Thor e partes da agenda S2 mantêm
adaptação/C# identificados; não alegar paridade integral do cliente.
O efeito extra `ssflame7` e áudio `10s3fire.xes` ausentes no pacote não são
inventados nem substituídos por recursos de outro tiro.

## ADR-096 — lobby clássico como entrada

25/10/2026. A entrada deixa de ser a sala 1×1 (ADR-092) e passa a ser o lobby
do cliente clássico. Create abre essa sala. Buddy não é colocado: o buraco do
botão é preenchido com a cor da moldura. Ranking e Join ficam desabilitados.
Não há rede, contas, multiplayer nem salas para entrar.

A arte vem do `graphics.xfs` do TestClient jglim (SHA
a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08): fundo
`gamelist_back.img` e sala `ready_back.img`, não as variantes cartoon
`gamelistmode`/`readymode`. Rank e GP do cartão são o nível e o XP locais do
perfil, não um rank de servidor. O mapa segue Miramo Town A. Jewel, Death e
Big Bomb não entram como regra; o treino continua offline 1×1. O botão SOLO
só indica o modo vigente.

EXIT do lobby encerra o jogo. EXIT da sala volta ao lobby. A loja volta à
tela que a abriu. ESC na sala sem popup volta ao lobby e não abre as opções
de combate. Knight e Aduka não têm botão neste XFS (`mobile15` é RANDOM);
os ícones usam o quadro 0 das folhas já integradas sobre o fundo azul de um
botão de mobile. A grade 8×2 cabe no painel medido, menor que 63 px nativos.

A correção seguinte torna a grade a única escolha de mobile. O popup de
mobile e o da CPU saem; o de CHANGE (apelido, dificuldade, clima) fica.
Clicar no lugar B não abre painel: marca “Escolhendo: máquina” e o próximo
clique da grade aplica o ID na CPU. `pick_vehicle` segue o modo. Os lugares
ocupados desenham o mobile acima do fundo opaco e atrás dos nomes: o piloto
com o avatar equipado do perfil, a CPU com o piloto padrão, sem inventar
equipamento. O casco da sala é 52 px nativos para não sair do lugar.

## ADR-097 — itens da sala nos seis lugares

25/10/2026. O painel direito desenhava retângulos e o nome do item abaixo dos
seis lugares já pintados em `ready_back`, e o PopupSelectItem podia desenhar
controles fora da janela. A carga passa a aparecer como ícone dentro de cada
lugar. O catálogo fica no poço desse painel, limitado aos 6 slots de
`items.gd`. A troca grava `options.items` na hora. Não muda catálogo, custo,
CPU, combate nem rede.

## ADR-098 — ícones de Knight/Aduka e peça de 2 slots

25/10/2026. O botão de Knight e de Aduka usava o quadro 0 do atlas por cima
do `b_ready_mobile01` inteiro, então o Armor desse botão aparecia junto.
O quadro do atlas é um mobile só; o lugar da sala segue o desenho dos outros
clássicos (um atlas e um avatar). O fundo do botão perde o glifo antes da
colagem. Não se usa o RANDOM nem o placeholder. Item de 2 slots deixa de
repetir o ícone em cada lugar: um controle cobre os dois retângulos e o vão,
e o clique tira o item inteiro. Item de 1 slot permanece em um lugar.
Catálogo, `options.items` e o teto de 6 slots não mudam. CPU continua sem itens.

## ADR-099 — restauração fiel como padrão da skill HD

25/10/2026, REQ-12/19/20. O prompt atual do usuário substitui as orientações
de reconstrução/2.5D e segunda referência de acabamento na restauração de
Gunbound Classic. Fonte visual única, mesma geometria/paleta/alpha/estados,
alvo4× por dimensão quando suportado. Preservação prevalece sobre nitidez.
Rig/efeitos de HD já aprovado continuam disponíveis para correções próprias;
esta decisão não troca arte ativa nem revoga aceites anteriores.

Skill conserva o prompt integral, contrato medido e checker somente de leitura.
Dimensões/métricas não autorizam aceite visual; candidatos incompatíveis são
rejeitados sem corrigir por esticamento/crop. Três ensaios reais em
`assets/classic` falharam no contrato. Evidência/limites em
`CLASSIC_HD_RESTORATION_SKILL.md`. Sem integração, versão nova ou build.

No ensaio posterior do CREATE, o usuário aceitou explicitamente repetição
exata dos pixels. A skill passa a oferecer `upscale_exact.py` para esse
contrato: nearest inteiro, PNG separado e validação RGBA integral com
`--exact-pixels`. Não se apresenta esse resultado como restauração neural.
CREATE1712×180 foi conferido nos308160pixels, sem divergências/padding e
com as648cores originais. O aceite dessa técnica não autoriza substituir
outros assets nem aplicar os candidatos rejeitados ao runtime.

Solicitação seguinte estende explicitamente a mesma técnica aos41demais
atlas de botões em `assets/classic`. Derivados separados em
`assets/hd/classic/buttons_4x`, conjunto completo42PNGs/197estados incluindo
CREATE, com catálogo de origem/escala/hashes e verificação RGBA integral.
Os originais e seus `.png.import` são preservados. Esta ampliação não conecta
os derivados aos consumidores da interface nem altera dimensões lógicas.

## ADR-100 — atlas4× no lobby/sala com geometria nativa

25/10/2026, REQ-02/12/19/20. Pedido posterior autoriza integrar os derivados
da ADR-099. `ClassicChrome` troca o atlas e multiplica somente a região de
textura por4. Manifest nativo continua definindo células lógicas, estados,
layout e hitboxes; filtro nearest, stretch e mínimos dos controles permanecem.
Catálogo/recursoHD inválido ou ausente retorna ao original. Nenhum ajuste de
posição, tamanho, novo botão ou regra de treino é introduzido.

Importações dos42PNGs e inclusão explícita dos dois JSONs no preset permitem
uso no projeto e no PCK. Suítes735/0; GPU1920×1080 com RGBA idêntico para
lobby/sala; smoke isolado91/0/exit0, revisão independente aprovada.
Limites ambientais e evidências em `CLASSIC_BUTTONS_HD_INTEGRATION.md`.
Aplicativo previamente exportado não foi substituído por esta integração.

## ADR-101 — suavização conservadora aprovada

25/10/2026, REQ-02/12/19/20. O usuário aprovou o EXIT BICUBIC e pediu aplicar
o acabamento e adotá-lo na skill para próximas sessões. Substitui o acabamento
exato da ADR-099/100 no consumo dos botões, preservando fontes e derivados
anteriores. Ativo em `assets/hd/classic/buttons_smooth_4x`,42atlas/197estados.

Cada quadro é filtrado isoladamente em4×; alpha conserva cobertura/valores
nativos por nearest e o RGB usa interpolação bicúbica. Sem novas margens,
mistura de estados, redesenho ou mudança de layout/hitbox. Cores/pixels não
são idênticos à fonte; o modo exato permanece para pedidos que o exijam.
O EXIT integrado coincide com a prévia explicitamente aprovada.

Skill inclui helper reproduzível, inspeção por estado e fluxo sem IA para
melhorias desse tipo; relatórios usam destino novo para não sobrescrever
fontes/candidatos. Suítes778/0,21testes Python, GPU1920×1080 e PCK92/0/exit0,
com limites ambientais documentados em `CLASSIC_BUTTONS_SMOOTHING.md`.
Sem nova versão, aplicativo exportado ou envio ao remoto.

## ADR-102 — patente clássica atribuída e lobby contido

25/10/2026, REQ-02/10/12/19. Pedido atual substitui Rank=level daADR-096:
patente é campo próprio do perfilversion4. Novo dono local e legado sem campo
recebem GM20, Administrador do Sistema; explícito inválido recebeChick19.
Recompensas/nível de atributos continuam as existentes, sem alterar patente.
Não se retoma ranking competitivo nem rede. GP apresentado usa XP local.

REA/Hopper no PEfixado confirma decoderWORD+4, rank1/2 e render do cartão.
ConvençãoThor−4…20, GMquadro24; não usar GM27doOpenBound. Catálogo25patentes
com PNGs nativos separados. O cliente recebe patentes externamente; não se
inventa uma tabelaGP→patente do servidor com a progressão local.

Cartão conserva moldura e contém nome/GP/carteiras; mesmos ícones no canal.
Histórico local64mensagens com scroll, entrada transparente dentro da faixa,
BBCode do usuário literal. Filtros nas posições nativas. Layout final considera
os mínimos de fonte do Godot, reaplicando tamanho após tema/clipping.

1086checks Godot/0, revisor96/0 e50quadrosXFS, GPU1920×1080, PCK109/0/exit0.
Evidência/limites em `LOBBY_UI_RANK.md`; sem versão/app/commit/publicação.


## ADR-103 — acabamento restante do lobby em4×

25/10/2026, REQ-02/12/19/20. Após versionar o lobby/GM em5732568, aplicar
BICUBIC4× às quatro imagens estáticas e dois atlas de patente, por quadro,
alpha nearest. Mantém aparência/registro, sem redesenho/padding; RGB é
interpolado. Botões aprovados e originais permanecem. Sala não muda.

Novo catálogo independente valida origem/grade/dimensões com fallback nativo.
Tamanho mínimo/visual dos TextureRect explicitamente nativo, inclusive após
add_child. GM20/quadro24 continua independente do XP. Nenhuma mudança de perfil,
combate ou versão. PCKincluiJSON/PNGs; não há novo aplicativo exportado.

1045checks Godot/0,21testes Python; revisão independente776/0 e54células.
GPU1920×1080 confirma mesmas áreas de clique e salaRGBAidêntica. PCK223/0/exit0,
sem override/TLSlocal. Evidência/limites: LOBBY_ART_HD.md e docs/lobby-art-hd.
Commit local solicitado, sem envio ao remoto.


## ADR-104 — sala com composição clássica e acabamento4×

25/10/2026,REQ-02/12/19/20/36. Aplicar o mesmo acabamento conservador ao fundo,
mapas/retratos e11botões de itens da sala.14PNGs/84células, alpha nearest;
originais e botões previamente aprovados preservados. Ghidra/ASM confirma
mapa332,51 e retrato378,390. Dragon/Knight não usam os placeholdersRandom.

CabeçalhoGM, pesos de clima e faixa de avisos refletem os dados locais.
Texto contido e atributos acessíveis por hover. Grade8×2,16mobiles, estados,
slots/hitboxes e modalidadeoffline1×1 permanecem. Itens usam fontes clássicas
OpenBound apenas na sala; apresentaçãoHD da batalha não muda. Sem novas regras,
perfil, versão ou rede. Não representa porte integral do multiplayer original.

1256checks Godot/0,21Python, revisão172/0 e auditoria95/0 após correçãoP2
(tooltips). GPU1920×1080 confirma mesmos retângulos; PCK183/0/exit0 semoverride.
Evidência/limites em ROOM_UI_FIDELITY.md. Versionamento local solicitado,
sem publicação nem novo aplicativo exportado.


## ADR-105 — sala5×3,Random restrito,catálogo único e timesA/B

25/10/2026,REQ-02/12/19/20/36. A foto enviada substitui8×2 e abas de itens
preservados pelaADR104. Quatorze mobiles comuns+Random,cinco por linha/três
linhas. Knight/Dragon sem escolha direta; IDs14/15 continuam no modelo.
Random é sentinelaUI−2 separada dos IDs, resolvida aoStart somente entre14/15,
com RNGprivado e lados independentes. Preservar seleção ao reabrir sala/loja.

Onze itens em um catálogo rolável3colunas,semabas,com setas nativas;
equipamento mantém6slots. Oito faixas nativasA/B,nomes na base e mobiles acima.
Novos11PNGs/15janelas em4× conservador; setas de16/17px processadas por estado,
sem inventar padding uniforme. Originais/HD anteriores e batalha preservados.

1669checks Godot/0,21Python,revisão455+7+81semfalhas;GPU1920×1080 ePCK53/0.
Contrato/resultados:ROOM_REFERENCE_LAYOUT.md. Sem novoapp/versão/rede/publicação
ou commit solicitado nesta etapa. Aceite visual do usuário permanece separado.

## ADR-106 — catálogo nativo, apoio fixo com idle e avatar noRandom

25/10/2026,REQ-02/12/19/20/36. O pedido corrige a apresentação daADR105:
catálogo uniforme64×43 com ready_itemshop1/2 e indicação nativa de1/2slots;
equipamento35/71×31 com ready_item1/2. Setas encaixadas nos poços. FaixasA/B
atrás dos mobiles, contato144, nomes à frente. Remover somente oscilação
adicionada; sequências idle e avatares continuam com elapsed. O requisito
posterior do usuário rejeita congelar animação para estabilizar a posição.

Random exibe sprite original OpenBound e avatar equipado via renderer comum,
com registro/pivô nativos,12quadros e4× conservador/fallback. Nenhum novo ID
jogável;UI−2/sorteioKnight/Dragon noStart preservados. Mapa tem título único e
controles apenas nas setas laterais nativas; continuam inativos com um só mapa.
Sem novos mapas, regras ou mudanças de perfil.

1720checks dirigidos/0 e rodada finalUI/animação1027/0,21Python, GPU24quadros
com idle/avatares ativos e âncoras fixas;PCK109/0/exit0. Fontes/alpha/arte anterior
preservados. VerROOM_POLISH.md para evidência, limites e ressalvas ambientais.
Sem novoapp,versão,commit ou publicação solicitados nesta etapa.

## ADR-107 — cards encaixados, Ready e placas nativas da sala

25/10/2026,REQ-02/12/19/20. O novo pedido substitui contato144 daADR-106 por
composição105/563,155, derivada da posição guardada pelo cliente004dba80.
Retirar visualmente nome do mobile dos cards, inclusiveRandom; manter
apelido/CPU,avatar eidle. Nenhuma mudança de combate/perfil/IDs/sorteio.

Ready/chave usam ready_back índices6/7; hastes extras3–5 preservadas noatlas.
No treino, piloto é dono da sala e CPU está pronta. DecoraçãoIGNORE preserva
clique de seleção no card; não cria estado/protocolo de rede. Nome contido
antes da chave. PlacasSOLO/1:1/A SIDE/NODEATH/BASIC usam os botõesXFS como
indicadores; layout emduascolunas da foto, dados refletem regras existentes.
Não anunciarJewel/Double/Death40 como modos implementados.

7PNGs/25janelas, BICUBIC4× porjanela/alpha nearest, originais e456assets
prévios intactos; catálogo/fallback e exportação conferidos.1093checksGodot/0,
21Python/0,GPU17escolhas/24quadros,PCK40/0. Revisão aprovada apósP2deinput
reproduzido e corrigido. Evidência,derivações e ressalvas ambientais em
ROOM_CARD_FIDELITY.md. Semnovoapp/versão/commit/push. Aceite visual pendente.

## ADR-108 — dificuldade no card, clima sem poços e START azul

25/10/2026,REQ-02/12/19/20. Pedido posterior àADR-107 move a dificuldade
confirmada para o card da máquina (`CPU · Normal/Leve/Precisa`). Rascunho e
Cancelar não mudam o card. Retirar a linha duplicada do painel central.

Números do clima mantêm texto branco eLabel transparente. O fundo nativo
contém os poços escuros; restaurar somente essas oito bases usando amostra
laranja limpa da própria textura ativa, com densidade/fallback correspondentes.
Não editarPNG original nem símbolos/valores de clima.

UsarSTARTGAME azul nativo107×45/quatro estados0/1/2/3, em660,552, coerente
comEXIT/CHANGE. Fonte/HD novos acrescentados aos catálogos; antigoSTART verde
e42registros anteriores preservados. Extração reproduzível ealpha nearest.
Sem alteração da açãoStart, regras, perfil, versão, aplicativo ou publicação.

1286checksGodot/0,752/0 finais,21Python/0; GPUFullHD confirma8baseslaranja,
Normal/Precisa e estadosSTART. Revisão independente aprovada. Evidência e
limites:ROOM_FINAL_POLISH.md e docs/room-final-polish.

## ADR-109 — SETTINGS, modal clássico e lettering original preservado

25/10/2026,REQ-02/12/19/20. Pedido posterior remove seta deSTART, substitui
CHANGE porSETTINGS semsetacircular e adapta o modal à linguagem Classic.
Correção explícita do usuário rejeita a substituição da fonte: START usa a
palavra raster original; SETTINGS compõe letras recortadas dos sprites
START/EXIT/CHANGE, conservando contorno/cores/estados. Não aplicarSystemFont
nesses dois rótulos. Bordas limpas doSTARTGAME mantêm o acabamento azul.

Modal560×470 centrado usa moldura derivada de9recortes limpos de ready_back8,
rádios eOK/Cancel nativos. FonteASCII95glifos8×12 defont.fnt doXFS, mantendo
9120bits originais; caracteres fora deASCII nos apelidos usam fallback já
existente. Tint noCanvasItem preserva o raster. Layout é adaptação pedida,
sem alegar formulário nativo idêntico nem alterar regras/perfil/modos.

CapturarESC antes doGUI no painel visível evita queLineEdit consuma o
cancelamento; evento tratado evita navegação dupla. Rascunho/aceite/cancel,
foco, cliques eSTART conferidos.1317checksGodot/0,21Python/0,GPUFullHD ePCK70/0;
revisão independente aprovada. Evidência/limites:ROOM_SETTINGS_CLASSIC.md.
Semnovoapp/ZIP,versão,commit oupublicação. Aceite visual do usuário separado.

## ADR-110 — SETTINGS composto sobre alpha, sem emendas de retângulos

25/10/2026,REQ-02/12/19/20. START daADR-109 foi aprovado pelo usuário; deve
permanecerRGBA idêntico. Usuário rejeitouSETTINGS por recortes sem acabamento.
Substituir janelas opacas desenhadas separadamente por um rótuloRGBA completo,
81×17/quatro estados, derivado dos mesmos glifos originais.

Separar cobertura pela paleta nativa, alinhar altura de maiúsculas, espaçar1px,
contorno redondo1,25px e filtrar a palavra inteira em4×. Cores por estado vêm
dos sprites; nativefallback deriva do mesmo composto. SemSystemFont ou troca
da aparência doSTART/modal. O acabamento altera alpha/antialiasing/contorno;
não afirmar identidade pixel-exata dos glifos após composição.

965checksGodot/0,GPU4estados/fallback/clique eSTART aprovado idêntico. Revisor
reproduziu os dois atlas em memória comRGBA idêntico. Evidência/limites:
SETTINGS_LETTERING_FIX.md. Semapp/versão/commit/push solicitados.

## ADR-111 — restaurarRGBA completo das letras deSETTINGS

25/10/2026,REQ-02/12/19/20. Usuário rejeitou o aspecto de fonte daADR-110.
Substituir reconstrução de preenchimento/contorno por cópia direta dos pixels
originais. Paleta serve para localizar área e limpar fundo/vizinhos; sem
redesenhar traços. Ajustar alinhamento/junções com contornos antes das faces.
START aprovado deve continuarRGBA idêntico; modal/fonteASCII preservados.

WordComplete74×20/quatro estados, ampliação conservadora4× ealpha nearest,
PNG anteriores preservados. Catálogo altera somente o registro ativo do
rótulo.629núcleos/3156contornos exclusivos exatos e paletas por estado
conferidas;969checksGodot/0,GPU4estados/fallback/clique/START idêntico.
Evidência/limites:SETTINGS_ORIGINAL_LETTERS.md. Semapp/versão/commit/push.

## ADR-112 — alpha da casca e glifos isolados da sala

25/10/2026,REQ-02/12/19/20. Pedido posterior corrige exterior retangular
opaco e composição deSETTINGS. STARTGAME fonte tem cenárioRGB comalpha255
nos cantos; desenhar só por cima não elimina a textura base doTextureButton.
Usar casca derivada transparente107×45 nas quatro texturas do controle,
preservando o contorno preto, tamanho/estados/hitboxes. LetteringSTART
original fica separado e idêntico ao aprovado.

SETTINGS83×20 usaTdoSTART eIisolado doEXIT, com3px entre faces e topo18.
Maior componente8conexa por glifo elimina3pixels doA vizinho em cadaT;
cores/traços permanecem nativos.1436pixels de faceRGBA conferidos, montagem
anterior daADR-111 preservada em disco. BICUBIC4×/alpha nearest, fallback.

1344checksGodot/0 eGPUFullHD: fundo nos cantos,START lettering idêntico,
quatro estados/fallback da palavra,clique/modal. Evidência/limites:
ROOM_BUTTON_ALPHA.md. Semapp/versão/commit/push. Aceite visual separado.

## ADR-113 — contorno único deSETTINGS, faces originais preservadas

25/10/2026,REQ-02/12/19/20. Usuário aprovou a transparência daADR-112 e
pediu acabamento/espaçamento mais próximo deSTART. Máscaras individuais
de contorno ainda preservavam emendas de recortes. Compor a base azul como
uma palavra única, derivando o contorno2px e seu alpha suave0,15px da união
das faces; reduzir espaçamento3→2px. Não reconstruir preenchimento nem
substituir a fonte:1436pixels de faceRGBA copiados integralmente da fonte.

WordPolished78×22/quatro estados. Margem adicional/destinoy13 preservam
topo18. RGBBICUBIC4×, alpha derivado; fallbackRGB nativo e coberturaBOX sem
ringing. Casca transparente/START inteiros aprovadosRGBA idênticos. Ativos
anteriores preservados, catálogo aponta novo derivado.986checksGodot/0,
GPU4estados/fallback/clique. Evidência/limites:SETTINGS_WORD_FINISH.md.
Semapp/versão/commit/push; aceite visual do usuário separado.

## ADR-114 — alinhamento óptico dos T de SETTINGS

25/10/2026,REQ-02/12/19/20. Usuário identificou TT acima deSE/INGS. A caixa
de pixels fortes não inclui toda a barra suavizada do T. Compensar+1pixel
vertical nos dois T antes do contorno/ampliação, nos quatro estados.
Demais letras, espaços, faces nativas, acabamento, casca eSTART preservados.

Ativo WordBaseline78×22;1436facesRGBA exatas. Dois checks reproduzem a falha
antiga e conferem barrasT/T na linha visível deE.988checksGodot/0,GPUFullHD
e revisão independente aprovados; retirar o offset reproduz o atlas anterior.
Evidência/limites:SETTINGS_BASELINE.md. Sem nova exportação/PCK/app, versão,
commit ou publicação. Aceite visual do usuário separado.

## ADR-115 — Bigfoot original com acabamento4×

25/10/2026, REQ-12/19/20/45. Pedido do usuário aplica ao Bigfoot a suavização
aprovada na ADR-101/103. As nove folhas de `bigfoot/original` recebem BICUBIC
4× por quadro, alpha nearest, em `assets/hd/classic/mobiles_smooth_4x/bigfoot`.
Complementa a ADR-089: a fonte ativa continua sendo o tank5/EPA original; só a
densidade da textura muda. Mage e demais mobiles permanecem nativos.

ClassicSprite valida catálogo por folha e multiplica apenas recortes de origem;
destino, pivô, contato, RiderPivot, avatar, tiros e regras ficam nativos.
Folha inválida volta ao original. Piloto padrão compartilhado, aura e avatares
fora do escopo. Plano/evidência em `BIGFOOT_SMOOTH_4X.md`.

## ADR-116 — tiros Raon T1/T2/SS pelo MainAction nativo

26/10/2026, REQ-19/44/45. Pedido do usuário: corrigir os tiros do Raon.
Substitui, na ADR-094, a fase das órbitas T1 e o leque angular ±3° do T2 do
catálogo 0.19. `Mobile06_MainAction` 0x49c120 prevalece sobre o C#:
T1 emite idx0/2/3 (comum, fase0, fase180); T2 emite dois tiros no mesmo
ângulo com força nativa P+15 e P−15; SS emite um tiro com P+15. O15 é o
inteiro protegido 0x794bf0 escrito no WinMain. O deslocamento é somado ao P
já quantizado, sem clamp (`native_power` em `projectile_parameters`), e vale
igualmente para execução, previsão, CPU e itens.

Balas de mina T2/SS usam `SimulateShot_Bullet7n_9s_7p_9p`, que não chama
`HitTestMobilesAndJewels`: atravessam mobiles (`skip_actors`), como o Grub SS.
A supermina anda para a direita só com vx>0 no impacto. Ponto de plantio,
contato/encosta das minas, dano e rotação do sprite seguem como na ADR-094.
Evidência e limites em `RAON_CLASSIC_FIX.md`.

## ADR-117 — minas Raon no terreno pelo AnimateMine nativo

26/10/2026, REQ-19/44/45. Relato do usuário após a ADR-116. Substitui, na
ADR-094/116, o contato por caixa (`mine.pos+(0,5)`), a posição “chão−5”, a
falta de queda e o espelho da mina. Mina S2/SS fica no pixel do chão; a cada
tick do modelo segue a ordem nativa: inclinação, chão/encaixe 15 px, queda
acelerada com quique, remoção fora do mundo, gatilho. Explode quando os pés de
qualquer mobile vivo (dono incluído) ficam a menos de 8 px; a supermina também
explode junto de outra mina. Explosão em y−10. O desenho gira em torno do ponto
do chão pela inclinação nativa e espelha quando a mina olha para a direita.
Balas T2/SS continuam atravessando mobiles (ADR-116). Agenda/alvo/orçamento S2
e passo da supermina seguem como antes. Evidência em `RAON_CLASSIC_FIX.md`.

## ADR-118 — rastro nativo de 8 níveis nas balas do Raon

26/10/2026, REQ-19/20/45. Referência em vídeo do usuário mostrou o T1 com
cauda de cópias. O cliente publica cada bala por quadro (`0x458690`), desenha
os níveis 7..0 com alfa 255−32k e desloca o histórico a cada quadro; o quadro
é limitado a um por tick de 20 Hz. O Godot passa a desenhar as sete cópias
anteriores com o quadro atual da bala, a partir do histórico por tick, para
T1/T2/SS do Raon; ao sair do modelo, a cena esvazia a cauda um nível por tick
(pausável), como o deslocamento nativo. Sem espelho vertical (flag nativo 0).
A mesma rotina vale para as balas comuns dos outros mobiles
no cliente, mas fica desligada para eles até decisão do usuário, porque muda
o visual já aprovado. Modelo, colisão e previsão não mudam.

## ADR-119 — rastro nativo em todas as balas comuns

26/10/2026, REQ-19/20/45. Pedido do usuário após conferir o Raon. Estende a
ADR-118: todas as classes de bala que no cliente publicam pelo `0x458690`,
`0x4ae1a0` ou `0x488880` desenham sete cópias anteriores com alfa 255−32k e
escoam a cauda após o impacto. As classes `0x488880` (Nak SS, Grub SS,
Aduka S2/SS) espelham verticalmente quando seguem para a esquerda. Desenhos
próprios sem histórico (lasers do Mage, água do Turtle, Dragon S1/S2,
satélites/íons) não mudam. Nak mantém sua orientação aprovada e recebe só as
cópias. Modelo, colisão e previsão não mudam.

## ADR-120 — rastro apenas no T1 do Raon

26/10/2026, REQ-19/20/45. Decisão do usuário: “o rastro precisa estar apenas
no T1 do Raon”. Substitui a ADR-119 por inteiro e restringe a ADR-118: somente
o T1 do Raon desenha as sete cópias e esvazia a cauda após o impacto
(`ClassicSprite.has_trail`). T2/SS do Raon e todos os outros mobiles voltam ao
sprite único aprovado; o espelho “Facing” de Nak/Grub/Aduka e as cópias do Nak
foram retirados. O censo do slot3 continua registrado como evidência do cliente,
sem efeito no Godot.

## ADR-121 — piloto no lado direito do Aduka

**Substituída pela ADR-122; implementação rejeitada pelo usuário.**

26/10/2026, REQ-19/20/45. Usuário esclareceu: “Mover o piloto para o lado
direito do mobile”. O Aduka mantém o espelho do casco contra a mira (`rear`),
mas seu RiderPivot consumido pelo desenho passa a ter X invertido. O idle
(-8,-23) torna-se (8,-23) nas coordenadas do casco; cada pose conserva seu Y.
Aplicar tanto ao piloto padrão como ao avatar equipado, sem virar suas peças.
É ajuste visual solicitado, não alegação de paridade nativa do encaixe.
Metadados/PNG originais, EPA, outros mobiles e combate permanecem preservados.
Plano: capturar antes/depois nos dois sentidos e poses; rodar regressões de
mobiles, avatar, sala e cena. Sem nova versão, exportação ou publicação.

## ADR-122 — orientação do conjunto Aduka na sala

26/10/2026, REQ-02/19/20/45. A imagem e a correção posterior do usuário
esclarecem que no lado A o personagem olha à direita e o Aduka mira à
esquerda, pela traseira. A ADR-121 deslocou o assento incorretamente; remover
essa compensação e restaurar integralmente o RiderPivot nativo. A sala passa
a converter seu sentido visual em sentido de tiro pelo `room_facing=-1` do
catálogo de apresentação do Aduka. Lado B espelhado, piloto padrão/equipado
e casco giram juntos. Arena mantém `rear` e o sentido real do tiro.
Plano: validar a sala real com Aduka nos dois lados e captura de poses nos
dois sentidos de tiro; executar regressões de sala/cena/mobile/avatar. Manter
as capturas da ADR-121 como histórico rejeitado, sem reutilizar seus números
como evidência desta correção. Sem nova versão, app ou publicação.

## ADR-123 — aproximar o piloto do centro do Aduka

27/10/2026, REQ-02/19/20/45. Usuário aprova a orientação da ADR-122 e pede
piloto mais centralizado. Somar(+8,0) em pixels nativos ao RiderPivot do
Aduka, antes de escala/espelho/inclinação. Idle(-8,-23) torna-se(0,-23);
demais poses preservam os deslocamentos relativos e todos os Y originais.
Constante no catálogo `MobileLooks`, consumo único em `ClassicSprite`, para
piloto padrão/equipado e sala/arena/loja. Não espelhar X (ADR-121 rejeitada),
nem prender X=0 por quadro. Orientação aprovada, fontes/atlas, outros mobiles
e combate preservados. É adaptação visual solicitada, sem alegação de
paridade nativa do novo encaixe. Evidência/plano: `ADUKA_CENTER.md`.

## ADR-124 — revisão da família Aduka pelo cliente original

27/10/2026. Pedido posterior à centralização aprovada: revisar toda a família
e os assets, com diferença percebida no T2. Auditar MainAction, vtables,
detonação/Thor, EPA, camadas e sons no mesmo PE/XFS. Corrigir divergências
comprovadas em módulos próprios, preservando ADR-122/123 e rastro ADR-120.
Fontes e limites comuns explícitos; sem anunciar paridade integral da engine.
Plano/evidências: `ADUKA_AUDIT.md`. Sem publicação ou nova exportação solicitada.

## ADR-125 — núcleo nativo de dano/contato/clima do Aduka e T2 legível com3 criaturas

27/10/2026. Solicitação posterior exige REA de dano/colisão, três bichos no
T2 e correção de força desproporcional no tornado com o vento atual.
`450eb0→45db20` calcula dano no cliente: substituir a lacuna/adapter da
ADR-124 por raio/queda linear inteiros, aspecto, vulnerabilidade/defesa,
tipos, escudo e XP próprios. Portar amostragem8/refino1px, raioThor2px com
ponte produção→registro→consumo e cratera por scanlines; máscara1px do
foreground original, cópia privada para CPU. Nova geometria fica restrita
a tiros Aduka/Thor, mantendo caixas de outros ataques e o apoio global.

Tornado do Aduka conserva velocidade24.8, mínimo|vx|200, duas inversões e
terceira saída; sem aceleração dentro e sem restaurar impulso inicial. Vento
atual congelado na semente volta a acelerar no tick seguinte à liberação.
Force acumula+8/tick entre20..100 e entra separado no dano. Outros climas e
itens ainda usam os contratos offline onde o consumidor nativo não foi portado.

O PE fixado tem2emissões T2. Pedido explícito de3 prevalece: override único
em `Mobiles.emission`, ticks2/6/10, sem adulterar catálogo extraído. T2 usa
os pixels originais de`bullet16sl.img` em alpha como corpo fallback para
ser legível no HD; só esse passe substitui ADD, que na captura produzia
silhuetas brancas sobre neve. Não alegar que3emissões/alpha estão no PE.
T1/SS, glows separados, posição/orientação aprovada e demais assets mantidos.

Plano/matriz/limites: `ADUKA_COMBAT_REA.md`; evidência estática Ghidra em
`docs/aduka-combat/native-proof.json`, fixtures independentes e GPU em
`docs/aduka-combat`. Não é paridade integral da engine nem execução Windows.


## ADR-126 — revisão Mage por REA: combate, EMP, força e Tempo

27/10/2026. Pedido baseado no aprendizado da revisão Aduka. Consumidores
do mesmo PE comprovam poder200/186/380, dimensões66/54/60, aspectos143/
134/130, divisão1/2/1 dos bônus, AABB/scanlines e queda linear. Mage passa
pelo núcleo numérico compartilhado daADR-125, isolado por vehicle1; T2
usa os pontos físicos da hélice no contato e na borda do tornado.
EMP esgota escudo em raio estrito150 do hotspotY−10 antes do blast normal.
Tornado conserva velocidade24.8, duas inversões/saída3; gravidade/vento
retomam no tick seguinte. Force é bônus separado por tick. Arte/registro/
EPA/LaserEffect/PCM corretos foram conferidos e preservados. A adaptação
C# de dano/colisão/EMP/tornado do Mage descrita anteriormente é substituída
somente neste escopo. Demais bridges de clima, ativação de itens, muzzle/
apoio e proteção de voo permanecem identificadas. VerMAGE_CLIENT_REVIEW.md.


## ADR-127 — Lightning: raios, choque, contato, clima e animação nativos

27/10/2026. Pedido de revisão geral pelo cliente original, apósAduka/Mage.
MesmosPE/XFS/DAT, Ghidra12.2/JDK26; matriz/plano/evidência e limites em
`LIGHTNING_CLIENT_REVIEW.md`. T1/T2 só colidem com terreno, stride3/8 e
refino1. T1 usa primeira superfície vertical do topo; T2 duas diagonais
com ordem e sinais nativos. SS seleciona inimigos em raio estrito120,
cria raios/T1 remotos e não inventa blast próprio no ponto do guia.

Choque76/76/46, cadeia20 e raios70/70/120 são campos separados de poder/
Attack/Defense. Mecânicos ampliam raio20% e dano8%; cadeia usa raio original
e exclui alvosflag1/2. Resolução ao fim do tick mantém elegibilidade do golpe
letal para propagar antes do resultado. Real e CPU usam o mesmo estado/cópia.
Queda linear, Defense, crateras e contato usam núcleo comum comprovado;
coarse_step é parametrizado com padrão8 para preservar os outros portes.
Force+3/+8/+8 separado; tornado preserva24.8, duas inversões e saída3.

Arte original/EPA/pivôs/PCM conferidos. Lightning.xtf é desenhado em quads
inteiros/UV1/4/alpha255−24×tick; SSpl emADD, sem rastro. A apresentação usa
RNG local de variantes. Avatar e seus efeitos não aparecem emdead, conforme
guardas das texturasAvata noPE; chassis segue. Sem editar11campos de cabeçalho
que não são pivôs válidos nessa pose. Avatares/HD vivos e demais mobiles
preservados. Bridges de clima/itens/origem/scheduler e demais limites seguem
explícitos; não é execução dinâmica nem paridade integral do cliente.

## ADR-128 — climas secundários do Mage pelo cliente original

27/10/2026. Substitui os bridges de clima daADR-126 nas partidas contendo
Mage. `mage_weather.gd` mantém calendário8/categorias7, LCGs/CRT, vento,
intervalos de coluna do `stage.dat`, mescla e limpeza43c620 a cada turno.
Miramo usa[2,1,2,1,2,0,0]: Thor ocupa o peso anteriormente atribuído à cura
pelo C#. Fraqueza/Espelho/Aleatório não entram nesse calendário. As demais
combinações de mobiles conservam o adaptador anterior.

Moon cura somente o ator do turno em3%/8% do maxHP final, semREGEN; Eclipse
bloqueia itens e limpaDual/Dual+, sem bloqueioSS adicional. Anexos Mage
executam elétrico→Thor→blast próprio/EMP; choque/cadeia resolve ao fim do
tick. Elétrico tem blastLightningT1 próprio com poder/dimensão divididos
por2 após atributos; NÃO herdaForce15c0. O percentual17e4 é outro campo.
Thor consulta o clima no impacto, divide só poder por1/2/1, multiplica o
período visual, inicia emY500/X porLCG, avança40Y na fronteira e recalcula
nível na transição seguinte. Snapshot copia todo o estado, semIO no worker.

Três colunas usamXTFs originais, tiles64Y, UV/scroll/20Hz e mistura nativos;
assets antigos preservados. Seeds/período/opções de sala são entradas
offline; ativação de itens, regeneração comum e partículas decorativas em
voo permanecem bridges declarados. Sem alegação de execução Windows ou
paridade integral. Matriz, provas e resultados em `MAGE_SECONDARY_WEATHER.md`.

## ADR-129 — partículas decorativas originais em voo do Mage

27/10/2026. Substitui o bridge de partículas em voo declarado naADR-128,
somente paraMage T1/T2/SS. `455cc0` publica amostras compactas dos pontos
coarse8 já calculados, após clima e antes do contato; refino1 não emite.
`MageSparks` consome esses registros no apresentador, com geradorMSVCRT
próprio e timestamp20Hz copiado no snapshot. Nenhum sorteio visual ou
objeto gráfico entra no modelo/worker; dano, contato e RNG de combate
permanecem preservados. Outros mobiles e projéteis de item mantêm seus
consumidores anteriores.

Force usa rand%400<qualidade×Force; Electric, rand%100<qualidade. Force0
mantém as tentativas436dc0 e436bd0. Densidade passivaMage1e50=0 impede
uma terceira família, mas não elimina a rolagem comum. Pontos de nascimento
fixos, offsets−10..10 e ângulos0..359; ambas famílias nascem antes do seu
Animate no mesmo tick. Primeiro desenhoclock1, último15, remoção16;
giro1/6°, alfa255−16clock, tamanho2×(16−clock) e frames de2ticks.

CrashTexture.xtf original decodificada sem geração/reescala. Quad4ec840 usa
LUTfloat32 e storesFPU, UV1/8 nas faixasV.25/.375; ambasSRCALPHA/ONE.
Pausa congela partículas/RNG, saída/nova partida limpa dados eRIDs.
Qualidade3 e seed4242 são entradas locais explícitas; não se alega replay
do gerador globalWindows. Arte/registro/LaserEffect, combate/perfil e fontes
anteriores preservados. Contrato, plano, evidência e validação em
`MAGE_FLIGHT_SPARKS.md`.

## ADR-130 — Avatar Shop e avatares com os assets originais do cliente

27/10/2026, REQ-47 (e REQ-10/20/38..41/46). Pedido do usuário: corrigir os
assets/imagens do Avatar Shop usando os originais do jogo, com REA quando
necessário. Decisões do usuário: avatares **tudo original** (loja, sala e
batalha), botões com as imagens originais em inglês e loja **igual ao
original** (sem busca, contador, "Nível", "Standard"/"Treino offline" fixos).

Substitui na loja a composição vetorial/GPT da 0.16 (fundo `xfs_landscape`,
retratos `xfs_portraits`, molduras `XfsStyle`, rótulos PT e prévia de mobile
OpenBound) e, em todo o jogo, o uso ativo dos mestres HD 0.17/0.18 de
avatares: `AvatarArt` passa a desenhar as peças nativas do XFS por padrão
(`new(true)` mantém o HD para auditorias). Arquivos HD preservados em disco.

A tela usa `store_back`/`store_avatar`/`store_myavatar`/`store_icon`/
`store_window_back`, botões `b_store_*`/`b_myavatar_*`/`b_storewindow_*`/
`b_scroll_*`, `numfont` e o atlas ASCII do `font.fnt`, extraídos por
`scripts/import_xfs_shop.py` (116 frames anteriores inalterados, 171 no total)
e acabados com o BICUBIC4× aprovado (ADR-101/103) por
`scripts/build_shop_smooth_hd.py`, com fallback nativo validado por hash.

Regras comprovadas no cliente (REA/Hopper e Ghidra 12.2 headless, PE
`4af6283d…`): grade de cards `0x44a000`, até três status em ordem fixa com
regra de sinal própria do shot_delay, preço `%8d` de `0x44c460` com avanço
10/4 e vírgulas 279/280, rótulos CASH/GOLD/ONLY. Demais posições medidas por
casamento de template na captura `gb-avatar.png`. Gênero/atributos ficam na
faixa lateral fora do palco; Laundry restaura a prévia; Sell/Gift/BUDDY/CASH
CHARGE desabilitados. Catálogo, preços, bônus, compra/rollback, atributos e
perfil inalterados. Matriz e limites em `AVATAR_SHOP_ORIGINAL.md`.

## ADR-131 — preto opaco nas faixas RLE e retrato pelo pivô

27/10/2026, REQ-47. O usuário apontou contornos pontilhados nos retratos da
loja. Causa: `decode_gunbound_img.py` aplicava a chave de cor preta também
aos frames RLE (tipo 1), cuja transparência já está nas lacunas entre faixas;
os pretos do contorno viravam furos. Na captura `gb-avatar.png` esses pixels
são pretos (109 em `sfh00001`, média ≈20). Regra corrigida: só frames cheios
RGB565 (tipo 0) usam preto como chave (os três retratos padrão 28×28 têm fundo
preto); RLE mantém o preto opaco; ARGB4444 segue o alfa explícito.

Afeta 496 dos 534 retratos e 98 frames da loja (contornos, dígitos com caixa
preta, botões). Peças vestidas são ARGB4444 e não mudaram. Retratos corrigidos
ganham arquivo `_rle` (anterior preservado); frames da loja e derivados 4×
foram regenerados. O catálogo grava `portrait_pivot`; o cliente desenha o
retrato em card+(52,62)+pivô, confirmado nos nove cards da captura.
Complementa a ADR-130 (que dizia 116 frames inalterados).

## ADR-132 — objetivo jglim e OpenBound fora do escopo

27/10/2026. Pedido do usuário: o objetivo do projeto é reescrever com fidelidade
jglim/gunbound-launcher (launcher e TestClient do cliente Thor's Hammer) e
jglim/gunbound-server, com suporte multiplataforma e novas funcionalidades sobre
essa base. OpenBound é outra versão do jogo (Season 2) e sai do escopo: não é
fonte de regra, dado ou arte, nem pasta anexada às sessões.

Consequências: a skill gunbound-mobile-port foi apagada; `.claude/settings.json`,
`.devin/config.json` e o hook deixam de anexar/proteger `~/Workspaces/Gunbound`;
o agente fidelity-reviewer e as skills gunbound-client-port/gunbound-classic-hd
citam só o cliente; `.claude/skills/gunbound-classic-hd` passa a link para
`skills/`. A hierarquia vira cliente comprovado > projetos jglim > adaptação
declarada. Regras e assets herdados dessa fase continuam ativos como adaptação
até serem substituídos; `assets/openbound/` mantém nome, atribuição e licença.
AGENTS, README e documentos de entrada foram limpos; registros e ADRs antigos
ficam como histórico. Substitui a regra "senão vale o C#" da ADR-076 e o papel
de fallback C# nas ADRs anteriores. Rede e servidor continuam no roadmap.


## ADR-133 — Assets de batalha extraídos do cliente (27/10/2026)

Pedido posterior manda substituir os recursos ativos de Miramo Town A, HUD,
clima/Thor, itens e música/áudio por arquivos do Thor's Hammer. Supera o uso
ativo de GPT nesses grupos das ADR-039/044/050/053/058 e demais decisões de
arte dessa fase, preservando todos os derivados no disco e o histórico.
Não altera o visual aprovado dos16mobiles/avatares nem regras de combate.

Recursos novos em assets/xfs/{maps,hud,weather,thor,items,audio}, extraídos de
graphics.xfs/sound.xfs e catalogados por hash. Miramo usa o próprio alpha de
mos.img, comprovado contra mos.lnd em3.240.000pixels, idêntico à máscara
anterior. HUD e itens usam composições explícitas dos recortes nativos nas
caixas/hitboxes anteriores; isso não anuncia paridade de layout/animação com
o cliente Windows. Hover/clique de itens repetem os dois estados existentes.
Climas conservam os adaptadores de regra/calendário fora do porte Mage já
aprovado; usar textura original não torna a simulação nativa.

Lacunas ficam na arte herdada1×, sem GPT ativo ou recurso inventado: categorias
Weakness/Mirror/Random, componentes de HUD sem equivalente, aura UsingItem,
fundo/abas do antigo Select Item e sons cujo evento/arquivo não foi comprovado.
PE pede itemblast.xes ausente e lightningblast.xes divergente do nome
lightingblast.xes disponível. Não se estabelece equivalência por semelhança.
A música usa stage1..6 e mantém agenda aleatória declarada; turn2/turn do
cliente distinguem ator local/adversário. Fallback por grupo é testado.

Inventário, fontes e limites em CLIENT_ASSETS_PORT.md e nos três relatórios
de HUD/clima/áudio, mais CLIENT_ASSETS_ITEMS.md. Escuta, execução do cliente
Windows e aceite humano continuam separados da validação automatizada.
A solicitação não autoriza commit/push nem entrega de pacote exportado.

## ADR-134 — Header e footer nativos separados (27/10/2026)

Validação visual do usuário substitui a preservação das caixas antigas da
ADR-133 para o HUD. Usar as faixas azuis de play_back.img: header com Options,
clima, Gold, itens e Skip; footer com tiros, ângulo, modo de mira e carga.
Peças/pivôs/fontes específicos vêm do cliente, inclusive numfont e os botões
40×30/35×34. Botões/áreas de input acompanham as novas posições.

`battle_hud_layout.gd` é o contrato compartilhado de geometria. Header64px,
footer70,4px e mundo1280×665,6 desdey64 no canvas1280×800; escala uniforme1,6.
Isso preserva o aspecto das peças, mantendo declarada a adaptação do miolo
800×600→800×500. Câmera/draw/input recebem o recorte; modelo e colisão ficam
em coordenadas do mundo. MOVE aparece durante input de movimento no turno
próprio (visibilidade ainda adaptada). Fallback preserva caixas novas.

A referência Jewel esclarece variantes, sem autorizar outro modo. TreinoSolo
mostra Gold no painel roxo178; Life172/173 e Jewel179/180 são identificados
separadamente e permanecem inativos, sem placares fictícios. F4/reserva amarela
já pintados no fundo nativo ficam inativos. Não implementar Tag/Jewel/Score.

Plano/fontes/evidência/QA em HUD_CLIENT_LAYOUT.md. Originais, HD anteriores,
perfil, avatares, mobiles, regras e arquivos Git preexistentes preservados.
Sem commit/push nem pacote exportado nesta correção.

Extensão do mesmo pedido: cronômetro e vento também migram para os recursos
comprovados. Clock usa numfont146..166 e ponto156 (segundos+décimos); vento
usa moon.xtf e numfont167..177. Não altera o prazo30s nem vento físico.
Orientação do anel segue o vetor real; texto imóvel. Ausência de qualquer
parte nativa ativa o fallback integral do grupo. Detalhes/ASM/oráculos no
mesmo registroHUD_CLIENT_LAYOUT.

## ADR-135 — Posição e etapas da barra MOVE (27/10/2026)

A validação do usuário corrige a suposição da ADR-134 de colocar MOVE acima
do footer. O consumidor406990 desenha a moldura play_back[5+estágio] em169,574
(flag1) e o preenchimento8 em244,583, com clip inclusivo. O quadro5 tem pivô
(0,+10), o6 pivô(0,0); ambos terminam emy600 no cliente. No canvas curto,
y484/474 da moldura e483 do fill, terminando no rodapé y500.

Movimento próprio escreve flag1/delta+1/estágio0; atualização limita etapa a1;
soltar escreve flag0/delta−1/estágio1. O porte replica essa progressão privada
na apresentação; pausa não avança e nenhuma regra física/orçamento muda.
Ritmo das atualizações segue o Godot, explicitamente sem afirmar scheduler
nativo. Flag2 tem outro caminho, fora deste recorte de movimento próprio.

Novo NativeMoveExpanded é quadro6 sem fit/recorte. Falha de origem/hash usa
quadro5 compacto; GPU compara o resultado com uma referência compacta.
Detalhes/ASM/fontes em MOVE_BAR_NATIVE.md. Header, Gold, itens, cronômetro,
vento, mobiles, avatares e perfil preservados. Sem commit/push/exportação.

## ADR-136 — Fundo opaco dos quadros do footer (27/10/2026)

O usuário apontou background ausente após a correção de posição MOVE. O
importador estava herdando uma chave de cor preta do decoder de sprites.
REA/Hopper no PE fixado confirmou play_back[1] e overlays retangulares, o
caminho RGB5654ebaf0/4eba80, os spans4e9130 e o flush4e93e0 por REP MOVSD/MOVSB.
Preto0x0000 é copiado, sem transparência, nesse caminho. A importação local
restaura alpha255 somente para tipo0 de play_back.img, sem alterar decoder
global ou fontes/avatares/mobiles. RLE e XTF mantêm suas regras anteriores.

Teste esperado por palavras brutas substitui a circularidade de comparar com
o mesmo decoder. Probe GPU800×44 tem os35.200 pixels iguais ao raster bruto,
independente do fundo magenta/verde. Mantêm-se layout e etapas daADR-135;
a alegação anterior de fidelidade do raster do fundo fica substituída por este
contrato. Não implica cliente Windows executado ou paridade integral do jogo.
Registro emFOOTER_BACKGROUND_NATIVE.md; sem versão/export/commit/push.


## ADR-137 — Menu clássico único na batalha (27/10/2026)

Pedido do usuário substitui o menu de pausa próprio e a recomposição do
PopupGameOptions das ADR-052/053/056/133. Usar play_option.img completo,
rádio e b_option_cancel/exitgame/confirm sem apagar labels ou deformar frames.
REA/Hopper no PE4af6283d… rastreou loader/render/input/dispatch e áudio;
fonte, matriz e13registros portáveis em BATTLE_OPTIONS_NATIVE.md e docs/battle-options.

O painel276×408 fica em8,45 nativos, escala1,6. Input conserva limites
estritos e seis níveis de scroll/áudio; Drag/Slice fazem bridge para os IDs
já existentes. Scroll desenha trunc(valor/10)-2; música/efeito usam LUT exata.
SetVolume recebe100*(valor−100) centésimos de dB: converter para amplitude,
sem piso artificial para valores1..19; OFF interrompe efeitos ativos.
O master−19dB e o backend/agendamento de música permanecem adaptações.

ESC/Options/P acionam o mesmo menu, show_pause permanece apenas como alias.
OK confirma/grava; X/ESC restauram snapshot e volumes; QUIT cancela edição
antes de voltar à sala, sem recompensar abandono. Disponibilidade/saída de
QUIT e congelamento continuam adaptações do treino offline; não portar os
estados de saída de rede ou impedir o usuário de deixar o treino.
Sniper/MIDI/3d não portados ficam desabilitados, sem inventar efeitos.

O grupo de cinco atlas tem cópia nativa independente para fallback, com
validação por dimensão/hashRGBA. Originais/HD anteriores preservados;
61atlasHUD/15entradas; sem alteração no decoder global, física, CPU ou perfil.
Sem cliente Windows executado/escuta/aceite humano; sem versão/app/exportação,
commit ou push. Regressão e capturas devem ser lidas no registro da entrega.

## ADR-138 — tela de transição ao iniciar a partida

Integrado à `main` local em 27/10/2026 (PR #5, branch `cursor/match-loading-screen-ba1a`).
O PR numerava esta entrega como REQ-48/ADR-133, já usados pelos assets de
batalha; foi renumerada para REQ-49/ADR-138 sem mudar o conteúdo.

27/10/2026. O Start da sala mostra a tela de loading do cliente Thor's Hammer
antes da batalha. No 1×1 local ela fica no mínimo 5 segundos: o tempo fixo
substitui a espera de rede, que continua fora do escopo. A tela usa
`load_back.img` e `load_stage01.img` (Miramo Town, rótulo no próprio bitmap;
a máscara é o quadro 1). Os nomes seguem a conta de 0x004430c0: coluna
`spawn_x * 748 / largura do mapa` e linha do primeiro pixel não zero da
máscara, mais 18. Sem máscara, y = 122.

Random é resolvido ao abrir a tela, não ao entrar na batalha. O card central
e os dois lugares mostram o mobile sorteado (Dragon ou Knight). A partida
recebe esses ids e os mesmos pontos de spawn. `start_match()` sem argumentos
continua imediato, para as suítes que montam a batalha direto (a revanche
citada no PR saiu com a ADR-139). A fórmula `map_id * 11 + lado` vista no carregamento do arquivo não
foi usada para escolher o bitmap: o índice 11 é cópia do Cave, e o quadro
com o rótulo MIRAMO TOWN é o `load_stage01`.

## ADR-139 — Janela de resultado do cliente (27/10/2026)

Pedido do usuário: encerrar a partida mostrando vencedores e perdedores
como no cliente (imagem de referência). Substitui o cartão próprio de
resultado com REVANCHE (REQ-09). Ghidra 12.2 no PE `4af6283d…` localizou o
recurso 9001 `result_back.img`, o render `FUN_004c8890`, a linha
`FUN_004d0260` e o botão OK criado na mensagem 0x4413 de `FUN_004b4100`.

Painéis por time (A em 24,48; B em 403,48), WIN se o time venceu. Linhas a
partir de y151, passo 66. Barra, patente `rank1`, apelido `font.fnt`, P
`%3d` (numfont 80/90, letra 100/101) e G `%5d` (fonte por time 103/114,
letra 113/124). Sem escurecer a batalha; um bloqueador transparente impede
o HUD por baixo, como a remoção dos botões no cliente.

Adaptações: OK volta à sala; o OK fica sobre o footer no canvas de 500 de
altura; P mostra o XP do porte e a CPU não pontua; CPU como "CPU"/Chick;
empate desenha LOSE nos dois lados; guild, marcador de evento e log no chat
inativos; aviso discreto só quando o perfil não grava. Assets em catálogo
próprio `assets/xfs/result`, sem derivado HD. Contrato em
`RESULT_SCREEN_NATIVE.md`.


### Correção da ADR-138 após validação — 27/10/2026

O pedido atual substitui a decisão anterior da ADR-138 de mostrar o mobile
sorteado no card central e somente cascos nos lugares. O centro mantém a
imagem/título do mapa, vindos do quadro nativo `ready_selectmap.img` já importado
como `room_maps[1]`; o título faz parte do bitmap. Os lugares usam a composição
completa da sala (mobile e piloto, equipamento do usuário e animação). Nenhum
nome de mobile aparece no canto dos slots. Random, espera de 5 segundos e
spawns compartilhados com a batalha permanecem. Sem regra nova ou mudança no
menu clássico da ADR-137; não implica commit, exportação ou push.

### ADR-138 — posição dos nomes na superfície (27/10/2026)

O usuário pediu o commit local da pré-partida e esclareceu que deseja apenas
reposicionar os nomes na prévia inferior. Ghidra confirmou que 0x4430c0
guarda linha+18 porque o mapa nativo é desenhado em y18; 0x442280 desenha o
nome em y+5. `LoadingView` já posiciona a imagem por STAGE_ORIGIN: retirar os
18 repetidos e o ajuste visual extra20, usando origem+linha+5. Isso substitui
a adaptação anterior do deslocamento para o banco de neve. Imagem/máscara do
painel aprovado, fonte, cor e indicadores existentes permanecem; não adicionar
miniaturas de mobile. Menu clássico e regras preservados; commit autorizado,
sem exportação ou push.

## ADR-140 — posições da sala conforme capacidade

27/10/2026, issue #10, REQ-02. A sala 1×1 mostra apenas TeamA0 e
TeamB0. A capacidade por time determina a visibilidade das faixas e dos
poços; não há seletor de capacidade ou novos modos. O próprio `room_back`
contém os seis poços excedentes: coberturas na cor do painel os ocultam,
sem interceptar input ou alterar o asset. Isso substitui as oito faixas da
ADR-105 para 1×1; grade, Random, itens e fluxo permanecem.

## ADR-141 — restaurar o relevo dos poços vazios

27/10/2026, REQ-02. A imagem de referência e o pedido posterior substituem
a cobertura azul da ADR-140. O quadro 0 de `ready_back.img` já contém os
poços rebaixados; a sala deve deixá-los visíveis, escondendo somente as seis
faixas A/B excedentes. O fundo nativo e seu derivado 4× são preservados.
REA e comparação do quadro XFS estão em `ROOM_REFERENCE_LAYOUT.md`; o
carregamento está comprovado por análise estática, não por execução do
cliente Windows. Capacidade 1×1 e controles existentes permanecem.
