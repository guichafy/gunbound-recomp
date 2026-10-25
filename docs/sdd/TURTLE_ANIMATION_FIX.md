# Correção dos tiros do Turtle — 0.20.1

REQ-04/07/19/45, ADR-086. Pedido do usuário: T1, T2 e SS com animação
quebrada. Correção implementada; gates independentes de especificação e
qualidade aprovados. Este registro substitui, para Turtle, as conclusões
incompletas de apresentação/SS da 0.20.0. Baseline anterior preservado em
`.tools/turtle-fix/before/`; fontes originais e C# não foram modificados.

## Causas e correções

1. WaterEffect tem oito colunas de 32 px em 256 px. O renderer amostrava meia
   coluna: agora usa u=fase/8, largura 1/8 e altura 1/16, conforme
   PE 0x4c495b/0x4c4973. Alpha=(255−16*i)/255.
2. Normais independentes abriam frestas nas curvas. Uma seção transversal
   por amostra fornece os mesmos vértices aos segmentos vizinhos. Todo o
   histórico visual é interpolado em uma cópia; a colisão não lê esse desenho.
3. Filhos SS reutilizavam a bolha grande `bullet12p`. O importador agora
   inclui `bullet12c`/EPA em SSChild, com 15 quadros próprios; a seleção usa
   o marcador `child`, sem herdar a abertura do pai.
4. O pai retomava o voo no último quadro change e dividia ao impacto.
   Agora o tick físico 44 inicia change, os dez ticks EPA completam a abertura
   e a transição cria seis filhos e remove o pai, sem dano/cratera/explosão
   no ar. Provas: ctor 0x4ae381, teste 0x4ae3d2, spawner 0x4ae404 e remoção 0x4ae40c.
5. Impacto do pai **normal** compõe flame123+ssflame12
   (0x48e0f9/0x4ae61a..649); pai em change e filhos usam somente flame123
   (filhos 0x432b5c). Eventos e efeitos preservam `child` e `ss_state`.

A pesquisa estática detalhada permanece em
`.tools/battle-execution/turtle-animation-research.md`. O cliente original
não foi executado; a textura WaterEffect já era correta e não foi regenerada.

## Revisão e regressões

A revisão independente encontrou e fechou três P2:

- Impacto exatamente no tick 44 gerava seis filhos antes da abertura.
  `burst` agora exige a sentinela `split`; impacto comum não divide o pai.
- Durante hold, endpoints anteriores faziam o renderer repetir um salto
  de 26,96 px a 20 Hz. Os endpoints visuais agora coincidem com a posição parada.
- Impacto durante change ainda desenhava SSFlame. A camada extra agora exige
  pai normal; o estado atravessa o evento e a cena.

RED inicial: 130 falhas/142 checks antes do reparo; GREEN inicial 146/0.
As regressões de revisão foram reproduzidas em RED 148/1, 157/2 e 158/1;
**suíte final Turtle 158 checks/0 falhas**, reexecutada pelo revisor. Probe
independente adicional: 18 cenários/4628 verificações/0 falhas, T1/T2/SS nos dois
sentidos a 30/60/120 FPS, igualdade real/previsão, geometria interpolada e
histórico imutável. Colisão real no tick 44 e hold foram revalidados isoladamente.
Relatório: `.tools/battle-execution/turtle-animation-review.md`.

## Captura temporal

Editor Godot nativo, com adaptador local Node para
`tests/capture_turtle_projectiles.gd`: SubViewport **1920×1080**, 270 quadros
em 60 FPS (4,5 s), incluindo 30 quadros de pausa. A captura usa Match e
ClassicSprite reais, T1/T2/SS nos dois sentidos. Quadros 090/145/195/209/230
foram inspecionados: faixa contínua e sequência bolha normal→abertura→seis
bolhas menores. Quadros 150 e 179 da pausa têm hash de bytes idêntico. Quadros completos em
`.tools/turtle-fix/gpu-frames/`; vídeo 411 KB, 1920×1080/60 FPS/270 quadros.

[Vídeo temporal](../turtle-projectiles/turtle-shots.mp4) ·
[Faixas](../turtle-projectiles/time-090.png) ·
[Abertura](../turtle-projectiles/time-195.png) ·
[Filhos](../turtle-projectiles/time-230.png).

Esta evidência Full HD é da correção Turtle; não substitui a recaptura da
matriz completa 0.20 nem comprova escuta, mouse manual ou aceite do usuário.

## Limites e fechamento

HUD, carga 3 s, limites de mira e trava SS foram preservados. A captura isolada
de projéteis não é QA completo do HUD/input. Dano, raio, velocidade inicial,
gravidade e dispersão dos filhos conservam a adaptação existente; órbita T2,
colisão refinada, dano/cratera e física especial integral não são anunciados
como paridade nativa. Armor e Boomer conservam suas regras próprias.

**Harness final aprovado: 7432 checks Godot, 16 testes Python e 29 partidas
completas (13 seeds + 16 mobiles), zero falhas; parse de todos os scripts
aprovado.** Log `.tools/turtle-fix/full-check-final.log`. Probe de recursos
na fonte: 154/0, log limpo. A primeira tentativa do harness foi
interrompida por conflito do nome `paused` com SceneTree somente no script de
captura; o nome foi corrigido e a rodada integral reiniciada.

**App/ZIP 0.20.1 reexportados**, exit0; assinatura ad-hoc verificada com
`codesign --verify --deep --strict`. ZIP de 210.315.916 bytes (aproximadamente
201 MiB), CRC e versões 0.20.1 no Info.plist interno conferidos. Smoke PCK
independente em `/tmp`: **170 checks/0 falhas/exit0**; modo packed, `res=` vazio,
`override.cfg=false` e TLS override vazio. Override ausente no ROOT e no PCK.

O único ERROR do smoke é o ambiental `get_system_ca_certificates` do macOS;
não houve SCRIPT ERROR nem leaks. O build registra os erros ambientais de
CA/editor_settings fora da sandbox; não declarar esses logs limpos.
Logs `.tools/turtle-fix/build-macos.log` e `.tools/turtle-fix/pck.log`;
hashes em `.tools/turtle-fix/release-artifacts.json`. Hashes de fonte/QA
permaneceram iguais após o harness; `git diff --check` passou. Pacote 0.20.0
preservado como baseline. Sem commit, push ou publicação nesta correção.
