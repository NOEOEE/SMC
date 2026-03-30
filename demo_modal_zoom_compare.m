clearvars -except ans;
clc;

caseList = {'nominal', 'disturbance'};
caseTitleList = {'Nominal modal comparison', 'Strong-disturbance modal comparison'};
controllers = {'open_loop', 'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};
allResults = cell(numel(caseList), 1);
summaryTabs = cell(numel(caseList), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 11: dedicated modal full-response + local-zoom comparison\n');
fprintf('Modes reported separately: q1 and q2\n');
fprintf('The script uses a finer output grid so the q2 transient is visible\n');
fprintf('==============================================\n');

for ic = 1:numel(caseList)
    p = get_sim_params(caseList{ic});
    p.sim.outputDt = 5e-4;
    p.sim.tEnd = min(p.sim.tEnd, 3.0);

    results = cell(numel(controllers), 1);
    names = cell(numel(controllers), 1);
    PeakQ1 = zeros(numel(controllers), 1);
    IAE_Q1 = zeros(numel(controllers), 1);
    PeakQ2 = zeros(numel(controllers), 1);
    IAE_Q2 = zeros(numel(controllers), 1);
    PeakY2Global = zeros(numel(controllers), 1);

    fprintf('\n--- Case %d/%d: %s ---\n', ic, numel(caseList), caseTitleList{ic});
    for k = 1:numel(controllers)
        fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
        results{k} = run_closed_loop_case(p, controllers{k});
        names{k} = results{k}.label;

        modal = calc_modal_metrics(results{k});
        PeakQ1(k) = modal.PeakAbsQ1;
        IAE_Q1(k) = modal.IAE_Q1;
        PeakQ2(k) = modal.PeakAbsQ2;
        IAE_Q2(k) = modal.IAE_Q2;
        PeakY2Global(k) = results{k}.metrics.PeakAbsY2Global;
    end

    T = table(names, PeakQ1, IAE_Q1, PeakQ2, IAE_Q2, PeakY2Global);
    disp(T);
    summaryTabs{ic} = T;
    allResults{ic} = results;

    refIdx = find(strcmpi(controllers, 'lnftsmc_eso'), 1);
    if isempty(refIdx)
        refIdx = 1;
    end
    winQ1 = local_zoom_window(results{refIdx}.t, 1000 * results{refIdx}.x(:,3), 0.20, 0.18);
    winQ2 = local_zoom_window(results{refIdx}.t, 1000 * results{refIdx}.x(:,4), 0.20, 0.05);

    local_plot_modal_zoom(results, caseTitleList{ic}, winQ1, winQ2);
end

local_plot_modal_zoom_paper_summary(allResults, caseTitleList);

Tnom = summaryTabs{1};
Tdist = summaryTabs{2};
paperT_nominal = table(string(Tnom.names), Tnom.PeakQ1, Tnom.IAE_Q1, Tnom.PeakQ2, Tnom.IAE_Q2, Tnom.PeakY2Global, ...
    'VariableNames', {'Controller', 'PeakQ1', 'IAE_Q1', 'PeakQ2', 'IAE_Q2', 'PeakY2Global'});
paperT_disturbance = table(string(Tdist.names), Tdist.PeakQ1, Tdist.IAE_Q1, Tdist.PeakQ2, Tdist.IAE_Q2, Tdist.PeakY2Global, ...
    'VariableNames', {'Controller', 'PeakQ1', 'IAE_Q1', 'PeakQ2', 'IAE_Q2', 'PeakY2Global'});

paperTables(1) = struct( ...
    'name', 'Table09_modal_zoom_nominal', ...
    'table', paperT_nominal, ...
    'purpose', 'Modal metrics under nominal conditions using the finer output grid used for the local zoom plots.');
paperTables(2) = struct( ...
    'name', 'Table10_modal_zoom_disturbance', ...
    'table', paperT_disturbance, ...
    'purpose', 'Modal metrics under strong-disturbance conditions using the finer output grid used for the local zoom plots.');

paperFigureMap = struct( ...
    'sourceName', 'Modal zoom - paper summary', ...
    'exportName', 'Fig03_modal_local_zooms', ...
    'purpose', 'Dedicated local zooms of q_1 and q_2 under nominal and disturbance conditions.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 11 is exported as a paper figure because the peak metrics alone do not separate controllers well; the local modal decay rates do.'};


function local_plot_modal_zoom(results, caseTitle, winQ1, winQ2)
clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);

figure('Name', ['Modal zoom - ', caseTitle, ' - q1 full response'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'k--', 'LineWidth', 1.3, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'LineWidth', 1.1, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_1 (mm)');
title(ax, [caseTitle, ': q_1 full response']);
legend(ax, 'Location', 'best');

figure('Name', ['Modal zoom - ', caseTitle, ' - q1 local zoom'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'k--', 'LineWidth', 1.3, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,3), 'LineWidth', 1.1, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlim(ax, winQ1);
ylim(ax, local_zoom_ylim(results, 3, winQ1));
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_1 (mm)');
title(ax, [caseTitle, ': q_1 local zoom']);
legend(ax, 'Location', 'best');

figure('Name', ['Modal zoom - ', caseTitle, ' - q2 full response'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'k--', 'LineWidth', 1.3, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'LineWidth', 1.1, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_2 (mm)');
title(ax, [caseTitle, ': q_2 full response']);
legend(ax, 'Location', 'best');

figure('Name', ['Modal zoom - ', caseTitle, ' - q2 local zoom'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'k--', 'LineWidth', 1.3, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,4), 'LineWidth', 1.1, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlim(ax, winQ2);
ylim(ax, local_zoom_ylim(results, 4, winQ2));
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_2 (mm)');
title(ax, [caseTitle, ': q_2 local zoom']);
legend(ax, 'Location', 'best');
end

function local_plot_modal_zoom_paper_summary(allResults, caseTitleList)
figure('Name', 'Modal zoom - paper summary', 'Color', 'w');
tlo = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for ic = 1:numel(allResults)
    results = allResults{ic};
    refIdx = 1;
    for k = 1:numel(results)
        if strcmpi(results{k}.controllerName, 'lnftsmc_eso')
            refIdx = k;
            break;
        end
    end
    winQ1 = local_zoom_window(results{refIdx}.t, 1000 * results{refIdx}.x(:,3), 0.20, 0.18);
    winQ2 = local_zoom_window(results{refIdx}.t, 1000 * results{refIdx}.x(:,4), 0.20, 0.05);

    axQ1 = nexttile(tlo);
    local_plot_modal_zoom_tile(axQ1, results, 3, winQ1, [caseTitleList{ic}, ': q_1 local zoom']);
    if ic == 1
        legend(axQ1, 'Location', 'best');
    end

    axQ2 = nexttile(tlo);
    local_plot_modal_zoom_tile(axQ2, results, 4, winQ2, [caseTitleList{ic}, ': q_2 local zoom']);
end
xlabel(tlo, 'Time (s)');
ylabel(tlo, 'Modal displacement (mm)');
title(tlo, 'Dedicated modal local zooms');
end

function local_plot_modal_zoom_tile(ax, results, xCol, win, panelTitle)
clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    if k == 1
        plot(ax, results{k}.t, 1000 * results{k}.x(:,xCol), 'k--', 'LineWidth', 1.25, 'DisplayName', labels{k});
    else
        plot(ax, results{k}.t, 1000 * results{k}.x(:,xCol), 'LineWidth', 1.1, 'Color', clr(k,:), 'DisplayName', labels{k});
    end
end
xlim(ax, win);
ylim(ax, local_zoom_ylim(results, xCol, win));
title(ax, panelTitle);
if xCol == 3
    ylabel(ax, 'q_1 (mm)');
else
    ylabel(ax, 'q_2 (mm)');
end
end

function win = local_zoom_window(t, signal, ratioThreshold, spanRatio)
if nargin < 3 || isempty(ratioThreshold)
    ratioThreshold = 0.2;
end
if nargin < 4 || isempty(spanRatio)
    spanRatio = 0.15;
end

t = t(:);
signal = signal(:);
T = max(t(end) - t(1), eps);
peak = max(abs(signal));

if peak <= eps
    tStart = t(1);
else
    [~, idxPeak] = max(abs(signal));
    idxRel = find(abs(signal(idxPeak:end)) <= ratioThreshold * peak, 1, 'first');
    if isempty(idxRel)
        idx = min(numel(t), idxPeak + max(round(0.15 * numel(t)), 1));
    else
        idx = idxPeak + idxRel - 1;
    end
    tStart = t(idx);
end

span = max(spanRatio * T, 10 * max(median(diff(t)), eps));
win = [tStart, min(tStart + span, t(end))];
if win(2) <= win(1)
    win = [max(t(1), t(end) - span), t(end)];
end
end

function yLim = local_zoom_ylim(results, xCol, win)
vals = [];
for k = 1:numel(results)
    mask = results{k}.t >= win(1) & results{k}.t <= win(2);
    if any(mask)
        vals = [vals; 1000 * results{k}.x(mask, xCol)]; %#ok<AGROW>
    end
end

if isempty(vals)
    yLim = [-1, 1];
    return;
end

vMin = min(vals);
vMax = max(vals);
span = vMax - vMin;
if span < 1e-6
    pad = max(0.1 * max(abs([vMin; vMax])), 1e-3);
else
    pad = 0.12 * span;
end
yLim = [vMin - pad, vMax + pad];
end
