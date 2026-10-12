# Avatar contínuo e equipamento no Shop — 0.14.4

Pedido: corrigir a aparência de imagens alternadas no avatar/personagem e
vestir itens no Shop com persistência até a batalha. REQ-10/19/20/38/39.

Diagnóstico: HD usa peças constantes, mas aplica a cada 0,1 s o centro da
silhueta de cada quadro original como deslocamento independente. Não é um
pivô anatômico: há saltos de até 16 px no conjunto de metadados. O repouso do
piloto também reinicia sua fase em mudanças de pose. Na loja, Experimentar é
temporário mesmo após comprar; vestir só está acessível no Inventário.

Plano e critérios antes do código:
1. Regressão RED: registro HD idêntico nos 22 quadros; botão da loja veste
   item comprado mesmo se ele já estiver na prévia, salvando o perfil.
2. Fixar o registro das peças HD, conservando aspecto, atlas/pivôs originais e
   fallback. Respirar como conjunto contínuo, não mover cada silhueta.
3. Compartilhar relógio contínuo do piloto e interpolar mudanças de pose no
   estado visual por ator, incluindo interrupções e repetição do recuo.
   Pausa congela relógio; colisão/modelo não usam a interpolação.
4. Experimentar para não possuídos; Vestir para possuídos. Vestir salva de
   forma transacional, atualiza prévia/indicador e usa o conjunto persistido
   ao iniciar/reiniciar batalha. Não equipar compra automaticamente.
5. Testar quatro categorias, recarga do perfil, falha de escrita, batalha,
   pausas/transições; suites pertinentes, captura animada GPU e app assinado.

Resultado: critérios implementados;1731checks+10partidas sem falhas, revisão
independente sem achados. Captura GPU360frames a60fps em
`docs/avatar-motion/motion.mp4`; três conjuntos em Mage/Bigfoot e ambos os
sentidos, com todas as mudanças de pose. App/ZIP0.14.4 exportados e assinatura
estrita válida; smoke GPU do PCK confirma Vestir4slots → recarga → batalha e
registro HD constante. Perfis isolados; arte não regenerada, fonte C# e perfil
real preservados. Validação do usuário pendente. Gestos/olhos não reanimados;
fallback original conserva quadros nativos.
