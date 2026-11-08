# Auditoria dos avatares clássicos — 08/11/2026

Estado anterior à implementação: o pedido posterior de acesso às67 peças e
lista mista foi atendido pela ADR-157. Ver `AVATAR_OFFLINE_ACCESS.md` para o
comportamento atual; contagens/fontes/evidência desta auditoria permanecem.

## Conclusão

**Não faltam registros nem camadas de avatar a migrar do TestClient Thor’s Hammer
280 disponível em `GunboundClassic`.** Os 562 registros estão nos dois catálogos
do porte; os 479 vendáveis têm arte e retrato. A auditoria de pixels verificou
10.466 quadros de 629 camadas e os 534 retratos existentes como `s*.img` no XFS,
sem divergências. Os demais retratos são fallbacks do importador, não imagens
nativas adicionais.

Há dois motivos comprovados para a oferta parecer menor:

1. **67 peças não padrão, com arte já migrada, ficam fora da venda** porque o
   byte de disponibilidade do DAT é zero. Incluem Skeleton, Soccer Hat,
   Friendship A, Ballroom Suit/Dress, High School Band, Clown Custom,
   Birthday Hat, Black Noodle, Orbiting Moon, Skeleton Sword e bandeiras.
   São registros por peça/gênero, não 67 conjuntos completos.
2. **O porte filtra pelo gênero selecionado; o cliente lista os dois gêneros**,
   priorizando o gênero do jogador. Esta diferença de apresentação é uma
   adaptação existente, não perda de assets. Trocar o gênero no controle
   lateral da loja permite consultar as peças do outro gênero no porte.

A galeria [hidden-native-records.png](../avatar-catalog-audit/hidden-native-records.png)
mostra todos os 67 registros. A lista completa, inclusive padrões e lacunas da
fonte, está em [inventory.json](../avatar-catalog-audit/inventory.json).

## Escopo e procedimento

Pedido: investigar a sensação de avatares ausentes a partir de uma worktree,
usando Ghidra. Requisitos relacionados: **REQ-38..41/46/47**, ADR-089/130/132.
Esta entrega contém auditoria e evidência; não muda loja, perfil, preços,
catálogos, render, versão ou aplicativo.

Worktree: `codex/avatar-catalog-ghidra-audit`, criada sobre `main` local
(`HEAD` antes da investigação; SHA registrado em `provenance.json`). Os arquivos
ignorados XFS/DAT foram ligados às fontes locais para preparar o checkout.
A importação Godot foi executada antes dos testes; nenhum perfil real foi usado.

Comparação: diretório real `~/Workspaces/GunboundClassic/gunbound-launcher/TestClient`,
cópia local `.tools/gunbound-client`, DATs de `GunboundClassic/avatar-xfs`,
`assets/xfs/avatars/{classic,catalog}.json`, todos os recursos de avatar do índice
de `graphics.xfs` e consumidores de catálogo/loja/render do Godot.
Nenhuma fonte de outra edição do jogo foi usada.

## Fontes fixadas

| Arquivo | SHA-256 |
|---|---|
| `GunBound.gme` (1.815.040 bytes) | `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde` |
| `avatar.xfs` (22.968 bytes) | `829be830e0c50c273d5e0ece03c22fbe0c45e07527129e60e8843d16a1df0e6d` |
| `graphics.xfs` (90.913.019 bytes) | `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08` |

Launcher local: commit `2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1`.
Servidor local: commit `46af0e758643563666723efecd7a32a3debb939a`.
Os três arquivos do TestClient e da cópia de trabalho têm os mesmos hashes.
Os dados extraídos e o `avatar.xfs` do diretório `avatar-xfs` também foram
conferidos pela suíte Python. Hashes das fontes preservados após a auditoria.

## Cobertura por DAT

| DAT | Categoria | Registros | Vendáveis | Fora de venda |
|---|---|---:|---:|---:|
| `mh.dat` | Cabeça masculina | 77 | 70 | 7 |
| `fh.dat` | Cabeça feminina | 81 | 74 | 7 |
| `mb.dat` | Corpo masculino | 78 | 69 | 9 |
| `fb.dat` | Corpo feminino | 78 | 72 | 6 |
| `mg.dat` | Olhos masculino | 37 | 34 | 3 |
| `fg.dat` | Olhos feminino | 37 | 34 | 3 |
| `mf.dat` | Bandeiras compartilhadas | 174 | 126 | 48 |
| `ff.dat` | Sem registros | 0 | 0 | 0 |
| **Total** | | **562** | **479** | **83** |

Dos 83 registros fora da venda, 7 são padrões: 4 com arte (cabeça/corpo dos
2 gêneros) e 3 vazios (olhos dos 2 gêneros e bandeira). Restam **67 com arte**
e **9 sem arte no próprio XFS**. Portanto 550 registros têm camadas e 12 não
têm. As nove ausências não são peças esquecidas pelo importador:

| Chave | Nome DAT | Imagem ausente na fonte |
|---|---|---|
| `xfs:0:1:61` | `.` | `mb00061.img` |
| `xfs:0:1:62` | `.` | `mb00062.img` |
| `xfs:0:1:63` | `.` | `mb00063.img` |
| `xfs:2:3:84` | `84` | `mf00084.img` |
| `xfs:2:3:85` | `85` | `mf00085.img` |
| `xfs:2:3:86` | `86` | `mf00086.img` |
| `xfs:2:3:87` | `87` | `mf00087.img` |
| `xfs:2:3:88` | `88` | `mf00088.img` |
| `xfs:2:3:163` | `lucky` | `mf00163.img` |

## O que o Ghidra comprovou

Ghidra **12.2**, Java **26**, headless direto. PE x86 little-endian, image base
`0x00400000`; endereços abaixo são **VA**, não offsets de arquivo. Extratos
reproduzíveis em [ghidra/](../avatar-catalog-audit/ghidra/) incluem ASM, C,
referências, manifestos e comandos/hashes. O pseudocódigo tem convenções
internas incompletas; as conclusões abaixo também foram conferidas no ASM.

| Consumidor | Evidência | Conclusão / confiança |
|---|---|---|
| `0x00423bf0` | Abre `fb/fh/fg`, zera o contador de bandeiras femininas e abre `mb/mh/mg/mf`; lê contagens de 4 bytes | Sete tabelas ativas; `ff.dat` não fornece uma segunda coleção de bandeiras. **Comprovada** |
| `0x004240c0` | `0x004241f4`: `IMUL EDX,EDX,0x84`; `0x00424206`: lê `0x84`; `0x0042426a/7e`: byte do registro +27 → objeto +`0x23b` | Registro 132 bytes, disponibilidade no byte 27. **Comprovada** |
| `0x00449540` | `0x004496e8`, `0x004497b9`, `0x004498e9` chamam leitor para ambos os gêneros; `TEST AL,AL` e `JZ` depois de ler o campo +`0x23b` | Só adiciona registros com disponibilidade não zero. Ordem depende do gênero do jogador; lista ambos. **Comprovada estaticamente** |
| `0x00447760` | Entrada pela vtable `0x00555614`; chama inicialização `0x00423bf0` e lista `0x00449540` | Rotinas fazem parte do caminho de abertura da loja. **Comprovada** |
| `0x00423e20` | `AND 0x8000` / `AND 0x7fff`, lê DAT e verifica id | Identidade de gênero/id e resolução dos itens do inventário; sem inventar um id ausente. **Comprovada** |

A autoanálise não reconheceu `0x00447760` inicialmente. A consulta parcial
`loader` tem `ok=false` e não é usada como resultado integral aprovado. Entrada
confirmada pelos bytes `51 53 55 56 57 68 10 27 00 00` e ponteiro little-endian
`60 77 44 00` na vtable; depois seeding explícito no banco. `shop-init` e as
consultas finais `strings/catalog/shop-filter/shop-list` têm **ok=true** nos
manifestos do runner e do exportador. Nenhum seeding alterou o PE. Os logs
do Java registram `OS Truststore load failed: X509 trusted CA certificates
not found`; é uma ressalva ambiental do truststore, sem erro de análise ou
decompilação nessas consultas locais. Nenhum certificado foi alterado.

## Diferenças de exibição no porte

`avatar_catalog.gd:items` limita as peças ao gênero atual e às compartilhadas.
`avatar_shop_model.gd:filter` retira `buyable=false`, pagina de 9 em 9 e não
trunca a coleção. `avatar_shop.gd:refresh` habilita as setas conforme a página;
`toggle_gender` troca o conjunto e volta à primeira página.

| Categoria | Loja atual masculina | Loja atual feminina | Soma dos registros únicos vendáveis |
|---|---:|---:|---:|
| Cabeça | 70 / 8 páginas | 74 / 9 páginas | 144 |
| Corpo | 69 / 8 páginas | 72 / 8 páginas | 141 |
| Olhos | 34 / 4 páginas | 34 / 4 páginas | 68 |
| Bandeira | 126 / 14 páginas | 126 / 14 páginas | 126 (compartilhadas) |

O gênero único reduz a coleção visível de cada vez: 299 registros para masculino,
306 para feminino, contra 479 únicos considerando ambos. O filtro de venda
coincide com o cliente; o filtro de gênero não reproduz a listagem mista nativa.

Não existe concessão/evento offline exposto para receber os 67 registros
não padrão e não vendáveis. Estarem no catálogo permite resolver equipamento,
mas não cria um caminho de aquisição. A fonte não prova como cada um era
obtido no serviço original; não os rotular automaticamente como recompensas
ou itens de evento. `Profile.purchase` e o botão de compra também rejeitam
não vendáveis. Nenhum saldo, posse ou flag foi alterado nesta investigação.

## Imagens extras e versão

A varredura integral de nomes de peças e retratos em `graphics.xfs` encontrou
somente **`ff00001.img` e `sff00001.img`** sem registro DAT. É uma bandeira
vermelha e sua miniatura, vistas em
[unlisted-native-graphics.png](../avatar-catalog-audit/unlisted-native-graphics.png).
A tabela feminina está vazia e o leitor de bandeira força `mf`; não há nome,
preço/status/registro que comprove um item adicional de loja. Não criar um
novo avatar a partir dessas duas imagens.

O exemplo `8F800100` (Love Cupid, cabeça masculina id 143) aparece no servidor
`jglim`, inclusive no inventário de exemplo `saneusername`. Mas `mh.dat` vai
até 76 e nenhum recurso `mh00143` existe neste TestClient. O servidor não
fornece esse asset nem prova sua presença nesta build. Essa referência não
é justificativa para inventar/importar um item de outra edição.

## Reprodução e validação

O script de auditoria só lê o projeto/fontes e exige um diretório novo para
saída. Usa os decodificadores XFS/IMG existentes, não é um segundo decoder
independente; o layout e o filtro foram corroborados separadamente no ASM.

```sh
python3 docs/avatar-catalog-audit/audit.py \
  --project "$PWD" \
  --client /Users/guichafy/Workspaces/GunboundClassic/gunbound-launcher/TestClient \
  --output /private/tmp/avatar-audit-new-run --pixels
python3 -m unittest discover -s tests -p test_xfs_import.py -v
./scripts/check.sh test_xfs_catalog test_shop_xfs test_shop_original test_xfs_equipment
```

Resultados desta sessão: auditoria **0 problemas**, fontes intactas;
**10.466 quadros / 534 retratos**, pixels e pivôs iguais à decodificação do XFS;
**14 testes Python**, aprovados; **3.924 checks Godot**, 0 falhas
(3.816 catálogo, 12 loja XFS, 77 loja original, 19 equipamento).
Import Godot exit0, sem ERROR/WARNING no log. `git diff --check` conferido.
Galerias são montagens dos retratos nativos, não captura GPU nem execução do
cliente Windows. Não houve suíte completa de combate, pois nenhuma regra foi
alterada; não houve exportação, commit, push ou validação visual do app novo.

## Próximos passos delimitados

- Se as peças procuradas estão na galeria, **não exigem migração de arte**.
  Torná-las acessíveis exige definir uma concessão/seleção offline explícita,
  preservando a indisponibilidade de venda nativa e sem inventar preços.
- Se a intenção é ver os dois gêneros juntos como no cliente, há um trabalho
  separado de listagem e seleção compatível, com cuidado para não trocar o
  gênero do equipamento real por uma mera seleção de card.
- Se as peças não existem nestes dados, identificar nome/imagem e uma build
  Thor’s Hammer que as contenha antes de afirmar o que deve ser migrado.
  A auditoria é completa para este TestClient, não para todas as versões históricas.
