# ASate clássico — guia, Ion e filhos

REQ-04/05/07/08/19/44/45. Escopo: ASate ID10, T1/T2/SS; preservar
mobile, avatares, perfil, equipamento e elenco. Cliente fixado: GunBound.gme
SHA256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Não inclui Knight nem alegação de paridade integral do dano/colisão.

## Especificação e plano anteriores ao módulo

1. O guia colide e aciona Ion; não causa dano/cratera compensatórios.
2. Ion é estado do modelo por autor, copiado profundamente na previsão;
   emissão é decidida pelo tick, nunca pelo renderer.
3. Fechar movimento inteiro, transição ao chegar e frames de emissão no ASM;
   portar T1 um filho, T2 três e SS seis em duas passagens de três.
4. Filhos usam campos/autoria próprios; modelo retém o turno até completar
   efeito e filhos. Render usa atlas Ion original e LaserEffect dos filhos.
5. Fixtures independentes cobrem limites/contagem/cópia e integração real/previsão;
   captura GPU e partidas completas são verificação da integração geral.

## Matriz de evidência

| Contrato | Fonte | Estado |
|---|---|---|
| T1 um filho frame1; T2 frames1/3/5, ângulos central−1/0/+1 | Ion0x480310 ASM e chamadas0x481015/480a61/480b11/480bcc | comprovado |
| SS contador1..3 em duas passagens, idx5/6/7 depois1/2/3 |0x480cfc..480e9a; count8 é metadado | comprovado |
| Aproximação inteira ceil(|delta|/2); idle ceil/8 |0x4806b3..48081b | comprovado |
| Ion acima do dono: T1−200, T2−550, SS−400 |0x480310,47fad0,47fee0 | comprovado |
| Mira LUT ângulo em pixels, sem quantização3° |0x47bfd0 chama4f1f10 | comprovado |
| Filhos velocidade inicial cos*7680/sin*−7680, aceleração cos*1024/sin*−1024 |0x42f4b0 e dados5580a0..ac | comprovado |
| Fonte Ion normal/fire1/fire2/move,20 quadros×1tick |graphics.xfs laserion.img/.epa | comprovado |
| Colisão/dano/cratera e limitação de topo do satélite independente da câmera | modelo atual/pipeline comum | adaptação explicitada |

Extratos novos: `.tools/asate-fix/01-ion`, `02-machine`, `03-data`, `04-child`;
Ghidra12.2/Java25, projeto exclusivo `builds/ghidra-asate-fix`. Manifestos ok;
ABI conferida no ASM, não copiada da assinatura incompleta do decompilador.
Raw C histórico é pista auxiliar; Ghidra novo e os mesmos bytes prevalecem.

## API de integração

`ensure_satellite(model, owner)` cria em `model.satellites`.
`begin(model, projectile, impact)` devolve efeito para `model.battle_effects`.
`step(effect, model)` avança um tick20Hz e emite filhos; true enquanto ativo.
`step_satellites(model)` atualiza idle, sem acessar estado fora do snapshot.
Root intercepta guia antes de explode, não semeia gravidade no filho já fp_ready,
retém o turno e copia ambos os dicionários/arrays no FlightSnapshot.

## Limites

O cliente limita Y pelo topo da câmera mais constante protegida. Esta dependência
visual é desacoplada do modelo offline: campo opcional `satellite_ceiling` limita
Y; sem ele usa deslocamento do dono. Não ler câmera viva durante CPU.
Dano/cratera por filho preservam parâmetros do catálogo; fórmula de dano nativa,
clima especial e detalhes de transporte de parâmetros protegidos não são
reivindicados como portados por este módulo. Sem execução do cliente original,
export/app ou escuta novos nesta pesquisa.

## Evidência legível e fixture numérica

- `47bfd0`: EAX=target_x−Ion_x, ECX=target_y−Ion_y, chama4f1f10;
  LUT reduz cada componente por divisão assinada2 até −127..128 e retorna
  int16 nativo. Não usar atan2 ideal, /100 nem o arredondamento3° do voo.
- `4807cb..4807f5`: delta±7/div8 no idle; delta±1/div2 no movimento.
  Isso equivale a ceil do módulo com sinal. Cada eixo fecha exatamente no alvo.
- `480d88..480e9a`: índice1,2,3; troca de passagem inverte incremento X,
  conserva o endpoint e reinicia índice1. Não há um quarto disparo em cada lado.
- `48025c..4802dd`: double558070=`000000e0f4dcb13f`
  (0.06977777928113937 rad); tan×altura, truncamento, meio passo truncado.
  Para dono(100,700), alvo(600,800): altura400, passo27; X inicial560,
  emissões X560,587,614,614,587,560 e Y300.
- `42f784..42f8dc`: LUT float32; velocity=(cos×7680,sin×−7680),
  acceleration=(cos×1024,sin×−1024), todos truncados para inteiro24.8.
  Bytes5580a0..ac: `000080c4 00008044 0000f0c5 0000f045`.
  Heading270: velocity(0,7680), acceleration(0,1024); partindo(9,12),
  um tick produz fp_position(2304,10752), fp_velocity(0,8704).
- `49ce4f..49ce82`: meia largura float558084=`0000c040`=6.
  Guardar cada seção após tick, não reorientar a cauda pelo heading futuro.
- `42f52d/42f58f` e47f1c0: tail15, RGB T1 `00ff00` verde, T2/SS
  `ffff00` amarelo. Filhos compartilham LaserEffect; não reutilizam o sprite guia.
- Ion original:60quadros, normal0..19, fire1=20..39, fire2=40..59,
  move0..19; todos1tick. Bob de22ticks em481100 só afeta o desenho, nunca contato.

A seleção da arma na UI antes de atirar ainda não altera a altura do Ion;
modelo conserva a última arma efetivamente lançada (T2−550, T1/SS−200 no
idle). A elevação imediatamente após escolherT2 é uma pendência visual objetiva.

Validação isolada: `Godot --headless --log-file /tmp/asate-effect-test.log
--path . --script tests/test_asate_effect.gd`:80checks,0falhas; inclui 1/3/6,
retorno, sinais, pontos SS independentes, clone e imutabilidade do renderer,
seções históricas após mudança de heading. Integração e captura GPU ficam no
registro global da tarefa; estes números não comprovam o conjunto integrado.

graphics.xfs SHA256 `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`; laserion.img descompactado
SHA256 `51a40da70ed62103dbc2559cad7c5b06d55f2550bf426e1005619e16a689585b`. PNG extraído `b8ad9a678b1903da8be2828c5cacf06db30eb2b54d670aca5c802e494b5dfcf4`.
