# Integração do Shop à main (0.14.3)

Pedido explícito do usuário: levar todo trabalho de codex/avatar-shop à main.
Main continha itens0.13 commitados; ambas limpas. Integração local, sem remoto.
REQ-35..41; preservar itens, Shop/perfil/HD e todo histórico/documentação.

Resolução: Match.start mantém loadout como7ºargumento e recebe atributos no8º.
Atores copiam ambos; scene.start_match transmite opções/atributos/equipamento.
Dano usa fator único(1+(Attack persistente+bonus do item−Defense)/100), Dig soma
persistente+bonus Bunge antes de aumentar raio. ItemDelay aplica custo original
×(1−pontos/100), truncando antes de dividir7,5. Predict/voo compartilham
shot_shells e cálculos, inclusive Dual+. Gold agrega uma vez por salvo/resultado.

Validação: suite do worktree completa1454+10partidas passou antes do merge.
Testes de integração previstos: ItemDelay vs AttackDelay, dano aditivo com
Power Up/defesa/escudo, Dig+Bunge, Dual+previsão/cópia e cena Shop+itens/restart.
Executar suites de ambas entregas e partidas completas antes de commit;
reexportar app na pasta principal e conferir assinatura/PCK com perfil isolado.

Resultado: direcionados200 e integração39 passaram; suite completa1584checks+
10partidas sem falhas. Revisão independente dos contratos/modificadores/snapshot
não identificou Important/Critical. Regressão de dano climático do sinalizador
sem Gold foi reproduzida/corrigida. Aplicativo combinado exportado na raiz main;
smoke PCK separado verifica catálogo/HD/itens e custo reduzido com perfil isolado.
