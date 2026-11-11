# Bigfoot — issue #28

[Contrato, fontes, plano e limites](../sdd/BIGFOOT_COMBAT_ISSUE_28.md).

Três sequências Godot/OpenGL/Metal, Apple M4 Pro,1920×1080. Cada vídeo tem
301quadros com T1/T2/SS nos dois sentidos. Passo manual1/60s, modelo20Hz;
não representa benchmark de desempenho nem execução do cliente Windows.

- [Normal e vento8/−3](normal.mp4): [voo](normal-090.png), [crateras](normal-240.png).
- [Tornado e vento−8/3](tornado.mp4): [voo](tornado-090.png), [impactos](tornado-150.png).
- [Force, eletricidade, Thor e vento−8/3](attachments.mp4): [anexos](attachments-150.png).

Os30quadros45–74 de cada sequência têm RGBA idêntico e modelo congelado;
retomada termina com4/6/8impactos por sentido e zero shells. Contagens e
posições estão nos manifests de cada sequência. `validation.json` registra
hashes RGBA/MP4; o revisor independente também comparou os90PNGs de pausa.

`evidence.json` resume as três consultas Ghidra12.2/JDK26 da sessão, incluindo
identidade, funções, vtables e manifests aprovados. `native-instructions.txt`
preserva trechos essenciais; o PE/DAT não é redistribuído. O oráculo
reproduzível fica em `tests/tools/bigfoot_oracle`, com saídas em
`tests/fixtures/bigfoot_native.json`.

Arte, smoothing4×, fontes de áudio e catálogoEPA não foram modificados.
Sem escuta, input ou aceite visual humano; geometria do hotspot/muzzle e
ativação de itens offline continuam pontes declaradas. Pacotes finais são
validados pelos workflows existentes, sem publicação manual adicional.
