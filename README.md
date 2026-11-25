# Análise da atomização e da distribuição do tamanho de gotas utilizando redes bayesianas
## Sobre o projeto

Este projeto foi desenvolvido para a disciplina de **Modelos Probabilísticos**, ministrada pelo Prof. Dr. Carlos Dias Maciel no segundo semestre de 2026, no Programa de Pós-Graduação da UNESP, em Araraquara.

O objetivo do estudo foi investigar como as características dos bicos atomizadores e as condições operacionais estão relacionadas às propriedades do spray gerado, com foco na distribuição do tamanho das gotas.
Para isso, foram utilizadas ferramentas de análise estatística e modelagem probabilística em **R**, especialmente **redes bayesianas**, para investigar dependências entre as variáveis experimentais. O trabalho concentra-se na **construção, aprendizagem estrutural e avaliação de redes bayesianas**, sem assumir que as associações identificadas sejam necessariamente relações causais.
## Base de dados

Os dados são provenientes do estudo experimental de Fritz e Hoffmann (2015), desenvolvido no âmbito do *United States Department of Agriculture – Agricultural Research Service* (USDA-ARS).

Os experimentos foram realizados em túnel de vento, utilizando diferentes modelos de bicos atomizadores e condições de pressão de alimentação, velocidade do ar, orientação e tamanho nominal do orifício. A distribuição do tamanho das gotas foi caracterizada por difração a laser.

A base contém:
- **2.270 registros experimentais**;
- **716 condições operacionais distintas**;
- **18 identificações de bicos atomizadores**;
- **13 variáveis**, incluindo parâmetros operacionais, características do spray e identificadores experimentais.

Os dados são experimentais; os modelos apresentados pelos autores do estudo original são correlações empíricas ajustadas a partir dessas medições.
**Fonte:** [USDA-ARS — Fixed-Wing Spray Nozzle Models](https://catalog.data.gov/dataset/data-from-update-to-the-usda-ars-fixed-wing-spray-nozzle-models).
## Variáveis e siglas
### 1. Parâmetros de entrada
| Variável | Descrição | Unidade ou tipo |
|---|---|---|
| `Nozzle` | Modelo ou família do bico atomizador utilizado no experimento. | Categórica |
| `Orifice` | Tamanho nominal do orifício do bico, conforme a designação do fabricante. | Código nominal (tratado como categórico) |
| `Airspeed` | Velocidade do ar no túnel de vento. | mph |
| `Pressure` | Pressão de alimentação do líquido no bico atomizador. | psi |
| `Orientation` | Ângulo de orientação do bico em relação ao escoamento de ar. | ° |
**Observação:** os valores de `Orifice` não representam necessariamente diâmetros físicos expressos na mesma unidade entre diferentes famílias de bicos.
### 2. Características da distribuição de gotas
| Variável | Sigla | Descrição | Unidade |
|---|---|---|---|
| `DV10` | Dv0.1 | Diâmetro abaixo do qual se encontra 10% do volume acumulado das gotas. | µm |
| `DV50` | Dv0.5 / VMD | Diâmetro mediano volumétrico, abaixo do qual se encontra 50% do volume acumulado. | µm |
| `DV90` | Dv0.9 | Diâmetro abaixo do qual se encontra 90% do volume acumulado das gotas. | µm |
| `RS` | Relative Span | Medida adimensional da largura relativa da distribuição de tamanhos. | Adimensional |
| `Less100` | — | Percentual do volume do spray em gotas com diâmetro inferior a 100 µm. | % |
| `Less200` | — | Percentual do volume do spray em gotas com diâmetro inferior a 200 µm. | % |
Os diâmetros DV10, DV50 e DV90 representam percentis da distribuição **volumétrica**, e não da distribuição numérica de gotas.

O *Relative Span* (RS) é calculado por:

$$
RS = \frac{DV90-DV10}{DV50}
$$

Valores menores de RS indicam uma distribuição relativamente mais estreita, enquanto valores maiores indicam maior dispersão entre os percentis volumétricos considerados.
### 3. Identificadores experimentais

| Variável | Descrição |
|---|---|
| `Run` | Identificador da execução experimental. |
| `Rep` | Identificador da repetição experimental. |

`Run` e `Rep` permanecem na base original, mas **não foram utilizados como nós das redes**. A modelagem também excluiu `RS`, por ser calculado a partir dos percentis volumétricos já representados por DV10, DV50 e DV90.
Portanto, os grafos utilizam **10 variáveis**: cinco parâmetros de entrada (`Nozzle`, `Orifice`, `Airspeed`, `Pressure`, `Orientation`) e cinco características do spray (`DV10`, `DV50`, `DV90`, `Less100`, `Less200`). `Nozzle` e `Orifice` foram tratados como fatores; as demais variáveis foram mantidas como numéricas, sem discretização.
## Metodologia

Foram construídos quatro grafos direcionados acíclicos (*Directed Acyclic Graphs*, DAGs):
- **G1 — Hipótese inicial:** cada parâmetro de entrada foi conectado às cinco características do spray (25 arestas).
- **G2 — Aprendizagem estrutural:** grafo obtido por *Hill Climbing*, partindo de uma estrutura vazia e utilizando o critério BIC-CG (11 arestas).
- **G3 — Hipótese fisicamente motivada:** grafo proposto a partir de relações consideradas plausíveis entre geometria, operação e características granulométricas (9 arestas).
- **G4 — Aprendizagem inicializada no G3:** aplicação de *Hill Climbing* usando o G3 como estrutura inicial, permitindo alterar suas arestas (13 arestas).
Para G2 e G4, foram utilizadas as mesmas restrições direcionais, três reinícios do algoritmo e nenhum limite adicional de pais por nó. As estruturas foram comparadas pelo **BIC-CG**, pela **log-verossimilhança** e pela **distância estrutural de Hamming (SHD)**.
Como a base combina variáveis categóricas e contínuas, foi utilizada a pontuação para redes condicionais gaussianas (`bic-cg`). O BIC-CG e a log-verossimilhança avaliam o ajuste estatístico aos dados utilizados, enquanto a SHD quantifica diferenças estruturais entre os grafos. Essas métricas **não demonstram causalidade nem desempenho preditivo em observações novas**.
## Resultados principais

| Grafo | Nós | Arestas | BIC-CG | Log-verossimilhança |
|---|---:|---:|---:|---:|
| G1 | 10 | 25 | Não calculado | Não calculada |
| G2 | 10 | 11 | -85197.65 | -82890.98 |
| G3 | 10 | 9 | -90744.17 | -89121.39 |
| G4 | 10 | 13 | -87143.97 | -84806.39 |
O G1 não recebeu pontuação porque a rotina de avaliação identificou combinações de categorias com poucas observações para estimar adequadamente algumas distribuições condicionais. Entre os modelos avaliados, o **G2 apresentou o BIC-CG mais favorável**. O G4 melhorou o ajuste em relação ao G3, mas não superou o G2.

As distâncias estruturais obtidas foram: **SHD(G2, G3) = 14**, **SHD(G2, G4) = 6** e **SHD(G3, G4) = 13**.
Esses resultados mostram que o ponto de partida pode influenciar a estrutura encontrada pelo algoritmo. Como o *Hill Climbing* é uma busca heurística, não há garantia de que o melhor resultado observado corresponda à estrutura globalmente ótima.
## Organização dos arquivos

```text
.
├── README.md
├── dados/
│   ├── Dataset.csv
│   └── bicos/
├── scripts/
│   ├── projeto_Final.R
│   ├── preparacao_dados.R
│   ├── grafos.R
│   └── analisar_grafo.R
├── resultados/
│   ├── grafo1.dot
│   ├── grafo1.svg
│   ├── G2.dot
│   ├── G2.svg
│   ├── G3.dot
│   ├── G3.svg
│   ├── G4.dot
│   ├── G4.svg
│   └── metricas_grafos.csv
└── Relatório.pdf
```

A estrutura acima representa os **arquivos esperados para a execução completa**; as funções também podem gerar CSVs individuais por bico.
- `scripts/preparacao_dados.R`: importa a base, define `features`, `targets` e identificadores, prepara os tipos de variáveis e exporta os CSVs por bico.
- `scripts/grafos.R`: constrói G1, G2, G3 e G4, apresenta informações sobre suas conexões e salva os grafos em DOT/SVG.
- `scripts/analisar_grafo.R`: verifica as condições de estimação e calcula o BIC-CG de cada estrutura, quando aplicável.
- `scripts/projeto_Final.R`: integra as etapas, calcula as métricas e compara as estruturas por SHD.
- `resultados/`: reúne as visualizações e a tabela `metricas_grafos.csv`.
- `Relatório.pdf`: relatório acadêmico com a discussão dos resultados.
## Como executar

**Requisitos:** R, pacote `bnlearn` e [Graphviz](https://graphviz.org/) para gerar as figuras SVG. No Windows, o script procura inicialmente `C:/Program Files/Graphviz/bin/dot.exe` e, caso necessário, procura `dot` no `PATH`.

Execute o R a partir da **raiz do projeto**, onde devem estar as pastas `scripts/` e `dados/`:

```r
# Execute a partir da pasta raiz do repositório
source("scripts/projeto_Final.R")
```
Se o diretório de trabalho estiver em outro local, ajuste-o previamente com `setwd()` ou abra o projeto no R/VS Code a partir de sua pasta raiz. Os caminhos usados nos scripts são relativos a essa pasta.

A execução prepara os dados, constrói os quatro grafos, salva os arquivos DOT e, com o Graphviz disponível, as figuras SVG em `resultados/`, apresenta as métricas e os valores de SHD no console e atualiza `resultados/metricas_grafos.csv`.

Algumas análises complementares apresentadas no relatório, como a contagem de condições operacionais distintas e a comparação das arestas mantidas, adicionadas ou removidas entre os grafos, foram realizadas separadamente, de forma individual ou manual. Por esse motivo, nem todas as informações discutidas no relatório são exibidas automaticamente durante a execução dos scripts disponibilizados. O relatório PDF não é gerado pelo script principal.
## Ferramentas e observações

O projeto foi desenvolvido em **R**, com o pacote `bnlearn` para aprendizagem e avaliação de redes bayesianas e o Graphviz para visualização dos grafos.

Ferramentas de inteligência artificial foram utilizadas como apoio à elaboração de trechos de código e à revisão do texto em inglês. A definição dos objetivos, a seleção das hipóteses estruturais e a interpretação dos resultados fazem parte do desenvolvimento acadêmico do trabalho.
## Referência principal

Fritz, B. K.; Hoffmann, W. C. (2015). *Update to the USDA-ARS Fixed-Wing Spray Nozzle Models*. **Transactions of the ASABE**, 58(2), 281–295. https://doi.org/10.13031/trans.58.10896

**Dados experimentais:** [USDA-ARS — Fixed-Wing Spray Nozzle Models](https://catalog.data.gov/dataset/data-from-update-to-the-usda-ars-fixed-wing-spray-nozzle-models).
