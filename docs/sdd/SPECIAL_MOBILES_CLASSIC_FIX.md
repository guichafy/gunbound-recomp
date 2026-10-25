# Correção ASate, JD, Aduka e Raon — REQ-04/05/07/08/09/19/44/45

Solicitação de 25/10/2026: corrigir tiros, animações e características dos
quatro mobiles conforme o cliente Gunbound Classic. Não muda o elenco,
avatares, equipamentos, perfil, mapa ou escopo offline.

## Contrato e plano de implementação

O cliente fixado em `gunbound-client-port/references/project.md` prevalece.
Ghidra direto, ASM, tabelas e consumidores fundamentam cada correção;
lacunas mantêm adaptação declarada. Os registros por família guardam a
origem, a derivação independente e os resultados de validação:
`ASATE_CLASSIC_FIX.md`, `JD_CLASSIC_FIX.md`, `ADUKA_CLASSIC_FIX.md` e
`RAON_CLASSIC_FIX.md`.

- [x] Reproduzir os defeitos com testes antes das alterações compartilhadas.
- [x] ASate: guia sem dano artificial, Ion e filhos T1/T2/SS (1/3/6), com
      cronologia/arte e autoria por tiro.
- [x] JD: cristal de atração T2 e efeito numérico SS; não integrar cristal
      como projétil em queda. Relógio físico separado da EPA desenhada.
- [x] Aduka: T2/SS acionam Thor fora do clima Thor; separar guia e feixe,
      conferir contagens/obstáculos/nível e mostrar recursos originais.
- [x] Raon: três componentes T1 e estados próprios das minas T2/SS;
      conservar autoria e Gold após troca de turno.
- [x] Integrar módulos ao passo comum em `match.gd`, fábrica e catálogo;
      estado persistente explícito, cópia profunda no `flight_snapshot.gd`.
- [x] Renderer consome estados e relógios do modelo; pausa não avança clocks.
- [x] Rodar testes por família, integração real/previsão, itens/atributos/
      Gold e harness completo com partidas.
- [ ] Sequência GPU temporal: bloqueio ambiental antes do primeiro quadro.
- [x] Atualizar decisões, tarefas e handoff com resultados e limites reais.

## Arquitetura de integração

`match.gd` conserva turno, dano e resultado. `battle_effects` guarda efeitos
que continuam após o impacto do guia e `satellites` guarda posições próprias
quando necessário. Ambos entram no snapshot; o turno não termina enquanto
um efeito ativo ainda puder emitir filhos ou aplicar uma regra. Nenhum
renderer decide colisão, dano ou nascimento. Os módulos por família são
pré-carregados; o worker não carrega arquivos/recursos.

Fixtures devem cobrir dois sentidos, ticks de transição, pausa, Dual/Dual+,
Teleport sem especial herdado, autoria após troca de turno e isolamento da
previsão. Captura Godot é validação do porte, não execução do cliente nativo.

## Revisão de integração

Revisão independente encontrou e reproduziu: candidato vazio da CPU para
Thor/plantio, troca de turno antes da mina SS acabar, input antes da agenda
S2 e perda de Thunder/Thor anexos no plantio. Todos receberam testes RED e
correção; a suite também impede multiplicar Thunder pelos filhos ASate.
`test_special_mobiles_integration.gd` compara eventos/atores/terreno/minas/
efeitos/satélites real×previsão, dois sentidos, Dual/Dual+/Teleport e cópias.

O teste antigo de roster ainda media o cartão anterior da sala e procurava
dificuldade entre os botões de mobile. Foi ajustado somente para o popup e
o Aceitar vigentes da ADR-092. Alterações simultâneas da sala (ADR-095)
foram preservadas; duas inferências Variant por `round` viraram `roundf`.
Uma rodada encontrou esses arquivos durante edição e foi interrompida;
os testes de cena passaram novamente antes da rodada final.

## Limite de QA visual observado

`tests/capture_special_mobiles.gd` prepara três armas×dois sentidos por
mobile, 1920×1080, pixels1:1, 300 quadros/mobile a60Hz, pausa30 quadros e
retomada. Parse aprovado. A execução GPU abortou antes do primeiro quadro:
exit134/SIGABRT em FontRegistry/`___RegisterApplication_block_invoke`.
Alternativa por LaunchServices (`open -na`) retornou kLSNoExecutableErr
−10827 apesar do executável existente. A tentativa Node ficou sem resposta
e foi interrompida. Nenhum PNG/MP4 nem validação visual são reivindicados.
Registro local: `.tools/special-mobiles-fix/gpu-attempt.json`; crash macOS
`Godot-2026-10-25-001419.ips`. Não há resultado visual antigo que valide esta
correção. Aceite do usuário, escuta e execução dinâmica do cliente pendentes.

## Pacote 0.20.5

`python3 scripts/build_macos.py` reexportou app e ZIP. Assinatura profunda/
estrita, versão0.20.5, bundle/executável e CRC do ZIP conferidos. Probe do
PCK em diretório isolado:68 checks/0 falhas/exit0, carrega16 sprites, módulos,
texturas, WAV/JSON e dispara/prevê12 armas dos quatro mobiles.
PCK SHA256 `aed815614c4f052a53289c12f9013a3b97c378da40af5c70347eb942a8ba573c`.
ZIP SHA256 `aaf774711fb472c26a196c7fe07ab7e021d00f7fa9b33e01d567c471832d9b0e`.

Ressalvas ambientais: export/import não conseguem ler CA do macOS nem salvar
editor_settings no perfil; PCK isolado registra o erro de CA, sem erro de
script/leak. O probe final usa log absoluto gravável; a primeira tentativa
também encontrou o log padrão sem permissão. Nenhum override/TLS foi criado
ou embarcado. Logs em `.tools/special-mobiles-fix/`. Commit local autorizado
pelo usuário em25/10/2026; sem push.

## Verificação final

`./scripts/check.sh`: **11493 checks Godot,29 testes Python,29 partidas**,
zero falhas, exit0 e parse aprovado. Log final:
`.tools/special-mobiles-fix/final-harness.log`. As69 suites enumeradas pelo
harness incluem novas suites por família, renderer/recursos e integração;
contagem específica de suites conferida no log, sem usar resultados antigos.
Integração263/0; ASate80/0, JD80/0, Aduka93/0, rendererThor16/0,
Raon168/0; provas Python Raon5/5, texturaThor2/2, áudioIon3/3.
`git diff --check` aprovado. CapturaGPU/escuta/aceite visual permanecem
pendentes conforme bloqueio acima. Versionamento local autorizado; sem push.

Após a última edição simultânea de `menu_screen.gd`, repetidas as seis suites
de sala/cena/roster/itens:184 checks/0. App reexportado, assinatura/CRC e
PCK68/0 revalidados. Nenhum script de runtime é mais novo que o PCK final;
hashes acima correspondem a essa última exportação.
