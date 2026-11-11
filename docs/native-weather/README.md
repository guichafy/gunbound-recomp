# Clima global — evidência da issue #26

Contrato e matriz: [NATIVE_WEATHER_ISSUE_26](../sdd/NATIVE_WEATHER_ISSUE_26.md).
`evidence.json` fixa entradas e hashes dos extratos Ghidra da sessão; a consulta
intermediária parcial está identificada e foi substituída pela final integral.
Não inclui PE/DAT/XFS no produto. Reproduzir os VAs finais com o runner da skill
em banco próprio, a partir dos hashes pinados; `run.ok`, `manifest.ok` e
`source_unchanged` finais são verdadeiros. O Ghidra emitiu avisos ambientais
de truststore CA e reflexão Java; não houve timeout ou falha dos extratos finais.

`tests/tools/native_weather/check_calendar.py` reconfirma seis seeds das
fixtures preexistentes usando somente aritmética32bits das instruções do PE,
sem importar helpers GDScript. `scripts/import_mage_weather.py` reconstrói
pesos/ranges de stage.dat, conferidos byte a byte sem delta no catálogo ativo.

## GPU

- [Transições controladas](transitions.mp4):480frames1920×1080, pares2×4/4×2,
  sete categorias, 30quadros de pausa por par, retomada e feixe controlado.
- [Thor em detalhe](thor.mp4): complemento60frames com câmera manual aplicada
  após o evento de turno, mostrando satélite e feixe nos dois pares.
- PNGs `side0/side1-*`: amostras dos sete climas; os dois PNGs Thor vêm do
  complemento e mostram o enquadramento corrigido. Demais amostras e vídeo
  de480frames vêm da sequência completa anterior ao ajuste focal da câmera.
- `gpu.json`/`thor-gpu.json`: configuração e amostras. `verified-gpu.json`:
  digest da sequência bruta e comparação independente de60quadros de pausa
  em RGBA, além da asserção feita pelo próprio capturador.

Godot4.7.2, Compatibility/OpenGL/Metal AppleM4Pro. Passos manuais de1/60s,
vídeos a60fps; não é medição de desempenho em tempo real. Calendário controlado
para visitar todas as transições, não reprodução de sessão Windows.
A primeira captura não enquadrava Thor; a segunda confirmou o feixe, e o
complemento corrigiu a câmera após o reset de GrantTurn. Não usar as tentativas
iniciais como prova de inspeção visual do satélite.

Comandos (perfil temporário sob `.tools`, áudio mudo):

```sh
Godot --path . --script tests/capture_weather.gd --disable-vsync --always-on-top
Godot --path . --script tests/capture_weather.gd --disable-vsync --always-on-top -- --thor-only
```

Cliente Windows original, escuta, mouse e aceite visual humano não executados.
Interações específicas ainda adaptadas não passam a ser nativas por usar o
novo calendário. Não houve mudança de arte ou ampliação do escopo offline1×1.
