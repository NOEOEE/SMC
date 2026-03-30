function m = calc_extended_metrics(out, eb2, settleBandY2Global)
%CALC_EXTENDED_METRICS Additional metrics for robustness / chattering studies.
%
% Whole-beam vibration descriptor (primary reported quantity):
%   out.yGlobal(:,2)
%
% Control-side boundary channel (used for barrier / ESO / safety checks):
%   out.yCtrl(:,2)

if nargin < 2 || isempty(eb2)
    eb2 = inf;
end
if nargin < 3 || isempty(settleBandY2Global)
    settleBandY2Global = 0.05;
end

m = out.metrics;

t = out.t(:);
y2Ctrl = out.yCtrl(:,2);
yd2Ctrl = out.yd(:,2);
y2Global = out.yGlobal(:,2);
u2 = out.u(:,2);
res2 = out.residual(:,2);

e2Ctrl = y2Ctrl - yd2Ctrl;
e2Global = y2Global;

m.IAE_y2Ctrl = trapz(t, abs(e2Ctrl));
m.RMS_y2Ctrl = sqrt(trapz(t, y2Ctrl.^2) / max(t(end) - t(1), eps));
m.PeakY2Ctrl = max(abs(y2Ctrl));
m.PeakE2Ctrl = max(abs(e2Ctrl));

m.IAE_y2Global = trapz(t, abs(e2Global));
m.RMS_y2Global = sqrt(trapz(t, y2Global.^2) / max(t(end) - t(1), eps));
m.PeakY2Global = max(abs(y2Global));
m.PeakE2Global = max(abs(e2Global));

% Primary aliases point to the whole-beam descriptor.
m.IAE_y2 = m.IAE_y2Global;
m.RMS_y2 = m.RMS_y2Global;
m.PeakY2 = m.PeakY2Global;
m.PeakE2 = m.PeakE2Global;

% Boundary / safety occupancy is still evaluated on the controller-side output.
m.RatioEbCtrl = m.PeakE2Ctrl / max(eb2, eps);
m.OverEbCtrl = max(m.PeakE2Ctrl - eb2, 0.0);
m.HitBoundaryCtrl = any(abs(e2Ctrl) >= eb2);
m.BoundaryMarginCtrl = eb2 - m.PeakE2Ctrl;

% Legacy aliases preserved for compatibility with older scripts.
m.RatioEb = m.RatioEbCtrl;
m.OverEb = m.OverEbCtrl;
m.HitBoundary = m.HitBoundaryCtrl;
m.BoundaryMargin = m.BoundaryMarginCtrl;

m.SettlingTimeY2Global = local_settling_time(t, abs(e2Global), settleBandY2Global);
m.SettlingTimeY2Ctrl = local_settling_time(t, abs(e2Ctrl), settleBandY2Global);
m.SettlingTimeY2 = m.SettlingTimeY2Global;

if numel(t) >= 2
    dt = diff(t);
    du2 = diff(u2);
    m.TVU2 = sum(abs(du2));
    m.ISVU2 = sum(du2.^2);
    m.RMSdU2 = sqrt(mean((du2 ./ max(dt, eps)).^2));
else
    m.TVU2 = NaN;
    m.ISVU2 = NaN;
    m.RMSdU2 = NaN;
end

T = max(t(end) - t(1), eps);
m.RMSU2 = sqrt(trapz(t, u2.^2) / T);
m.EnergyU2 = trapz(t, u2.^2);

m.RMSEstErr2 = sqrt(trapz(t, res2.^2) / T);
m.IAEEstErr2 = trapz(t, abs(res2));
m.PeakEstErr2 = max(abs(res2));
end

function ts = local_settling_time(t, signalAbs, band)
% Return the first time after which the signal stays inside the band.
ts = NaN;
if isempty(t) || isempty(signalAbs)
    return;
end
inside = signalAbs <= band;
for k = 1:numel(t)
    if all(inside(k:end))
        ts = t(k);
        return;
    end
end
end

