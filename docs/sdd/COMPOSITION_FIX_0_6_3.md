# Composição piloto/mobile 0.6.3

Pedido: tiros corrigidos, mas proporção do piloto/carrinho ainda incorreta no
menu, conforme screenshot. REQ-19/20/12; preservar REQ-09 e tiros0.6.2.

Diagnóstico: altura29 do piloto contra altura nativa equivalente54/57;
canhão Bigfoot30×28 e rodas30 superdimensionados. Hip anchor7/−25 foi definido
sem os offsets nativos. Testes anteriores asseguravam estabilidade temporal,
mas não a relação entre piloto, rodas e arma. Piloto unido não implica conjunto
corretamente proporcionado. Corrigir composição no render compartilhado.

Plano: manter PNGs existentes e anatomia única; calibrar figura inteira com a
união alpha original corpo/cabeça e RiderPivot idle. Recalibrar rodas/canhão,
assento e ordem de camadas; peças com aspecto preservado. Mesmo layout no menu
e arena, inclinações e ambos sentidos. Sem mudança de física/tamanho físico,
regras/colisão/tiros/áudio/progresso; fontes originais preservadas.

- [x] Reproduzir screenshot/comparar composição original e HD.
- [x] Regressão das proporções e encaixe; calibrar layout compartilhado.
- [x] Comparar captura anterior versionada com menus/arena atuais; poses nos dois sentidos.
- [x] Suites pertinentes, revisão, exportação/assinatura/runtime/PCK.
- [x] Atualizar SDD e Git local.
- [ ] Usuário validar composição final.

Evidência:788checks/12suites, zero falhas; regressão RED106/3→GREEN108/0.
120framesGPU/24fps e comparação original/HD em docs/composition; menu/arena
reais atualizados em docs/hd. Revisão sem achados bloqueantes. Exportação0.6.3,
assinatura/runtime/PCK isolado sem falhas. Fontes/tiros/regras preservados.
Galeria em encostas é fixture visual; não inclui morte/contato físico no terreno.
Margem por aspect fit da roda~0,49unidade; sem efeito em colisão. Aceitação
artística pelo usuário pendente.
