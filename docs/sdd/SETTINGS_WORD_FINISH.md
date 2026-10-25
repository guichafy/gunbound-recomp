# SETTINGS: contorno da palavra e espaçamento — 25/10/2026

Registro vertical dos T corrigido posteriormente pelaADR-114,
`SETTINGS_BASELINE.md`. Fonte, acabamento e espaçamento desta etapa preservados.

REQ-02/12/19/20. Usuário aprovou a transparência da ADR-112, mas ainda
rejeita o acabamento dos recortes. Preservar casca/alpha e START aprovados.

Causa: copiar máscaras de contorno de cada fonte traz quinas, sombras e
limites diferentes para cada glifo. As máscaras terminam abruptamente
perto de letras vizinhas; ampliar não remove essas emendas.

Plano: manter o raster e as cores das faces nativas S/E/T/I/N/G, mas compor
uma única base azul de contorno para a palavra inteira. Espaço entre faces
passa de3 para2pixels; topo das letras continua no mesmo nível de START.
Derivar alpha contínuo do conjunto e suavizar a borda em4×; não redesenhar
as faces nem substituir a fonte. Rejeição anterior da ADR-110 reconstruía
também o preenchimento; aqui as faces continuam copiadas integralmente.

Validar todos os estados, identidade das faces nativas, alpha da casca
aprovada, fallback e captura GPU lado a lado com START. Aparência depende
do aceite visual do usuário. Sem app/ZIP, versão, commit ou publicação.

## Resultado

Registro ativo aponta a `room_settings_word_polished`:78×22/quadro, quatro
estados. Margem transparente de1px adicional e destino y13 mantêm as faces
na mesma altura18 deSTART. Contorno único azul2px, com acabamento de alpha
de0,15px; RGB das faces é copiado antes da ampliaçãoBICUBIC4×. Alpha é
derivado e não uma repetição nearest das máscaras recortadas anteriores.
Fallback conservaRGB nativo e usa cobertura de área BOX para evitar ringing.
1436pixels de faceRGBA nativos idênticos às fontes; todas as quatro bordas
dos quatro estados de ambos os atlas são transparentes.

986checksGodot/0 em4suítes (settings56,sala162,UI172,botões596). Probe antes
da mudança reproduziu4falhas de borda dura. A capturaGPU1920×1080 confirma
START inteiroRGBA idêntico àADR-112, cenário nos cantos, clique abre modal,
quatro estados e fallback da palavra. Evidências em `docs/settings-word-finish`;
gerador `scripts/build_settings_word_finish.py`, fonte/parâmetros/hashes em
`source-polished.json`. Fonte nativa preservada; somente contorno/alpha e
espaçamento foram retrabalhados. Derivados anteriores mantidos em disco.

Revisão independente aprovada: reproduçãoRGBA dos dois atlas, faces e
margens completas; compensação da âncora conferida. PCK isolado177812004bytes:
96checks/0,exit0 fora do projeto, semoverride local. Override restaurado
byte a byte. Ressalvas ambientaisCA/editor_settings registradas nos logs,
semSCRIPT ERROR no probe final. Nenhum app/ZIP foi atualizado.
