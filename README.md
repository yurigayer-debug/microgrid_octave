-----

# Ferramenta de Otimização de Microrredes Híbridas / Hybrid Microgrid Optimization Tool

-----

### Português

Um script em Octave para a simulação e otimização tecno-econômica de microrredes híbridas (PV, Baterias, Gerador). O objetivo é encontrar a configuração de menor Custo Nivelado da Energia (LCOE) para operações conectadas à rede (On-Grid) e isoladas (Off-Grid).

  * **Autor:** Eng. Yuri Escobar Gayer ([yurigayer@gmail.com](mailto:yurigayer@gmail.com))
  * **Orientador:** Prof. Dr. Lizandro de Souza Oliveira ([lizandro.oliveira@ucpel.edu.br](mailto:lizandro.oliveira@ucpel.edu.br))
  * **Programa:** Mestrado em Engenharia Eletrônica e Computação - [https://pos.ucpel.edu.br/ppgeec/](https://pos.ucpel.edu.br/ppgeec/)

-----

##  Funcionalidades Principais

  * **Painel de Controle (Seção 1):** Centraliza todas as entradas do usuário (custos, perfis, tarifas, espaço de busca).
  * **Métricas Avançadas:** Calcula LCOE (Custo Nivelado da Energia), LCOS (Custo Nivelado do Armazenamento), LCC, CAPEX e OPEX.
  * **Lógica de Despacho Dupla:**
      * **On-Grid:** `SFV` -\> `SAE` -\> `Rede` (Backup). GMG inativo.
      * **Off-Grid:** `SFV` -\> `SAE` -\> `GMG` (Backup).
  * **Gráfico Interativo:** O plot de LCOE é clicável e exibe uma caixa de texto com 8 KPIs (SFV, SAE, GMG, LCOE, LCOS, CAPEX, OPEX, Autonomia).
  * **Geração de Relatórios:** Exporta 8 arquivos de saída (dossiês `.txt`, sumários `.txt` e dados brutos `.csv`).

##  Como Usar

### 1\. Pré-requisitos

  * GNU Octave (v10.2.0 ou similar).
  * Pacote `statistics` (carregado via `pkg load statistics`).

### 2\. Configuração

1.  Abra o script `microgrid_optimizer.m`.
2.  Modifique **apenas a Seção 1 (Painel de Controle)** com os dados do seu projeto.

### 3\. Execução

  * Pressione **F5** ou execute o script no Octave.

##  Saídas (Outputs)

### Relatórios (.txt / .csv)

  * **`dossie_projeto_...txt`**: Relatório completo da **Solução Ótima** (menor LCOE).
  * **`relatorio_sumario_...txt`**: Sumário "Top 15" de soluções (idêntico ao console).
  * **`relatorio_completo_...csv`**: Dados brutos de **todas** as soluções viáveis.
  * **`perfil_carga_e_solar.csv`**: Dados de 8760 horas de carga (kW) e irradiação (W/m²).

### Gráficos Principais

1.  **LCOE vs. Penetração (Interativo):** Gráfico de decisão. **Clique em um ponto** para ver os KPIs.
2.  **Operação Diária Detalhada:** "Eletrocardiograma" do despacho da microrrede em uma semana de inverno.
3.  **Balanço Mensal de Energia:** Estratégia sazonal de geração e consumo.

-----

### English

-----

An Octave script for the techno-economic simulation and optimization of hybrid microgrids (PV, Batteries, Genset). The goal is to find the configuration with the lowest Levelized Cost of Energy (LCOE) for both on-grid and off-grid operations.

  * **Author:** Yuri Escobar Gayer, Eng. ([yurigayer@gmail.com](mailto:yurigayer@gmail.com))
  * **Advisor:** Prof. Lizandro de Souza Oliveira, PhD ([lizandro.oliveira@ucpel.edu.br](mailto:lizandro.oliveira@ucpel.edu.br))
  * **Program:** Master's in Electronic and Computer Engineering

-----

##  Key Features

  * **Control Panel (Section 1):** Centralizes all user inputs (costs, profiles, tariffs, search space).
  * **Advanced Metrics:** Calculates LCOE (Levelized Cost of Energy), LCOS (Levelized Cost of Storage), LCC, CAPEX, and OPEX.
  * **Dual Dispatch Logic:**
      * **On-Grid:** `PV` -\> `BESS` -\> `Grid` (Backup). GENSET is inactive.
      * **Off-Grid:** `PV` -\> `BESS` -\> `GENSET` (Backup).
  * **Interactive Plot:** The LCOE chart is clickable, displaying a text box with 8 key KPIs (PV, BESS, GENSET, LCOE, LCOS, CAPEX, OPEX, Autonomy).
  * **Report Generation:** Exports 8 output files (`.txt` optimal solution dossiers, `.txt` summaries, and `.csv` raw data).

##  How to Use

### 1\. Prerequisites

  * GNU Octave (v10.2.0 or similar).
  * `statistics` package (loaded via `pkg load statistics`).

### 2\. Configuration

1.  Open the `microgrid_optimizer.m` script.
2.  Modify **only Section 1 (Control Panel)** with your project data.

### 3\. Execution

  * Press **F5** or run the script in Octave.

##  Outputs

### Reports (.txt / .csv)

  * **`dossie_projeto_...txt`**: Complete report of the **Optimal Solution** (lowest LCOE).
  * **`relatorio_sumario_...txt`**: "Top 15" solutions summary (identical to console).
  * **`relatorio_completo_...csv`**: Raw data of **all** viable solutions.
  * **`perfil_carga_e_solar.csv`**: The 8760-hour load (kW) and irradiation (W/m²) data.

### Key Graphs

1.  **LCOE vs. Penetration (Interactive):** Main decision-making chart. **Click a point** to view its KPIs.
2.  **Detailed Daily Operation:** The microgrid's dispatch "EKG" during a critical winter week.
3.  **Monthly Energy Balance:** The seasonal strategy for generation and consumption.
