# Encerramento da partida — REQ-50 / ADR-139

Pedido de 27/10/2026: ao fim do treino, mostrar vencedores e perdedores na
janela de resultado do cliente Thor's Hammer (imagem de referência do
usuário: painéis WIN/LOSE lado a lado, barras A/B, P e G, botão OK).
Substitui o cartão "TREINO CONCLUÍDO" com REVANCHE/Voltar ao menu (REQ-09).

## Fontes

- `GunBound.gme` SHA-256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
- `graphics.xfs` SHA-256 `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
- Ghidra 12.2 headless, JDK 26, work-dir `builds/ghidra-result`;
  extratos em `.tools/result-port/ev2..ev4` (`manifest.json` ok=true).

## Contrato

Coordenadas na tela virtual 800×600 do cliente; o porte desenha ×1,6.
Todo quadro é desenhado em âncora + pivô do IMG (`FUN_004ed6a0` soma
`+0x28/+0x2c` do quadro).

| Comportamento | Fonte | Confiança |
|---|---|---|
| `result_back.img` é o recurso 9001 (0x2329), carregado no loader da batalha | 0x441b01, 0x4df58e | comprovado |
| Quadros: 0 LOSE 373×381 pivô(1,2); 1 WIN 373×383 pivô(1,0); 2 barra A 308×47 pivô(−5,0); 3 barra B 303×47; 4 marcador de evento 44×38 pivô(−22,−19) | IMG | comprovado |
| Painel do time A em (24,48), do time B em (403,48); quadro = 1 se o time venceu (byte 0x62155), senão 0 | `FUN_004c8890` 0x4caa9a, 0x4cac35 | comprovado |
| Linhas do time: y = 151 + 66·n enquanto y ≤ 414 (até 4); ordem dos slots 0..7 presentes no time | `FUN_004c8890` | comprovado |
| Base x da linha: A = 52, B = 431 (0x1af − 379 para A) | `FUN_004d0260` 0x4d0283..0x4d028b | comprovado |
| Barra: quadro 2 (A) ou 3 (B) em (bx, y) | 0x4d0298..0x4d02ca | comprovado |
| Patente: `rank1.img` (recurso 100), quadro = WORD do slot (código + 4), em (bx+41, y+17) | 0x4d02f3..0x4d032a; 0x40f145 | comprovado |
| Guild `"%s[%3d/%3d]"` em (bx+58, y+16), cor RGB565 0xF800, só se houver guild | 0x4d0346..0x4d03a1 | comprovado; inativo no porte |
| Apelido em (bx+58, y+30), cor 0, `font.fnt` meia largura, avanço 6 | 0x4d03b8..0x4d03d5; `FUN_004eb450` | comprovado |
| P: `"%3d"`, só os 3 primeiros caracteres, avanço 9, em (bx+254, y+8); dígito = `numfont` 80+c (valor ≥ 0) ou 90+c (< 0); '−' = 102; espaço pula e avança | 0x4d03fd..0x4d0557 | comprovado |
| Letra P: `numfont` 100 (≥ 0) ou 101 (< 0) em (bx+281, y+8) | 0x4d056c..0x4d05f1 | comprovado |
| G: `"%5d"`, 5 caracteres, avanço 16, em (bx+195, y+26); dígito 103+c (A) ou 114+c (B); '−' 224 (A) / 225 (B) | 0x4d05f1..0x4d0766 | comprovado |
| Letra G: 113 (A) / 124 (B) em (bx+274, y+26) | 0x4d0773..0x4d07d1 | comprovado |
| P lê o objeto 0x5cba0 do slot; G lê 0x5ba80 (o log do chat confirma `%3dP %6dG`) | 0x4d03ee, 0x4d05ff, 0x556720 | comprovado |
| Botão `b_result_confirm` (ID 0x3f8) em (671,441), 103×45; EPA ready 0, mouse 1, push 2, disable 3 | `FUN_004b4100` msg 0x4413 | comprovado |
| A mensagem de fim (0x4413) remove os 8 botões do HUD e cria só o OK | `FUN_004b4100` | comprovado |
| A janela é desenhada direto sobre a batalha, sem escurecer | `FUN_004c8890` | comprovado |
| `resultmode.img` não é referenciado por nenhuma string do PE | busca no PE | comprovado (não usado) |

## Adaptações declaradas

- **Destino do OK:** volta à sala (`show_menu`). O despachante do comando
  0x3f8 não foi localizado de forma conclusiva.
- **Canvas mais baixo:** o porte tem 800×500 virtuais; painéis cabem (até y 431),
  mas o OK (441..486) fica sobre o footer (456). O OK é desenhado acima dele.
- **Valores:** P mostra o XP ganho no porte (o cliente mostra GP); a CPU não
  pontua (0P). G do jogador é `gold_reward`; G da CPU vem do mesmo
  `GoldTracker.player_reward`.
- **CPU:** apelido "CPU" e patente Chick (código 19), pois o treino não tem
  conta para ela.
- **Empate:** sem estado nativo; o byte de vencedor fora de 0/1 resulta em
  LOSE nos dois painéis, que é o que o porte desenha.
- **Inativos:** linhas de guild, marcador de evento (0x6aa660 = 0xFFFF) e o
  log de resultado no chat (flag 0x11d8), que o treino offline não tem.
- **Apelido:** o porte aceita até 20 caracteres; o cliente guarda 12.
- **Tempo de abertura:** mantém a espera de 1,7 s após o evento `finished`;
  no cliente a janela abre com a mensagem do servidor.
- **Falha ao salvar:** a janela nativa não tem esse aviso. O porte desenha
  uma linha discreta abaixo dos painéis só quando o perfil não foi gravado.

## Plano

- [x] Extrair evidência (loader, render, linha, botão) e conferir assets.
- [x] Importador `scripts/import_xfs_result.py` → `assets/xfs/result/catalog.json`.
- [x] `classic_result.gd`: layout puro das operações de desenho.
- [x] `match_overlay.show_result` com a janela nativa e bloqueador transparente.
- [x] Oráculo independente `tests/test_result_screen.gd` e regressões de cena.
- [x] Captura GPU `tests/capture_result_screen.gd` (vitória, derrota, empate).
- [x] Aceite visual do usuário nas capturas (27/10/2026).
- [ ] Cliente Windows não executado; destino nativo do OK pendente.
