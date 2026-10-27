# Mage: climas secundários pelo cliente

Pedido de27/10/2026, apósADR-126. AfetaREQ-04/07/08/09/23/24/25/35/44.
Plano: provar consumidores emASM; fixtures independentes; portar calendário,
vento e colunas em estado copiável; Moon/Eclipse; anexos elétrico/Thor antes
do dano próprio; validar modelo/previsão, partidas e apresentação; registrar
resultados e limites. Escopo: partidas contendoMage; demais combinações mantêm
o adaptador anterior. Fonte: mesmoGunBound.gme daADR-126, Ghidra12.2/JDK26.

## Contrato comprovado

* Calendário41fd50/41f200/4d0a10: oito células, sete categorias, shuffle31,
  tabela1024 e LCG32bits. Fraqueza/Espelho/Aleatório não pertencem a esta build.
* stage.dat: cabeçalho4bytes, streamLZHUF, checksum final soma+77;32 registros
  de484bytes. MiramoTown: pesos[2,1,2,1,2,0,0], sete categorias na ordem
  Force/Tornado/Lightning/Wind/Thor/Moon/Eclipse; oito intervalosX nativos.
* Colunas435800/435ad0/435da0: largura64..127, contato estrito largura/4;
  mescla somente primeiro encontro, média inteira e1,5×maior largura.
  43c620, chamado em4cee69 antes da fronteira de período, remove todos os
  tipos diferentes do atual a cada turno; categorias sem coluna removem todas.
* Moon43c6a0: só ator vivo/ativo do turno; trunc(maxHP×3/100), ou8% com
  characterdata[35]&2. Sem cura de escudo ou multiplicadorREGEN. Após regen comum.
* Eclipse43a670/4b8584/4ba690: bloqueia itens e removeDual/Dual+ globalmente.
  Sem prova de bloqueioSS.
* MageT1/T2/SS: elétrico→Thor→blast próprio/EMP; choque pendente consumido
  ao fim do tick. Elétrico: primário20/divisor1/2/1 + cadeia20, raio25;
  blastLightningT1 separado, podertrunc((230+3Attack)/2),
  dimensãotrunc((54+trunc(Dig/2))/2), aspecto134, flags1. Não herdaForce15c0;
  o campo17e4 copiado é o percentual separado, comprovado em45db20.
* Thor: clima4 consultado no impacto. Divisor1/2/1 só no poder, período visual
  multiplicado pelo divisor. Posição inicialY500 eX porLCG; entradaThor
  acrescenta40Y até1000, saída preserva posição. SemAttack/Dig herdados.
  XP acumula nos impactos; nível recalculado na transição4ccd10→4ac180.
* Colunas: FirewallTexture/LightningTexture/TornadoTexture originais,
  quad de largura inteira, tiles64Y sem escala vertical, Animate20Hz,
  scroll2/2/6px e UV nativos; Electric usaSRCALPHA/ONE, outras mistura alpha.

## Fronteiras de entrada e validação

Treino1×1 fornece período2, seeds locais para os geradores separados, categorias
habilitadas e preset experimental "todos". A arena procedural usa ranges do
mundo como entrada de fallback. Isso não demonstra replay da seed de uma
sessão Windows; não implementa rede. Ativação de itens, regeneração comum,
montagem/origem dos atores e partículas decorativas em voo continuam bridges
identificados. Não é alegação de paridade integral.

O contador10000 e seu hook de decremento existem. No ciclo2D normal auditado,
`4bd8b0→4507d0` chama apenas Animate+8; o desenho4508a0 usa+0xc;
`4f3100` remove objetos marcados+14 sem chamar+0x10. Animate só incrementa o
relógio visual. Portanto o porte não inventa expiração nesse caminho.
Não se generaliza essa conclusão a todos os fluxos indiretos/3D do executável.

## Evidência e reprodução

`docs/mage-weather/native-proof.json` fixa hashes PE/DAT/XFS, endereços,
manifestos aceitos e parciais explicitamente rejeitados para prova integral.
ExtratosC/ASM locais em `.tools/mage-weather`; o corpo do executável não é
copiado ao produto. Ghidra12.2/JDK26, ABI Windows x86, consumidorASM e dados
confirmados antes do porte.

`scripts/import_mage_weather.py` reproduz stage/intervalos; o importer de arte
reproduz as três folhasXTF,196608 pixelsRGBA idênticos. As suítes
`test_mage_weather`, `test_mage_weather_effects`, `test_mage_secondary_weather`,
`test_mage_weather_source` e `test_mage_weather_art` cobrem fixtures aritméticas,
borda/tick anterior/exato/posterior, cópia profunda e real=previsão.

Revisão independente encontrou umP2:17e4 era percentual, nãoForce15c0.
Corrigido com RED57/2→GREEN57/0 e integração575/0. NenhumP1/P2 restante no
delta revisado. Na conferência final deUI, corrigida também a fila de item:
Eclipse limpa a seleção pendente, sem consumir inventário nem alterar o
adaptador legado; RED49/3→GREEN49/0 e revisão focal semP1/P2.

Harness completo: **26775 checks Godot +58 testes Python +29 partidas,
95 suítes/parse, zero falhas, exit0**. Executado com cópia imutável byte a byte
de `scripts/check.sh`, limite900s por suíte. Depois do ajuste final deUI,
`test_items_scene` passou49/0, incluindo dois novos checks; consolidação
**26777 checks Godot**. Regras/física permaneceram iguais durante o harness;
o delta posterior deUI foi validado separadamente. Hashes, logs, contagens e
pausaRGBA independente em `docs/mage-weather/verified-source.json`.

Tentativas preliminares preservadas em `.tools/mage-weather`: expectativas
antigas deUI/cura/raio corrigidas; uma rodada usou timeout120s insuficiente
e o harness foi editado durante sua execução. A rodada imutável acima foi
executada novamente até exit0; essas tentativas não são usadas como aceite.

GPU: `capture_mage_weather.gd`, Compatibility/OpenGL noAppleM4Pro,
`--disable-vsync --always-on-top`,1920×1080/60Hz/540quadros. Seis casos:
T1/T2/SS nos dois sentidos, contatos controlados, colunas e anexos,30quadros
de pausa idênticos por caso. MP4 de9s/540frames e amostras em
`docs/mage-weather`; série bruta local em `.tools/mage-weather/frames`.
O vídeo comprova arte/relógios/pausa; oP2 numérico foi conferido depois nos
testes focais e no harness final, sem alteração de geometria/raster.
Escuta, mouse e aceite visual humano não foram executados; clienteWindows
não foi executado. Importação teve erros ambientais deCA/editor_settings
fora do sandbox, sem falha de import dos recursos. App/ZIP não reexportados.
