clearvars -except ans;
clc;

p = get_sim_params('nominal');
beam = p.beam;
meas = p.measure;

fprintf('\n==============================================\n');
fprintf('Physical parameter check\n');
fprintf('==============================================\n');
fprintf('f1 = %.4f Hz\n', beam.fn(1));
fprintf('f2 = %.4f Hz\n', beam.fn(2));

fprintf('\nM = diag([%.8f, %.8f])\n', beam.M(1,1), beam.M(2,2));
fprintf('C = diag([%.8f, %.8f])\n', beam.C(1,1), beam.C(2,2));
fprintf('K = diag([%.8f, %.8f])\n', beam.K(1,1), beam.K(2,2));

fprintf('\nPhi_s   = [%.8f, %.8f]\n', beam.Phi_s(1), beam.Phi_s(2));
fprintf('Phi_tip = [%.8f, %.8f]\n', beam.Phi_tip(1), beam.Phi_tip(2));

fprintf('\nGamma_p = [%.8e; %.8e]\n', beam.Gamma_p(1), beam.Gamma_p(2));
fprintf('Bp      = [%.8f; %.8f]\n', beam.Bp(1), beam.Bp(2));

fprintf('\nbTrue = [%.6f; %.6f]\n', p.plant.bTrue(1), p.plant.bTrue(2));
fprintf('b0    = [%.6f; %.6f]\n', p.plant.b0(1), p.plant.b0(2));

fprintf('\n==============================================\n');
fprintf('Whole-beam weighted vibration descriptor (highlight)\n');
fprintf('==============================================\n');
fprintf('y2_ctrl   = 1000 * Phi_s * q    (used inside controller / ESO)\n');
fprintf('y2_global = 1000 * sum_i alpha_i * |w(x_i,t)|\n');
fprintf('Weights alpha_i use a uniform weighting rule over the measured points.\n');
fprintf('That is, alpha_i = 1/N for i = 1,2,...,N, and the root point x=0 is not included.\n');
fprintf('Measured points x_i/L = [');
fprintf(' %.2f', meas.xNorm); fprintf(' ]\n');
fprintf('Virtual root point: x/L = %.2f, weight used in the reported sum = %.4f\n', ...
    meas.virtualRootXNorm, meas.virtualRootWeight);

Point = (1:meas.numPoints).';
x_over_L = meas.xNorm(:);
x_m = meas.x(:);
alpha = meas.weights(:);
phi1 = meas.PhiGrid(:,1);
phi2 = meas.PhiGrid(:,2);
Tmeas = table(Point, x_over_L, x_m, alpha, phi1, phi2);
disp(Tmeas);

fprintf('Sum of measured-point weights alpha_i  = %.6f\n', sum(meas.weights));
fprintf('Weighted linear modal coefficients     = [%.8f, %.8f]\n', meas.PhiEqBase(1), meas.PhiEqBase(2));
fprintf('Note: y2_global is the highlighted whole-beam vibration descriptor;\n');
fprintf('      controller safety boundary checks still use y2_ctrl.\n');
