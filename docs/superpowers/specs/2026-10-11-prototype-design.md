# Brisa de Aço — protótipo desktop

## Objetivo e autorização
Uma partida 2D de artilharia 1×1 contra computador, para validação funcional no macOS e aprendizado com o resultado. O usuário autorizou executar e entregar o protótipo sem novas etapas de aprovação. Godot 4.7.2 + GDScript, renderizador Compatibility. A engine preserva a possibilidade de portar para Windows, Linux, Android e iOS; somente macOS será validado nesta entrega.

## Primeira entrega
- Menu com apelido, seleção entre dois veículos, dificuldade da máquina e início de treino.
- Arena original lateral, terreno destrutível por máscara de pixels, deslocamento limitado, gravidade e vento.
- Três disparos: básico, pesado e especial. Dano, tamanho de cratera e atraso diferentes. Especial uma vez por partida.
- Vida, eliminação por queda, animação de projétil/explosão, colisão por varredura para impedir atravessamento em alta velocidade.
- Turnos por fila de atraso; o jogador pode agir novamente se sua ação terminar antes da disponibilidade do adversário. Tempo de decisão de 30 segundos; passagem automática ao expirar.
- Máquina escolhe disparo simulando a mesma física, com erro de mira por dificuldade; não altera dano nem vida.
- HUD de vida, vento, atraso, turno, força, ângulo, arma e deslocamento. Pausa, ajuda, reinício, revanche e retorno ao menu.
- Apelido, XP/pontuação, nível e número de vitórias salvos localmente. Recompensa concedida uma vez ao encerrar a partida. Nenhum ranking, conta, rede ou anúncio.
- Sprites e panorama originais gerados com GPT Images; terreno e efeitos desenhados pela engine.

## Decisões concretas para validar
Dois veículos: Escaravelho (ágil, menor vida) e Carapaça (mais resistente, maior atraso). Mira de 10–85 graus, força de 15–100%, movimento por A/D ou setas, ângulo por W/S ou controles na tela, espaço para carregar e soltar o tiro. Botões oferecem disparo direto usando a força selecionada. Especial é disponível a partir do terceiro turno próprio. Vitória por zerar a vida ou derrubar o adversário. Vento muda no início de cada turno, entre -30 e +30 unidades. Física customizada de passo fixo compartilhada com a IA, sem pretensão de copiar valores proprietários do Gunbound.

## Arquitetura
TerrainModel: máscara, crateras, altura e textura. CombatRules: balística, varredura de colisão, dano e fila. MatchModel: atores, estados, movimento, lançamento, resolução e CPU. PlayerProfile: persistência e recompensas. GameView: desenho, partículas, câmera leve e HUD/menu. SoundBank: pequenos efeitos originais sintetizados em memória.

## Validação
Testes headless em GDScript exercitam trajetória/vento, crateras, colisão em alta velocidade, dano, alternância por atraso, especial, timeout, pausa, persistência e recompensa única. Integração joga partidas completas controladas com a mesma lógica. Verificação visual no aplicativo e exportação macOS Universal com assinatura ad-hoc local. Não há publicação nem notarização para distribuição pública.

## Roadmap
Multiplayer online, salas privadas, busca automática, ranking online, reconexão e formatos 2×2+. Mobile após desktop: UI/UX, controles, cross-play e progresso compartilhado voltam à discussão nessa etapa.
