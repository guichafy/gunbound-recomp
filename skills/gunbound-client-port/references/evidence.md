# Registro de evidência e aceite

Criar uma linha por comportamento na documentação da mudança, preenchendo
os campos abaixo. Versionar extratos essenciais reproduzíveis; manter dumps
grandes e binários na área local de pesquisa.

| Campo obrigatório | Conteúdo |
|---|---|
| Escopo | REQ, mobile/arma/sistema, comportamento e build alvo |
| Origem | Caminho/repositório, commit ou SHA-256, recurso e versão |
| Localização | Função/VA/RVA/offset identificado, image base e trecho relevante |
| Contrato | Entradas, unidades, tipos, relógio, ordem e transições |
| Confiança | Observado em execução / derivado de estática / inferido |
| Decisão de porte | Comprovado / C# / adaptação / pendente; arquivos afetados |
| Esperado independente | Derivação e amostras; origem distinta do produto |
| Validação | Comandos, build/hash, resultados, frames/tempo e logs inspecionados |
| Limites | O que foi exercitado; pergunta restante e próximo passo |
| Aceite | Revisão técnica e aceite do usuário separados, com escopo explícito |

Transição no tick N: incluir N−1, N e N+1, dois sentidos e impacto exatamente
em N. Guardar posição central, contato, contador e seção, não só ponto final.

Relatar falhas ambientais: exit 0 com ERROR no startup não é log limpo.
Teste na fonte não comprova recurso no PCK; rodar Godot não atualiza app
exportado. Não embarcar overrides locais de TLS/certificados.
