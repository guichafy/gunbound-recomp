# Sala: contato do mobile, Ready e placas do mapa — 25/10/2026

REQ-02/12/19/20. Correção solicitada a partir das duas imagens anexadas:
mobile encaixado na faixa do chão, sem nome do mobile no card, indicadores
Ready e configuração do mapa com arte clássica. A terceira imagem citada não
foi recebida; usar as fontes locais para os elementos identificáveis.

## Plano e evidência

1. Substituir o contato144 da ADR-106 pelo encaixe155 e horizontal105/563.
   `GunBound.gme` SHA256
   `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`:
   função004dba80, ASM004dbb00–004dbb12, guarda posição da composição
   `(base_x+67,base_y+14)`; bases38/496,141. Conversão para o renderer
   Godot: descontar seu contato24 da âncora. O encaixe na faixa é derivado;
   análise estática não é execução visual do cliente.
2. Remover a exibição dos nomes dos mobiles em ambos os cards, inclusive
   Random; manter apelido, identificação da CPU, avatares e idle.
3. Extrair ready_back.img índices3–7: hastes vazias, WAIT, READY e chave.
   ASM004dbd2b–004dbd39 confirma índice=status+3; estado4 usa índice6
   (004dbcd9) e chave7 em base+(99,32). Haste em base+(105,−30).
   No treino, piloto é dono da sala; CPU está pronta. Sem protocolo/toggle novo.
4. Usar placas nativas SOLO,1:1,A SIDE,NODEATH,BASIC sob a prévia, com
   disposição em duas colunas baseada na foto. Refletir somente regras
   disponíveis: não anunciar Jewel,Double ouDeath40 como regras ativas.
   Dificuldade/clima continuam acessíveis, com textos abaixo das placas.
5. Fontes do graphics.xfs SHA256
   `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
   arquivos novos, BICUBIC4× por janela/alpha nearest conforme acabamento
   aprovado, catálogo independente e fallback nativo. Preservar assets prévios.
6. Regressões de sala/cena/avatar, inspeção GPU1920×1080 com ambos os
   lados, roster/Random e relógio parado/avançado. AtualizarSDD com resultados.

Sem mudança de combate/perfil, novo mapa, versão, app, commit ou publicação.

## Resultados

Implementado conforme plano. Contato155, posições105/563, sem nomes dos
mobiles nos dois cards (incluindo16mobiles eRandom). Animação/equipamento
continuam no renderer compartilhado. Ready usa índice6 doIMG (quadro3 do
atlas extraído), chave7 em137,173; o texto do piloto fica contido antes da
chave. Indicadores são decoração IGNORE, mantendo toda a área do card clicável.

As cinco placas mostram SOLO,1:1,A SIDE,NODEATH,BASIC. A distribuição em
duas colunas segue a foto; não anuncia regrasJewel/Double/Death40 ausentes
do treino. Tooltips das placas descrevem o estado existente. Dificuldade e
clima continuam abaixo; nenhuma regra ou estado de prontidão de rede criado.

Arte:7PNGs/25janelas novas, fontes emassets/classic/room/status e derivados
emassets/hd/classic/room_status_4x, catálogos incluídos no export. Conferência
independente64/0 deRGBA das25janelas, alpha nearest e hashes;456arquivos
anteriores deassets/classic eassets/hd/classic idênticos aoHEAD.
Revisor também comparou as25janelas diretamente aoXFS e os7hashesHD.

TDD:12falhas iniciais de contato/cards/indicadores; revisão identificou umP2
deinput emReady. Teste com viewport explícita e cliques reais passou com
IGNORE; probe negativo reintroduzindoPASS nas instâncias falhou somente nos
dois cliques. Não usar a primeira execução desse probe, que ainda tinha
stretch implícito, como prova isolada. Revisor aprovou após correção.

Regressão final10suítes:1093checksGodot/0;21testesPython da skillHD/0.
Comando: `./scripts/check.sh test_room_polish test_room_reference test_room_ui
test_scene test_items_scene test_roster test_avatar_mount test_avatar_continuity
test_mobile_animation test_original_mobiles`. Captura e smoke novos compilam.
Uma execução intermediária coincidiu com remoção temporária dooverride na
exportação: três suítes tiveram erro ambientalCA (assertivas0); outra tinha
os dois cliques com viewport ainda implícita. Rodada final acima passou
comoverride restaurado e viewport explícita.

GPU real1920×1080, OpenGL/Metal AppleM4Pro:17escolhas nos dois lados,
incluindoRandom, eNak equipado.24quadros20Hz,20variações visuais, âncoras
fixas e repetiçãoRGBA idêntica com relógio mantido. Inspeção das capturas
room-corrected,room-nak-equipped e galeria; fallback nativo capturado.
Não é execução dinâmica do cliente original. Mouse físico/escuta não foram
exercitados; cliques de viewport são automatizados.

PCK176886720bytes,40checks/0/exit0 fora do projeto (`--path /private/tmp`):
catálogos,25janelasHD,7fallbacks nativos, posições, nomes,Ready/Random e
ausência deoverride. Arquivooverride local restaurado byte a byte. PCK registra
erro ambientalCA; import/export registramCA/editor_settings sem permissão.
SemSCRIPT ERROR. GPU inicial restrita abortou; captura fora do sandbox passou.

Evidência:docs/room-card-fidelity (render.json,art-validation.json,PNGs,
reports,evidence com Ghidra12.2/ASM/hash). Logs locais em.tools/room-contact.
Sem novoapp/ZIP,versão,commit ou publicação. Aceite visual do usuário pendente.
