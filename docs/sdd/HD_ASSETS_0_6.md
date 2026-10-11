# Assets HD — proposta e plano 0.6

Pedido: usar GPT Images para melhorar Bigfoot, tiros e demais assets importados,
mantendo a aparência clássica (preferência confirmada pelo usuário).
Requisitos afetados: REQ-19, REQ-12; novo REQ-20: derivados HD com transparência,
identidade reconhecível e validação visual em 1920×1080.

## Escopo

Somente os assets gráficos já integrados: Bigfoot, Mage, piloto, três projéteis
por mobile e suas explosões. Sons, combate, tamanho arena60/menu180, balística,
perfil e mapas continuam os atuais. Originais permanecem byte a byte intactos.
Full HD é a resolução da apresentação/captura, não o tamanho de cada bomba.
Sprites devem ter detalhes suficientes para exibição ampliada; não basta mudar
o tamanho dos PNGs originais.

## Estratégia visual

Produzir derivados com GPT Images, usando quadros originais como referência.
Avaliar primeiro fidelidade, transparência, alinhamento e grade. Novos atlas de
poses usam quadros chave da sequência original, preservando duração e estados;
não afirmar restauração exata de todos os pixels/quadros. Se a geração não
preservar a identidade ou a estrutura, rejeitar e registrar o limite antes de
substituir o render funcional. Armazenar prompts, dimensões, mapeamento e origem
em assets/hd e nesta documentação. A resolução lógica do combate não muda.

## Plano de implementação

- [x] Gerar e inspecionar Bigfoot em grade, com poses selecionadas dos originais.
- [x] Gerar/inspecionar Mage, piloto e tiros/efeitos com o mesmo acabamento.
- [x] Integrar apenas derivados aprovados visualmente no leitor de atlas;
      conservar pivôs, tamanho de desenho, tempo, espelhamento e fallback original.
- [x] Verificar recortes/alpha e capturar menu, arena, tiros e explosões Full HD.
- [x] Rodar testes de cena/atlas pertinentes, reexportar e verificar assinatura.
- [x] Registrar resultado real, limitações e hand-off; versionar localmente.

## Aceitação

Nenhum erro de recorte/transparência ou mudança de mecânica; personagem clássico
reconhecível, projéteis distinguíveis e aplicativo atualizado para validação.
Qualidade/fidelidade artística final dependem da avaliação do usuário.

## Registro de execução

Sete PNGs gerados/inspecionados; seleção usa heroes com fontes maiores.
Ruling: refinamento de recortes é necessário porque alpha1/255 fora da figura
deformava o enquadramento — catálogo considera alpha>8/255, preservando PNGs.
Teste de ruído reproduzido falhando e passando; normalizar números JSON em int
foi necessário para usar o catálogo. Captura inicial por stretch1728×1080 foi
substituída por framebuffer real1920×1080;16 capturas verificadas por dimensão.
Ruling: criar fonte maior para MageEMP, que é desenhado até520px em Full HD;
célula pequena de effects seria ampliada e prejudicaria nitidez.

439checks passaram (251 anteriores+188 HD);10 partidas naturais concluídas.
App0.6.0 reexportado/assinado; PCK independente validou derivados/JSON/salvas.
Nenhum original importado alterado. Revisão identificou capturas MageT1/SS sem
explosão; script agora exige efeito da arma, usa força65 para Mage e falha se
não houver impacto natural. Capturas corrigidas concluídas sem erros.
Revisão independente aprovou código e capturas corrigidas, sem achados pendentes.
Entrega versionada localmente como v0.6.0; validação artística final pelo usuário.
