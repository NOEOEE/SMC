function [TT, XX, WW, tSel] = reconstruct_beam_field(result, p, nX, nT, unitName, tArg)
%RECONSTRUCT_BEAM_FIELD Rebuild whole-beam displacement field from modal states.
% Supports dense interpolation on a specified time window/grid so the 3D figure
% can clearly show the transient from vibration to rest.
%
% tArg:
%   [] / omitted -> use full simulation horizon with nT samples
%   scalar       -> use linspace(t0, min(tArg, tEnd), nT)
%   vector       -> use the provided time grid directly

if nargin < 3 || isempty(nX)
    nX = 120;
end
if nargin < 4 || isempty(nT)
    nT = 360;
end
if nargin < 5 || isempty(unitName)
    unitName = 'mm';
end
if nargin < 6
    tArg = [];
end

xg = linspace(0, p.beam.L, nX).';

if isempty(tArg)
    tSel = linspace(result.t(1), result.t(end), nT).';
elseif isscalar(tArg)
    tEndUse = min(max(tArg, result.t(1) + eps), result.t(end));
    tSel = linspace(result.t(1), tEndUse, nT).';
else
    tSel = tArg(:);
    tSel = tSel(tSel >= result.t(1) & tSel <= result.t(end));
    if numel(tSel) < 2
        tSel = linspace(result.t(1), result.t(end), nT).';
    end
end

q1 = interp1(result.t(:), result.x(:,3), tSel, 'pchip');
q2 = interp1(result.t(:), result.x(:,4), tSel, 'pchip');
q  = [q1.'; q2.'];

phi1 = beam_mode_shape(1, xg, p.beam);
phi2 = beam_mode_shape(2, xg, p.beam);
W = phi1 * q(1,:) + phi2 * q(2,:);

switch lower(unitName)
    case 'mm'
        W = 1000 * W;
    case 'um'
        W = 1e6 * W;
    otherwise
        % keep meters
end

[TT, XX] = meshgrid(tSel, xg);
WW = W;
end
