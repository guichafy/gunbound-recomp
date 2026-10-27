# Áudio do cliente — REQ-48 / ADR-133

27/10/2026. Substituição de música ativa e sinal de turno pelo cliente Thor’s
Hammer. Sem alteração de regras, perfil, itens, agenda de combate ou roster.

## Fontes e importação

- Fonte somente leitura: `../GunboundClassic/gunbound-launcher/TestClient/sound.xfs`.
  Repositório `jglim/gunbound-launcher`, commit
  `2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1`.
- SHA-256 do XFS:
  `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023`.
- PE analisado: `.tools/mobile-animation-port/GunBound.gme`, SHA-256
  `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
- `scripts/import_xfs_audio.py` usa o leitor XFS existente, recusa outra
  identidade antes de gravar e extrai as **96 entradas: 11 MP3 e 85 XES**.
  O inventário preliminar dizia 10/86; a TOC real corrige essa contagem.
- XES: 16 bytes `<HHIIHH>` = PCM formato1, estéreo, 22050Hz, 88200bytes/s,
  bloco4, 16bits; os bytes seguintes são amostras intercaladas. Não pular18
  bytes: isso perderia meia amostra estéreo e alteraria todo o alinhamento.
  Importador acrescenta somente o contêiner RIFF/WAVE. MP3 é cópia exata.
- Destino: `assets/xfs/audio/`. `catalog.json` contém cada entrada, offset,
  tamanho/hash XFS, arquivo de destino, tamanho/hash do arquivo e hash PCM.
  Este é o inventário completo por existência e proveniência, incluindo
  recursos extraídos que não ganharam consumidor ativo.
- `.wav.import`: compressão0, sem normalização, trim, redução de bits ou
  conversão mono. O padrão QOA do Godot muda PCM; portanto não serve aqui.
  Importador preserva UIDs existentes e força compressão0. Não apaga originais.

Regenerar: `python3 scripts/import_xfs_audio.py`. Em outro checkout, passar
`--source /caminho/para/sound.xfs`, depois importar pelo editor Godot.
O export precisa incluir `assets/xfs/audio/catalog.json`.

## Consumidores e confiança

| Consumidor | Recurso do cliente / existência | Resultado e classificação |
|---|---|---|
| `scripts/sound.gd:79` `next_song`, `:88` `music_stream` | `stage1.mp3`…`stage6.mp3`, todos presentes | **Cliente**: seis MP3 exatos. Agenda aleatória ao iniciar batalha e após `finished` mantém a adaptação offline existente. Não é prova da sequência nativa. |
| `scripts/sound.gd:96` `play_turn`, chamado por `scripts/game.gd:564` | `turn2.xes` local / `turn.xes` outro ator, ambos presentes | **Comprovado** no ASM0x4ce1da…0x4ce1ee: compara ID do ator `[EBX+0x10a0]` ao ID local; igualdade escolhe0x556764 (`turn2`), desigualdade0x556758 (`turn`), chama0x4ee9b0. Pitch1. |
| `scripts/hud_art.gd:92` `clock_sound` / `:266` `tick` | `turnwa.xes` presente | **Pendente de equivalência de evento**. PE usa como aviso condicional0x462469 e durante espera do carregamento0x4dfad9 (`contador %20==0`); não comprova o relógio herdado a cada segundo com pitch crescente. `ClockSecond.mp3` permanece adaptação declarada. |
| `scripts/item_art.gd:52` `shoot_sound` / `:53` `blast_sound` | `itemblast.xes` solicitado pelo PE, **ausente** no XFS; não há `itemfire.xes` | **Lacuna**.0x4317b0 configura `itemflame` e copia `itemblast.xes` para o campo de áudio+0x3813 (0x431d30). Não substituir por `bombblast`/`jblast` por semelhança. `ShootTeleport/BlastTeleport.mp3` permanecem declarados. |
| `scripts/weather_art.gd:122` raio | PE pede `lightningblast.xes` (0x553c44), **ausente**; XFS contém `lightingblast.xes` (sem `n`) | **Lacuna de identidade**.0x434fc0 associa `lightningflame` ao nome exato do PE. Não se cria alias silencioso entre nomes diferentes. |
| `scripts/weather_art.gd:125` espelho / `:128` vento | `4moon.xes`, `reflect.xes`, `light-dem.xes` presentes | **Pendente de evento**.0x4cee30 constrói `%dmoon.xes` na troca de clima; não basta para atribuir `4moon` à transição de vento da adaptação. Presença de `reflect`/`light-dem` não comprova o disparador de espelho/raio. Sons herdados preservados como lacuna. |
| `scripts/weather_art.gd:85` / `:118` Thor nativo | `22blast.xes` presente | Já portado antes desta mudança pelo consumidor de Aduka/Thor; não remapear o evento só por catálogo novo. |
| `scripts/sound.gd:109` `synthesize` fire/explosion/result | Nenhuma equivalência genérica comprovada | **Adaptação mantida** como fallback; os sons próprios por arma já são escolhidos pelos consumidores de mobiles. Não usar `gold.xes` como resultado só pelo nome. Synth `turn` só é fallback de recurso nativo ausente/inválido. |
| Sem consumidor novo | `title/logo/channel/ready/sudden.mp3` e demais85 XES | **Extraídos/preservados**. Sem novas telas, rede ou sudden-death. `sudden` não entra na lista aleatória de batalha. |

`stage*.mp3` não é alegado equivalente byte a byte aos antigos `Theme*.mp3`:
são músicas diferentes. `music_stream` prefere o recurso do cliente validado;
a rota herdada só é fallback explícito quando o nativo faltar ou falhar a
validação. A correspondência de fallback por índice serve à compatibilidade,
não significa equivalência entre canções.

`client_audio.gd` valida no primeiro carregamento o conteúdo efetivamente
importado pelo Godot: hash MP3 exato ou PCM16 estéreo/22050Hz/hash exato, sem
loop; falha retorna `null` para o consumidor aplicar o fallback declarado.
Não basta o arquivo existir. Nenhum arquivo antigo foi removido.

## Evidência estática

Ghidra12.2 / JDK26; banco isolado `builds/client-audio-rea`. Exportação
`.tools/client-assets/audio-01-consumers` (`run.json` e `manifest.json` com
`ok=true`) cobre0x4ccd10 (turno),0x4317b0 (item),0x4cee30 (clima), dados e ASM.
`.tools/client-assets/audio-03-effects-proven` tem os dois manifestos
`ok=true`, cobre0x461ca0,0x4dcbe0,0x434fc0,0x434ac0,0x434160,0x4337f0,
0x4317b0 e strings0x553c44/68/90/b8.

A consulta intermediária `audio-02-effects` contém um seletor0x4b91f6 sem
função reconhecida; `ok=false`, não é usada como aprovação. Os seletores
comprovados foram repetidos em `audio-03-effects-proven`. Ausência de uma
função na análise não comprova ausência de código nativo.

## Verificação observada

- `python3 tests/test_client_audio_source.py`:5 testes,0 falhas; compara todas
  as96 entradas diretamente à fonte, incluindo PCM após os16 bytes, hashes,
  parâmetros WAV, rejeição de fonte/formato inválido e regeneração exata.
- `Godot --headless --script tests/test_client_audio.gd`:223 checks,0 falhas;
  carrega os96 recursos importados, confere hashes e duração, corrompe fixture
  PCM para testar rejeição/fallback, valida os dois sons de turno, mute,
  sliders, iniciar/parar música e transição `finished`.
- `test_hud.gd`:443 checks,0 falhas após ajustar a verificação da lista de
  música para consultar o mesmo resolvedor nativo do runtime.
- Última execução áudio com `--verbose` e caminho absoluto de log: sem
  `SCRIPT ERROR`, leaks ou recursos pendentes. O teste aguarda a liberação
  do servidor de áudio e retorna dos cenários antes de encerrar a árvore.
- Importação do editor: sem erros de script; erros ambientais conhecidos de
  certificado/editor_settings ocorreram sob sandbox. Warning anterior de
  evento de input repetido permanece na suíte HUD, fora desta mudança.
- Escuta humana, comparação auditiva com o cliente em execução e PCK/app
  reexportados **não validados nesta etapa**. Teste headless comprova payload,
  seleção e controle de playback; não comprova percepção auditiva.
