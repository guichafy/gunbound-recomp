# Mage — substituição do segundo veículo, versão 0.4

Pedido: o outro carro deve corresponder ao Mage do Gunbound, usando os assets.
REQ-19: substituir Carapaça (índice 1) por Mage, mantendo Bigfoot pequeno (60)
e perfil/offline 1×1. Mage é selecionável; o adversário do Bigfoot é Mage.

## Fonte e comportamento definido antes do código

Fork `cb2fc197dd6b0498390219750ca6251bf0582d63`, `Unit/Mage.cs`,
`UnitProjectiles/MageProjectile.cs`, `HelicoidalTrace.cs`, `MobileMetadata.cs`,
`MobileFlipbook.cs` e `SpecialEffectBuilder.cs`; assets do pacote já recebido.

- Atlas original 2180×3150, células 109×150, pivô (52,85), piloto/offsets originais.
  Render em escala próxima à do Bigfoot reduzido; movimento, carga, tiros, dano,
  pouca vida e morte com os intervalos/FPS do fork. PNGs intactos.
- 760 HP + escudo inicial 220; movimento 90; escudo absorve explosões antes da
  vida. Regenera 20 no início do turno próprio, até `760 - HP + 220`, como o fork.
  Queda continua causando dano de vida/eliminando; escudo não impede cair.
  **Substituído (ADR-076):** 730 HP e 30 de regeneração do escudo
  (`characterdata.dat`), em todo início de turno (ADR-066); queda curta não fere.
- Mira local 15–50°, S1 um laser (150/raio25), S2 dois lasers em hélice (200 por
  componente/raio25), SS orbe com explosão e EMP que zera escudo até raio100.
- O construtor executado de SS no fork usa dano S2=200, embora exista constante
  SS=300 não usada. Para reproduzir o projeto indicado, manter **200**, registrar
  a divergência e não inventar o valor 300 silenciosamente.
- Hélice: componentes em fases 0/π, deslocamento perpendicular 15, período 1 s.
  Colisão, trilha e previsão da CPU usam o mesmo deslocamento em passo fixo.
- Delays do Mage 750/900/1300 convertidos por 7,5 para as unidades atuais da fila:
  100/120/173,333. Proporções originais, sem tornar Mage 7,5 vezes mais lento que
  os veículos atuais. Gravidade/força/vento horizontal continuam adaptados à arena
  do protótipo (substituído pelo ADR-076: números do C#, gravidade 196); não declarar equivalência integral do cliente C#/Gunbound.
- SS mantém a disponibilidade atual (terceiro turno próprio, uma vez por partida).
  Interações com itens, clima especial/Thor e tabelas de resistências ficam fora.
- Sprites de lasers/orbe/explosões e seis sons de disparo/impacto originais.
  HUD mostra escudo; informações de arma/delay e previsão consultam o modelo.

## Plano

1. Testes RED: Mage no catálogo, HP/escudo, absorção/regen/EMP, S2 duplicado,
   mira, delays, colisão/previsão na hélice e seleção de sprite/quadros.
2. Extrair leitor de atlas configurável de Bigfoot sem mudar seus quadros; criar
   perfil Mage com dados reais, copiar só assets usados e preservar proveniência.
3. `MatchModel.weapon_rules/aim_limits/predict_shot` fornecem regras por ator;
   atualizar voo, explosão, CPU e fila usando as mesmas funções de combate.
4. Integrar Mage no menu/arena, escudo, trilhas/Fx/áudio originais e poses da CPU.
5. Suites existentes + Mage, partidas completas, revisão independente, capturas,
   exportação 0.4.0/assinatura/startup, SDD e commit/tag local.

Riscos a verificar: dupla hélice pode atingir em momentos diferentes; não encerrar
voo com componente vivo. Previsão não pode gastar escudo nem alterar terreno/RNG.
Pausa congela os offsets/trilhas/animações. Renascimento limpa escudo e efeitos.
Explosões do atlas têm índices finais no fork fora da imagem: limitar ao tamanho
real, sem acessar quadros vazios. Perfil real não é usado em testes/capturas.

## Verificação e revisão

Mage36 checks (inclui atlas e parede) + cena15 checks; suites anteriores130,
total181, zero falhas. Oito partidas naturais seeds81–88:24/10/8/17/17/8/29/19
 tiros, todas encerradas. Revisão identificou previsão independente dos dois
lasers: o primeiro pode abrir passagem para o segundo. Corrigido com RED→GREEN;
salvas usam o voo real em cópias isoladas da máscara e atores, incluindo dano e
remoção de atores mortos. Previsão não altera terreno/escudo/HP reais. Cópia de
terreno não cria textura GPU. Tiros simples mantêm caminho rápido compartilhado.

Cena cobre mira/HUD/escudo, carga S2, recuo, reinício, morte completa, carga da CPU
e pausa dos dois colliders/trilhas. Capturas reais em `docs/mage-*.png`; impacto
é condição controlada para verificar Fx. Sem validação manual completa de mouse.
