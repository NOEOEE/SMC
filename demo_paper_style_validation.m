clearvars -except ans;
clc;

pBase = get_sim_params('nominal');
pBase.sim.outputDt = 5e-4;
pBase.sim.tEnd = min(pBase.sim.tEnd, 4.0);

% Literature-inspired maneuver setting: isolate command-induced vibration so
% the benefit of the input shaper is visible.
x0 = pBase.init.xPlant;
x0(1:6) = 0;
pBase.init.xPlant = x0;
y0 = state_to_outputs(x0, pBase);
pBase.init.z0 = [y0.y(1); 0; 0; y0.y(2); 0; 0];
pBase.plot.enableMainPlots = false;

pNo = pBase;
pNo.shaper.enable = false;

pYes = pBase;
pYes.shaper.enable = true;

fprintf('\n==============================================\n');
fprintf('Experiment 10: paper-style integrated validation\n');
fprintf('Main method: ln-NFTSMC + ESO\n');
fprintf('Added literature-inspired ZVD input-shaper ablation on channel 1 reference\n');
fprintf('Validation items: tracking, disturbance estimation, control input, sliding surface, vibration suppression\n');
fprintf('==============================================\n');

outNo = run_closed_loop_case(pNo, 'lnftsmc_eso');
outYes = run_closed_loop_case(pYes, 'lnftsmc_eso');

plot_paper_style_validation(outYes, outNo, pYes);

modalNo = calc_modal_metrics(outNo);
modalYes = calc_modal_metrics(outYes);
peakQ1No = modalNo.PeakAbsQ1;
iaeQ1No = modalNo.IAE_Q1;
peakQ2No = modalNo.PeakAbsQ2;
iaeQ2No = modalNo.IAE_Q2;
peakY2No = outNo.metrics.PeakAbsY2Global;
iaeY2No = outNo.metrics.IAE_y2Global;
peakQ1Yes = modalYes.PeakAbsQ1;
iaeQ1Yes = modalYes.IAE_Q1;
peakQ2Yes = modalYes.PeakAbsQ2;
iaeQ2Yes = modalYes.IAE_Q2;
peakY2Yes = outYes.metrics.PeakAbsY2Global;
iaeY2Yes = outYes.metrics.IAE_y2Global;

sh = get_zvd_shaper(pYes.shaper.wn, pYes.shaper.zeta);

CaseName = {'ln-NFTSMC+ESO no shaper'; 'ln-NFTSMC+ESO + ZVD shaper'};
PeakQ1_mm = [peakQ1No; peakQ1Yes];
IAE_Q1_mm_s = [iaeQ1No; iaeQ1Yes];
PeakQ2_mm = [peakQ2No; peakQ2Yes];
IAE_Q2_mm_s = [iaeQ2No; iaeQ2Yes];
PeakY2Global_mm = [peakY2No; peakY2Yes];
IAE_Y2Global_mm_s = [iaeY2No; iaeY2Yes];
PeakResidual2 = [max(abs(outNo.residual(:,2))); max(abs(outYes.residual(:,2)))];
PeakU2 = [max(abs(outNo.u(:,2))); max(abs(outYes.u(:,2)))];
T = table(CaseName, PeakQ1_mm, IAE_Q1_mm_s, PeakQ2_mm, IAE_Q2_mm_s, PeakY2Global_mm, IAE_Y2Global_mm_s, PeakResidual2, PeakU2);
disp(T);

SuppressionByPeakQ1_pct = 100 * (1 - peakQ1Yes / max(peakQ1No, eps));
SuppressionByIAEQ1_pct = 100 * (1 - iaeQ1Yes / max(iaeQ1No, eps));
SuppressionByPeakQ2_pct = 100 * (1 - peakQ2Yes / max(peakQ2No, eps));
SuppressionByIAEQ2_pct = 100 * (1 - iaeQ2Yes / max(iaeQ2No, eps));
SuppressionByPeakY2_pct = 100 * (1 - peakY2Yes / max(peakY2No, eps));
SuppressionByIAEY2_pct = 100 * (1 - iaeY2Yes / max(iaeY2No, eps));

fprintf('\nZVD shaper parameters (first flexible mode):\n');
fprintf('  wn   = %.6f rad/s\n', sh.wn);
fprintf('  zeta = %.6f\n', sh.zeta);
fprintf('  A    = [%.6f, %.6f, %.6f]\n', sh.A(1), sh.A(2), sh.A(3));
fprintf('  tau  = [%.6f, %.6f, %.6f] s\n', sh.tDelay(1), sh.tDelay(2), sh.tDelay(3));

fprintf('\nSuppression summary relative to no-shaper case:\n');
fprintf('  Peak |q1| suppression      = %.2f %%\n', SuppressionByPeakQ1_pct);
fprintf('  IAE  |q1| suppression      = %.2f %%\n', SuppressionByIAEQ1_pct);
fprintf('  Peak |q2| suppression      = %.2f %%\n', SuppressionByPeakQ2_pct);
fprintf('  IAE  |q2| suppression      = %.2f %%\n', SuppressionByIAEQ2_pct);
fprintf('  Peak y2_global suppression = %.2f %%\n', SuppressionByPeakY2_pct);
fprintf('  IAE  y2_global suppression = %.2f %%\n', SuppressionByIAEY2_pct);
