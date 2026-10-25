# Entregas e próximos trabalhos

## ASate/JD/Aduka/Raon 0.20.5 — ADR-094

- [x] Investigar os quatro mobiles com Ghidra/ASM/dados e fixtures independentes.
- [x] Corrigir Ion/filhos, cristais JD, Thor Aduka e tiros/minas Raon.
- [x] Integrar autoria, cópia profunda, fim de efeito/turno e candidatos da CPU.
- [x] Preservar Thunder/Thor anexos e impedir multiplicação por filhos.
- [x] Resolver minas S2 antes do input; SS mantém o turno até detonar.
- [x] EPA, recursos originais e laser Thor aditivo; PCM Ion T1/T2 separado.
- [x] Harness completo11493 checks Godot/29 Python/29 partidas e parse sem falhas.
- [x] App/ZIP0.20.5 assinados, versão/CRC e PCK isolado68/0 conferidos.
- [ ] Executar captura GPU: script pronto, bloqueio FontRegistry/LaunchServices antes do primeiro quadro.
- [ ] Aceite visual do usuário e escuta manual; cliente original não executado.

Plano e limites: SPECIAL_MOBILES_CLASSIC_FIX.md e quatro registros por família.

## Sala inicial 1×1 — REQ-02/09/36, ADR-092

- [x] Trocar o cartão “Preparar treino” pela sala com piloto, máquina e Miramo.
- [x] Menu da partida com apelido, dificuldade e clima; Aceitar grava, Cancelar restaura.
- [x] Mobile em popup próprio; itens no PopupSelectItem; Iniciar num clique.
- [ ] Aceite visual do usuário na sala, no menu da partida e no popup de mobile.
- [x] Botão CPU escolhe o mobile da máquina; o pareamento antigo segue como padrão (ADR-093).
- [ ] Aceite visual da escolha do mobile da CPU.
- [x] Sala desenha o mobile no casco nativo de 60 px (ADR-095).
- [ ] Aceite visual do tamanho do mobile na sala.

## Ghidra na skill de porte — REQ-12/19/44/45, ADR-091

- [x] Adotar Ghidra headless direto e incluir runner/exportador reproduzíveis.
- [x] Validar importação nova, entradas indicadas, dados/vtable e22extratos
      idênticos na reabertura; ausência de função retorna falha explícita.
- [x] Validar5testes do runner e8checks independentes de LUT/seção no Godot;
      suites dirigidas1368/0. Estrutura/links/UI/alias conferidos.
- [x] Aplicar a skill em contexto independente antes e depois da atualização;
      reproduzir/corrigir cleanup de descendentes resistentes ao timeout.
- [x] Revisão para commit local autorizada após pull/merge: cinco testes do
      runner aprovados; override local excluído do versionamento.

Registro: GHIDRA_SKILL_VALIDATION.md. Sem port/runtime/build novo nesta tarefa.

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
