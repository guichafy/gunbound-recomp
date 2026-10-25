# Hand-off para o Codex — fidelidade da batalha (vento, tiros, arte/áudio)

## Retomada atual0.20 —24/10/2026

Esta investigação foi executada nas tarefas 1–7; tarefa 8 produziu pesquisa
rastreadora48 tiros e planos futuros. Estado implementado, gates e limites em
[BATTLE_FIDELITY_0_20.md](BATTLE_FIDELITY_0_20.md) e [HANDOFF.md](HANDOFF.md).
Física comum original/carga 3 s/mínimo nativo, Boomer, minas/fábrica, WaterEffect
e cronologia audiovisual estão integrados. Revisões e harness final aprovados:
7287 checks, 16 testes Python e29 partidas, sem falhas. Composição GPU inspecionada
no editor (3004×1805); recaptura Full HD e escuta pendentes. App/ZIP 0.20.0
assinados; PCK isolado160 checks/0 falhas, com erro ambiental de CA registrado. Não confundir pesquisa de famílias
com porte nativo completo nem usar "pendente" histórico para refazer a 0.20.

## Revisão anterior à implementação no HEAD c796154 —24/10/2026 (histórico)

**Decisão posterior do usuário:** seguir física original, carga de 3 s e
força mínima original (ADR-084). Escopo aprovado; implementação pendente.
As perguntas sobre essas escolhas no histórico abaixo já foram respondidas.

Análise retomada e plano em [BATTLE_FIDELITY_PLAN.md](BATTLE_FIDELITY_PLAN.md).
O restante deste documento preserva a investigação inicial; em caso de conflito,
usar as correções e o grau de confiança da revisão:

- Roster commitado em `6038d0a`; HEAD `c796154` trata do brilho Great Devil,
  sem mudança no laço de combate. IDs 14–16 = Dragon/Knight/Aduka.
- Recuperados 511 arquivos do temporário em
  `.tools/battle-re/recovered-2026-10-24/`, com manifesto SHA-256. Há um
  `re-tiros.md` parcial útil: Boomer tem curva/sustentação e S2 com quatro
  spawns. Não é necessário refazer essa pesquisa do zero.
- Reproduzidos raio 0 das minas Raon e perda de parâmetros Lightning.
  Também confirmada a hipótese de autoria: mina troca `shot_actor` no voo
  real e não avança na previsão. Corrigir ambos no primeiro pacote.
- JD/cristal e Aduka S2/SS ficam na pesquisa: não inventar dano nem usar
  a antiga identificação J.Frog para decidir sua mecânica.
- Vento atual tem efeito mensurável; física original aprovada na ADR-084,
  substituindo parcialmente ADR-076, ainda sem porte. Corrigir os cabeçalhos dos relatórios
  antes de usar gravidade/velocidade dos três últimos registros.
- Achado posterior do usuário: Turtle T1 aparenta Armor T1. Confirmado que
  PNGs e entradas `bullet12n.img`/`bullet1n.img` do XFS são idênticos. O C#
  adiciona rastro próprio (`HelicoidalTrace`), ausente no renderer clássico
  atual. Investigar composição Bullet12 na tarefa 4; não substituir a bala
  arbitrariamente nem classificar a cópia como causa comprovada.
- Validação dirigida: 2268 checks/zero falhas de assertiva, mas harness
  retorna 4 por `get_system_ca_certificates` do Godot no ambiente atual;
  dois testes Python passaram. Sem suíte completa/partidas/GPU/build novos.

Nenhum código de produto alterado nesta revisão. O plano define a sequência
e as decisões ainda necessárias; não representa execução concluída.

## Investigação inicial (histórico)

Data: 24/10/2026. Estado: **investigação feita em parte, nenhum código alterado**.
Base: árvore de trabalho 0.19.0 **sem commit** (roster dos 16 mobiles, feito por outra
sessão já encerrada). Não descarte esses arquivos modificados.

## Pedido do usuário

"Corrigir o modo batalha com os Mobiles e o Vento" seguindo o GunBound original
(jglim/gunbound-launcher e jglim/gunbound-server), por engenharia reversa do cliente.
Bugs relatados:
1. O vento não afeta os tiros como deveria. Exemplo: no Boomer, a mudança de vento não alterou o projétil.
2. Mobiles sem T2/SS próprios. Exemplo: o T2 do Boomer é igual ao T1.
3. Animações de tiro fora de sincronia com o áudio, e animações trocadas entre mobiles.

"Na dúvida, me acione": pergunte ao usuário antes de qualquer decisão em aberto, em português.

## Evidências (locais, ignoradas pelo Git)

`.tools/battle-re/`:
- `CONTEXT.md`: contexto, regras e mapa de tipos usado pelos sub-agentes.
- `godot-mapa.md` + `godot-mapa/*.gd|out`: mapa do código e probes headless de vento, paridade e especiais. **Completo.**
- `re-fisica.md`: balística e vento do `GunBound.gme`. **Completo.**
- `re-especiais.md`, `arte-audio.md`: **parciais**, porque os agentes foram interrompidos. Os brutos da sessão ficaram em
  `/private/tmp/claude-501/-Users-guichafy-Workspaces-DemoGame/647ae7d0-042d-4b98-9131-c1ebdb83caef/scratchpad/re/`
  (podem sumir): contact.png, sound_toc, graphics_toc, tank_epa.json e wav extraídos.
- `re-tiros`: **não concluído**. Precisa ser refeito; ver a pendência P2.

Binário: `~/Workspaces/GunboundClassic/gunbound-launcher/TestClient/GunBound.gme` (PE x86).
`sound.xfs` fica na mesma pasta. Análise só estática: nunca execute `.gme` ou `.exe`. O Rizin do
REA não está instalado; o agente usou `/usr/bin/objdump` com um parser de PE próprio. GunBound-Decomp
(colemancda) serve só como índice. **Armadilha:** a numeração dos parâmetros de `SpawnPrimaryShot`
(0x42bbb0) está deslocada em um: o argumento 3 é o tipo, o 8 é o ângulo e o 9 é a força.

Tipos do cliente (gameserver.py:1200): 0 Armor, 1 Mage, 2 Nak, 3 Trico, 4 Bigfoot, 5 Boomer,
6 Raon, 7 Lightning, 8 JD, 9 ASate, 10 Ice, 11 Turtle, 12 Grub, 13 Aduka, 14 Kalsiddon, 15 JFrog.
Arte e balas usam o índice tipo+1 (`tankN`, `bulletN`). Os IDs no Godot vão de 1 a 16, na ordem do `classic_mobiles.gd`.

## Achados comprovados

### Vento e balística (re-fisica, godot-mapa)
- A fiação do Godot está correta, e a previsão da CPU é igual ao tiro real (18 combinações testadas).
  O ângulo 0° empurra para +x e a bússola concorda. O Change Wind sincroniza o vento.
- **Godot hoje:** gravidade 196, velocidade de força×100/14 (714 px/s para todos), vento de 0 a 34
  multiplicado por 1,2 (máximo 40,8 px/s², 0,208 da gravidade), integração exata em 120 Hz.
- **Original** (comprovado no binário):
  - Euler a 20 Hz, com ponto fixo de 8 bits. A ordem do passo é `pos += v`, depois a colisão, depois `v += a`.
  - As acelerações são congeladas no disparo.
  - Gravidade = 4·f[40] px/s²: 392 em geral; Mage, Lightning e Aduka têm 360; JFrog 376.
  - Força do vento de 0 a 26 (`rand()%27`). Aceleração 4·int(W·cosφ) em x e −4·int(W·sinφ) em y (a conta trunca).
    O ângulo é anti-horário, com 90 = para cima. Na tela: `φ_tela = (360−φ)%360`.
  - **Não há fator de vento por mobile no tiro comum.** O Boomer usa o spawner comum.
  - Velocidade máxima = 20·f[25] px/s, por mobile: Boomer 700 (f25 35), Bigfoot 840, Mage 900, JD/Ice/Grub/Aduka 1000.
    A carga enche em 3 s.
  - Inclinação: θ = mira + inclinação; quando o mobile está virado para a esquerda, 180 − (mira + inclinação).
  - O vento fica constante no turno. Oscila de −1 a +1 por turno (tabela 0x56d440) quando o efeito de vento está ligado.
    O evento de vento gira φ por um delta de −128 a +179. O Change Wind faz φ += 180.
- Conclusão: o original tem só ~1,3× mais vento em relação à gravidade (1,67× para o mesmo número do HUD).
  Porém o voo é cerca de 2× mais rápido e a velocidade varia por mobile. A queixa do usuário
  provavelmente mistura magnitude com a falta de comportamento próprio (P2).
- O C# integra sem o ½ e roda a 0,9× do tempo real, ou seja, 1,62× o Godot. O BATTLE_RULES_AUDIT não registra isso.

### Bugs concretos no Godot (godot-mapa, comprovados por probe)
1. **Raon S2/SS não causam dano.** `classic_flight.gd:105` lê `blast_radius`, que não existe, e cai em `extra_radius`, que vale 0.
   O teste `test_classic_mobiles.gd:57/119` injeta o raio à mão e por isso não pega o erro.
2. **Lightning:** `ShellState.create` (shell_state.gd) é lista branca e descarta `bolt_extra`, `bolt_extra_radius`,
   `bolt_angles` e `bolt_reach`. O S2 sai com 1 raio em vez de 4, e o choque extra fica em 0. O teste (l.68) chama `bolts` direto.
3. **Cristal do JD inerte:** o filho é montado à mão em `classic_flight.gd:94-102`, com dano e raio 0. O SS do JD tem dano 0.
4. **J.Frog S2/SS** com dano e raio 0, sem cratera. Confirmar no binário: o poder vem 0 na tabela [57..82].
5. **Boomer S1, S2 e SS são o mesmo projétil:** mesma velocidade, impacto, bala e som. Só mudam dano, raio e custo.
   Também são projétil comum: A.Sate, Kalsiddon, Grub S1/S2, Aduka S1/S2, JD S1, J.Frog S1, Ice S1/SS,
   Armor S1/S2, Trico S1, Turtle S1 (tabela no §1 de godot-mapa.md).
6. **Ângulo cortado em 85°** em `combat.gd:38`: os 86–90° do Boomer não existem. A CPU só busca de 15 a 80° (`cpu_planner.gd:35`).
7. **Som e animação:** os 13 clássicos lançam o projétil e tocam o som no quadro 0 (`classic_mobiles.gd:103/112`,
   `game.gd:410-419`), com recuo fixo de 1,16 s (`mobile_looks.gd:8`). O C# usa `SpawnTime` por arma:
   Armor S2 0,6 e SS 0,7; Ice 0,7/0,2/0,7; Trico 0,7/0,7/0,5; Raon 0,7; Lightning S2 0,2.
   Os recuos de 25 quadros a 19 fps (1,32 s) são cortados.
8. **Áudio:**
   - O Raon está mudo: `import_classic_mobiles.py:31` usa o prefixo "Raon", mas os arquivos são `RaonLauncher*`.
   - O Kalsiddon não tem áudio, e o J.Frog não tem som de tiro.
   - Sons repetidos entre mobiles no pacote C#: tiro do JD = Teleport; explosão do Aduka = Mage/A.Sate.
   - Fonte correta: o `sound.xfs` original (o agente arte-audio começou a extrair: sound_toc, wav).
9. **Arte:**
   - Em vários tiros, o "corpo" da bala é a camada de brilho desenhada 2×: JD S1/S2, A.Sate S1/S2, Ice S1/S2,
     Kalsiddon S1/S2, Lightning SS e J.Frog S2/SS.
   - O Aduka S1 não tem folha de bala, e o Kalsiddon não tem explosão.
   - Conferir as trocas reais com a folha de contato (P3).
10. **Risco (hipótese):** a mina rastejante do Raon SS explode fora da previsão. Ao explodir, ela sobrescreve `shot_actor`
    (`classic_flight.gd:142`, `match.gd:375`).
11. Código morto: `crystal_damage`/`crystal_radius` (shell_state.gd:25-26) e a chave `flight` sobrescrita
    (`classic_mobiles.gd:110`). Os filhos de burst e cristal não passam por `ShellState`.

## Pendências, em ordem

- **P0. Perguntar ao usuário (bloqueia a física):** adotar a balística original (g = 4·f40, velocidade 20·f25 por mobile,
  vento 0–26 × 4 truncado, Euler a 20 Hz ou equivalente) substitui a "balística do C#" do ADR-076. Isso muda a mira, a CPU,
  as seeds 81–93 e o golden master (`.tools/golden/`). Alternativas: (a) porte fiel; (b) só escalar o vento e a gravidade;
  (c) manter. Recomendação: (a), com um ADR novo.
- **P1. Corrigir os bugs 1–4, 6, 8 (prefixo do Raon) e 11 já.** Não dependem de decisão. Faça os filhos passarem por
  `ShellState` e escreva testes pelo caminho real (`fire` + voo), sem injetar campos à mão.
- **P2. Refazer a engenharia reversa dos tiros sem classe**, começando pelo Boomer (Bullet6: o bumerangue do original curva e volta?),
  depois A.Sate (Bullet10, `SpawnShot_Type9`), Kalsiddon (15), J.Frog (16), Grub (13), JD S1 (9) e Aduka (14).
  Para cada um: endereços Spawn/Simulate/Detonate, trajetória, número de projéteis, tempos, vento, sons e o momento em que tocam.
  Também conferir os especiais vindos do C# (Armor, Trico, Raon, Lightning, Ice, Turtle) contra o binário (re-especiais parcial).
- **P3. Arte e áudio:** montar a tabela ID → `tankN`/`bulletN`/`ssflameN`/sons do `sound.xfs` → o que está em
  `assets/openbound/<kind>/`. Gerar uma folha de contato. Trocar os sons do pacote C# pelos originais quando o C# não tiver o mobile.
  Conferir com o usuário qualquer divergência.
- **P4. Sincronizar som e animação:** usar um tempo de spawn por arma (C#, ou o momento lido no `.epa` e no binário)
  e a duração do recuo pela contagem de quadros do `.epa`.
- **P5. SDD:** plano em `docs/sdd/` antes do código, ligado a REQ-45, REQ-05/06 e REQ-19. ADR novo se substituir o 076.
  Atualizar SPEC, TASKS e HANDOFF. Criar uma suíte de vento por mobile e de correspondência ID → arte/som.
  Mudança de combate exige `./scripts/check.sh` completo e as partidas completas.

## Ponto de extensão para tiro novo (manter tiro real = previsão)

1. Catálogo em `classic_mobiles.gd`.
2. `ShellState.create` (lista branca).
3. Emissão e `ClassicFlight.prepare`.
4. Laço único em `match.gd:395-479`.
5. `WeatherContact`.
6. `explode`, `plant_mine`, `burst`.
7. `FlightSnapshot.capture`.
8. `cpu_planner.gd`.
9. `ItemEffects.modify_shells`.
10. Apresentação: `projectile_art`, `classic_sprite`, `play_mobile_shot`, `MobileLooks`.
11. Teste de paridade por arma (molde: `.tools/battle-re/godot-mapa/parity_probe.gd`).
