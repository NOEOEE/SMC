clearvars -except ans;
clc;

caseList = {'nominal', 'disturbance'};
controllers = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};
allResults = cell(numel(caseList), numel(controllers));
summaryTabs = cell(numel(caseList), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 9: control smoothness / chattering comparison\n');
fprintf('Metrics: PeakU2, RMSU2, TVU2, ISVU2, RMSdU2, EnergyU2\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('==============================================\n');

for ic = 1:numel(caseList)
    p = get_sim_params(caseList{ic});
    fprintf('\n--- Case %d/%d: %s ---\n', ic, numel(caseList), caseList{ic});

    names  = cell(numel(controllers), 1);
    IAE_y2Global = zeros(numel(controllers), 1);
    PeakU2 = zeros(numel(controllers), 1);
    RMSU2  = zeros(numel(controllers), 1);
    TVU2   = zeros(numel(controllers), 1);
    ISVU2  = zeros(numel(controllers), 1);
    RMSdU2 = zeros(numel(controllers), 1);
    EnergyU2 = zeros(numel(controllers), 1);

    for k = 1:numel(controllers)
        fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
        out = run_closed_loop_case(p, controllers{k});
        allResults{ic, k} = out;
        ext = calc_extended_metrics(out, p.ctrl.prop.eb(2), 0.05);

        names{k} = out.label;
        IAE_y2Global(k) = ext.IAE_y2Global;
        PeakU2(k) = ext.PeakAbsU2;
        RMSU2(k) = ext.RMSU2;
        TVU2(k) = ext.TVU2;
        ISVU2(k) = ext.ISVU2;
        RMSdU2(k) = ext.RMSdU2;
        EnergyU2(k) = ext.EnergyU2;
    end

    T = table(names, IAE_y2Global, PeakU2, RMSU2, TVU2, ISVU2, RMSdU2, EnergyU2);
    summaryTabs{ic} = T;
    disp(T);
end

zoomWin = local_time_zoom_window(allResults{1,1}.t);
figure('Name', 'Control smoothness - channel 2 control input', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    out = allResults{1, k};
    plot(ax, out.t, out.u(:,2), 'LineWidth', 1.2, 'DisplayName', out.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'u_2 (V)');
title(ax, 'Nominal case: channel 2 control input');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Control smoothness - channel 2 control-rate proxy', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    out = allResults{1, k};
    du2rate = zeros(size(out.u(:,2)));
    dt = diff(out.t);
    du2rate(2:end) = diff(out.u(:,2)) ./ max(dt, eps);
    plot(ax, out.t, du2rate, 'LineWidth', 1.1, 'DisplayName', out.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'du_2/dt');
title(ax, 'Nominal case: channel 2 control-rate proxy');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

local_plot_tradeoff_paper_summary(summaryTabs, caseList);

Tnom = summaryTabs{1};
Tdist = summaryTabs{2};
paperT_nominal = table(string(Tnom.names), Tnom.IAE_y2Global, Tnom.PeakU2, Tnom.RMSU2, Tnom.TVU2, Tnom.ISVU2, Tnom.RMSdU2, Tnom.EnergyU2, ...
    'VariableNames', {'Controller', 'IAE_y2Global', 'PeakU2', 'RMSU2', 'TVU2', 'ISVU2', 'RMSdU2', 'EnergyU2'});
paperT_disturbance = table(string(Tdist.names), Tdist.IAE_y2Global, Tdist.PeakU2, Tdist.RMSU2, Tdist.TVU2, Tdist.ISVU2, Tdist.RMSdU2, Tdist.EnergyU2, ...
    'VariableNames', {'Controller', 'IAE_y2Global', 'PeakU2', 'RMSU2', 'TVU2', 'ISVU2', 'RMSdU2', 'EnergyU2'});

paperTables(1) = struct( ...
    'name', 'Table07_chattering_nominal', ...
    'table', paperT_nominal, ...
    'purpose', 'Control-effort and smoothness metrics under nominal conditions.');
paperTables(2) = struct( ...
    'name', 'Table08_chattering_disturbance', ...
    'table', paperT_disturbance, ...
    'purpose', 'Control-effort and smoothness metrics under strong-disturbance conditions.');

paperFigureMap = struct( ...
    'sourceName', 'Control smoothness - paper tradeoff summary', ...
    'exportName', 'Fig06_vibration_effort_tradeoff', ...
    'purpose', 'Trade-off between vibration suppression and control effort under nominal and disturbance conditions.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 9 is exported as a paper summary figure to make the effort-performance trade-off explicit instead of claiming blanket superiority.'};


function local_plot_tradeoff_paper_summary(summaryTabs, caseList)
figure('Name', 'Control smoothness - paper tradeoff summary', 'Color', 'w');
tlo = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for ic = 1:numel(caseList)
    T = summaryTabs{ic};
    ax = nexttile(tlo);
    hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');

    x = T.IAE_y2Global;
    y = T.RMSU2;
    scatter(ax, x, y, 55, 'filled');
    for k = 1:height(T)
        text(ax, x(k) + 0.01 * max(x), y(k), local_short_controller_name(T.names{k}), 'FontSize', 8, 'Interpreter', 'none');
    end
    xlabel(ax, 'IAE_{y_{2,g}}');
    ylabel(ax, 'RMS(u_2)');
    title(ax, [caseList{ic}, ': suppression-effort trade-off']);
end

title(tlo, 'Vibration suppression vs control effort');
end

function label = local_short_controller_name(nameIn)
label = char(nameIn);
label = strrep(label, 'Classic ', '');
label = strrep(label, 'ln-NFTSMC(no ESO)', 'ln-NFTSMC(noESO)');
end

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
