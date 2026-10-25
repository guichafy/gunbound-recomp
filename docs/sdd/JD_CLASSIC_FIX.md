# JD — cristais de atração T2 e repulsão/dano SS

REQ-04/08/09/19/44/45. Escopo autorizado: corrigir os efeitos JD no passo
comum da simulação e da previsão, sem trocar arte, mobiles, equipamentos,
perfil, balística, dano primário T2 ou versão/build. Plano escrito antes do
módulo: substituir a interpretação incorreta de cristal balístico por um
estado de efeito parado; testar alcance, movimento, dano e término isolados;
integrar o mesmo estado no Match/FlightSnapshot; executar regressões.

## Fonte e identidade

PE `.tools/mobile-animation-port/GunBound.gme`, SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Ghidra12.2/JDK25, runner da skill gunbound-client-port; projeto exclusivo
`builds/ghidra-jd-fix`; novos extratos `.tools/jd-fix/pass1..3`.
Pass1 registrou `function_not_found` para Animate T2; o ponteiro da vtable
0x555cf4 prova 0x465470. Pass2 semeou essa entrada e teve `ok=true`, assim
como pass3. ASM do PE, não o pseudocódigo, decide ABI e células guardadas.
Dados: `characterdata.dat` reextraído na pesquisa registrada em
BATTLE_SHOT_MATRIX.md (16×83 células). Cliente original não executado.

## Evidência e contrato

| Comportamento | Evidência nativa | Situação |
|---|---|---|
| T2 chama efeito fixo, não queda | Spawn0x437b40; Animate0x465470 chama0x4644e0 sem Simulate | Comprovado |
| SS efeito separado | Spawn0x437d90; Animate0x490780 chama0x48f300 | Comprovado |
| Apenas1 cristal por dono | Ambos spawns chamam437ae0(owner), que apaga objeto186a4/idowner antes da nova criação | Comprovado |
| Raio T2/SS | extraA JD[68]=60 / JD[81]=68; `dx²+dy² < r²` | Comprovado |
| Ampliação do raio em atores | actor+9ce4 (char35 bit8): r+=r/2; +9ce7 (bit4): r+=r/4, nessa ordem | Comprovado |
| Atração T2 | abs(dx)>2; acumulador actor+bfdc += 200−3*slope; se >100 desloca quotient/100 e guarda remainder | Comprovado |
| Repulsão SS | 48f9f7 IDIV100; effect.x>actor.x subtrai actor.x, senão soma; mesmo acumulador | Comprovado |
| Duração | T2 aplica efeito e depois testa contador<=18; SS aplica e depois testa<=20; sem ator deslocável encerra | Comprovado |
| SS dano por tick | ctx+15406c × actor+6520 /100; helpers40a7d0 IMUL e40a8c0 CDQ/IDIV | Comprovado |
| Origem dos 14 pontos | base characterdata ctx+f0384; stride mobile b1ac=83×548; f0384+(8×83+82)×548=15406c; JD[82]=14 | Derivado de ASM/dados |
| Fator de dano | actor+6520 carrega char[21] em41d17b..192; bits35 e tipo elétrico4 modificam ±4 em48f5f9..6bc | Comprovado |
| Destinos SS | shield=actor+6fd4, máximo em+6db0=char[23]; hp=+6968, máximo+6744=char[22]; 48f7f0..862 reduz shield e leva excesso negativo ao hp | Comprovado |
| Popup SS | 436860: ECX=slot; EDX=−dano, x/y na pilha; escreve EDX em popup+48 e soma ao existente | Comprovado, ABI custom |
| Imunidade | ator morto flag+bff7 ignorado; type14 Knight não recebe dano SS, mas passa movimento; modo3 não integra treino | Comprovado |
| Minas T2/SS | classe186a3: T2 atrai com acumulador (100−slope)*2; SS chama vtable+20 para detonar | Comprovado; coordenado com modelo de minas |
| Outros objetos | classe186a6 tem movimento e campo numérico próprios | Pendente: não existe equivalente no treino |

O raio usa divisão inteira truncada para zero, e a borda é exclusiva. Os
fatores char[21], em ordem type0..15, são
84,92,90,92,100,94,85,86,94,94,93,82,92,95,88,91. Os bits char[35] são
8,5,8,2,8,2,8,4,4,5,2,2,2,3,8,8. O SS elétrico aumenta fator4 para bit8 e
reduz4 para bit2. Não multiplica por ataque do dono nem Power Up novamente.

`actor+4b6c` é ângulo do apoio, não atributo Defesa: setter45ba50 mede
superfície e ângulo, grava a célula em45c6aa. Integração usa tilt do modelo
corrente para esse ângulo; a medição nativa completa, bloqueios contra
paredes/degraus e sinal da orientação são adaptação identificada. O fator de
dano usa o valor nativo do mobile sem aplicar a fórmula genérica de blast;
equipamento/atributo Defesa conserva adaptação corrente explicitada no módulo.

## API e validação planejada

`create(projectile, position, owner)` cria Dictionary independente de shell;
`step(effect, actors, mines, terrain, events)` aplica exatamente um tick20Hz,
retorna true para manter ou false para remover após aplicar esse tick.
Snapshot deve fazer duplicate(true). Posição do cristal não muda; campos
`age`, `ticks`, `state` alimentam arte existente. O chamador atribui Gold a
partir dos eventos de dano, consome detonação de mina marcada e só encerra o
turno após esvaziar projéteis e efeitos.

Esperados independentes: no plano, atração2px/tick e repulsão2px/tick;
resíduo<=100 aguarda o tick seguinte; 22ticks SS contra JD dão
13×22=286 pontos antes de escudo; no Bigfoot14×22=308. T2 aplica no máximo
20ticks (contadores0..19), SS22 (0..21), pois o gate é posterior ao efeito.
Atores na borda exata ficam fora; T2 com abs(dx)<=2 encerra, SS ainda causa
dano. Captura temporal/escuta e comparação dinâmica com cliente continuam
limites separados da suíte de modelo.

## Resultado observado do módulo

Reprodução pré-integração `.tools/jd-fix/reproduce_legacy.gd` executou o
Match/ClassicFlight vigentes22 ticks: `displacement=false damage=false`,
exit1 contra o esperado independente (ambos true). O ramo original criava
shell `crystal_body` com dano0 e aceleração balística, descartando os
consumidores Animate especializados. Teste isolado novo
`tests/test_jd_effect.gd`: raio nos oito vizinhos e borda exata, lados,
resíduo, escudo/excesso, Knight, repetição, TTL, cópia e minas. Resultado atual **80 checks/0**, por `./scripts/check.sh test_jd_effect`,
registrado em `.tools/check-logs/test_jd_effect.log`; integração/regressão e captura final
são responsabilidade do passo comum, ainda em validação.

A tabela de fatores e bits do módulo é uma ponte específica do cristal JD,
não aplicação retroativa de resistências em todos os blasts. Defesa em
atributos atuais reduz o fator em trunc(8*Defense/10), tomando o trecho
41d1c3..21b como ponte; equivalência completa entre equipamento Godot e
pacotes/atributos nativos não foi reivindicada.
