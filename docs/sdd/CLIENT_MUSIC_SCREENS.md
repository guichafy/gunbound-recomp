# Música por tela — REQ-53 / ADR-153

Issue #7 (complementa a #6). 07/11/2026. Lobby, loja, sala e batalha tocam
as faixas que o cliente Thor's Hammer chama em cada tela. Sem mudança de
regras, perfil, itens, agenda de combate, layout ou input.

## Estado anterior

A issue descreve a 0.11: playlist `Theme*` do OpenBound na batalha. Desde a
ADR-133 a batalha já tocava `stage1..6.mp3` do `sound.xfs`, sorteados ao
iniciar e a cada fim de faixa; `Theme*` era só o fallback de recurso nativo
inválido. Lobby, sala e loja ficavam em silêncio (`_clear_front` e
`show_shop` chamavam `stop_music`). A Revanche citada na issue saiu com a
ADR-139: o resultado tem só o OK, que volta à sala.

## Fontes

- `sound.xfs` SHA-256 `081c1b9f…9023`, já importado em `assets/xfs/audio`
  (`CLIENT_ASSETS_AUDIO.md`). A TOC tem 11 MP3: `title`, `logo`, `channel`,
  `ready`, `stage1..6` e `sudden`. Nenhuma faixa de resultado, vitória,
  derrota ou empate.
- `GunBound.gme` SHA-256 `4af6283d…fcde`. Strings de áudio fora de armas:
  `channel.mp3`, `logo.mp3`, `logo2.mp3`, `title.mp3`, `ready.mp3`,
  `stage%d.mp3`, `sudden.mp3` e efeitos `.xes` de botão/turno/gold. Nenhum
  nome de áudio de resultado.
- Ghidra 12.2 headless, banco copiado em `builds/ghidra-music`; referências
  de dados em `builds/music-ev1` e funções em `builds/music-ev2` (`ok=true`).
  O restante saiu de `objdump` sobre o mesmo PE.

## Evidência

O tocador de música é `0x4eea30` (nome em EDI, um argumento empilhado).
Ele sai sem tocar se a música estiver desligada (`0x79354a`), compara o nome
com o atual em `0x793568` e retorna sem reiniciar quando é o mesmo. Senão
para o canal atual e toca o novo. Há 24 chamadas diretas:

| Chamada | Tela (strings do mesmo trecho) | Faixa | Argumento |
|---|---|---|---|
| `0x4292cc` | lobby `gamelist_back.img`, `b_gamelist_*` | `channel.mp3` | 1 |
| `0x447c32` | loja `store_back.img`, `b_store_*` | `channel.mp3` | 1 |
| `0x4e17ac` | seleção de servidor `b_server_*` | `channel.mp3` | 1 |
| `0x4d734f` | sala `b_ready_character` | `ready.mp3` | 1 |
| `0x4bb7f8` / `0x4bb822` | init da batalha `FUN_004bb730` | `stage%d.mp3` | 1 |
| `0x4b87e0`…`0x4ba3a2` (14) | religar BGM dentro da batalha: põe `0x79354a`, depois volume `0x4eeb10` | `stage%d.mp3` | 1 |
| `0x4b76e7` | morte súbita | `sudden.mp3` | 1 |
| `0x4432a6` / `0x443416` | logos de abertura | `logo2.mp3` / `logo.mp3` | 0 |
| `0x4e5396` | título | `title.mp3` | 1 |

O argumento 1 em todas as músicas de tela e 0 nos logos é lido como "repetir";
é dedução pelo padrão de uso, não leitura do backend de áudio.

**Índice da batalha.** `0x4d4004…0x4d4038` grava o byte do mapa recebido em
`[jogo+0x475c4]` e regrava `byte % 11` (`cdq; idiv 11`). O `stage.dat` tem os
mapas A em 0..10 e os B em 11..21, então o campo é o mapa sem lado.
`FUN_004bb730` formata `stage%d.mp3` com esse campo; se `0x4eea30` falhar
(arquivo ausente), formata `rand() % 6 + 1`. Miramo Town é o registro 1
(A) e 12 (B): `stage1.mp3`. Cave (0) e os mapas 7..10 não têm faixa própria
e caem no sorteio.

**Loading.** A rotina `0x4430c0` lê o mesmo campo para a prévia, mas não
chama música. A faixa da sala segue até a init da batalha.

**Resultado.** Nenhum consumidor de música foi encontrado no caminho do
resultado: as 24 chamadas acima estão classificadas e nenhuma pertence ao fim
de partida. As chamadas de `0x4eeae0` (parar canal) usam índices de laços de
efeito (`+0xb0a4`, `+0x6a64b4`), não o canal da música. A faixa de batalha
segue sob a janela até o OK, que volta à sala e chama `ready.mp3`. Vitória,
derrota e empate não têm áudio separado. Isso é ausência de evidência no
PE analisado, não prova de que nenhum código indireto toque algo.

## Contrato do porte

| Tela | Faixa pedida |
|---|---|
| Lobby (`show_lobby`) | `channel` |
| Loja (`show_shop`) | `channel`; vindo do lobby não reinicia |
| Sala (`show_menu`), popups, grade, itens | `ready` |
| Loading (`begin_loading`) | segue `ready` |
| Batalha (`start_match`) | `stage%d` de `client_stage % 11` do mapa; Miramo → `stage1` |
| Resultado (`finished`, janela, OK pendente) | segue a faixa da batalha |
| OK do resultado, QUIT da batalha | `ready` (volta à sala) |

- Pedir a faixa atual não reinicia (`0x4eea30`).
- Fim da faixa recomeça a mesma do início. Em Godot isso é `finished → play()`
  sobre o mesmo stream; o MP3 importado continua sem `loop`, como exige a
  validação de `client_audio.gd`.
- O pedido fica gravado mesmo com BGM 0 ou mudo; `music_request` é o que as
  suítes conferem. BGM 0 ou mudo não tocam nada; voltar a ter volume recomeça
  a faixa pedida, como o religar do cliente.
- Mapa sem faixa (`stage0`, `stage7..10`): sorteio 1..6 uma vez, depois o
  mesmo arquivo repete.
- Fallback: `stage*` inválido usa o `Theme*` de mesmo índice (ADR-133,
  declarado). `channel` e `ready` não têm fallback: sem recurso válido, silêncio.

## Adaptações e limites

- O efeito sintetizado `result` no fim da partida continua como adaptação
  (ADR-133), sem relação com música.
- Sem morte súbita, título, logos, servidor ou rede: `sudden`, `title`,
  `logo*` continuam sem consumidor.
- O backend do cliente não foi executado; repetição, transição entre faixas e
  volume relativo não foram ouvidos no Windows. Escuta no porte pendente.
