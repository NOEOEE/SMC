clearvars -except ans;
clc;

p = get_sim_params('nominal');
controllers = {'lnftsmc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};

fprintf('R2021b debug run: one controller at a time\n');
for k = 1:numel(controllers)
    fprintf('\n---- %d/%d : %s ----\n', k, numel(controllers), controllers{k});
    out = run_closed_loop_case(p, controllers{k}); %#ok<NASGU>
    fprintf('done: %s\n', controllers{k});
end

fprintf('All controller runs completed.\n');
