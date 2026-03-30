function out = evaluate_beam_measurement(q, dq, meas)
%EVALUATE_BEAM_MEASUREMENT Evaluate the weighted whole-beam vibration descriptor.
%
% Inputs:
%   q  - modal displacement vector, size [nModes x 1] or [nModes x N]
%   dq - modal velocity vector, same size as q
%   meas - struct from build_beam_measurement.m
%
% Outputs (primary fields):
%   y2GlobalNormAbs     - normalized weighted combination of |w(x_i,t)|, in mm
%   y2GlobalIntegralAbs - direct integral-type weighted sum, in mm
%   y2WeightedLinear    - linear weighted combination (without abs), in mm
%   wPointsMm           - point displacements at the selected beam locations, in mm

if nargin < 2 || isempty(dq)
    dq = zeros(size(q));
end

q = reshape(q, size(meas.PhiGrid, 2), []);
dq = reshape(dq, size(meas.PhiGrid, 2), []);

wPoints = meas.PhiGrid * q;
dwPoints = meas.PhiGrid * dq;
absSmooth = sqrt(wPoints.^2 + meas.absSmoothEps^2);
dAbsSmooth = (wPoints .* dwPoints) ./ absSmooth;

weights = meas.weights(:);
rawWeights = meas.rawWeights(:);

out.wPoints = wPoints;
out.dwPoints = dwPoints;
out.absSmoothPoints = absSmooth;
out.dAbsSmoothPoints = dAbsSmooth;
out.pointContribNorm = absSmooth .* weights;
out.pointContribIntegral = absSmooth .* rawWeights;

out.y2GlobalNormAbs = 1000 * sum(out.pointContribNorm, 1);
out.dy2GlobalNormAbs = 1000 * sum(dAbsSmooth .* weights, 1);
out.y2GlobalIntegralAbs = 1000 * sum(out.pointContribIntegral, 1);
out.dy2GlobalIntegralAbs = 1000 * sum(dAbsSmooth .* rawWeights, 1);
out.y2WeightedLinear = 1000 * (meas.PhiEqBase * q);
out.dy2WeightedLinear = 1000 * (meas.PhiEqBase * dq);

out.wPointsMm = 1000 * out.wPoints;
out.pointContribNormMm = 1000 * out.pointContribNorm;
out.pointContribIntegralMm = 1000 * out.pointContribIntegral;
end

