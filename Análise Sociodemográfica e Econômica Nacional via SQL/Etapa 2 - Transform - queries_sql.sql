-- ======================================================================
-- PROJETO: Análise Sociodemográfica e Econômica Nacional — IBGE 2022/2023
-- ETAPA 2: Análise e Automação — Queries SQL com Classificação Automática
-- ======================================================================
-- SGBD         : SQLite (compatível com PostgreSQL e MySQL)
-- Tabela usada : censo
-- Linhas       : 27 (uma por Unidade Federativa)
-- Ferramenta   : DB Browser for SQLite / DBeaver / psql
-- ======================================================================
--
-- COMO EXECUTAR:
--   1. Abra o banco ibge_censo.db no DB Browser for SQLite
--   2. Vá em "Execute SQL"
--   3. Cole cada bloco individualmente e pressione F5 (ou botão Play)
--   4. Os resultados aparecem no painel inferior com a coluna de status
--
-- CONVENÇÕES ADOTADAS:
--   - Palavras-chave SQL em MAIÚSCULAS (SELECT, FROM, WHERE, etc.)
--   - Nomes de colunas e tabelas em minúsculas com underscore
--   - Aliases descritivos em português para facilitar leitura
--   - ROUND() aplicado em todos os cálculos de ponto flutuante
-- ======================================================================




-- ======================================================================
-- DESAFIO 1 — Cálculo de Densidade Demográfica
-- ======================================================================
--
-- OBJETIVO:
--   Calcular a densidade demográfica de cada UF (habitantes por km²)
--   a partir dos dados brutos de população e área territorial.
--   Ordenar do mais populoso ao menos populoso e classificar
--   automaticamente cada estado em uma faixa de adensamento.
--
-- CONCEITO:
--   Densidade Demográfica = População Residente ÷ Área Territorial (km²)
--   Quanto maior o valor, mais pessoas vivem por unidade de área.
--
-- COLUNAS ENVOLVIDAS:
--   populacao  → INTEGER — total de habitantes residentes (Censo 2022)
--   area_km2   → REAL    — extensão territorial em km² (IBGE 2022)
-- ======================================================================

SELECT

    -- Identificação da unidade federativa e sua macrorregião.
    -- Inclui 'regiao' para facilitar análises comparativas no relatório.
    uf,
    regiao,

    -- Dados brutos usados no cálculo, exibidos para rastreabilidade.
    -- O leitor do relatório pode conferir manualmente o resultado.
    populacao,
    ROUND(area_km2, 2) AS area_km2,

    -- CÁLCULO PRINCIPAL: divisão aritmética simples.
    -- ROUND(..., 2) limita a 2 casas decimais para legibilidade.
    -- O alias 'densidade_calculada' é o nome da coluna no resultado.
    ROUND(populacao / area_km2, 2) AS densidade_calculada,

    -- CLASSIFICAÇÃO AUTOMÁTICA via CASE WHEN.
    -- O banco de dados avalia cada linha e atribui um rótulo de texto
    -- conforme a faixa em que a densidade calculada se enquadra.
    -- As faixas foram definidas com base nos intervalos reais do IBGE:
    --   >= 100 hab/km²  → regiões metropolitanas / capitais densas
    --   >= 20  hab/km²  → estados intermediários do litoral e sul
    --   >= 5   hab/km²  → estados com interior mais vazio
    --   <  5   hab/km²  → grandes vazios demográficos (Amazônia)
    CASE
        WHEN (populacao / area_km2) >= 100 THEN 'Alta Densidade'
        WHEN (populacao / area_km2) >= 20  THEN 'Média Densidade'
        WHEN (populacao / area_km2) >= 5   THEN 'Baixa Densidade'
        ELSE                                    'Muito Baixa Densidade'
    END AS classificacao_densidade

-- Fonte de dados: tabela principal do censo.
FROM censo

-- ORDER BY aplica a ordenação sobre o alias 'densidade_calculada'.
-- DESC = decrescente → os estados mais densos aparecem primeiro.
-- Isso facilita a identificação imediata das regiões críticas.
ORDER BY densidade_calculada DESC;

/*
──────────────────────────────────────────────────────────────────────
RESULTADO ESPERADO (27 linhas):

 UF                  | Região       | Densidade  | Classificação
 ────────────────────┼──────────────┼────────────┼───────────────────
 Distrito Federal    | Centro-Oeste |  489,06    | Alta Densidade
 Rio de Janeiro      | Sudeste      |  402,49    | Alta Densidade
 São Paulo           | Sudeste      |  178,92    | Alta Densidade
 Alagoas             | Nordeste     |  112,38    | Alta Densidade
 Sergipe             | Nordeste     |  106,73    | Alta Densidade
 Pernambuco          | Nordeste     |   98,57    | Média Densidade
 ...                 | ...          |    ...     | ...
 Mato Grosso         | Centro-Oeste |    4,19    | Muito Baixa Densidade
 Roraima             | Norte        |    2,84    | Muito Baixa Densidade
 Amazonas            | Norte        |    2,53    | Muito Baixa Densidade

DISTRIBUIÇÃO POR CLASSIFICAÇÃO:
  Alta Densidade        →  5 UFs
  Média Densidade       → 12 UFs
  Baixa Densidade       →  7 UFs
  Muito Baixa Densidade →  3 UFs

──────────────────────────────────────────────────────────────────────
INSIGHT — IMPACTO PARA TOMADA DE DECISÃO:

O resultado expõe dois Brasis opostos em termos de gestão territorial.
Os 5 estados de Alta Densidade — DF, RJ, SP, AL e SE — concentram
populações em áreas relativamente pequenas, gerando pressão constante
sobre infraestrutura urbana: transporte, saneamento, habitação e saúde.
Investimento per capita nessas regiões é mais eficiente logisticamente,
porém a demanda supera historicamente a oferta de serviços.

No extremo oposto, Amazonas (2,53 hab/km²), Roraima e Mato Grosso
enfrentam o desafio inverso: prestar serviços públicos em territórios
imensíssimos com pouquíssimos habitantes por km². O custo per capita
de construir uma escola, um posto de saúde ou uma estrada nessas
regiões é ordens de magnitude maior do que nos estados densos.
Políticas públicas uniformes aplicadas igualmente a todas as UFs
são, portanto, estruturalmente injustas e ineficientes.
──────────────────────────────────────────────────────────────────────
*/




-- ======================================================================
-- DESAFIO 2 — Agregação Macrorregional (IDH e Renda por Região)
-- ======================================================================
--
-- OBJETIVO:
--   Consolidar os 27 estados em 5 macrorregiões e calcular, para cada
--   região, a média do IDH e do rendimento mensal per capita.
--   Classificar automaticamente cada região pelo nível de desenvolvimento.
--
-- CONCEITO:
--   GROUP BY agrupa todas as linhas com o mesmo valor de 'regiao'
--   e aplica funções de agregação (AVG, COUNT) sobre esse conjunto.
--   O resultado retorna 5 linhas — uma por macrorregião.
--
-- FUNÇÕES DE AGREGAÇÃO UTILIZADAS:
--   AVG()   → média aritmética simples do grupo
--   COUNT() → contagem de registros no grupo
--   ROUND() → arredondamento do resultado para apresentação
--
-- COLUNAS ENVOLVIDAS:
--   regiao              → TEXT    — macrorregião brasileira
--   idh                 → REAL    — índice de 0 a 1 (PNUD 2021)
--   rendimento_per_capita → INTEGER — renda domiciliar mensal em R$
-- ======================================================================

SELECT

    -- Dimensão de agrupamento: cada linha do resultado representa
    -- uma das 5 macrorregiões brasileiras.
    regiao,

    -- COUNT(uf) conta quantos estados compõem cada região.
    -- Útil para contextualizar as médias (Nordeste tem 9 estados;
    -- Centro-Oeste tem 4 — médias com pesos populacionais distintos).
    COUNT(uf) AS total_estados,

    -- AVG(idh): média simples do IDH de todos os estados da região.
    -- ROUND(..., 3) mantém 3 casas decimais, padrão do índice PNUD.
    ROUND(AVG(idh), 3) AS media_idh,

    -- AVG(rendimento_per_capita): média da renda mensal domiciliar
    -- per capita de todos os estados da região.
    -- ROUND(..., 2) para exibir como valor monetário (centavos).
    ROUND(AVG(rendimento_per_capita), 2) AS media_rendimento_per_capita,

    -- CLASSIFICAÇÃO AUTOMÁTICA DO IDH REGIONAL.
    -- Faixas baseadas na tabela oficial do PNUD/ONU:
    --   >= 0,800 → Muito Alto  |  >= 0,750 → Alto
    --   >= 0,700 → Médio-Alto  |  >= 0,650 → Médio
    --   <  0,650 → Baixo
    CASE
        WHEN AVG(idh) >= 0.750 THEN 'IDH Alto'
        WHEN AVG(idh) >= 0.700 THEN 'IDH Médio-Alto'
        WHEN AVG(idh) >= 0.650 THEN 'IDH Médio'
        ELSE                        'IDH Baixo'
    END AS status_idh,

    -- CLASSIFICAÇÃO AUTOMÁTICA DA RENDA REGIONAL.
    -- Faixas calibradas com base no salário mínimo de 2023 (R$ 1.320):
    --   >= R$ 2.000 → Renda Alta   (acima de 1,5x o salário mínimo)
    --   >= R$ 1.500 → Renda Média  (acima do salário mínimo)
    --   <  R$ 1.500 → Renda Baixa  (abaixo ou próximo ao mínimo)
    CASE
        WHEN AVG(rendimento_per_capita) >= 2000 THEN 'Renda Alta'
        WHEN AVG(rendimento_per_capita) >= 1500 THEN 'Renda Média'
        ELSE                                         'Renda Baixa'
    END AS status_renda

FROM censo

-- GROUP BY é obrigatório sempre que há funções de agregação.
-- Sem ele, o banco retornaria erro ou apenas 1 linha global.
-- Aqui agrupa as 27 UFs nos 5 grupos regionais.
GROUP BY regiao

-- Ordenamos pela média de IDH de forma decrescente para que
-- as regiões mais desenvolvidas apareçam no topo do relatório.
ORDER BY media_idh DESC;

/*
──────────────────────────────────────────────────────────────────────
RESULTADO ESPERADO (5 linhas):

 Região        | Estados | IDH   | Renda     | Status IDH    | Status Renda
 ──────────────┼─────────┼───────┼───────────┼───────────────┼─────────────
 Sul           |    3    | 0,756 | R$ 2.624  | IDH Alto      | Renda Alta
 Sudeste       |    4    | 0,754 | R$ 2.259  | IDH Alto      | Renda Alta
 Centro-Oeste  |    4    | 0,751 | R$ 2.439  | IDH Alto      | Renda Alta
 Norte         |    7    | 0,699 | R$ 1.363  | IDH Médio     | Renda Baixa
 Nordeste      |    9    | 0,686 | R$ 1.169  | IDH Médio     | Renda Baixa

──────────────────────────────────────────────────────────────────────
INSIGHT — IMPACTO PARA TOMADA DE DECISÃO:

O resultado revela uma divisão binária nítida no Brasil: Sul, Sudeste
e Centro-Oeste formam um bloco homogêneo de IDH Alto e Renda Alta,
enquanto Norte e Nordeste — que juntos somam 16 dos 27 estados e
abrigam a maior parte da população mais pobre do país — operam
em patamares de IDH Médio e Renda Baixa.

A diferença de renda entre o Sul (R$ 2.624) e o Nordeste (R$ 1.169)
é de 2,25 vezes, o que significa que um trabalhador nordestino típico
precisa de mais de dois meses de renda para igualar o ganho mensal
de um trabalhador sulista. Esse dado reforça que transferências de
renda, fundos de equalização fiscal (como o FPE) e políticas de
desenvolvimento regional não são escolhas políticas — são correções
estruturais necessárias para um mínimo de equidade territorial.
──────────────────────────────────────────────────────────────────────
*/




-- ======================================================================
-- DESAFIO 3 — Filtragem por Linha de Corte Dinâmica (Frota de Veículos)
-- ======================================================================
--
-- OBJETIVO:
--   Identificar os estados com frota de veículos acima da média
--   nacional, calculando essa média de forma dinâmica (sem hardcode).
--
-- CONCEITO:
--   Uma SUBQUERY (consulta aninhada) é uma query dentro de outra.
--   Aqui ela é usada de duas formas:
--     1. Na cláusula WHERE → como filtro dinâmico
--     2. Na cláusula SELECT → para exibir a média ao lado de cada linha
--
-- RESTRIÇÃO TÉCNICA DO PROJETO:
--   É PROIBIDO escrever o valor da média diretamente no código.
--   ERRADO:  WHERE total_veiculos > 4022899   ← valor fixo (hardcoded)
--   CORRETO: WHERE total_veiculos > (SELECT AVG(total_veiculos) FROM censo)
--
--   A vantagem: se os dados forem atualizados, a query continua correta
--   sem precisar de nenhuma alteração manual.
--
-- COLUNA ENVOLVIDA:
--   total_veiculos → INTEGER — frota total registrada por UF (DENATRAN 2022)
-- ======================================================================

SELECT

    -- Identificação da UF e sua região para contextualização.
    uf,
    regiao,

    -- Valor absoluto da frota da UF, formatado para leitura.
    total_veiculos,

    -- SUBQUERY no SELECT: calcula e exibe a média nacional em cada linha.
    -- O mesmo valor aparece repetido em todas as linhas — isso é intencional.
    -- Permite que o leitor compare diretamente o valor da UF com a média.
    -- ROUND(..., 0) arredonda para inteiro (veículos não têm decimais).
    ROUND((SELECT AVG(total_veiculos) FROM censo), 0) AS media_nacional,

    -- Diferença entre a frota da UF e a média nacional.
    -- Valor positivo = quantos veículos a UF tem ALÉM da média.
    -- Útil para dimensionar o excedente de cada estado.
    ROUND(
        total_veiculos - (SELECT AVG(total_veiculos) FROM censo),
    0) AS excedente_da_media,

    -- CLASSIFICAÇÃO AUTOMÁTICA por intensidade do excedente.
    -- O limiar de 3x a média separa o outlier extremo (SP) dos demais.
    -- Nota: o CASE só precisa cobrir casos acima da média, pois o WHERE
    -- já filtrou os estados abaixo — não há risco de NULL aqui.
    CASE
        WHEN total_veiculos > (SELECT AVG(total_veiculos) FROM censo) * 3
            THEN 'Muito Acima da Média'
        WHEN total_veiculos > (SELECT AVG(total_veiculos) FROM censo)
            THEN 'Acima da Média'
    END AS status_frota

FROM censo

-- FILTRO DINÂMICO: a subquery calcula AVG em tempo de execução.
-- O banco primeiro resolve o SELECT interno (AVG ≈ 4.022.899),
-- depois usa esse resultado como valor de corte no WHERE externo.
WHERE total_veiculos > (SELECT AVG(total_veiculos) FROM censo)

-- Ordenação decrescente: estado com maior frota aparece primeiro.
ORDER BY total_veiculos DESC;

/*
──────────────────────────────────────────────────────────────────────
RESULTADO ESPERADO (8 linhas — estados acima da média nacional):

 UF                 | Região   | Frota      | Média Nac. | Excedente   | Status
 ───────────────────┼──────────┼────────────┼────────────┼─────────────┼──────────────────────
 São Paulo          | Sudeste  | 35.091.000 | 4.022.899  | +31.068.101 | Muito Acima da Média
 Minas Gerais       | Sudeste  | 11.891.402 | 4.022.899  |  +7.868.503 | Acima da Média
 Rio de Janeiro     | Sudeste  |  7.743.212 | 4.022.899  |  +3.720.313 | Acima da Média
 Paraná             | Sul      |  7.190.000 | 4.022.899  |  +3.167.101 | Acima da Média
 Rio Grande do Sul  | Sul      |  6.978.234 | 4.022.899  |  +2.955.335 | Acima da Média
 Santa Catarina     | Sul      |  5.189.234 | 4.022.899  |  +1.166.335 | Acima da Média
 Bahia              | Nordeste |  4.887.673 | 4.022.899  |    +864.774 | Acima da Média
 Goiás              | C-Oeste  |  4.199.523 | 4.022.899  |    +176.624 | Acima da Média

Média nacional calculada dinamicamente: 4.022.899 veículos
UFs acima da média: 8 de 27 (29,6% dos estados)

──────────────────────────────────────────────────────────────────────
INSIGHT — IMPACTO PARA TOMADA DE DECISÃO:

S�o Paulo é um outlier tão extremo (35 milhões de veículos) que sozinho
distorce a média nacional para cima, tornando-a uma métrica de corte
elevada para a maioria dos estados. Dos 8 estados acima da média,
6 pertencem ao Sudeste e Sul — as regiões de maior renda do país.

Para formuladores de políticas de mobilidade urbana e infraestrutura
viária, o dado indica onde a demanda por rodovias, combustíveis,
manutenção de vias e emissões veiculares é mais intensa. Já os 19
estados abaixo da média — especialmente os do Norte e Nordeste —
sinalizam dependência crítica de transporte público e coletivo,
que historicamente recebe subinvestimento nessas regiões.
──────────────────────────────────────────────────────────────────────
*/




-- ======================================================================
-- DESAFIO 4 — Análise de Vulnerabilidade Social
-- ======================================================================
--
-- OBJETIVO:
--   Mapear os estados que combinam simultaneamente dois indicadores
--   de vulnerabilidade: baixa renda per capita E alto volume de
--   matrículas no ensino fundamental (grande população em idade escolar
--   dependente da rede pública).
--
-- CONCEITO:
--   O operador AND exige que AMBAS as condições sejam verdadeiras.
--   Um estado com baixa renda mas poucas matrículas NÃO aparece.
--   Um estado com muitas matrículas mas renda alta NÃO aparece.
--   Somente a interseção das duas condições é retornada.
--
-- CRITÉRIOS DEFINIDOS PELO PROJETO:
--   rendimento_per_capita < 1.500        → abaixo da linha de corte
--   matriculas_ensino_fundamental > 200.000 → grande demanda escolar
--
-- COLUNAS ENVOLVIDAS:
--   rendimento_per_capita           → INTEGER — renda domiciliar em R$ (2023)
--   matriculas_ensino_fundamental   → INTEGER — matrículas no EF (INEP 2021)
-- ======================================================================

SELECT

    -- Identificação da UF e região para mapeamento geográfico.
    uf,
    regiao,

    -- Valores brutos dos dois indicadores filtrados.
    -- Exibi-los no resultado permite conferir os critérios aplicados.
    rendimento_per_capita,
    matriculas_ensino_fundamental,

    -- CLASSIFICAÇÃO AUTOMÁTICA DE VULNERABILIDADE POR RENDA.
    -- Subcategoriza os estados que já passaram pelo filtro (renda < 1.500)
    -- em graus mais específicos de criticidade:
    --   < R$ 1.000 → Crítica   (quase R$ 400 abaixo do salário mínimo)
    --   < R$ 1.200 → Alta      (claramente abaixo do mínimo)
    --   >= R$ 1.200 → Moderada (próximo ao mínimo, mas ainda vulnerável)
    CASE
        WHEN rendimento_per_capita < 1000 THEN 'Vulnerabilidade Crítica'
        WHEN rendimento_per_capita < 1200 THEN 'Alta Vulnerabilidade'
        ELSE                                   'Vulnerabilidade Moderada'
    END AS nivel_vulnerabilidade,

    -- CLASSIFICAÇÃO AUTOMÁTICA DA DEMANDA ESCOLAR.
    -- Indica o tamanho da rede de ensino fundamental que o estado
    -- precisa sustentar com sua capacidade fiscal limitada:
    --   > 1.000.000 matrículas → Alta Demanda   (estados grandes/populosos)
    --   > 500.000   matrículas → Média Demanda
    --   <= 500.000  matrículas → Baixa Demanda  (estados menores)
    CASE
        WHEN matriculas_ensino_fundamental > 1000000 THEN 'Alta Demanda Escolar'
        WHEN matriculas_ensino_fundamental > 500000  THEN 'Média Demanda Escolar'
        ELSE                                              'Baixa Demanda Escolar'
    END AS demanda_escolar

FROM censo

-- DUPLO FILTRO COM AND:
-- Linha 1: seleciona estados com renda abaixo de R$ 1.500
-- Linha 2: seleciona estados com mais de 200.000 matrículas no EF
-- AND garante que apenas estados que atendam às DUAS condições
-- simultaneamente sejam incluídos no resultado.
WHERE rendimento_per_capita        < 1500
  AND matriculas_ensino_fundamental > 200000

-- Ordenação pelo indicador mais crítico (renda) em ordem crescente:
-- os estados mais pobres aparecem primeiro no relatório.
ORDER BY rendimento_per_capita ASC;

/*
──────────────────────────────────────────────────────────────────────
RESULTADO ESPERADO (12 linhas):

 UF                  | Região   | Renda  | Matrículas | Vulnerab.       | Demanda Escolar
 ────────────────────┼──────────┼────────┼────────────┼─────────────────┼────────────────
 Maranhão            | Nordeste |   945  | 1.064.699  | Crítica         | Alta
 Piauí               | Nordeste | 1.104  |   453.011  | Alta            | Baixa
 Alagoas             | Nordeste | 1.110  |   458.782  | Alta            | Baixa
 Pará                | Norte    | 1.112  | 1.372.895  | Alta            | Alta
 Bahia               | Nordeste | 1.139  | 1.946.957  | Alta            | Alta
 Amazonas            | Norte    | 1.172  |   702.763  | Alta            | Média
 Paraíba             | Nordeste | 1.195  |   563.914  | Alta            | Média
 Sergipe             | Nordeste | 1.195  |   350.481  | Alta            | Baixa
 Ceará               | Nordeste | 1.214  | 1.270.312  | Moderada        | Alta
 Rio Grande do Norte | Nordeste | 1.238  |   510.219  | Moderada        | Média
 Pernambuco          | Nordeste | 1.383  | 1.378.021  | Moderada        | Alta
 Tocantins           | Norte    | 1.427  |   231.879  | Moderada        | Baixa

Total: 12 UFs (10 do Nordeste, 2 do Norte)
Nenhum estado do Sul, Sudeste ou Centro-Oeste atende às duas condições.

──────────────────────────────────────────────────────────────────────
INSIGHT — IMPACTO PARA TOMADA DE DECISÃO:

Este desafio revela o perfil mais crítico de vulnerabilidade social:
estados com grande número de crianças em idade escolar e renda familiar
insuficiente para custear qualquer serviço privado. Nesses 12 estados,
a escola pública não é apenas uma opção — é a única opção disponível.

O Maranhão é o caso extremo: com R$ 945 de renda per capita e mais
de 1 milhão de matrículas no ensino fundamental, o estado concentra
o pior cenário possível — máxima demanda escolar com mínima capacidade
de financiamento familiar. 

A total ausência de estados do Sul, Sudeste e Centro-Oeste na lista
não é coincidência: é a expressão quantitativa da desigualdade regional
estrutural do Brasil. Políticas de fundos redistributivos da educação
(FUNDEB) e programas de transferência de renda (Bolsa Família) têm
justamente esses 12 estados como público prioritário. Os dados SQL
confirmam e quantificam essa prioridade de forma objetiva.
──────────────────────────────────────────────────────────────────────
*/
