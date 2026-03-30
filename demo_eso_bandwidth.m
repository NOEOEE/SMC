clearvars -except ans;
clc;

pBase = get_sim_params('nominal');
woScale = [0.8, 1.0, 1.2, 1.4];
results = cell(numel(woScale), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 4: ESO bandwidth sweep\n');
fprintf('Controller: ln-NFTSMC + ESO\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('==============================================\n');

for k = 1:numel(woScale)
    p = pBase;
    p.eso.wo(2) = pBase.eso.wo(2) * woScale(k);
    results{k} = run_closed_loop_case(p, 'lnftsmc_eso');
    results{k}.label = sprintf('ln-NFTSMC+ESO (w_{o2} x %.1f)', woScale(k));
end

plot_bandwidth_compare(results, pBase, woScale);

names   = cell(numel(results), 1);
PeakDz2 = zeros(numel(results), 1);
IAE_y2Global  = zeros(numel(results), 1);
PeakU2  = zeros(numel(results), 1);

for k = 1:numel(results)
    r = results{k};
    names{k}        = r.label;
    PeakDz2(k)      = r.metrics.PeakAbsResidual2;
    IAE_y2Global(k) = r.metrics.IAE_y2Global;
    PeakU2(k)       = r.metrics.PeakAbsU2;
end

T = table(names, PeakDz2, IAE_y2Global, PeakU2);
disp(T);

