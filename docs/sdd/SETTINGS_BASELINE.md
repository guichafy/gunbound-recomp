# Alinhamento visual dos T de SETTINGS — 25/10/2026

REQ-02/12/19/20. Usuário aponta SE/INGS abaixo dos dois T. Preservar fonte,
espaçamento, acabamento e alpha aprovados; corrigir somente registro vertical.

O alinhamento anterior usava a caixa de pixels fortes(r>=190). No T, a barra
superior também possui uma linha visível mais fraca acima dessa caixa; a
sequência TT evidencia essa linha, enquanto E/I começam na linha da caixa.
Comparar somente a caixa forte não prova alinhamento visual das maiúsculas.

Plano: compensação óptica de+1pixel nativo nos dois T, aplicada às faces e
ao contorno em todos os estados antes da ampliação. Demais letras, START,
casca e hitboxes preservados. Conferir barra dos dois T na mesma linha
visível de E, além de capturaGPU lado a lado. Sem nova fonte ou redesenho.

## Resultado observado

Ativo `room_settings_word_baseline`,78×22/quadro. Os dois T recebem+1px
vertical nos quatro estados; demais registros e pixels das faces preservados.
Os1436pixels nativos de face continuamRGBA idênticos às fontes. Tamanho,
espaços, contorno/alpha e âncora da palavra não mudam. Gerador registra a
compensação em `docs/settings-baseline/source-baseline.json`.

Dois checks novos reproduziram o erro anterior e agora passam: topo visível
das barrasT/T coincide comE na linha5 do rótulo normal.988checksGodot/0 em
4suítes. GPU1920×1080: START inteiro idêntico ao aprovado, fundo nos cantos,
4estados/fallback e clique/modal preservados. Captura e recorte lado a lado
em `docs/settings-baseline`. Revisão independente aprovada: retirar somente
a compensação reproduz exatamente o atlas anterior; sem cortes nas bordas.

Aceite visual confirmado pelo usuário ("Agora ficou bom") e commit local
autorizado em25/10/2026. Verificação antes do commit:1350checksGodot/0 em
8suítes,21Python/0 e24hashes. Sem nova exportação/PCK/app/ZIP, versão ou
publicação; o PCK anterior não valida este novo registro vertical.
