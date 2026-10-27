# Porte fiel do cliente

Este documento resume a vocação do projeto. O procedimento operacional é a skill
[gunbound-client-port](../skills/gunbound-client-port/SKILL.md), com referências de
[evidência](../skills/gunbound-client-port/references/evidence.md),
[engenharia reversa](../skills/gunbound-client-port/references/reverse-engineering.md),
[Ghidra](../skills/gunbound-client-port/references/ghidra.md) e
[animação e raster](../skills/gunbound-client-port/references/animation.md).

## O que se busca

O projeto reescreve em Godot os projetos
[jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher) (launcher e TestClient)
e [jglim/gunbound-server](https://github.com/jglim/gunbound-server), mantendo o jogo fiel e
acrescentando suporte multiplataforma e funcionalidades novas. Extensões são declaradas como
tais e não alteram o comportamento original. A etapa atual é o cliente.

Reproduzir no Godot o comportamento do GunBound Thor's Hammer que se pode provar a partir
do cliente original, e manter o resultado visual que o usuário já aprovou. O usuário
autorizou a engenharia reversa do binário do lado do cliente para isso.

Não se busca um jogo "inspirado em". Cada diferença que permanece é conhecida, tem nome e
está registrada.

## Hierarquia de fontes

| Ordem | Fonte | Uso |
|---|---|---|
| 1 | Cliente original: `GunBound.gme` e os arquivos XFS/DAT em `.tools/` | Prevalece quando o comportamento está comprovado |
| 2 | Projetos jglim (TestClient e servidor) | Alvo da reescrita e referência. O servidor não prova o render do cliente |
| 3 | Adaptação declarada | Enquanto falta prova, sempre identificada como tal |

O OpenBound é uma versão diferente do jogo (Season 2) e não é fonte deste projeto
(ADR-132). Regras e assets que vieram dele numa fase anterior contam como adaptação
herdada. A pasta `assets/openbound/` mantém o nome histórico e as atribuições.

Os caminhos e hashes fixados estão em
[references/project.md](../skills/gunbound-client-port/references/project.md).

## Como cada comportamento é classificado

Cada célula da matriz de um porte recebe uma das quatro classes:

- **Comprovada:** lida no ASM, nas tabelas ou nos dados do cliente, com o consumidor real
  localizado.
- **Derivada:** calculada a partir de dados comprovados, com a derivação registrada.
- **Adaptada:** herdada de uma fase anterior ou decidida localmente, porque falta prova.
- **Pendente:** ainda não investigada.

## Contratos separados

Física, colisão e apresentação não se provam umas pelas outras. Um PNG original e testes
verdes de colisão não comprovam a animação.

| Contrato | Prova exigida |
|---|---|
| Regra numérica | Oráculo independente do código portado. A execução real é igual à previsão da CPU |
| Animação | Sequência GPU temporal nos dois sentidos, nos limites, na pausa e na retomada |
| Som e input | Escuta e interação observadas |
| Pacote entregue | Reexportação com recursos, PCK, versão e assinatura conferidos |

Uma captura do Godot não é a execução do cliente original. Uma análise estática não é uma
validação dinâmica. Os registros dizem qual das duas foi feita.

## Regras que o porte preserva

- IDs 1–16 dos mobiles, catálogo, equipamentos e perfil.
- Avatares, loja e mobiles com a arte já aprovada. Desde a ADR-130, loja e avatares usam os
  quadros originais.
- `match.gd` decide turno, dano e resultado. A previsão da CPU e o disparo real
  compartilham o mesmo passo. Interpolação e efeitos nunca entram na colisão.
- A modernização visual fica para uma etapa própria, quando pedida.

## Onde ficam os registros

Cada porte tem um documento em `docs/sdd/` com o pedido, a matriz, as fontes, os testes e
os limites. A lista por mobile está em [MOBILES.md](MOBILES.md). As decisões ficam em
[DECISIONS.md](sdd/DECISIONS.md) e o estado de cada tarefa em [TASKS.md](sdd/TASKS.md).
