# Card do avatar0.14.7 — REQ-20/38/39

Validação do usuário: retângulo de preço cobre os detalhes da moldura; imagem
de referência também mostra melhorias por peça. ADR-067, fonte C# somente leitura.

Causa visual: ColorRect148×27 em(9,115) é uma camada plana independente,
desenhada sobre o contorno branco e os detalhes inferiores da textura do card.

Fonte de regras: AvatarMetadata.cs e AvatarMetadata.json não têm campos de
bônus; Player.Attribute contém os modificadores. EquipAvatar só troca IDs.
Assim, nenhum dos15avatares do catálogo aumenta ataque/vida/etc. Informado
ao usuário ao perguntar se avatar aumenta ataque; manter comportamento atual
e comunicar “Cosmético · sem bônus”. Não copiar stats dos avatares de outra
imagem nem atribuir bônus fictícios a Space Marine/Basic.

Plano antes do código:
1. Remover retângulo solto e compor faixa azul na própria moldura, reutilizando
   os pixels HD/nativos; bordas, cantos, rebites e highlight continuam visíveis.
2. Reservar linha no painel branco para “Cosmético · sem bônus” e tooltip sobre
   melhorias via Atributos; mesma informação na confirmação de compra.
3. Ajustar retrato para126×66 sem distorcer, mantendo card166×147/grade3×3.
   Arte já aprovada é suficiente: nenhum PNG nem anatomia precisa regeneração.
4. Validar suites de loja/cena e captura FullHD (HD/fallback/compra/roster),
   reexportar0.14.7, conferir assinatura e smoke do PCK em/tmp.
5. Atualizar TASKS/HANDOFF com resultados observados e limites.

Resultado: apresentação corrigida em HD e fallback, com rebites/moldura
visíveis.1848checks em check.sh --quick, zero falhas;280específicos de
loja/cena/continuidade. Revisão independente sem achados. GPU1920×1080 e
vídeo120frames60FPS em docs/avatar-card-fix; PNG anterior enviado pelo usuário
preservado. Nenhuma geração raster nova: reaproveitamos mestres/registros
aprovados. Partidas longas não repetidas porque combate não mudou.

App/ZIP0.14.7 reexportados e assinatura estrita válida. Smoke GPU do PCK
real, executado de/tmp com --path /private/tmp, passou: informação de efeito,
retrato126×66,20texturasHD, popup, inventário, recarga e equipamento na batalha.
Fonte C#/perfil real preservados; validação visual pelo usuário pendente.
