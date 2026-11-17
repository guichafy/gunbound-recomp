# Recuperação do PR57 e desempenho Android — 16/11/2026

REQ-ANDROID-V1/A1–A8. Pedido atual autoriza corrigir, otimizar, enviar e fazer
merge do PR57 após todos os gates. Substitui a reserva anterior de merge pelo
usuário. Play Store, credenciais persistentes e redesenho continuam fora.

## Design e execução

Manter Godot/GL Compatibility e a apresentação aprovada. Medir antes/depois
no mesmo AVD ARM64/API36, resolução e cenários, declarando os limites de
emulação. Otimizar somente custos comprovados de apresentação/recursos;
CPU, física, colisão, roster, mapas e perfil permanecem equivalentes.
Não reduzir gates, omitir suítes ou aumentar timeout para esconder falhas.

- [x] Reproduzir falhas do run43750784089: fixture Android sem diretório em
  checkout limpo; seleção de bash/stub no Windows; registro do emulador no SDK.
  Fixar com regressões e executar testes de automação e cenas afetadas.
- [x] Instrumentar cenário reproduzível e coletar baseline de frame/CPU/memória.
  Identificar custo dominante e corrigir com teste de invariantes; comparar
  imagens, cenário e medidas antes/depois no mesmo ambiente.
- [ ] Executar regressão, exportar/inspecionar APK, executar smoke Android e
  solicitar revisão independente do delta antes de integrar.
- [ ] Atualizar requisitos/decisões/handoff/issues e descrição do PR com provas.
  Enviar branch; acompanhar todos os checks do SHA final sem bypass, fazer
  merge protegido e acompanhar a execução da main.

## Foco de revisão

Checkout vazio versus arquivos locais prévios; Git Bash versus WSL/quoting;
metadata do SDK versus bytes travados; invalidação de cache/recursos; pausa,
retomada, animação e entradas conservando a mesma saída visual e mecânica.

## Evidência inicial

Mac e Windows: layout acessa shop nula após save_profile retornar false;
lifecycle falha após a mesma navegação recusada. Falta .tools/android-v1 no
prepare_test_dirs. Windows: testes invocam bash do PATH e executável stub
POSIX; seleção precisa ser explícita/portável. Android: avdmanager informa
que package emulator não está instalado embora o binário tenha sido extraído.
As causas SDK/Windows serão confirmadas por reprodução específica.

## Decisão de desempenho

Inventário de texturas/AVD: aproximadamente835MB carregados,388texturas no
lobby desktop; o catálogo de16sprites é construído antes de qualquer seleção.
Maior folha ativa Bigfoot4× tem6880×6240 (171,7MB RGBA sem mipmaps).
Preservar essa folha aprovada. Em Android, iniciar catálogo vazio; carregar
somente os IDs apresentados e descartar os outros em transições sala/batalha.
Preparar ambos antes de BattleArt.reset para preservar native_animation/EPA.
Desktop e factory completa usada pelos testes continuam disponíveis.

Regressão: catálogo Android inicial vazio; selecionar os16IDs em sequência,
conservar ambos sprites/poses e manter somente IDs visíveis. InvalidID retorna
null. Comparar APKs e sequência raster idêntica com o mesmo seed/frames.
Diagnóstico mede240frames por cenário (60warmup+180amostras), passo1/60 fixo,
SOLO/rajadaBigfoot/JEWEL emNirvanaA; registra intervalos, CPU, drawcalls e bytes.
Não é o orçamento físico60s; não afirmar aceite físico com esses dados.

## Validação local observada — 17/11/2026

- Automação105 testes/4,789s, sem falhas, Ruff/diffOK.
- Recursos130/0; sete cenas962/0 antes do guard de minas.
- GPU comparação HEAD4be8312e versus implementação:3/0, raster final idêntico
  em SOLO/BigfootT2/JEWEL,1440frames processados no total,1280×800.
- APK diagnóstico1760ff1721d823314764ba8b1c912ac96ad61f1a80d76924a0c7ae4070afc7d4:
  assinatura/alinhamento16k/recursos aprovados; AVD ARM64/API36:48tiros,66mapas,
  22JEWEL eUI3, zero falhas.
- Texturas antes→depois:835863250→517618654 bytes SOLO (−38,1%);
  835203714→516959118 na rajada;835898234→242207890 JEWEL (−71,0%).
  Drawcalls91/92/102 iguais. JSONs em ../android-v1/pr57-recovery/.
- O depois foi medido enquanto o harness concorreu pelaCPU: intervalos de
  frames não são uma comparação justa deFPS. Não afirmar aceleração ou
  orçamento físico aprovado. Benefício comprovado é memória/carregamento.
- Matriz dos16 IDs passa; sprites auxiliares de Raon só carregam quando
  minas/cristais existem. Não iniciar catálogo completo no lobby Android.

Referência de dados modernos: implementação nativa AOSP
[createUserData](https://android.googlesource.com/platform/external/qemu/+/refs/heads/emu-32-release/android-qemu2-glue/main.cpp)
aceita data/empty_data_disk e cria ext4 no boot. A reprodução com CLI19
passou da falha de pacote à falha userdata.img após registrar package.xml,
comprovando as duas incompatibilidades antes de enviar a correção.
Boot completo Linux das duas imagens ainda depende do novo run remoto.

Revisão independente encontrou um P2 adicional: loading ainda desenhava o
modelo da partida anterior sob a sala, alternando carga/liberação da dupla
anterior e da nova a cada quadro. Loading agora usa o caminho frontal.
Regressão por cinco quadros reais: RED132/2, GREEN132/0; verifica
Bigfoot/Mage→Grub/Lightning sem nenhuma recarga dos IDs antigos.

Revisão final independente aprovou o delta sem P1/P2 pendente após esse ajuste.
