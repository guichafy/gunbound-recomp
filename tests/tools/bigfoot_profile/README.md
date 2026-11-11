# Perfil de custo Bigfoot — issue #28

Não faz parte do jogo nem da suíte normal. Com bootstrap/import concluídos:

```sh
python3 tests/tools/bigfoot_profile/prepare.py
Godot --headless --path . --script tests/tools/bigfoot_profile/match.gd -- baseline 81
Godot --headless --path . --script tests/tools/bigfoot_profile/match.gd -- current 81
Godot --path . --rendering-method gl_compatibility --resolution 1920x1080 --disable-vsync --script tests/tools/bigfoot_profile/ui.gd
```

Executar baseline/current em sequência, sem harness/encoding concorrentes.
`prepare.py` lê scripts da base035d8e17 pelos objetos Git e do checkout atual;
cria cópias isoladas sob `.tools/bigfoot-native/profile`. Reescreve somente
caminhos internos e envolve predict/tick/explode/settle/carve/collision_copy
com contadores de tempo. Mesmos assets, seed, RNG e regras; fonte ativa intacta.
Os tempos instrumentados incluem esse overhead; são comparação no mesmo host,
não benchmark portable nem meta de tempo para outros computadores.

A sonda conta candidatos/ticks/turnos/eventos e põe um identificador em cada
shell real depois de fire. Cada shell primário deve explodir no máximo uma
vez. Os snapshots da busca não herdam essa marca; contadores agregam o trabalho
previsto e executado. A partida precisa alcançar finished antes do guard original.

A sonda GPU usa a cena real com CPU Bigfoot, Thor/eletricidade e seed23.
Abertura/pausa/retomada são acionadas programaticamente, não com mouse humano.
Ela compara o modelo durante12quadros de pausa e mede _process e intervalos
reais de render sem vsync. Usa perfil próprio em.tools, nunca o perfil real.

Saídas em.tools/bigfoot-native/profile-{baseline,current}-81.json e
ui-responsiveness.json. Resultados desta sessão preservados em
`docs/bigfoot-native/performance/` e explicados no contratoSDD.
