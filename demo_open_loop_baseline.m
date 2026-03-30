clearvars -except ans;
clc;

caseList = {'nominal', 'disturbance'};
caseTitleList = {'Nominal initial condition + command', 'Strong-disturbance case'};
controllers = {'open_loop', 'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};
allResults = cell(numel(caseList), 1);
summaryTabs = cell(numel(caseList), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 2: explicit open-loop / no-control baseline\n');
fprintf('Controllers: open-loop / ln-NFTSMC+ESO / Classic SMC+ESO / NTSMC+ESO / PD+ESO / ln-NFTSMC(no ESO)\n');
fprintf('Reported vibration metrics: y2_global, q1, q2\n');
fprintf('==============================================\n');

for ic = 1:numel(caseList)
    p = get_sim_params(caseList{ic});
    p.sim.outputDt = min(p.sim.outputDt, 0.002);

    results = cell(numel(controllers), 1);
    names = cell(numel(controllers), 1);
    PeakY2Global = zeros(numel(controllers), 1);
    IAE_y2Global = zeros(numel(controllers), 1);
    PeakQ1 = zeros(numel(controllers), 1);
    IAE_Q1 = zeros(numel(controllers), 1);
    PeakQ2 = zeros(numel(controllers), 1);
    IAE_Q2 = zeros(numel(controllers), 1);
    PeakAbsTrackY1 = zeros(numel(controllers), 1);

    fprintf('\n--- Case %d/%d: %s ---\n', ic, numel(caseList), caseTitleList{ic});
    for k = 1:numel(controllers)
        fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
        results{k} = run_closed_loop_case(p, controllers{k});
        names{k} = results{k}.label;

        PeakY2Global(k) = results{k}.metrics.PeakAbsY2Global;
        IAE_y2Global(k) = results{k}.metrics.IAE_y2Global;
        PeakAbsTrackY1(k) = max(abs(results{k}.y(:,1) - results{k}.yd(:,1)));

        modal = calc_modal_metrics(results{k});
        PeakQ1(k) = modal.PeakAbsQ1;
        IAE_Q1(k) = modal.IAE_Q1;
        PeakQ2(k) = modal.PeakAbsQ2;
        IAE_Q2(k) = modal.IAE_Q2;
    end

    basePeakY2 = max(PeakY2Global(1), eps);
    baseIAEY2 = max(IAE_y2Global(1), eps);
    basePeakQ1 = max(PeakQ1(1), eps);
    baseIAEQ1 = max(IAE_Q1(1), eps);
    basePeakQ2 = max(PeakQ2(1), eps);
    baseIAEQ2 = max(IAE_Q2(1), eps);

    RedPeakY2_pct = 100 * (1 - PeakY2Global / basePeakY2);
    RedIAEY2_pct = 100 * (1 - IAE_y2Global / baseIAEY2);
    RedPeakQ1_pct = 100 * (1 - PeakQ1 / basePeakQ1);
    RedIAEQ1_pct = 100 * (1 - IAE_Q1 / baseIAEQ1);
    RedPeakQ2_pct = 100 * (1 - PeakQ2 / basePeakQ2);
    RedIAEQ2_pct = 100 * (1 - IAE_Q2 / baseIAEQ2);

    T = table(names, PeakAbsTrackY1, PeakY2Global, IAE_y2Global, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, ...
        RedPeakY2_pct, RedIAEY2_pct, RedPeakQ1_pct, RedIAEQ1_pct, RedPeakQ2_pct, RedIAEQ2_pct);
    disp(T);

    summaryTabs{ic} = T;
    allResults{ic} = results;

    local_plot_open_loop_baseline(results, caseTitleList{ic});
end

local_plot_open_loop_paper_summary(allResults, caseTitleList);

Tnom = summaryTabs{1};
Tdist = summaryTabs{2};
ControllerNom = string(Tnom.names);
ControllerDist = string(Tdist.names);
paperT_nominal = table(ControllerNom, Tnom.IAE_y2Global, Tnom.IAE_Q1, Tnom.IAE_Q2, Tnom.RedIAEY2_pct, Tnom.RedIAEQ1_pct, Tnom.RedIAEQ2_pct, ...
    'VariableNames', {'Controller', 'IAE_y2Global', 'IAE_Q1', 'IAE_Q2', 'RedIAEY2_pct', 'RedIAEQ1_pct', 'RedIAEQ2_pct'});
paperT_disturbance = table(ControllerDist, Tdist.IAE_y2Global, Tdist.IAE_Q1, Tdist.IAE_Q2, Tdist.RedIAEY2_pct, Tdist.RedIAEQ1_pct, Tdist.RedIAEQ2_pct, ...
    'VariableNames', {'Controller', 'IAE_y2Global', 'IAE_Q1', 'IAE_Q2', 'RedIAEY2_pct', 'RedIAEQ1_pct', 'RedIAEQ2_pct'});

paperTables(1) = struct( ...
    'name', 'Table03_open_loop_baseline_nominal', ...
    'table', paperT_nominal, ...
    'purpose', 'Reduction of whole-beam and modal vibration metrics relative to the explicit open-loop baseline under nominal conditions.');
paperTables(2) = struct( ...
    'name', 'Table04_open_loop_baseline_disturbance', ...
    'table', paperT_disturbance, ...
    'purpose', 'Reduction of whole-beam and modal vibration metrics relative to the explicit open-loop baseline under strong-disturbance conditions.');

paperFigureMap = struct( ...
    'sourceName', 'Open-loop baseline - paper summary', ...
    'exportName', 'Fig02_open_loop_whole_beam_baseline', ...
    'purpose', 'Whole-beam vibration responses against the open-loop baseline under nominal and strong-disturbance conditions, including early-time local zooms.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = { ...
    'Experiment 2 is one of the paper-core visual figures because it directly benchmarks the proposed controller against the explicit no-control baseline.', ...
    'The q2 integral metric remains worse than open loop for several controllers, so the full baseline tables are exported on purpose instead of hiding that trade-off.'};


function local_plot_open_loop_baseline(results, caseTitle)
clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
zoomWin = local_time_zoom_window(results{1}.t);

figure('Name', ['Open-loop baseline - ', caseTitle, ' - attitude'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, results{k}.y(:,1), 'k--', 'LineWidth', 1.4, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, results{k}.y(:,1), 'LineWidth', 1.2, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
plot(ax, results{2}.t, results{2}.yd(:,1), 'k:', 'LineWidth', 1.0, 'DisplayName', 'y_{1d}');
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_1 (rad)');
title(ax, [caseTitle, ': attitude response']);
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', ['Open-loop baseline - ', caseTitle, ' - whole-beam vibration'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'k--', 'LineWidth', 1.4, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.2, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, [caseTitle, ': whole-beam vibration']);
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', ['Open-loop baseline - ', caseTitle, ' - q1'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'k--', 'LineWidth', 1.4, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'LineWidth', 1.2, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_1 (mm-equivalent)');
title(ax, [caseTitle, ': first flexible mode']);
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', ['Open-loop baseline - ', caseTitle, ' - q2'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'k--', 'LineWidth', 1.4, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'LineWidth', 1.2, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_2 (mm-equivalent)');
title(ax, [caseTitle, ': second flexible mode']);
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');
end

function local_plot_open_loop_paper_summary(allResults, caseTitleList)
figure('Name', 'Open-loop baseline - paper summary', 'Color', 'w');
tlo = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for ic = 1:numel(allResults)
    results = allResults{ic};
    labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
    zoomWin = local_time_zoom_window(results{1}.t);

    axFull = nexttile(tlo);
    local_plot_whole_beam_case(axFull, results, labels, false, zoomWin, [caseTitleList{ic}, ': full response']);
    if ic == 1
        legend(axFull, 'Location', 'northeast');
    end

    axZoom = nexttile(tlo);
    local_plot_whole_beam_case(axZoom, results, labels, true, zoomWin, [caseTitleList{ic}, ': local zoom']);
end
xlabel(tlo, 'Time (s)');
ylabel(tlo, 'y_{2,g} (mm)');
title(tlo, 'Whole-beam vibration benchmark against the open-loop baseline');
end

function local_plot_whole_beam_case(ax, results, labels, useZoom, zoomWin, panelTitle)
clr = lines(numel(results));
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'k--', 'LineWidth', 1.3, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.15, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
title(ax, panelTitle);
if useZoom
    xlim(ax, zoomWin);
    ylim(ax, local_whole_beam_zoom_ylim(results, zoomWin));
end
end

function yLim = local_whole_beam_zoom_ylim(results, win)
vals = [];
for k = 1:numel(results)
    mask = results{k}.t >= win(1) & results{k}.t <= win(2);
    if any(mask)
        vals = [vals; results{k}.yGlobal(mask,2)]; %#ok<AGROW>
    end
end
if isempty(vals)
    yLim = [-1, 1];
    return;
end
vMin = min(vals);
vMax = max(vals);
span = vMax - vMin;
if span < 1e-9
    pad = max(0.1 * max(abs([vMin; vMax])), 1e-3);
else
    pad = 0.12 * span;
end
yLim = [vMin - pad, vMax + pad];
end

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
