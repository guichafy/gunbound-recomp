# Avatar Shop — design do cliente XFS 0.16

## Pedido e decisão

REQ-20/38/39. Referências indicadas: jglim/gunbound-server e gunbound-launcher.
Após a pergunta sobre catálogo/bônus, o usuário reforçou “use 100% o design xfs
e o que precisar para funcionar com esse pedido”. Implementar a composição
comprovada por Other/gb-avatar.png e pelos frames de graphics.xfs. Esta mudança
substitui o layout do vídeo (ADR-070). A interpretação inicial restringiu a
mudança ao design e manteve quinze registros; o usuário apontou isso como erro
em nova validação. **Interpretação substituída:** integrar o catálogo XFS completo,
preços e bônus por equipamento, com efeito real e visualização correspondente.

## Fontes verificadas

- Servidor commit 46af0e758643563666723efecd7a32a3debb939a: screenshot gb-avatar.png,
  gameserver.py User e comandos 0x6000/6004/6010/6011/6020/6030.
- Launcher commit 2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1: TestClient/avatar.xfs
  e graphics.xfs versão 280. Launcher inicia cliente; não desenha a loja.
- avatar.xfs: oito DATs, 562 registros, 479 marcados compráveis; campos reais
  de descrição/preço e oito bônus. Não equivalem aos quinze registros C#.
- graphics.xfs: 2384 arquivos; store_back/store_avatar/store_myavatar/store_icon
  e b_store_* são o layout ciano da captura. avatarmode.img contém um layout
  cinza antigo, preservado no mesmo pacote, mas não é o screenshot de referência.
- Extração somente leitura: LZHUF em blocos 4096, índice final em blocos 131072,
  frames IMG com dimensões/pivô e RGB565/RLE/ARGB4444. Originais preservados.

## Plano de implementação

1. Versionar extrator determinístico/validador e manifest de origem; preservar
   frames originais da loja e DATs sem modificar os XFS locais.
2. Portar a geometria clássica 800×600 para encaixe uniforme em Full HD;
   catálogo à esquerda, painel My Avatar à direita, grade 3×3, categorias,
   setas verticais, barras de saldo no topo, ações Try/Buy e ações de inventário.
   O canvas 4:3 ocupa 1440×1080 centralizado; fundo preenche as laterais.
3. Molduras, fontes e superfícies sólidas via desenho vetorial para nitidez;
   reutilizar arte HD aprovada onde a identidade coincide. Regenerar somente
   arte ilustrada necessária via gunbound-classic-hd/GPT Images; guardar brutos,
   prompts, dimensões reais e metadados; fallback aos frames XFS.
4. Preservar compra/vestir/preview transacionais e progresso. Identidades XFS
   separadas das antigas evitam converter um equipamento comprado em outro.
   Integrar modificadores assinados por peça ao snapshot do combate/previsão.
   Controles de rede/contas permanecem indisponíveis com explicação.
5. Atualizar testes de layout/input e executar regressões de cena/loja; GPU
   1920×1080 e sequência 60Hz; export macOS, assinatura e PCK isolado.

## Situação inicial e limites

Baseline 0.15.0 tem alterações não commitadas; preservá-las. Fonte C# intocada.
A revisão automática de uma tentativa adicional de download falhou por limite
 de uso; a cópia do servidor já autorizada terminou e forneceu a screenshot.
Resultados/pendências serão registrados ao concluir; não há validação da0.16 ainda.

## Correção do catálogo e atributos — plano em execução

REQ-38/39/40/41, além de REQ-20. Usar writing-plans/executing-plans e revisão
independente; sem commits/publicação neste checkout sujo.

- [x] Importar os 562 registros dos oito DATs com preços, disponibilidade,
  descrição e oito modificadores assinados. Decodificar retratos `s*.img` e
  peças `*.img`, conservar pivôs/quadros e registrar ausências reais do pacote.
- [x] Catálogo XFS ativo; namespaces separados preservam posses C# sem remapear
  IDs incompatíveis. Defaults válidos para ambos os gêneros; bandeiras compartilhadas.
  Compra respeita disponibilidade e preço nativo, sem saldo extra/migração destrutiva.
- [x] Render de peças XFS por metadados de cada frame, com registro Body constante,
  originais preservados, HD aprovado somente quando a identidade for equivalente.
- [x] Cards com retrato separado de até oito bônus; nomes limitados à própria área,
  saldo fora da busca, inventário com equipamento/atributos sem sobreposição.
- [x] Snapshot de batalha soma atributos do piloto e bônus de equipamento antes
  de aplicar as fórmulas locais existentes. Valores negativos permanecem negativos;
  não aplicar novamente o orçamento de pontos ao bônus. CPU/previsão compartilham regras.
- [x] Testes de catálogo real, restrições, persistência legada, somas, combate e
  snapshots; regressões anteriores com fixtures C# explícitas quando apropriado.
- [x] GPU FullHD, páginas/categorias/gêneros, equipamento/compra, vídeo60Hz,
  export macOS e smoke PCK. Registrar cobertura HD real e ausências sem inventar arte.

## Resultado observado da0.16

562registros/479compráveis ativos, 550registros com peças reais em629camadas;
três padrões sem peça e nove placeholders indisponíveis. Todos os compráveis
têm retrato e peça. Ghost tem somente camada L; Guild Flags sem miniatura usam
um quadro da própria peça. ff.dat é vazio; mf é compartilhado entre gêneros.

Namespaces XFS impedem colisão de IDs. Profile3 conserva saldo/XP/posses e
converte somente identidades verificadas: Pilot Goggles antigo1→XFS2. Kappa,
ausente do XFS, continua como legado possuído. Compra nativa debita preço real,
com rollback. Atributos somados por peça são copiados para a batalha, limitados
a50por atributo; orçamento do piloto não é gasto por equipamento. Penalidades
negativas também alteram o atraso. CPU e previsão usam o mesmo snapshot.

3163checks e10partidas completas passaram antes do último atlas de retratos.
Após integrar esse atlas:106checks dirigidos, oito testes Python e GPU passaram.
Capturas1920×1080/120frames60Hz em docs/avatar-shop-xfs; preço tem cor única
RGB0/131/179. Smoke do PCK fora do projeto passou:562registros, recursos,
compra/vestir/recarga/batalha e1280×800. App/ZIP0.16.0 assinados/reexportados.

Fundo1672×941 e18retratos em atlas887×1774 foram gerados com GPT Images e a
skill gunbound-classic-hd. As demais miniaturas e a maioria das peças vestidas
continuam no fallback original; somente as identidades do HD antigo foram
reaproveitadas. Isso **não constitui migração HD completa dos avatares**.
O usuário apontou essa lacuna e solicitou controle/migração integral; próximo
plano em AVATAR_HD_MIGRATION.md. Nenhum perfil real foi usado nos testes.
Revisão inicial encontrou destaque ausente no fallback, corrigido RED→GREEN.
Revisão final da integração foi interrompida por limite de uso do revisor;
checagem local e testes acima foram concluídos, sem segunda aprovação independente.
