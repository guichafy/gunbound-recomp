# JEWEL: ciclo de vida, geração e pilotos — evidência independente

13/11/2026. PE SHA256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Ghidra12.2/JDK26, banco exclusivo `/tmp/gb-jewel-impl-lifecycle`. Nenhum
runtime/SDD compartilhado alterado nesta pesquisa; nenhuma fonte OpenBound.

## Contratos fechados

1. **Dano em piloto.** `45db20`, `45e8a7..45e8bd`: após cálculo e pose,
   `mode==3` salta para `45ea1b`, evitando HP, números de dano, autoria e
   contadores de dano. Não eliminar contato, deformação de terreno ou pose
   por esse gate. O shock (`45ea40`, q07) igualmente testa modo3 antes de
   subtrair HP. Efeitos próprios `48d8e0` e `48f300` têm gate `mode!=3`
   antes de HP/stats (q07). A ausência de HP por blast não era conclusão
   suficiente sozinha; esses consumidores ampliam a evidência. Não foi
   executado o cliente nem o conjunto completo de todos os48tiros.

2. **Queda de piloto.** Todos16 vtables de mobile referenciam `461ca0`
   (q05.entry-refs). Em `462625..4626eb`, com Y>=altura, flag `actor+bff4==1`
   e modo1 ou3, usa pose `ice` (`555c90`), grava global temporário
   `context+6240c=5`, e para ator local `battle+93=1`/câmera desativada.
   Grava `ae14=1`, `bff4=false`, `bff7=true`. Não subtrai HP nem pontos
   aqui. **Esse5 não é penalidade de placar:** o endereço é `6240c`, distinto
   dos placares `67e3d0/67e5f4`. A rotina de queda/drop é `45cb50` (q06).
   Espera de reposicionamento não deve chamar término por HP de SOLO.

3. **Escolha de retorno.** UI `4b97d0` (entrada confirmada pelo prólogo
   `SUB ESP,0x88`, não pelo VA interno `4ba8d2`) envia mensagem `8408`
   quando `battle+93` está ativa. Em JEWEL grava WORD `turn_counter+2`
   (`4ba8e1..4ba919`), fora JEWEL `+4`. X é escolhido pelo mouse no mapa:
   `camera_x + mouse_x - 400`, WORD (`4ba942..4ba96c`), não sorteado.
   CampoDWORD seguinte é10 quando campo protegido do ator em
   `ebef4+slot*224`<10; senão `45d360(0)/2` truncado. `45d360` calcula
   delay e não HP. O header fornece o slot. Emissor limpa `battle+93`.

4. **Fila/tempo.** Dispatcher `4b5460`, mensagem8408 (`4b6275..4b62bf`),
   insere WORD prazo em `battle+8a0`, WORD X em`+aa0`, slot em`+ca0`,
   DWORD delay em`+ea0`, incrementa quantidade`+89c` e ordena por`4ccc60`.
   `4ce3d0` compara `prazo<=context+eba98`. Esse contador avança1 por
   troca de turno em `4d0a10`/`4d0d39..4d0d4a`; não é segundos.
   O prazo começa no **clique de retorno**, não automaticamente no void.
   O consumidor espera o término de efeitos (`43c820`), pega o ator pelo
   slot e só reativa quando `bff7==true`: pose drop, `bff4=true`,
   X=escolha/Y=0, limpa movimento/acumuladores, remove objetocategoria186a7
   do slot e aplica atributos por41c360. Limpa `bff7` e`ae14`; instala
   delay em`actor+bfb8`. Consome a entrada mesmo sem ator/flag válida.

5. **HP no retorno.** Apesar de4ce3d0 não escrever HP diretamente, chama
   **41c360**. ASM `41d291..41d2c9` carrega máximo da tabela de espécie
   (`context + species*b1ac + f34c0`) em`actor+6db0`, depois copia
   `6db0→6fd4` (HP atual); `41d2da..41d2ee` copia também para71f8
   (apresentação). Portanto retorna com máximo nativo, não HP recebido
   noDWORD8408. Pseudocódigo41c360 tem ABI incorreta: use os registradores
   EBX (ator), EDI (destino protegido), EAX (leitor) do ASM.

6. **Geração inicial.** UI Start `4d54e0`, `4d569e..4d575c` envia3430 e,
   em modo3, seis pares: `WORD rand()` seguido de `BYTE(rand()%100)`
   (100=global796aa0, default). Parser`4d45e0..4d464f` lê seis pares
   em arrays `context+6a81b8`/`6a8e90`, stride224. Setup4bb730 tenta
   os seis, X modulo largura. Fábrica438410 procura primeiro slot livre
   0..7, rejeita sem slot/coluna sem terreno, varre coluna desdeY0 e
   cria em primeiro pixel sólido+1. Seis tentativas, não seis garantidos.

7. **Tipos.** O primeiro limiar é global794bf0, default **15**, comprovado
   em`40d9d2..40d9d9`, seguido de40 e80: roll0..14 tipo0(+25),
   15..39 tipo1(+10),40..79 tipo2(+5),80..99 tipo3(−5).
   Não é25% por tipo. O módulo de CRT15bits introduz pequeno viés.

8. **Reposição.** Gerador41f200, `41fb2f..41fbdf`, em modo3 e contador
   `context+6a7f94<6`, envia flag0, BYTE`rand()%100`, WORD`rand()`;
   senãoFF. Parser41ebf0, se modo3 e flag!=FF, ativa `6a7f90`, grava
   roll eX. `4cf310` estado1 consome/limpa flag e tenta um drop.
   A ordem RNG de reposição é **roll antesX**, inversa da inicial.
   Não há laço para preencher tudo até6. A tentativa ocorre por atualização
   de turno que chama41f200, não por todo tick nem todo projétil.

9. **Contador e drops.** `6a7f94` inicia0;438410 incrementa somente ramo
   inicial normal (`438874..438885`). Drop começaY0 sem incrementar.
   `479ba0` incrementa ao aterrissar (`479e94..479e99`) e então limpa
   flagdrop. Remoção fora do drop decrementa (`47a72a..47a72f`).
   Portanto limite de reposição6 conta jewels estabelecidos, não todos
   os slots ocupados; teto físico8 continua distinto. Durante drop,
   remoção/void **não** transfere pontos: `47a276..47a29d`, flagdrop1
   salta toda pontuação. O dano durante drop não está demonstrado como
   proibido por essa flag.

10. **RNG.** CRT525c4f: `state=(state*214013+2531011)&0xffffffff`,
    retorno`(state>>16)&32767`. O programa também consome esseCRT para
    ofuscação de campos/UI; reproduzir apenas a sequência de jewels é
    adaptação de stream privado, não replay integral doCRT global.

## Agenda, passe, SS e prêmio

- A cadeia normal de avanço termina no estado1de4cf310, cria drop pendente,
  passa por fila de retorno4ce3d0, efeitos4cea70/4cee30 e retorna ao início.
  Jewels não substituem iniciativa por time. Piloto aguardando retorno tem
  flags diferentes de piloto ativo; não marcar permanentemente morto.
- SS usa as verificações existentes de arma/itens e`bfbc` nos consumidores
  4ccd10/4b97d0, sem ramo especial JEWEL nesses gates. A pesquisa não
  comprova nova regraSS por serJEWEL. Não liberar/retravarSS arbitrariamente.
- A função41f200 tem nove consumidores documentados emq09.entry-refs,
  incluindo emissão de fim de ação, itens e atualizaçõesC308. A política
  exata do passe deve ser ligada ao consumidor real, sem criar segundo
  jewel na mesma troca. Não executar reposição em`fire()` por projétil.
- Blocos de prêmio/Gold por eliminar piloto em4ccd10 e dispatcher4b5460
  são pulados emmodo3; placarJEWEL pertence à remoção de jewel479ba0.
  Nenhum ganho de placar por matar piloto ou débito por void foi encontrado
  nos consumidores fechados. Isso não justifica zerar Gold do resultado.
- Ponto de integração proposto (derivado): gate deHP emDamage.deal e
  caminhos diretos equivalentes preservando contato/terreno/push/pose;
  impedirGoldRewards de registrar dano/kill inexistente. Void exige hook
  de modo antes da morte SOLO, mantendo ator e estado de espera. Retorno
  deve usar dadosmaxHP do ator/espécie e agenda comum.

## Limites e adaptações que ainda precisam de escolha explícita

O cliente exige interação do jogador para escolher X de retorno. Uma CPU
offline e um retorno automático precisam de política declarada. Sem UI
extra, o projeto deve declarar a escolha deX e o momento de agendar+2.
A conversão entre contador nativo de trocas e agenda offline deve preservar
limiares anterior/exato/posterior e não contar cada explosão como turno.
A criação/dano completo e ordenação simultânea estão fora deste recorte.
Não há execuçãoWindows/GPU/escuta, nem emulação de todas funções nesta entrega.

## Validação e reprodução

`tests/tools/jewel_oracle/lifecycle_contract.py` lê PE pinado, valida bytes de
seis gates/constantes e produz `lifecycle-fixtures.json`: fronteiras15/40/80,
contagens5/6/7, prazoN−1/N/N+1 e CRT com cinco seeds. É **traduçãoASM com
bytes conferidos, não execuçãoPE**. O runtimeGodot não participa dos esperados.

Consultas completas aprovadas: q01,q02,q06,q07,q09,q10,q11 (run/manifest.ok).
Consultasq03/q04/q05/q08 foram parciais: endereço45354 não éVA legível;
VAs internos não reconhecidos retornaram function_not_found. Os resultados
individuais aprovados são úteis, sem promover a consulta parcial a sucesso.
Não semear os pontos internos. q09 semeia entrada já confirmada4d54e0;
q10 semeia4b97d0 com prólogo/limite confirmado emobjdump. PE intacto.

## Adendo: passe e penalidade (consultas q13/q14 aprovadas)

`4b82b0` é a entrada UI antes ausente (prólogo confirmado com leitura do
primeiro argumento seguido deSUB ESP,80). Case3 é o botão skip, criado no
setup sob índice3. EnviaC301 com `45d360(1)` e chama41f200(0) em4b8e5f.
Não tem exceçãoJEWEL: portanto passe também tenta a mesma reposição quando
contador estabelecidos<6. O passe não deve criar duas tentativas em hooks
separados. C301 no dispatcher4b5460 agenda o custo e conservaSS pelos gates
existentes. A evidência não exige alterar o passe200 já adaptado do porte.

O débito−1 por piloto encontrado em4b5394 é exclusivo do modo1: ASM
4b530aPUSH1→4b5313compare→4b531aJZ salta os débitos emoutros modos.
Assim essa penalidade não é regraJEWEL. O caminho também distingue ator já
emespera+bff7. Não deduzir perda de pontos do global6240c=5.
