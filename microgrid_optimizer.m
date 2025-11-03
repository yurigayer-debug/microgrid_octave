% ==================================================================================================
% FERRAMENTA DE OTIMIZAÇÃO DE MICRORREDES HÍBRIDAS (ON-GRID / OFF-GRID)
% ==================================================================================================
%  Um script em Octave para a simulação e otimização tecno-econômica de microrredes híbridas
%  (PV, Baterias, Gerador). O objetivo é encontrar a configuração de menor 
%  Custo Nivelado da Energia (LCOE) para operações conectadas à rede (On-Grid) e isoladas (Off-Grid).
%
%  Autor: Eng. Yuri Escobar Gayer (yurigayer@gmail.com)
%  Orientador: Prof. Dr. Lizandro de Souza Oliveira (lizandro.oliveira@ucpel.edu.br)
%  Programa: Mestrado em Engenharia Eletrônica e Computação - https://pos.ucpel.edu.br/ppgeec/
%
% ==================================================================================================
% SEÇÃO 0: INICIALIZAÇÃO DO AMBIENTE
% ==================================================================================================
clear all;
close all;
clc;
format short g; % Define o formato de exibição dos números.
pkg load statistics; % Carrega o pacote de estatísticas.

% ==================================================================================================
% SEÇÃO 1: PAINEL DE CONTROLE (ENTRADAS DO USUÁRIO)
% ==================================================================================================
% Nesta seção estão centralizadas TODAS as variáveis que o usuário deve modificar
% para rodar diferentes cenários de simulação.

% --- 1.1: Parâmetros da Carga ---
consumo_medio_mensal_kwh = 2500; % [kWh/mês] Defina aqui o consumo médio mensal da carga.

% Escolha o perfil de carga (descomente UMA linha):
perfil_diario_tipico = [0.35; 0.30; 0.28; 0.25; 0.28; 0.45; 0.65; 0.70; 0.60; 0.55; 0.50; 0.55; 0.58; 0.55; 0.50; 0.55; 0.65; 0.85; 1.00; 0.95; 0.80; 0.70; 0.55; 0.45]; % ----Perfil Residencial base EPE
%perfil_diario_tipico = [0.20; 0.18; 0.15; 0.15; 0.18; 0.25; 0.40; 0.70; 0.90; 0.95; 0.98; 0.95; 0.98; 1.00; 1.00; 0.98; 0.90; 0.80; 0.60; 0.40; 0.30; 0.25; 0.22; 0.20];  %------- Perfil Comercial base EPE
%perfil_diario_tipico = [0.30; 0.28; 0.28; 0.25; 0.28; 0.40; 0.70; 0.95; 1.00; 1.00; 1.00; 0.98; 0.95; 0.98; 1.00; 1.00; 1.00; 1.00; 0.98; 0.98; 0.95; 0.90; 0.60; 0.40];  % -----------Perfil Industrial base EPE

% --- 1.2: Parâmetros do Recurso Solar (GHI) ---
% Média mensal de irradiação (GHI) para a localidade [kWh/m²/dia] (Jan a Dez)
media_ghi_mensal_kwh_m2_dia = [5.5, 5.1, 4.3, 3.3, 2.5, 2.1, 2.3, 2.9, 3.6, 4.5, 5.2, 5.6]; % Pelotas/RS

% --- 1.3: Espaço de Busca (Tamanhos a Simular) ---
% Defina os vetores de tamanhos (kW e kWh) que o otimizador deve testar.
vetor_tamanho_pv_kw = [11.2,15,20,25,30];
vetor_tamanho_bateria_kwh = [5,10,15,20];
vetor_tamanho_gerador_kw = [10,15,20]; % (Use 0 para simular sem gerador)

% --- 1.4: Parâmetros Financeiros e de Rede ---
vida_util_projeto = 25; % [anos]
taxa_desconto = 0.08;   % [fração] (Ex: 8% = 0.08)
tarifa_compra_energia = 0.05; % [R$/kWh] (Preço que você PAGA para a rede)
tarifa_venda_energia = 0.04;  % [R$/kWh] (Preço que você RECEBE da rede)

% --- 1.5: Custos e Parâmetros dos Componentes ---
% Sistema Fotovoltaico (SFV)
custo_pv_por_kw = 3500;       % [R$/kWp] Custo de capital
custo_om_pv_anual = 500;        % [R$/kWp/ano] Custo de O&M
fator_derating_pv = 0.85;     % [fração] Perdas totais (inversor, cabos, sujeira)
vida_util_pv = 25;            % [anos]

% Sistema de Armazenamento (SAE - Bateria)
custo_bateria_por_kwh = 1200;     % [R$/kWh] Custo de capital
custo_om_bateria_anual = 50;      % [R$/kWh/ano] Custo de O&M
vida_util_bateria_ciclos = 6000;  % [ciclos] Vida útil (throughput)
profundidade_max_descarga = 0.80; % [fração] DoD (Ex: 80% = 0.80)
eficiencia_bateria = 0.90;      % [fração] Eficiência de ida e volta (round-trip)

% Grupo Motor Gerador (GMG - Diesel)
custo_gerador_por_kw = 1700;    % [R$/kW] Custo de capital
custo_om_gerador_horario = 2;   % [R$/hora de uso] Custo de O&M horário
vida_util_gerador_horas = 30000;% [horas] Vida útil
custo_combustivel = 6.5;        % [R$/Litro] Custo do Diesel
consumo_curva_A = 0.240;      % [L/kWh] Coeficiente linear da curva de consumo
consumo_curva_B = 0.010;      % [L/kW] Coeficiente angular da curva de consumo

% --- 1.6: Filtros de Relatório e Confiabilidade ---
% Filtros para limpar os relatórios (Seção 7)
autonomia_minima_desejada = 2;    % [horas]
autonomia_maxima_desejada = 500;  % [horas]
penetracao_minima_desejada = 20;  % [%]
penetracao_maxima_desejada = 500; % [%]

% Confiabilidade (Seção 6)
limite_confiabilidade = 0.99; % [fração] Meta de atendimento (Ex: 99% = 0.99)

% ==================================================================================================
% SEÇÃO 2: GERAÇÃO E ANÁLISE DOS DADOS DE ENTRADA
% ==================================================================================================
horas_no_ano = 8760;
vetor_tempo = (1:horas_no_ano)';
disp('Gerando perfil de carga realista...');

disp('Escalonando perfil de carga pelo CONSUMO MÉDIO MENSAL...');
consumo_total_anual_desejado_kwh = consumo_medio_mensal_kwh * 12;
perfil_base_anual_unitario = repmat(perfil_diario_tipico, 365, 1);
perfil_base_anual_unitario = [perfil_base_anual_unitario; perfil_base_anual_unitario(1:(horas_no_ano - 365*24))];
perfil_base_anual_unitario = perfil_base_anual_unitario(1:horas_no_ano);
soma_energia_perfil_unitario = sum(perfil_base_anual_unitario);
fator_escala_energia = consumo_total_anual_desejado_kwh / soma_energia_perfil_unitario;
carga_horaria_base_anual = perfil_base_anual_unitario * fator_escala_energia;

fator_sazonal = 1.1 + 0.15*cos(2*pi*vetor_tempo/horas_no_ano);
fator_aleatorio = 1 + 0.1*(rand(horas_no_ano, 1) - 0.5);
carga_horaria_kW = carga_horaria_base_anual .* fator_sazonal .* fator_aleatorio;

consumo_total_anual_calc = sum(carga_horaria_kW);
consumo_medio_mensal_calc = consumo_total_anual_calc / 12;
demanda_maxima_kw_calc = max(carga_horaria_kW);
demanda_media_kw_calc = mean(carga_horaria_kW);
fator_de_carga_calc = demanda_media_kw_calc / demanda_maxima_kw_calc;

disp('Gerando perfil de irradiação solar realista...');
dias_no_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
vetor_dia_do_ano = floor((vetor_tempo-1)/24) + 1;
irradiacao_horaria_W_m2 = zeros(horas_no_ano, 1);
dia_atual = 0;
for mes = 1:12
    ghi_diario_mes = media_ghi_mensal_kwh_m2_dia(mes);
    pico_irradiacao_W_m2 = (ghi_diario_mes * pi / 24) * 1000;
    for dia = 1:dias_no_mes(mes)
        dia_atual = dia_atual + 1;
        if dia_atual > 365, continue; end
        horas_do_dia = find(vetor_dia_do_ano == dia_atual);
        for hora_indice = 1:24
            hora_atual = horas_do_dia(hora_indice);
            hora_do_dia = mod(hora_indice - 1, 24);
            if (hora_do_dia >= 6 && hora_do_dia < 18), irradiacao_horaria_W_m2(hora_atual) = pico_irradiacao_W_m2 * sin(pi * (hora_do_dia - 6) / 12);
            else, irradiacao_horaria_W_m2(hora_atual) = 0; end
        end
    end
end
irradiacao_horaria_W_m2(irradiacao_horaria_W_m2 < 0) = 0;
disp('SEÇÃO 3: Parâmetros e dados carregados e analisados.');
disp(' ');

% ==================================================================================================
% SEÇÃO 3: DEFINIÇÃO DO ESPAÇO DE BUSCA
% ==================================================================================================
[P, B, G] = ndgrid(vetor_tamanho_pv_kw, vetor_tamanho_bateria_kwh, vetor_tamanho_gerador_kw);
combinacoes = [P(:), B(:), G(:)];
num_combinacoes = size(combinacoes, 1);
disp(['SEÇÃO 4: Espaço de busca definido. Serão simuladas ' num2str(num_combinacoes) ' configurações em 2 modos de operação.']);
disp(' ');

% ==================================================================================================
% SEÇÃO 4: LOOP PRINCIPAL DE SIMULAÇÃO E ANÁLISE
% ==================================================================================================
% Definir cabeçalho de resultados aqui para ser usado no callback do plot (Seção 8)
header_completo = {'PV_kWp','Bateria_kWh','Gerador_kW','LCOE_R$/kWh','Penetr.Renov_%','Autonomia_h','CAPEX_R$','OPEX_Anual_R$','LCC_R$','Combustivel_Anual_L','Horas_Gerador_h','Curtailment_kWh','Carga_Nao_Atendida_kWh','Energia_Importada_kWh','Energia_Exportada_kWh', 'Autoconsumo_%', 'LCOS_R$/kWh'};

resultados_grid = []; resultados_offgrid = [];
custo_marginal_gerador = consumo_curva_A * custo_combustivel;
for modo_operacao = 1:2
    if modo_operacao == 1, conectado_a_rede = true; disp('SEÇÃO 5: Iniciando simulação para MODO CONECTADO À REDE...');
    else, conectado_a_rede = false; disp('SEÇÃO 5: Iniciando simulação para MODO ILHADO (OFF-GRID)...'); end

    resultados_modo_atual = zeros(num_combinacoes, 17); % Coluna 17 para LCOS

    tic;
    for i = 1:num_combinacoes
        fprintf('... Progresso: %d/%d (%.0f%%)\r', i, num_combinacoes, 100*i/num_combinacoes);
        pv_kw = combinacoes(i, 1); bateria_kwh = combinacoes(i, 2); gerador_kw = combinacoes(i, 3);
        energia_pv_gerada_kwh=zeros(horas_no_ano,1); energia_bateria_descarga_kwh=zeros(horas_no_ano,1);
        energia_bateria_carga_kwh=zeros(horas_no_ano,1); energia_gerador_kwh=zeros(horas_no_ano,1);
        energia_nao_atendida_kwh=zeros(horas_no_ano,1); energia_curtailment_pv_kwh=zeros(horas_no_ano,1);
        combustivel_consumido_litros=zeros(horas_no_ano,1); horas_operacao_gerador=0;
        soc_bateria=ones(horas_no_ano+1,1); energia_importada_grid_kwh=zeros(horas_no_ano,1);
        energia_exportada_grid_kwh=zeros(horas_no_ano,1);

        for h = 1:horas_no_ano
            soc_bateria(h) = soc_bateria(h);
            energia_pv_gerada_kwh(h) = (irradiacao_horaria_W_m2(h) / 1000) * pv_kw * fator_derating_pv;
            balanco_kwh = energia_pv_gerada_kwh(h) - carga_horaria_kW(h);
            if conectado_a_rede
                if balanco_kwh >= 0, energia_para_carga_max = (1 - soc_bateria(h)) * bateria_kwh / eficiencia_bateria; energia_bateria_carga_kwh(h) = min(balanco_kwh, energia_para_carga_max); energia_exportada_grid_kwh(h) = balanco_kwh - energia_bateria_carga_kwh(h);
                else,
                    deficit_kwh = -balanco_kwh;
                    energia_disponivel_bateria = max(0, (soc_bateria(h) - (1-profundidade_max_descarga)) * bateria_kwh * eficiencia_bateria);
                    energia_bateria_descarga_kwh(h) = min(deficit_kwh, energia_disponivel_bateria);
                    deficit_restante_kwh = deficit_kwh - energia_bateria_descarga_kwh(h);

                    % (On-Grid SEMPRE importa da rede)
                    if deficit_restante_kwh > 0.01
                        energia_importada_grid_kwh(h) = deficit_restante_kwh;
                    end
                end
            else % Modo Off-Grid
                if balanco_kwh >= 0, energia_para_carga_max = (1 - soc_bateria(h)) * bateria_kwh / eficiencia_bateria; energia_bateria_carga_kwh(h) = min(balanco_kwh, energia_para_carga_max); energia_curtailment_pv_kwh(h) = balanco_kwh - energia_bateria_carga_kwh(h);
                else, deficit_kwh = -balanco_kwh; energia_disponivel_bateria = max(0, (soc_bateria(h) - (1-profundidade_max_descarga)) * bateria_kwh * eficiencia_bateria); energia_bateria_descarga_kwh(h) = min(deficit_kwh, energia_disponivel_bateria); deficit_restante_kwh = deficit_kwh - energia_bateria_descarga_kwh(h); if deficit_restante_kwh > 0.01 && gerador_kw > 0, energia_gerador_kwh(h) = min(deficit_restante_kwh, gerador_kw); energia_nao_atendida_kwh(h) = deficit_restante_kwh - energia_gerador_kwh(h); horas_operacao_gerador++; combustivel_consumido_litros(h) = consumo_curva_A * energia_gerador_kwh(h) + consumo_curva_B * gerador_kw; else, energia_nao_atendida_kwh(h) = deficit_restante_kwh; end, end
            end
            if bateria_kwh > 0, soc_bateria(h+1) = soc_bateria(h) + (energia_bateria_carga_kwh(h) * eficiencia_bateria / bateria_kwh) - (energia_bateria_descarga_kwh(h) / eficiencia_bateria / bateria_kwh); else, soc_bateria(h+1) = soc_bateria(h); end
        end

        % --- Bloco de Cálculo de Custo Detalhado  ---
        custo_capital_pv = (custo_pv_por_kw * pv_kw);
        custo_capital_bateria = (custo_bateria_por_kwh * bateria_kwh);
        custo_capital_gerador = (custo_gerador_por_kw * gerador_kw);
        custo_capital_total = custo_capital_pv + custo_capital_bateria + custo_capital_gerador;
        custo_om_anual_pv = (custo_om_pv_anual * pv_kw);
        custo_om_anual_bateria = (custo_om_bateria_anual * bateria_kwh);
        custo_om_anual_gerador = (custo_om_gerador_horario * horas_operacao_gerador);
        custo_anual_combustivel = sum(combustivel_consumido_litros) * custo_combustivel;
        custo_om_anual = custo_om_anual_pv + custo_om_anual_bateria + custo_om_anual_gerador;
        if conectado_a_rede
            custo_compra_grid_anual = sum(energia_importada_grid_kwh) * tarifa_compra_energia;
            receita_venda_grid_anual = sum(energia_exportada_grid_kwh) * tarifa_venda_energia;
            custo_operacional_anual_total = custo_om_anual + custo_anual_combustivel + custo_compra_grid_anual - receita_venda_grid_anual;
        else
            custo_operacional_anual_total = custo_om_anual + custo_anual_combustivel;
        end
        ciclos_anuais = sum(energia_bateria_descarga_kwh) / max(1, bateria_kwh);
        vida_util_bateria_anos = vida_util_bateria_ciclos / max(1, ciclos_anuais);
        num_substituicoes_bateria = floor(vida_util_projeto / max(1, vida_util_bateria_anos));
        vida_util_gerador_anos = vida_util_gerador_horas / max(1, horas_operacao_gerador);
        num_substituicoes_gerador = floor(vida_util_projeto / max(1, vida_util_gerador_anos));
        custo_subst_presente_bateria = 0;
        custo_subst_presente_gerador = 0;
        if vida_util_bateria_anos > 0, for s = 1:num_substituicoes_bateria, custo_subst_presente_bateria += (custo_bateria_por_kwh*bateria_kwh) / ((1 + taxa_desconto)^(s * vida_util_bateria_anos)); end, end
        if vida_util_gerador_anos > 0, for s = 1:num_substituicoes_gerador, custo_subst_presente_gerador += (custo_gerador_por_kw*gerador_kw) / ((1 + taxa_desconto)^(s * vida_util_gerador_anos)); end, end
        custo_substituicao_presente_total = custo_subst_presente_bateria + custo_subst_presente_gerador;
        fator_vp_anuidade = ((1+taxa_desconto)^vida_util_projeto - 1) / (taxa_desconto * (1+taxa_desconto)^vida_util_projeto);
        custo_operacional_presente = custo_operacional_anual_total * fator_vp_anuidade;
        custo_ciclo_vida_total = custo_capital_total + custo_substituicao_presente_total + custo_operacional_presente;
        energia_total_entregue_anual = sum(carga_horaria_kW) - sum(energia_nao_atendida_kwh);
        custo_anualizado_total = custo_ciclo_vida_total / fator_vp_anuidade;
        if energia_total_entregue_anual > 0, lcoe = custo_anualizado_total / energia_total_entregue_anual; else, lcoe = inf; end
        custo_op_presente_bateria = custo_om_anual_bateria * fator_vp_anuidade;
        lcc_bateria_pv = custo_capital_bateria + custo_op_presente_bateria + custo_subst_presente_bateria;
        custo_anualizado_bateria = lcc_bateria_pv / fator_vp_anuidade;
        energia_anual_descarga_kwh = sum(energia_bateria_descarga_kwh);
        if energia_anual_descarga_kwh > 0, lcos = custo_anualizado_bateria / energia_anual_descarga_kwh; else, lcos = inf; end
        % --- Fim do Bloco de Custo ---

        energia_renovavel_total = sum(energia_pv_gerada_kwh) - sum(energia_curtailment_pv_kwh);
        penetracao_renovavel = (energia_renovavel_total / max(1, sum(carga_horaria_kW))) * 100;
        autonomia_horas = bateria_kwh * profundidade_max_descarga / max(0.001, mean(carga_horaria_kW));
        autoconsumo_perc = (consumo_total_anual_calc - sum(energia_importada_grid_kwh)) / max(1, consumo_total_anual_calc) * 100;

        resultados_modo_atual(i, :) = [pv_kw, bateria_kwh, gerador_kw, lcoe, penetracao_renovavel, autonomia_horas, custo_capital_total, custo_operacional_anual_total, custo_ciclo_vida_total, sum(combustivel_consumido_litros), horas_operacao_gerador, sum(energia_curtailment_pv_kwh), sum(energia_nao_atendida_kwh), sum(energia_importada_grid_kwh), sum(energia_exportada_grid_kwh), autoconsumo_perc, lcos];
    end
    fprintf('\n');
    tempo_total_simulacao = toc;
    disp(['... Simulação concluída em ' num2str(tempo_total_simulacao) ' segundos.']); disp(' ');
    if conectado_a_rede, resultados_grid = resultados_modo_atual; else, resultados_offgrid = resultados_modo_atual; end
end

% ==================================================================================================
% SEÇÃO 5: ANÁLISE DE CONFIGURAÇÃO MÍNIMA OFF-GRID
% ==================================================================================================
disp('SEÇÃO 6: Analisando a configuração mínima para operação Off-Grid...');
disp(' ');
max_energia_nao_atendida = (1 - limite_confiabilidade) * consumo_total_anual_calc;
indice_confiaveis = resultados_offgrid(:, 13) <= max_energia_nao_atendida;
resultados_confiaveis = resultados_offgrid(indice_confiaveis, :);
disp('------------------------------------------------------------------------------------------');
disp('                          RELATÓRIO DE CONFIGURAÇÃO MÍNIMA VIÁVEL (OFF-GRID)');
disp('------------------------------------------------------------------------------------------');
if isempty(resultados_confiaveis)
    disp('NENHUMA configuração no espaço de busca atingiu a meta de fiabilidade.');
else
    [~, idx_ordenado_capex] = sort(resultados_confiaveis(:, 7));
    configuracao_minima = resultados_confiaveis(idx_ordenado_capex(1), :);
    disp(['Analisando a configuração de menor CAPEX que atende a carga com >= ' num2str(limite_confiabilidade*100) '% de confiabilidade.']);
    disp(' ');
    fprintf('  >> Configuração Mínima Encontrada: %.1f kWp SFV | %.1f kWh SAE | %.1f kW GMG\n', configuracao_minima(1), configuracao_minima(2), configuracao_minima(3));
    fprintf('     - Custo de Capital (CAPEX): R$ %.0f\n', configuracao_minima(7));
    fprintf('     - Custo da Energia (LCOE):  R$ %.4f / kWh\n', configuracao_minima(4));
    fprintf('     - Energia Nao Atendida:     %.2f kWh/ano\n', configuracao_minima(13));
end
disp('------------------------------------------------------------------------------------------');
disp(' ');

% ==================================================================================================
% SEÇÃO 6: PÓS-PROCESSAMENTO E APRESENTAÇÃO DOS RESULTADOS NO CONSOLE
% ==================================================================================================
disp('SEÇÃO 7: Processando e apresentando relatórios comparativos no console...');
disp(' ');

% --- Processamento e Exibição MODO ON-GRID ---
resultados_atuais = resultados_grid;
resultados_atuais(isinf(resultados_atuais(:,4)) | isnan(resultados_atuais(:,4)),:) = [];
indice_validos = resultados_atuais(:, 6) >= autonomia_minima_desejada & resultados_atuais(:, 6) <= autonomia_maxima_desejada & resultados_atuais(:, 5) >= penetracao_minima_desejada & resultados_atuais(:, 5) <= penetracao_maxima_desejada;
resultados_finais_on_grid = resultados_atuais(indice_validos, :);
[~, idx_ordenado] = sort(resultados_finais_on_grid(:, 4));
resultados_finais_on_grid = resultados_finais_on_grid(idx_ordenado, :);

% ---  Salvar Relatório Sumário On-Grid em TXT ---
try
    disp('- Salvando relatório sumário On-Grid em TXT...');
    fileID = fopen('relatorio_sumario_on_grid.txt', 'w');
    fprintf(fileID, '===================================================================================================================================================\n');
    fprintf(fileID, '                                        RELATÓRIO DE OTIMIZAÇÃO - MODO CONECTADO À REDE (ON-GRID)\n');
    fprintf(fileID, '===================================================================================================================================================\n');
    header_str = sprintf('%-8s|%-10s|%-14s|%-13s|%-14s|%-16s|%-20s|%-20s', 'PV(kWp)', 'Bat(kWh)', 'LCOE(R$/kWh)', 'LCOS(R$/kWh)', 'OPEX Anual(R$)', 'Autoconsumo(%)', 'Energia Import.(kWh)', 'Energia Export.(kWh)');
    fprintf(fileID, '%s\n', header_str);
    fprintf(fileID, '---------------------------------------------------------------------------------------------------------------------------------------------------\n');
    num_resultados_a_exibir = min(15, size(resultados_finais_on_grid, 1));
    if num_resultados_a_exibir == 0
        fprintf(fileID, 'NENHUMA CONFIGURAÇÃO ATENDEU AOS CRITÉRIOS DE FILTRAGEM PARA ESTE MODO.\n');
    else
        for k = 1:num_resultados_a_exibir
            linha = resultados_finais_on_grid(k, :);
            linha_str = sprintf('%-8.1f|%-10.0f|%-14.4f|%-13.4f|%-14.0f|%-16.1f|%-20.0f|%-20.0f', linha(1), linha(2), linha(4), linha(17), linha(8), linha(16), linha(14), linha(15));
            fprintf(fileID, '%s\n', linha_str);
        end
    end
    fprintf(fileID, '===================================================================================================================================================\n');
    fclose(fileID);
    disp('- Relatório sumário On-Grid salvo com sucesso.');
catch
    disp('- ERRO ao salvar relatório sumário On-Grid em TXT.');
end

% (Impressão original no console)
disp('===================================================================================================================================================');
disp('                                        RELATÓRIO DE OTIMIZAÇÃO - MODO CONECTADO À REDE (ON-GRID)');
disp('===================================================================================================================================================');
disp(sprintf('%-8s|%-10s|%-14s|%-13s|%-14s|%-16s|%-20s|%-20s', 'PV(kWp)', 'Bat(kWh)', 'LCOE(R$/kWh)', 'LCOS(R$/kWh)', 'OPEX Anual(R$)', 'Autoconsumo(%)', 'Energia Import.(kWh)', 'Energia Export.(kWh)'));
disp('---------------------------------------------------------------------------------------------------------------------------------------------------');
num_resultados_a_exibir = min(15, size(resultados_finais_on_grid, 1));
if num_resultados_a_exibir == 0, disp('NENHUMA CONFIGURAÇÃO ATENDEU AOS CRITÉRIOS DE FILTRAGEM PARA ESTE MODO.');
else
    for k = 1:num_resultados_a_exibir
        linha = resultados_finais_on_grid(k, :);
        disp(sprintf('%-8.1f|%-10.0f|%-14.4f|%-13.4f|%-14.0f|%-16.1f|%-20.0f|%-20.0f', linha(1), linha(2), linha(4), linha(17), linha(8), linha(16), linha(14), linha(15)));
    end
end
disp('==================================================================================================================================================='); disp(' ');

% --- Processamento e Exibição MODO OFF-GRID ---
resultados_atuais = resultados_offgrid;
resultados_atuais(isinf(resultados_atuais(:,4)) | isnan(resultados_atuais(:,4)),:) = [];
indice_validos = resultados_atuais(:, 6) >= autonomia_minima_desejada & resultados_atuais(:, 6) <= autonomia_maxima_desejada & resultados_atuais(:, 5) >= penetracao_minima_desejada & resultados_atuais(:, 5) <= penetracao_maxima_desejada;
resultados_finais_off_grid = resultados_atuais(indice_validos, :);
[~, idx_ordenado] = sort(resultados_finais_off_grid(:, 4));
resultados_finais_off_grid = resultados_finais_off_grid(idx_ordenado, :);

% ---  Salvar Relatório Sumário Off-Grid em TXT ---
try
    disp('- Salvando relatório sumário Off-Grid em TXT...');
    fileID = fopen('relatorio_sumario_off_grid.txt', 'w');
    fprintf(fileID, '================================================================================================================================================\n');
    fprintf(fileID, '                                        RELATÓRIO DE OTIMIZAÇÃO - MODO ILHADO (OFF-GRID)\n');
    fprintf(fileID, '================================================================================================================================================\n');
    header_str = sprintf('%-8s|%-10s|%-10s|%-14s|%-13s|%-15s|%-18s|%-22s', 'PV(kWp)', 'Bat(kWh)', 'Ger(kW)', 'LCOE(R$/kWh)', 'LCOS(R$/kWh)', 'Autonomia(h)', 'Penetr.Renov(%)', 'Carga Nao Atendida(kWh)');
    fprintf(fileID, '%s\n', header_str);
    fprintf(fileID, '------------------------------------------------------------------------------------------------------------------------------------------------\n');
    num_resultados_a_exibir = min(15, size(resultados_finais_off_grid, 1));
    if num_resultados_a_exibir == 0
        fprintf(fileID, 'NENHUMA CONFIGURAÇÃO ATENDEU AOS CRITÉRIOS DE FILTRAGEM PARA ESTE MODO.\n');
    else
        for k = 1:num_resultados_a_exibir
            linha = resultados_finais_off_grid(k, :);
            linha_str = sprintf('%-8.1f|%-10.0f|%-10.0f|%-14.4f|%-13.4f|%-15.1f|%-18.1f|%-22.2f', linha(1), linha(2), linha(3), linha(4), linha(17), linha(6), linha(5), linha(13));
            fprintf(fileID, '%s\n', linha_str);
        end
    end
    fprintf(fileID, '================================================================================================================================================\n');
    fclose(fileID);
    disp('- Relatório sumário Off-Grid salvo com sucesso.');
catch
    disp('- ERRO ao salvar relatório sumário Off-Grid em TXT.');
end

% (Impressão original no console)
disp('================================================================================================================================================');
disp('                                        RELATÓRIO DE OTIMIZAÇÃO - MODO ILHADO (OFF-GRID)');
disp('================================================================================================================================================');
disp(sprintf('%-8s|%-10s|%-10s|%-14s|%-13s|%-15s|%-18s|%-22s', 'PV(kWp)', 'Bat(kWh)', 'Ger(kW)', 'LCOE(R$/kWh)', 'LCOS(R$/kWh)', 'Autonomia(h)', 'Penetr.Renov(%)', 'Carga Nao Atendida(kWh)'));
disp('------------------------------------------------------------------------------------------------------------------------------------------------');
num_resultados_a_exibir = min(15, size(resultados_finais_off_grid, 1));
if num_resultados_a_exibir == 0, disp('NENHUMA CONFIGURAÇÃO ATENDEU AOS CRITÉRIOS DE FILTRAGEM PARA ESTE MODO.');
else
    for k = 1:num_resultados_a_exibir
        linha = resultados_finais_off_grid(k, :);
        disp(sprintf('%-8.1f|%-10.0f|%-10.0f|%-14.4f|%-13.4f|%-15.1f|%-18.1f|%-22.2f', linha(1), linha(2), linha(3), linha(4), linha(17), linha(6), linha(5), linha(13)));
    end
end
disp('================================================================================================================================================'); disp(' ');

% ==================================================================================================
% SEÇÃO 7: GERAÇÃO DE GRÁFICOS DE ANÁLISE ANUAL
% ==================================================================================================
disp('SEÇÃO 8: Gerando gráficos de análise...');

% --- GRÁFICOS DE CARACTERIZAÇÃO DA CARGA ---
figure('Name', 'Dados de Entrada Anuais (Carga e Recurso Solar)');
[ax, h1, h2] = plotyy(vetor_tempo, carga_horaria_kW, vetor_tempo, irradiacao_horaria_W_m2);
set(h1, 'Color', 'b', 'LineStyle', '-'); set(h2, 'Color', 'r', 'LineStyle', '-');
ylabel(ax(1), 'Consumo da Carga (kW)'); ylim(ax(1), [0, max(carga_horaria_kW)*1.2]);
ylabel(ax(2), 'Irradiacao Solar (W/m^2)'); ylim(ax(2), [0, max(irradiacao_horaria_W_m2)*1.2]);
grid on; title('Perfil Anual de Carga e Irradiacao Solar (8760 horas)');
xlabel('Hora do Ano'); legend([h1, h2], {'Carga', 'Irradiacao'}, 'Location', 'best');

figure('Name', 'Perfil Diario Tipico de Carga');
carga_diaria_matrix = reshape(carga_horaria_kW, 24, floor(horas_no_ano/24));
perfil_diario_medio = mean(carga_diaria_matrix, 2);
plot(0:23, perfil_diario_medio, 'b-', 'LineWidth', 2);
grid on; title('Perfil Diario Medio de Consumo'); xlabel('Hora do Dia');
ylabel('Consumo Medio (kW)'); xticks(0:2:23);

figure('Name', 'Consumo Mensal de Energia');
consumo_mensal_kwh = zeros(12, 1); hora_inicial = 1;
for mes = 1:12
    hora_final = hora_inicial + dias_no_mes(mes) * 24 - 1; if hora_final > horas_no_ano, hora_final = horas_no_ano; end
    consumo_mensal_kwh(mes) = sum(carga_horaria_kW(hora_inicial:hora_final));
    hora_inicial = hora_final + 1;
end
bar(consumo_mensal_kwh);
grid on; title('Consumo Total de Energia por Mes'); xlabel('Mes'); ylabel('Consumo Mensal Total (kWh)');
set(gca, 'XTickLabel', {'Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'});

% --- GRÁFICOS DE ANÁLISE DE OTIMIZAÇÃO E BALANÇO ENERGÉTICO ---
for m = 1:2
    if m == 1, resultados_atuais = resultados_finais_on_grid; modo_str = 'On-Grid';
    else, resultados_atuais = resultados_finais_off_grid; modo_str = 'Off-Grid'; end
    if isempty(resultados_atuais), disp(['Nenhum dado viável para plotar para o modo ' modo_str]); continue; end

    solucao_otima_plot = resultados_atuais(1,:);

    % ---  Gráfico LCOE Interativo ---
    figure('Name', ['LCOE vs Penetr. Renovavel (' modo_str ')']);
    h_ax_lcoe = gca; % Pega o eixo atual
    h_pontos = plot(h_ax_lcoe, resultados_atuais(:,4), resultados_atuais(:,5), 'o', 'MarkerSize', 6, 'DisplayName', 'Soluções Viáveis');
    hold on;
    plot(h_ax_lcoe, solucao_otima_plot(4), solucao_otima_plot(5), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Solução Ótima');

    % Define a função de callback
    set(h_pontos, 'ButtonDownFcn', {@exibir_dados_ponto_customizado, resultados_atuais});

    grid on; title(['LCOE vs. Penetração Renovável (' modo_str ') - CLIQUE EM UM PONTO']);
    xlabel('LCOE (R$/kWh)'); ylabel('Penetração Renovável (%)'); legend show; hold off;


    pv_kw_otimo = solucao_otima_plot(1); bateria_kwh_otimo = solucao_otima_plot(2); gerador_kw_otimo = solucao_otima_plot(3);
    energia_pv_otimo=zeros(horas_no_ano,1); energia_bateria_descarga_otimo=zeros(horas_no_ano,1);
    energia_bateria_carga_otimo=zeros(horas_no_ano,1); energia_gerador_otimo=zeros(horas_no_ano,1);
    energia_importada_otimo=zeros(horas_no_ano,1); soc_bateria_otimo=ones(horas_no_ano+1,1);
    energia_exportada_otimo=zeros(horas_no_ano,1); energia_curtailment_otimo=zeros(horas_no_ano,1);

    for h = 1:horas_no_ano
        soc_bateria_otimo(h) = soc_bateria_otimo(h);
        energia_pv_otimo(h) = (irradiacao_horaria_W_m2(h) / 1000) * pv_kw_otimo * fator_derating_pv;
        balanco_kwh = energia_pv_otimo(h) - carga_horaria_kW(h);
        if m == 1 % On-Grid
            if balanco_kwh >= 0
                energia_para_carga_max = (1 - soc_bateria_otimo(h)) * bateria_kwh_otimo / eficiencia_bateria;
                energia_bateria_carga_otimo(h) = min(balanco_kwh, energia_para_carga_max);
                energia_exportada_otimo(h) = balanco_kwh - energia_bateria_carga_otimo(h);
            else
                deficit_kwh = -balanco_kwh;
                energia_disponivel_bateria = max(0, (soc_bateria_otimo(h) - (1-profundidade_max_descarga)) * bateria_kwh_otimo * eficiencia_bateria);
                energia_bateria_descarga_otimo(h) = min(deficit_kwh, energia_disponivel_bateria);
                deficit_restante_kwh = deficit_kwh - energia_bateria_descarga_otimo(h);

                %  Sempre importa da rede
                if deficit_restante_kwh > 0.01
                    energia_importada_otimo(h) = deficit_restante_kwh;
                end


            end
        else % Off-Grid
            if balanco_kwh >= 0
                energia_para_carga_max = (1 - soc_bateria_otimo(h)) * bateria_kwh_otimo / eficiencia_bateria;
                energia_bateria_carga_otimo(h) = min(balanco_kwh, energia_para_carga_max);
                energia_curtailment_otimo(h) = balanco_kwh - energia_bateria_carga_otimo(h);
            else
                deficit_kwh = -balanco_kwh;
                energia_disponivel_bateria = max(0, (soc_bateria_otimo(h) - (1-profundidade_max_descarga)) * bateria_kwh_otimo * eficiencia_bateria);
                energia_bateria_descarga_otimo(h) = min(deficit_kwh, energia_disponivel_bateria);
                deficit_restante_kwh = deficit_kwh - energia_bateria_descarga_otimo(h);
                if deficit_restante_kwh > 0.01 && gerador_kw_otimo > 0
                    energia_gerador_otimo(h) = min(deficit_restante_kwh, gerador_kw_otimo);
                end
            end
        end
        if bateria_kwh_otimo > 0, soc_bateria_otimo(h+1) = soc_bateria_otimo(h) + (energia_bateria_carga_otimo(h) * eficiencia_bateria / bateria_kwh_otimo) - (energia_bateria_descarga_otimo(h) / eficiencia_bateria / bateria_kwh_otimo); else, soc_bateria_otimo(h+1) = soc_bateria_otimo(h); end
    end

    % ---  Gráfico de Balanço Energético (com excedente) ---
    figure('Name', ['Balanco Mensal de Energia (' modo_str ')']);
    consumo_mensal = zeros(12,1); geracao_solar_mensal = zeros(12,1); descarga_bateria_mensal = zeros(12,1); geracao_gerador_mensal = zeros(12,1); energia_importada_mensal = zeros(12,1); energia_excedente_mensal = zeros(12,1); legenda_excedente = 'Exportado (Rede)';

    hora_inicial = 1;
    for mes = 1:12, hora_final = hora_inicial + dias_no_mes(mes) * 24 - 1; if hora_final > horas_no_ano, hora_final = horas_no_ano; end
    consumo_mensal(mes) = sum(carga_horaria_kW(hora_inicial:hora_final));
    geracao_solar_mensal(mes) = sum(energia_pv_otimo(hora_inicial:hora_final));
    descarga_bateria_mensal(mes) = sum(energia_bateria_descarga_otimo(hora_inicial:hora_final));
    geracao_gerador_mensal(mes) = sum(energia_gerador_otimo(hora_inicial:hora_final));
    energia_importada_mensal(mes) = sum(energia_importada_otimo(hora_inicial:hora_final));
    if m == 1 % On-Grid
        energia_excedente_mensal(mes) = sum(energia_exportada_otimo(hora_inicial:hora_final));
        legenda_excedente = 'Exportado (Rede)';
    else % Off-Grid
        energia_excedente_mensal(mes) = sum(energia_curtailment_otimo(hora_inicial:hora_final));
        legenda_excedente = 'Curtailment (Perda)';
    end

    hora_inicial = hora_final + 1; end
    bar([consumo_mensal, geracao_solar_mensal, descarga_bateria_mensal, geracao_gerador_mensal, energia_importada_mensal, energia_excedente_mensal]);
    grid on; title(['Balanço Mensal de Energia (' modo_str ')']); xlabel('Mês'); ylabel('Energia (kWh)');
    set(gca, 'XTickLabel', {'Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'});
    legend({'Consumo', 'Geração Solar', 'Descarga Bateria', 'Geração Gerador', 'Importado da Rede', legenda_excedente}, 'Location', 'northwest');


    % ---  Gráfico de Operação Diária  ---
    figure('Name', ['Operacao Diaria (Semana Exemplo) (' modo_str ')']);
    dia_inicio_inverno = 182; % Dia 182 eh 1 de Julho
    horas_plot = (24*(dia_inicio_inverno-1)+1) : (24*(dia_inicio_inverno+3)); % Plota 4 dias de inverno

    [ax, h1_carga_fantasma, h_soc] = plotyy(horas_plot, carga_horaria_kW(horas_plot), horas_plot, soc_bateria_otimo(horas_plot)*100);
    hold(ax(1), 'on');

    h_pv = area(ax(1), horas_plot, energia_pv_otimo(horas_plot), 'FaceColor', [1 0.9 0.4], 'EdgeColor', 'none');
    h_import = area(ax(1), horas_plot, energia_importada_otimo(horas_plot), 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none');
    h_ger = area(ax(1), horas_plot, energia_gerador_otimo(horas_plot), 'FaceColor', [0.9 0.5 0.5], 'EdgeColor', 'none');
    h_bat_desc = bar(ax(1), horas_plot, energia_bateria_descarga_otimo(horas_plot), 'FaceColor', [0.4 0.4 0.8], 'EdgeColor', 'none', 'BarWidth', 1);

    dados_negativos_plot = [-energia_bateria_carga_otimo(horas_plot), -energia_exportada_otimo(horas_plot)];
    h_negativos_stacked = bar(ax(1), horas_plot, dados_negativos_plot, 'stacked', 'BarWidth', 1);

    set(h_negativos_stacked(1), 'FaceColor', [0.4 0.8 0.4]); % Handle [1] = Carga Bateria (Verde)
    set(h_negativos_stacked(2), 'FaceColor', [1 0.6 0.2]); % Handle [2] = Exportado Rede (Laranja)

    h_carga = plot(ax(1), horas_plot, carga_horaria_kW(horas_plot), 'k-', 'LineWidth', 2);

    hold(ax(1), 'off');

    set(h1_carga_fantasma, 'Visible', 'off');
    set(h_soc, 'Color', 'm', 'LineStyle', '--', 'LineWidth', 2);

    ylabel(ax(1), 'Potência (kW)');
    limite_y_negativo = min([-max(carga_horaria_kW(horas_plot))*0.5, min(sum(dados_negativos_plot, 2))*1.1]);
    limite_y_positivo = max([max(carga_horaria_kW(horas_plot))*1.5, max(energia_pv_otimo(horas_plot))*1.1]);
    ylim(ax(1), [limite_y_negativo, limite_y_positivo]);

    ylabel(ax(2), 'Estado de Carga da Bateria (%)');
    ylim(ax(2), [0 100]); % Eixo Y do SoC corrigido

    grid on; title(['Operação Diária Detalhada (' modo_str ')']); xlabel('Hora do Ano');

    % Legenda dinâmica
    if m == 1 % On-Grid: Inclui "Importado Rede" E "Exportado Rede"
        handles_legenda = [h_pv, h_import, h_ger, h_bat_desc, h_negativos_stacked(1), h_negativos_stacked(2), h_carga];
        labels_legenda = {'Geração Solar', 'Importado Rede', 'Geração Gerador', 'Descarga Bateria', 'Carga Bateria', 'Exportado Rede', 'Carga'};
    else % Off-Grid: Omite "Importado Rede" e "Exportado Rede"
        handles_legenda = [h_pv, h_ger, h_bat_desc, h_negativos_stacked(1), h_carga];
        labels_legenda = {'Geração Solar', 'Geração Gerador', 'Descarga Bateria', 'Carga Bateria', 'Carga'};
    end

    legend(ax(1), handles_legenda, labels_legenda, 'Location', 'northwest');
end
disp('Gráficos de balanço energético gerados com sucesso.'); disp(' ');


% ==================================================================================================
% SEÇÃO 8: GERAÇÃO DE FICHEIROS DE RELATÓRIO
% ==================================================================================================
disp('SEÇÃO 9: Iniciando exportação de relatórios...');
try, fileID = fopen('perfil_carga_e_solar.csv', 'w'); fprintf(fileID, 'Hora,Carga_kW,Irradiacao_W_m2\n'); fclose(fileID); csvwrite('perfil_carga_e_solar.csv', [vetor_tempo, carga_horaria_kW, irradiacao_horaria_W_m2], '-append'); disp('- Ficheiro de perfil de carga e solar salvo com sucesso.');
catch, disp('- ERRO ao salvar o ficheiro de perfil de carga.'); end

for m = 1:2
    if m == 1, resultados_finais_export = resultados_finais_on_grid; modo_str = 'on_grid';
    else, resultados_finais_export = resultados_finais_off_grid; modo_str = 'off_grid'; end
    if isempty(resultados_finais_export), disp(['Nenhum resultado viável para exportar para o modo ' modo_str]); continue; end
    solucao_otima = resultados_finais_export(1,:);
    nome_csv = ['relatorio_completo_' modo_str '.csv'];
    try
        fileID = fopen(nome_csv, 'w'); fprintf(fileID, '%s\n', strjoin(header_completo, ',')); fclose(fileID);
        csvwrite(nome_csv, resultados_finais_export, '-append');
        disp(['- Relatorio CSV para modo ' modo_str ' salvo com sucesso.']);
    catch, disp(['- ERRO ao salvar relatorio CSV para modo ' modo_str]); end
    nome_txt = ['dossie_projeto_' modo_str '.txt'];
    try
        fileID = fopen(nome_txt, 'w');
        fprintf(fileID, '================================================================\n');
        fprintf(fileID, '                DOSSIE COMPLETO DO PROJETO - MODO %s\n', upper(modo_str));
        fprintf(fileID, '================================================================\n\n');
        fprintf(fileID, '--- PREMISSAS DE ENTRADA DO PROJETO ---\n\n');
        fprintf(fileID, ' PERFIL DE CARGA (SINTETICO):\n');
        fprintf(fileID, '   - Consumo Medio Mensal (Informado): %.0f kWh/mes\n', consumo_medio_mensal_kwh);
        fprintf(fileID, '   - Consumo Total Anual (Calculado): %.0f kWh/ano\n', consumo_total_anual_calc);
        fprintf(fileID, '   - Consumo mensal médio (Calculado): %.0f kWh/ano\n', consumo_total_anual_calc/12);
        fprintf(fileID, '   - Demanda Maxima (Pico Calculado): %.2f kW\n', demanda_maxima_kw_calc);
        fprintf(fileID, '   - Demanda Media (Calculada): %.2f kW\n', demanda_media_kw_calc);
        fprintf(fileID, '   - Fator de Carga (Calculado): %.2f\n\n', fator_de_carga_calc);
        fprintf(fileID, ' CRITERIOS DE OTIMIZACAO (FILTROS):\n');
        fprintf(fileID, '   - Autonomia Desejada: Entre %.1f e %.1f horas\n', autonomia_minima_desejada, autonomia_maxima_desejada);
        fprintf(fileID, '   - Penetracao Renovavel Desejada: Entre %.0f%% e %.0f%%\n\n', penetracao_minima_desejada, penetracao_maxima_desejada);
        fprintf(fileID, ' FINANCEIRO:\n');
        fprintf(fileID, '   - Vida Util do Projeto: %d anos\n', vida_util_projeto);
        fprintf(fileID, '   - Taxa de Desconto: %.1f %%\n\n', taxa_desconto*100);
        if m==1, fprintf(fileID, ' REDE ELETRICA:\n   - Tarifa de Compra: R$ %.2f/kWh\n   - Tarifa de Venda: R$ %.2f/kWh\n\n', tarifa_compra_energia, tarifa_venda_energia); end
        fprintf(fileID, ' COMPONENTES:\n');
        fprintf(fileID, '   - PV: Custo=R$%.0f/kWp, O&M=R$%.0f/kWp/ano, Perdas=%.0f%%, Vida=%danos\n', custo_pv_por_kw, custo_om_pv_anual, (1-fator_derating_pv)*100, vida_util_pv);
        fprintf(fileID, '   - Bateria: Custo=R$%.0f/kWh, O&M=R$%.0f/kWh/ano, DoD=%.0f%%, Efic=%.0f%%, Vida=%dciclos\n', custo_bateria_por_kwh, custo_om_bateria_anual, profundidade_max_descarga*100, eficiencia_bateria*100, vida_util_bateria_ciclos);
        fprintf(fileID, '   - Gerador: Custo=R$%.0f/kW, O&M=R$%.2f/h, Vida=%dhoras, Combustivel=R$%.2f/L\n\n', custo_gerador_por_kw, custo_om_gerador_horario, vida_util_gerador_horas, custo_combustivel);
        fprintf(fileID, '--- RESULTADOS DA SOLUCAO OTIMA ---\n\n');
        fprintf(fileID, ' CONFIGURACAO:\n');
        fprintf(fileID, '   - PV: %.1f kWp | Bateria: %.1f kWh | Gerador: %.1f kW\n\n', solucao_otima(1), solucao_otima(2), solucao_otima(3));
        fprintf(fileID, ' METRICAS TECNICO-ECONOMICAS ANUAIS:\n');
        fprintf(fileID, '   - LCOE: R$ %.4f / kWh\n', solucao_otima(4));
        fprintf(fileID, '   - LCOS (Bateria): R$ %.4f / kWh\n', solucao_otima(17));
        fprintf(fileID, '   - CAPEX: R$ %.0f\n', solucao_otima(7));
        fprintf(fileID, '   - OPEX Anual: R$ %.0f\n', solucao_otima(8));
        fprintf(fileID, '   - Custo Ciclo de Vida (LCC): R$ %.0f\n', solucao_otima(9));
        fprintf(fileID, '   - Penetracao Renovavel: %.1f %%\n', solucao_otima(5));
        fprintf(fileID, '   - Autoconsumo (On-Grid): %.1f %%\n', solucao_otima(16));
        fprintf(fileID, '   - Autonomia (Off-Grid): %.1f horas\n\n', solucao_otima(6));
        fprintf(fileID, ' BALANCO DE ENERGIA ANUAL (kWh):\n');
        fprintf(fileID, '   - Consumo Total da Carga: %.0f\n', consumo_total_anual_calc);
        fprintf(fileID, '   - Energia Importada da Rede: %.0f\n', solucao_otima(14));
        fprintf(fileID, '   - Energia Exportada para a Rede: %.0f\n', solucao_otima(15));
        fprintf(fileID, '   - Energia Desperdicada (Curtailment): %.0f\n', solucao_otima(12));
        fprintf(fileID, '   - Energia Nao Atendida (Corte de Carga): %.2f\n\n', solucao_otima(13));
        fprintf(fileID, ' OPERACAO DO GERADOR (ANUAL):\n');
        fprintf(fileID, '   - Horas de Operacao: %.0f horas\n', solucao_otima(11));
        fprintf(fileID, '   - Consumo de Combustivel: %.0f Litros\n', solucao_otima(10));
        fprintf(fileID, '================================================================\n');
        fclose(fileID);
        disp(['- Dossie do projeto ' modo_str ' salvo com sucesso.']);
    catch, disp(['- ERRO ao salvar dossie do projeto para modo ' modo_str]); end
end
disp(' '); disp('Processo finalizado.');

% --- FIM DO CÓDIGO ---

% ==================================================================================================
% SEÇÃO 9: FUNÇÕES DE CALLBACK (Interação do Mouse)
% ==================================================================================================
% (Função de callback para o gráfico LCOE)
%

function exibir_dados_ponto_customizado(h_obj, event, resultados)
    % Esta função é chamada quando um ponto no gráfico LCOE é clicado
    % exibe uma caixa de texto customizada diretamente no gráfico.

    % 1. Obter o eixo e o local do clique
    h_ax = get(h_obj, 'Parent');
    clique = get(h_ax, 'CurrentPoint');
    clique_x = clique(1,1); % LCOE
    clique_y = clique(1,2); % Penetração

    % 2. Obter todos os dados do gráfico
    lcoes_data = get(h_obj, 'XData');
    penetracao_data = get(h_obj, 'YData');

    % 3. Encontrar o ponto de dados mais próximo do clique
    distancia = sqrt((lcoes_data - clique_x).^2 + (penetracao_data - clique_y).^2);
    [~, idx_ponto_proximo] = min(distancia);

    % 4. Obter a linha de dados completa da matriz de resultados
    linha_dados = resultados(idx_ponto_proximo, :);

    % 5. Mapear colunas para os dados solicitados
    % Colunas: [1]PV_kWp, [2]Bateria_kWh, [3]Gerador_kW, [4]LCOE, [6]Autonomia_h, [17]LCOS, [7]CAPEX, [8]OPEX_Anual
    dados_sfv = linha_dados(1);
    dados_sae = linha_dados(2);
    dados_gmg = linha_dados(3);
    dados_lcoe = linha_dados(4);
    dados_autonomia = linha_dados(6);
    dados_lcos = linha_dados(17);
    dados_capex = linha_dados(7);
    dados_opex = linha_dados(8);

    % 6. Preparar o texto para exibição (Cell Array)
    texto_para_plotar = {
        '--- Solução Selecionada ---',
        sprintf(' SFV (PV): %.1f kWp', dados_sfv),
        sprintf(' SAE (Bat): %.1f kWh', dados_sae),
        sprintf(' GMG (Ger): %.1f kW', dados_gmg),
        ' -------------------------',
        sprintf(' LCOE: R$ %.4f /kWh', dados_lcoe),
        sprintf(' LCOS: R$ %.4f /kWh', dados_lcos),
        sprintf(' CAPEX: R$ %.0f', dados_capex),
        sprintf(' OPEX: R$ %.0f /ano', dados_opex),
        sprintf(' Autonomia: %.1f h', dados_autonomia)
    };

    % 7. Apagar a caixa de texto anterior (se existir)
    delete(findobj(h_ax, 'Tag', 'ponto_info_texto'));

    % 8. Calcular Posição e Criar o novo objeto de texto
    lcoe_ponto = lcoes_data(idx_ponto_proximo);
    pen_ponto = penetracao_data(idx_ponto_proximo);

    offset_x = (max(lcoes_data) - min(lcoes_data)) * 0.02; % 2% do range do eixo X
    offset_y = (max(penetracao_data) - min(penetracao_data)) * 0.02; % 2% do range do eixo Y

    text(lcoe_ponto + offset_x, pen_ponto + offset_y, ...
         texto_para_plotar, ...
         'Parent', h_ax, ...
         'Tag', 'ponto_info_texto', ...        % Tag para encontrá-lo e apagá-lo
         'BackgroundColor', [1, 1, 0.9], ... % Fundo amarelo claro
         'EdgeColor', 'black', ...           % Borda preta
         'FontSize', 9, ...
         'FontName', 'Consolas', ...        % 'Monospaced'
         'VerticalAlignment', 'bottom', ...
         'HorizontalAlignment', 'left');

    % 9. Feedback no console (opcional, mas útil)
    fprintf('\n>> Dados exibidos no gráfico para a configuração:\n');
    fprintf('   SFV: %.1f kWp | SAE: %.1f kWh | GMG: %.1f kW\n', ...
            dados_sfv, dados_sae, dados_gmg);
end

