# Partículas decorativas em voo do Mage

Pedido de27/10/2026, apósADR-128. REQ-07/08/09/24/44; apresentação dos
tirosMage T1/T2/SS comForce/eletricidade. Preservar combate, fontes, elenco,
avatares, HD e perfil. Não exportar/públicar uma nova aplicação neste corte.

Plano: confirmar ASM/fábricas/Animate/Draw/dispatch; fixtures independentes
e RED; emitir amostras dos pontos físicos já calculados; implementar estado
visual em20Hz, textura/quad nativos; regressões, GPU temporal, revisão e
registro. Sem trocar as regras de colisão para produzir efeitos.

## Contrato comprovado

MesmoPE/XFS daADR-128. `455cc0` tentaFX em cada coarsepoint8px, após clima
e antes da colisão; refino1 não emite. Menor coordenada avança antes ded0,
há overshoot e delta zero ainda tem uma amostra. Force436dc0 sempre tenta,
inclusive valor0: `rand()%400 < Effect3D*Force15c0`. Electric436ec0 só com
3918true: `rand()%100 < Effect3D`. Nascimento tem offsetsX/Y `rand()%21−10`
e ângulo `rand()%360`. Guard6a7f74 suprimeFX no passe de simulação sem gráficos.
QuandoForce0, o helper comum436bd0 ainda consome uma rolagem. A densidade
passiva1e50 do Mage é0, portanto esse helper não cria uma terceira família;
essa tentativa também deve permanecer na sequência visual.

Force48dcc0/48dd10/48dd80 usa categoria190003; Electric481e30/481e80/481ef0,
190004. ObjetosMage100002 são atualizados antes deles na árvore2D ascendente:
primeiro desenho já temclock1, alfa239 e ângulo acrescido1/6. Clock15
continua visível;16 é removido antes do desenho. Posição de nascimento fica
fixa; tamanho2*(16−clock), alfa255−16clock, framefloor(clock/2), UV1/8;
Force ocupaV.25..375, Electric.375..5. Quad4ec840 usaLUTfloat32 e storesFPU,
sem truncar os vértices para inteiros. AmbosSRCALPHA/ONE em450c20.

## Integração prevista

O modelo publica dados compactos das amostras já calculadas e um relógio
decorativo inteiro. Não executa sorteios nem cria partículas na previsão.
O apresentador consome essas amostras e mantém geradorMSVCRT próprio,
qualidadeEffect3D3 como entrada local explícita, clock/ângulos/término nativos.
Eventos com timestamps preservam passos agrupados no mesmo quadro. Pausa
congela tudo e troca de tela limpa dados/RIDs. Outros mobiles conservam o
renderer anterior. Seeds locais não demonstram replay do RNG globalWindows.

## Validação e entrega

Harness completo: **27046 checks Godot +60 testesPython +29 partidas,
98suítes/parse, zero falhas, exit0**. Cópia imutável byte a byte do
`scripts/check.sh`; implementação/fixtures/assets permaneceram iguais por
hash durante a rodada. Testes novos:63 de emissão/RNG/clock e206 de raster,
mais2Python com todos os65536pixels. FluxoRED→GREEN observado; revisão
independente corrigiu a segunda rolagem comum deForce0 e terminou semP1/P2.
Probes independentes conferiram partículas vivas em10/30/40/60FPS e relógio
após resultado, sem alterar atores ou publicar novos eventos de combate.

GPU realAppleM4Pro/Compatibility:360quadros1920×1080, relógio60Hz,12casos
T1/T2/SS ×Force/Electric ×dois sentidos. Pausas30frames idênticas emRGBA,
retomada e limpeza verificadas. Vídeo6s/360frames em `docs/mage-sparks`.
Arena real comHUD/T2/Force/Electric também capturada, com pausa30 idêntica,
retomada e limpeza ao voltar ao menu; perfil isolado e som silenciado.
34,386s de captura/escrita não é uma medição deperformance60FPS.

REA estático no mesmoPE; não foi executado clienteWindows nem escuta/aceite
visual humano. MSVCRT525c4f foi confirmado emASM:214013/2531011,shift16,
mask32767, estadoPTD+14 viaFLS/TLS; seed4242 e qualidade3 continuam entradas
locais explícitas, sem replay dos demais consumidores do RNG da sessão.
Importação teve somente os erros ambientais conhecidos deCA/editor_settings;
GPU/harness finais semerro de script ou recurso. A tentativa inicial de captura
foi recusada por nomes locais do scriptQA e corrigida antes daGPU final; os resultados acima usam apenas a execução completa.

`native-proof.json` fixa entradas, VAs, manifestos completos e parciais;
`verified-source.json` registra hashes/contagens/logs/limites. Solicitação
posterior autoriza commit e push na `main`, incluindo as dependências nativas
anteriores pendentes do conjunto integrado. Não foi feita nova exportação
deaplicativo, alteração de versão ou publicação deapp/ZIP.
