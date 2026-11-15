# Revisão independente — primeira entrega Android para teste

Data: 15/11/2026. Base: `9465ce4e`; delta não commitado de
`.github/workflows/desktop.yml` e `tests/test_ci_android_workflow.py`.

## Resultado

Nenhum P1/P2 encontrado no escopo revisado.

O requisito vigente é instalação direta para testes, sem Play Store e sem
provisionamento de secrets para a primeira entrega. A exigência histórica de
assinatura persistente em toda execução da main foi substituída pela emenda do
design Android; assinatura persistente continua exigida no caminho explícito
de distribuição.

## Verificações

- PR executa e envia o candidato `.ci` independentemente da flag; não executa
  o passo que recebe secrets de assinatura.
- Push da main com flag ausente ou `false` executa e envia o mesmo candidato,
  sem depender de secrets. Flag `true` seleciona o caminho persistente, que
  continua falhando explicitamente se a chave estiver ausente.
- API36 e API24 usam o mesmo caminho de APK e o mesmo app ID em cada modo;
  API24 não reexporta nem substitui o APK após o smoke da API36.
- Upload de `android-test-candidates-not-for-distribution` acompanha o gate
  do candidato. Upload de `android-package` acompanha o gate de distribuição.
  Os uploads normais continuam condicionados ao sucesso dos passos anteriores.
- O diff não altera jobs/checks de desktop, permissões, publisher, ambiente
  de aceite físico ou dependências da publicação. Candidatos não entram no
  publisher oficial.
- O exportador existente gera chave de teste temporária no modo candidato;
  o smoke existente limpa somente o pacote `.ci` antes de instalar, evitando
  conflito entre as chaves efêmeras de diagnóstico e candidato.

## Evidência local desta revisão

`python3 -m unittest discover -s tests -p test_ci_android_workflow.py -v`:
3 testes, 0 falhas, 0,298s. Os testes cobrem seis combinações PR/main ×
flag ausente/false/true e executam o shell real da escolha API24 com Python
stub. `git diff --check`: exit 0.

Revisão estática do workflow completo, delta e consumidores existentes de
assinatura/instalação. Sem execução de Godot, build, emulador, instalação,
CI remota ou mutação de arquivos de implementação/remotos. A validação
remota dos APKs permanece pendente.
