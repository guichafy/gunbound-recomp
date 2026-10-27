# Fundo opaco do footer — REQ-27/28/48 / ADR-136

O usuário apontou buracos/ausência de background no rodapé após a ADR-135.
A posição MOVE estava coberta, mas os testes comparavam PNG com o mesmo
decoder que tornava RGB565 preto transparente. Isso não provava o raster nativo.

Fontes fixadas: PE `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`;
graphics.xfs `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
REA/Hopper foi aberto nessa cópia; evidência completa em
`docs/footer-background/rea-evidence.json`. Endereços são VA, x86.

| Contrato | Fonte | Classe |
|---|---|---|
| Footer play_back[1] em (0,556), antes dos overlays | 406990, ramo 406a38..406a70 | comprovado |
| Tipo1 despacha RLE; outros para blit retangular | 4eb91e..4eb937 | comprovado |
| Tipo0 emite toda scanline RGB565, sem teste de cor zero | 4ebb37..4ebbb2 →4eba80 →4e9130 | comprovado |
| Quadros1/5/6/9/11 são tipo0; preto faz parte do painel | cabeçalhos/payload XFS + consumidor | comprovado |
| play_back RGB565 tipo0 deve ter alpha255; demais recursos preservados | contrato local do importador HUD | derivado |
| Encaixe no canvas mais curto, scheduler, regras de jogo | ADR-134/135 preservadas | adaptação declarada |

Plano:

- [x] Oráculo independente por palavras RGB565, incluindo preto e cobertura.
- [x] Corrigir exclusivamente a importação HUD; não mudar decoder de mobiles/avatares.
- [x] Regerar atlas/catálogo, preservar UID/imports/originais e validar fallback.
- [x] GPU com fundo contrastante, Slice/Drag/carga/MOVE, pausa/retomada.
- [x] Regressões, documentação e manifesto da correção; sem export/commit/push.

Não alegar execução do cliente Windows nem identidade de todo o jogo.

## Prova do consumidor final e validação

O REA localizou também o flush: 406990 marca a camada3. O consumidor
4c9bee..4c9bf5 passa3 e o bufferf22650 para4e93e0. Em4e942f..4e944d o cliente
copia os spans dessa camada com REP MOVSD e REP MOVSB, sem teste de cor.
4e9130 agenda os spans; a cópia final ocorre em4e93e0. As outras chamadas de
flush usam camadas1/2; não confundi-las com a camada do HUD. Evidências em
`docs/footer-background/rea-raster-evidence.json` e `rea-layer-evidence.json`.

Teste novo falhou primeiro em NativeFooter; esperados antigos usavam o mesmo
decoder incorreto. O oráculo agora reconstrói RGBA das palavras brutas para
os quadros RGB565 de play_back, mantendo a referência RLE existente.11 testes
Python passaram; sete suítes dirigidas passaram:1.195 checks Godot +11 Python.
Revisão independente aprovada sem P1/P2. Decoder compartilhado não foi editado.

GPU:480 quadros1920×1080 em Slice/Drag/esquerda/direita,4×30 quadros pausados
idênticos e retomada. Probe nativo800×44 sobre magenta e verde tem RGBA idêntico
às35.200 palavras RGB565 decodificadas: zero pixels transparentes e1.449 pretos
restaurados.35 PNGs salvos, incluindo fallback. Prova em
`docs/footer-background/pixel-proof.json`. Execução do cliente Windows continua
pendente; isso comprova o porte do contrato estático e o render Godot.

Harness completo final `./scripts/check.sh`: **109 suítes,28.157 checks Godot,
86 testes Python e29 partidas, zero falhas, exit0**. Compilação de todos os
scripts/capturas aprovada. Fonte/assets estáveis desde o início da rodada.
README: quatro PNGs FullHD,86 quadros de T1, MP4 1920×1080/30Hz e GIF15Hz.
Logs GPU/README/harness finais sem ERROR/SCRIPT ERROR/leaks; importação do
editor teve apenas a gravação ambiental de editor_settings fora do sandbox.
Manifesto com hashes em `docs/footer-background/verified-source.json`.
Versão0.20.5 e aplicativo exportado anterior mantidos, sem commit/push.
