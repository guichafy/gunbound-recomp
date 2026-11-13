# JEWEL — publicação e apresentação

Ghidra12.2/JDK26, mesmo PE pinado nos contratos de dano/ciclo. Consultas
`presentation-q1` e `presentation-q2`: manifests e runs aprovados, origem
inalterada. Espaços finais normalizados; ASM e diagnósticos preservados.

- `4784a0` copia a imagem registrada numa célula64×64, ancorada em(32,48).
  Os limites direito/baixo são63exclusivos. `JewelArt.CELL_CLIP` reproduz
  esse recorte; o importador conserva todos os pixels da fonte sem recortá-los.
- Publicação `47a960` está no estudo anterior `docs/jewel-native/ghidra/q07`:
  mesmo frameEPA para recursos3000+tipo/3100+tipo. Ausência de frame da luz
  não autoriza módulo por50 nem uma segunda animação. Corpo alfa→luz somada.
- `461c60` troca pose e reinicia relógio/índice; `450730` avança a EPA, já
  fechado pelo oráculo de tick. `4372f0` cria um efeito `flame`; a chamada
  de remoção usa CL0, portanto não sorteia o deslocamento opcional desse
  produtor. Jflame é separado do corpo do jewel.
- `479ba0` usa `jblast.xes` em47a718; drop salta pontuação/som, mas chega a
 47a763 e pode criar Jflame quando resistência é esgotada. Ramo vencedor
 47a711 salta som/efeito. A representação local remove a entidade ao fim
  e emite o resultado pela política offline; não é replay do protocolo.
- `408180` publica dígitos numfont189..198 no rodapé nativo, y569, x692/749
  e passo20; valor em três posições, espaços omitidos. O layout do porte
 800×500 usa o painel no header, posição/escala adaptadas e documentadas.
  Os dois placares são apresentados por equipe, independentes de Gold.

PNG/EPA são conferidos contra o XFS pinado em `test_jewel_assets.py`;
registro, clip, frame e ausência de luz em `test_jewel_art.gd`. O programa
Windows completo não foi executado. Capturas GPU e limites da validação
ficam no contrato de implementação e em `../gpu/verification.json`.
