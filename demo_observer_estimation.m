clearvars -except ans;
clc;

p = get_sim_params('disturbance');
controllersESO = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso'};
resultsESO = cell(numel(controllersESO), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 7: observer estimation validation\n');
fprintf('Case: strong disturbance\n');
fprintf('Controllers with ESO: ln-NFTSMC+ESO / Classic SMC+ESO / NTSMC+ESO / PD+ESO\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('==============================================\n');

names = cell(numel(controllersESO), 1);
RMSEstErr2 = zeros(numel(controllersESO), 1);
IAEEstErr2 = zeros(numel(controllersESO), 1);
PeakEstErr2 = zeros(numel(controllersESO), 1);
IAE_y2Global = zeros(numel(controllersESO), 1);
PeakU2 = zeros(numel(controllersESO), 1);

for k = 1:numel(controllersESO)
    fprintf('Running controller %d/%d: %s\n', k, numel(controllersESO), controllersESO{k});
    resultsESO{k} = run_closed_loop_case(p, controllersESO{k});
    ext = calc_extended_metrics(resultsESO{k}, p.ctrl.prop.eb(2), 0.05);
    names{k} = resultsESO{k}.label;
    RMSEstErr2(k) = ext.RMSEstErr2;
    IAEEstErr2(k) = ext.IAEEstErr2;
    PeakEstErr2(k) = ext.PeakEstErr2;
    IAE_y2Global(k) = ext.IAE_y2Global;
    PeakU2(k) = ext.PeakAbsU2;
end

T = table(names, RMSEstErr2, IAEEstErr2, PeakEstErr2, IAE_y2Global, PeakU2);
disp(T);

outNoESO = run_closed_loop_case(p, 'lnftsmc_noeso');
zoomWin = local_time_zoom_window(resultsESO{1}.t);

figure('Name', 'Observer estimation - disturbance and compensation term', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, resultsESO{1}.t, resultsESO{1}.dTrue(:,2), 'k-', 'LineWidth', 1.4, 'DisplayName', 'd_{2,true}');
for k = 1:numel(resultsESO)
    zhatUsed2 = resultsESO{k}.dTrue(:,2) - resultsESO{k}.residual(:,2);
    plot(ax, resultsESO{k}.t, zhatUsed2, 'LineWidth', 1.2, 'DisplayName', [resultsESO{k}.label, ' : \rho_2 z_{23}']);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'disturbance estimate');
title(ax, 'Channel 2 disturbance and ESO-based compensation term');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Observer estimation - residual error', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(resultsESO)
    plot(ax, resultsESO{k}.t, resultsESO{k}.residual(:,2), 'LineWidth', 1.2, 'DisplayName', resultsESO{k}.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'd_2 - \rho_2 z_{23}');
title(ax, 'Channel 2 estimation residual');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Observer estimation - whole-beam vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(resultsESO)
    plot(ax, resultsESO{k}.t, resultsESO{k}.yGlobal(:,2), 'LineWidth', 1.2, 'DisplayName', resultsESO{k}.label);
end
plot(ax, outNoESO.t, outNoESO.yGlobal(:,2), '--', 'LineWidth', 1.2, 'DisplayName', outNoESO.label);
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, 'Whole-beam vibration descriptor under strong disturbance');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 2.0), t(end))];
end
