function plot_controller_compare_outputs(results, p, caseTag)
%PLOT_CONTROLLER_COMPARE_OUTPUTS
% Single-axis comparison figures for multiple controllers.
%
% Figures generated:
%   1) y1(t) angle output
%   2) y2,c(t) controller-side displacement output
%   3) y2,g(t) whole-beam vibration descriptor
%   4) Delta y1(t) = y1(t)-y1(0)
%   5) Delta y2,c(t) = y2,c(t)-y2,c(0)
%   6) Delta y2,g(t) = y2,g(t)-y2,g(0)
%   7) e1(t) = y1(t)-y1d(t)
%   8) e2(t) = y2,c(t)-y2d(t)
%   9) e2,g(t) = y2,g(t)-0
%
% Usage:
%   plot_controller_compare_outputs(results, p, 'nominal')
%
% where results is a cell array of outputs returned by RUN_CLOSED_LOOP_CASE.

if nargin < 3 || isempty(caseTag)
    caseTag = 'case';
end

if isempty(results)
    error('results is empty.');
end

n = numel(results);
clr = lines(n);
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);

base = results{1};
t = base.t(:);

eb = NaN;
if nargin >= 2 && ~isempty(p) && isfield(p, 'ctrl') && isfield(p.ctrl, 'prop') && isfield(p.ctrl.prop, 'eb') && numel(p.ctrl.prop.eb) >= 2
    eb = p.ctrl.prop.eb(2);
end

% -------- 1) y1 output --------
figure('Name', ['Controller comparison - ' caseTag ' - y1 output'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    plot(ax, results{k}.t, results{k}.y(:,1), 'LineWidth', 1.5, 'Color', clr(k,:));
end
plot(ax, base.t, base.yd(:,1), 'k--', 'LineWidth', 1.4);
xlabel(ax, 'Time (s)');
ylabel(ax, 'y_1 = \theta (rad)');
title(ax, ['Angle output comparison - ' caseTag]);
legend(ax, [labels; {'y_{1d}'}], 'Location', 'best');

% -------- 2) y2,c output --------
figure('Name', ['Controller comparison - ' caseTag ' - y2c output'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    plot(ax, results{k}.t, results{k}.y(:,2), 'LineWidth', 1.5, 'Color', clr(k,:));
end
plot(ax, base.t, base.yd(:,2), 'k--', 'LineWidth', 1.4);
legHandles = gobjects(n + 1, 1);
for k = 1:n
    legHandles(k) = plot(nan, nan, '-', 'LineWidth', 1.5, 'Color', clr(k,:));
end
legHandles(n + 1) = plot(nan, nan, 'k--', 'LineWidth', 1.4);
legLabels = [labels; {'y_{2d}'}];
if ~isnan(eb)
    hEbP = plot(ax, base.t,  eb * ones(size(base.t)), 'Color', [0.25 0.25 0.25], 'LineStyle', '--', 'LineWidth', 1.0);
    hEbN = plot(ax, base.t, -eb * ones(size(base.t)), 'Color', [0.25 0.25 0.25], 'LineStyle', '--', 'LineWidth', 1.0);
    legHandles = [legHandles; hEbP; hEbN]; %#ok<AGROW>
    legLabels = [legLabels; {'+e_b'; '-e_b'}]; %#ok<AGROW>
end
xlabel(ax, 'Time (s)');
ylabel(ax, 'y_{2,c} (mm)');
title(ax, ['Controller-side displacement output comparison - ' caseTag]);
legend(ax, legHandles, legLabels, 'Location', 'best');

% -------- 3) y2,g output --------
figure('Name', ['Controller comparison - ' caseTag ' - y2g output'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    if isfield(results{k}, 'yGlobal') && size(results{k}.yGlobal,2) >= 2
        plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.5, 'Color', clr(k,:));
    end
end
plot(ax, base.t, zeros(size(base.t)), 'k--', 'LineWidth', 1.2);
xlabel(ax, 'Time (s)');
% ylabel(ax, 'y_{2,g} (mm)');
% title(ax, ['Whole-beam vibration descriptor comparison - ' caseTag]);
ylabel(ax, 'y_{2,g} = y_{tip} (mm)');
title(ax, ['Beam-tip linear displacement comparison - ' caseTag]);
legend(ax, [labels; {'zero line'}], 'Location', 'best');

% -------- 4) Delta y1 --------
figure('Name', ['Controller comparison - ' caseTag ' - delta y1'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    y1 = results{k}.y(:,1);
    plot(ax, results{k}.t, y1 - y1(1), 'LineWidth', 1.5, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)');
ylabel(ax, '\Delta y_1 (rad)');
title(ax, ['Angle variation comparison - ' caseTag]);
legend(ax, labels, 'Location', 'best');

% -------- 5) Delta y2,c --------
figure('Name', ['Controller comparison - ' caseTag ' - delta y2c'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    y2c = results{k}.y(:,2);
    plot(ax, results{k}.t, y2c - y2c(1), 'LineWidth', 1.5, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)');
ylabel(ax, '\Delta y_{2,c} (mm)');
title(ax, ['Controller-side displacement variation comparison - ' caseTag]);
legend(ax, labels, 'Location', 'best');

% -------- 6) Delta y2,g --------
figure('Name', ['Controller comparison - ' caseTag ' - delta y2g'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    if isfield(results{k}, 'yGlobal') && size(results{k}.yGlobal,2) >= 2
        y2g = results{k}.yGlobal(:,2);
        plot(ax, results{k}.t, y2g - y2g(1), 'LineWidth', 1.5, 'Color', clr(k,:));
    end
end
xlabel(ax, 'Time (s)');
% ylabel(ax, '\Delta y_{2,g} (mm)');
% title(ax, ['Whole-beam descriptor variation comparison - ' caseTag]);
ylabel(ax, '\Delta y_{2,g} (mm)');
title(ax, ['Beam-tip linear displacement variation comparison - ' caseTag]);
legend(ax, labels, 'Location', 'best');

% -------- 7) e1 --------
figure('Name', ['Controller comparison - ' caseTag ' - e1'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    e1 = results{k}.y(:,1) - results{k}.yd(:,1);
    plot(ax, results{k}.t, e1, 'LineWidth', 1.5, 'Color', clr(k,:));
end
plot(ax, base.t, zeros(size(base.t)), 'k--', 'LineWidth', 1.0);
xlabel(ax, 'Time (s)');
ylabel(ax, 'e_1 (rad)');
title(ax, ['Angle tracking error comparison - ' caseTag]);
legend(ax, [labels; {'zero line'}], 'Location', 'best');

% -------- 8) e2 --------
figure('Name', ['Controller comparison - ' caseTag ' - e2'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    e2 = results{k}.y(:,2) - results{k}.yd(:,2);
    plot(ax, results{k}.t, e2, 'LineWidth', 1.5, 'Color', clr(k,:));
end
legHandles = gobjects(n + 1, 1);
for k = 1:n
    legHandles(k) = plot(nan, nan, '-', 'LineWidth', 1.5, 'Color', clr(k,:));
end
legHandles(n + 1) = plot(nan, nan, 'k--', 'LineWidth', 1.0);
legLabels = [labels; {'zero line'}];
plot(ax, base.t, zeros(size(base.t)), 'k--', 'LineWidth', 1.0);
if ~isnan(eb)
    hEbP = plot(ax, base.t,  eb * ones(size(base.t)), 'Color', [0.25 0.25 0.25], 'LineStyle', '--', 'LineWidth', 1.0);
    hEbN = plot(ax, base.t, -eb * ones(size(base.t)), 'Color', [0.25 0.25 0.25], 'LineStyle', '--', 'LineWidth', 1.0);
    legHandles = [legHandles; hEbP; hEbN]; %#ok<AGROW>
    legLabels = [legLabels; {'+e_b'; '-e_b'}]; %#ok<AGROW>
end
xlabel(ax, 'Time (s)');
ylabel(ax, 'e_2 = y_{2,c}-y_{2d} (mm)');
title(ax, ['Controller-side displacement tracking error comparison - ' caseTag]);
legend(ax, legHandles, legLabels, 'Location', 'best');

% -------- 9) e2,g --------
figure('Name', ['Controller comparison - ' caseTag ' - e2g'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:n
    if isfield(results{k}, 'yGlobal') && size(results{k}.yGlobal,2) >= 2
        e2g = results{k}.yGlobal(:,2); % reference is zero
        plot(ax, results{k}.t, e2g, 'LineWidth', 1.5, 'Color', clr(k,:));
    end
end
plot(ax, base.t, zeros(size(base.t)), 'k--', 'LineWidth', 1.0);
xlabel(ax, 'Time (s)');
ylabel(ax, 'e_{2,g} = y_{tip}-0 (mm)');
title(ax, ['Beam-tip linear displacement deviation comparison - ' caseTag]);
% ylabel(ax, 'e_{2,g} = y_{2,g}-0 (mm)');
% title(ax, ['Whole-beam deviation comparison - ' caseTag]);
legend(ax, [labels; {'zero line'}], 'Location', 'best');
end
