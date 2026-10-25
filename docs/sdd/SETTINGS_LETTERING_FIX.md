# Acabamento de SETTINGS — 25/10/2026

**Substituído pelaADR-111:** usuário rejeitou a alteração do peso da fonte
desta reconstrução. Catálogo ativo passou aRGBA nativo completo; ver
`SETTINGS_ORIGINAL_LETTERS.md`. Preservar estes arquivos como histórico.

REQ-02/12/19/20. Usuário aprovouSTART e rejeitou o aspecto de letras recortadas
emSETTINGS. Este pedido substitui a composição por retângulos daADR-109,
preservando o botãoSTART, sua tipografia, o modal e os comportamentos.

Causa: janelas de três sprites continham fundo opaco, partes dos contornos
vizinhos e baselines diferentes. Recortar atlas já filtrados e desenhar as
janelas lado a lado evidenciava cada emenda.

Plano: extrair a cobertura dos glifos nativosS/E/T/I/N/G separando-a do
contorno azul/fundo pela paleta original. Alinhar a altura das maiúsculas,
manter as formas, compor a palavra com espaçamento fixo e contorno contínuo
uniforme. Gerar um rótulo transparente único por estado (normal/hover/push/
disabled), com cores dos mesmos sprites. Suavizar o conjunto em4×, evitando
filtragem independente junto às emendas. Preservar fontes e versões anteriores.

O rótulo passa a uma textura única no renderer; fallback nativo acompanha o
mesmo desenho. Validar alpha/registro/estados, cliques e capturaFullHD;
compararSTART aprovado byte a byte na mesma cena congelada. SemSystemFont,
novas regras, perfil, versão, app, commit oupush. Acabamento derivado/adaptado
dos glifos originais, sem alegação de pixels idênticos após composição.

## Resultados

SETTINGS usa agora um rótuloRGBA único81×17, com quatro estados. Gerador
`scripts/build_settings_word.py` recupera a cobertura dos glifos nativos pela
paleta tinta/ouro/branco, alinha a altura forte das maiúsculas, dá1px de
espaçamento e aplica contorno redondo comum1,25px. O conjunto4× é filtrado
uma vez; fallback nativo vem do mesmo composto. Não usa fonte de sistema e
não retém os retângulos opacos das letras. Alpha/antialiasing/contorno são
derivados e adaptados; não são repetição exata dos pixels dos recortes.

UmPNG nativo324×17 eHD1296×68 acrescentados aos catálogos settings, sem
substituir fontes anteriores. Quatro estados mantêm cores dos sprites;
push desloca o rótulo1px. Renderer recebe4texturas completas, preserva o
ramo deSTART e a área de clique107×45. Modal/fonteASCII permanecem iguais.

TDD: probe inicial falhou na ausência deword_frames. Suíte específica35/0,
mais sala162/0,UI172/0 ebotões596/0:965checksGodot/0. Inclui alpha de bordas,
estados, fallback, clique real deSETTINGS/OK/Cancel/START eESC. Revisão
independente aprovou e reproduziu ambos os atlas em memória comRGBA idêntico.

GPU1920×1080,OpenGL/Metal AppleM4Pro: quatro estados reais, clique abre modal,
fallback nativo eSTART aprovadoRGBA idêntico ao recorte da captura anterior,
na mesma cena congelada. Inspeção do rótulo normal/hover/push/desabilitado.
Capturas/metadados emdocs/settings-lettering-fix; logs em.tools/room-contact/
word-*. Não é execução dinâmica do cliente original; escuta/mouse físico
não exercitados. Aceite visual do usuário separado das verificações.

Pacote local em validação; semnovoapp/ZIP,versão,commit oupush.
