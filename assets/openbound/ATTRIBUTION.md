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
imagens geradas pelo projeto Brisa de Aço. O fork OpenBound não distribui o
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
