function out = demo_output_variation_and_error(caseName, controllerName)
%DEMO_OUTPUT_VARIATION_AND_ERROR
% One-click demo for drawing
% - angle response
% - displacement response
% - relative variation curves
% - tracking error curves
%
% Examples
%   demo_output_variation_and_error
%   demo_output_variation_and_error('nominal', 'lnftsmc_eso')
%   demo_output_variation_and_error('disturbance', 'pd_eso')

if nargin < 1 || isempty(caseName)
    caseName = 'nominal';
end
if nargin < 2 || isempty(controllerName)
    controllerName = 'lnftsmc_eso';
end

p = get_sim_params(caseName);
out = run_closed_loop_case(p, controllerName);

figPrefix = sprintf('%s - %s', out.label, p.caseName);
plot_output_variation_and_error(out, p, ...
    'ShowWholeBeam', true, ...
    'ShowRates', false, ...
    'FigurePrefix', figPrefix);

fprintf('\n==============================================\n');
fprintf('Angle / displacement / error plots generated\n');
fprintf('Case       : %s\n', p.caseName);
fprintf('Controller : %s\n', out.label);
fprintf('Figures include:\n');
fprintf('  1) angle output y1 and reference\n');
fprintf('  2) angle variation relative to initial value\n');
fprintf('  3) controller-side displacement y2_ctrl and reference\n');
fprintf('  4) controller-side displacement variation\n');
fprintf('  5) whole-beam displacement y2_global\n');
fprintf('  6) whole-beam displacement variation\n');
fprintf('  7) angle error e1\n');
fprintf('  8) displacement error e2 (controller-side)\n');
fprintf('  9) whole-beam displacement deviation from the desired zero line\n');
fprintf('==============================================\n');
end
