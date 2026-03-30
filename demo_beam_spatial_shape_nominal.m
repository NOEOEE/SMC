clearvars -except ans;
clc;

% Demo: generate beam spatial displacement shape plots for the nominal case.
% Two figures are produced:
%   1) ln-NFTSMC+ESO closed-loop beam shapes
%   2) Open-loop beam shapes
%
% This avoids 3D figures and uses single 2D spatial curves that are easier
% to place directly in the paper.

p = get_sim_params('nominal');

outCtrl = run_closed_loop_case(p, 'lnftsmc_eso');
outOpen = run_closed_loop_case(p, 'open_loop');

% Recommended snapshot times focused on the early vibration-suppression stage.
tPlot = [0, 0.02, 0.04, 0.08, 0.15, 0.30];

plot_beam_spatial_snapshots(outCtrl, p, tPlot, 240, 'mm', ...
    'Nominal case - beam spatial displacement snapshots (ln-NFTSMC+ESO)');

plot_beam_spatial_snapshots(outOpen, p, tPlot, 240, 'mm', ...
    'Nominal case - beam spatial displacement snapshots (open-loop baseline)');
