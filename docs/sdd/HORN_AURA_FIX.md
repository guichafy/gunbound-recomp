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
