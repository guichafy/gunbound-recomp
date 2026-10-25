# Entregas e próximos trabalhos

## Avaliação Ghidra — REQ-12/19/44/45

- [x] Testar instalação12.2/Java25 no PE local, com hash preservado.
- [x] Exportar8rotinas de tiros/render Mage após indicar4entradas conhecidas;
      reabrir projeto e conferir24extratos idênticos.
- [x] Comparar cobertura ASM com extratos Hopper e verificar política do REA:
      6.7.0 aceita12.1.x, rejeita12.2; CLI direta funciona.
- [x] Registrar comandos, ajustes de cache/projeto e limites em GHIDRA_EVALUATION.md.
- [ ] Integração MCP com12.2 depende de conector compatível; configuração global preservada.

## Bigfoot/Mage originais 0.20.3 — REQ-12/19/20/45

- [x] Extrair tank2/tank5, EPA, RiderPivot, tiros/luzes/impactos em original/.
- [x] Ativar ClassicSprite e composição Mage original, escala nativa, miras/auras originais.
- [x] Preservar HD anterior, avatares/equipamentos, regras, IDs e perfil.
- [x] Oráculo de pixels/hotspots; regressão ativa 39/0; harness 8059 checks,
      17 testes Python, 29 partidas e parse aprovados.
- [x] Galeria GPU 1920×1080/210 quadros/60 Hz; pausa 30 quadros idênticos.
- [x] App/ZIP 0.20.3, assinatura/CRC/versão e PCK isolado 44/0/exit0.
- [ ] Captura específica menu/loja/arena (UI timeout); galeria e suites concluídas.
- [ ] Aceite visual do usuário; escuta e mouse manual.

Ver ORIGINAL_MAGE_BIGFOOT.md e ADR-089; composição dos lasers Mage permanece adaptação.

## Catálogo clássico de avatares (REQ-46, ADR-089)

- [x] Conferir `avatar.xfs` com o TestClient do gunbound-launcher (mesmo SHA-256, versão 280, 562 registros).
- [x] Índice `classic.json` com slot, preços, status e texto CP949; nenhuma peça removida.
- [x] WORD/DWORD do gunbound-server: bit 15 masculino, slot corpo/cabeça/olho/bandeira, conjunto do `amigos` e padrões `/gender`.
- [x] Love Cupid (id 143) e `ff.dat` vazio permanecem fora do catálogo comprável.
- [x] Chaves e categoria da loja preservadas para equipamento já salvo.
- [x] `test_xfs_import.py` (12) e `test_xfs_catalog.gd` (3816 checks, zero falhas).
- [x] Regressão de loja/perfil/atributos/HD: 2178 checks, zero falhas.
- [x] No merge com a `main`, REQ-45/ADR-082 permanecem do roster e do chifre; este catálogo usa REQ-46/ADR-089.
- [ ] Usuário validar na loja as descrições com reticência e o nome coreano do concurso.
- [ ] App não reexportado nesta entrega.
