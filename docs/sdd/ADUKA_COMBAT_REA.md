# Aduka: dano, contato e três emissões T2

REQ-04/05/07/08/09/19/20/44/45. Pedido posterior à ADR-124: substituir
o dano/contato adaptados e corrigir o T2 para três bichos. Preservar montagem
e orientação aprovadas, originais, outros mobiles, equipamentos e perfil.

## Fonte e método

Mesmo GunBound.gme SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
graphics.xfs SHA256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Ghidra12.2/JDK26 direto; extratos novos em `.tools/aduka-combat/01..08`.
Endereços abaixo são VA, x86 LE32, base400000. Sem executar o cliente Windows.

## Evidência e contrato em revisão

| Caminho | Evidência | Situação |
|---|---|---|
| Dano por ator | 450eb0→45db20; ECX é projétil, primeiro argumento é ator | Comprovado pelo ASM; substitui a lacuna da ADR-124 |
| Distância | dx×100/aspect, dy pelo centro da caixa, teste estrito d²<r²; r=dim/2+10 | Comprovado; divisões inteiras antes do sqrt |
| Queda | trunc((r−sqrt(d²))×1000/r), depois base×fator/1000 e passes inteiros separados | Comprovado; conferir modificadores antes do porte |
| Caixa | 450e10→45d640; limites inclusivos sem rotação; 45f300/45f5d0 deslocam por tabelas de inclinação | Comprovado; converter a origem do ator para o registro visual existente |
| Projétil | 455cc0 stride8 +458920/458a00 refinam pixel a pixel; terreno antes de ator | Comprovado; conservar ordem e truncamentos |
| Raio Thor | 4398e0→4e4fe0: stride2 até limites, não segmento geométrico contínuo | Comprovado; distinguir ramo de cálculo do ramo que consome contatos registrados |
| Thor | 432320 fixa aspect150, percentual100 e tipo elétrico; XP45ea16 soma dano antes de limitar vida | Comprovado; não herdar ataque/dig do guia sem consumidor nativo |
| T2 | 466fd0 tem chamadas nos ticks2/6; SS2/6/10 | Build analisada tem2. Usuário exige3 no T2: sobreposição explícita da agenda2/6/10, não alegação de3 no PE |

## Plano autorizado

1. Fechar inicialização de dados/atributos, escudo, XP, contato e escavação
   pelos consumidores do mesmo PE; registrar diferenças de contexto.
2. Criar fixtures independentes e reproduzir os erros de dano, caixa,
   coordenadas de contato e contagem T2 antes da implementação.
3. Isolar a resolução nativa do Aduka/Thor, compartilhada por execução e CPU;
   carregar dados antes do worker e copiar qualquer máscara/estado adicional.
4. Aplicar3 emissões T2 sem duplicar a lógica do HUD/CPU ou adulterar o
   catálogo extraído. Capturar os3 sprites reais e os respectivos impactos.
5. Rodar regressões dirigidas, harness completo com29partidas, captura GPU
   temporal/dois sentidos/pausa e revisão independente. Atualizar ADR,
   TASKS/HANDOFF com resultados observados e lacunas. Sem exportação/push.

Análise estática não é execução do cliente. A resolução do terreno e a origem
de coordenadas do mundo offline devem permanecer explicitamente identificadas
quando não houver prova de equivalência, mesmo após portar o algoritmo.

## Ampliação solicitada: clima, vento e visibilidade do T2

Pedido durante a implementação: garantir que o sprite do T2 seja legível e
investigar a força desproporcional no tornado. REA novo em11..14:
`451030` detecta tornado estritamente por X dentro de largura/4, sem recorteY.
`4aafd0` (T2), `467a70` (SS) e `46e5a0` (T1) conservam velocidade em ponto
fixo dentro dele, limitando apenas |vx| mínimo a200 unidades24.8 (0,78125px
por tick). Invertem vx nas duas primeiras saídas; a terceira libera, sem
restaurar a velocidade inicial. Aceleração de gravidade/vento só é somada
fora desse ramo. O adapter C# de velocidade vetorial constante/relançamento
não deve continuar ativo para o Aduka. Vento atual é convertido na semente
do tiro e deve voltar a atuar na saída, sem criar impulso extra.

`455cc0→4510f0` acumula bônus de Force por passo, uma vez por tick, +8 com
limites20..100; `45db20` aplica metade desse valor num passe separado. O
Thor cria sua própria explosão e não copia o bônus do guia. Colunas existentes
continuam no catálogo offline; a ponte usa sua largura exibida128×scale,
enquanto o contato nativo usa um quarto dessa largura (`4ac760` desenha
largura nativa inteira). Tipos de clima adicionais sem consumidor comprovado
não devem ser anunciados como paridade integral.

Validação adicional: oráculo de trajetória com velocidades/acelerações
inteiras, ventos opostos/verticais, limites de entrada/saída e cópia CPU;
captura temporal T2 com três criaturas, mapa claro e tornado, nos dois
sentidos. A revisão independente também encontrou doisP2: assimetria da LUT
de inclinação/Ysuprimido porflag1 e efeito Bunge omitido. Corrigir e testar;
modificadores de itens offline preservados e identificados até seu porte.

Visibilidade: captura real Miramo/HD reproduziu3sprites presentes, mas
praticamente brancos por ADD sobre neve. O XFS fixado contém só
`bullet16sl.img` (a folha colorida das criaturas), sem`bullet16s.img`.
Pedido de legibilidade prevalece: essa folha atua como corpo fallback em
alpha, sem editar seus pixels/pivôs. T1/SS e glows separados continuam
aditivos. É uma decisão de apresentação para o HD existente, não prova de
que o batch nativo usa alpha nesse passe; o batch ADD permanece registrado.

## Implementação e validação observada

Harness final `./scripts/check.sh`: **16544checksGodot,44testesPython,
29partidas (13seeds+16mobiles),84suítes**, sem falhas, parse aprovado e
exit0. Log `.tools/aduka-combat/verified-harness.log`. Revisão posterior
semP1/P2, `git diff --check` limpo; código validado por SHA no JSON de QA.

- `aduka_combat.gd`/`combat_native.json`: poderT1=152+3×Attack,
  dimensão64+trunc(Dig/2), aspecto120, flags70. Defesa é
  row21−trunc(8×Defense/10); elemento altera o percentual antes de dividi-lo.
  Thor recebe poder100..300, dimensão44..54, aspecto150/flags4/percentual100,
  sem Attack/Dig do guia. XP soma o dano calculado, incluindo escudo/overkill;
  a publicação do modelo continua limitando HPterminal a0.
- `aduka_weather.gd`: amostra só coordenadas físicas, uma incidênciaForce
  por tick; snapshots duplicam máscara/estado. Vento usado no lançamento
  afeta a velocidade antes da entrada e volta a acelerar após a saída3.
  Não há mínimo de velocidade vetorial nem restauração do impulso de lançamento.
- `import_aduka_combat.py`: catálogo de16caixas e3LUTs,616fixturesPython
  independentes do GDScript e20trajetórias×100ticks de tornado. Novas suítes
  de combate661checks eclima2629checks; quatro ventos/dois sentidos também
  percorrem o modelo real e sua cópia CPU. Registros Python conferem o PE,
  campos, operadores e assets, mantendo495quadros originais da ADR-124.
- Revisão independente do ASM/código corrigiu doisP2: índice negativo usa
  NEG/SUB4, flags1 suprimemY; Bunge conserva seu bônus de cratera offline
  explícito. Regressões específicas adicionadas; revisão posterior sem P1/P2.
- GPU M4Pro/OpenGL4.1: Miramo real com3T2 visíveis, primeiroThorquadro77,
  HUD acima do feixe e saída semglow residual. Imagem antesADD, imagem alpha
  e detalhe em `docs/aduka-combat`. GaleriaT1/T2/SS:300quadros1920×1080,
  T1umaexplosão/T2trêsThor/SStrêsThor em cada sentido; pausa30idêntica e
  retomada,15,46s de captura/escrita (não prova de performance60FPS).
  Vento/tornado:outros300quadros, pausa30idêntica e retomada,19,66s; cenários
  controlados de trajetória terminam fora da arena estreita semThor, como
  registrado no JSON. Relógio60Hz; física20Hz.
- Captura adicional inicialmente parou noquadro17 com janela macOS ociosa;
  repetição com `RenderingServer.force_draw` offscreen concluiu os300.
  Não usar a tentativa parcial como validação. Clipe codificado a60quadros/s
  representa o relógio do harness. Perfil isolado e som silenciado.

Essenciais ASM completos/limites dos manifests em `native-proof.json`.
Consulta09 teve seletores não resolvidos e12 faltou4ac750, recuperado14;
somente resultados resolvidos sustentam as afirmações. `45d640` foi dividido
pela análise em`0045d640..0045d691` e`0045d692..0045db13`, ambos preservados.

## Limites deliberados

Não houve execução do cliente Windows nem escuta humana. Origem de ator
convertida para o registro visual aprovado; muzzle, apoio/queda, agenda de
clima e tipos adicionais continuam na arquitetura offline. Colunas usam a
largura já exibida como ponte para a unidade nativa; não se afirma identidade
do pacote/geração climática do cliente. Itens mantêm seus efeitos anteriores
onde a ativação nativa não foi portável neste corte. A câmera/interpolação
não participa do contato. Não há exportação/app/PCK/ZIP, versão, commit ou
push desta alteração. T2com3 ealpha são exigências de apresentação/composição
do usuário, explicitamente distintas das duas chamadas/passeADD do PE fixado.
