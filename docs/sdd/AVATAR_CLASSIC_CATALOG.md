# Catálogo clássico de avatares — REQ-46

Na `main`, REQ-45 já é o roster dos 16 mobiles e ADR-082 já é o brilho do
chifre. Este catálogo usa REQ-46 e ADR-089.

## Pedido

Manter todos os avatares originais do Gunbound clássico e refazer o catálogo
para a equivalência máxima com o launcher e o servidor:

- https://github.com/jglim/gunbound-launcher
- https://github.com/jglim/gunbound-server

## Fontes conferidas

- `TestClient/avatar.xfs` do launcher, 22968 bytes, SHA-256
  `829be830e0c50c273d5e0ece03c22fbe0c45e07527129e60e8843d16a1df0e6d`.
  O arquivo em `assets/xfs/reference/avatar.xfs` é o mesmo.
- `GunBoundServer/gameserver.py`, classe `User`, comandos `0x6000`, `0x6004`,
  `0x6010` e `0x6011`, o exemplo comentado e `user_data_example.json`.
- `AvatarInfoProcessor.cs` do Img-Tools (CarlosX): ordem dos oito inteiros
  depois de Gold e Cash. O servidor não guarda esses números; quem os aplica
  é o cliente, a partir do DAT.

## O que o catálogo passa a descrever

`assets/xfs/avatars/classic.json` lista os 562 registros, na ordem dos DATs.
Cada um traz arquivo, id, nome, descrição, preços, os oito status e o slot
clássico. A arte continua em `catalog.json`, com a mesma chave
`xfs:gênero:categoria:id`.

| Protocolo | Valor comprovado |
|---|---|
| WORD | id nos bits 0–14; bit 15 ligado significa masculino |
| DWORD | WORD + slot no terceiro byte |
| Slot | corpo 0, cabeça 1, olho 2, bandeira 3 |
| Equipado | quatro WORDs, nessa mesma ordem |
| Bandeira vazia | WORD 0 para os dois gêneros |
| Padrão masculino | `00 80 00 80 00 80 00 00` |
| Padrão feminino | `00 00 00 00 00 00 00 00` |

O comentário do servidor que diz “head, body, eye and flag” não fecha com o
usuário `amigos`: `44 80 43 80 24 80 A4 80` é Rocker Suit, Rocker Hair,
Dizzy Glasses e Bazooka, ou seja, corpo, cabeça, olho e bandeira. O comando
`/gender m` confirma o bit 15. `01 00 01 00`, comentado como Space Marine (H),
é a cabeça feminina: o bit de masculino está desligado e `fh.dat` id 1 também
se chama Space Marine.

`8F 80 01 00` (Love Cupid, id 143) não existe nesta versão. A cabeça masculina
vai só até o id 76. O decodificador devolve vazio em vez de criar a peça.

## Textos

Os 562 nomes e descrições decodificam em CP949. Vinte e oito descrições estavam
em CP1252: a reticência `A1 A6` aparecia como `¡¦` e o UserID do concurso
coreano saía ilegível. O texto restaurado termina em `까꿍사냥꾼` e usa `…`.
Preço, id e status não mudam.

## O que fica de fora de propósito

- `ff.dat` tem contagem 0. `ff00001.img` e `sff00001.img` permanecem no índice
  gráfico e não viram item de loja.
- Avatares de clientes posteriores à versão 280.
- Ex-item: este `avatar.xfs` não traz DAT de ex-item.
- A categoria da loja (cabeça 0, corpo 1, óculos 2, bandeira 3) permanece,
  para o equipamento já salvo continuar apontando para a mesma peça.
- Legado OpenBound (Kappa e os quinze registros) continua no namespace antigo.

## Validação

- `tests/test_xfs_import.py`: índice clássico igual ao DAT, hash do XFS,
  códigos do servidor e descrição coreana.
- `tests/test_xfs_catalog.gd`: 3816 checks, zero falhas. Inclui ida e volta
  dos 562 registros, o conjunto do `amigos`, os dois padrões de gênero e a
  rejeição do Love Cupid.
- Regressão: catálogo, perfil, equipamento, saldo, atributos, migração HD,
  arte e loja XFS, 2178 checks, zero falhas.
