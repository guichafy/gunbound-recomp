# Gravidade durante tiros — REQ-04/05/08/19/32/42/44/45

## Contrato e investigação (07/11/2026)

Relato: o mobile permanece suspenso depois de perder o piso, até terminar a
rajada. `explode` altera a máscara no voo, mas `settle_actors` só é chamado
por `tick` depois de `resolve_wait` em `PHASE_SETTLE`. A previsão executa
`advance_projectiles`, sem essa resolução final.

A cada tick fixo de combate (20 Hz), depois de projéteis, efeitos e dano
pendente, acomodar os dois atores vivos sobre a máscara atual. O próximo tick
usa as posições novas para colisão. Impactos do mesmo tick conservam a pose
carimbada no início; não acomodar dentro de `explode`, antes de medir dano.
Aplicar a mesma ordem nos ticks sem projéteis (minas/efeitos persistentes).
Manter o término da ação, Gold e resultado nos pontos existentes.

A queda vertical instantânea no modelo, deriva de vento, geometria de apoio e
suavização visual existentes continuam adaptações. Este ajuste de ordem foi
solicitado pelo usuário; não constitui prova de cadência nativa da gravidade.
Emissões pendentes acompanham o deslocamento do dono até o nascimento
(`launch_actor_pos`), uma vez, incluindo endpoints visuais e posição24.8 se
pré-semeada. Velocidade escolhida fica preservada; filhos sem essa referência
e tiros já em voo não são transladados. Política adaptada do treino, sem prova
nova do cliente. Não adicionar física nova, assets, rede, perfil ou exportação.

## Plano antes do código

1. Preparar worktree e referências locais; importar e validar a base.
2. Adicionar `test_actor_gravity`: cratera por projétil real antes de uma
   emissão atrasada, dois impactos sucessivos, ambos atores/16 mobiles,
   suporte estável, queda no vazio, dano sem duplicação e snapshot isolado.
   Executar e observar falhas por posição suspensa no voo.
3. Chamar `settle_actors()` no fim de `advance_projectile_tick` (após
   `LightningCombat.resolve`) e depois dos efeitos nos ticks sem voo.
   Preservar a acomodação final idempotente e o agendamento existente.
4. Revisão: reproduzir também queda do atirador antes de uma emissão
   atrasada; transladar somente a origem ainda não emitida e testar snapshot.
5. Verificar paridade de deltas, contatos posteriores à queda e quadro da
   apresentação/pausa. Executar harness completo com as 29 partidas e
   registrar resultados, limitações e artefatos.

## Revisão focal

- Colisão após cratera usa posição do modelo; interpolação só na view.
- Previsão copia máscara/atores e não altera estado vivo ou recompensas.
- Último impacto e minas fora do voo também perdem suporte imediatamente.
- Queda no vazio não encerra prematuramente os projéteis restantes.
- Apoio estável não deriva com vento nem muda HP; resolução final idempotente.

## Validação

- Base antes da correção: `test_mobile_parity`27/0, `test_boomer`928/0,
  `test_scene`27/0; importação concluída.
- Reprodução inicial:54checks/44falhas (posição suspensa durante o voo);
  após as chamadas de acomodação,54/0. Revisão reproduziu também a emissão
  pendente na origem antiga:65checks/2falhas antes da translação,65/0 depois.
- Regressão final `test_actor_gravity`:68/0; cobre16mobiles, ambos atores,
  duas crateras, último impacto, vazio sem fall duplicado, apoio estável,
  vento Boomer, deltas partidos, snapshot isolado, emissão pendente e tiro
  posterior com colisão/dano reais sem repetição de dano. Revisão independente
  repetiu68/0 e não encontrou novos achados após os ajustes.
- Harness completo: `python3.13 scripts/ci/check.py` (venv local com coverage),
  exit0 em294,481s;100suítes de modelos/cenas,46.113checks,29partidas
  (13seeds+16mobiles),152testes Python/zero skips e329parses sem falhas.
  Captura também passou `--check-only` dirigido. Cobertura62% da automação
  Python; isso não mede cobertura de linhas GDScript.
- Fixtures Mage/Boomer/Armor/Turtle antes mantinham atores suspensos ou
  enterrados. Receberam piso local (`tests/support/actor_platforms.gd`) e
  origem apoiada; as expectativas balísticas e de animação foram preservadas.
  Primeira rodada também usou Python sem coverage; a rodada final acima
  corrigiu o ambiente e não reutiliza aquele resultado parcial.
- GPU: `tests/capture_actor_gravity.gd`,180quadros1920×1080/60Hz, sentidos
  direito/esquerdo, dois impactos dirigidos com cratera real e BattleArt;
  pausa30quadros idênticos e retomada. Alvo y375→421→433 com fase `flight`
  ainda ativa. Inspeção visual dos quadros inicial/intermediário/final;
  vídeo em `.tools/gravity-during-shots/gravity-during-shots.mp4`.
- Evidências locais: `.tools/gravity-during-shots/{red,launch-red,final-harness,
  gpu,capture-parse}.log`, `final-report.json`, `final-python.log`,
  `final-coverage-report.log`, `gpu/frames.json` e180PNGs. `git diff --check`
  aprovado; revisão final sem achados pendentes.

Limites: fixture GPU de impactos dirigidos, sem executar o cliente Windows,
sem escuta/input humano ou aceite visual do usuário. Regras aproximadas da
queda permanecem declaradas; não se afirma paridade integral com o PE.
Versão0.20.5 preservada, sem app/ZIP reexportado, merge, push ou publicação.
Alteração preexistente de `project.godot` no checkout de origem preservada.
