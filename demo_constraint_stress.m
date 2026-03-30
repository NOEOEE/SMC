clearvars -except ans;
clc;

p = get_sim_params('stress');
controllers = {'lnftsmc_eso', 'ntsmc_eso', 'lnftsmc_noeso'};
results = cell(numel(controllers), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 3: constraint-stress comparison\n');
fprintf('Tighter vibration boundary and near-boundary initial condition\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('Boundary occupancy: still checked on controller-side y2_ctrl\n');
fprintf('==============================================\n');

for k = 1:numel(controllers)
    results{k} = run_closed_loop_case(p, controllers{k});
end

if isfield(p, 'plot') && isfield(p.plot, 'enableMainPlots') && p.plot.enableMainPlots
    plot_stress_compare(results, p);
end

names            = cell(numel(results), 1);
PeakY2Global     = zeros(numel(results), 1);
PeakY2Ctrl       = zeros(numel(results), 1);
RatioEbCtrl      = zeros(numel(results), 1);
OverEbCtrl       = zeros(numel(results), 1);
HitBoundaryCtrl  = false(numel(results), 1);
IAE_y2Global     = zeros(numel(results), 1);
PeakU2           = zeros(numel(results), 1);

eb2 = p.ctrl.prop.eb(2);

for k = 1:numel(results)
    r = results{k};
    ext = calc_extended_metrics(r, eb2, 0.05);
    names{k}           = r.label;
    PeakY2Global(k)    = ext.PeakY2Global;
    PeakY2Ctrl(k)      = ext.PeakY2Ctrl;
    RatioEbCtrl(k)     = ext.RatioEbCtrl;
    OverEbCtrl(k)      = ext.OverEbCtrl;
    HitBoundaryCtrl(k) = ext.HitBoundaryCtrl;
    IAE_y2Global(k)    = ext.IAE_y2Global;
    PeakU2(k)          = ext.PeakAbsU2;
end

T = table(names, PeakY2Global, PeakY2Ctrl, RatioEbCtrl, OverEbCtrl, HitBoundaryCtrl, IAE_y2Global, PeakU2);
disp(T);

local_plot_constraint_stress_paper_summary(results, p);

Controller = string(names);
paperT_stress = table(Controller, PeakY2Global, PeakY2Ctrl, RatioEbCtrl, OverEbCtrl, HitBoundaryCtrl, IAE_y2Global, PeakU2);

paperTables = struct( ...
    'name', 'Table05_constraint_stress_metrics', ...
    'table', paperT_stress, ...
    'purpose', 'Constraint-stress summary showing boundary occupancy, whole-beam vibration, and control effort.');

paperFigureMap = struct( ...
    'sourceName', 'Constraint stress - paper summary', ...
    'exportName', 'Fig05_constraint_stress_summary', ...
    'purpose', 'Constraint-stress responses highlighting whole-beam vibration and normalized boundary occupancy.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 3 is exported as both a paper figure and a paper table because the time response and the boundary-occupancy metrics are both important to the paper narrative.'};


function local_plot_constraint_stress_paper_summary(results, p)
clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
eb = p.ctrl.prop.eb(2);

figure('Name', 'Constraint stress - paper summary', 'Color', 'w');
tlo = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tlo);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
for k = 1:numel(results)
    plot(ax1, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.3, 'Color', clr(k,:), 'DisplayName', labels{k});
end
xlabel(ax1, 'Time (s)'); ylabel(ax1, 'y_{2,g} (mm)');
title(ax1, 'Whole-beam vibration under stress');
legend(ax1, 'Location', 'best');

ax2 = nexttile(tlo);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
for k = 1:numel(results)
    plot(ax2, results{k}.t, abs(results{k}.y(:,2)) / eb, 'LineWidth', 1.3, 'Color', clr(k,:), 'DisplayName', labels{k});
end
plot(ax2, results{1}.t, ones(size(results{1}.t)), 'k--', 'LineWidth', 1.0, 'DisplayName', 'boundary');
xlabel(ax2, 'Time (s)'); ylabel(ax2, '|y_{2,c}| / e_b');
title(ax2, 'Normalized boundary occupancy');
legend(ax2, 'Location', 'best');

title(tlo, 'Constraint-stress comparison');
end
