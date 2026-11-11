# Sondagem das minas Raon — issue #31 / ADR-164

Base origin/main: `33c3c7a7adad8bf344a22549ed8f3f8dd0edf9d8`.
REQ-04/05/07/08/19/44/45; treino offline 1×1, aparência/IDs preservados.

## Fonte e matriz fechada antes do código

Ghidra12.2 headless/JDK26.0.1, banco próprio `/private/tmp/raon-issue31-ghidra`.
Duas consultas novas (ground/init), run.ok/manifest.ok/source_unchanged true.
PE x86 LE32, base0x400000; endereços são VA. Hashes SHA256:
- PE: `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
- characterdata.dat: `b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`.
- graphics.xfs: `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
DAT/XFS conferidos pelo bootstrap; nenhum asset alterado.

| Contrato | Evidência | Estado / consumidor |
|---|---|---|
| Coordenadas inteiras, queda inicialmente falsa | SpawnMine4375f0/SpawnSuperMine437870 escrevem40/264 e byte3fb4=0; vtables5563f0/556380 slot8 | Comprovado / create_mine |
| Sonda por byte de1px, y<0 vira0, x inválido/sem sólido retorna10000 | 4e4340: EDI=x, EAX=y, EDX=terrain; compara18/1c e lê34; sem limite30 | Comprovado / Terrain.native_surface_at |
| h15=sonda(x,y−15) | 498bc4..498c26 / 49223e..4922a0; 40a6e0 SUB | Comprovado / ground_at |
| y<h15: snap se gap≤15; senão inicia queda e zera velocidade somente se ainda não caindo | 498c71..498ceb / 4922e3..4923e2 | Comprovado / settle |
| y≥h15: somente se h15==y−15 consulta h30=sonda(x,y−30) | 498cf0..498e04 / 4923e7..4924ee | Comprovado / settle |
| Somente se h30==y−30 troca chão para sonda(x,y+1); se esta retorna y+1 usa y; caso contrário conserva h15 | 498e42..498f85 / 49252c..492677 | Comprovado / settle |
| Snap NÃO limpa flag/velocidade; queda seguinte usa o chão escolhido | 499015..49912e / 4926fb..492814 | Comprovado / settle |
| Queda y+v<h: incrementa v e y; senão v<5 pousa/limpa; v≥5 y=h−v,v=1 | mesmos consumidores | Comprovado / settle |
| Limites após acomodar: x<0/x≥W/y≥H/y<−200 remove sem blast | 49912e..499217 / 492814..492912 | Comprovado / outside |
| Máscara pronta antes das threads, duas cópias independentes e crateras coerentes | Match.start/FlightSnapshot/Terrain existentes, globalThor | Existente / não ampliar AdukaWeather.active |

O oráculo `tests/tools/raon_oracle/generate.py` executa as duas rotinas do PE
até depois dos limites, preservando SUB/ADD/reads/sonda/ramificações/queda.
Somente inclinação, animação e busca de alvo são stubs; não são provadas por
estas fixtures. 46 casos cobrem camadas, sólido/vazio nas origens, plataforma
1px/grossa, cratera, snap14/15/16, queda/bounce e limites. Nenhum esperado
importa o GDScript. Cliente Windows inteiro não executado.

## Plano de implementação

Execução inline autorizada; skills writing-plans/executing-plans/TDD.
Arquitetura: adicionar somente a consulta Terrain.native_surface_at(x:int,
from_y:int)->int. Raon ground_at usa essa máscara pré-preparada; settle fecha
o ramo comum aos dois tipos. Sem mudança de API pública ou estado novo.

- [x] Regressão `test_raon_ground`: comparar y/flags/velocidade/lost com46casos
  PE; observar RED no settle antigo. Sonda isolada inclui1px/sentinela.
- [x] Implementar helper de terreno e ramo de enterramento; atualizar fixtures
  de terreno artificial para preparar ambas as máscaras antes do uso.
- [x] Snapshot/execução idênticos, fracionamento/pausa, crateras não restauradas;
  confirmar Raon/Turtle/Trico e AdukaWeather.active preservados.
- [x] Captura GPU em camadas/enterramento/cratera, dois tipos e sentidos,
 30quadros de pausa idênticos/retomada; suites dirigidas e harness integral.
- [ ] Revisão independente, documentação final, commit/push/PR; quatro gates,
 rebase merge e CI/release da main. Sem publicação manual/bump de versão.

Focos: seleção de camada preserva h15 quando h30 não começa sólido; sentinela
10000 não vira chão fora do mapa; crateras em ambas as máscaras/cópias;
flags persistem até pouso; preparo1px nunca seleciona contato de projétil.
Movimento horizontal/agenda/itens/dano de minas/clima particular continuam as
pontes declaradas anteriores. Esta entrega não fecha o porte integralRaon.

## Registro de execução

- Bootstrap pinado concluído; primeiro bloqueio de escrita na pasta irmã de
 áudio legado foi resolvido executando o mesmo bootstrap autorizado fora do
 sandbox. Nenhuma pasta mutável de outra sessão foi copiada.
- Baseline dirigido8suítes/1268checks/0falhas. A primeira importação no sandbox
 registrou erro ambiental de certificado `ret != noErr`; a execução nativa
 repetida passou. Não se usou override de certificados.
- RED: test_raon_ground586checks/88falhas pelo comportamento antigo, não parse.
 GREEN final:787checks/0,46cenáriosPE. Dirigidas13suítes/7238checks/0falhas,
 incluindo TricoT2/SS e TurtleT2/projéteis; loggreen-directed-final.log.
 Primeira tentativaGREEN teve erro de inferência em `upper`; anotaçãoint
 corrigiu o parse antes da rodada verde. Sem enfraquecer assertivas.
- OráculoUnicorn2.1.4 em ambiente Python externo somente leitura, JIT fora
 do sandbox; regeneraçãoCLI idêntica porcmp; PE divergente rejeitado antes
 da saída. CLI teve sombreamentoargs detectado pela regeneração e corrigido.
- GPU330quadrosFullHD,60Hz manual,7minas iniciais,3explosões observadas;
 pausa90..119 idêntica no bufferRGBA, retomada120 diferente. Pillow conferiu
 independentemente todos os10PNGs de pausa salvos. Sequência/6stills em
 docs/raon-ground-native; loggpu.log/jornal em .tools/issue31/frames.
- Pacote via scripts/ci/package.py macos: ZIP extraído universal, assinatura
 ad-hocdeep/strict, UI+48tiros+Ice+Trico+Raon enterrado aprovados. Versão local
0.20.5, manifest aponta base33c3c7a7 pois export pré-commit; sem publicação
manual/bump. Template localmacos.zip SHA256
`88df5e2e6fee99088699be66e6d42e4da4fb0c5619d054297d755a49558a4792`;
editor/template executados reportam4.7.2. Logs package.log e .tools/package-logs.

Revisão independente `/root/review_raon`: sem achados acionáveis pendentes.
Conferiu ASM/ABI, hashes/manifests, regeneraçãoUnicorn idêntica, cópias/crateras,
seleção de contato, logs dirigidos/pacote e PNGs da pausa. Harness integral final exit0 em351,293s:365parses,117suítesGodot/60.180checks,
160Python sem skips/falhas e29partidas. CoberturaPython62% (somente scripts/ci,
piso40%) e inventário/guard900s/pool4 preservados. Logs inspecionados: sem
SCRIPT ERROR/ERROR/leaks nas suítes; o textoFAIL do testePython de worker
quebrado é saída esperada da regressão do runner, unittest160/OK.
Ruff/diff aprovados. Relatório bruto em docs/raon-ground-native/harness-report.json.
Gates remotos ainda pendentes; integrar somente por quatro gates/rebase merge.
