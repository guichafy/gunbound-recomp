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

## ADR-069 — estado coerente e posicionamento da loja

Revisão contra C#: usuário escolheu abas acima dos cards e rodapé na ordem
Experimentar/Vestir→Comprar→Presente. Preservar grade3×3/lista lateral;
alinhar legendas em áreas separadas do ícone, com hitbox incluindo o texto.
Crop Miramo com proporção nativa, em vez de esticar imagem. Seleção ausente
da página filtrada deve limpar ações; save falho ao vestir deve preservar
seleção/equipamento/prévia e mostrar erro, incluindo clique pela grade.
Não adicionar bônus por peça, novos assets/rig nem alterações de combate.

## ADR-070 — loja Full HD orientada pelo vídeo

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
