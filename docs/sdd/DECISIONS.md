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
