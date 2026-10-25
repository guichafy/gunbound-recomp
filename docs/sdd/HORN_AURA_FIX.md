# Aura do chifre — correção focada

REQ-10/20/39; ADR-078. Usuário confirmou aura pulsante ao redor do chifre e
apontou distância entre luz e peça. Validado primeiro em worktree isolado
(base fix/0.18.2); integrado somente este reparo na main atual, preservando as
regras de batalha e as demais branches.

O PNG de luz separado mantinha geometria diferente da peça. Agora uma máscara
em memória seleciona o ouro da própria cabeça HD, dentro da janela do chifre.
Uma distância de contorno produz halo suave com origem, escala e recorte
compartilhados com a cabeça. Cache fixo, sem deslocamento por quadro. Aura
é desenhada atrás da cabeça; ouro/segmentos/contorno ficam preservados. O
relógio existente mantém pulsação e pausa. Originais e masters preservados.

Plano: reproduzir ordem e deslocamento; testar pontos reais do ouro; capturar
162frames60fps/1920×1080 com sentidos/inclinação e30frames de pausa; comparar
superfície com referência sem aura; regressões, QA e app exportado na main.

Implementação: avatar_contour_glow.gd, AvatarXfsHD, AvatarArt e metadado somente
Great Devil L. Outros19efeitos inalterados. Revisão independente confirmou
origem/escala/ordem e pediu guarda contra perfil de contorno na base: `index<=0`
retorna vazio antes de qualquer chamada recursiva; dois testes negativos cobrem
o retorno e o fallback integral. Cache não cresce com o relógio.

GPU da main: 162 quadros em 1920×1080/60fps, dois sentidos e inclinação −9°.
30 quadros de pausa idênticos. 2804 amostras de ouro, zero violações do limite
de transparência da fonte (alpha original 243–254, mais 2/255 para filtragem).
Energia do halo: pico1803,62746/vale1081,06275, razão1,66838; superfície do ouro
preservada. PNGs, vídeo e relatório em `docs/horn-aura/`.

Conclusão da main: `check.sh --quick`5296checks e13testesPython PASS. Todos37
lotes recapturados com o renderer final; QA550/629,12N/A e auditoria runtime
550confirmados/zero pendentes. App/ZIP0.18.3 reexportados; assinatura estrita e
versão conferidas. Smoke PCK fora do projeto PASS (loja/550avatares/629camadas/
compra/vestir/reload/batalha); capturas shop-avatar/mobile vêm desse PCK e
confirmam `contour_derived`. Sem novos testes de partidas completas por ser
reparo visual. Aceite da aparência pelo usuário continua pendente.

## Correção após teste do usuário — 23/10/2026

0.18.3 foi rejeitada: brilho e animação ficaram imperceptíveis. O halo atrás
da anatomia mudou a aparência além do pedido. Plano REQ-10/20/39: reproduzir
a perda no tamanho real da loja; restaurar a textura L anterior sobre a peça,
com mesma opacidade e relógio; ajustar apenas sua curva por geometria de UV
constante, ancorada na cabeça. Conferir pico/vale no próprio ouro, ambos os
sentidos/inclinação, pausa e prévias Avatar/Mobile do aplicativo exportado.
Originais e demais19efeitos preservados. ADR-079 substitui ADR-078.

Implementação0.18.4: `AvatarXfsHD.curve_light` registra nove marcos em64faixas
UV constantes sobre a textura L existente. Mesh reutilizada no cache; mesmo
transform da anatomia, composição sobre a peça e opacidade0,78382033. Fórmula
de pulsação0,8+0,2sin(ageTAU/1,1) preservada; nenhum PNG regenerado/editado.

Teste GPU antes da implementação reproduziu o relato: energia animada82,847
contra487,8 do efeito anterior no tamanho da loja. Depois do ajuste353,184 e
861pixels variando; o efeito segue os pontos reais do ouro na curva.162quadros,
ambos sentidos/escalas, inclinação e30quadros pausados idênticos. Vídeo/PNGs
em `docs/horn-curve/`; metadado `light_curve` somente Great Devil L.

Prévia real: Avatar pico642,094/vale386,729 e Mobile543,667/328,580, isolando o
brilho de cada pose contra referência sem luz. Revisão independente sem achados.
`check.sh --quick`5299checks e13Python PASS; QA37lotes e550avatares/629camadas
atualizados, zero pendentes/falhas no audit runtime. App/ZIP0.18.4 exportados e
assinatura estrita/versão conferidas. Smoke PCK550/629/loja/vestir/reload/batalha
PASS fora do projeto. Pico/vale Avatar/Mobile acima reproduzidos no PCK; capturas
e relatório em `docs/horn-curve/`. Em 23/10/2026 o usuário relatou que a
implementação ficou melhor e solicitou revisão, commit e envio à main remota.

## Brilho refeito a partir do clássico — 24/10/2026

Usuário: os chifres do Great Devil Head ainda não estavam bons; refazer a partir
do clássico com o brilho na posição e no formato do chifre, como na baixa
resolução. ADR-082 substitui ADR-079. REQ-10/20/39.

Medição do clássico: `mh00071l` é a silhueta do próprio chifre, desenhada por
cima. Após a conversão L (alfa × canal mais claro), núcleo branco 187/255 sobre
todo o chifre e o contorno, rampa 187→162→125→73→23 nos 4 px nativos externos.
A luz acima de 20/90/160 cobre 1,81/1,43/0,98× a área do chifre e 71% da energia
fica sobre ele. A meia-lua HD (1094×1173) tinha outra geometria; curvada na
0.18.4, cobria só 2301/2563 pixels do ouro e deixava a base dourada.

Implementação 0.18.7: `scripts/build_devil_horn_light.py` lê a cabeça HD
selecionada (`batch_005`, 198×153), separa o ouro saturado, fecha os sulcos,
pega o componente principal, preenche furos e soma 3 px de contorno. Borda:
crescimento 4 px + desfoque 5 (1,86/1,36/1,01× e 71%, próximo do clássico).
Núcleo branco, franja creme (255,238,176), alfa assado. Saída
`great_devil_horn_light.png` 238×193 (cabeça + 20 px por lado). Registro
`overlay_base` em `AvatarXfsHD.piece`: origem/escala da cabeça, opacidade 1,
fallback original se tamanho/deslocamento/opacidade forem inválidos. Pulsação
0,8+0,2·sin(age·TAU/1,1) e relógio mantidos. `repair_avatar_effect_alignment.py`
não recoloca mais a curva. Reexecutar `register_xfs_avatar_hd.py batch_005`
devolve a célula gerada à camada: rodar o script de novo em seguida. Sem nova geração GPT Images: a forma vem do chifre HD.

Validação: RED no catálogo 0.18.4 (5 falhas, cobertura 2301/2563); GREEN
`test_xfs_hd_migration` 2009 checks (cobertura ≥98% do ouro com alfa >0,7,
zero vazamento em rosto/cabelo, escala/origem da cabeça, fallback com NaN,
deslocamento ou opacidade inválidos). GPU 1920×1080/60fps, 162 quadros, dois
sentidos e −9°, 30 quadros de pausa idênticos: `docs/horn-classic/`
(clássico × 0.18.4 × 0.18.7, `motion.mp4`). Pulso na escala da loja 635,9 contra
353,2 da 0.18.4 (1503 pixels visíveis). Prévia real da loja: Avatar 1163/701 e
Mobile 900/543 (pico/vale; 0.18.4: 642/387 e 544/329). 37 lotes recapturados,
QA 550 e auditoria runtime 550 confirmados/0 pendentes/0 falhas.
Usuário validou na main em 24/10/2026: "funcionou muito melhor".

