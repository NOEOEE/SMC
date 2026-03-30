clearvars -except ans;
clc;

p = get_sim_params('disturbance');
p.sim.outputDt = 5e-4;
p.sim.tEnd = min(p.sim.tEnd, 3.0);
controllers = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso'};
results = cell(numel(controllers), 1);
modalObs = cell(numel(controllers), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 8: modal-state ESO estimation error study\n');
fprintf('Case: strong disturbance, fine output grid\n');
fprintf('Modal outputs q1 / q2 are reconstructed from the stored multi-point beam displacements\n');
fprintf('Reported errors: q1 / q2 / dq1 / dq2\n');
fprintf('==============================================\n');

names = cell(numel(controllers), 1);
RMSE_Q1 = zeros(numel(controllers), 1);
Peak_Q1 = zeros(numel(controllers), 1);
RMSE_Q2 = zeros(numel(controllers), 1);
Peak_Q2 = zeros(numel(controllers), 1);
RMSE_dQ1 = zeros(numel(controllers), 1);
Peak_dQ1 = zeros(numel(controllers), 1);
RMSE_dQ2 = zeros(numel(controllers), 1);
Peak_dQ2 = zeros(numel(controllers), 1);
ReconRMSE_Q1 = zeros(numel(controllers), 1);
ReconRMSE_Q2 = zeros(numel(controllers), 1);

for k = 1:numel(controllers)
    fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
    results{k} = run_closed_loop_case(p, controllers{k});
    modalObs{k} = run_modal_state_eso_analysis(results{k}, p);
    names{k} = results{k}.label;

    M = modalObs{k}.metrics;
    RMSE_Q1(k) = M.RMSE_q_mm(1);
    Peak_Q1(k) = M.Peak_q_mm(1);
    RMSE_Q2(k) = M.RMSE_q_mm(2);
    Peak_Q2(k) = M.Peak_q_mm(2);
    RMSE_dQ1(k) = M.RMSE_dq_mm_s(1);
    Peak_dQ1(k) = M.Peak_dq_mm_s(1);
    RMSE_dQ2(k) = M.RMSE_dq_mm_s(2);
    Peak_dQ2(k) = M.Peak_dq_mm_s(2);
    ReconRMSE_Q1(k) = M.ReconRMSE_q_mm(1);
    ReconRMSE_Q2(k) = M.ReconRMSE_q_mm(2);
end

T = table(names, RMSE_Q1, Peak_Q1, RMSE_Q2, Peak_Q2, RMSE_dQ1, Peak_dQ1, RMSE_dQ2, Peak_dQ2, ReconRMSE_Q1, ReconRMSE_Q2);
disp(T);

mainIdx = find(strcmpi(controllers, 'lnftsmc_eso'), 1);
if isempty(mainIdx)
    mainIdx = 1;
end
mainObs = modalObs{mainIdx};
zoomWin = local_time_zoom_window(mainObs.t);

figure('Name', 'Modal-state ESO - q1 main method', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, mainObs.t, 1000 * mainObs.qTrue(:,1), 'k-', 'LineWidth', 1.2, 'DisplayName', 'q_1 true');
plot(ax, mainObs.t, 1000 * mainObs.qHat(:,1), 'LineWidth', 1.1, 'DisplayName', 'q_1 ESO');
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_1 (mm)');
title(ax, [results{mainIdx}.label, ': modal-state ESO on q_1']);
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Modal-state ESO - q2 main method', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, mainObs.t, 1000 * mainObs.qTrue(:,2), 'k-', 'LineWidth', 1.2, 'DisplayName', 'q_2 true');
plot(ax, mainObs.t, 1000 * mainObs.qHat(:,2), 'LineWidth', 1.1, 'DisplayName', 'q_2 ESO');
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_2 (mm)');
title(ax, [results{mainIdx}.label, ': modal-state ESO on q_2']);
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Modal-state ESO - dq1 main method', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, mainObs.t, 1000 * mainObs.dqTrue(:,1), 'k-', 'LineWidth', 1.2, 'DisplayName', 'dq_1 true');
plot(ax, mainObs.t, 1000 * mainObs.dqHat(:,1), 'LineWidth', 1.1, 'DisplayName', 'dq_1 ESO');
xlabel(ax, 'Time (s)'); ylabel(ax, 'dq_1 (mm/s)');
title(ax, [results{mainIdx}.label, ': modal-state ESO on dq_1']);
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Modal-state ESO - dq2 main method', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, mainObs.t, 1000 * mainObs.dqTrue(:,2), 'k-', 'LineWidth', 1.2, 'DisplayName', 'dq_2 true');
plot(ax, mainObs.t, 1000 * mainObs.dqHat(:,2), 'LineWidth', 1.1, 'DisplayName', 'dq_2 ESO');
xlabel(ax, 'Time (s)'); ylabel(ax, 'dq_2 (mm/s)');
title(ax, [results{mainIdx}.label, ': modal-state ESO on dq_2']);
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Modal-state ESO error - q1', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    plot(ax, modalObs{k}.t, 1000 * modalObs{k}.errQ(:,1), 'LineWidth', 1.1, 'DisplayName', results{k}.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_{q_1} (mm)');
title(ax, 'q_1 estimation error');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'southwest');

figure('Name', 'Modal-state ESO error - q2', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    plot(ax, modalObs{k}.t, 1000 * modalObs{k}.errQ(:,2), 'LineWidth', 1.1, 'DisplayName', results{k}.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_{q_2} (mm)');
title(ax, 'q_2 estimation error');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Modal-state ESO error - dq1', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    plot(ax, modalObs{k}.t, 1000 * modalObs{k}.errDQ(:,1), 'LineWidth', 1.1, 'DisplayName', results{k}.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_{dq_1} (mm/s)');
title(ax, 'dq_1 estimation error');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

figure('Name', 'Modal-state ESO error - dq2', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    plot(ax, modalObs{k}.t, 1000 * modalObs{k}.errDQ(:,2), 'LineWidth', 1.1, 'DisplayName', results{k}.label);
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_{dq_2} (mm/s)');
title(ax, 'dq_2 estimation error');
legend(ax, 'Location', 'best');
add_time_zoom_inset(ax, zoomWin, 'northeast');

function zoomWin = local_time_zoom_window(t)
t = t(:);
span = max(t(end) - t(1), eps);
zoomWin = [t(1), min(t(1) + min(0.20 * span, 0.8), t(end))];
end
