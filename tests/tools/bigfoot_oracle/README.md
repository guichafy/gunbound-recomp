# Oráculo Bigfoot da issue #28

Execute com Unicorn2.1.4 em Python3.12 (dependência apenas da pesquisa):

```sh
python tests/tools/bigfoot_oracle/generate.py
```

Preparar antes o bootstrap do projeto. O gerador confere SHA256 do PE/DAT,
lê as linhas DAT verificadas do bootstrap e usa o loader x86 existente do
Grub. Não importa código Godot nem requer recursos de outra sessão.
Em macOS o JIT do Unicorn precisa de um ambiente que permita execução JIT.

- `489580` real emite72cenários: todos os eventos/componentes com theta em
  ambos os sentidos e força1/210/420; spawners são pontos de observação.
- `41da80` real inicializa18cenários com atributos positivos/negativos e
  truncamentos de bônus. Obfuscação usa rand1 e alocação local controlada.
- `45db20` real calcula180danos: corpo24px plano, sem flags/resistências,
  vulnerabilidade100/83, percent100/133, Force0/27. Tilt helpers retornam0;
  parada em45e758 observa o dano final antes de HP/pose/rede. Saída anterior
  da função significa dano0; não há supressão de exceção ou acesso inválido.
- `4e4450` real rasteriza18crateras em bitmap200×200. Apenas `4e4bc0`, passe
  visual de blackmask, é omitido. A fixture guarda os intervalos físicos
  apagados, com direita exclusiva, por linha; compara o raster inteiro.

`generate.py` gera `tests/fixtures/bigfoot_native.json`. Os testes Godot leem
esse resultado sem instalar Unicorn. Os parâmetros dos três materiais da
build são idênticos; o treino usa material0. Geometria do hotspot, terreno
procedural/visual e ativação dos itens permanecem pontes documentadas.
Isso executa funções isoladas do PE, não o jogo Windows inteiro.
