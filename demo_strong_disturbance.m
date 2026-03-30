clearvars -except ans;
clc;

p = get_sim_params('disturbance');
controllers = {'lnftsmc_eso', 'smc_eso', 'lnftsmc_noeso', 'ntsmc_eso', 'pd_eso'};
results = cell(numel(controllers), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 5: strong-disturbance comparison\n');
fprintf('Controllers under stronger multi-source disturbance\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('==============================================\n');

for k = 1:numel(controllers)
    results{k} = run_closed_loop_case(p, controllers{k});
end

if isfield(p, 'plot') && isfield(p.plot, 'enableMainPlots') && p.plot.enableMainPlots
    plot_disturbance_compare(results, p);
end

names   = cell(numel(results), 1);
IAE_y1  = zeros(numel(results), 1);
IAE_y2Global  = zeros(numel(results), 1);
PeakU2  = zeros(numel(results), 1);
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
    PeakU2(k)       = r.metrics.PeakAbsU2;
    PeakDz2(k)      = r.metrics.PeakAbsResidual2;

    modal = calc_modal_metrics(r);
    PeakQ1(k) = modal.PeakAbsQ1;
    IAE_Q1(k) = modal.IAE_Q1;
    PeakQ2(k) = modal.PeakAbsQ2;
    IAE_Q2(k) = modal.IAE_Q2;
end

T = table(names, IAE_y1, IAE_y2Global, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, PeakU2, PeakDz2);
disp(T);

Controller = string(names);
paperT_disturbance = table(Controller, IAE_y1, IAE_y2Global, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, PeakU2, PeakDz2);

paperTables = struct( ...
    'name', 'Table02_strong_disturbance_main_metrics', ...
    'table', paperT_disturbance, ...
    'purpose', 'Main strong-disturbance quantitative comparison across the five closed-loop controllers.');

paperFigureMap = struct('sourceName', {}, 'exportName', {}, 'purpose', {});
paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 5 is exported as a paper table, while the paper figure for disturbance time responses is handled by the open-loop baseline script.'};
