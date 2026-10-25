# Lobby: chat, carteira e patente clássica

25/10/2026. REQ-02/10/12/19; ADR-102. Solicitação: corrigir as inconsistências
da captura do lobby e adotar patentes clássicas, com o perfil inicial GM.

## Contrato e desenho

- Conservar o palco800×600, fundos/botões aprovados e navegação offline.
- Cartão: insígnia vertical nativa, apelido, Rank GM, GP e dois campos de
  carteira dentro da moldura. Valores completos com separadores; nomes longos
  contidos com tooltip. GM significa Administrador do Sistema.
- Lista do canal: mesma patente do cartão e apelido contido no painel.
- Chat: histórico limitado com rolagem, entrada transparente dentro da faixa
  nativa, Enter envia uma mensagem local, caracteres de BBCode tratados como
  texto. Botões de canal continuam com canal1 ativo e demais indisponíveis.
- Patente atribuída é um dado próprio do perfil, separado de level()/XP.
  Perfil novo e perfil legado sem patente recebem GM20. Dado explicitamente
  inválido recebe Chick19. Saldo, XP, partidas e avatares não são redefinidos.
  Recompensas preservam a patente, inclusive GM; não há ranking de servidor.
- GP apresentado usa o XP local existente; não se afirma portar recompensas
  nem classificação competitiva do servidor. Nada muda nos pontos de atributos.

## Evidência

REA/Hopper abriu GunBound.gme SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Ghidra do conector indisponível por configuração12.1.x; Hopper funcionou.
`docs/lobby-rank/rea-evidence.json` conserva14registros com IDs/ASM/pseudocódigo.

| Observação | Fonte | Autoridade |
|---|---|---|
| rank1.img→recurso100; rank2.img→101 | 0040f145–0040f162 | ASM original |
| WORD da patente recebe +4 | 004e04ff–004e050a; -1 resultante vira23 | ASM original |
| Lobby usa rank1, posição172,9 | 0042986a–004298ad | ASM original |
| Atlas vertical15×25/horizontal25×15,25quadros; GM no24 | graphics.xfs SHA a52f9f46… + decodificador + inspeção | recurso original |
| Códigos −4…20, GM20, Chick19 | gunbound-server/README.md local, conferidos com atlas/+4 | referência de protocolo + derivação |
| GM27 do OpenBound é outra convenção | Player.cs C# | não adotar no cliente Thor |

GP→patente é atribuição externa no cliente analisado. Não inventar tabela
competitiva com base na progressão local. Não executamos o cliente original.

## Plano de implementação e validação

- [x] Testes vermelhos: GM/migração/persistência/rollback; regiões de atlas,
  contenção do cartão/entrada, rolagem e envio literal, navegação preservada.
- [x] Extrator reproduzível separado para rank1/rank2; PNGs/fontes preservados,
  catálogo próprio com hash, quadro e código. Não regenerar botões existentes.
- [x] Modelo de patentes e campo versionado do perfil; apresentação do lobby.
- [x] Suítes de perfil/loja/atributos/cenas/HD proporcionais, parse e captura GPU
  1920×1080: padrãoGM, nome/carteira máximos e histórico longo com entrada.
- [x] Revisão independente e atualização SPEC/DESIGN/TASKS/HANDOFF/resultados.

Não publicar, não alterar a versão nem reexportar o app nesta solicitação.

## Resultados observados

Concluído em fonte, sem commit/publicação ou nova versão/app. O cartão usa
rank1 no ponto nativo172,9; a lista do canal usa rank2. Os seis filtros foram
reposicionados pelas coordenadas de0042aba0. A identificação offline/versão
cabe na faixa lateral. Label/LineEdit têm tamanho reaplicado após tema e
clipping: o tamanho mínimo inicial da fonte padrão era a causa do vazamento.

- Teste inicial corrigido de infraestrutura:26checks/23falhas, reproduzindo
  patente ausente, carteira/entrada, histórico e texto literal. Após o porte,
  três falhas de contenção revelaram o crescimento de Label antes do tema.
- Suíte final `test_lobby_ui`:96/0, incluindo cliques reais da viewport,
  teclaH sem abrirAjuda, Enter único, roda do mouse e Create/volta.
- Treze suítes dirigidas: **1086checks/0falhas**. Perfil legado/loja,
  atributos, avatares/equipamentoXFS, itens, roster, cena e botõesHD preservados.
  Log `.tools/lobby-rank/regression-final.log`.
- **50quadros** de rank1/rank2 iguais emRGBA à extraçãoXFS, conferidos de forma
  independente; revisor repetiu a comparação e os96checks sem falhas.
- GPU real OpenGL4.1Metal/AppleM4Pro,1920×1080, capturas `lobby-gm.png` e
  `lobby-stress.png` em `docs/lobby-rank`: nome20caracteres, GP/carteiras1bilhão,
  histórico64mensagens, textoBBCode literal e entrada focada. Imagens finais
  inspecionadas; versão lateral visível. `render.json` guarda os retângulos.
- PCK temporário isolado: **109checks/0falhas/exit0**, cinquenta recortes,
  recursos nativos, perfilversion4/GM/carteira/chat e abertura da sala.
  `override.cfg` removido só durante exportação e restaurado byte a byte;
  smoke confirma ausência de override/TLSlocal no pacote. Pacote não é app
  novo. Log `.tools/lobby-rank/pck-smoke.log`.
- Parse da captura, compilaçãoPython com cache local e `git diff --check`
  aprovados. `.gd.uid`/`.png.import` novos criados pela importaçãoGodot.

Limites: inspeçãoGPU é do porte, não execução do cliente original; fonte de
patente é estática+assets/protocolo. Sem teste de rede, ladder ou GP→patente
competitiva. Perfil real não usado nos testes. Sem nova validação de escuta.
Aceite visual do usuário permanece separado. GPU requer execução fora do
sandbox. Import/export relatam CA/editor_settings ambientais; smoke tem
aviso deCA, sem SCRIPT ERROR. Verificação Python inicialmente tentou cache
protegido do sistema; passou com PYTHONPYCACHEPREFIX local.

Revisão independente: aprovada, sem achados materiais; log separado em
`/private/tmp/lobby-rank-independent-review.log`. Nenhuma regra de combate ou
fórmula de recompensa/atributos mudou; não se exigiu repetir29partidas.
