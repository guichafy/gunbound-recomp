---
name: gunbound-client-port
description: "Use when porting GunBound Thor's Hammer client behavior to Godot/GDScript, investigating fidelity differences with REA and the client binary, comparing OpenBound C# with native rules, or correcting mobile, projectile, avatar, EPA, XFS, timing, animation or rendering discrepancies."
---

# GunBound client → Godot

Reproduzir o comportamento comprovado do cliente, preservando o resultado
visual já aprovado. Tratar física, colisão e apresentação como contratos
distintos. PNG original e testes verdes de colisão não comprovam animação.

## Delimitar

Ler o handoff, requisitos e código atuais. Definir mobile/arma/sistema,
versão de origem, comportamento esperado e limites antes de alterar código.
Preservar IDs, elenco, avatares, equipamentos, perfil e HD aprovados.
Modernizar o design em etapa própria, quando solicitada.

Consultar [mapa do projeto](references/project.md) em Gunbound Recomp.
Usar **gunbound-mobile-port** para detalhes do fallback C# e
**gunbound-classic-hd** para registro/rig/efeitos HD; evidência nativa
comprovada prevalece sobre aproximações dessas referências.

## Investigar e portar

1. Fixar hash/versão de binário, arquivos de dados e fontes consultadas.
   Usar [REA e evidência](references/reverse-engineering.md): seguir o
   consumidor real do dado, confirmar ASM e registrar lacunas.
2. Produzir uma matriz por comportamento: fonte, unidade, ordem, confiança,
   implementação e validação. Classificar cada célula como comprovada,
   derivada, adaptada ou pendente; usar o [registro](references/evidence.md).
3. Construir esperados independentes do código portado, a partir das
   instruções/dados originais. Cobrir sinais, truncamentos, limites legais
   e ticks anterior/exato/posterior a cada transição. Reproduzir o erro.
4. Implementar estado privado por projétil/ator e passo comum de execução
   e previsão. Copiar profundamente novos campos para snapshots. Manter
   interpolação e efeitos fora da colisão. Pré-carregar recursos antes do worker.
5. Para movimento/efeitos, aplicar [animação e raster](references/animation.md).
   Distinguir trajetória central, ponto de contato e seção desenhada;
   conferir relógios, geometria, UV, mistura, pivôs e estados.

## Conferir e registrar

| Contrato | Prova necessária |
|---|---|
| Regra numérica | Oráculo independente; execução = previsão; testes pertinentes |
| Animação | Sequência GPU temporal; sentidos, limites, pausa e retomada |
| Som/input | Escuta e interação observadas quando afetados |
| Pacote entregue | Reexportação; recursos/PCK, versão e assinatura conferidos |

Executar regressões proporcionais à mudança; regras de combate exigem modelos
e partidas completas conforme o handoff. Identificar build, comandos,
resultados e limitações. Captura Godot não é execução do cliente original;
análise estática não é validação dinâmica. Inspecionar logs além do exit code.

Atualizar especificação, decisões, tarefas e handoff. Entregar o delta,
evidências e pendências objetivas. Encaminhar ao usuário somente a dúvida que
as fontes disponíveis não resolvem, preservando o trabalho já autorizado.
