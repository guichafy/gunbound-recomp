# Android no macOS

Fluxo local para gerar **APK Android** e executá-lo em emulador descartável,
independente do GitHub Actions. O app macOS não participa desse teste.
O requisito A8 e seus limites estão no [design Android](sdd/ANDROID_V1_DESIGN.md).
Prepare/build/boot/open/check foram executados no Mac Apple Silicon/API36/ARM64.
O candidato passou o fluxo UI SOLO/JEWEL, Back/IME, persistência e Home/Resume;
o diagnóstico passou48tiros/66mapas/22JEWEL/UI3. APKs exatos, capturas e limites
em [validação local](android-v1/local-validation.md). CI remota e aceite físico
continuam pendentes.

Em [GitHub Releases](https://github.com/guichafy/gunbound-recomp/releases), baixe
**Gunbound-Recomp-VERSÃO-Android-Test.apk** para instalar o jogo. O SHA-256 está
em `SHA256SUMS`, junto aos checksums dos ZIPs macOS e Windows. O APK de teste
usa o identificador `com.chafy.gunboundrecomp.ci` e uma chave efêmera. Se o
Android recusar a atualização por diferença de assinatura, desinstalar o app
anterior apaga seu perfil local.

A primeira entrega passou o smoke nas APIs 24 e 36. Testes em aparelho físico e
distribuição com chave persistente estão na [issue #56](https://github.com/guichafy/gunbound-recomp/issues/56).
O artifact dos PRs contém o mesmo arquivo de instalação com o nome `candidate.apk`.

Use Python 3.12 ou mais recente, Godot **4.7.2** em `/Applications/Godot.app`,
Xcode Command Line Tools (`swiftc` para OCR nativo) e um SDK Android instalado.
O SDK é usado em leitura; `.tools/android-v1` guarda JDK17/templates verificados,
AVD, cache e relatórios. A preparação automática de JDK cobre macOS Apple
Silicon; no Intel, informe `--jdk /caminho/do/JDK17/Contents/Home` e instale a
imagem x86_64 correspondente. Não há suporte novo de iOS.

No SDK precisam existir platform-tools/adb, Build Tools36.0.0, Android36,
emulator, command-line tools/avdmanager e imagem
`system-images;android-36;google_apis;arm64-v8a` (Apple Silicon).
Instale os componentes por [Android Studio/SDK Manager](https://developer.android.com/studio/intro/update#sdk-manager)
ou em um SDK separado sob `.tools` antes de executar o fluxo. Não execute
`sudo` nem altere seu SDK para tentar aproveitar um cache da CI Linux.
O SDK existente neste Mac foi reaproveitado; versões locais observadas são
registradas em `.tools/android-v1/local-toolchain.json`. A CI possui seu próprio
lock de ferramentas Linux, incluindo Build Tools 36.1.0. Isso não promete APKs
binariamente idênticos entre hosts.

Execute os comandos na raiz do worktree, substituindo `python3` por seu Python
compatível se necessário:

```bash
python3 scripts/android_local.py prepare --sdk-root /opt/homebrew/share/android-commandlinetools
python3 scripts/android_local.py build --mode candidate
python3 scripts/android_local.py boot --visible
python3 scripts/android_local.py open --mode candidate
python3 scripts/android_local.py check --mode candidate
```

`prepare` verifica hashes oficiais de JDK/templates, configura o editor
portátil de exportação e compila o OCR Apple Vision usado nos screenshots.
O export exige `4.7.2.stable` no `--version` da cópia do editor; diagnóstico e
candidato aparecem no Android como **Gunbound Recomp Test**. Mantém ADB ativo
ao terminar, sem mudar preferências do Godot instalado.
Não muda preferências do editor instalado. Se a rede não estiver disponível,
um cache já verificado é reutilizado. Um novo checkout precisa primeiro da
importação do projeto Godot, conforme [desenvolvimento](DESENVOLVIMENTO.md).

O serial padrão é `emulator-5590`. Para outra porta livre, use o mesmo
`--serial emulator-5584` em `boot`, `open` e `check`. O script recusa serial de
telefone, porta ocupada por outro AVD e emulador com nome diferente de
`gunbound_android_v1`. `boot` reutiliza esse AVD quando ele já está ligado;
se estiver em modo oculto, `--visible` não muda uma instância já existente.
Para encerrá-lo, execute somente contra o serial verificado:

```bash
/caminho/do/SDK/platform-tools/adb -s emulator-5590 emu kill
```

`open` instala apenas `com.chafy.gunboundrecomp.ci`. A chave de teste é
efêmera; trocar de build exige desinstalar esse package **somente no AVD de
teste**, procedimento feito pelo script. Por isso ele apaga o perfil CI
anterior. Nunca use esse caminho para testar atualização de um perfil real.
O OCR Apple Vision lê o quadro completo e, se necessário, procura o texto OK
na região inferior; usa as caixas realmente reconhecidas, convertidas de volta
ao quadro, e falha quando não encontra um alvo único. A leitura do estado IME
pode ser repetida dentro do prazo; eventos de toque/Back nunca são repetidos
automaticamente. Não execute importações/testes Godot do host simultaneamente
ao smoke: o editor instalado pode encerrar o serviço adb ao sair.

Durante o próprio smoke, relaunch/force-stop conserva e verifica o perfil
isolado; atualização assinada persistente é um teste distinto da implantação.

Para executar o diagnóstico interno de recursos/combate, gere o outro APK:

```bash
python3 scripts/android_local.py build --mode diagnostic
python3 scripts/android_local.py open --mode diagnostic
```

`check --mode candidate` é a faixa normal de UI; `check --mode diagnostic`
não é um atalho para o diagnóstico. Use `open --mode diagnostic` para lançar
os casos internos e confira o logcat/relatório do mesmo token e APK.
O host de CI usa `android_ui_smoke.py --diagnostic --apk APK --app-id ID
--version VERSION --token HEX32 --output DIR [--adb PATH --serial SERIAL]`.
Esse runner pressupõe o sandbox`.ci` do diagnóstico instalado/compatível ou
um AVD novo; não instale sobre candidato de outra chave efêmera com`install -r`.

O diagnóstico usa feature/argumentos embutidos somente nesse APK e perfil
`user://ci/gunbound-package-<token>/ci-profile.json`. O app encerra ao terminar.
O relatório stdout/logcat precisa conter token/versão corretos, 48 tiros,
66 casos de mapas, JEWEL em22lados e UI 3, sem falhas. O candidato normal não
aceita esse modo no Android. Não injete argumentos no APK final por `am start`.

Arquivos úteis:

- `builds/android/candidate.apk` e `diagnostic.apk`: builds locais de teste.
- `*.inspection.json`: identidade, APIs, ABIs, certificado e SHA do APK inspecionado.
- `.tools/android-v1/local-launch.json`: APK exato, API/ABI e lançamento no AVD.
- `.tools/android-v1/local-ui-smoke/`: screenshots, OCR, logcat e `report.json`.
- `.tools/android-v1/{emulator.log,local-toolchain.json}`: ferramentas e boot.

O check visual usa regiões OCR/TSV da imagem real, sem assumir que a janela
inteira é a área segura. Aguarda IME/foco e fechamento do teclado para salvar;
o apelido sintético esperado é`Android42`, verificado como palavra exata após
relaunch. Relatórios distinguem ações tentadas de tiro/deslocamento comprovado.
Back usa dedupe300ms para os dois caminhos observados na tagGodot 4.7.2; um
segundo Back intencional dentrodesse intervalo também é ignorado.
O check falha se não reconhecer o estado esperado; consulte screenshot
e OCR ao investigar. Apple Vision exige acesso aos serviços locais do macOS;
uma execução confinada pode precisar de permissão do ambiente. Não considere
timeout, OCR ausente ou processo vivo como aprovação de gameplay.

Emulador ARM64 sobre macOS comprova essa execução virtual. Multitouch físico,
áudio, aparelhos reais, API24 e atualização do APK de distribuição têm evidências
separadas. Assinatura persistente, secrets, proteção GitHub e publicação não são
ativados por esses comandos. Veja [plano](sdd/ANDROID_V1_PLAN.md) e [estado observado](sdd/HANDOFF.md).


## Exportador comum e contrato da CI

O helperlocal chama a mesma CLI dos jobsLinux. Para usar toolsJSON já preparado:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot python3 scripts/build_android.py --mode candidate --tools .tools/android-v1/local-tools.json --output builds/android/candidate.apk
```

As opções são `--mode diagnostic|candidate|distribution`, `--tools`, `--output`
e `--token` para diagnóstico; não existem `--variant`/`--godot` nessa CLI.
O preset legacy mantém min/target Gradle vazios e inspeciona APIs 24/36 do APK real.
Orientação Godot 4 (`SCREEN_SENSOR_LANDSCAPE`) exporta Android 11/`userLandscape`
na tag 4.7.2, não enum nativo 6. Assinatura, alinhamento 16 KiB, duas ABIs/ELFs,
permissões, recursos/remaps, 22 previews Android e licenças são inspecionados.

Na CI, job `android` aparece como **Build and smoke Android candidate**;
Ubuntu 24.04/Python 3.13, timeout de 120 min, SDK/JDK Linux pinados em `ci-tools.json`,
AVDs x86_64 API 36/24. PRs e a main padrão produzem APKs de teste sem secrets:
`android-test-candidates-not-for-distribution`; evidências sobem em
`android-evidence`, inclusive em falha. Main com distribuição ativada tenta assinatura persistente e só
após os gates sobe `android-package` (APK/manifesto/sidecar). Esse caminho ainda
não foi executado remotamente nem comprova que secrets/reviewers estão disponíveis.
Somente main com `ANDROID_PUBLICATION_ENABLED=true` seleciona distribuição
persistente; os inputs de assinatura são exigidos apenas nesse modo futuro.
Chave/certificado ausente ou divergente falha; não há fallback debug publicável.

A finalização (`build_android.py --finalize` com dois relatórios e commit)
exige smoke final do mesmo SHA/versão executado em x86_64; o AVD ARM64 macOS não
satisfaz esse gate. Manifesto Android schema 2 registra `godot:"4.7.2"` do pin,
`certificate_sha256`, APIs/ABIs/versão/SHA e estados planos `diagnostic` e
`final_x86_64`, conservando `arm64_acceptance:"manual_gate_required"`.
O JSON não transforma tentativa adb em prova de tiro ou aceite físico.

A publicação padrão ocorre após um push na main com todos os builds aprovados.
O publisher confere os manifestos desktop, a inspeção do APK de teste e os
relatórios das APIs 24 e 36 contra o SHA-256 dos bytes a publicar. O rascunho
só é publicado depois do envio dos dois ZIPs, do APK e de SHA256SUMS.

O modo com `ANDROID_PUBLICATION_ENABLED=true` publica o APK de distribuição
após verificar o aceite físico ARM64 vinculado a run, commit e SHA. Ele requer
chave persistente, secrets, environment e reviewers configurados.
