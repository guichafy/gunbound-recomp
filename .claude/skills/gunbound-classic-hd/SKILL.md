---
name: gunbound-classic-hd
description: "Use quando a tarefa envolver regenerar imagens ou sprites de Gunbound Classic/OpenBound em alta resolução ou Full HD, animar mobiles/personagens/avatares, ou corrigir tremor, troca de anatomia, proporção e encaixe dessas peças."
---

# Gunbound Classic: arte HD e animação contínua

Preserve a identidade clássica ao reconstruir detalhes. Anime uma anatomia
constante por pivôs e transformações contínuas. Nitidez de um quadro isolado
não comprova estabilidade de uma animação.

## Escolha o resultado

- **Imagem somente:** regenere a imagem solicitada; não altere a engine.
- **Asset para o jogo:** entregue a arte, metadados de registro e integração.
- **Animação com arte já boa:** corrija registro/rig/relógios antes de gerar
  novamente. Uma geração nova não resolve um pivô incorreto.

Full HD significa **1920×1080** para a imagem/composição final. Sprites e atlas
transparentes podem ter outros tamanhos: confirme os pixels úteis da figura
e a nitidez na maior escala de uso. Um PNG1254×1254 não é Full HD; aumentar
a tela transparente ou interpolar pixels não reconstrói detalhes.

## Regenerar

Leia [geração e prompts](references/generation.md) quando criar/substituir arte.
Inspecione a fonte e um asset HD aprovado como referências distintas: a fonte
define identidade/geometria, o aprovado define acabamento. Preserve direção,
silhueta, cores, pose e proporções. Gere peças estáveis e efeitos separados.
Use GPT Images no fluxo aprendido neste projeto, respeitando outra escolha
explícita do usuário e a ferramenta de imagens disponível. Preserve originais,
brutos, alpha real, prompts e dimensões observadas; copie o resultado escolhido
para o projeto e regenere o catálogo antes de integrar.

Para personagem sem equipamento modular, prefira anatomia inteira. Para
avatares vestíveis, cabeça/corpo/óculos/bandeira continuam separados, ligados
por âncoras constantes. Não gere uma cabeça diferente em cada pose nem
redimensione partes conforme os efeitos crescem.

## Registrar e animar

Leia [registro, composição e movimento](references/animation.md) para código.
Recorte alpha uma vez e registre o pivô na janela nativa. O centro da silhueta
por quadro não é uma junta: olhos/cabelo/luz mudam o bbox sem mover o assento.
Conserve aspecto e escala compartilhada. Distinga Body/RiderPivot de quadris
de um piloto inteiro; derive a montagem do contato real do mobile.

Respiração usa relógio contínuo pausável; ações conservam seus tempos originais.
Misture mudanças de pose a partir da geometria atualmente exibida, por ator,
incluindo interrupções/recuo repetido. Rodas seguem distância acumulada.
Animação não determina colisão, dano ou trajetória.

## Conferir e entregar

Verifique registro/proporções constantes, ciclos/transições, pausa, ambos os
sentidos e inclinação. Inspecione sequência GPU a60fps, além de uma imagem
1920×1080 sem distorção de aspecto. Confira alpha/halos e nitidez no tamanho
real. Rode regressões pertinentes; preserve fallback nativo quando faltar
arte/metadado válido. Se entregar aplicativo, reexporte e confira seu pacote.

Em Gunbound Recomp/DemoGame, consulte [mapa do projeto](references/demogame.md)
para arquivos, fórmulas e testes existentes. Não copie suas coordenadas para
outro mobile sem medir a fonte. Entregue caminhos, dimensões reais, prompt,
evidência de movimento e limitações: rig HD é adaptação artística, não
restauração de todos os gestos/olhos do original.
