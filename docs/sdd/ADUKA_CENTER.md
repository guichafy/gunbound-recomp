# Aduka — piloto mais centralizado (ADR-123)

27/10/2026, REQ-02/19/20/45. Usuário aprovou a orientação da ADR-122, mas
solicitou aproximar o personagem do centro do mobile. Manter personagem à
direita/traseira de tiro à esquerda no lado A e espelho no B.

## Evidência e decisão

| Comportamento | Fonte/localização | Contrato/confiança | Decisão |
|---|---|---|---|
| Encaixe importado | `graphics.xfs/tank16.img`, quadro0: hotspot(-23,-34), campos extras2/3=(15,11) | Ponto bruto(-8,-23), confirmado na extração e no `RiderPivot.json` | Preservar fontes e metadados |
| Registro do avatar | `Rider.cs`: Body(0,0), Head(7,-17); `MobileSprite.draw` consome `rider_offset` para padrão/equipado | Código C#/Godot inspecionado; pontos de registro distintos da silhueta alpha | Mover o conjunto, sem compensar peças individualmente |
| Centralização solicitada | Pedido posterior e composição GPU da ADR-122 | Ponto idle X=-8 fica de lado do eixo0 do mobile | Adaptação visual: somar(+8,0) antes de escala/espelho/inclinação |
| Poses | `tank16.epa` e RiderPivot por quadro | Moving(-8,-22), recoilT2 começa(-11,-19), hurt(3,-38), using_item(-8,-20) | Somar a mesma constante; não zerar X de cada quadro nem usar centro alpha |

SHA-256 do XFS:
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
SHA-256 da entrada tank16.img:
`7130e022f6a3b62b9cbc1af94cc8f84a4db94edd6f897484d6905826cd2e7b44`.
Atlas importado:
`140fca8ce204813b6989fe676ce36ee1ec35948d7d4b4a5c69f8cb1131b6e88f`.
Leitura direta com `gunbound_xfs.py`; relatório local em
`.tools/aduka-center/source-evidence.json`. Sem execução do cliente original
ou alegação de que a compensação solicitada é nativa. Não é necessário
alterar ou reinterpretar uma regra do binário para esse ajuste de composição.

## Plano e aceite

1. Declarar `rider_adjust=(8,0)` só no Aduka em `MobileLooks`.
2. Aplicar em `ClassicSprite.rider_offset`, compartilhado por sala, arena,
   prévia da loja, piloto padrão e equipado; preservar `room_facing/rear`.
3. Capturar antes/depois na sala real A/B e seis poses nos dois sentidos,
   pausa/retomada e variantes padrão/HD; inspecionar encaixe visual.
4. Rodar regressões pertinentes, registrar resultados/limites e atualizar
   handoff/tarefas. Sem regras de combate, perfil real, versão, app ou push.

Aceite visual da centralização é separado da orientação já aprovada.

## Resultado observado

Implementação em `MobileLooks.rider_adjust` e `ClassicSprite.rider_offset`.
Fontes/metadata/atlas preservados. `scripts/check.sh` com classic_mobiles,
original_mobiles, avatar_mount/art/hd/continuity, room_ui, room_reference,
roster, scene e shop_wide: **1018 checks, 11 suítes, zero falhas, exit0**.
Logs em `.tools/check-logs`; sem partidas completas novas (só apresentação).

GPU M4 Pro fora do sandbox, `tests/capture_aduka_mount.gd`:
1920×1080, relógio60Hz, 150quadros, seis poses×dois sentidos×padrão/HD.
Pausa60..89 com pixels idênticos; primeiro quadro visual diferente após
retomada é92 (EPA20Hz, não uma imagem diferente a cada render60Hz).
Sequência completa local em `.tools/aduka-center/frames`. Sala real com A/B,
antes/depois no mesmo relógio, piloto padrão e Great Devil. Comparação em
`docs/aduka-center/before-after.png`, amostras temporais e JSON de validação
na mesma pasta. Sala e amostras inspecionadas; orientação da ADR-122 mantida.
Sem erro de script nos logs. Sem nova versão, app/PCK, commit ou push;
aceite visual da centralização pendente.
