# Registro de decisões

Todas as decisões abaixo foram consolidadas em 2026-10-11. Não são exigências
imutáveis: registrar substituição e motivo se uma solicitação futura as alterar.

| ID / status | Decisão e motivo | Consequência |
|---|---|---|
| ADR-001 — adotada | Godot 4.7.2 + GDScript + Compatibility; usuário já conhece Godot e engine atende a família de plataformas exigida | Mac primeiro; outras plataformas exigem exportação e QA próprios |
| ADR-002 — adotada | Primeiro modo é treino offline 1×1 contra CPU, para validar sozinho uma partida completa | Não criar servidor, conta, matchmaking ou infraestrutura online agora |
| ADR-003 — adotada | Retirar ranking desta entrega, por instrução explícita posterior do usuário | Manter apelido, XP, nível e vitórias locais; ranking volta ao refinamento online |
| ADR-004 — adotada | Aprendizado a partir do produto final; usuário pediu execução e protótipo funcional | Documentar a solução entregue; aprovações intermediárias da entrega inicial dispensadas, sem ampliar escopo futuro |
| ADR-005 — adotada | Física customizada em passo fixo e compartilhada com previsão da CPU | Uma fonte para balística e colisão; alterações precisam preservar equivalência |
| ADR-006 — adotada | Terreno por máscara de pixels, crateras e raycast DDA | Simplicidade para 2D destrutível; resolução 2 px e fragmentos suspensos são limites atuais |
| ADR-007 — adotada | Turnos por disponibilidade acumulada, com atraso por arma/veículo | Uma ação rápida pode manter iniciativa; não impor alternância estrita |
| ADR-008 — adotada | CPU busca ângulo/força e aplica erro por dificuldade, sem se deslocar | Partida funcional com IA simples; navegação e tática ficam para refino |
| ADR-009 — adotada | Perfil JSON local com gravação temporária e IDs recentes de recompensa | Sem backend; perfil editável pelo usuário, sem promessa de antifraude online |
| ADR-010 — adotada | Arte original via GPT Images, explicitamente autorizada | PNGs e prompts preservados; não usar sprites, mapas ou marca Gunbound |
| ADR-011 — adotada | Executável/PCK internos ASCII, título visível com acento | Corrige selo inválido observado; reexportar sempre pelo script que normaliza e assina |
| ADR-012 — adotada | Git local na `main`; documentação SDD e `AGENTS.md` como entrada para futuras sessões | Fonte/arte/docs no commit; builds/templates/cache ignorados; remoto não definido |
| ADR-013 — adotada em 0.2 | Usuário aprovou o pacote de refinamento com “implementa”; referência visual/técnica dos vídeos/OpenBound | Adaptar HUD e comportamentos em Godot; pacote principal de texturas ausente, nenhum código/asset do fork incorporado |
| ADR-014 — adotada em 0.2 | Mira relativa ao corpo/apoio, com conversão única em `MatchModel` | CPU, canhão e voo concordam; não usar a velocidade sem inclinação para prever o tiro |
| ADR-015 — adotada em 0.2 | Carga crescente com auto-disparo a 100%; pausa cancela sem disparar | Substitui oscilação da força; soltura tardia não duplica tiro |
| ADR-016 — adotada em 0.2 | Animação em `BattleArt`, sem alteração de colisão/posição física | Usa PNG original com transformações/efeitos; sem spritesheets oficiais |
| ADR-017 — adotada em 0.2 | Fila previsão somente após arma conhecida; painel evita vida/identificação de ator vivo | Ordem e custo vêm do modelo; evita informação falsa e sobreposição em crateras |
| ADR-018 — pedido atual, integração pendente | Usuário solicitou os assets/mobiles reais do fork, incluindo Bigfoot | Substitui a restrição artística de ADR-010 para a próxima integração. Pacote externo recebido via Drive e validado; usar sprites reais, sem substitutos gerados |
| ADR-019 — recebimento de assets | Manter pacote original e extração em `.tools/source-assets/`, com checksum/inventário; copiar só recursos utilizados ao integrar | Download de 813 arquivos validado; nenhum binário de cliente/servidor baixado ou executado; jogo ainda 0.2.0 nesta etapa |
| ADR-020 — Bigfoot visual 0.3 | Pedido atual prioriza Bigfoot com sprites reais; integrar atlas/piloto/animações/projéteis como terceiro veículo | PNGs intactos, FPS/offsets do fork, filtro nearest. Vida 1100/movimento 90; armas/física continuam protótipo, sem equivalência integral |
| ADR-021 — pose de tiro | Recuo usa arma registrada; carga reinicia ciclo ao trocar seleção | Evita SS mudar para S1 após turno curto e herdar relógio de outra carga; regressões RED→GREEN |

## Achados resolvidos na revisão inicial

- Ajuda após resultado retirava as ações finais: fechamento agora restaura resultado.
- Colisão por amostragem podia perder canto de célula: substituída por travessia DDA.
- Previsão ignorava o atirador por toda a trajetória: janela de 0,15 s agora é
  compartilhada com o disparo real.
- Barra de vida herdava altura mínima do tema: dimensão ajustada após estilização.
- Áudio headless imediato deixava objetos de playback pendentes: testes de cena
  usam áudio mudo; o aplicativo mantém os efeitos sintetizados.

Esses ajustes têm regressões nos testes. A revisão foi da implementação inicial;
não representa uma nova revisão independente desta documentação.

## Ajuste visual 0.3.1

ADR-022 — adotada: reduzir Bigfoot/piloto juntos, mantendo os pixels originais,
contato com chão e offsets relativos. Escala de arena 60 (antes 80), menu 180
(antes 230). Ajuste de apresentação em REQ-19; regras de colisão/combate preservadas.

## Mage 0.4

ADR-023 — adotada: substituir Carapaça por Mage com atlas/piloto/efeitos/sons
originais. Reutilizar leitor base de atlas sem mudar quadros ou escala Bigfoot.
Dados de combate próprios do Mage consultados pelo modelo, HUD e CPU.

ADR-024 — adotada: manter SS=200 conforme construtor executado do fork, embora
constante SS=300 não seja utilizada lá; EMP antes do dano. Delays750/900/1300
normalizados÷7,5. HP/escudo/regen/mira/hélice seguem dados originais; balística e
regras de desbloqueio SS continuam adaptadas à arena atual. Sem alegar clone
completo nem ampliar para resistência/clima/itens/rede.

ADR-025 — adotada após revisão0.4: prever salvas com o mesmo avanço real sobre
máscara/atores isolados. Prever componentes separadamente no terreno inicial
perdia impactos após o primeiro abrir cratera; fixture com parede de2px verifica
passagem do segundo laser e ausência de mutação do modelo vivo (RED→GREEN).
