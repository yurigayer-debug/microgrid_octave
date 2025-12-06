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

  * **Painel de Controle (Seção 1):** Centraliza as entradas do usuário (custos, perfis, tarifas, espaço de busca).
  * **Métricas Avançadas:** Calcula LCOE (Custo Nivelado da Energia), LCOS (Custo Nivelado do Armazenamento), LCC, CAPEX e OPEX.
  * **Lógica de Despacho Dupla:**
      * **On-Grid:** `SFV` -\> `SAE` -\> `Rede` (Backup). GMG inativo.
      * **Off-Grid:** `SFV` -\> `SAE` -\> `GMG` (Backup).
  * **Gráfico Interativo:** O plot de LCOE é clicável e exibe uma caixa de texto com 8 KPIs (SFV, SAE, GMG, LCOE, LCOS, CAPEX, OPEX, Autonomia).
  * **Geração de Relatórios:** Exporta arquivos de saída (dossiês `.txt`, sumários `.txt` e dados brutos `.csv`).

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

  * **`dossie_projeto_...txt`**: Relatório da **Solução Ótima** (menor LCOE).
  * **`relatorio_sumario_...txt`**: Sumário de soluções (idêntico ao console).
  * **`relatorio_completo_...csv`**: Dados brutos de **todas** as soluções viáveis.
  * **`perfil_carga_e_solar.csv`**: Dados de 8760 horas de carga (kW) e irradiação (W/m²).

### Gráficos Principais

1.  **LCOE vs. Penetração (Interativo):** Gráfico de decisão. **Clique em um ponto** para ver os KPIs.
2.  **Operação Diária Detalhada:** Despacho de Energia  da microrrede em uma semana de inverno.
3.  **Balanço Mensal de Energia:** Estratégia sazonal de geração e consumo.

-----

### English

Aqui está a tradução técnica para Inglês (EUA), adequada para um arquivo `README.md` (GitHub) ou documentação técnica.

**Nota:** Substituí as siglas em português (SFV, SAE, GMG) pelas correspondentes internacionais padrão (PV, ESS, Genset) para manter o rigor técnico.

***

An Octave script designed for the techno-economic simulation and optimization of hybrid microgrids (PV, Batteries, Generator). The objective is to determine the configuration with the lowest Levelized Cost of Energy (LCOE) for both grid-connected (On-Grid) and islanded (Off-Grid) operation modes.

* **Author:** Yuri Escobar Gayer ([yurigayer@gmail.com](mailto:yurigayer@gmail.com))
* **Advisor:** Prof. Lizandro de Souza Oliveira, Ph.D. ([lizandro.oliveira@ucpel.edu.br](mailto:lizandro.oliveira@ucpel.edu.br))
* **Program:** Master's Program in Electronic and Computer Engineering - [https://pos.ucpel.edu.br/ppgeec/](https://pos.ucpel.edu.br/ppgeec/)

***

## Key Features

* **Control Panel (Section 1):** Centralizes user inputs (costs, profiles, tariffs, search space).
* **Advanced Metrics:** Calculates LCOE (Levelized Cost of Energy), LCOS (Levelized Cost of Storage), LCC, CAPEX, and OPEX.
* **Dual Dispatch Logic:**
    * **On-Grid:** `PV` -> `ESS` -> `Grid` (Backup). Genset inactive.
    * **Off-Grid:** `PV` -> `ESS` -> `Genset` (Backup).
* **Interactive Plot:** The LCOE plot is clickable and displays a text box containing 8 KPIs (PV, ESS, Genset, LCOE, LCOS, CAPEX, OPEX, Autonomy).
* **Report Generation:** Exports output files (`.txt` project dossiers, `.txt` summaries, and `.csv` raw data).

## How to Use

### 1. Prerequisites

* GNU Octave (v10.2.0 or similar).
* `statistics` package (loaded via `pkg load statistics`).

### 2. Configuration

1.  Open the `microgrid_optimizer.m` script.
2.  Modify **only Section 1 (Control Panel)** with your specific project data.

### 3. Execution

* Press **F5** or run the script within Octave.

## Outputs

### Reports (.txt / .csv)

* **`dossie_projeto_...txt`**: **Optimal Solution** Report (lowest LCOE).
* **`relatorio_sumario_...txt`**: Solution summary (identical to console output).
* **`relatorio_completo_...csv`**: Raw data for **all** viable solutions.
* **`perfil_carga_e_solar.csv`**: 8760-hour data for load (kW) and irradiance (W/m²).

### Main Plots

1.  **LCOE vs. Penetration (Interactive):** Decision chart. **Click on a point** to view KPIs.
2.  **Detailed Daily Operation:** Microgrid energy dispatch during a winter week.
3.  **Monthly Energy Balance:** Seasonal generation and consumption strategy.

***
