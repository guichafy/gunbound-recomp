# Partículas originais do Mage

Force e eletricidade usam a textura `CrashTexture.xtf` do cliente. As
partículas nascem nos pontos físicos do voo, ficam naquela posição,
encolhem e desaparecem em15passos, com giro/alfa/mistura originais.
O sorteio visual não consome o RNG de combate nem cria objetos naCPU.

`flight-sparks.mp4`:6s/360quadros,1920×1080/60Hz, T1/T2/SS comForce e
Electric nos dois sentidos. Pausas30quadros idênticas e retomada conferidas.
As imagens `arena-*` mostram também a integração na arena real/HUD.

Validação:27046checksGodot,60Python e29partidas;98suítes,zero falhas.
Pixels65536 conferidos contraXFS; revisão focal semP1/P2 após correção
da tentativa comum sem emissão. Registro técnico: `../sdd/MAGE_FLIGHT_SPARKS.md`.

REA estático; sem execuçãoWindows ou aceite visual humano. Qualidade3 e
seed4242 são inputs locais explícitos, sem promessa de replay do RNG completo
de uma sessãoWindows. Fontes/manifestos/hashes em `native-proof.json` e
`verified-source.json`. App não reexportado.
