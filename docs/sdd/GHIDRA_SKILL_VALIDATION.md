# Ghidra na skill de porte — plano e validação

REQ-12/19/44/45. Pedido: adotar Ghidra na skill existente e demonstrar que
serve à análise do cliente e à reescrita delimitada em Godot. Nenhuma mudança
de combate, arte, perfil ou versão do jogo faz parte desta tarefa.

## Plano

1. Exercitar a skill anterior em contexto independente, usando só o PE local,
   para registrar lacunas operacionais antes de editar as instruções.
2. Incorporar Ghidra headless como caminho preferencial, com scripts
   reutilizáveis na própria skill. Python3 conduz importação/reabertura;
   Java exporta funções, bytes, referências e metadados pelo Ghidra.
3. Isolar perfil/cache/projeto, conferir hash do PE e recusar reutilização de
   projeto de outra origem. Entradas de função só são criadas por opção
   explícita e com endereços comprovados; ausências/falhas permanecem visíveis.
4. Validar importação nova, vtable/dados, funções ausentes, reabertura e
   resultados exportados. Derivar um contrato numérico da ASM nova e exercitar
   a integração GDScript existente com perfil isolado.
5. Repetir a aplicação em contexto independente, conferir links/frontmatter,
   atualizar HANDOFF/TASKS e tentar versionar somente esta mudança local.

Arquivos: `skills/gunbound-client-port/SKILL.md`, `references/ghidra.md`,
`references/reverse-engineering.md`, `references/evidence.md`,
`references/project.md`, `agents/openai.yaml`,
`scripts/run_ghidra.py` e `scripts/ExportClientEvidence.java`.
Testes de interface do runner em `tests/test_ghidra_skill.py`.

## Critérios

- Novo checkout consegue executar os recursos da skill sem depender de scripts
  descartáveis em `.tools` ou configuração global do REA.
- `--help` funciona; caminho de projeto oculto é recusado antes de abrir Java.
- Ghidra12.2 direto e compatibilidade do MCP são tratados separadamente.
- O export registra VA/entrada real, SHA-256, arquitetura, image base, bytes,
  referências e estado de cada pedido, inclusive função não encontrada.
- Reabrir projeto preserva extratos; outra identidade não reutiliza o banco.
- O contrato Godot deriva de instruções/dados, sem transformar pseudocódigo
  em fonte original nem anunciar validação visual/dinâmica inexistente.

## Resultados

Em execução; registrar somente evidência observada ao concluir.
