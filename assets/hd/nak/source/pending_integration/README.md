# Nak HD preparado, ainda sem integração aprovada

O pedido atual solicita regenerar imagens do PR1, que contém o Nak. A revisão
automática de permissões rejeitou integrar/importar/testar esses novos recursos
por exigir confirmação específica, ainda pendente. O runtime permanece com
Nak original. Este checkpoint versiona o trabalho preparado, sem o exportar
nem o apresentar como validado.

`manifest.json` registra21arquivos e SHA256, com caminho original e checkpoint.
`integration.patch.gz` (gzip sem perda) preserva os dois diffs de mobile_rig/nak_sprite. Outros
brutos/prompts/referências ficam ao lado, em `assets/hd/nak/source`.

Após confirmação explícita: restaurar arquivos nos caminhos registrados,
reaplicar o patch (conferindo a versão do rig), corrigir a separação S2/SS da
folha de efeitos, criar testes NakHD/HUD, habilitar mipmaps e importação,
capturar1920×1080/60fps com pausa e dois sentidos, atualizar QA/export. Ler
`docs/sdd/NAK_HD.md`. Os603checks existentes observados antes do bloqueio não
substituem essas verificações HD pendentes.
