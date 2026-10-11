# Correção de piloto, tiros e impactos 0.6.2

Pedido atual: personagem e tiros precisam da mesma correção de inconsistência,
incluindo animação dos tiros. Screenshot do usuário registra o encaixe do piloto
no Bigfoot inclinado. REQ-19/20/12, com pausa REQ-09 preservada.

## Diagnóstico

Piloto0.6.1 ainda monta cabeça e corpo redesenhados separadamente, esticados
para duas caixas independentes: ombros/pescoço/pés não formam anatomia coesa.
Projéteis0.6 alternam4desenhos/recortes contra o alpha do quadro original:
silhueta e tamanho mudam, loop dá salto. Bullet1/3 e shots HD apontam à DIREITA
(chama à esquerda), mas o render Bigfoot aplica angle+PI; chama fica à frente.
MageSS troca fases e gira círculos com anatomia variável; trilha repete cabeças
brancas com recortes distintos. Explosões saltam entre6imagens e ajustam
footprint a cada quadro original, alterando centro/forma/escala.

## Correção

Gerar um piloto sentado completo e coeso via GPT Images, mesmo rosto/roupa HD,
um único sprite proporcional. Posição no assento, respiração/retrocesso leves
por transformações contínuas; corpo e cabeça nunca separados nem esticados.
Gerar seis cabeças de projétil HD constantes (3Bigfoot/3Mage), sem chama
embutida. Corpo com retângulo fixo/aspecto preservado centrado na posição
física, orientação correta. Chama, brilho e anéis separados, progressão
contínua pelo age físico; lasers Mage usam trilha contínua em posições reais
sem renderizar sequência de cabeças duplicadas. Hélice mantém hit_pos/phase.
Impactos HD têm blend entre fases, centro fixo e aspecto preservado; EMP usa
seu círculo constante, crescimento/rotação/fade suaves. Duração original.
Fallback aos projéteis/Fx/piloto originais se recursos inválidos, preservando
originais/derivados anteriores. Não alterar física, dano, salvas, turno,
tamanho dos mobiles ou progresso. Sem ranking/rede/mobile/novas armas.

## Execução e aceitação

- [x] Regressões RED: orientação, centro e escala estáveis, fase contínua,
  piloto coeso proporcional, trilha/EMP e pausa/fallback.
- [x] Gerar assets GPT Images, catalogar recortes e validar transparência.
- [x] Integrar piloto e animação contínua de tiros/impactos no render real.
- [x] GREEN e suites existentes; inspecionar sequências GPU de6armas,
  personagem nos dois sentidos/em apoio inclinado e efeito de impacto.
- [x] Revisão independente, reexportar0.6.2/assinatura/runtime/PCK, SDD e Git.

Limite: animação HD adaptada, não restauração quadro a quadro do Gunbound.
Aceitação artística/funcional final depende da validação do usuário.

## Evidência final

783 checks sem falhas nas12suites, incluindo103 específicos. Revisão aprovada
após P2 catálogo inválido de impactos/EMP: duas regressões RED→GREEN.
72framesGPU/24fps, piloto nos dois sentidos e ±30°, galeria PNG/MP4/GIF em
docs/projectiles.16capturas de jogo real atualizadas em docs/hd. App/ZIP0.6.2
Universal reexportados, assinatura/runtime/PCK isolado sem falhas. Originais,
som e modelos de combate/terreno/perfil sem alterações. Git local/tagv0.6.2.
Galeria usa fixtures e tiros4×; inspeção de frames, sem teste manual completo.
