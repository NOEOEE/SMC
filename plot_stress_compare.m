function plot_stress_compare(results, p)
%PLOT_STRESS_COMPARE Single-axis figures for Experiment 2.

clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
eb = p.ctrl.prop.eb(2);
zoomWin = local_time_zoom_window(results{1}.t);

figure('Name', 'Constraint stress - whole-beam vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.6, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, 'Whole-beam vibration descriptor');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Constraint stress - controller-side vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.y(:,2), 'LineWidth', 1.6, 'Color', clr(k,:));
end
hEbP = plot(ax, results{1}.t, eb * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.2);
hEbN = plot(ax, results{1}.t, -eb * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.2);
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,c} (mm)');
title(ax, 'Controller-side vibration output with safety boundary');
legend(ax, [hEbP, hEbN], {'+e_b', '-e_b'}, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Constraint stress - normalized boundary occupancy', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, abs(results{k}.y(:,2)) / eb, 'LineWidth', 1.6, 'Color', clr(k,:));
end
plot(ax, results{1}.t, ones(size(results{1}.t)), 'k--', 'LineWidth', 1.2);
xlabel(ax, 'Time (s)'); ylabel(ax, '|y_{2,c}| / e_b');
title(ax, 'Normalized boundary occupancy');
legend(ax, [labels; {'boundary'}], 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Constraint stress - channel 2 control effort', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.u(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'u_2 = V_p (V)');
title(ax, 'Channel 2 control effort under constraint stress');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');
end

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
