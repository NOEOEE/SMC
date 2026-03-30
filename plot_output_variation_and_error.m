function plot_output_variation_and_error(out, p, varargin)
%PLOT_OUTPUT_VARIATION_AND_ERROR
% Draw single-axis time-response figures for
% 1) angle output,
% 2) displacement output,
% 3) output variations relative to the initial value,
% 4) tracking-error curves.
%
% Inputs
%   out : result struct returned by run_closed_loop_case
%   p   : parameter struct from get_sim_params
%
% Optional name-value pairs
%   'ShowWholeBeam'  : true/false, default true
%   'ShowRates'      : true/false, default false
%   'FigurePrefix'   : char/string, default out.label
%
% Notes
% - y(:,1)      : angle output y1 = theta (rad)
% - y(:,2)      : controller-side vibration output y2_ctrl (mm)
% - yGlobal(:,2): whole-beam vibration descriptor y2_global (mm)
% - error curves are defined as e = y - yd

if nargin < 2
    error('plot_output_variation_and_error requires at least out and p.');
end

opt.ShowWholeBeam = true;
opt.ShowRates = false;
opt.FigurePrefix = '';
if ~isempty(varargin)
    opt = local_parse_inputs(opt, varargin{:});
end

if isempty(opt.FigurePrefix)
    if isfield(out, 'label') && ~isempty(out.label)
        opt.FigurePrefix = char(out.label);
    else
        opt.FigurePrefix = 'Closed-loop response';
    end
end

t = out.t(:);
y = out.y;
yd = out.yd;
dy = out.dy;
dyd = out.dyd;

e = y - yd;
ed = dy - dyd;

dTheta = y(:,1) - y(1,1);
dY2Ctrl = y(:,2) - y(1,2);

if isfield(out, 'yGlobal') && ~isempty(out.yGlobal)
    yGlobal = out.yGlobal;
    dY2Global = yGlobal(:,2) - yGlobal(1,2);
    e2Global = yGlobal(:,2) - yd(:,2);
else
    yGlobal = [];
    dY2Global = [];
    e2Global = [];
end

eb2 = [];
if isfield(p, 'ctrl') && isfield(p.ctrl, 'prop') && isfield(p.ctrl.prop, 'eb') && numel(p.ctrl.prop.eb) >= 2
    eb2 = p.ctrl.prop.eb(2);
end

% 1) angle output
figure('Name', [opt.FigurePrefix, ' - angle output'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, y(:,1), 'LineWidth', 1.5, 'DisplayName', 'y_1 = \theta');
plot(ax, t, yd(:,1), '--', 'LineWidth', 1.3, 'DisplayName', 'y_{1d}');
xlabel(ax, 'Time (s)'); ylabel(ax, 'Angle (rad)');
title(ax, [opt.FigurePrefix, ': angle output']);
legend(ax, 'Location', 'best');

% 2) angle variation relative to initial value
figure('Name', [opt.FigurePrefix, ' - angle variation'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, dTheta, 'LineWidth', 1.5, 'DisplayName', '\Delta\theta = \theta(t)-\theta(0)');
xlabel(ax, 'Time (s)'); ylabel(ax, '\Delta\theta (rad)');
title(ax, [opt.FigurePrefix, ': angle variation relative to initial value']);
legend(ax, 'Location', 'best');

% 3) controller-side displacement output
figure('Name', [opt.FigurePrefix, ' - controller-side displacement'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, y(:,2), 'LineWidth', 1.5, 'DisplayName', 'y_{2,c}');
plot(ax, t, yd(:,2), '--', 'LineWidth', 1.3, 'DisplayName', 'y_{2d}');
if ~isempty(eb2)
    plot(ax, t,  eb2 * ones(size(t)), '--', 'LineWidth', 1.0, 'DisplayName', '+e_b');
    plot(ax, t, -eb2 * ones(size(t)), '--', 'LineWidth', 1.0, 'DisplayName', '-e_b');
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'Displacement (mm)');
title(ax, [opt.FigurePrefix, ': controller-side displacement output']);
legend(ax, 'Location', 'best');

% 4) controller-side displacement variation
figure('Name', [opt.FigurePrefix, ' - controller-side displacement variation'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, dY2Ctrl, 'LineWidth', 1.5, 'DisplayName', '\Delta y_{2,c} = y_{2,c}(t)-y_{2,c}(0)');
xlabel(ax, 'Time (s)'); ylabel(ax, '\Delta y_{2,c} (mm)');
title(ax, [opt.FigurePrefix, ': controller-side displacement variation']);
legend(ax, 'Location', 'best');

% 5) whole-beam displacement output
if opt.ShowWholeBeam && ~isempty(yGlobal)
    figure('Name', [opt.FigurePrefix, ' - whole-beam displacement'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, yGlobal(:,2), 'LineWidth', 1.5, 'DisplayName', 'y_{2,g}');
    plot(ax, t, yd(:,2), '--', 'LineWidth', 1.3, 'DisplayName', 'reference zero line');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'Whole-beam displacement (mm)');
    title(ax, [opt.FigurePrefix, ': whole-beam vibration descriptor']);
    legend(ax, 'Location', 'best');

    figure('Name', [opt.FigurePrefix, ' - whole-beam displacement variation'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, dY2Global, 'LineWidth', 1.5, 'DisplayName', '\Delta y_{2,g} = y_{2,g}(t)-y_{2,g}(0)');
    xlabel(ax, 'Time (s)'); ylabel(ax, '\Delta y_{2,g} (mm)');
    title(ax, [opt.FigurePrefix, ': whole-beam displacement variation']);
    legend(ax, 'Location', 'best');
end

% 6) error curves
figure('Name', [opt.FigurePrefix, ' - angle tracking error'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, e(:,1), 'LineWidth', 1.5, 'DisplayName', 'e_1 = y_1 - y_{1d}');
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_1 (rad)');
title(ax, [opt.FigurePrefix, ': angle tracking error']);
legend(ax, 'Location', 'best');

figure('Name', [opt.FigurePrefix, ' - displacement tracking error'], 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
plot(ax, t, e(:,2), 'LineWidth', 1.5, 'DisplayName', 'e_2 = y_{2,c} - y_{2d}');
if ~isempty(eb2)
    plot(ax, t,  eb2 * ones(size(t)), '--', 'LineWidth', 1.0, 'DisplayName', '+e_b');
    plot(ax, t, -eb2 * ones(size(t)), '--', 'LineWidth', 1.0, 'DisplayName', '-e_b');
end
xlabel(ax, 'Time (s)'); ylabel(ax, 'e_2 (mm)');
title(ax, [opt.FigurePrefix, ': controller-side displacement tracking error']);
legend(ax, 'Location', 'best');

if opt.ShowWholeBeam && ~isempty(yGlobal)
    figure('Name', [opt.FigurePrefix, ' - whole-beam displacement deviation'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, e2Global, 'LineWidth', 1.5, 'DisplayName', 'e_{2,g} = y_{2,g} - y_{2d}');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'e_{2,g} (mm)');
    title(ax, [opt.FigurePrefix, ': whole-beam displacement deviation']);
    legend(ax, 'Location', 'best');
end

% 7) optional rate curves
if opt.ShowRates
    figure('Name', [opt.FigurePrefix, ' - angle rate'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, dy(:,1), 'LineWidth', 1.5, 'DisplayName', '\dot{y}_1');
    plot(ax, t, dyd(:,1), '--', 'LineWidth', 1.3, 'DisplayName', '\dot{y}_{1d}');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'Angular rate (rad/s)');
    title(ax, [opt.FigurePrefix, ': angle rate']);
    legend(ax, 'Location', 'best');

    figure('Name', [opt.FigurePrefix, ' - displacement rate'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, dy(:,2), 'LineWidth', 1.5, 'DisplayName', '\dot{y}_{2,c}');
    plot(ax, t, dyd(:,2), '--', 'LineWidth', 1.3, 'DisplayName', '\dot{y}_{2d}');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'Rate (mm/s)');
    title(ax, [opt.FigurePrefix, ': controller-side displacement rate']);
    legend(ax, 'Location', 'best');

    figure('Name', [opt.FigurePrefix, ' - error rates'], 'Color', 'w');
    ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, t, ed(:,1), 'LineWidth', 1.5, 'DisplayName', '\dot{e}_1');
    plot(ax, t, ed(:,2), 'LineWidth', 1.5, 'DisplayName', '\dot{e}_2');
    xlabel(ax, 'Time (s)'); ylabel(ax, 'Error rate');
    title(ax, [opt.FigurePrefix, ': error-rate curves']);
    legend(ax, 'Location', 'best');
end
end

function opt = local_parse_inputs(opt, varargin)
if mod(numel(varargin), 2) ~= 0
    error('Optional arguments must be supplied as name-value pairs.');
end
for k = 1:2:numel(varargin)
    name = lower(string(varargin{k}));
    value = varargin{k+1};
    switch name
        case "showwholebeam"
            opt.ShowWholeBeam = logical(value);
        case "showrates"
            opt.ShowRates = logical(value);
        case "figureprefix"
            opt.FigurePrefix = char(string(value));
        otherwise
            error('Unknown option: %s', varargin{k});
    end
end
end
