# REA: do artefato ao contrato

## Fixar a fonte

Identificar distribuição/build/região do cliente e SHA-256 do PE e dos
XFS/DAT relevantes. Registrar commit das fontes consultadas. Reusar a cópia
local existente; preservar binários e fonte C# sem edição.

| Fonte | Uso |
|---|---|
| Cliente compatível: instruções + dados + ramo ativo | Regra nativa comprovada |
| Captura/trace do mesmo cliente | Comportamento observado naquele cenário |
| OpenBound C# | Referência legível e fallback onde falta prova nativa |
| Emulador de servidor | Protocolo/dados; conferir o que realmente implementa |
| Vídeo/lembrança | Hipótese visual a investigar |

Fontes públicas indicadas pelo usuário:

- https://github.com/jglim/gunbound-launcher — launcher e diretório TestClient.
- https://github.com/jglim/gunbound-server/ — emulador do servidor Thor's Hammer.

Abrir as fontes e conferir a versão usada. Launcher não equivale ao código
do jogo; servidor não comprova sozinho animação/física do cliente. Quando
fontes discordarem, localizar o ramo ativo e registrar a divergência.
Não misturar constantes de builds diferentes.

## Escolher o caminho de análise

Preferir Ghidra headless direto e os recursos de [ghidra.md](ghidra.md).
Esse fluxo exporta ASM, pseudocódigo, referências e bytes sem depender de
GUI ou de um conector. Descobrir a compatibilidade atual antes de usar MCP:
`GHIDRA_INSTALL_DIR` aponta à raiz que contém `support/analyzeHeadless`,
não ao launcher `bin/ghidraRun`. REA6.7.0 aceita12.1.x e recusa12.2; conferir
novamente se a versão mudar. Falha do conector não significa falha do Ghidra.

## Investigar com REA/MCP compatível

Descobrir as ferramentas REA disponíveis e ler seus schemas atuais. Abrir o
caminho absoluto conhecido com `open_binary`; usar strings de recurso ou
endereços comprovados como sementes. Seguir xrefs, construtor/fábrica,
vtable/dispatch, chamadores e consumidores até a rotina ativa. Pedir
pseudocódigo para orientação e assembly para confirmar a operação. Salvar
extratos relevantes, IDs de evidência e limitações do provedor. Ausência de
xrefs com cobertura parcial não prova ausência de comportamento.

Em Ghidra direto, os extratos têm manifesto/hash/logs, sem IDs de evidência
REA. Registrar esse caminho explicitamente; não inventar IDs de MCP.
Indicar entradas ausentes somente com evidência de chamada/dispatch/ASM.
`decompileCompleted=true` não comprova assinatura, unidade ou fórmula: casts
de ponteiros e `unaff_*` exigem seguir ABI/helpers e confirmar instruções.

Registrar endereço como **VA, RVA ou offset de arquivo**, image base,
arquitetura e hash. Endereço é local àquela build. Conferir branch,
signedness/largura, ponto fixo, LUT, quantização, shifts, divisão inteira,
overflow quando aplicável, conversão FPU e ordem de operações. `idiv`
negativo trunca para zero; shift aritmético pode arredondar de outra forma.
`int(a*b/100)` não substitui automaticamente `(int(a*b)<<8)/100`.
Conferir intermediários e resíduos acumulados, não somente o ponto final.

Reconstruir inicialização → atualização → colisão → transformação →
remoção/filhos e consumidores de render/som. Tick físico, contador de
estado, EPA e tempo de render são relógios distintos. Descrever o contrato
em unidades originais antes de converter para Godot.

## Provar sem circularidade

Derivar fixtures das instruções/tabelas e entradas fixadas, sem importar o
helper GDScript testado nem copiar seus resultados como esperados. Guardar
a derivação e conferir manualmente amostras de fronteira. Em análise
dinâmica, identificar ambiente/cenário/trace e separar observação de inferência.

Análise estática pode fundamentar um porte delimitado: declarar o que não foi
executado. Para observar o cliente, usar ambiente de teste isolado/offline
apropriado. O porte não autoriza publicação, conexão a serviços externos ou
adição de multiplayer ao protótipo.

Se faltar evidência, manter o fallback existente identificado e registrar a
pergunta exata, pesquisa feita e próximo experimento. Não inventar dano,
resistência, som ou arte para preencher uma lacuna.
