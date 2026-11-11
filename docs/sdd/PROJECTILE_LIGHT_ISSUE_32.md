# Composição de luzes — issue #32 / ADR-165

Base: origin/main `2f622d85b652ef9917e69d0bb8cd2a054db8c87d`.
REQ-07/19/20/44/45 (apresentação); REQ-04/05/08 preservados.
Somente cliente Thor’s Hammer, offline 1×1, nenhuma arte nova.

## Evidência anterior ao código

PE SHA256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
x86 LE32, base400000. Bootstrap valida DAT/XFS contra `.github/ci-tools.json`.
Ghidra12.2/JDK26.0.1, banco exclusivo `/private/tmp/gunbound-issue32-ghidra`.
Consultas render/publish/vtables/constructors/spawn/load-final/final aprovadas
(run/manifest/source_unchanged). Consultas load/bind/trico-publish parcialmente
úteis: endereços interiores não reconhecidos, explicitamente substituídos
pelas entradas43f0e0/4c1d30/4ae1a0. Sem execução do cliente inteiro.

| Contrato | Fonte VA / consumidor | Classe |
|---|---|---|
| Corpo primeiro, 19/20=5/6; luz depois, 5/2 |4c3020:4c4d2b..50,4c4f7f..9e; BulletTexture1=556880,2=556870|comprovado|
| Buffers de publicação correspondentes |4c1d30 liga grupos a ctx20b94/20b9c;458690 grava corpo e luz,455b60 retorna AL=1 só se célula existe|comprovado|
| Alfa por nível255−32k, nível0=255 |4c4e86..99/4c50da..ed; não ampliar rastro aprovado|comprovado|
| Armor T1/T2 |42bbb0 type0→454dc0/468860→555c34/555dac slot+12=458690; bullet1n/nl,s/sl|comprovado|
| Bigfoot T1/SS |42bbb0 type4→454dc0;42de70 type4→48de40→55631c; ambos458690; bullet5n/nl,p/pl|comprovado|
| Trico T1/T2 |42bbb0 type3→454dc0/4a2a70→555c34/5564d0;458690; bullet4n/nl,s/sl|comprovado|
| Trico SS em voo |42de70 type3→4accf0→5565f8+12=4ae1a0, publica mesma dupla somente count3fa0=−1; bullet4p/pl; pós-contato não publica|comprovado|
| JD T1/T2/SS |42bbb0 type8→46e550/4654b0→555e88/555d14;42de70→4907d0→556360;458690|comprovado|
| ASate guias T1/T2 |42bbb0 type9→4812d0→556160;458690|comprovado|
| Ice T1/T2/SS |42bbb0 type10→454dc0/473160→555c34/555f38;42de70→475990→555f58;458690|comprovado|
| Folhas somente luz |loader43f0e0 carrega IDs próprios de corpo/luz; XFS não tem bullet9n/s,bullet10n/s,bullet11s.img; só nl/sl disponíveis; não desenhar duas vezes|comprovado (índice/pixels) e derivado (roteamento Godot)|
| Pivôs/EPA/recortes |frames.json e importadores existentes, sem alteração|preservados; sem nova alegação de paridade geométrica|

`tests/tools/projectile_light/evidence.py` fixa bytes do ASM/vtables, hashes
reais e fatos do XFS; gera fixture independente do GDScript. Não inclui PE.
Inventário ativo: Mage usa renderer próprio; Nak/Grub/Aduka/Lightning já
aditivos; Dragon T1/T2 sem corpo, SS/filhos já corretos; Knight próprio para
filhos e guia já aditivo. Turtle T1/T2 WaterEffect, SS/filhos sem luz separada.
Boomer/Raon sem luz de projétil separada. ASate filhos LaserEffect/Ion, JD
cristais e demais impactos fora do delta. Bigfoot T2, Armor SS, ASate SS
mantêm corpo alfa. Seleção nova explícita por consumidor, nunca pelo nome L
isoladamente. Nenhum consumidor entra em AdukaWeather.active.

## Plano de implementação (antes do código)

1. Gerar fixture por leitura do PE/XFS; conferir vtable+publish e loader.
   Registrar somente trechos essenciais reproduzíveis, sem binário.
2. `tests/test_projectile_light.gd`: abrir pass por view; registrar chamadas
   reais de draw_projectile, conferir folha/recorte/pivô/transform/alfa,
   ausência de duplicação, armas sem luz e preservação de has_trail.
   Observar RED antes de ampliar seleção. Adicionar ao check.sh.
3. `classic_sprite.gd`: ampliar ADDITIVE_LIGHT_KINDS só aos seis acima;
   delimitar light_only por lista comprovada. Manter funções públicas,
   física, EPA, smooth4× e geometrias. `additive_sprite_art.gd`: liberar
   canvas de views destruídas, cobrir liberação e independência entre views.
4. CapturaGPU FullHD: seis IDs,3 armas, dois sentidos, fundo claro/escuro,
   comparação legado/novo; tempo fracionado, contato real,30frames pausa,
   retomada e frames vazios após remoção. Pixel probe independente confere
   corpo alfa→luz aditiva e ausência de comandos residuais/duplicados.
5. Dirigidas requisitadas + portes #26..31; harness completo (29partidas,
   guard900s/pool4 intactos), Ruff/diff; revisão independente antes do PR.
   PR quatro gates, rebase merge, mainCI/release automática. Sem bump manual.

## Focos de revisão

Não tocar máscara/contato; nenhum evento de combate novo; snapshots
inalterados e apresentação não muta shells; luz limpa mesmo em frame vazio,
por view, pausa conserva EPA; fixtures antigas não enfraquecidas. Inspecionar
capturas e logs além do exit. Aceite técnico não é aceite humano.

## Registro de execução

- Worktree nativa própria; branch codex/issue-32-projectile-light.
- Bootstrap local sem caminho legado usa GUNBOUND_SOUND_XFS explícito.
- Baseline inicial restrito falhou em certificado macOS (ret!=noErr), não
  em assertiva; nova rodada autorizada fora do sandbox em andamento.
- RED final610checks/332falhas → GREEN910/0. Primeira fixture de investigação
  tinha TOC como lista e comparação JSON int/float; corrigidas antes do RED
  válido. Uma chamada dirigida usou nome inexistente test_trico_native;
  repetição com test_trico_t2 passou4043/0, SS394/0, Raon787/0.
- QA GPU encontrou diferença de um pixel no Bigfoot T2 sem luz (frame120,
  sentido esquerdo), na comparação de painéis transladados; hipótese inicial de matrix versus
  draw_set_transform não bastou para explicar a diferença.
  Ruling: armas sem célula de luz conservam exatamente o caminho anterior;
  seleção aditiva exige luz efetiva ou folha light-only. Probes legado/novo
  na MESMA posição confirmaram12pares RGBA idênticos, sem relaxar a prova.
  A borda filtrada4× pode rasterizar diferente em posições de tela distintas.
- Revisão independente achou P2 na captura especial Armor draw_armor, que
  saía antes do begin_projectiles; lifecycle reparado nessa captura também.

## Validação técnica final

Capturas finais:722framesGPU FullHD (361/fundo),200impactos,36modelos por
fundo nos dois sentidos;30frames pausa por fundo RGBA idênticos,retomada e
zero projéteis. VerificadorPillow independente:8probes de mistura (alfa1/0,5,
corpo+luz e só luz),8fundos vazios,72pares finais sem resíduo e12pares sem
luz legado/novo na mesma posição RGBAexatos. Revisão independente confirmou
regeneração da fixture e todas essas provas; nenhum achado pendente após
reparar o begin da capturaArmor. LogsGPU sem errors/warnings/leaks.

Pacote local via scripts/ci/package.py→build_macos.py, ZIP extraído fora do
projeto, universal4.7.2, assinaturaad-hoc deep/strict e smoke48tiros/UI PASS.
Versão local0.20.5,manifest HEADbase2f622d85 pré-commit, fonte do delta atual.
SHA256ZIP2698563b0b85883fb804372a3b60aa853ba8df5d2a7275c3e0648c09442f2f3d.
Template local SHA25688df5e2e6fee99088699be66e6d42e4da4fb0c5619d054297d755a49558a4792,
binários4.7.2.stable.official.ed1daf0bf. Sem bump nem publicação manual.

Ruff no escopo real daCI(E9,F63,F7,F82 scripts/tests) e Ruff completo dos
novos helpers aprovados; diff limpo. Ruff sem seleção no repositório inteiro
acusou472avisos históricos em artefatos/scripts auxiliares fora desse escopo;
não alterados nesta issue. Primeiro harness integral361,178s/367parses/
118suítes/61090checks/160Python/29partidas/62%cobertura aprovado. Rodada final
estável358,979s/367parses/118suítes/61090checks/160Python/29partidas passou
sem falhas/skips/leaks; resultados em docs/projectile-light/validation.*.
Runner e guard900s inalterados.

Limites: análise estática do cliente e renderGPU do porte; sem execução
Windows inteira,escuta,input ou aceite visual humano. Nada disso é inferido
dos testes verdes. Publicação somente pelo workflow existente após merge.
