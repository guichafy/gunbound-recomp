# Bigfoot e Mage originais — 0.20.3

REQ-12/19/20/45; solicitação de restaurar a arte original dos dois mobiles,
seguindo o pipeline usado no restante do elenco. Substitui a preservação do
HD desses dois mobiles na ADR-088. Avatares, equipamentos e demais HD seguem
preservados. Não altera regras, IDs, perfil, física, salvas, dano ou áudio.

## Plano e aceitação

1. Extrair tank2 (Mage) e tank5 (Bigfoot), EPA, RiderPivot, projéteis/luzes e
   impactos do graphics.xfs já disponível, com hash fixo do importador.
   Salvar em subpastas `original/`; conservar todos os arquivos anteriores.
2. Usar ClassicSprite na apresentação ativa, com escala nativa igual aos
   outros mobiles, contato pré-calculado e durações EPA. O render original
   não deve passar pelo rig HD nem pelas cabeças/impactos gerados.
3. Mage T1/T2 preservam as texturas originais S1T/S2T já disponíveis no
   OpenBound e sua composição atual; não inventar um sprite de bala ausente
   do XFS nem anunciar paridade integral do laser nativo. SS usa bullet2p e
   ssflame2 originais. Bigfoot usa bullet5n/s/p e flame51/52/53.
4. Validar fontes/pixels e runtime, ambos os sentidos, poses, avatares,
   tiros/impactos, pausa, menu/loja/batalha e os demais mobiles. Rodar harness
   integral; exportar app/ZIP, conferir assinatura e recursos no PCK.

As descrições de rig/projéteis HD anteriores ficam como referência histórica;
nenhuma imagem HD é apagada. O catálogo ativo escolhe sprites originais.

## Evidência e limites

Implementado. Mage: 410 quadros, quatro folhas de efeitos/projétil. Bigfoot:
469 quadros, oito folhas. Importador e oráculo Python conferiram todos os
pixels, hotspots e RiderPivot contra o XFS; estados/durações de recoil T2
conferidos contra a EPA. Arquivos antigos e imagens HD não foram alterados.

Regressão ativa RED: 16 checks / duas falhas (ambos ainda usavam HD). GREEN:
39/0. Harness integral final: **8059 checks Godot, 17 testes Python e 29 partidas
(13+16), zero falhas, parse completo aprovado**. Log:
`.tools/original-mobiles/full-check-final.log`. Uma primeira rodada acusou
falhas por CA ambiental e 12 expectativas antigas de mira HD em test_hud;
expectativas atualizadas para a escolha original, rodada final aprovada.
Apenas para o harness foi usado override local de CA `/etc/ssl/cert.pem`,
removido antes de exportar e ausente do ROOT/PCK.

GPU pelo editor nativo: **1920×1080, 210 quadros com relógio de 60 Hz**,
poses, inclinações, sentidos, tiros e impactos. Galeria usa fixtures de
apresentação e o catálogo ativo de Game, não simulação de tiros reais.
Os 30 quadros 120–149 de pausa têm hash idêntico; movimento após retomada
inspecionado em quadros anteriores/posteriores. PNG/MP4 e hashes em
`docs/original-mobiles/`. Empilhamento do EMP ampliado cruza o painel da
galeria: não é uma captura do layout da arena. Avatares HD atuais mantidos.
O SS Mage chega ao seu ssflame2 original e Bigfoot T2 ao flame52 próprio.

App e ZIP **0.20.3** reexportados por `scripts/build_macos.py`: assinatura
profunda/estrita e Info.plist válidos, ZIP CRC válido. Smoke isolado do PCK
em `/tmp`: **44/0, exit0**, conferindo 16 sprites, recursos nativos, JSON/EPA,
lasers, miras, auras, áudio e avatar HD. Sem SCRIPT ERROR/leaks. Único ERROR
do smoke: `get_system_ca_certificates`; export também registra a restrição
ambiental de gravação de editor_settings. Logs em
`.tools/original-mobiles/{build,pck}.log`.

Limites: não houve execução do cliente original, escuta, mouse manual ou
aceite visual do usuário. Nova captura automatizada específica de menu/loja/
arena foi preparada e passou no parse, mas sua execução posterior ficou
bloqueada por timeout do controle UI; a evidência visual concluída é a galeria.
Navegação, loja e batalha foram cobertas pelas suites de cena/modelos. Mage
T1/T2 conservam a composição adaptada do OpenBound, sem alegação de laser
nativo integral. Nenhuma mudança de regra de combate, commit ou push.
