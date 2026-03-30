clearvars -except ans;
clc;

p = get_sim_params('nominal');
beam = p.beam;
meas = p.measure;

fprintf('\n==============================================\n');
fprintf('Demo: whole-beam uniform-weight measurement setup\n');
fprintf('==============================================\n');
fprintf('Primary descriptor: y2_global = 1000 * sum_i alpha_i * |w(x_i,t)|\n');
fprintf('Weight rule: uniform weighting over measured points, alpha_i = 1/N\n');
fprintf('Measured points x_i/L = [');
fprintf(' %.2f', meas.xNorm); fprintf(' ]\n');
fprintf('Uniform weights alpha_i = ['); fprintf(' %.4f', meas.weights); fprintf(' ]\n');

Point = (1:meas.numPoints).';
x_over_L = meas.xNorm(:);
x_m = meas.x(:);
alpha = meas.weights(:);
phi1 = meas.PhiGrid(:,1);
phi2 = meas.PhiGrid(:,2);
Tmeas = table(Point, x_over_L, x_m, alpha, phi1, phi2);
disp(Tmeas);

xDense = linspace(0, beam.L, 240).';
phi1Dense = beam_mode_shape(1, xDense, beam);
phi2Dense = beam_mode_shape(2, xDense, beam);

figure('Name', 'Whole-beam uniform-weight measurement - points', 'Color', 'w');
hold on; grid on; box on;
plot(xDense / beam.L, phi1Dense, 'LineWidth', 1.6, 'DisplayName', 'Mode 1');
plot(xDense / beam.L, phi2Dense, 'LineWidth', 1.6, 'DisplayName', 'Mode 2');
plot(meas.xNorm, meas.PhiGrid(:,1), 'o', 'LineWidth', 1.4, 'HandleVisibility', 'off');
plot(meas.xNorm, meas.PhiGrid(:,2), 's', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('x / L');
ylabel('\phi_i(x)');
title('Measurement points used in the whole-beam descriptor');
legend('Location', 'best');

figure('Name', 'Whole-beam uniform-weight measurement - weights', 'Color', 'w');
hold on; grid on; box on;
bar(meas.xNorm, meas.weights, 0.55);
xlabel('x / L');
ylabel('\alpha_i');
title('Uniform weights over the selected beam points');

paperFigureMap = struct( ...
    'sourceName', 'Whole-beam uniform-weight measurement - points', ...
    'exportName', 'Fig01_measurement_points', ...
    'purpose', 'Measurement locations used to define the whole-beam descriptor y_{2,g}.');

Controller = string.empty(0,1); %#ok<NASGU>
paperTables = struct( ...
    'name', 'TableP01_measurement_points_and_weights', ...
    'table', Tmeas, ...
    'purpose', 'Measurement locations, uniform weights, and mode-shape ordinates used in y_{2,g}.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = { ...
    'The measurement-points figure is kept in the paper because it defines the reported whole-beam vibration descriptor.', ...
    'The uniform-weight bar chart is not exported as a paper figure because the same information is already captured by the table and the text alpha_i = 1/N.'};
