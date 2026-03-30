function m = calc_metrics(t, yCtrl, ydCtrl, u, residual, y2Global)
%CALC_METRICS Basic performance indices.
%
% Controller-side output:
%   yCtrl(:,2) = original single-point output used in the controller / ESO.
%
% Whole-beam output:
%   y2Global   = weighted combination of absolute displacements at multiple
%                beam points. This is the highlighted performance metric.

if nargin < 6 || isempty(y2Global)
    y2Global = yCtrl(:,2);
end

eCtrl = yCtrl - ydCtrl;
T = max(t(end) - t(1), eps);

m.IAE_y1 = trapz(t, abs(eCtrl(:,1)));

m.IAE_y2Ctrl = trapz(t, abs(eCtrl(:,2)));
m.RMS_y2Ctrl = sqrt(trapz(t, yCtrl(:,2).^2) / T);
m.PeakAbsY2Ctrl = max(abs(yCtrl(:,2)));

m.IAE_y2Global = trapz(t, abs(y2Global(:)));
m.RMS_y2Global = sqrt(trapz(t, y2Global(:).^2) / T);
m.PeakAbsY2Global = max(abs(y2Global(:)));

% Primary aliases now point to the whole-beam descriptor.
m.IAE_y2 = m.IAE_y2Global;
m.RMS_y2 = m.RMS_y2Global;
m.PeakAbsY2 = m.PeakAbsY2Global;

m.PeakAbsY1 = max(abs(yCtrl(:,1)));
m.PeakAbsU1 = max(abs(u(:,1)));
m.PeakAbsU2 = max(abs(u(:,2)));
m.PeakAbsResidual1 = max(abs(residual(:,1)));
m.PeakAbsResidual2 = max(abs(residual(:,2)));
end

