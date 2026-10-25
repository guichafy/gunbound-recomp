# Correções da sala a partir das três imagens — 25/10/2026

REQ-02/12/19/20/36. O pedido corrige apresentação, sem mudar regras de itens,
perfil, elenco ou disponibilidade de mapas. Miramo Town A continua o único
mapa implementado; as setas únicas ficam sobre as setas laterais nativas da
prévia, desabilitadas enquanto não houver outro mapa jogável.

Plano:
- Extrair ready_itemshop1/2 para catálogo uniforme64×43, mantendo símbolos
  nativos de slots; ready_item1/2 para equipamento35/71×31. Normal/desabilitado
  próprios, BICUBIC4× por janela e alpha nearest; preservar fontes anteriores.
- Corrigir encaixe das setas de rolagem no fundo; manter roda e bloqueio modal.
- Remover oscilação adicionada e manter âncora no chão da faixa com animações de repouso nativas ativas.
- Remover setas inferiores e nome duplicado do mapa; só título nativo da prévia.
- Regressões, captura GPU de geometria/estados/temporal, fallback e registros.

Investigação: catálogo usava os ícones alongados de equipamento OpenBound,
reduzindo itens de um slot dentro de células iguais; draw_room_figures adicionava
sin(elapsed) à âncora; build_centre criava setas/texto sob a prévia que já os traz.

Condição adicional do usuário: Random deve exibir o mobile laranja original
com o avatar atual do piloto. O ícone de seleção não substitui esse desenho.
Fonte OpenBound: Graphics/Tank/Random/CharacterSpritesheet.png (12×28×47),
ContentMetadata/Mobile/Random/RiderPivot.json; MobileFlipbook.cs confirma
célula28×47 e pivô(14,23.5). Usar renderer compartilhado de mobile/avatar
somente na sala; preservar escolha−2 e sorteio14/15 noStart, sem novo ID jogável.
Validar composição, fallback do piloto, ambos os times e RNG sem consumo na UI.

Condição final do usuário: posição fixa não significa congelar animação.
Mobile usa frame_index(idle,elapsed), piloto padrão e avatares recebem elapsed;
sem seno/offset adicional. Random também mantém sua sequência original.
Captura temporal deve comprovar variações de mobile e avatar, âncoras fixas e
repetição idêntica quando o relógio é mantido, além da composição equipada.

## Resultado observado

- Catálogo usa ready_itemshop1/2 normal/desabilitado64×43, três colunas, onze
  itens, símbolos nativos de slots e custo original do catálogo. Barra equipada
  usa ready_item1/2:35×31 ou71×31 sobre seis posições, com remoção e gravação
  preservadas. Não usa ícone alongado de equipamento dentro do catálogo.
- Setas16/17×48 preservadas, agora centralizadas nos poços nativos em750,404
  e750,487. Roda, limites e bloqueio modal passam pela regressão existente.
- Chão emy144; faixasA/B atrás dos mobiles e nomes à frente. Sem seno/offset
  adicional. Relógio elapsed alimenta EPA idle e avatar; não congelar o quadro.
- Só o título nativo da prévia nomeia o mapa. Controles transparentes sobre
  setas laterais322,94/454,94; continuam desabilitados, pois Miramo Town A é o
  único mapa jogável implementado. O pedido não inclui novos mapas.
- Random agora usa corpo original separado e avatar real do perfil;CPU usa
  piloto padrão. Células12×28×47, pivô14/23.5, contato45 e RiderPivot15/−5.
  Render compartilhado de avatar,HD4× com fallback nativo e mesma geometria.
  Escolha−2 não entra no modelo. Sorteio14/15 continua apenas noStart.

Arte:23PNGs novos/56janelas nativas (22itens×2estados +12Random). BICUBIC4×
por janela, alpha nearest, sem padding/novo desenho. Validação independente132/0
para itens, mais fonte/alpha/grade/hash/registro doRandom conferidos.359arquivos
rastreados anteriores e11PNGs da referência da etapa anterior preservados.

### Verificação

TDD:16/16 falhas iniciais de catálogo/layout;2/2 adicionais de camada/contato;
2falhas reproduzindo íconeRandom sem personagem. Captura temporal antes da
correção do relógio retornou idle_animation_active=false para normal/Random;
depois true. Teste encontrou fallback involuntário noRandom por diferença de
int/float no descriptorJSON; corrigido e densidade4/12janelas validada.

Regressão dirigida16suítes:1720checks/0. Após pedido final de animação,
10suítes deUI/avatar/animação:1027checks/0.21testes Python da skill aprovados.
Logs locais em.tools/room-polish; git diff --check limpo.

GPU1920×1080 OpenGL/Metal AppleM4Pro:3comparaçõesHD/nativo conservam layout,
hitboxes e85texturas de estados. Galeria16mobiles em ambos os lados inspecionada.
Sequência24quadros20Hz:20variações da região do casco e20da região do piloto,
âncoras fixas e repetiçãoRGBA idêntica com relógio mantido. Random anima e
exibe avatar equipado; trocar chapéu altera apenas piloto,CPU e RNG invariantes.
Capturas/render.json e GIF emdocs/room-polish. Não é execução do cliente original.

PCK isolado109checks/0/exit0,176501484bytes:catálogos/23PNGs,Random4×/fallback,
6slots, grade/times, contato/camadas,setas e sorteio real. Override/TLSlocal
excluídos e arquivo original restaurado byte a byte. Warning ambientalCA noPCK;
import/export registram CA/editor_settings sem permissão. SemSCRIPT ERROR.

Sem novo aplicativo/ZIP, versão, commit ou publicação. Aceite visual do usuário,
mouse físico e escuta não são substituídos pelas verificações automatizadas.
