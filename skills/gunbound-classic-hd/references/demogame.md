# Aplicação em Gunbound Recomp / DemoGame

Use este mapa apenas ao trabalhar no projeto correspondente. Localize a raiz
pela sessão; os caminhos abaixo são relativos a ela. A skill funciona sem
essa cópia do projeto para princípios de geração/registro/animação.

## Onde encontrar fonte e estado vigente

- Godot: `/Users/guichafy/Workspaces/DemoGame`; leia AGENTS.md e
  `docs/sdd/HANDOFF.md` → SPEC.md → DESIGN.md antes de alterar comportamento.
- C# OpenBound: `/Users/guichafy/Workspaces/Gunbound`, fonte de mecânicas,
  metadados e arte; não modificar a referência para ajustar um derivado.
- Originais integrados: `assets/openbound/`, `assets/xfs/` e `assets/classic/`;
  derivados: `assets/hd/`. `assets/classic/manifest.json` descreve as janelas
  e a ordem dos estados dos botões de lobby/sala. Use-o como metadado,
  mantendo cada PNG como sua única referência visual na restauração.
  Preserve originais, `.gd.uid` e `.png.import`. Brutos de geração ficam
  separados do runtime, usualmente em `source/` com `.gdignore`.
- Estado aprovado: composição e animação0.14.4 confirmadas pelo usuário.
  Documentos antigos guardam tentativas substituídas; ADR-063 prevalece sobre
  offsets de bbox por quadro da ADR-061. Não recuperar o tremor antigo.

## Código e metadados reutilizáveis

Botões do lobby/sala: acabamento bicúbico aprovado, ativo em
`assets/hd/classic/buttons_smooth_4x`. `scripts/classic_chrome.gd` converte só
recortes de textura; hitboxes/layout continuam nativos. Fontes em
`assets/classic`, derivados exatos anteriores em `buttons_4x`. Regenerar
a partir da fonte por quadro, nunca reamostrar o HD. Consultar
`docs/sdd/CLASSIC_BUTTONS_SMOOTHING.md` e ADR-101 para catálogo/validação.

Mobile original: Bigfoot usa o mesmo acabamento (ADR-104) em
`assets/hd/classic/mobiles_smooth_4x/bigfoot`, gerado por
`scripts/build_bigfoot_smooth_hd.py` a partir de `bigfoot/original` com a grade
do `frames.json`. `MobileLooks.smooth` liga por mobile; `mobile_smooth_art.gd`
valida o catálogo e `ClassicSprite` multiplica só recortes de origem. Para outro
mobile, gerar destino novo e repetir `test_bigfoot_smooth` adaptado.

| Tema | Implementação existente |
|---|---|
| Arte do avatar / fallback original | scripts/avatar_art.gd, avatar_hd.gd |
| Cabeça/corpo/óculos/bandeira e pivôs | assets/openbound/avatars/catalog.json |
| HD aprovado, recortes/hashes | assets/hd/avatars/catalog.json, GENERATION.json |
| Layout de referências para regenerar | assets/hd/avatars/source/layout.json |
| Montagem mobile/Body | scripts/mobile_sprite.gd, mobile_rig.gd |
| Interrupção e mistura por ator | scripts/battle_art.gd: presentation |
| Piloto não modular / partes do mobile | assets/hd/pilot_side.png, mobile_parts.png |
| Tiros, impactos e orientação | scripts/projectile_art.gd |
| Efeito derivado da anatomia (`overlay_base`) | scripts/build_devil_horn_light.py, avatar_xfs_hd.gd, tests/capture_horn_classic.gd |

Brilho do Great Devil (ADR-082, validado pelo usuário em 24/10/2026): o L
clássico é a silhueta do chifre. `build_devil_horn_light.py` deriva o PNG da
cabeça HD e registra `overlay_base`; rodar de novo após trocar a cabeça ou
reexecutar `register_xfs_avatar_hd.py batch_005`. Mudar `avatar_xfs_hd.gd` ou
`avatar_art.gd` altera `renderer_hashes`: recapturar os 37 lotes com
`tests/capture_xfs_hd_migration.gd -- batch_NNN`, registrar `--qa`, rodar
`tests/audit_xfs_hd_runtime.gd` e `prepare_xfs_avatar_hd.py`. Os outros 19
efeitos de cabeça ainda usam âncoras de luz gerada; aplique effects.md se o
usuário apontar forma errada neles.

Use os catalogadores existentes em vez de redescobrir o layout:

```sh
python3 scripts/catalog_avatar_hd.py
python3 scripts/catalog_hd_assets.py
```

Execute apenas o correspondente aos assets realmente alterados. AvatarHD
valida offsets legados para integridade do catálogo, mas **não os aplica**
como deslocamento em peças HD. Não reintroduzir a linha que traduz a peça
pelo centro alpha de cada quadro.

Para Shop, a prévia de item não possuído continua temporária. Vestir item
possuído usa Profile.equip transacional; game.start_match copia equipped_set.
Confira as quatro categorias após recarga de perfil/batalha quando mudar
esse fluxo. Não gerar catálogo, preços ou mecânicas novas como parte da arte.

## Verificação e aplicativo

Prepare `.tools/` e importe recursos em checkout novo. Regressões úteis:

```sh
./scripts/check.sh test_avatar_hd test_avatar_mount test_avatar_continuity test_mobile_animation test_pilot_projectiles test_avatar_shop
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_avatar_continuity.gd
```

A captura de continuidade atual gera360frames a60fps em1600×1080; não é
1920×1080. Para nova entrega Full HD, adapte o framebuffer/layout ou use uma
captura Full HD existente pertinente, preservando aspecto. Não renomear um
vídeo de outra resolução como Full HD.

Mudanças de cena/input também exigem testes de cena; regras de combate exigem
modelos e partidas completas. Perfis de teste isolados, nunca o perfil real.
Ao entregar aplicativo atualizado:

```sh
python3 scripts/build_macos.py
codesign --verify --deep --strict --verbose=2 'builds/Gunbound Recomp.app'
```

Confirme recursos no PCK exportado; rodar o projeto não atualiza o app pronto.
Registre REQs/decisão e evidências em SDD quando mudar o projeto. Não publicar
ou criar novos serviços como parte desse aprendizado.

Detalhes medidos: `docs/sdd/AVATAR_MOUNT_FIX.md`, AVATAR_HD.md,
AVATAR_SMOOTH_0_14_4.md, COMPOSITION_FIX_0_6_3.md, PILOT_SHOTS_FIX_0_6_2.md.
