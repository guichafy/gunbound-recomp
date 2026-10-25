# Origem dos recursos Bigfoot e Mage

Arquivos copiados sem edição do pacote `Game Assets.rar`, fornecido pelo usuário
via [Google Drive](https://drive.google.com/drive/folders/120agUFRkAARqZNHYxB7NS86VtrPstx-K).
Originais preservados em `.tools/source-assets/content/Graphics/Tank/Bigfoot/`.

- `bigfoot/CharacterSpritesheet.png` — atlas original RGBA 2580×3120.
- `bigfoot/Bullet1.png`, `Bullet2.png`, `Bullet3.png` — projéteis originais.
- `bigfoot/RiderBody.png`, `RiderHead.png` — Body/Basic e Hat/Basic masculinos,
  copiados de `Graphics/Avatar/Male/`; piloto padrão composto por camadas.
- `bigfoot/RiderPivot.json` — offsets por quadro copiados do fork, sob seus avisos
  GPL, mantidos sem alterações no arquivo. O leitor aceita sua vírgula final.

Recursos visuais de Gunbound, atribuídos a seus titulares originais; não são
imagens geradas pelo projeto Gunbound Recomp. O fork OpenBound não distribui o
pacote de texturas nem o identifica como arte licenciada sob GPL.

Intervalos de quadros, dimensões e FPS referenciados de
[OpenBound MobileFlipbook.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Animation/MobileFlipbook.cs).
Copyright (C) 2020, Carlos H.M.S. <carlos_judo@hotmail.com>.
Os avisos GPL-3.0-or-later desse código estão preservados em
`OPENBOUND_CODE_LICENSE.GPL` e no leitor de atlas. Não confundir a licença do
código de referência com a origem dos sprites.

A integração é um protótipo local. Não houve publicação nem upload dos assets.
O restante dos recursos baixados ainda não foi incorporado ao jogo.

## Mage (0.4)

- `mage/CharacterSpritesheet.png` — atlas original 2180×3150, células 109×150.
- `mage/S1T.png`, `S2T.png`, `Bullet3.png` — lasers/trilhas e orbe originais.
- `mage/Flame1.png`, `Flame2.png`, `Flame3.png` — efeitos de impacto originais,
  copiados de `Graphics/Special Effects/Tank/Mage/`.
- `mage/ShootS1.mp3`, `ShootS2.mp3`, `ShootSS.mp3`, `BlastS1.mp3`, `BlastS2.mp3`,
  `BlastSS.mp3` — áudio original de `Audio/SFX/Tank/{Shoot,Blast}/Mage*.mp3`.
- `mage/RiderPivot.json` — offsets originais do mesmo commit do fork; piloto
  reutiliza as camadas masculinas já presentes em `bigfoot/`.

Hashes e caminhos exatos em `SOURCE_MANIFEST.json`. Arquivos PNG/MP3/JSON intactos.
Regras Mage baseadas em MobileMetadata, MageProjectile e HelicoidalTrace do fork;
valores/adaptações registrados em `docs/sdd/MAGE_0_4.md`. Os avisos de autoria e
licença do código de referência acima também se aplicam a esses dados.

## Ataques Bigfoot (0.5)

Seis sons `bigfoot/{Shoot,Blast}{S1,S2,SS}.mp3` copiados de
`Audio/SFX/Tank/{Shoot,Blast}/Bigfoot*.mp3`. Efeitos:
`bigfoot/Flame1.png` e `Flame3.png` de `Graphics/Special Effects/Tank/Bigfoot/`;
`bigfoot/Flame2.png` vem de `Graphics/Special Effects/Tank/Armor/Flame2.png`.
Essa origem diferente do T2 reproduz a chamada ArmorProjectile2Explosion
executada em BigfootProjectile2.cs. Não substituir silenciosamente pelo método
BigfootProjectile2Explosion não usado. As três imagens têm20 quadros reais;
SS limita ao tamanho real, apesar do fim29 na referência. PNGs/MP3s intactos,
hashes/caminhos exatos em SOURCE_MANIFEST. Emitter/dados de referência e
adaptações em `docs/sdd/BIGFOOT_ATTACKS_0_5.md` e `scripts/bigfoot_attacks.gd`.

## Mapa Miramo Town (0.8)

- `maps/miramo_town/ForegroundA.png` — foreground original 1800×1800 RGBA de
  `Graphics/Maps/MiramoTown/`; o alpha é a máscara de colisão do jogo.
- `maps/miramo_town/Background.png` — fundo original 1300×1300; fallback do
  fundo HD.

Dados do mapa (ID20, tipo A, clima, 11 spawn points) e a regra de erosão vêm de
`Map.cs`, `Topography.cs`, `LevelScene.cs` e `RoomMetadata.cs` do OpenBound,
copiados em `scripts/maps.gd`/`scripts/terrain.gd` com aviso GPL. Derivados HD
GPT Images em `assets/hd/maps/miramo_town/`. Arquivos originais intactos.

## Clima, Thor e partícula (0.9)

- `weather/` — colunas Force/Tornado/Electricity/Weakness/Mirror/Random,
  partículas ForceParticle/ElectricityParticle, raio LightningSE e ícones do
  WeatherDisplay (`Interface/InGame/HUD/Blue/WeatherDisplay/Weather.png`);
  sons Mirror, WindTransition e LightningS1.
- `thor/` — Spritesheet 14×4 (197×190), ThorLaser e som AdukaS2.
- `maps/miramo_town/Particle.png` — partícula de chão 20×3 (48×48).

Regras de clima, vento e Thor portadas de `MatchMetadata.cs`,
`WeatherDisplay.cs`, `WeatherHandler.cs`, `WeatherEffect/*.cs`,
`ThorSatellite.cs`, `BeamDummyProjectile.cs` e `ParticleBuilder.cs` (GPL).
Arquivos copiados sem edição; SHA-256 em `SOURCE_MANIFEST.json`.

## HUD de batalha (0.10)

- `hud/` — barra de ação (`Interface/InGame/HUD/Blue/ActionBar/*`), botões
  ShotSelector/Options/SkipTurn (`Interface/StaticButtons/HUD/Blue/*`), bússola
  (`WindCompass/*`), moldura do clima, balão do relógio, moldura de vida, mira
  (`Interface/InGame/HUD/Crosshair/CrosshairFrame`, `Pointer` e as faixas
  Mage/Bigfoot S1/S2/SS Ally/Enemy), fontes numéricas
  (`Interface/Spritefont/HUD/Blue/*`) e o som `ClockSecond`.

Layout, estados de botão, carga e mira portados de `HUD.cs`, `Crosshair.cs`,
`WindCompass.cs`, `Delayboard.cs`, `HealthBar.cs`, `ProgressBar.cs`,
`SpriteNumericField.cs`, `Button.cs`, `ShotButton.cs` e `Mobile.cs` (GPL).
Arquivos copiados sem edição; SHA-256 em `SOURCE_MANIFEST.json`. Derivados HD
GPT Images em `assets/hd/hud/`.

## Itens de batalha (0.13)

Copiados sem edição de `.tools/source-assets/content/` para `items/`:

- `ItemDual.png` … `ItemEnergyUp1.png` — 11 botões de
  `Interface/StaticButtons/Popup/SelectItem/` (renomeados com prefixo `Item`).
- `MatchStatus.png` (`Interface/InGame/HUD/Blue/ActionBar/`),
  `SelectItemBackground.png` (`Interface/Popup/Blue/SelectItem/Background.png`),
  `TabIndex.png` (`Interface/StaticButtons/AvatarShop/`).
- `TeleportBullet.png` (`Graphics/Tank/Common/`), `Teleport1.png` e
  `Teleport2.png` (`Graphics/Special Effects/General/`).
- `ShootTeleport.mp3` / `BlastTeleport.mp3` — `Audio/SFX/Tank/{Shoot,Blast}/Teleport.mp3`.

Regras de `Item.cs`, `Mobile.cs`, `MatchManager.cs`, `HUD.cs`, `EquippedButtonBar.cs`,
`PopupSelectItem.cs` e `GenericProjectile.cs` do mesmo fork (GPL-3.0-or-later).
Hashes em `SOURCE_MANIFEST.json` (chaves `items/…`). Derivados HD em `assets/hd/items/`.
## Shop e avatar

Os sprites do Shop, 13 atlas de avatar e15 retratos vieram de
OpenBound-Assets/Game Assets, nas quatro categorias Hat/Body/Goggles/Flag.
Catálogo normalizado conserva preços/IDs/pivôs da DatabaseSeed original.
assets/openbound/avatars/manifest.json lista os caminhos fonte e SHA-256 dos
80 arquivos copiados, com pixels intactos. Não são derivados GPT Images.
Regras portadas do código OpenBound GPL-3.0-or-later, Copyright2020 Carlos H.M.S.

## Nak (0.15)

O fork OpenBound não tem arte nem classe do Nak. Copiados sem edição do fork:
`nak/RiderPivot.json` (`ContentMetadata/Mobile/Nak`), `nak/Shoot{S1,S2,SS}.mp3`,
`nak/Blast{S1,S2,SS}.mp3` e `hud/CrosshairNak{S1,S2,SS}{Ally,Enemy}.png`.
Sprites do cliente original GunBound Thor's Hammer (Softnyx), `TestClient/graphics.xfs`
de [jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher), extraídos
por `scripts/import_nak_assets.py` com leitor próprio; formato documentado por
[colemancda/GunBound-Decomp](https://github.com/colemancda/GunBound-Decomp):
`nak/CharacterSpritesheet.png` (`tank3.img`), `nak/Bullet1.png` (`bullet3n`),
`nak/Bullet1Light.png` (`bullet3nl`), `nak/Bullet2.png` (`bullet3s`),
`nak/Bullet2Light.png` (`bullet3sl`), `nak/Bullet3.png` (`bullet3pl`),
`nak/Flame1/2/3.png` (`flame31`, `flame32`, `ssflame3`). Pixels intactos, só
reposicionados em células pelo hotspot de cada quadro; `nak/frames.json` guarda
células, origens e o `tank3.epa`. Hashes em `SOURCE_MANIFEST.json` (`nak/…`).
Recursos visuais de Gunbound, atribuídos a seus titulares; uso local de protótipo.


## Restauração Bigfoot/Mage (0.20.3)

`mage/original/` e `bigfoot/original/`: tank2/tank5 e seus projéteis, luzes,
impactos, EPA e RiderPivot extraídos sem modificar pixels de
jglim/gunbound-launcher TestClient/graphics.xfs. SHA-256 do arquivo:
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Importador: scripts/import_classic_mobiles.py --only mage / --only bigfoot.
Metadados por folha incluem entrada e hash do payload. S1T/S2T de Mage são
as texturas originais OpenBound já atribuídas acima; composição atual mantida.
Fontes anteriores e derivados HD preservados. Ver ADR-089 e
docs/sdd/ORIGINAL_MAGE_BIGFOOT.md.


### Mage LaserEffect0.20.4

`mage/original/LaserEffect.png` é a conversão ARGB4444 sem perda do payload
`LaserEffect.xtf` do mesmo graphics.xfs acima. Manifesto em frames.json/ribbons.
Composição/faixas/onda e poses: docs/sdd/MAGE_BIGFOOT_ANIMATION_PORT.md.
S1T/S2T e todos os derivados HD anteriores continuam preservados.
