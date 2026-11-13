# Patente na batalha — issue #43

REQ-19/27/28, ADR-166. Correção de apresentação no treino offline 1×1.
Não cria ranking nem progressão XP→patente. Fonte exclusiva Thor's Hammer.

## Contrato e plano antes do código

- [x] Fixar PE `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
  analisar com Ghidra12.2/JDK26 em banco próprio `/tmp/gunbound-issue43-f29c-ghidra`.
- [x] Conferir consumidores e ABI em ASM, não apenas pseudocódigo.
- [x] Propagar patente do perfil e Chick da CPU no estado de apresentação.
- [x] Desenhar rank2 original em ambos os atores e na lista de turnos.
- [x] Regressão73/0, nomes20caracteres, dois times/ordens e GPU375+375pixels sem divergência.
- [x] Rodada integral401,293s:369parses/119suítes/61.163checks/160Python/29partidas, zero falhas/skips.
- [x] Registrar resultados/limites em TASKS/HANDOFF.
- Integração porPR/rebase autorizada posteriormente pelo usuário; quatro gates obrigatórios, sem bypass. Sem export/release manual.

## Matriz de evidência

| Contrato | Fonte nativa | Estado / aplicação |
|---|---|---|
| rank1=100, rank2=101 | 40f145..40f162 | comprovado; assets existentes |
| Desenho comum dos16mobiles | referências DATA/vtables→462900 | comprovado no PE |
| Âncora da caixa X=mobileX−cameraX+400−41, Y=mobileY−cameraY+270+38 | 462ecb..462fd7 | comprovado; porte fornece posição visual já traduzida pela câmera |
| Sem guilda: rank2 em caixa+(1,7), nome em caixa+(27,9), sombra+(28,10) | 4635be..463608 | comprovado; rank antes do nome |
| Helper sprite: EAX=frame, EDX=recurso, EBX=x, EDI=y | 4eb890..4eb8d0 | comprovado pela passagem a4ed6a0/4eb9c0 |
| Fila: rank2 em(19,y), nome em(47,y+3), passo15px | 4094e8..4095b6 | comprovado; porte mantém passo16/espaçamento/delay existentes |
| Guilda usa rank1 e duas linhas | 46342a..4635bc | comprovado; sem guildas no treino, não implementar esse ramo |
| Patente atribuída do jogador / CPUChick | profile.rank / resultado existente | adaptação offline preservada, independente do XP |
| Fonte/contorno e escala de tela da fila | hud_art.gd | adaptação preservada; não alegar raster integral nativo |

Nome do mundo passa a partir de mobile+(−14,47), em vez de centralizar apenas
texto em mobile+(0,70); rank ocupa25×15 em mobile+(−40,45). Baseline usa a
fonte do porte; o cliente desenha glifos6×12. Nomes20caracteres são extensão
existente do perfil (campo nativo13bytes); ficam completos, com emblema fixo
à esquerda, sem sobreposição com o texto. Cores de time existentes preservadas.

Extratos finais/manifestos serão preservados em `docs/battle-rank/`.
Análise estática e captura Godot não são execução do clienteWindows.

## Validação observada

Regressão inicial RED4checks/3falhas esperadas (patente ausente no estado e
layouts ausentes) → GREEN73/0. GPUCompatibility/M4Pro: duas composições
1920×1080 e uma1280×800, jogadorGM20 e código−4/nome20caracteres, CPUChick19,
fila nas duas ordens. Probe independente compara todos375pixels do emblema
de cada ator, na cena1280×800, com o PNGoriginal: zero divergências; isso
confirma também que o draw real recebeu a patente correta.

Revisão independente sem achados acionáveis: ABI/ASM, posições, códigos,
cache, fluxo de apresentação e capturas. RuffE9/F63/F7/F82 e diff aprovados.
Não houve alteração de regras de combate, perfil, equipamento ou exportação
manual. A versão permanece a do checkout; a CI calcula a versão de release.

Tentativas ambientais anteriores preservadas em`.tools/battle-rank`: gate
de importação no sandbox bloqueado por CA/macOS; primeira rodada fora do
sandbox passou369parses/119suítesGodot/61.163checks/29partidas, mas a faixa
Python não tinha coverage. Uma repetição Python encontrou14erros de setup
por avatar.xfs ausente, sem falhas de assertiva. Preparação definitiva pelo
bootstrap--skip-godot--client-source--no-legacy-sound e venv próprio com as
versões exatas daCI. Override temporário de CA removido antes das rodadas
fora do sandbox; nenhum override está sendo entregue.

### Limites

ClienteWindows inteiro não executado; Ghidra prova estática, não paridade
dinâmica. Fonte/contorno/escala da fila e nomes20caracteres são adaptações
existentes preservadas. GPU usa cenário estático com posições controladas,
sem prova de contato/assentamento no chão. Som/input não foram alterados
nem submetidos a escuta/interação; aceite visual humano pendente.

## Rodada integral definitiva (12/11/2026)

`.tools/ci-venv/bin/python scripts/ci/check.py` → exit0/401,293s,
369scripts compilados,119suítesGodot/61.163checks,160testesPython/0skips,
29partidas, cobertura de automação62%. Inspeção de todos os logsGodot sem
SCRIPT ERROR/ERROR/leaks/recursos em uso. Pythonlocal3.15.2, dependências
exatas daCI; CIremota usa3.13. Manifesto/hash em`docs/battle-rank/validation.json`.
Essa rodada substitui as tentativas ambientais anteriores.

Worktree`/Users/guichafy/.codex/worktrees/f29c/DemoGame`, branch
`codex/battle-rank-issue-43`, basea1556fd949828e25a525c837f1b3274123bcd573.
A orientação posterior do usuário autoriza commit/push/PR e integração desta
primeira entrega na main. Política remota conferida: quatro checks da app
GitHubActions15368, main atualizada, histórico linear, administradores
sujeitos às regras; apenas rebase merge. Link/SHA/resultado remoto são
devolvidos na resposta final desta tarefa. Nenhuma política foi alterada.
