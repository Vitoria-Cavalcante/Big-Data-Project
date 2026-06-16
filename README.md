Projeto: Inteligência Analítica de Dados Censitários (IBGE)
Este projeto demonstra a execução de um pipeline de dados completo, desde a extração e tratamento de dados brutos do IBGE até a automação de insights estratégicos usando SQL puro e visualização dinâmica.

Sobre o Projeto:
O objetivo deste trabalho é atuar como uma solução de Engenharia e Análise de Dados. O sistema não apenas processa informações sociodemográficas do Brasil, mas aplica regras de negócio diretamente no banco de dados, permitindo que a própria base de dados "classifique" o status de cada análise (como níveis de densidade, vulnerabilidade social e indicadores econômicos).

Tecnologias Utilizadas
- Linguagem: Python (Pandas para tratamento de dados).
- Banco de Dados: SQLite (SQL para automação de regras de negócio).
- Visualização: HTML/CSS/JavaScript (Chart.js para representação dos dados).

Metodologia: Pipeline ETL (Extract, Transform, Load).

Funcionalidades do Pipeline:
- Coleta e Higienização: Tratamento rigoroso de encodings (latin-1 para utf-8), correção de delimitadores, formatação de decimais e limpeza de nomes de colunas.
- Automação via SQL: Implementação de lógica condicional (CASE WHEN) no banco de dados para categorização automática dos resultados.
- Insights Dinâmicos: Relatórios que entregam o dado processado junto com a interpretação de impacto prático.
- Dashboard Interativo: Visualização web independente de ferramentas de BI proprietárias.

Desafios Analíticos Resolvidos:
O projeto resolve quatro desafios principais através de consultas SQL avançadas:
- Densidade Demográfica: Classificação automática por faixas de saturação populacional.
- Agregação Macrorregional: Análise de IDH e Renda por região geográfica.
- Análise de Frota: Filtragem dinâmica utilizando médias calculadas em tempo real.
- Vulnerabilidade Social: Cruzamento multi-criterioso de dados educacionais e socioeconômicos.


📁 Estrutura do Repositório
├── data/               # Arquivos brutos (origem IBGE) e processados
├── notebooks/          # Scripts de limpeza (ETL) em Python
├── sql/                # Queries de consulta e automação (CASE WHEN)
├── web/                # Interface de visualização (HTML/JS)
└── README.md

💡 Como executar
- Clone este repositório:
git clone https://github.com/seu-usuario/seu-repositorio.git

- Prepare o ambiente:
Certifique-se de ter o Python instalado e instale as dependências:
pip install pandas

- Execute o pipeline:
Rode os scripts na pasta notebooks/ para processar a base bruta.

- Consulte os dados:
Utilize um cliente SQLite para executar as queries na pasta sql/.



📝 Contribuição
Este projeto faz parte de um estudo acadêmico/profissional sobre Big Data e Engenharia de Dados. Sinta-se à vontade para abrir Issues com sugestões ou Pull Requests para melhorias nas queries SQL.

Desenvolvido por [Vitória Cavalcante e Amanda Rapold]
