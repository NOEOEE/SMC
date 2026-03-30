function plot_bandwidth_compare(results, p, woScale)
%PLOT_BANDWIDTH_COMPARE Single-axis figures for Experiment 3.

clr = lines(numel(results));
labels = cell(numel(results), 1);
for k = 1:numel(results)
    labels{k} = sprintf('w_o x %.1f', woScale(k));
end
zoomWin = local_time_zoom_window(results{1}.t);

figure('Name', 'ESO bandwidth sweep - whole-beam vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.yGlobal(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, 'Whole-beam vibration descriptor versus ESO bandwidth');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'ESO bandwidth sweep - controller-side vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.y(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
hEbP = plot(ax, results{1}.t, p.ctrl.prop.eb(2) * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.0);
hEbN = plot(ax, results{1}.t, -p.ctrl.prop.eb(2) * ones(size(results{1}.t)), 'k--', 'LineWidth', 1.0);
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,c} (mm)');
title(ax, 'Controller-side vibration output versus ESO bandwidth');
legend(ax, [hEbP, hEbN], {'+e_b', '-e_b'}, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'ESO bandwidth sweep - channel 2 control input', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.u(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'u_2 = V_p (V)');
title(ax, 'Control effort versus ESO bandwidth');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'ESO bandwidth sweep - disturbance estimate', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, results{2}.t, results{2}.dTrue(:,2), 'k--', 'LineWidth', 1.4);
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.z3(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'd_2 and z_{23}');
title(ax, 'True disturbance and ESO estimate (channel 2)');
legend(ax, [{'d_2 true'}; labels], 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'ESO bandwidth sweep - residual estimation error', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(results)
    plot(ax, results{k}.t, results{k}.residual(:,2), 'LineWidth', 1.4, 'Color', clr(k,:));
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'd_2 - z_{23}');
title(ax, 'Residual estimation error versus ESO bandwidth');
legend(ax, labels, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');
end

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
