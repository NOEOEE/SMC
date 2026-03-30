clc; clear; close all;

caseName = 'nominal';
controllers = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};

p = get_sim_params(caseName);
results = cell(numel(controllers), 1);

fprintf('\n==============================================\n');
fprintf('Multi-controller output comparison\n');
fprintf('Case: %s\n', caseName);
fprintf('Controllers: %s\n', strjoin(controllers, ' / '));
fprintf('Figures: y outputs + variation + error\n');
fprintf('==============================================\n');

for k = 1:numel(controllers)
    fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
    results{k} = run_closed_loop_case(p, controllers{k});
end

plot_controller_compare_outputs(results, p, caseName);
