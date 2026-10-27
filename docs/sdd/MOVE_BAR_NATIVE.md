# Barra MOVE no footer — REQ-27/28/48 / ADR-135

> Correção posterior do fundo: ADR-136, `FOOTER_BACKGROUND_NATIVE.md`
> (em docs/sdd). Capturas anteriores preservam o raster com preto transparente;
> a validação atual está em `docs/footer-background/`.

Correção pedida após validação: MOVE foi colocada acima do footer por uma
suposição de composição. O consumidor nativo confirma que ela sobrepõe a
parte inferior da área de carga. Arte nativa isolada não comprovava posição.

Fontes: graphics.xfs a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08;
PE 4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde.
Ghidra 12.2/JDK26, extratos novos em `.tools/move-bar/`.

| Contrato | Evidência | Classificação |
|---|---|---|
| Movimento próprio ativa flag1, delta+1, estágio0 | 45fdbc..45fdd7 /460241..46025c; simétrico esquerda/direita | comprovado |
| Soltar ativa flag0, delta−1, estágio1 | 46046e..460489 | comprovado |
| Update soma estágio+delta e limita0..1 | 406969..40698b, chamada4be267 | comprovado |
| Moldura é play_back[5+estágio], origem169,574 na flag1 | 407860..407889 | comprovado |
| Quadro5 é485×16, pivô(0,+10); quadro 6 é485×26, pivô(0,0) | IMG+metadadosXFS | comprovado |
| Preenchimento ativo: quadro 8,400×12 em244,583 | 407949..40796f | comprovado |
| Clip à direita:244+trunc(400×restante/máximo), limite inclusivo | 4078fa..407944 /4eadb0 e4ed870 | comprovado |
| No canvas curto, subtrair100 de y, preservar x/pivô | ADR-134: footer556→456 | derivado |
| Progresso usa orçamento atual do modelo; update visual segue frames Godot | porte atual | adaptação declarada |

Flag2 possui outro posicionamento/quadros; não é usada pelo movimento próprio
confirmado acima. Não ampliar esse comportamento sem identificar seu produtor.

## Plano

- [x] Oráculos de posição, pivô, clip inclusivo e transição abrir/fechar.
- [x] Extrair quadro 6 sem redimensionar; validar fallback compacto.
- [x] Mover moldura/fill para dentro do footer, mantendo só apresentação.
- [x] Capturas GPU nos dois sentidos, pausa e soltura; cenas e harness pertinente.
- [x] Atualizar SPEC/DECISIONS/TASKS/HANDOFF; manter arte/estado anterior como histórico.

Sem alteração de movimento físico, custo, carga, perfil, relógio ou vento.
Sem versão/app/exportação/commit/push solicitados.

## Verificação desta correção

- Red/green: a cena falhou por ausência do contrato MOVE; após a correção,
  sete suítes dirigidas passaram (1.195 checks Godot + 10 testes Python).
- `./scripts/check.sh --quick`:107 suítes, 28.157 checks Godot + 85 testes Python,
  parse aprovado, exit0. `./scripts/check.sh test_matches test_classic_matches`: mais duas suítes,
  13 seeds + 16 mobiles = 29 partidas, zero falhas/exit0. As duas chamadas
  cobrem todas as 109 suítes do harness, com código de produção estável. A captura
  final também passou em compilação separada.
- GPU final: 240 quadros em 1920×1080, esquerda/direita, abertura compacta,
  expansão, soltura e 2 × 30 quadros RGBA idênticos na pausa. Recorte independente
  da barra confirma preenchimento imóvel na pausa e diferente após retomada.
  Fixtures 0/50/100: 2/434/864 pixels ciano, equivalentes aos recortes inclusivos
  nativos 1/201/400 na escala 2,16. 22 PNGs salvos.
- Asset de estágio expandido ausente ou com hash inválido produz pixels
  idênticos ao quadro compacto nativo com seu pivô. Revisão independente
  aprovada, sem P1/P2; sugestão de fallback coberta pela captura.
- Log final GPU: `.tools/move-bar/gpu-debug.log` (exit0, sem erros).
  Tentativas anteriores de captura falharam em input/pausa e não são prova.
  A fixture final reaplica o input por quadro e exige MOVE visível na pausa.
- [Evidência ASM](../move-bar/native-evidence.json),
  [prova de pixels](../move-bar/pixel-proof.json) e
  [manifesto do fonte](../move-bar/verified-source.json).

Cliente Windows não executado; frequência da atualização da UI continua
adaptada ao porte, sem alegação de paridade temporal integral. Áudio mudo na
captura. App/ZIP existentes não foram atualizados. README T1 não movimenta o
ator e suas capturas anteriores não foram regeneradas nesta correção; veja
`docs/move-bar` para a sequência específica.
