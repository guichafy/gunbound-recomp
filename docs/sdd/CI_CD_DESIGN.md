# CI/CD e releases desktop — proposta para aprovação

Pedido de 28/10/2026. Requisitos afetados: REQ-01 (plataformas) e REQ-12
(qualidade e entrega); novo requisito proposto REQ-52 (automação de releases).
Este documento é um desenho, ainda não uma implementação ou validação.

## Resultado esperado

Cada push na `main` passa pelos controles de qualidade e produz uma release
com dois ZIPs versionados: macOS universal (Intel/Apple Silicon) e Windows
x86_64. Pull requests executam os mesmos controles sem publicar. Linux,
mobile, servidor e multiplayer continuam fora deste pedido.

## Versão e histórico

- `feat:` incrementa minor; `fix:` e `perf:` incrementam patch;
  `!` ou footer `BREAKING CHANGE:` incrementam major, inclusive antes de 1.0.
  O maior incremento entre os commits ainda não publicados prevalece.
- Para cumprir literalmente uma versão por push, pushes contendo somente
  `docs:`, `ci:`, `test:`, `chore:` ou outros tipos válidos incrementam patch.
  Essa é uma extensão deliberada da convenção, que não exige releases para
  esses tipos. Commits novos devem seguir Conventional Commits.
- Base normal: última tag de release `vX.Y.Z` ancestral do commit em teste.
  Na primeira execução, usar `project.godot` (atualmente 0.20.5) como base e
  analisar apenas os commits do push, sem reinterpretar todo o histórico antigo.
- A versão calculada é aplicada em `application/config/version` no checkout
  de build e lida pelos exportadores. Não criar commits automáticos na main.
  Tag, release, metadados e os dois pacotes devem apontar ao mesmo SHA e versão.
  O valor versionado no Git é a base de desenvolvimento; tags registram entregas.
- Reexecução do mesmo SHA reutiliza a mesma versão; release completa não deve
  ser sobrescrita. Falha parcial deve permitir retomar a release em draft.
  Concorrência da publicação deve ser serializada e não cancelar publicação ativa.
  Publicar todos os pushes, sem descartar intermediários por uma fila que só
  conserva a execução pendente mais recente.

## Controles antes de publicar

1. Validar mensagens dos commits novos, YAML/workflows com actionlint, Python
   com Ruff e scripts GDScript com o compilador Godot. Introduzir lint de
   estilo GDScript somente com baseline explícita, sem reformatar todo o jogo.
2. Preparar checkout limpo: Python e dependências fixadas, Godot 4.7.2 e
   templates correspondentes, importação dos recursos antes dos testes.
   Downloads devem verificar hashes; caches são otimização, nunca pré-requisito.
3. Rodar o harness completo, incluindo modelos, cenas e as 29 partidas, em
   macOS e Windows. Remover dependência do caminho fixo de `/Applications`.
   O runner de testes precisa preservar timeout, saída não zero e detecção de
   `SCRIPT ERROR`, erro de parse e ausência de resumo, nos dois sistemas.
4. Preparar as fontes Thor's Hammer usadas por testes a partir de uma revisão
   fixa do TestClient autorizado, conferindo hashes conhecidos. Resolver caminhos
   dependentes de pastas vizinhas. Não desabilitar testes obrigatórios para
   obter verde. Suítes exclusivamente investigativas que exigem ferramentas
   externas devem aparecer como tais no relatório, nunca como checks executados.
5. Medir cobertura de linhas Python, publicar XML/HTML e estabelecer um piso
   baseado na primeira medição real. Esse número não representa o jogo GDScript.
   Publicar separadamente inventário de suítes GDScript, resultados/checks e
   partidas; não chamar inventário de cobertura de linhas. Cobertura dinâmica
   GDScript exigiria instrumentação compatível com o harness atual e fica
   explicitamente fora do indicador Python desta primeira entrega.
6. Exportar em runners nativos e executar smoke do artefato empacotado, fora
   do projeto: inicialização, recursos essenciais, versão e perfil temporário.
   Testes headless não substituem aceite visual, áudio e input humanos.
7. Conferir ZIPs, licenças/atribuições, ausência de `override.cfg`, credenciais,
   `.tools`, testes e fontes de pesquisa nos pacotes. Gerar SHA-256 e manifesto
   contendo versão, SHA do projeto e versão Godot. Guardar logs mesmo em falha.
8. Somente depois de ambos passarem, anexar os dois ZIPs, checksums e manifesto
   à release em draft; conferir assets esperados e então torná-la pública.

## Exportação e compatibilidade

- Acrescentar preset Windows Desktop x86_64 com os mesmos filtros de recursos
  e exclusões do macOS, PCK separado e metadados de versão consistentes.
- Tornar o exportador macOS configurável por CLI/ambiente, preservando
  normalização do executável, assinatura ad-hoc e verificação `codesign`.
- Acrescentar exportador Windows e empacotamento com executável, PCK e avisos
  legais. Corrigir caminhos, diferenças de filesystem e processo identificadas
  pelos testes, preservando regras, assets e perfil do jogo.
- Sem certificados fornecidos: macOS com assinatura ad-hoc, sem notarização;
  Windows sem Authenticode. Documentar isso na release. Assinatura comercial
  e notarização exigem certificados/contas do proprietário e não serão alegadas.

## Segurança e manutenção

Permissão padrão `contents: read`; somente o job de publicação recebe
`contents: write`. PRs não recebem segredos nem permissão de publicação;
não usar `pull_request_target` para executar código do PR. Fixar actions em
SHA completo e dependências em versão; Dependabot atualiza essas referências.
Evitar interpolar mensagens de commit em shell. Timeouts e retenção limitada
de artifacts; não executar código do jogo num job com credenciais de escrita.
Proteções da main e checks obrigatórios serão documentados; sua ativação no
GitHub é uma configuração separada, não efeito de criar arquivos locais.

## Entrega e validação

### Revisão do desenho e pendências antes da implementação

A revisão independente identificou pontos que precisam ser fechados no plano:

- Serializar somente a publicação não impede dois builds de calcularem a mesma
  versão. Definir reserva/fila durável antes do build, com recuperação de falhas,
  sem perder pushes intermediários; `concurrency` padrão sozinho não basta.
- Precisar o bootstrap `before..sha`, incluindo `before` zerado, force push,
  histórico legado sem Conventional Commits e tags já existentes.
- Medir a cobertura inicial para definir o piso numérico e a política de lint
  do legado, sem anunciar gates que ainda não foram executados.
- Confirmar com o usuário se cobertura Python com relatórios GDScript separados
  atende à primeira entrega ou se cobertura de linhas GDScript é obrigatória.

O envio desta proposta para revisão não implementa a automação. Não existem
workflows novos, exportador Windows ou relatórios de cobertura nesta mudança.

### Execução futura

Implementação prevista: workflow CI/release, bootstrap reproduzível,
versionador testado, runner multiplataforma, exportadores/presets, relatórios,
testes de automação e documentação SDD. Preservar as alterações locais já
existentes em Grub/Boomer. Não enviar commits ou publicar uma release nesta
sessão sem pedido explícito; a pipeline passa a agir quando enviada à main.

Validar localmente os scripts novos e as verificações disponíveis, registrando
resultados e falhas reais. Builds nativos Windows e execução hospedada do
Actions dependem dos runners: não anunciar compatibilidade comprovada nem
release publicada apenas pela revisão estática da configuração.

## Referências consultadas

- [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Segurança de GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
- [Exportação Windows no Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)
- [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)
