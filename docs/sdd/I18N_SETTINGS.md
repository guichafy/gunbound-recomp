# Idiomas e Settings — REQ-55 / ADR-155

## Emenda — Settings no lobby (08/11/2026)

Solicitação posterior move o acesso para a tela anterior ao Create: Settings
em (163,551), à esquerda de Ranking desabilitado em (286,551). Remover o botão
Settings da sala. O painel completo abre sobre o lobby e Salvar/Cancelar/ESC
permanecem no lobby; Create herda apelido/treino/preferências confirmados.
Preservar histórico e rascunho de chat ao atualizar idioma/nome. Prévia e falhas
de gravação conservam o contrato anterior. Esta emenda substitui a localização
na sala; menu nativo de batalha e arte não mudam.

Plano: teste de clique/posição/bloqueio/cancelamento/save/entrada na sala;
reutilizar lettering clássico por factory, abrir SettingsPanel em MatchOverlay,
atualizar identidade/idioma do lobby sem reconstruí-lo, remover acesso da sala;
regressão de cenas e captura GPU do novo acesso e modal.

Concluído: teste inicial botão ausente 1/1 → 14/0; 18 suítes/1.582 checks sem
falhas. Captura lobby-settings-entry.png e modais EN/PT/960px inspecionados;
logs lobby-final.log e lobby-final-confirm.log. Sem export/push.

Pedido de 08/11/2026: executar na main local. Traduzir texto de interface em
português para inglês, permitir escolher o idioma e melhorar Settings da sala.
Textos rasterizados em imagens ficam para outra entrega.

## Contrato e design

- Inglês (`en`) padrão; português (`pt_BR`) selecionável e persistido em options.
  Arquivos antigos/idiomas inválidos usam inglês. Não traduzir apelidos, entrada
  de chat, nomes próprios ou identificadores/regras de combate.
- Catálogo central de mensagens na apresentação, com TranslationServer do Godot.
  Formatação ocorre após tradução; texto manual do HUD também passa pelo catálogo.
- Settings existente na sala abre painel ampliado, desenhado em resolução nativa
  por controles Godot. Moldura antiga e assets permanecem preservados. Esta é
  uma modernização solicitada, não reprodução do painel do cliente.
- Paleta segue a sala: marinho #0b1b2e, azul #284c72, ciano #6fdbef,
  branco #edf5ff e âmbar #ffc760. Fonte escalável com fallback; títulos 26,
  seções 18 e controles 16–18. Duas colunas (treino / preferências), rodapé
  separado e foco de teclado visível. Nada de ampliar bitmap para texto do modal.
- Exibir apelido, dificuldade, clima; áudio BGM/SFX, modo Drag/Slice,
  velocidade de câmera, fundo e idioma. Opções não portadas (Sniper/MIDI/3D,
  Mouse Speed/skins) são informadas como indisponíveis, sem controles fictícios.
- Áudio/idioma têm prévia. Cancelar/ESC restaura snapshot sem gravar; Salvar
  persiste e atualiza a sala. Erro de gravação mantém o modal aberto com aviso.
  Nickname/dificuldade/clima só confirmam ao salvar. Abrir/fechar não altera
  mobile, equipamento, itens, música, física, XP ou Gold.
- Menu de batalha continua nativo (ADR-137); utiliza o idioma global nos textos
  de código. Textos contidos nos sprites continuam preservados.

## Plano de implementação

**Goal:** interface em inglês/português e Settings legível e completo na sala.
**Architecture:** serviço i18n e catálogo separado, locale nas options,
SettingsPanel próprio para edição visual, MenuScreen integra snapshot/ações.
**Tech Stack:** Godot 4.7.2/GDScript, sem dependências novas.
**Spec:** REQ-55 em SPEC.md; este documento define o delta pré-código.

1. [x] Catálogo/serviço e persistência: testes de idioma padrão, arquivo antigo,
   inválido, reload, placeholders e nomes do catálogo de mobiles; implementar
   `I18n.text(message: String)` e `I18n.set_locale(locale: String)`.
2. [x] Modal: testes reais de Settings, salvar/cancelar/ESC/erro de gravação,
   prévia de áudio/idioma e estado da sala preservado; construir SettingsPanel
   e integrar callbacks no MenuScreen/Game. Verificar tamanho e hitboxes.
3. [x] Cobertura: localizar todo texto PT de apresentação/catálogos e traduzir
   antes de formatar; testar sala/lobby/HUD/loja/ajuda e dados de usuário intactos.
4. [x] Rodar harness de cenas/modelos e Python (sem partidas, regras intocadas),
   capturar painel GPU em ambos idiomas e em janela menor, revisar diff,
   atualizar TASKS/HANDOFF. Sem export/push/publicação.

## Foco de revisão

Locale inválido/ausente; cancelamento após prévia; falha de salvamento; textos
longos/PT com acentos e 20 caracteres no apelido; cliques/teclado bloqueados
atrás do modal; export precisa incluir o catálogo; dados de usuário não traduzidos.

## Validação

`test_i18n`: 247/0; `test_settings_i18n`: 34/0. O primeiro teste começou
com 3 falhas (idioma padrão/legado/serviço ausente); a cobertura dinâmica
reproduziu 4 falhas antes da tradução dos templates. Revisão independente:
P2 dos tooltips de itens e P3 do placeholder reproduzidos com 8 falhas no
cenário conjunto e corrigidos para 34/0.

Três capturas OpenGL/Metal Apple M4 Pro em `docs/settings-i18n/`, inspecionadas:
EN/PT 1280×800 e PT 960×600; apelido com 20 caracteres largos. Música e regras
não foram alteradas; escuta humana e aceite do usuário não foram executados.
Sem exportação: o catálogo é um script referenciado por preload e entra nos
presets `all_resources`; essa afirmação não substitui um smoke de PCK novo.
O menu nativo da batalha manteve sua suíte 146/0. Regressão ampla: 105 suítes Godot/46.606 checks, 20 suítes Python/108 testes,
parse aprovado. Primeiro run exit1 por quatro expectativas PT antigas de
`test_roster`, corrigidas e repetidas em 79/0; rodada final das 18 suítes
afetadas 2.085/0/exit0. Histórico e limites completos no HANDOFF. Arquivos project.godot e o UID preexistente de
test_music_screens foram preservados. Sem push/publicação.
