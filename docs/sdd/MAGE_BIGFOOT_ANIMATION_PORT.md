# Porte dos tiros e animações Bigfoot/Mage — 0.20.4

REQ-04/07/08/09/12/19/44/45. Feedback após testar0.20.3: tiros e animações
relacionadas precisam acompanhar o porte dos atlas. Avatares/equipamentos,
16 IDs, perfil e originais preservados. Nenhuma nova geração HD.

## Fonte e diagnóstico

PE Thor's Hammer SHA256 4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde,
image base0x400000, VAs x86. XFS identificado nos manifests0.20.3. REA/Hopper
sobre cópia local do PE, sem executá-lo. Outra sessão já possuía o caminho
original; cópia byte-idêntica usada para não interrompê-la.

| Caminho | Contrato original / evidência | Lacuna0.20.3 |
|---|---|---|
| Mage T1 | Animate0x47ebc0, Publish0x47f1c0: histórico16/seções±8, fase0..7; cor0x0f80ffff no spawn0x42bbb0 | sprites16×16 de S1T estampados ao longo do trajeto |
| Mage T2 | Init0x4a46f0, Detonate0x4a4950, Animate0x4a6200, Publish0x4a6840: fases0/180, avanço40°, offset perpendicular13px truncado em pixel, seção±8 | hélice C#15px e estampas S2T |
| Raster Mage | Render0x4c45e4/0x4c47aa/0x4c490c: LaserEffect.xtf, flagtrue, UV1/16, fases T1=0..7/T2=8..15, v/16; dois triângulos/quad; alpha por byte nativo | não usa a textura/faixa do cliente |
| Bigfoot T1/T2/SS e MageSS | EPA e sprites já extraídos; salvas/grupos MainAction já ativos; MageSS chama ssflame2 em0x48d8e0 | Bigfoot ainda recebe linha genérica de rastro sobre as bombas |
| Poses e eventos | tank2/tank5 EPA: durações próprias para hurt/hurt_2/drop/shock/item/dead; render usa suporte e quadros | BattleArt interrompe poses com timers C# e adiciona rotação/fade genéricos na morte |

Onda/colisão Mage usa heading pré-aceleração, seção usa heading pós, como
ordem move→Detonate/Simulate→Animate na vtable. Não acumular offset no carrier.
O original inicializa fase com a paridade do componente (flags0/1); o segundo
componente recebe cor0x0fff80ff, não a cor roxa do fork. Colisão/dano refinados,
clima/tornado permanecem adaptações já declaradas; não anunciar porte integral.

## Plano de implementação

Execução nesta sessão, seguindo o pedido atual; sem commit/push.

- [ ] Testes RED independentes: onda13px/40°/fases, UV/cor/alpha/seções,
      timers EPA, morte sem rotação/fade e rastro genérico ausente no Bigfoot.
- [ ] `scripts/mage_flight.gd`: prepare/hit_point/finish_tick puros no passo
      real/previsão; estado/sections privados por shell, sem IO no worker.
      Integrar em classic_flight, ShellState e catálogo Mage; preserva dano.
- [ ] `scripts/mage_projectile_art.gd`: segmentos/triângulos com LaserEffect
      original, 16colunas, 15segmentos, seções interpoladas somente em cópia.
      ClassicMageSprite usa essa faixa em T1/T2 e mantém SS/impactos originais.
- [ ] Tempos em ClassicSprite.pose_duration; BattleArt recebe o sprite no
      tick/eventos e usa EPA nos dois mobiles. Retirar overrides genéricos de
      morte/dano e rastro extra desses dois; demais mobiles/HD preservados.
- [ ] Testes dirigidos, harness com29partidas, capturaGPU de tiros reais e
      poses/ciclos/pausa/sentidos; export0.20.4 e smoke/assinatura/PCK.

Foco da revisão: Dual/Dual+ e teleport não herdam onda indevida; tempo de
pausa congela histórico/pose; arma trocada não troca recuo; zero velocidade e
força mínima aceitam quads cruzados; final de hurt/dead não corta o último
quadro. Fixtures da parede Mage podem mudar devido à onda nativa; registrar.

## Resultados

A preencher com resultados observados, incluindo limitações visuais/áudio/input.
