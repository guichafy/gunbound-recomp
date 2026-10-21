# Nak HD — plano e evidências

Pedido atual: finalizar a arte HD do mobile Nak e das imagens integradas pelo PR #1.
REQ-19/20/43; complemento visual da integração0.15, sem alterar combate/perfil.
A fonte C# e o cliente original permanecem somente leitura.

## Contrato e plano (antes do código)

1. Auditar atlas original/392quadros, três projéteis e brilhos, três impactos,
   seis cunhas de mira e consumo no menu. O retrato do menu é o próprio mobile.
2. Gerar com GPT Images integrado um mestre constante do Nak completo sem
   piloto, projéteis fixos e efeitos separados com RGBA real. Fonte clássica
   define identidade/geometria; mobile_parts aprovado define acabamento.
   Preservar os brutos, prompts, referências e hashes em source/.gdignore.
3. Catalogar recortes alpha>8, janelas nativas, pivô/hotspot e contato constantes.
   Introduzir NakHD com geometria fixa e transforms suaves, integrado pela
   interface atual do MobileRig. Usar o Body registrado do RiderPivot corrigido
   pelo RIDER_ADJUST existente; piloto/equipamento desenhado atrás do chassis.
4. Integrar tiros e impactos mantendo hit_pos, duração e semântica originais.
   S2 mantém cabeça fixa no ar/enterrada; SS orienta o mini Nak ao voo.
   Fall back nativo coerente se arte ou metadados obrigatórios faltarem.
5. Preservar a geometria informativa da mira. Cunhas planas não precisam de
   pintura nova: densidade maior pode ser preparação determinística, identificada
   explicitamente sem alegar reconstrução de detalhe por IA.
6. Verificar registro/escala, transições por ator, pausa, ambos os sentidos,
   inclinação, recursos inválidos e regras Nak existentes. Capturar framebuffer
   real1920×1080 e sequência60fps; medir dimensões úteis reais. Root registra
   documentos globais, regressão completa e export/publicação autorizados.

O rig é uma adaptação artística contínua do mestre; não restaura cada gesto ou
piscada dos392quadros originais. Originais/.png.import/.gd.uid preservados.

## Resultado observado

Preparados: dois atlas RGBA1536×1024; mobile794×485úteis, projéteis361–567px;
12efeitos168–331px de largura. Brutos/prompts/referências preservados. Os603checks
existentes passaram antes do bloqueio, mas não comprovam o HD novo.

A revisão automática rejeitou integrar/importar/testar por exigir confirmação
específica, solicitada e pendente. O runtime original foi restaurado.21outputs
novos e patch de dois scripts estão em assets/hd/nak/source/pending_integration,
com manifest de SHA256/caminhos. Não exportados; não aceitos visualmente.

Após confirmação: separar melhor efeitos S2/SS (brilhos encostam nas janelas
atuais), criar testes NakHD/HUD3×, mipmaps/import, GPU1920×1080/360frames60fps
com pausa e ambos sentidos, regressão e export. Sem afirmar migração concluída.
