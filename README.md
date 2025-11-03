
# Ferramenta de Otimização de Microrredes Híbridas / Hybrid Microgrid Optimization Tool

![Language](https://img.shields.io/badge/Language-Octave-blue.svg)
![Status](https://img.shields.io/badge/Status-Academic%20Project-lightgrey.svg)

---

### 🇧🇷 Português

Um script em Octave para a simulação e otimização tecno-econômica de microrredes híbridas (PV, Baterias, Gerador). O objetivo é encontrar a configuração de menor Custo Nivelado da Energia (LCOE) para operações conectadas à rede (On-Grid) e isoladas (Off-Grid).

* **Autor:** Eng. Yuri Escobar Gayer ([yurigayer@gmail.com](mailto:yurigayer@gmail.com))
* **Orientador:** Prof. Dr. Lizandro de Souza Oliveira ([lizandro.oliveira@ucpel.edu.br](mailto:lizandro.oliveira@ucpel.edu.br))
* **Programa:** Mestrado em Engenharia Eletrônica e Computação - https://pos.ucpel.edu.br/ppgeec/

---

### 🇬🇧 English

An Octave script for the techno-economic simulation and optimization of hybrid microgrids (PV, Batteries, Genset). The goal is to find the configuration with the lowest Levelized Cost of Energy (LCOE) for both on-grid and off-grid operations.

* **Author:** Yuri Escobar Gayer, Eng. ([yurigayer@gmail.com](mailto:yurigayer@gmail.com))
* **Advisor:** Prof. Lizandro de Souza Oliveira, PhD ([lizandro.oliveira@ucpel.edu.br](mailto:lizandro.oliveira@ucpel.edu.br))
* **Program:** Master's in Electronic and Computer Engineering



-----

### 🇧🇷 Português

-----

## 💡 Sobre o Projeto

Esta é uma ferramenta de otimização tecno-econômica para microrredes híbridas (SFV-SAE-GMG) desenvolvida em GNU Octave.

O script avalia milhares de configurações de sistema em dois modos de operação: **On-Grid** (Conectado à Rede) e **Off-Grid** (Ilhado).

O diferencial deste código é a centralização de todas as entradas em um **"Painel de Controle" (Seção 1)**, o cálculo de métricas financeiras avançadas como **LCOE** (Custo Nivelado da Energia) e **LCOS** (Custo Nivelado do Armazenamento), e a geração de gráficos de despacho interativos.

## 🚀 Funcionalidades

  * **Painel de Controle Unificado:** (Seção 1) Configure facilmente carga, custos, tarifas e o espaço de busca (SFV, SAE, GMG).
  * **Métricas Avançadas:** Calcula LCOE, LCOS, CAPEX, OPEX e LCC.
  * **Lógica de Despacho Dupla:**
      * **On-Grid:** `SFV` -\> `SAE` -\> `Rede` (Backup). O GMG não é utilizado.
      * **Off-Grid:** `SFV` -\> `SAE` -\> `GMG` (Backup).
  * **Plot Interativo:** O gráfico de LCOE é clicável. Clique em uma solução para exibir seus dados (SFV, SAE, GMG, LCOE, LCOS, CAPEX, OPEX e Autonomia) em uma caixa de texto no próprio gráfico.
  * **Exportação Completa:** Gera 8 relatórios de saída, incluindo dossiês `.txt` da solução ótima, sumários `.txt` (Top 15) e dados brutos `.csv` de todas as soluções viáveis.

## 🛠️ Como Usar

### 1\. Pré-requisitos

  * GNU Octave (v10.2.0 ou similar).
  * Pacote `statistics` (carregado via `pkg load statistics`).

### 2\. Configuração

1.  Abra o script `microgrid_optimizer.m`.
2.  Modifique **apenas a Seção 1 (Painel de Controle)** com seus dados de projeto.
3.  Defina o `consumo_medio_mensal_kwh`, custos de componentes, tarifas e os `vetor_...` (espaço de busca) que deseja simular.

### 3\. Execução

  * Pressione **F5** ou execute o script no Octave.

## 📊 Saídas (Outputs)

O script gera os 8 arquivos a seguir no seu diretório:

### Relatórios (.txt e .csv)

  * **`relatorio_sumario_on_grid.txt` / `...off_grid.txt`**: O "Top 15" de soluções (menor LCOE), idêntico ao que é exibido no console.
  * **`dossie_projeto_on_grid.txt` / `...off_grid.txt`**: Dossiê completo da **Solução Ótima** (menor LCOE), detalhando premissas, configuração e balanço de energia anual.
  * **`relatorio_completo_on_grid.csv` / `...off_grid.csv`**: Os dados brutos de **todas as soluções viáveis** (que passaram pelos filtros) para análise em Excel/Python.
  * **`perfil_carga_e_solar.csv`**: Os dados de 8760 horas de carga (kW) e irradiação (W/m²) gerados e usados na simulação.

### Gráficos Principais

1.  **LCOE vs. Penetração (Interativo):** Gráfico de decisão principal. **Clique em um ponto** para ver os 8 KPIs daquela configuração.
2.  **Operação Diária Detalhada:** O "eletrocardiograma" do despacho (SFV, SAE, GMG, Rede) e SoC da bateria durante uma semana crítica de inverno.
3.  **Balanço Mensal de Energia:** A estratégia sazonal de geração e consumo.

## 🧑‍💻 Autor

  * **Eng. Eletricista Yuri Escobar Gayer - yurigayer@gmail.com**
-----

### 🇬🇧 English

-----

## 💡 About This Project

This is a GNU Octave tool for techno-economic optimization of hybrid microgrids, comprising a PV System (SFV), Battery Energy Storage (BESS/SAE), and a Genset (GMG).

The script evaluates thousands of system configurations in two distinct operating modes: **On-Grid** (Grid-Connected) and **Off-Grid** (Islanded).

This code's key feature is the centralization of all inputs in a **"Control Panel" (Section 1)**, the calculation of advanced financial metrics like **LCOE** (Levelized Cost of Energy) and **LCOS** (Levelized Cost of Storage), and the generation of interactive dispatch graphs.

## 🚀 Features

  * **Unified Control Panel:** (Section 1) Easily configure load, component costs, tariffs, and the simulation search space (PV, BESS, GENSET sizes).
  * **Advanced Metrics:** Calculates LCOE, LCOS, CAPEX, OPEX, and LCC.
  * **Dual Dispatch Logic:**
      * **On-Grid:** `PV` -\> `BESS` -\> `Grid` (Backup). GENSET is not used.
      * **Off-Grid:** `PV` -\> `BESS` -\> `GENSET` (Backup).
  * **Interactive Plot:** The LCOE chart is clickable. **Click a solution point** to display its key data (PV, BESS, GENSET, LCOE, LCOS, CAPEX, OPEX, and Autonomy) in a text box directly on the plot.
  * **Full Export:** Generates 8 output reports, including `.txt` dossiers for the optimal solution, `.txt` summaries (Top 15), and `.csv` raw data for all viable solutions.

## 🛠️ How to Use

### 1\. Prerequisites

  * GNU Octave (v10.2.0 or similar).
  * `statistics` package (loaded via `pkg load statistics`).

### 2\. Configuration

1.  Open the `microgrid_optimizer.m` script.
2.  Modify **only Section 1 (Control Panel)** with your project data.
3.  Input your load data (`consumo_medio_mensal_kwh`), component costs, grid tariffs, and the `vetor_...` (search space) you wish to simulate.

### 3\. Execution

  * Press **F5** or run the script in Octave.

## 📊 Outputs

The script generates the following 8 files in your directory:

### Reports (.txt & .csv)

  * **`relatorio_sumario_on_grid.txt` / `...off_grid.txt`**: The "Top 15" solutions (lowest LCOE), identical to the console output.
  * **`dossie_projeto_on_grid.txt` / `...off_grid.txt`**: A complete dossier of the **Optimal Solution** (lowest LCOE), detailing inputs, configuration, and annual energy balance.
  * **`relatorio_completo_on_grid.csv` / `...off_grid.csv`**: The raw data of **all viable solutions** (that passed the filters) for external analysis in Excel/Python.
  * **`perfil_carga_e_solar.csv`**: The 8760-hour load (kW) and irradiation (W/m²) data generated and used in the simulation.

### Key Graphs

1.  **LCOE vs. Penetration (Interactive):** The main decision-making chart. **CLICK A POINT** to see that configuration's 8 key metrics.
2.  **Detailed Daily Operation:** The system's "EKG," showing the dispatch logic (PV, BESS, GENSET, Grid) and battery SoC during a critical winter week.
3.  **Monthly Energy Balance:** The macro-level seasonal energy strategy.

## 🧑‍💻 Author

  * **Eng. Eletricista Yuri Escobar Gayer - yurigayer@gmail.com**
