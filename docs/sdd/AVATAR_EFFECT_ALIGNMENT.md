# Correção do registro dos efeitos de avatar — 0.18

Pedido20/10/2026; REQ-10/20/39. O Great Devil Head vestido apresenta luzes
fora dos chifres após a migração HD. O trabalho0.17 foi preservado em3eb2b01,
incluindo suas fontes e evidências; PR1 já consta como MERGED no GitHub.

## Causa reproduzida

A fonte mh00071l.img tem22quadros:0–10 de Staring (dois chifres frontais) e
11–21 de Normal (um chifre de perfil). A preparação escolheu o maior efeito
dentre todos os22quadros (4), enquanto a cabeça usa Normal16. A composição
misturou anatomias de estados diferentes. O fallback também percorria os22
quadros de luz sem respeitar a faixa de estado. A tabela de Avatar.cs confirma
as faixas por categoria. O teste anterior verificava registro constante,
mas não compatibilidade entre estado da anatomia e do efeito.

## Plano autorizado

- [x] Reproduzir em teste a faixa correta para os20modelos de cabeça com L.
- [x] Preparar referências L na faixa Normal11–21 e conservar brutos anteriores.
- [x] Regenerar efeitos que representam outra anatomia/posição; comparar com
      a cabeça HD e com a composição nativa do mesmo estado.
- [x] Corrigir calendário de fallback e testar Normal/Staring sem trocar o
      mestre HD durante a animação; fallback inteiro quando arte inválida.
- [x] Inspecionar todos os20modelos com efeito na GPU1920×1080/60fps, em ambos
      os sentidos, inclinados e pausados; conferir conexão anatômica.
- [x] Atualizar ledger/controle, rodar regressões, exportar/assinar e conferir PCK.
- [ ] Registrar e sincronizar main com o PR preservado (upload HTTP expirou).

A arte HD permanece adaptação de anatomia constante. A correção não adiciona
novos gestos Staring HD nem altera combate, perfil, compras ou saldos.

## Resultado observado

Um novo efeito do Great Devil (uma luz de perfil) foi gerado em1295×1214RGBA,
recorte1094×1173. O atlas experimental20efeitos foi rejeitado e preservado.
Os outros19mestres foram mantidos e seus20efeitos registrados em pontos fixos
medidos no HD. Luz/cabeça agora compartilham Normal.

1989checks da suite HD (incluindo200calendários de fallback e45regressões de
referência/encaixe),5234checks totais+13partidas,13Python PASS. Capturas20cabeças
360frames/60fps/6s em1920×1080,30frames de pausa idênticos, ambos sentidos,
inclinação e prévia real da loja em docs/avatar-effects. Revisão independente
sem bloqueadores;37lotes recapturados e auditoria550 sem fallback oculto.

Arte preparada do Nak permanece como fonte pendente versionada, após revisão
automática exigir confirmação específica para sua integração. Runtime Nak
original restaurado; ver NAK_HD.md e source/pending_integration.
