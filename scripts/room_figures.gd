extends Node2D
## Piloto e CPU da sala, acima do fundo e atrás dos botões.
## O nó vive no palco 800×600; o pai aplica a escala 4/3.

var paint: Callable = Callable()

func _draw() -> void:
	if paint.is_valid():
		paint.call(self)
