function plot_paper_style_validation(outShaped, outUnshaped, p)
%PLOT_PAPER_STYLE_VALIDATION Single-axis literature-inspired validation figures.

figure('Name', 'Paper-style validation - tracking error', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outShaped.t, outShaped.y(:,1) - outShaped.yd(:,1), 'LineWidth', 1.3, 'DisplayName', 'e_1');
plot(ax, outShaped.t, outShaped.dy(:,1) - outShaped.dyd(:,1), 'LineWidth', 1.1, 'DisplayName', 'de_1/dt');
xlabel(ax, 'Time (s)'); ylabel(ax, 'tracking error');
title(ax, 'Channel 1 tracking error and rate error');
legend(ax, 'Location', 'best');

figure('Name', 'Paper-style validation - disturbance estimation', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
zhatUsed2 = outShaped.dTrue(:,2) - outShaped.residual(:,2);
plot(ax, outShaped.t, outShaped.dTrue(:,2), 'k--', 'LineWidth', 1.3, 'DisplayName', 'd_{2,true}');
plot(ax, outShaped.t, zhatUsed2, 'LineWidth', 1.2, 'DisplayName', '\rho_2 z_{23}');
plot(ax, outShaped.t, outShaped.residual(:,2), 'LineWidth', 1.0, 'DisplayName', 'd_2-\rho_2 z_{23}');
xlabel(ax, 'Time (s)'); ylabel(ax, 'disturbance / residual');
title(ax, 'Channel 2 disturbance estimation');
legend(ax, 'Location', 'best');

figure('Name', 'Paper-style validation - control inputs', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outShaped.t, outShaped.u(:,1), 'LineWidth', 1.2, 'DisplayName', 'u_1');
plot(ax, outShaped.t, outShaped.u(:,2), 'LineWidth', 1.2, 'DisplayName', 'u_2');
xlabel(ax, 'Time (s)'); ylabel(ax, 'control input');
title(ax, 'Control inputs');
legend(ax, 'Location', 'best');

figure('Name', 'Paper-style validation - sliding surface', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outShaped.t, outShaped.s(:,1), 'LineWidth', 1.2, 'DisplayName', 's_1');
plot(ax, outShaped.t, outShaped.s(:,2), 'LineWidth', 1.2, 'DisplayName', 's_2');
xlabel(ax, 'Time (s)'); ylabel(ax, 'sliding surface');
title(ax, 'Sliding-surface evolution');
legend(ax, 'Location', 'best');

figure('Name', 'Input-shaper ablation - q1', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outUnshaped.t, 1000 * outUnshaped.x(:,3), '--', 'LineWidth', 1.2, 'DisplayName', 'q_1 no shaper');
plot(ax, outShaped.t, 1000 * outShaped.x(:,3), '-', 'LineWidth', 1.3, 'DisplayName', 'q_1 + ZVD');
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_1 (mm-equivalent)');
title(ax, 'First flexible mode comparison');
legend(ax, 'Location', 'best');

figure('Name', 'Input-shaper ablation - q2', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outUnshaped.t, 1000 * outUnshaped.x(:,4), '--', 'LineWidth', 1.2, 'DisplayName', 'q_2 no shaper');
plot(ax, outShaped.t, 1000 * outShaped.x(:,4), '-', 'LineWidth', 1.3, 'DisplayName', 'q_2 + ZVD');
xlabel(ax, 'Time (s)'); ylabel(ax, 'q_2 (mm-equivalent)');
title(ax, 'Second flexible mode comparison');
legend(ax, 'Location', 'best');

figure('Name', 'Input-shaper ablation - whole-beam vibration', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outUnshaped.t, outUnshaped.yGlobal(:,2), '--', 'LineWidth', 1.2, 'DisplayName', 'y_{2,g} no shaper');
plot(ax, outShaped.t, outShaped.yGlobal(:,2), '-', 'LineWidth', 1.3, 'DisplayName', 'y_{2,g} + ZVD');
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_{2,g} (mm)');
title(ax, 'Whole-beam vibration descriptor');
legend(ax, 'Location', 'best');

figure('Name', 'Input-shaper ablation - channel 1 response', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, outUnshaped.t, outUnshaped.y(:,1), '--', 'LineWidth', 1.2, 'DisplayName', 'y_1 no shaper');
plot(ax, outShaped.t, outShaped.y(:,1), '-', 'LineWidth', 1.3, 'DisplayName', 'y_1 + ZVD');
plot(ax, outShaped.t, outShaped.yd(:,1), 'k:', 'LineWidth', 1.0, 'DisplayName', 'y_{1d} shaped');
if ~isempty(p) && isfield(p, 'shaper') && p.shaper.enable
    noRef = arrayfun(@(tt) base_reference_command(tt, p), outShaped.t, 'UniformOutput', false);
    yRefNo = cellfun(@(r) r.y(1), noRef);
    plot(ax, outShaped.t, yRefNo(:), 'Color', [0.4 0.4 0.4], 'LineStyle', '-.', 'LineWidth', 1.0, 'DisplayName', 'y_{1d} raw');
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'y_1 (rad)');
title(ax, 'Channel 1 response with/without shaping');
legend(ax, 'Location', 'best');
end
