# Climas secundários do Mage

Portado do cliente original por REA estático, com regras compartilhadas entre
partida e previsão da CPU. Registro técnico: `../sdd/MAGE_SECONDARY_WEATHER.md`.

- Calendário de sete categorias e oito posições, vento e intervalos de coluna
  do `stage.dat`. Miramo passa a sortear Thor com peso2; Moon tem peso0.
- Moon cura apenas o ator do turno. Mage recupera21HP na base de730HP;
  o percentual usa a vida máxima final e não recebe bônus deREGEN.
- Eclipse bloqueia itens, cancela seleção enfileirada e removeDual/Dual+.
- Elétrico causa choque e uma explosão própria antes de Thor e do ataqueMage.
  O raio auxiliar não herda o bônus deForce acumulado pelo projétil.
- Thor consulta o clima no impacto, respeita divisorT2 e atualiza nível na
  transição seguinte. Colunas usam três texturas e desenho originais.

`secondary-weather.mp4`:9s,1920×1080,540quadros/60Hz. T1/T2/SS nos dois
sentidos, contatos controlados e pausa de30quadros idênticos em cada caso.
`gpu-validation.json` registra cenários; `native-proof.json` fixa fontes/REA;
`verified-source.json` registra testes, hashes e limites.

Harness completo95suítes:26775checksGodot+58testesPython+29partidas/0.
Regressão final da filaEclipse:49/0, dois checks novos,26777 consolidados.
Sem execução do clienteWindows, escuta, aceite visual humano ou novo app
exportado. Seeds locais, itens/regen comum e partículas decorativas em voo
mantêm fronteiras/adaptações declaradas no registro técnico.
