# Colisão de terreno no build — REQ-04/07/08/19/32/44/45/51/52

## Escopo e plano (08/11/2026)

Relato do usuário na versão macOS 0.22.0: T1 do Grub explode logo após sair;
T2 não interage com o chão. Investigar também dependências compartilhadas.
Não mudar regras nativas, arte, perfil ou versão; não publicar.

1. Confirmar identidade do ZIP 0.22.0 e comparar inicialização no código/PCK.
2. Reproduzir máscara vazia sem Mage/Lightning/Aduka, cobrindo Grub/Boomer,
   ambos os lados, terreno real/procedural, cópia da CPU e reutilização de partida.
3. Criar regressão vermelha antes da correção e centralizar a relação dos
   consumidores da máscara nativa, preparada em Match.start antes de threads.
4. Ampliar smoke embarcado: carregar terreno e executar tiros dos 16 mobiles,
   três armas, com adversário Bigfoot (sem habilitação incidental da máscara).
5. Rodar regressões e partidas completas; comparar diagnóstico no release
   original e em pacote local corrigido, com logs e perfil isolado.
6. Registrar causa, efeitos, resultados e limites em DECISIONS/TASKS/HANDOFF.

## Evidência inicial

Release v0.22.0: commit a6246e40e6f5dde4c95573a06b3e39c9b6f2019a.
ZIP macOS SHA-256 2afdbc0b1d4ed148c5e6513bec8325e2792497e54a536ed0719d40d8cbc328b6
confere com o digest do GitHub. Código do tag tem a mesma condição de
Match.start: somente IDs 1/8/16 ativam Terrain.enable_native.
AdukaWeather.active consome a máscara nos IDs 1/6/8/13/16; Grub T2/SS
consomem diretamente terrain.native_cells. Testes anteriores do Grub usam
CPU Mage e/ou preenchem a máscara manualmente, ocultando a omissão.
Sonda local: Grub×Mage e Lightning×Bigfoot têm 3.240.000 bytes nativos;
Grub×Bigfoot, Bigfoot×Grub, Boomer×Bigfoot e Bigfoot×Boomer têm zero.
Logs/artefatos locais: .tools/grub-build-audit/ (ignorados pelo Git).

O smoke atual da CI abre lobby/sala/loja; não inicia combate. Esta lacuna
permite publicar pacote sem verificar o contrato de colisão dos tiros.


## Reprodução no template release e correção

ZIP original extraído e assinatura conferida. Para não acessar o perfil real,
a sonda usa uma cópia do executável original com PCK de entrada diagnóstico;
o diagnóstico monta o PCK original 0.22.0 e carrega seu Match compilado.
`OS.is_debug_build() == false`. Não é uso manual da GUI nem modificação do
ZIP baixado. O template original bloqueia `--main-pack`; a sonda por isso
substitui apenas o PCK de entrada na cópia de diagnóstico.

| Grub × Bigfoot, seed 42, 45°/30% | Original 0.22.0 | PCK corrigido, mesmo executável release |
|---|---|---|
| Máscara nativa | 0 bytes | 3.240.000 bytes |
| T1 | explode tick 2 em (916,1336), ainda no ar | explode tick 30 em (1206,1411), plataforma |
| T2 | atravessa plataforma; termina ticks 88–90 em y1782 | ricocheteia na plataforma; termina ticks 72–74 em y1393–1426 |
| SS | atravessa plataforma; termina tick 86 em y1783 | ricocheteia; termina tick 70 em (1149,1421) |

Os ricochetes contados no pacote defeituoso são respostas próximas das bordas;
não comprovam contato com a superfície visível. O log original registra erros
ambientais de diretório/CA no sandbox, além do defeito: a repetição corrigida
fora dessa restrição não os apresenta. Nenhum SCRIPT ERROR foi registrado
nos tiros defeituosos, reforçando a necessidade de assertivas comportamentais.

Correção mínima: `AdukaWeather.NATIVE_TERRAIN_VEHICLES` compartilha a lista
1/6/8/13/16 com Match.start. Máscara preparada antes das threads/cópias;
nenhum fallback tardio oculta falta de inicialização ou recria crateras.
Boomer e Grub eram os consumidores omitidos; Mage/Lightning/Aduka já tinham
preparo. Outros mobiles passam pelo smoke para detectar efeitos indiretos.

## Regressões observadas

- Teste novo `test_native_terrain`: primeiro 324 checks/107 falhas; após correção
  e cobertura de execução/previsão, 477 checks/0. Cobre cinco consumidores ×
  16 adversários × dois lados × dois terrenos, reinício e isolamento da CPU;
  24 disparos adicionais de Grub/Boomer com igualdade de eventos/atores/
  projéteis/máscaras entre execução e snapshot, e previsão sem mutar terreno.
- `test_ci_combat`: 221 checks/0, 48 disparos de todos os mobiles contra Bigfoot,
  usando terreno real e sem preenchimento manual. Nak SS é exceção explícita
  para travessia; Raon T2 observa minas e Aduka T2/SS observam Thor.
- `test_ci_smoke`: 9 checks/0; total dirigido 707 checks/0.
- `test_ci_packages.py`: 12 testes/0; teste novo reprova o gate antigo que
  aceitava apenas UI (vermelho antes da alteração, verde depois).
- PCK corrigido no template release original: lobby/sala/loja, 48 disparos,
  `PACKAGED COMBAT: PASS (48 shots)` e `PACKAGED SMOKE: PASS`, exit0.
- Revisão independente somente leitura: sem achados acionáveis; revisor
  repetiu os 12 testes Python e diff sem erros.

Empacotamento local concluído: `scripts/ci/package.py --platform macos`
(Godot 4.7.2, Python 3.12.14), exit0. ZIP extraído em diretório temporário
fora do projeto, arquitetura universal, assinatura deep/strict válida e
smoke de UI + 48 disparos aprovado; sem ERROR/SCRIPT ERROR no log final.
Ruff (E9/F63/F7/F82) e diff sem erros. App/ZIP mantêm 0.20.5, a versão do
checkout; são artefatos locais com alterações ainda não commitadas, não
uma nova release 0.22.0. O campo commit do manifest é a base HEAD4b42bfdf,
não identifica sozinho o working tree; hashes dos fontes efetivamente
exportados estão em `.tools/grub-build-audit/source-hashes.json`.
ZIP local SHA-256:
`8a201577009897d660c0b5827eff22d02917900850d369ca1112d805bd0cf768`.
A release pública 0.22.0 não foi alterada.

Harness integral final: `.tools/ci-speed-py313/bin/python3 scripts/ci/check.py
--workers 4`, exit0 em304,292s: 348 scripts/capturas compilados,109suítes
Godot/48.540checks,29partidas (13seeds+16mobiles) e156testesPython, zero
falhas/skips. CoberturaPython da automação62%, acima do gate40%. Relatório
`.tools/check-logs/report.json`, cópia em `.tools/grub-build-audit/`.
`test_native_terrain`477/0, `test_ci_combat`221/0, `test_grub_model`311/0,
`test_grub_flight`15.690/0; desempenhoCPU19/0. Nenhuma falha ambiental
permaneceu na rodada integral final. Não publicar/enviar sem pedido.

## Limites da entrega

Cliente Windows original, pacoteWindows, capturaGPU e aceitevisual/input/
escuta humanos não foram executados nesta correção. A prova no release
macOS é de execução automatizada dos modelos carregados do PCK e do smoke
do ZIP, não uma sessão manual de jogo. Perfil real não foi usado; fontes,
arte, regras nativas e versão preservados. Não houve commit/push/release.
Para distribuir a correção, ainda é necessário versionar e gerar uma nova
release a partir destes fontes, mediante solicitação do usuário.


## Pedido posterior de publicação (08/11/2026)

Usuário autorizou commit/push e nova versão para validação macOS. A árvore
base da correção é idêntica à main/tagv0.22.0 a6246e40. Entrega pela branch
`codex/fix-native-terrain`, PR com quatro checks obrigatórios e integração
por rebase; CI calcula0.22.1 a partir de commitfix, exporta, extrai/testa ZIP
e publica somente após aprovação dos dois pacotesdesktop. Preservar
project.godot baseline e políticas de proteção; não alterar a release0.22.0.
Resultados remotos serão informados ao concluir a entrega.
