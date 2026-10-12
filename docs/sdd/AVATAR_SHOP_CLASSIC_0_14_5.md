# Avatar Shop clássico 0.14.5

Pedido: primeira imagem enviada define a composição desejada; a segunda mostra
os problemas da loja atual. Fonte C# é somente leitura.

REQ-38/39/20: tela virtual800×600, escala uniforme e centralizada; grade3×3
com nove itens/página em cards166×147, janela146×90, retratos126×78 centrados sem distorcer aspecto.
A coluna esquerda reúne prévia compacta do conjunto/mobile, saldo Cash/Gold,
inventário sempre visível com oito linhas e rolagem. Selecionar uma peça possuída
nessa lista veste/salva e atualiza prévia; não compra nem cobra novamente.
Categorias cabeça/corpo/óculos/bandeira e setas ficam abaixo da grade; Try/Buy
continuam no rodapé. Busca compacta e filtro Inventário preservados.

REQ-40: distribuição de atributos sai da coluna e entra em painel próprio
aberto por Atributos. Rascunho, confirmar/cancelar, limites e efeitos permanecem;
ESC fecha primeiro o painel. Modal bloqueia todos os controles subjacentes.

Identidade/aparência: usar moldura, ícones, animações e fundos originais do
OpenBound; recriar a composição da foto em controles Godot, preservando fontes
PNG e metadados. Derivados HD de avatar aprovados conservam pivôs/rig.
O C# usa5×5: aqui a foto prevalece para layout3×3. Catálogo tem15 registros,
não os nove chapéus da foto; não inventar avatares/preços/bonificações por peça.
Não adicionar venda, descarte, presentes ou amigos sem mecânica offline aprovada.

Plano e critérios:
1. Reproduzir diferenças de grade/paginação em regressão e comparar fonte.
2. Reorganizar a apresentação, inventário lateral e painel de atributos.
3. Verificar compra modal, lista vestível, troca gênero/categoria, busca/páginas,
   cancelamento/rollback e persistência para batalha, com perfis isolados.
4. Capturar composição1920×1080 com barras laterais e aspecto4:3 preservado;
   conferir retratos, alinhamento, nitidez e sequência da prévia em GPU.
5. Executar suites pertinentes/quick, revisar e reexportar app assinado.

Originais, regras de combate, saldo/perfil e rig mantidos. A skill
$gunbound-classic-hd orienta aspecto/registro/validação; essa correção de layout
não necessita regenerar anatomia aprovada.

## Resultado observado

Concluído na worktree.1758checks rápidos sem falhas;25Shop+25classic e130
continuidade. Revisão independente não encontrou Critical/Important; menores
visuais corrigidos. Capturas FullHD e120frames GPU/60fps preservados.
App/ZIP0.14.5 reexportados e assinatura estrita validada; smoke GPU do pacote
real confirmou cliques no inventário, perfil recarregado e quatro peças em
batalha. Fonte C#/perfil real/rig originais não modificados. Usuário ainda não
validou esta composição; main preservada até nova integração.

## Integração à main solicitada posteriormente

Fast-forward completo959db5f→5dda3d8, sem conflitos. Na main,1758checks e10
partidas completas sem falhas; app/ZIP0.14.5 reexportados na pasta principal,
assinatura estrita e smoke GPU do PCK válidos (inventário/recarga/batalha).
Esta integração substitui a condição de main preservada da etapa anterior.
