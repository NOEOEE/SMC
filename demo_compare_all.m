clearvars -except ans;
clc;

p = get_sim_params('nominal');
controllers = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};
results = cell(numel(controllers), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 1: nominal comparison with classic-SMC benchmark\n');
fprintf('Controllers: ln-NFTSMC+ESO / Classic SMC+ESO / NTSMC+ESO / PD+ESO / ln-NFTSMC(no ESO)\n');
fprintf('Plant: literature-based beam / piezo + rigid channel\n');
fprintf('Whole-beam metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('==============================================\n');

for k = 1:numel(controllers)
    fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
    results{k} = run_closed_loop_case(p, controllers{k});
end

if isfield(p, 'plot') && isfield(p.plot, 'enableMainPlots') && p.plot.enableMainPlots
    plot_nominal_compare(results, p);
end

names  = cell(numel(results), 1);
IAE_y1 = zeros(numel(results), 1);
IAE_y2Global = zeros(numel(results), 1);
RMS_y2Global = zeros(numel(results), 1);
PeakY2Global = zeros(numel(results), 1);
PeakU1 = zeros(numel(results), 1);
PeakU2 = zeros(numel(results), 1);
PeakDz1 = zeros(numel(results), 1);
PeakDz2 = zeros(numel(results), 1);
PeakQ1 = zeros(numel(results), 1);
IAE_Q1 = zeros(numel(results), 1);
PeakQ2 = zeros(numel(results), 1);
IAE_Q2 = zeros(numel(results), 1);

for k = 1:numel(results)
    r = results{k};
    names{k}        = r.label;
    IAE_y1(k)       = r.metrics.IAE_y1;
    IAE_y2Global(k) = r.metrics.IAE_y2Global;
    RMS_y2Global(k) = r.metrics.RMS_y2Global;
    PeakY2Global(k) = r.metrics.PeakAbsY2Global;
    PeakU1(k)       = r.metrics.PeakAbsU1;
    PeakU2(k)       = r.metrics.PeakAbsU2;
    PeakDz1(k)      = r.metrics.PeakAbsResidual1;
    PeakDz2(k)      = r.metrics.PeakAbsResidual2;

    modal = calc_modal_metrics(r);
    PeakQ1(k) = modal.PeakAbsQ1;
    IAE_Q1(k) = modal.IAE_Q1;
    PeakQ2(k) = modal.PeakAbsQ2;
    IAE_Q2(k) = modal.IAE_Q2;
end

T = table(names, IAE_y1, IAE_y2Global, RMS_y2Global, PeakY2Global, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, PeakU1, PeakU2, PeakDz1, PeakDz2);
disp(T);

Controller = string(names);
paperT_nominal = table(Controller, IAE_y1, IAE_y2Global, RMS_y2Global, PeakY2Global, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, PeakU1, PeakU2, PeakDz1, PeakDz2);

paperTables = struct( ...
    'name', 'Table01_nominal_main_metrics', ...
    'table', paperT_nominal, ...
    'purpose', 'Main nominal quantitative comparison across the five closed-loop controllers.');

paperFigureMap = struct('sourceName', {}, 'exportName', {}, 'purpose', {});
paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 1 is exported as a paper table, not a paper figure, because the open-loop benchmark figure in Experiment 2 already visualizes the nominal time responses.'};
