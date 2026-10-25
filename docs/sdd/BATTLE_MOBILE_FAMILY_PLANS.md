# Planos por família de tiros — tarefa 8

REQ-44/45. Complemento de BATTLE_SHOT_MATRIX.md, 24/10/2026. Planos de pesquisa/implementação; nenhum item abaixo afirma implementação concluída. Original comprovado prevalece; C# só preenche regra ainda não comprovada e realmente equivalente ao mobile. Identidades type13 Dragon,14 Knight,15 Aduka preservadas.

## Pré-requisitos comuns

- Concluir fábrica/autoria/previsão e física original das tarefas anteriores. As famílias devem usar o mesmo passo de simulação na CPU e no disparo real, sem ler estado vivo pela thread.
- Gravar em fixtures: type/kind/idx, estado de voo, posição/velocidade/aceleração fixa, quadros de animação, contatos, spawns e efeitos de dano. Não converter quadro MainAction em segundos por suposição.
- Usar os 48 registros da matriz e os endereços originais como referência independente. Não escrever testes que apenas repitam constantes da implementação nova.
- Cada novo campo persistente de voo/efeito deve entrar no snapshot, na cópia do mundo e no teste real×previsão. Cada filho conserva autoria, item, arma de origem e estágio de dano; separar dano primário de efeito climático.
- Antes do código de uma família, atualizar SPEC/plano/DECISIONS com o subconjunto já fechado. Não portar um raw Ghidra com registradores/argumentos ausentes.

## 1. Rajadas e dois impactos — Armor/Raon/Trico/Dragon

Pacote pequeno1: Armor S2 permanece um objeto. Fixture deve registrar primeiro impacto, estado do mesmo ID ativo, dados reduzidos por7/10 e segundo impacto final; terreno removido no primeiro afeta a segunda colisão. `count=2` nunca gera segundo objeto. Original0x44ec23/0x4688b0; C# confirma `primaryExplosion`.

Pacote pequeno2: Raon S1 muda quatro para três projéteis, idx0 comum e idx1/2 orbitais. Fixture verifica as três chamadas em0x49c2dc/0x49c3fc/0x49c50d e as fases; C# de quatro não é a referência. As minas S2/SS dependem primeiro da correção de autoria/agenda da tarefa anterior.

Pacote pequeno3: Trico S2 três componentes, mantendo o centro comum e dois orbitais; fechar do ASM0x4a2ce0/Animate0x4a4610 o deslocamento por tick antes de alterar a curva atual. Dragon S2 tem quatro chamadas em frames1/6/11/16; a cadência deve vir da tarefa de animação/relógio. Dragon SS tem cinco filhos por laço em0x46ca60, com dados e velocidade conferidos no spawner0x4388e0.

Testes: contagem por volley e Dual/Dual+, IDs únicos, primeira/segunda colisão, colisão por terreno modificado, mesma composição no predict_shot, filho sem duplicar atributo/Power Up/Gold; partidas completas com cada mobile e clima adverso. Não alterar Mage/Bigfoot HD nesta família.

## 2. Satélites — ASate/Knight

Gate de pesquisa antes do modelo: extrair fixtures das máquinas Ion0x480310 e0x47ca40, incluindo movimento para o alvo, estados por animação, local de origem, arredondamento de ângulo, força dos filhos e retorno ao idle. ASate SS tem seis emissões pelo contador real1..3×2, apesar de count8. Knight SS tem oito por laço i<8, enquanto o C# cria sete.

Pacote1: introduzir efeito de tiro guia→satélite→filho na simulação, com ator/satélite virtual no snapshot. Guia não recebe dano arbitrário para compensar filhos ausentes. Testes de referência: um guia com impacto confirmado produz ASate1/3/6 e Knight3/5/8 filhos, ordem e coordenadas das fixtures.

Pacote2: dano/cratera dos filhos com campos próprios, mantendo autoria/itens e encerrando o turno só depois do último filho/efeito. Validar ausência ou perda do guia, alvo fora de tela e pausa. Não chamar uma função de render para decidir spawn.

Pacote3: apresentação usando Ion original, arte de cada filho e sons das tabelas PE. Captura GPU compara guia, transição, cada emissão e idle; validação de modelo independe da animação desenhada.

## 3. Cristais — JD

Gate: resolver 0x4644e0 e0x48f300 célula a célula. Confirmar alcance extraA, fator de movimento, defesa de direção, imunidades, minas, objetos arrastados, duração (S2 contador≤18 e SS limite20) e o termo global ctx+0x15406c. Mapear explicitamente os destinos numéricos e a semântica do SpawnDamagePopup do SS. Não chamar o cristal de projétil em queda porque slot6 aponta ao tick comum: Animate especializado não delega a ele.

Pacote1: cristal S2 de atração em efeito de modelo separado do sprite, executado na simulação e previsão. Fixture com dois atores em lados opostos mede coordenadas por tick e autoria; fixtures adicionais para alvo já dentro do limite de2px e minas/objetos de classe0x186a3.

Pacote2: cristal SS somente depois de fechar a etapa numérica. Testes provam a cadeia com poder primário zero e verificam exatamente qual campo é reduzido, qual é o movimento, se o mesmo alvo pode repetir contato e como termina o efeito. Zero não permite nem dano fixo inventado nem ausência automática de dano.

## 4. Thor forçado — Aduka

Gate: seguir0x4398e0→0x432320→0x4ac260/330/400/4d0 e tabelas por nível. Fixar criação inicial do Thor, nível, XP, raio/poder e diferença S2/SS (incluindo obstáculos), além dos três guias do SS. O parâmetro final1 em0x4ab292/0x468611 já demonstra acionamento independente do gate climático; poder zero de characterdata não é bloqueio de design.

Pacote1: representar requisição de Thor como estágio de efeito no modelo, com autoria explícita e cópia no snapshot. Fixtures com clima sem Thor confirmam que S2 ainda o aciona. Testar Thor ausente/inicializado, níveis extremos, dano em mais de um contato e posição do feixe sem usar interpolação de câmera.

Pacote2: aplicar exatamente tabelas/regras fechadas; S2 tem2 impactos e SS3. A linha visual0x186a9 envelhece20 ticks, mas não é um projétil balístico que recebe dano de S1. Testes de referência devem distinguir poder do guia, poder do Thor e dano final; CPU/previsão devem reproduzir nível/XP sem alterar o Thor vivo.

## 5. Ricochetes — Grub

Gate: fechar normal tangencial, retenção de velocidade, relógio após primeiro contato, limiar de término e energia de cada explosão em0x49e650/0x49fd40 e0x4857f0/0x486ea0. Há contadores44 (S2) e40 (SS); não são automaticamente TTL desde o lançamento. SS não consulta mobile no Simulate.

Pacote1: Grub S2, quatro spawns no mesmo frame2 com ajustes de força/ângulo por ramo. Fixtures em plano, rampa, teto, quina e vão; comparar cada colisão/velocidade à referência e preservar vento original.

Pacote2: SS com filtragem correta de colisão e sua própria agenda de ricochete/dano; fixtures atravessando um ator antes do terreno e repetindo passagem pelo mesmo ator. Verificar previsão em terreno já escavado por ricochete anterior e encerramento de turno após a última ação.

## 6. Feixes, campos e transformação — Lightning/Ice/Turtle

Lightning: confirmar varredura original de cada braço e separar dano de passagem e choque final. C# S2 cria4 eletricidades mas isso não substitui a leitura dos quatro caminhos originais. Fixtures com cobertura parcial, dois sólidos separados e mobile fora/atrás da última célula sólida; testar que parâmetros adicionais não se perdem na fábrica.

Ice: identificar as células alteradas pelo simulador/Explode, teto e repetição da redução antes de mudar o modelo. C# `OnDealDamage` é fonte auxiliar e contém sua própria condição de limite. Fixtures repetindo S2 contra o mesmo ator, defesa máxima/mínima, SS e ausência de dano inicial.

Turtle: S1 precisa da composição ribbon do Animate; S2 tem dois componentes fase0/180. SS conta44 ticks, entra change e então0x432850(...,6) emite seis filhos comuns; fechar posições, velocidades, extraA/B e escalas antes de portar. Fixtures verificam não duplicar explosão do pai após divisão e cada filho conserva autoria e dados ajustados.

## Aceite de cada pacote implementado

Rodar suites de catálogo/fábrica/snapshot, modelo do mobile, itens/atributos/Gold e paridade real×previsão; depois `./scripts/check.sh` completo com partidas. Input/cena só exige novas suites de cena se alterado. Capturas GPU para a apresentação do mobile efetivamente portado. Atualizar TASKS/HANDOFF com números observados e pendências; nenhum build/commit/push faz parte desta pesquisa. Não pedir ao usuário fórmulas que ainda podem ser demonstradas pela fonte estática.
