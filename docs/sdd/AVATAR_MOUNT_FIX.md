# Avatar/mobile — correção de registro (REQ-39, REQ-19)

Relato do usuário: inventory.png mostra corpo/cabeça/acessórios deslocados do
mobile. A inspeção confirmou avatar recuado e apoiado num pivô incorreto.

Causa: o rig recebeu o centro Body do avatar original no ponto dos quadris do
piloto HD monolítico, com deslocamento arbitrário(0,−8). Os registros diferem.
Rider.cs coloca Body em RiderPivot; cabeça/óculos/bandeira são relativos a ele.
Para reproduzir a referência sem mudar os PNGs ou proporção, a montagem local
no apoio é `(RiderPivot_idle − (0, contact_y−pivot_y)) ×60/hull_width`, com escala
uniforme60/hull_width. Bigfoot:(3,5−31)×60/49; Mage:(5,6−32)×60/46.

Plano da correção: registrar esse transform a partir da configuração existente
do MobileSprite, aplicá-lo ao conjunto AvatarArt, conservando movimento contínuo
do chassis. Caminho de piloto legado continua inalterado. Sem mudanças de
combate/perfil/compra. Teste vermelho test_avatar_mount, comparação GPU
original/HD e inventory/poses atualizados; suites de cena/arte e harness quick;
app/ZIP reexportados e assinatura/PCK conferidos após a alteração.

Segunda diferença encontrada: DepthParameter põe AvatarBody0.046 atrás de
Mobile0.05. O caminho equipado desenhava o corpo sobre o chassis. A correção
desenha o conjunto equipado antes do chassis/arma/rodas, tanto no HD quanto no
fallback original. O piloto HD legado mantém suas camadas anteriores.

Resultado: regressão2falhas→24checks sem falhas; quick1314sem falhas.
Comparação GPU usa fallback Godot com geometria/metadados do C#, não execução
do aplicativo C#. Imagens atualizadas; app/ZIP0.14.1, assinatura e PCK válidos.
Validação manual do usuário permanece pendente.
