# Hand-off — Brisa de Aço 0.2.0

## Estado atual: refinamento 0.2 entregue

Em 2026-10-11, após `c530e23`, o usuário solicitou melhorias de mecânica,
animações e design a partir de três vídeos e do fork Chafy-Studio/_OpenBound.
Pesquisa registrada em `GUNBOUND_REFERENCES.md`; design/execução em
`REFINEMENT_0_2.md`. O usuário aprovou com “implementa”. Versão 0.2.0 implementada,
testada, revisada e reexportada; próxima etapa é feedback funcional do usuário.

O pacote principal de sprites não está no fork. Nenhum código/asset do OpenBound
foi incorporado; a proposta utiliza nossa arte original e adapta comportamentos.
Aplicativo e ZIP locais agora são 0.2.0. A pesquisa está em `.tools/`, fora do Git.

Mudanças: console azul metálico, armas 1/2/SS, força graduada e marcador anterior,
fila prevista, bússola, movimento que vira, apoio inclinado afetando mira e
auto-disparo a 100%. `battle_art.gd` cuida de repouso/movimento/carga/recuo/dano/
destruição e clarão/detritos/fumaça. Animações por código sobre PNGs originais.
Pausa cancela carga sem atirar e congela animação. Perfil e nome do app preservados.

Verificação desta versão: 40 + 28 modelos, 13 + 21 cena = **102**, zero falhas;
seis partidas seeds 81–86 com **24, 10, 10, 17, 6 e 7 tiros**, zero falhas.
Revisão independente encontrou sobreposição de vida após cratera, corrigida com
RED→GREEN. A fila espera a arma da CPU e muda de posição para proteger a vida.
Build Universal 0.2.0, assinatura profunda/estrita válida, executável independente
headless encerrou com código 0. Capturas GPU atualizadas, incluindo `charge.png`.
Não foi realizada validação manual completa de mouse; o roteiro continua pendente.

Comandos adicionais da versão atual, além dos três do baseline abaixo:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement_scene.gd
```

Commits desta entrega são obtidos em `git log`; nenhum push/remoto foi criado.

## Histórico do baseline 0.1 (preservado)

Atualizado em 2026-10-11. Protótipo entregue; aguardando feedback funcional do
usuário. Esta sessão acrescenta SDD e o primeiro snapshot Git, sem mudar o jogo.

## Retomar em uma nova sessão

1. Ler este documento, `SPEC.md`, `DESIGN.md`, `TASKS.md` e `DECISIONS.md`.
2. Conferir `git status`, `git log -5 --oneline` e a solicitação atual do usuário.
3. Consultar requisitos `REQ-*` antes de mudar comportamento; ler o código afetado.
4. Priorizar feedback funcional. Sem nova solicitação, não começar o roadmap.
5. Atualizar especificação, tarefas, decisões e este hand-off ao concluir mudanças.

## O que existe

Jogo 2D original offline 1×1: dois veículos, três armas, vento, terreno destrutível,
vida, dano e quedas, turnos por atraso, CPU com três dificuldades, pausa, ajuda,
resultado/revanche/menu e perfil local. PNGs gerados com GPT Images e efeitos
visuais/sonoros originais. Ranking foi retirado explicitamente.

O aplicativo macOS Universal foi entregue e aberto no computador na sessão
inicial. Fonte é o projeto Godot; aplicativo e ZIP são artefatos locais ignorados.

| Caminho | Uso |
|---|---|
| `project.godot` | Importar no Godot e executar com F5 |
| `scenes/main.tscn` | Cena principal; executar com F6 |
| `builds/Brisa de Aco.app` | Aplicativo local independente |
| `builds/Brisa-de-Aco-macOS.zip` | Pacote local da entrega |
| `docs/VALIDACAO.md` | Roteiro de aceitação funcional pelo usuário |
| `docs/APRENDIZADO.md` | Explicação da implementação para aprender com o resultado |
| `docs/ART.md` | Prompts e origem das imagens |

## Ambiente e checkout novo

Ambiente validado: macOS, Godot **4.7.2.stable.official.ed1daf0bf** em
`/Applications/Godot.app`, GDScript, renderer Compatibility. Python 3 é usado
apenas no empacotamento. Sem dependências Node.js. Outros alvos não foram testados.

Git local na branch `main`, sem remoto na consolidação. Identidade já configurada
no ambiente foi utilizada; não foi criada configuração global nova. O snapshot
contém código, UIDs/import settings, arte, evidências e documentação. Exclui
`.godot/`, `.tools/`, `builds/`, temporários e arquivos locais de credenciais.

Depois de clonar/copiar uma revisão em outro diretório, prepare a pasta usada
pelos testes e importe recursos antes de rodar os scripts:

```sh
mkdir -p .tools
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

Execute a partir da raiz. Em outras máquinas, ajuste o caminho do Godot;
comandos de pacote e assinatura abaixo são exclusivos do macOS.

## Verificações

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
```

Evidência inicial: 40 verificações de modelos + 13 da cena, zero falhas; seis
partidas naturais de modelos, seeds 81–86, encerradas em 10–28 tiros. Os testes
de partidas deixam a IA controlar ambos os atores; não simulam um humano usando
mouse. Testes de cena exercitam handlers reais de input e usam áudio mudo.
Todos os perfis de teste são isolados em `.tools/`, sem conceder XP ao jogador.

As mesmas suites foram reexecutadas na consolidação Git/SDD; consultar o registro
ao final deste hand-off. A revisão independente inicial confirmou as correções
registradas em `DECISIONS.md`.

Capturas de QA em `docs/menu.png`, `arena.png`, `impact.png`, `result.png`.
São renders reais; a captura de resultado usa vitória controlada, não comprova
término natural. Partidas naturais são verificadas separadamente na suite.

Limite da validação inicial: Computador conseguiu ler captura, mas recusou
interação de mouse como `noWindowsAvailable`. Não alegar teste manual completo
do aplicativo por mouse. Ainda falta o relato do usuário sobre uso funcional.

## Reproduzir o aplicativo

O exportador requer `.tools/macos.zip`, não versionado. No computador original
esse arquivo está disponível. Em um checkout novo, baixar o pacote oficial
`Godot_v4.7.2-stable_export_templates.tpz` na
[release Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable),
extrair `templates/macos.zip` e colocá-lo em `.tools/macos.zip`. Não confundir
esse template com o editor. Os presets debug/release apontam para esse arquivo.

```sh
python3 scripts/build_macos.py
codesign --verify --deep --strict --verbose=2 'builds/Brisa de Aco.app'
open 'builds/Brisa de Aco.app'
```

O script exporta, normaliza executável/PCK para `BrisaDeAco`, inclui avisos de
licença Godot, assina ad-hoc, verifica e cria ZIP. Não publicar uma exportação
direta sem essa normalização: foi necessário corrigir assinatura inválida com
nomes internos acentuados. Pacote não notarizado nem publicado; teste local.
Mudanças no código só chegam ao aplicativo depois de reexportar.

## Progresso do jogador e limites

Perfil real no Mac:
`~/Library/Application Support/Godot/app_userdata/Brisa de Aço/profile.json`.
Não apagar, migrar ou usar esse perfil em testes. Sem conta, ranking ou nuvem.

Limites: um mapa, dois veículos, CPU não se move, sprites estáticos com efeitos
por código, terreno de 2 px e fragmentos suspensos. Balanceamento provisório.
Não há protocolos online, builds Windows/Linux ou interface mobile implementados.

O próximo passo é validar a entrega com o usuário e registrar feedback.

## Registro desta consolidação — 2026-10-11

- `test_runner.gd`: 40 verificações, zero falhas, código de saída 0.
- `test_scene.gd`: 13 verificações, zero falhas, código de saída 0.
- `test_matches.gd`: seis partidas, zero falhas, código de saída 0; tiros por
  seed 81–86: 18, 10, 10, 28, 10, 10.
- Assinatura do aplicativo existente: `valid on disk` e
  `satisfies its Designated Requirement` na verificação profunda/estrita.
- Links locais da documentação principal/SDD e os 12 IDs de requisitos conferidos.
- Exclusões Git conferidas para cache, template, build e credenciais locais.

Nenhum comportamento do jogo foi alterado nesta consolidação. Não houve novo
build nem nova validação manual por mouse; o aplicativo é o da entrega inicial.
O commit inicial registra o snapshot completo. Consulte `git log` para obter sua
identificação e `git status` para detectar alterações posteriores.
