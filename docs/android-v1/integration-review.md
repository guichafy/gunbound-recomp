# Revisão final independente — delta de fechamento Android

15/11/2026. Somente leitura do delta após ui-review.md/ci-review.md: conexão
real de Back, extração JDK, troca diagnóstico/candidato, coordenadas/matte,
helper local macOS, OCR Vision por palavra e documentação. Não executei novas
suítes, builds ou comandos no AVD. O smoke GUI real continuava sob controle
do coordenador; este parecer não antecipa seu resultado.

## Resultado

**Nenhum P1/P2 novo confirmado nesse delta de fechamento.** Os bloqueios
anteriormente enviados foram tratados no código observado. Aprovação de
revisão de código não equivale a aceite Android físico nem a CI remota verde.

## Correções observadas

- Game._ready desabilita SceneTree.quit_on_go_back e conecta diretamente
  Window.go_back_requested a handle_back. A notificação WM local foi retirada
  desse roteamento. O teste agora emite somente o sinal real da Window ao
  conferir loja→lobby e sala→lobby, sem chamada manual que mascara ausência
  de conexão ou produz dupla navegação.
- handle_back mantém a trava de retomada e sua UI; fechar overlay não libera
  lifecycle. A pesquisa CPU pura é preservada ao suspender, evitando sorteios
  novos no mesmo turno. Esses caminhos já foram analisados nas revisões
  anteriores; não houve repetição de suítes pelo revisor.
- O cálculo dp passa pela inversa de get_screen_transform, incluindo origem
  da janela; extras de loja têm ramo Android com dimensões/fontes por dp e
  seletor quando não há faixa suficiente. O matte cobre desenho fora do
  canvas preservado sem mudar terreno/câmera/colisão.
- safe_tar permite links internos normalizados, mantém rejeição de escapes
  e usa data_filter durante a extração. O insumo Linux com links legítimos
  deixa de ser rejeitado indiscriminadamente.
- final_ui desinstala somente o package .ci no AVD previamente validado antes
  da troca de certificado efêmero. A distribuição mantém install -r e o
  contrato de chave persistente. Reinstalação CI não é anunciada como update
  que conserva perfil real.
- O smoke obtém tamanho de screenshots renderizados e atualiza em capture;
  não depende mais de wm size físico portrait. No macOS, Vision produz TSV
  por palavra com retângulos convertidos de origem inferior para superior;
  o parser exige alvo exato e único. Falhas/ambiguidade não provocam tap por
  aproximação silenciosa. Ações adb não são repetidas automaticamente após
  falha de transporte, evitando Back duplo.

## Execução local macOS — limites e segurança

android_local.py restringe serial a porta par de emulador e verifica o nome
reservado do AVD antes de instalar/remover pacote. AVD/user home são locais
ao worktree; o SDK fornecido é reaproveitado sem sdkmanager/install. O caminho
de abertura aceita somente com.chafy.gunboundrecomp.ci; a documentação explica
que a chave efêmera exige desinstalação desse sandbox. Não há ação sobre app
macOS ou telefone físico nesse helper.

prepare confere arquivos baixados JDK/templates antes de usá-los, registra
metadados do SDK já instalado e compila OCR local com swiftc. O fluxo exige
Python≥3.12, Godot4.7.2, SDK/imagem apropriados e ferramentas Xcode, descritos
em docs/ANDROID.md. Versões locais36.0.0 e CI36.1.0 são distinguidas; não se
afirma igualdade binária entre hosts. O helper check usa a interface atual
do smoke (adb/app-id/version/output), sem os antigos argumentos inexistentes.

## Evidência ainda separada / não coberta por este parecer

- A execução do AVD GUI em andamento deve terminar com seu próprio resultado
  e SHA do APK. Não classificar processo vivo, OCR parcial ou timeout como
  sucesso. Emulador ARM64 local continua execução virtual, não aparelho ARM64.
- O smoke relata corretamente pan/carga como gesto tentado quando não há
  prova de deslocamento/tiro; o timer não observado pode impedir a tentativa.
  Esses campos não atestam partida completa, multitouch físico ou áudio.
- logs() ainda consulta o PID atual. Uma sessão com relaunches pode ter
  mensagens/crash de PID anterior fora desse recorte; não apresentar esse
  log isolado como prova de ausência de erros na sessão inteira. Os logs de
  falha e do diagnóstico possuem cobertura própria, descrita no código.
- Safe areas/insets/IME, alta densidade, foco e acesso aos serviços Vision
  requerem evidência runtime. Os helpers puros e a leitura do código não
  comprovam todos os aparelhos/teclados/densidades.
- CI Linux/API24/API36, assinatura persistente, aprovação via GitHub e update
  de distribuição conservando perfil permanecem provas distintas. O harness
  da fonte informado pelo coordenador não foi repetido nesta revisão e não
  foi convertido em validação desses ambientes.

Nenhuma alteração de produto, commit, push, administração GitHub ou publicação
foi feita por este revisor.
