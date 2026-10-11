# Piloto em perfil e remoção Escaravelho 0.6.4

Pedido atual: perna distante não deve aparecer por trás da próxima; corrigir
sobreposição do piloto nos dois mobiles. Remover Escaravelho por não seguir
Gunbound. REQ-19/20/12 e REQ-02/08; pausa REQ-09 e progresso REQ-10 preservados.

Diagnóstico: perna distante pertence ao PNG inteiro, não pode ser ocultada só
por ordem das camadas. Novo mestre GPT Images mantém só a perna próxima visível,
com enquadramento/assento da composição0.6.3 preservados. Originais/derivados
anteriores intactos. Sem máscara raster por código.

Roster: só Mage/Bigfoot selecionáveis, IDs1/2 preservados. Remover registro0,
branches de render/armas/áudio exclusivos do Escaravelho e carregar só assets
ativos; não apagar fontes/arte histórica. Start com ID inválido normaliza para
Bigfoot, CPU sempre o outro mobile. Seleção deve usar ID separado do slot.
Retirar ícone Escaravelho do aplicativo. Menu/ajuda/docs/regras mostram só2mobiles.
Teste antigo com arma genérica deve usar fixture real Mage ou Bigfoot, com dano,
mira e delays correspondentes; não conservar um mobile removido só para testes.

- [x] Regressão roster/menu/oponente e perfil isolado.
- [x] Asset piloto em perfil, catálogo e encaixe nos dois sentidos.
- [x] Remover Escaravelho ativo, migrar fixtures sem perder cobertura de regras.
- [x] Suites completas e10partidas naturais ambos mobiles como jogador/CPU.
- [x] Capturas GPU/menu/arena, revisão independente, pacote0.6.4/assinatura/PCK.
- [x] SDD/Git local e abrir app para validação do usuário.

## Evidências/limites

825checks/13suites e10partidas alternando os dois mobiles, zero falhas.
Registro preservado271/153/703/977,4pxextra abaixo para conter PNG novo completo.
144framesGPU/24fps nos dois sentidos, encosta−30° e seis estados. Prévia em
docs/occlusion;16capturas reais em docs/hd. Revisão independente sem bugs concretos.
Original/HD anteriores/tiros/perfil intactos. App/ZIP0.6.4 Universal, assinatura,
runtime e PCK verificados; scarab/tortoise excluídos. Git local/tagv0.6.4.
Aceitação visual do usuário pendente; galeria não prova contato físico em todas
as encostas. Sem teste manual completo de mouse/áudio.
