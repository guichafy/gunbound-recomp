# Boomer — issue #9: investigação e plano

Estado: **encerramento da issue solicitado pelo usuário; aceite integral não comprovado**. Escopo:
REQ-04/05/06/07/08/09/19/20/23–26/35/44/45, Boomer ID 6 (tipo nativo 5),
treino offline contra Mage. A issue é a especificação de aceite; nenhuma
paridade adicional é presumida. Preservar elenco, perfil, equipamentos e arte
aprovada. A prova nativa prevalece; lacunas permanecem adaptações declaradas.

## Investigação de apoio, vento e apresentação — 28/10/2026

### Indireções adicionais: piloto e término da pose normal

| Caminho | Resultado observado em estática | Limite |
|---|---|---|
| 0x461ccb → objeto +0x38 | O construtor base 0x458b80 passa `this+0x38` a 0x44fb40 (`ev_60ec6526849b17a683d453b823b5e0000665d1ffdd7c8fb2881c4bb77447ebd5`); 0x44fb40 instala 0x555b38 (`ev_970726cd0a295dfa5d4aef238ac429b3f9f400958e2ac56dddac086b81f3fe19`). Bytes dessa vtable: +4 = 0x461c60, +8 = 0x44fcb0 (`ev_af6b4f9ef1cc654c1d283b8469e4d143cd28bf2254a8857c9188839c55209847`). A fábrica atribui `avata` ao objeto interno. | Destino derivado do construtor/tabela, não rastreado em execução; alterações dinâmicas não estão excluídas. |
| 0x44fcb0 → 0x450730 / 0x461c60 | O objeto interno avança seu EPA; ao completar, `_rand()%10` e a flag +0x8c8 escolhem `normal` ou `look` (`ev_f2cb6e8afab4e229c963afe3083b4544ea053d0e380a2c3a454ee06d3da8dd50`). +4 resolve ao seletor 0x461c60, que procura o nome no EPA e reinicia seus índices. | Sem leitura direta dos dois campos de vento no corpo analisado. Estado do gerador, outras chamadas e influência indireta não foram esgotados. |
| 0x461e49/0x461e57 → 0x450730/0x45ed80 | `normal` é estado índice 0, contém 20 ticks, flag EPA 0; ao terminar, 0x450730 marca +0x34. Em 0x45ed80 caso 0, `_rand()%8 == 0` e flag +0x8ba8 falsa selecionam `emotion1`; caso contrário, `normal`. `emotion1` tem 30 quadros/ticks, índices 318–347. `ev_7c20a8daa07ef4d91e314729b4c1eb5d8317f5a2ff1f4af1bc836f4e6b5c5780` e Ghidra ASM confirmam as ramificações. | Variação de repouso com sorteio é comprovada no recorte; não é prova de que vento controla ou não o estado. A semântica da flag +0x8ba8 e a sequência global do RNG não foram fechadas. |
| Porte | `BattleArt.state_name` retorna `idle` em repouso e `ClassicSprite` repete `normal`; `emotion1` do Boomer não está integrado. | Diferença identificada, não corrigida nesta investigação; precisa de contrato de RNG, interrupções e pausa antes de alterar apresentação. |

REA/Hopper snapshot `builds/boomer-wind-indirect-20261028-rea.json`
(SHA-256 `5f1f4324aeb4d36ac05b71f9ebcfcec8d86953abd2d458279ef0e12b547a5b7a`);
Ghidra12.2 `builds/boomer-wind-indirect-20261028`, `run.json` e
`manifest.json` `ok=true`, sete funções e duas tabelas, aviso de CA.
Probe independente `.tools/boomer-issue9/wind-indirect/probe.py` leu o PE,
comparou cinco bytes de chamadas indiretas e as duas tabelas e reextraíu
`tank6.epa` do XFS; saiu 0 e escreveu
`builds/boomer-wind-indirect-probe.json` (SHA-256
`e502bb9d260fc6e03a0687341d1657153f2be24335786d2760c31094117e293c`).
REA/Hopper não suporta `resolve_native_call_targets`; a resolução acima é
uma derivação das tabelas/construtores e não cobertura dinâmica completa.

Seguimento da flag e RNG: 0x4064a0 codifica um booleano em três bytes e
consome **duas chamadas a `_rand`** por escrita (`ev_6d5cc998765bf89d683e58bbf4628402c8c2bb72c93cf41e520a33d2cf599fa9`).
0x406530 lê o booleano protegido e o atribui a outro via 0x4064a0
(`ev_11c844a8cd7368f89a3ca28034be3331f92a4b58d2495ebcb12b9bd13dd2c607`).
A varredura literal de +0x8ba8 encontrou chamadas que a zeram em 0x43e598
e 0x4b6b6b, e cópias em 0x420a6c e 0x4d118c; a origem de todos os valores
verdadeiros e a semântica completa da flag não estão provadas. `_rand`
0x525c4f acessa estado da thread, atualiza-o por `state*0x343fd+0x269ec3`
e retorna bits 16–30 (`ev_49470c8bd02005ec03b2e62854c4c303193bb629448c49ec64d2d716bd60da63`).
Assim, escritas de estado na mesma thread podem alterar sorteios subsequentes,
inclusive a seleção de `look`/`emotion1`. Isso é uma possibilidade de
acoplamento indireto, não prova de que uma mudança de vento o provoque:
faltam sequência de chamadas, seed e threads do cenário de partida.
Snapshot REA adicional `builds/boomer-wind-rng-flag-20261028-rea.json`,
SHA-256 `41d4d8730dd06d4a1fe9934cb5a4c0109c7eeb1842b7f55652511b69758fea90`.

Próxima investigação: rastrear demais produtores da flag, eventuais
mutações do objeto interno, seed e consumo do RNG no caminho de mudança de
vento, e comparar cenário controlado do cliente original em ambiente offline.
Não alterar a pose por vento sem fechar esse vínculo. Nesta etapa o probe
independente voltou a passar e `./scripts/check.sh test_boomer` passou 928/0;
nenhum comportamento de produto foi alterado.

Continuação da pose: o PE seleciona `wnormal`/`wmove` por uma comparação
entre vida atual e vida máxima/3. Corrigir o limiar apenas para Boomer e
testar antes/exato/depois; continuar auditando os consumidores do vento sem
assumir que o prefixo `w` signifique vento. REQ-09/19/20/45.

### Continuação: sequências `wnormal` e `wmove` (ADR-149)

O estado do `tank6.epa` foi reextraído de `graphics.xfs` SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
o EPA mede 4373 bytes e SHA-256
`5b0f27bbff6717f61e2b5bdae9a75a367bf19efab97a3e84e0139c8c97d9d57c`.
`normal`/`move` têm 20 quadros 0–19/20–39; `wnormal`/`wmove` têm 20
quadros 40–59/60–79. Não há nome de estado com referência explícita a vento;
nomes sozinhos não provam a ausência de controle indireto.

O construtor 0x41c360 copia DAT[22] para +0x6744 e inicializa +0x6968
com esse valor; o Boomer tem DAT[22]=1000. Em 0x461ca0, o helper
0x40a8c0 calcula +0x6744/3 com `idiv`; 0x40b490 compara +0x6968 com
esse quociente usando `setl` assinado (`ev_b696ae1b2512706905ea9edb977320f4a2ac9fac05e68163de96ae6c60883c84`).
O ramo verdadeiro seleciona `wnormal` ou `wmove`; o falso, `normal` ou
`move`. Portanto, nesse caminho o prefixo `w` corresponde a vida baixa,
não a uma leitura de vento. Para máximo 1000, 332 é baixo e 333 não é.
`Mobiles.low_health` usa essa regra apenas para Boomer; outros mobiles
mantêm a regra anterior. O teste RED encontrou seis falhas nos casos 301 e
332, e GREEN passou 928 checks. GPU 1920×1080/OpenGL4.1: 640 quadros,
8 combinações de vida 332/333, vento 0/26 e ambos sentidos, pausa30 e
retomada em `docs/boomer-weak-pose-20261028`.
Harness completo após a alteração: 29.244 checks Godot, 92 testes Python,
29 partidas, sem falhas/exit0; log
`.tools/boomer-issue9/harness-wind-weak-adr149.log`, SHA-256
`fd53eb788920a5ad5da811441453b2041ebd452ea3a23213b98ab7ab106af598`.

Análise complementar: `0x439600` lê força e direção do vento e gera
objetos animados aleatórios; seu chamador direto `0x4e4970` também é chamado
por funções de impacto incluindo 0x48de60 (`ev_895e3a789c6a983b773d471a5ebcde44446a54228dd6ad6c39cd9b54157ff86d`,
`ev_9923fe501a4684afaf4e5e0a1e29a95f9ac2e44b57ada61c66ca295c28c502ff`).
Isso demonstra uma via de partículas ligadas ao impacto, não à pose em
repouso. A varredura de deslocamentos nos bytes do PE também identificou
0x4bb440 escrevendo os campos de vento no buffer 0xe9aacc, e 0x4cc5c0
comparando a direção em seu caso 0xf; seus contextos não estabelecem
alteração da pose apoiada. Ghidra 12.2 em
`builds/boomer-wind-pose-sweep-20261028`: `run.json` e `manifest.json`
`ok=true`, 6 seletores; aviso de truststore/CA. As funções têm indireções e
0x4b7a80 foi agrupada por Ghidra em 0x4b5460. A varredura literal de
deslocamentos não cobre valores copiados ou acessos indiretos: não permite
concluir que a pose apoiada ignore o vento. Cliente Windows não executado.
O snapshot REA com as evidências desta etapa está em
`builds/boomer-wind-pose-sweep-20261028-rea.json`.

Continuação solicitada: portar apenas o cálculo de apoio demonstrado em
0x45ba50, na máscara e origem adaptadas do treino; testar central/lados,
bordas, LUT, sentidos, e a coerência entre boca, mira e previsão. Comparar
em GPU repouso e recuo nas duas rampas, com vento e pausa. A pose dependente
de vento permanece pendente até identificar seu consumidor no cliente.

### Continuação: alinhamento do apoio (ADR-148)

`BoomerFlight.support_rotation` usa centro e ±14, ajuste dos lados que
excedem centro+24 e LUT original de `0x4f1f10`; `Match.body_rotation`
o usa somente para Boomer. A imagem que motivou o relato de flutuação era
do recuo: `tank6` quadro 108 já levanta uma roda na fonte; preservá-lo,
sem alinhar cada quadro pelo seu alpha. A captura em repouso mostrou também
que a amostragem anterior dava ±6,34° na rampa da fixture. A nova dá +9° e
−8° (assimetria da LUT original). A caixa física, solo em grade de 2 px,
origem visual +23, distância de segurança de 60 px e interpolação do render
são pontes do treino; a relação nativa exata dos hotspots segue em aberto.
Não se afirma equivalência integral. A boca, HUD, velocidade e previsão
continuam a receber `Match.body_rotation`.

GPU OpenGL 4.1 Apple M4 Pro: `tests/capture_boomer_support.gd` produziu
500 passos, quatro combinações de rampas/sentidos, repouso, recuo com vento
e pausa 30; imagens em `docs/boomer-support-20261028`. A repetição de
`capture_boomer_standing_wind.gd` no subdiretório `wind` passou 1000 passos
e 10 cenários, item Change Wind, pausa/retomada. Isso confirma o render do
porte, não uma alteração da pose do corpo pelo vento nativo. REA adicional
`builds/boomer-support-follow-20261028-rea.json` confirma que o desenho usa
o ângulo do apoio, mas não prova caminho de vento sobre a pose apoiada.
O usuário avaliou a montagem em repouso: “O apoio nas rampas parece correto”.
O cliente Windows segue não executado; isso não comprova paridade integral.
O teste dirigido foi RED para as amostras de rampa e para o caso de reflexão
em borda e GREEN com 913 checks. Harness completo: 29.229 checks Godot,
92 testes Python e 29 partidas, exit0; log
`.tools/boomer-issue9/harness-support-adr148.log`, SHA-256
`4ab92b1f3a12d6adefc121508c0599a11e629689ff0b3cf111256b2965790498`.

O PE e `characterdata.dat` foram novamente verificados: SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde` e
`b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`.
REA/Hopper, snapshot local `builds/boomer-support-20261028-rea.json`:

| Aspecto | Evidência e conclusão | Estado |
|---|---|---|
| Indireções do Animate | Os bytes da vtable 0x555c14 (`ev_1c106b785feaee801395c858fa18101d9bf63973f1bfff2176bdcecbf0696201`) resolvem +0x18 para 0x45f910 e +0x1c para 0x4542a0. Os acessos diretos ao vento identificados em 0x45f910 alimentam a mensagem de disparo; isso não fecha todas as indireções ou prova ausência de efeito visual. | Parcial; não inventar pose ao vento. |
| Amostras de apoio | 0x41c360 copia campos DAT 0/1 para +0xd54/+0xf78, este último para +0x119c; Boomer tem 28/24. 0x45ba50 calcula três consultas de coluna, em x e x±14, iniciadas em y−12, via divisão assinada de 0x40a8c0 e operações 0x40aca0/0x40aba0. 0x4e4340 procura para baixo o primeiro byte sólido e devolve 10000 se não houver (`ev_33df71320091080f890df0680779d86397c852dc170a3eb84f3a38636494e574`, `ev_e5b14a5c16e841ad584170c25c760d6c4966fdcd72254838d61d3766fa857fbf`, `ev_fee8959dc69c6c3f23b7c5a699e89983cf0c655eea7f33dfce27d4cde8e3c3c5`, `ev_6015ac62d2796ad46a275029999c3febd70715968192d4fd2d9cc25c1c9c15bd`). | Geometria de consulta comprovada no trecho; correspondência dos campos x/y e do hotspot com o modelo ainda requer comparação integral. |
| Borda e ângulo | 0x45bf1e–0x45bf5b compara lados com centro+24 e reflete ou substitui apoios afastados; 0x45bf5d–0x45bf84 usa a LUT 0x4f1f10 e divisão assinada. O construtor base inicializa divisor +0xbff0 a 1 e o ramo de criação tipo 5 chama esse construtor (`ev_ddfc0915208777a90e3be67e1f191852a180f6cf666929dc89a8fbe0a8a3d3cd`, `ev_3a22b762fde5ec41aa638cf7da208d6dfb84f9b70000bf88057a451fab505bb7`). Antes da ADR-148, o porte usava superfície a ±18, sem centro, grade 2px, `atan2` e clamp ±30°. | Histórico: regra substituída para Boomer pela ADR-148; origem, divisor e equivalência integral ainda têm limites. |
| Inspeção humana | O usuário ouviu uma captura do mixer Godot de quatro disparos T2 e um impacto provocado e respondeu “Parece correto”. Ao ver a fixture de rampa informou “Precisa de ajuste” e “Parece flutuar”. | Escuta aceita para o cenário apresentado; contato visual precisa de ajuste. Não equivale a comparação com o cliente Windows. |

`tests/capture_boomer_audio.gd` grava o bus master com `AudioEffectRecord`,
sem música, a partir da cena de batalha: verifica quatro recursos `62fire`
e um `62blast` da emissão/impacto. A fixture avança a cena manualmente e
provoca o impacto; sua temporização de captura depende do relógio do mixer.
Uma primeira captura foi ouvida pelo usuário (SHA-256
`2a83d95cdf7e56be449d677f6dbaec26b6bba6b90af7c002f3faec65ec756af4`);
a repetição, após acrescentar as verificações dos recursos, gerou
`docs/boomer-audio/boomer-t2-mixer.wav`, SHA-256
`c0c9d03971978a0361d35b64c0aa7fa3b47641297bcce193130ba63640ffd54b`.
Não é gravação do cliente original nem cobre todas as armas.

Na fixture de rampa, a posição usa `stance=25`; `MobileSprite.draw` aplica
`ground=24` no referencial rotacionado do ator. A máscara procedural e o
terreno desenhado são os mesmos, mas rotação, alpha dos quadros e raster
podem deslocar o contato. A observação do usuário requer diagnóstico de
contato por quadro e em ambos os sentidos antes de corrigir o encaixe;
nenhuma alteração de regra ou de posição foi feita nesta investigação.
O recorte ampliado `docs/boomer-muzzle-slope/slope1-facing1-detail.png`
mostra a extremidade esquerda do chassis acima da superfície, enquanto a
extremidade direita toca o terreno. É um único quadro de uma fixture, não
uma medida de distância em todos os quadros. Parse da captura de áudio e
suítes dirigidas `test_classic_shot_timing_scene` (49/0),
`test_client_audio` (223/0) e `test_client_audio_source` (5 testes) passaram.

## Identidade e evidência inicial

SHA-256 medidos em 27/10/2026: PE `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`, graphics.xfs `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`, sound.xfs `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023`, characterdata.dat `b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`. PE x86 LE, image base 0x400000; endereços abaixo são VAs desta build.

REA/Hopper no Animate do projétil `ev_e14da26a2ddcba010fcab53a9b97791689d297175063d732c3e5ee01ac35d7db`: 0x452bf0 chama a entrada virtual +0x18 e 0x450730, consulta 0x4065a0 e manipula campos de estado; o trecho não estabelece relação com o vento. O provedor não fornece limites completos do corpo e chamadas indiretas podem estar ausentes. Não concluir que o corpo ignora vento. Análise estática não é execução do cliente.

Ghidra 12.2/JDK 25: `builds/boomer-issue9-evidence-1` parcial (`ok=false`: 0x453f30 não reconhecida); bytes da vtable 0x555bf0 apontam para essa entrada. Reexecução `builds/boomer-issue9-evidence-2` com `--seed-known-entries`: `run.json` e `manifest.json` ambos `ok=true`, PE inalterado, 0x453f30 reconhecida. Logs inspecionados: aviso de truststore/CA, sem erro de análise. Os arquivos em `builds/` são locais e ignorados. O snapshot REA é `builds/boomer-issue9-rea.json`. O pseudocódigo contém ABI e chamadas indiretas ainda não resolvidas; esta extração não fecha a fórmula nem o consumidor de vento.

## Matriz inicial, antes de mudanças no produto

| Comportamento | Fonte/unidade/ordem | Classe e implementação atual | Validação ou próxima prova |
|---|---|---|---|
| Curva, sustentação e transformação SS | 0x4513b0, 0x453242 e LUT 0x4585e0; ponto fixo e ticks em CLASSIC_BALLISTICS_0_20 | Porte anterior delimitado, `boomer_flight.gd`; confiança da revisão anterior | Reconfirmar instruções e oráculo independente, fronteiras 35/36/45/46 e previsão |
| Cadência T1/T2/SS | 0x4542a0 e EPA, ticks 8 / 8,10,12,14 / 8; BATTLE_ASSET_MATRIX | Porte anterior, `classic_shot_timing.gd` | Reconferir despacho, áudio por emissão e Dual |
| Corpo e vento | Consumidor do corpo, unidade e ordem ainda desconhecidos; 0x452bf0 é do projétil | **Pendente**; `classic_sprite.gd` não recebe vento | Seguir vtable, render, EPA e consumidor do ângulo; não inventar inclinação |
| Animação dos tiros e impactos | tank6, bullet6n/s/p, flame61/62/63 e ssflame6; EPA | Inventário anterior; consumidor e composição não auditados nesta issue | Conferir pivôs, relógios, orientação, estados e GPU |
| Ficha, ataque, defesa e colisão | DAT pinado, 0x41da80 → 0x45db20; unidades e ordem por confirmar | **Pendente**; valores atuais em `classic_mobiles.gd` e dano/colisão adaptados | Seguir consumidor, construir oráculos independentes e comparar execução/previsão |
| Climas e vento da partida | Partida contém Mage; calendário e climas em MAGE_SECONDARY_WEATHER | Calendário existente para partidas com Mage; efeito específico Boomer **pendente** | Confirmar consumidores de cada categoria, animação e alterações em tiro/corpo/dano |
| Sons | 62fire/62blast, sound.xfs pinado, BATTLE_ASSET_MATRIX | Recursos e cadência a reconferir | Comparar payload e evento, escuta humana pendente |

## Subconjunto de dano confirmado para implementação

A extração `builds/boomer-issue9-evidence-4` tem manifestos `ok=true`;
`0x454559` passa count=4 ao spawn T2 e `0x42d667–0x42d68b` o encaminha
para `0x41da80`. No cálculo de Attack, `0x41e4eb–0x41e4ef` multiplica por
3 e divide pelo count; Dig usa divisão por 2 e depois pelo count. T1 e SS
usam count 1. `0x452383` e `0x48e047` chamam `0x450eb0` para dano; este
encaminha a `0x45db20`, já implementado em `aduka_combat.gd`. A linha DAT
pina poder/dimensão/aspecto/flags: T1 254/48/124/2, T2 118/42/114/2,
SS 350/46/120/2. Em SS a transformação atua também sobre a dimensão
preparada, não sobre a constante 46 isolada. A ponte de itens offline e o
registro espacial do ator seguem adaptações já declaradas. A revisão não
estabelece ainda o comportamento dos climas ou o consumidor de vento.

Plano deste subconjunto: fixture de Attack/Dig com divisores 1/4/1 e SS
antes/depois da transformação; ligar a resolução compartilhada de dano e
cratera à execução/previsão; excluir o sinalizador; validar contra os valores
DAT/ASM e a regressão completa. Não ativar colisão ou clima nativo sem fechar
suas ordens para Boomer.

## Estado observado nesta continuação

O caminho comprovado acima está ligado a `BoomerFlight.prepare/parameters` e
`Match.explode`, com SS transformando a dimensão preparada. `test_boomer`
passou 108 checks, incluindo atributos, tick46 e 243 de dano no centro do
Mage (DAT vulnerabilidade92, ajuste elemental +4). Real e previsão mantêm o
mesmo laço. `./scripts/check.sh`: 28.393 checks Godot e 29 partidas,
zero falhas, exit 0; parse aprovado. Clima, contato e origem espacial ainda incluem pontes adaptadas;
Registro anterior: Thunder/Thor/elétrico ainda não estavam revalidados naquele snapshot; ADR-144 substitui o trecho anexo.

A vtable do mobile em 0x555c14 contém Animate 0x461ca0, desenho 0x462900,
Simulate 0x45c6e0, tick 0x45f910 e MainAction 0x4542a0. Ghidra12.2 em
`builds/boomer-issue9-evidence-6` foi `ok=true` após seed comprovado de
0x458690. REA/Hopper `ev_a58e873bc5fe25de3c7f5b720619a2771f7e879528c264eb03df9b728bd2b781`
analisou o desenho; cobertura do corpo e indireções não é completa. Tick
0x45f910 lê vento em 0x460b78/0x460ba3 e 0x461228/0x461255 para codificá-lo
na mensagem de disparo; isso não demonstra animação do chassis. A busca pelo
consumidor de vento no corpo continua aberta. `0x458792` publica o campo
+0x1c2c para o desenho do projétil; sua conversão raster segue pendente.

Comparação RGBA byte a byte com extração do XFS pinado: tank6, bullet6n/s/p,
flame61/62/63 e ssflame6 idênticos aos atlas ativos. As entradas bullet6nl,
6sl e 6pl não constam no XFS. EPAs de corpo normal/move e tiros têm20 ticks;
bullet6p tem normal20/change10/cnormal20, impactos11/11/13 e ssflame15.
PCM de 62fire/62blast confere com sound.xfs (estéreo 22050Hz/16bit). Essas
comparações não validam composição, ativação secundária ou execução Windows.
A primeira comparação com coluna incorreta foi descartada; a final usou as
colunas do importador (20 corpo, 8 balas e 6 impactos) e bytes RGBA completos.

## Subconjunto de colisão e tornado (ADR-143)

Vtables 0x555bd0/0x555bf0 encaminham Simulate a 0x455cc0, que chama
0x451030/0x4510f0 e refinadores 0x458920/0x458a00; REA/Hopper
`ev_8488193ba8950246923f46f75c1fa942c4ba2184b7ce6a97bcec119cf456c5f8`.
0x45164e suprime sustentação quando o objeto-tornado já está ativo;
0x45265b–0x4528a5 limita |vx| a 200 e inverte nas duas primeiras saídas,
liberando na terceira. A aceleração é omitida no ramo da terceira saída.
0x4528a7–0x4528fb pula o reset por vy descendente dentro do tornado, mas
0x4528fb–0x452977 ainda atualiza o ângulo da curva. SS usa o mesmo contrato
em 0x453a15–0x453ce9, exceto durante a transição congelada. Estado é próprio
por projétil; a varredura e o passo de partida são os mesmos da previsão.
A primeira captura com apoio plano manteve indevidamente a máscara nativa
do terreno anterior; deve-se reconstruí-la ao trocar a fixture. Aquela
colisão não demonstra contato com o atirador e a captura foi descartada.
Limite: a conversão da origem do ator, item e outras variantes do clima ainda
são pontes declaradas. Testar entrada, duas inversões e terceira saída, curva
fixada na semente, Force e cópia; não alterar os outros mobiles.

## Orientação do projétil (ADR-143)

A publicação compartilhada 0x458792 lê `+0x1c2c`, o ângulo que os ticks
Boomer 0x4514c2/0x45290a e SS 0x453c85 atualizam. O raster 0x4ebdd0 usa
seno/cosseno: o vértice nativo (-48,-32) vai a (-32,+48) em 90 graus, logo
no canvas de Y para baixo a rotação é `-radians(ângulo)`. Sem curva, o tick
escreve zero; com curva o valor avança por tick e pausa na transformação.
Render deve ler a cópia de estado, sem afetar posição ou colisão; demais
mobiles mantêm sua orientação anterior. Confirmar fronteiras e GPU temporal.

## Classificação dos climas do treino Boomer × Mage

A partida seleciona o calendário de Mage (`Match.start`), com categorias e
pesos de Miramo em `MAGE_SECONDARY_WEATHER.md`. A classificação abaixo é do
porte atual; os efeitos anexos ainda não fechados não são paridade integral.

| Clima | Estado no Boomer |
|---|---|
| Force | Amostragem nativa por ponto de varredura, bônus separado no dano; ponte de geometria da coluna mantida. |
| Tornado | Limite/inversões e sequência da curva portados neste corte; cópia previsão testada. |
| Lightning | Contato marca eletricidade na varredura; anexo usa choque e explosão nativos compartilhados, antes do impacto próprio. Ativação offline de item mantém ponte. |
| Wind | Vetor físico congelado na semente; mudança de pose do corpo segue sem consumidor comprovado. |
| Thor | Acionamento pelo clima atual e divisor1/4/1 nos três tiros; feixe/contato usam a ponte offline compartilhada. |
| Moon | Calendário/regeneração por ator no caminho compartilhado de Mage; não foi feita auditoria específica de Boomer. |
| Eclipse | Bloqueio de itens compartilhado no calendário de Mage; interação específica com itens do Boomer ainda não foi toda exercitada. |

Atualização ADR-146: Miramo tem pesos `[2,1,2,1,2,0,0]`; Moon e Eclipse
foram exercitados por fixtures forçadas, não por sorteio natural. A
apresentação usa os consumidores compartilhados descritos em
`CLIENT_ASSETS_WEATHER.md` e `MAGE_SECONDARY_WEATHER.md`:

| Categoria | Apresentação e limite no Boomer |
|---|---|
| Force | `FirewallTexture`, quad/tile e relógio nativos compartilhados; partículas de contato preservam ponte de emissão. |
| Tornado | `TornadoTexture`, quad/tile e relógio nativos compartilhados; captura dos tiros em ambos os sentidos. |
| Lightning | `LightningTexture` aditiva e feixe de impacto; contato/ordem e captura controlada, geometria do anexo ainda ponte. |
| Wind | HUD/indicador e transição existentes; queda usa acumulação quantizada ADR-146, movimento visual interpolado; pose apoiada não comprovada. |
| Thor | `thor.img`/`thorl.img`/EPA e `LaserEffect`; anexos 1/4/1 com captura controlada, geometria de contato e som ainda limitados. |
| Moon | Ícone no calendário compartilhado e cura por turno; fixture forçada cobre Boomer, sem efeito visual próprio adicional comprovado. |
| Eclipse | Ícone no calendário compartilhado e bloqueio de itens; fixture forçada cobre Dual/Dual+ e SS, sem efeito visual próprio adicional comprovado. |

Captura de `tests/capture_boomer_issue9.gd`: seis casos, 240 passos a 60 Hz,
1280×800, OpenGL 4.1 no Apple M4 Pro; tiros1/2/SS, dois sentidos, vento
horizontal contrário, pausa de30 imagens idênticas e retomada nos seis. SS
mostra estados35/36/45/46 em ambos os sentidos; logs sem erro. Amostras e
resumo em `docs/boomer-issue9/`; os 105 PNGs de cada sequência e logs brutos
ficam em `/private/tmp/boomer9-final-*`. Essa captura não cobre impactos ou efeitos de todas as categorias, não é cliente Windows nem aceite
visual, e passos a60 Hz não demonstram desempenho real de60 FPS.
Além dos seis casos, dez capturas T1 com vento zero e quatro quadrantes
(±24, ±24), nos dois sentidos, tiveram 180 passos e pausa/retomada
confirmadas. Amostras e resultados constam no mesmo relatório. Isso não
comprova como o vento altera o chassis no cliente.

## Impactos anexos de Lightning e Thor (ADR-144)

Ghidra12.2 `builds/boomer-issue9-evidence-7` (manifestos `ok=true`):
0x45190b e 0x4536d3 chamam 0x431d90; 0x451bf2 chama 0x432320 e
0x453732 chama 0x4398e0, que consulta clima4 e passa count (+0x3f94)
a 0x432320. Os anexos antecedem 0x450eb0/0x48de60. Para T1/T2/SS,
count é 1/4/1. Reusar o caminho Mage de choque/elétrico→Thor antes do
impacto próprio, com divisor Boomer específico e sem executar também o
adapter legado. Testar clima atual, item elétrico, ordem, divisor e snapshots.
A geometria do feixe e a ativação offline de itens permanecem pontes.

## Minas atingidas pela explosão (ADR-145)

No PE pinado, 0x450e10 enumera classes 0x186a1 e 0x186a6, não a classe
0x186a3 das minas: não tratar a mina como caixa que interrompe diretamente
0x455cc0. 0x452383 e 0x48e047 chamam 0x450eb0 com flag de minas1;
0x450f7a–0x450fb3 percorre 0x186a3 e chama 0x499650. A rotina testa mina
ativa e `q(dx*100,aspect)^2 + dy^2 < (q(dimension,2)+10)^2`, usa a dimensão
do projétil (inclusive após SS), copia byte de autoria e chama o virtual de
explosão. REA `ev_73d3f6e95592863e85bc1a9cb30f98608bcd504d11b276c6b61d7fa098914e79`
e `ev_505656a35d1b8e30649eaa3cef1778e4e3df35d10e83f67fc9395ff6a3f00a3b`;
Ghidra `builds/boomer-issue9-impact-2`, `ok=true`. O modelo aciona o
explosor já existente de Raon, preservando a adaptação de dano/cratera da
mina; os testes cobrem borda estrita, autoria e igualdade da cópia na previsão.
A coleta de Gold da explosão principal precede o acionamento das minas para
evitar dupla contabilização; a ordem de contabilização é adaptação do porte. Cadeia
secundária entre minas continua separada enquanto não comprovada.

## Composição do impacto SS (ADR-145)

`0x45373b` chama o virtual de explosão 0x48de60; 0x48e0f7 chama
0x4372f0 com flame63. Só com estado EPA>1, 0x45373e–0x453773 chama
0x4373c0 com `ssflame6` no mesmo ponto. O estado `change` não tem colisão.
Os construtores recebem flag de rotação1, escolhem `_rand()%360` em cada
objeto e 0x471c70 avança2 graus por tick, ou5 com a flag global +0x45578;
o renderer consome esse ângulo. REA `ev_d58c5b970d1e2014bdf33211ef2cc3095ff9bdd90f0ef1dba2b8f96ea502fb29`,
`ev_581b68c25b33a2458fc9f8a10cd40bd0ec530e08832e9461bf0c0688f296f0c4`,
`ev_7c8fbb5fa3acd37107a7058e2a40eca75b11ba068e43842d805f9d325af04ee6`;
Ghidra `builds/boomer-issue9-impact-2` ok. O porte usa as duas camadas e seus
relógios por efeito, com sorteio visual Godot independente; o estado e a
sequência do RNG nativo, e o significado da flag de avanço5, não foram
fechados. O avanço2 é ponte declarada, sem afetar modelo/colisão. Os testes dirigidos
cobrem estado, quadros e rotação.

## Plano de execução

### Resultado parcial: pose em apoio e relógio EPA

No caminho direto do Animate do mobile, 0x461ca0 chama o cálculo de queda
0x45cb50, o alinhamento 0x45ba50 e o relógio EPA 0x450730. Ghidra
`builds/boomer-issue9-pose-graph` confirma que 0x450730 avança índices e
durações da pose carregada, sem chamadas nem leituras diretas dos campos de
vento; REA `ev_8e7bd8106f05228a75875e26e5584ad550b9b07c59ce39f58a4a17e74d19022b`.
O acesso ao vento confirmado no próprio Animate atua na posição durante a
queda. Chamadas virtuais e outras vias indiretas continuam sem cobertura
completa; este recorte não prova que todo o cliente ignore vento com o
Boomer apoiado. Não foi inventada uma pose ou inclinação dependente dele.

`capture_boomer_standing_wind.gd` exercitou a cena real apoiada em GPU:
1000 passos em 10 casos, dois sentidos, vento zero e quatro direções, uso
efetivo de Change Wind, pose de item, pausa30 e retomada. A posição do ator
permaneceu fixa nos cenários; amostras e relatório em
`docs/boomer-standing-wind`. Esta é a apresentação atual do porte, não uma
prova de que a pose apoiada nativa seja independente do vento.

Ghidra `builds/boomer-issue9-wind-chain` é parcial (`ok=false`, endereço
0x4bb440 sem função reconhecida); a repetição `wind-chain2` exclui essa
entrada e tem ambos manifestos `ok=true`. Ela cobre os produtores e
consumidores diretos de vento selecionados, sem encerrar as indireções.

### Continuação: PCM efetivamente reproduzido

REQ-07/19/20/45. O `sound.xfs` do TestClient em
`../GunboundClassic/gunbound-launcher/TestClient` foi reencontrado e seu
SHA256 `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023`
revalidado. As entradas `62fire.xes` e `62blast.xes` coincidem em PCM com
os WAVs ativos após o cabeçalho XES de 16 bytes. Contudo, os sidecars ativos
usam `compress/mode=2` (QOA), alterando o PCM importado. Mudança delimitada:
importar apenas esses dois WAVs em PCM sem perda, preservar UIDs e os
demais sons; testar os dados importados, seleção dos três tiros/impactos e
quatro emissões T2 nos ticks8/10/12/14 com pausa, aos 30/60/120 Hz.
MainAction 0x454603/0x45475a/0x4548b7/0x454a10 aponta para a mesma tabela
0x56d224 nos quatro spawns T2; 0x45448e/0x454cc1 cobrem T1/SS. O cliente
Windows não foi executado e a escuta humana permanece verificação separada.

### Continuação: relógio das poses de dano e morte

REQ-09/19/20/45. `tank6.epa` extraído novamente do graphics.xfs de hash
pinado contém `fdamage`/`bdamage` de 25 ticks, `drop` de 20, `item` de 23 e
`dead` de 10, a 20 Hz. REA `ev_1fd0d4848f29281030f1bffe33f56c17f4cf2a920f3913d6b540097f6bd753e6`
identifica `dead` em 0x555c90; 0x462685 chama o seletor virtual de pose com
essa string. `ClassicSprite.frame_index` já utiliza o EPA, mas
`MobileLooks` não marcava o Boomer como animação nativa: `BattleArt` limitava
os temporizadores e aplicava ao dano e à morte os efeitos genéricos de tinta,
rolagem e fade. Ativar o caminho nativo somente para o Boomer, com teste
independente de durações e fronteira, e capturar a cena nas duas direções,
incluindo pausa/retomada. Não inferir desse ajuste uma pose dependente do
vento quando apoiado.

### Continuação: boca fixa no chassis

REQ-04/07/08/19/44/45. O produtor 0x43c860 usa os pares 75°/38 do DAT
para calcular as três bocas por LUT e truncamento; 0x4542a0 soma X e subtrai
Y da posição física. A mira não participa dessa conta; espelhamento e
inclinação sim. `tank6.img` no XFS fixado tem no quadro0 `hy=-35`, altura37
e alpha terminando em y37, logo o último pixel fica 1px abaixo do hotspot.
O renderer atual registra esse hotspot 23px abaixo de `actor.pos` (apoio
visual 24px menos contato1). Usar essa conversão explícita como ponte;
quantização/filtragem da inclinação e o suporte ainda são adaptações. Em
apoio plano, `actor.pos=(500,500)` produz boca `(509,487)` para a direita
e `(491,487)` para a esquerda; a mira deve alterar só a velocidade. Testar
LUT inteira, espelho, inclinação, sinalizador, execução/previsão e colisão;
capturar em GPU. A conversão não prova equivalência integral do apoio nativo.

Resultado: `BoomerFlight.muzzle` aplica o par nativo aos três tiros e a
`Match.muzzle` o entrega também ao sinalizador; a conversão do hotspot e o
arredondamento/filtragem do apoio continuam pontes. O RED inicial detectou
a ausência do helper; o GREEN dirigido passou 899 checks de Boomer. Um teste
de sinalizador recebeu inicialmente a expectativa do sentido oposto ao que
o laço havia deixado ativo; a expectativa foi corrigida e o harness anterior
interrompido, sem usá-lo como prova. Ghidra adicional
`builds/boomer-issue9-muzzle-angle` tem ambos manifestos `ok=true` e confirma
que 0x4f1f10 consulta LUT de ângulo, em vez de `atan2` ideal. Não se anuncia
paridade integral do apoio do porte.

GPU na cena real: `capture_boomer_muzzle.gd`, 540 passos/6 casos, dois
sentidos e ângulos 10/45/90; `capture_boomer_muzzle_slope.gd`, 360 passos/4
casos, rampas e sentidos opostos. Pausa30 e retomada em todos; fonte e
resultados em `docs/boomer-muzzle` e `docs/boomer-muzzle-slope`. A primeira
rodada da fixture plana foi interrompida porque exigia avanço físico no
primeiro quadro de 60 Hz após pausa; a repetição verifica o próximo passo
de 20 Hz. A primeira rampa desenhava o adversário acima do chão; foi
descartada e repetida com o apoio correto. Fixtures e interpolação não são
execução Windows nem prova de 60 FPS sustentados.

GPU `capture_boomer_native_poses.gd`: 720 passos/8 casos, dano frontal e
traseiro, item e morte nos dois sentidos; pausa30 e retomada. Imagens e
relatório em `docs/boomer-native-poses`. Eventos são controlados e não
substituem validação visual humana.

Áudio: `62fire` e `62blast` reproduzidos no Godot têm PCM SHA256
`627deb602845305825b5fb781c86b63e427531de84087a8e07bfef1d00a1ace4` e
`ba2ba01ddfd3cb983acdd9814c9150b3abbad156328d7d56adc816207d747f26`,
iguais às entradas XES pinadas. O teste de cena falhou 4 checks com QOA e
passou 49/0 após reimportação PCM; testa cadência T2 e pausa a 30/60/120 Hz,
seleção T1/SS e impactos. `docs/boomer-audio/boomer-t2-audicao.wav` é uma
mistura de referência construída a partir do PCM original e das quatro
emissões, não gravação da saída do aplicativo. A escuta humana ainda não
foi feita. A reimportação encerrou com código0 e avisos ambientais de CA e
gravação de `editor_settings` em `/private/tmp/boomer-audio-import.log`.

Harness final ADR-147: 113 suítes, 29.215 checks Godot, 92 testes Python em
17 suítes e 29 partidas, exit0/sem falhas. Log
`.tools/boomer-issue9/harness-adr147.log`, SHA256
`f299d75c1151bb2f6609407058af44bc9a433023632bf7b07b0ffe6ed0ee8a79`.
As capturas novas tiveram parse dirigido e execução GPU separados.
O editor headless gerou o UID da captura apoiada após o harness, com exit0;
registrou os mesmos erros ambientais de CA e escrita de `editor_settings`
fora do workspace em `/private/tmp/boomer-adr147-import.log`.

### Continuação: vento sobre a posição do mobile em queda

REQ-04/05/08/19/23/44/45. A vtable do mobile encaminha Animate a
0x461ca0, que chama 0x45cb50 em 0x461d67. No ramo condicionado à flag
+0xbff4 e ao estado global 1 ou 3, 0x45ced6–0x45cf7c lê força e ângulo
do vento, aplica LUT de cosseno `0x4ead90`, trunca a multiplicação por
0x53753c, soma três vezes o resultado ao resíduo +0xbfec, soma o quociente
por 100 ao X e a outro campo espacial e guarda o resto assinado. O divisor
protegido é inicializado com 100 em 0x40daa2. 0x40aab0 confirma soma;
0x45cd1a/0x45cd56 zeram o resíduo na mudança de estado. REA/Hopper
`ev_a9883ebdc7b7e47b8aafbc1d373d65adb19bf02c3584ea83843d7bbc1dd5eb77`,
`ev_d1b0b76ac204c37cd21cf1679f1aabc14365f20036f6a18aba5b31d83df35d1b`,
`ev_e4a6255bc47f706d02165cb660576508cfd4881baaac5ad705063f29cbb905fe`,
`ev_5be1c343549e662c83972dafd4c5896281c967c40c3647374109982a31f14091`;
Ghidra `builds/boomer-issue9-wind-audit` e `boomer-issue9-wind-helpers`,
manifestos `ok=true`. A posição deslocada afeta o corpo durante a queda,
sem provar troca de pose ao vento quando apoiado.

Porte delimitado: aplicar a aritmética de deslocamento somente ao Boomer
no laço atual de queda, com resíduo inteiro por queda e previsão comum;
quantizar força/ângulo do vetor offline. Queda instantânea, bloqueio por
parede, flag de rede e passos verticais continuam adaptações declaradas.
Oráculo: força 10 e ângulo 0 produz incrementos de 30/100: deslocamentos
`0,0,0,1` e resíduos `30,60,90,20`; ângulo 180 espelha sinais; vento vertical
não move. Exercitar quantização, quadrantes, fronteiras e posição final.

1. Extrair despacho/vtable, construtor, atualização, colisão, desenho, EPA e áudio; seguir os dados do vento até o consumidor. Confirmar bytes, sinais, unidades e ordem em ASM; registrar manifestos e lacunas.
2. Conferir DAT e ataque/defesa, climas e itens; preencher a matriz por comportamento antes de modificar cada contrato. Definir esperados independentes nos limites e nos ticks anterior/exato/posterior.
3. Implementar somente contratos sustentados pela prova, compartilhando passo entre partida e previsão e copiando estado novo nos snapshots; manter apresentação fora da colisão.
4. Estender `tests/test_boomer.gd`, exercitar tiro real × previsão, itens e climas; executar `./scripts/check.sh` completo. Capturar GPU nos dois sentidos, vento, pausa/retomada e fronteiras SS; inspecionar logs e registrar limitações.
5. Atualizar SPEC, DECISIONS, TASKS, HANDOFF e MOBILES com resultados reais; não anunciar aceite até completar os critérios da issue.

Validação desta continuação: `test_boomer` 772/0; `./scripts/check.sh`
29.057 checks Godot, 29 partidas, exit 0, parse aprovado; log
`.tools/boomer-issue9/harness-adr143.log`, SHA256
`6ea8bc7b17890bfefea250d7d470f9137546dfeb31d69614916a07d1ebad7d5c`.

## Validação ADR-144 e trabalho restante

`./scripts/check.sh` em produção estável: 29.069 checks Godot e 29 partidas,
sem falhas, exit0, parse aprovado. Log `.tools/boomer-issue9/harness-adr144.log`
SHA256 `711f1b12b445c90d362d4cb60cbedf11be4e922ad0a0d9a41ba7b75843810a58`.
Quatro checks adicionais de Thunder, Teleport e vento após o lançamento foram
acrescentados depois da rodada sem mudar produção: `test_boomer` 788/0,
`test_items` 49/0 e `test_mage_weather_effects` 57/0.

`tests/capture_boomer_weather.gd` executada separadamente na GPU: 540 quadros,
1920×1080, seis cenários controlados, 1/4/1 emissões elétricas e Thor, 30
quadros de pausa idênticos e retomada em todos. Amostras e relatório em
`docs/boomer-weather`, frames brutos em `.tools/boomer-weather/frames`, log
em `.tools/boomer-issue9/weather-gpu.log`. A primeira execução foi interrompida
por indicador de vento incompatível com a fixture; só a final, com força e
vetor em zero, sustenta a evidência. Captura não demonstra 60 FPS real nem
execução do cliente Windows.

Pendentes de aceite: consumidor do vento na animação do chassis; colisão com
minas e variantes/limites da caixa e boca; correlação de orientação e todos
os estágios de impacto com o cliente; GPU de vento/clima durante impacto real,
item que gira vento, Moon/Eclipse e escuta; aceite humano. Os limites de
origem, itens e calendário offline seguem declarados. A issue não está fechada.

## Investigação adicional da boca e chassis

A emissão em 0x4542a0 soma campos +0x090c e +0x53fc para uma
coordenada e subtrai +0x5620 de +0x0b30 para a outra; 0x40aba0/0x40aca0
confirmam soma/subtração (REA `ev_6015ac62d2796ad46a275029999c3febd70715968192d4fd2d9cc25c1c9c15bd`,
`ev_fee8959dc69c6c3f23b7c5a699e89983cf0c655eea7f33dfce27d4cde8e3c3c5`).
As origens dos operandos ainda não foram provadas; a boca genérica continua
adaptação. As strings `tnormal` e `twnormal` são referidas em 0x4216fc e
0x4216f0, dentro de 0x4207c0 (REA `ev_ef72cd3929aaa27de5fc82ff58dc8fb0ff3831543ef4fab88575e9255420ce74`);
isso isoladamente não demonstra relação desses estados com vento. Não foi
executado o cliente Windows.

## Validação ADR-145

Suites dirigidas `test_boomer` 817/0, `test_raon_mines` 33/0,
`test_gold_rewards` 43/0 e `test_items_scene` 49/0. Captura
`tests/capture_boomer_impact.gd`: 360 passos em GPU OpenGL 4.1, 1920×1080,
SS normal e transformado, ambos os sentidos; 30 imagens idênticas durante
cada pausa. Contatos são controlados na cena real, não execução do cliente
Windows nem medição de FPS; a primeira captura foi interrompida porque os
efeitos climáticos cobriam o impacto. Amostras finais e relatório em
`docs/boomer-impact/`. REA exportado em `builds/boomer-issue9-rea-impact.json`
(27 evidências), Ghidra `builds/boomer-issue9-impact-2` com manifestos `ok=true`
e aviso ambiental de CA. Posição da boca e vento no chassis continuam
sem prova; permanecem pendentes os demais limites indicados acima.

A busca posterior localizou o produtor em 0x43c860: 0x43cbf7–0x43cc8f
calcula os operandos +0x53fc/+0x5620 multiplicando o campo +0x9f14 pela LUT
angular com índices `(ângulo+90)%360` e `ângulo%360`, respectivamente,
com conversão por 0x53753c. O ângulo depende de +0x51d8, +0x9cf0 e de
um ramo de orientação. 0x458b80 inicializa os seis campos com objetos de
0x224 bytes; não são inteiros simples. REA `ev_afa3e3292cb36732edf33529a6f06e8eace296268763ecd060c72cb6a0a3cb0f`,
`ev_929b74dd025126429e8b64eb65e1a282fb9c1b6db45670f129e772e4ffcbc0af`,
`ev_ddfc0915208777a90e3be67e1f191852a180f6cf666929dc89a8fbe0a8a3d3cd`;
registro `builds/boomer-issue9-rea-muzzle.json`. A origem de +0x9f14,
a ABI/conversão e os demais tiros ainda exigem confirmação antes do porte.

Ghidra `builds/boomer-issue9-muzzle` (run/manifest `ok=true`, aviso CA):
0x41d937–0x41d950 copia +0xf52b8 do registro indexado por `0xb1ac` para
+0x9f14; +0xf5094 alimenta +0x9cf0. Isso restringe a origem ao registro
do cliente; a identificação dos campos aparece abaixo. A conversão de ponto
fixo e a ordem de inclinação/orientação seguem
sem validação suficiente para alterar `muzzle`.

A base +0xf0384 e stride 0xb1ac correspondem a 83 campos de 0x224 bytes
do characterdata: +0xf5094 é o campo 36 e +0xf52b8 é o campo 37. No
registro Boomer (linha 5), esses valores são 75 e 38, respectivamente;
confere com a distância 38 da adaptação atual, sem provar equivalência da
geometria. `characterdata.dat` foi previamente reextraído e comparado em
BATTLE_SHOT_MATRIX; a identificação decorre da aritmética dos offsets.

Seguimento `builds/boomer-issue9-muzzle-follow`, Ghidra 12.2, ambos
manifestos `ok=true`: 0x45ba50 deriva inclinação do apoio e escreve +0x51d8
em 0x45c0c0, com inversão condicional por +0x1c54. O produtor 0x43c860 usa
esse campo e o ângulo fixo do DAT, não a mira diretamente, e calcula três
pares para as armas. REA `ev_d660bf61cd0fc977c82246154b73ce1951090d100f38f11eb3c38717e372abd2`
e `ev_781c59a5f286d48a3ae5a5f889234d7038cf7c523b0d344643c56304a3a75b05`.
No Boomer, os pares DAT são 75/38 para os três tiros. A inclinação do porte
usa outra amostragem e o pivô espacial/contato ainda é adaptado: a geometria
final e a trajetória visual não foram alteradas sem esses elos.

### Resultados do vento na queda

`BoomerFlight.fall_wind_step` aplica a LUT e acumulação quantizada; o laço
de queda de `Match` a usa só para o Boomer. A posição física e a cópia de
previsão concordam; o teste inclui zero, força1, limites de quociente,
quatro quadrantes, dois sinais e Change Wind após semear um projétil. O
calendário Moon/Eclipse também foi forçado em fixtures com o Boomer,
incluindo a regeneração biónica anterior à cura; os cenários não demonstram
que essas categorias são sorteadas naturalmente em Miramo. Os demais mobiles
mantêm ADR-077.

GPU `tests/capture_boomer_fall_wind.gd`: 1120 passos, 14 casos, 1920×1080,
dois sentidos, vento zero, horizontal e quatro quadrantes, pausa de 30 imagens
idênticas e retomada; amostras em `docs/boomer-fall-wind`. Na primeira rodada
o terreno desenhado não correspondia à máscara da fixture; ela foi descartada
e repetida após corrigir `map_id`. A segunda desenha o mesmo terreno da máscara.
É uma queda instantânea no modelo interpolada na apresentação, não prova do
relógio nativo de queda, de uma pose dependente do vento, ou 60 FPS reais.
REA completo em `builds/boomer-issue9-rea-fall-wind.json`; Ghidra logs
contêm aviso ambiental de truststore/CA. Nesta continuação PE, graphics.xfs e
characterdata foram novamente conferidos; a cópia local de sound.xfs não
foi encontrada, permanecendo apenas a comparação e hash já registrados.

Harness da ADR-146: 113 suítes, 29.146 checks Godot, 92 testes Python em 17
suítes, 13 partidas gerais e 16 clássicas, exit 0. Log
`.tools/boomer-issue9/harness-adr146.log`, SHA256
`2d66da3b9934e5e32614aa2f3fb2b11831ee84242c72dbe8328cd603afac4d1e`.
`test_boomer` foi ampliado antes de sua execução na rodada e passou 861/0;
a nova captura, criada após o parse global, passou em parse dirigido e na GPU.
O editor headless gerou seu `.gd.uid` após a rodada, exit 0, com erros
ambientais de leitura de certificados e gravação de `editor_settings` fora
do workspace em `/private/tmp/boomer-wind-import.log`; não são logs do harness.

Harness final `./scripts/check.sh`: 113 suítes, 29.102 checks Godot, 92
testes Python em 17 suítes e 29 partidas, exit 0/sem falhas. Log
`.tools/boomer-issue9/harness-adr145.log`, SHA256
`f744fb5131398d5d5ecd266275d1a2209a8a810953bdb17c56b1672f3c7bdb97`.
Depois da execução, a captura teve apenas redução dos PNGs salvos e passou
no parse dirigido; a física e o renderer não mudaram.
O editor headless foi aberto depois para gerar o UID da nova captura e saiu
com código 0; registrou avisos ambientais de certificados e de gravação de
`editor_settings` fora do workspace. Eles não fazem parte do harness.
