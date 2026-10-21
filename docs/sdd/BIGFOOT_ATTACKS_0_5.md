# Bigfoot T1/T2/SS — especificação e plano 0.5

Pedido atual: identificar no C# e assets recebidos os tiros reais do Bigfoot e
implementar as diferenças. Escopo: REQ-03–08, REQ-09 (pausa), REQ-19; offline,
mesma escala arena60/menu180 e perfil local. Mage permanece implementado.

## Dados da referência

Fork Chafy-Studio/_OpenBound, commit cb2fc197dd6b0498390219750ca6251bf0582d63:
`Pawn/UnitProjectiles/BigfootProjectile.cs`, `Common/Parameter.cs`,
`MobileMetadata.cs`, `MobileAction/Projectile.cs`, `Interface/ProgressBar.cs` e
`Animation/SpecialEffectBuilder.cs`. Pacote recebido em `.tools/source-assets/`.

| Tiro | Salva, relativa ao momento de disparo | Dano por bomba / raio | Mira | Atraso |
|---|---|---|---|---|
| T1 | 4 bombas: 0 / 0,2 / 0,4 / 0,6 s; ângulos locais +3 / −3 / 0 / 0° | 90 / 25 | 18–40° | 770 / 7,5 |
| T2 | 6 bombas: duas rajadas de3 em 0,2 e0,4 s; força −4 / 0 / +4 pontos em cada rajada, mesmo ângulo | 70 / 25 | 18–40° | 920 / 7,5 |
| SS | 8 bombas: 0 até0,875 s, intervalo0,125 s; ângulos +3 / −3 / 0 / 0°, repetidos | 90 / 25 | 23–35° | 1320 / 7,5 |

Força C# é intensidade0–100, não largura400 da imagem da barra. Portanto T2 usa
±4 pontos percentuais, após limitar a entrada15–100; componente pode ficar11–104.
A dispersão angular ocorre após limitar a mira base (não comprimir ±3 nas bordas).
Todos nascem na mesma boca de canhão e envelhecem apenas depois do lançamento.
T1/T2/SS usam Bullet1/2/3 com células63×40 / 18×15 / 69×35, FPS20 já presentes.
Sons BigfootS1/S2/SS de Shoot e Blast. T1 usa Flame1 Bigfoot; SS usa Flame3 Bigfoot.
T2 executado no C# chama **ArmorProjectile2Explosion**, não o método Bigfoot2:
usar Armor/Flame2 (175×183), registrar a diferença. Clamp de frames ao tamanho
real das imagens: BigfootFlame3 tem20 quadros, embora o fork solicite30.

## Adaptações explícitas

Manter gravidade260, vento horizontal×1,5 e força/escala da arena do protótipo
(substituído pelo ADR-076: gravidade 196, força × 100 / 14, vento 2D × 1,2).
Não portar física mundial inteira, resistências, clima/Thor, itens ou regenHP35.
Delays seguem conversão÷7,5 adotada para Mage. SS continua terceiro turno próprio,
um uso por partida. Perfil/XP não mudam. Não anunciar clone completo Gunbound.

## Arquitetura e plano de execução inline

`match.gd` controla regras por veículo e agendamento das bombas no passo120Hz.
Projéteis pendentes não se movem, colidem, envelhecem, emitem áudio ou aparecem.
Voo termina apenas quando não há bomba viva nem pendente. CPU simula a salva
inteira com o mesmo avanço real em máscara/atores isolados, incluindo crateras.
`game.gd`/BigfootSprite apresentam apenas bombas lançadas, Fx e áudio originais.
HUD usa mira por arma; selecionar SS ajusta18–40 para23–35 e limita valor.

- [x] Testes RED de séries/intervalos, rajadas, forças/ângulos nos dois sentidos,
  danos/escudo, espera com bombas pendentes, previsão/live após crateras, limites.
- [x] Perfil Bigfoot e fila temporal no modelo; CPU e preview usam regras próprias.
- [x] Copiar só efeitos e seis áudios usados, com hashes/avisos e pixels intactos.
- [x] HUD/sons/Fx/render sem antecipar bombas; cena cobre pausa/soltura/reinício/SS.
- [x] Suites completas, partidas com os dois lados Bigfoot, revisão independente,
  capturas T1/T2/SS, app/ZIP0.5.0 Universal, assinatura/PCK/startup.
- [x] Atualizar SDD/README/AGENTS, Git/tag local.
- [ ] Validação funcional do usuário.

Focos de revisão: intervalos exatos apesar do delta de frame; bomba pendente após
primeira explosão; perturbações de tiro preservadas nas bordas de mira/força;
projeção em encostas/duas direções; CPU e resultado aguardam a salva completa.

## Resultados observados

56 checks de ataques +14 de cena, somados às suites anteriores181:251 sem falhas.
Dez partidas seeds81–90 concluíram em17/10/8/7/10/8/15/9/11/20 tiros. Revisão
independente aprovou fontes/hashes e72 cenários adicionais de previsão/live.
Pausa/retomada, limites por tiro, carga/soltura tardia, reinício e espera por
bombas pendentes verificados. Capturas reais em docs/bigfoot-{t1,t2,ss}.png.
App/ZIP0.5.0 Universal assinado e runtime/PCK verificados sem erros; sem teste
manual completo de mouse/áudio. Aceitação funcional permanece com o usuário.
