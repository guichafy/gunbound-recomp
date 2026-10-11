# Correção de animação HD 0.6.1

Pedido: corrigir inconsistências de sprite e animação de Bigfoot/Mage.
Requisitos REQ-19/20 (arte/estados), REQ-12 (entrega validável).

## Diagnóstico

Atlas GPT 0.6 varia anatomia por quadro; Bigfoot moving inclui clarão indevido,
Mage mistura aura/corpo com ocupação diferente. draw_patch ajusta cada célula
inteira à área opaca do quadro antigo, comprimindo corpo quando efeitos crescem.
Piloto varia proporção por célula/recorte e segue offsets de uma silhueta diferente.
Quatro quadros por estado fazem saltos, especialmente na volta de um ciclo.

## Correção autorizada pelo pedido

Usar peças HD constantes: Bigfoot chassis/canhão/roda; Mage corpo/cajado.
Atlas novo GPT Images separado; preservar todos os PNGs anteriores e originais.
Animar transformações contínuas com tempo do BattleArt, pivôs fixos, medidas
constantes, suspensão/rodas/canhão/cajado. Piloto usa uma única cabeça/corpo HD
com âncora fixa por mobile, acompanha suspensão. Efeitos de carga/recuo em camada
independente, nunca alteram tamanho do carro. Fonte consistente em menu e arena.
Morte usa colapso/fade contínuo do mesmo corpo; não troca por desenho inconsistente.
Sem peças completas, fallback integral para atlas/piloto originais. Sem rede,
ranking ou regras novas. Física/colisão/turnos/vida e sons não mudam.

## Execução e aceitação

- [x] Regressão RED: peças/destinos fixos em estados, loop contínuo, piloto estável.
- [x] Gerar e catalogar peças, validar transparência e contorno.
- [x] Integrar sampler contínuo e relógio de pose; pausa congela; transições suaves.
- [x] Regressões GREEN e suites existentes, perfis isolados.
- [x] Captura GPU da sequência (idle/moving/carga/recuo/dano/morte) e inspeção.
- [x] Revisão, SDD, app 0.6.1 reexportado/assinatura/runtime, Git local.

Limite: animação articulada HD é adaptação artística, não restauração dos atlas
originais quadro a quadro. Aceitação estética final pertence ao usuário.

## Resultados observados

667checks, zero falhas (251 existentes+176HD+240animação). Critérios de
continuidade agregam90amostras a60Hz por estado/arma, sem inflar contagem.
216framesGPU a24fps, PNG1920×1080+MP4/GIF;16capturas de jogo atualizadas.
Revisão independente aprovada, fontes e frames representativos inspecionados.
App0.6.1Universal/ZIP, assinatura profunda/estrita, runtime e PCK isolado
validaram peças/recortes/Fx e salvas4/6/8; zero falhas. Originais/combate semdiff.
Sem validação manual completa; aceitação artística do usuário pendente.
