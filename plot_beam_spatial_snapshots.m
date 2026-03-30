function fig = plot_beam_spatial_snapshots(result, p, tPlot, nX, unitName, figTitle)
%PLOT_BEAM_SPATIAL_SNAPSHOTS Plot beam spatial displacement shapes at selected times.
%
% Main purpose:
%   Draw 2D beam shape curves w(x,t_k) versus x/L for several selected times.
%   This is suitable for paper figures and follows the user's current plotting
%   preference: single figure, no subplot, no 3D surface.
%
% Inputs:
%   result   - output struct from run_closed_loop_case(...)
%   p        - parameter struct from get_sim_params(...)
%   tPlot    - vector of snapshot times (s). If empty, a default early-time
%              set is generated automatically from the first-mode period.
%   nX       - number of spatial points along the beam. Default: 200
%   unitName - 'mm', 'um', or 'm'. Default: 'mm'
%   figTitle - figure title string. If empty, generated automatically.
%
% Example:
%   p = get_sim_params('nominal');
%   out = run_closed_loop_case(p, 'lnftsmc_eso');
%   plot_beam_spatial_snapshots(out, p, [0 0.02 0.04 0.08 0.15 0.30], 200, 'mm');

if nargin < 3 || isempty(tPlot)
    tPlot = local_default_snapshot_times(result, p);
end
if nargin < 4 || isempty(nX)
    nX = 200;
end
if nargin < 5 || isempty(unitName)
    unitName = 'mm';
end
if nargin < 6
    figTitle = '';
end

% Keep only valid unique times inside the simulated interval.
t0 = result.t(1);
tf = result.t(end);
tPlot = unique(tPlot(:).');
tPlot = tPlot(tPlot >= t0 & tPlot <= tf);
if isempty(tPlot)
    tPlot = local_default_snapshot_times(result, p);
    tPlot = tPlot(tPlot >= t0 & tPlot <= tf);
end

[~, XX, WW, tSel] = reconstruct_beam_field(result, p, nX, numel(tPlot), unitName, tPlot);
x = XX(:,1);
xNorm = x / p.beam.L;

fig = figure('Name', 'Beam spatial displacement snapshots', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(tSel)
    plot(ax, xNorm, WW(:,k), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('t = %.4g s', tSel(k)));
end

xlabel(ax, 'Normalized beam coordinate x / L');
ylabel(ax, local_unit_label(unitName));
if isempty(figTitle)
    if isfield(result, 'label') && ~isempty(result.label)
        title(ax, ['Beam spatial displacement snapshots - ', result.label]);
    else
        title(ax, 'Beam spatial displacement snapshots');
    end
else
    title(ax, figTitle);
end
legend(ax, 'Location', 'best');
end

function tPlot = local_default_snapshot_times(result, p)
% Emphasize the early transient, because later the beam is close to rest.
if isfield(p, 'beam') && isfield(p.beam, 'fn') && ~isempty(p.beam.fn)
    T1 = 1 / p.beam.fn(1);
else
    T1 = max((result.t(end) - result.t(1)) / 20, 0.02);
end

tCand = [0, 0.5*T1, 1.0*T1, 2.0*T1, 4.0*T1, 8.0*T1];
% Also add the time of the maximum whole-beam vibration to make the shape informative.
if isfield(result, 'yGlobal') && size(result.yGlobal,2) >= 2
    [~, idxPeak] = max(abs(result.yGlobal(:,2)));
    tPeak = result.t(idxPeak);
    tCand = [tCand, tPeak]; %#ok<AGROW>
end

tCand = unique(sort(tCand));
tPlot = tCand(tCand >= result.t(1) & tCand <= result.t(end));
if numel(tPlot) > 6
    % Keep the first five early-time points and the peak point.
    tPlot = unique([tPlot(1:min(5, numel(tPlot)-1)), tPlot(end)]);
end
end

function labelText = local_unit_label(unitName)
switch lower(unitName)
    case 'mm'
        labelText = 'Beam displacement w(x,t) (mm)';
    case 'um'
        labelText = 'Beam displacement w(x,t) (\mum)';
    otherwise
        labelText = 'Beam displacement w(x,t) (m)';
end
end
