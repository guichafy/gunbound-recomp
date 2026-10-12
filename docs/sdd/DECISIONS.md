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
