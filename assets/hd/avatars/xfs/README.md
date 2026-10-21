# Avatares XFS HD0.17

550avatares reais,629camadas vestíveis (549bases/80L),532miniaturas novas.
As18miniaturas anteriores ficam em assets/hd/shop/xfs_portraits.json.
Catálogo em catalog.json, separado dos retratos da loja e das13peças C# antigas.

Arte regenerada por GPT Images seguindo gunbound-classic-hd. Referências,
prompts, brutos rejeitados/selecionados, jobs e ledger estão em source,
preservados e excluídos do Godot/export por .gdignore e pelo preset.
37lotes/38atlas:887×1774(25),1024×1536(11),1448×1086(1),1774×887(1reparo).
Maior dimensão útil de cada sprite:145–942px. FullHD é a renderização1920×1080.

AvatarXfsHD registra recorte e janela nativa uma vez. AvatarArt usa esses
masters no avatar vestido, com rig contínuo, material translúcido e efeitos
separados. Não se usa a miniatura do Shop como substituta da peça vestível.
Originais XFS/PNGs anteriores preservados; fallback integral por peça.

Controle e evidências: docs/avatar-hd-migration/index.html, migration.csv,
qa/runtime-audit.json, contatos GPU por lote e motion.mp4(360frames/60fps).
Doze registros não requerem arte: três acessórios vazios e nove placeholders
sem recurso original. A animação é adaptação HD, sem redesenho quadro a quadro.

Reproduzir controle: python3 scripts/prepare_xfs_avatar_hd.py.
Registrar geração revisada: python3 scripts/register_xfs_avatar_hd.py batch_NNN.
Depois da comparação GPU: mesmo comando com --qa. Hashes da arte, registro e
renderer precisam corresponder à evidência; geração isolada não concede aceite.
