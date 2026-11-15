# Revisão pontual — gate monotônico de Back

15/11/2026. Leitura de PlatformLifecycle.accept_back e Game.handle_back;
nenhum teste novo, comando de AVD ou edição de produto.

## Gate

O guard de300ms usa Time.get_ticks_msec e estado persistente entre quadros/
trocas de tela, antes de qualquer efeito de Back. O limiar é inclusivo para
uma nova solicitação em300ms; a primeira chamada após inicialização é aceita.
Callbacks entre quadros mas dentro desse intervalo são ignorados. Não vi
P1/P2 na aritmética/ordem desse guard em relação à adaptação declarada.

O intervalo não prova identidade de gesto: um callback duplicado atrasado
≥300ms passa e um segundo gesto intencional <300ms é descartado. Sem gesture
ID, é uma heurística explícita baseada no atraso observado no AVD. Manter essa
ressalva no hand-off e no aceite de aparelho; não anunciar deduplicação
universal. O teste de relógio fake confirma o contrato do guard, não o limite
máximo de latência do engine/dispositivo.

## [P2] Exit confirmation não é tratada como modal em handle_back

No ramo screen=="lobby", handle_back cria um novo ConfirmationDialog em cada
Back aceito. Esse diálogo não é registrado em overlays e não há consulta a
um diálogo existente antes de adicionar outro. Assim duas chamadas aceitas
separadas por pelo menos300ms, mantendo screen=lobby, acumulam duas janelas.
O segundo Back deveria cancelar o modal existente conforme a prioridade D4,
em vez de abrir outra confirmação.

Reprodução dirigida a conferir no AVD: lobby → Back → aguardar mais300ms →
Back novamente. Pelo caminho de Game, root recebe um segundo filho
ConfirmationDialog e a confirmação permanece/empilha. A entrega de Back a
subwindows pode depender do modo embed do runtime; não executei esse detalhe
no AVD. O código não contém proteção se o sinal principal chegar, como já
ocorre no roteamento em análise.

Correção sugerida: manter uma referência ao diálogo de saída, fechar/cancelar
o existente no próximo Back e limpá-la ao ocultar/remover/trocar tela; garantir
um único callback e nunca chamar quit por cancelamento. Acrescentar sequência
de dois Back aceitos, não dois callbacks dentro do intervalo do mesmo gesto.

O achado foi enviado ao coordenador durante o smoke real em andamento; este
parecer não classifica aquele smoke como aprovado ou reprovado.

## Disposição final do P2 — corrigido

Releitura dirigida confirmou: handle_back procura PlatformExitConfirm antes
de outra navegação, faz queue_free e retorna se o diálogo já existe. O ramo
do lobby atribui esse nome ao único ConfirmationDialog e conecta canceled a
queue_free. O cancelamento não chama quit_game nem abre outro popup.

O teste acrescentado distingue novo Back aceito de duplicação dentro300ms e
confere que o filho deixa de existir após o cancelamento. O log existente
.tools/android-v1/exit-dialog-green.log foi lido: ANDROID LIFECYCLE CHECKS26,
FAILURES0. Não rodei testes novamente. **P2 encerrado por correção conferida**;
a ressalva sobre natureza heurística do gate300ms permanece, sem novo achado
nesse escopo. Smoke de AVD e agregado dirigido têm evidências próprias do
coordenador e não foram repetidos ou reclassificados por este revisor.
