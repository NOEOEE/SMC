function plot_nominal_compare(results, p)
%PLOT_NOMINAL_COMPARE Single-axis figures for Experiment 1.

clr = lines(numel(results));
labels = cellfun(@(r) r.label, results, 'UniformOutput', false);
eb = p.ctrl.prop.eb(2);
zoomWin = local_time_zoom_window(results{1}.t);

figure('Name', 'Nominal comparison - channel 1 attitude output', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.y(:,1), 'LineWidth', 1.5, 'Color', clr(k,:));
end
plot(ax, results{1}.t, results{1}.yd(:,1), 'k--', 'LineWidth', 1.4);
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_1 (rad)');
title(ax, 'Channel 1 attitude output');
legend(ax, [labels; {'y_{1d}'}], 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Nominal comparison - whole-beam vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.5, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, 'Whole-beam vibration descriptor');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Nominal comparison - controller-side vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.y(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
hEbP = plot(ax, results{1}.t, eb * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.0);
hEbN = plot(ax, results{1}.t, -eb * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.0);
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,c} (mm)');
title(ax, 'Controller-side vibration output with boundary');
legend(ax, [hEbP, hEbN], {'+e_b', '-e_b'}, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Nominal comparison - channel 1 control input', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.u(:,1), 'LineWidth', 1.3, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'u_1 = V_m');
title(ax, 'Channel 1 actual control input');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Nominal comparison - channel 2 control input', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.u(:,2), 'LineWidth', 1.3, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'u_2 = V_p (V)');
title(ax, 'Channel 2 actual control input');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Nominal comparison - channel 1 ESO residual', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.residual(:,1), 'LineWidth', 1.2, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'd_1 - z_{13}');
title(ax, 'Channel 1 ESO residual');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Nominal comparison - channel 2 ESO residual', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.residual(:,2), 'LineWidth', 1.2, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'd_2 - z_{23}');
title(ax, 'Channel 2 ESO residual');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');
end

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
