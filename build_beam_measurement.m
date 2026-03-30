function meas = build_beam_measurement(beam)
%BUILD_BEAM_MEASUREMENT Build the uniformly weighted whole-beam vibration descriptor.
%
% Uniform-weight definition used for the reported whole-beam index:
%   y_{2,g}(t) = 1000 * sum_i alpha_i * |w(x_i,t)|
% with
%   alpha_i = 1 / N,   i = 1,2,...,N
%
% The selected measured points are
%   x_i / L = [0.20, 0.40, 0.60, 0.80, 1.00]
%
% NOTE:
% - The clamped root x = 0 is not included in the weighted sum.
% - The controller / ESO still use y2_ctrl = 1000 * Phi_s * q.
% - This function only defines the highlighted whole-beam evaluation metric.

meas.name = 'uniformly weighted whole-beam absolute displacement descriptor';
meas.rule = 'uniform weighting over measured points';
meas.unit = 'mm';
meas.absSmoothEps = 1e-8;  % meters, used only to smooth |w| near zero.

meas.xNorm = [0.20; 0.40; 0.60; 0.80; 1.00];
meas.x = beam.L * meas.xNorm;
meas.numPoints = numel(meas.xNorm);

meas.virtualRootXNorm = 0.0;
meas.virtualRootWeight = 0.0;
meas.rawWeights = ones(meas.numPoints, 1) / meas.numPoints;
meas.weights = meas.rawWeights;
meas.rawWeightsWithRoot = [0.0; meas.rawWeights];
meas.sumRawWeights = sum(meas.rawWeights);

nModes = numel(beam.beta);
meas.PhiGrid = zeros(meas.numPoints, nModes);
for i = 1:meas.numPoints
    for m = 1:nModes
        meas.PhiGrid(i, m) = beam_mode_shape(m, meas.x(i), beam);
    end
end

meas.PhiEqBase = (meas.weights.' * meas.PhiGrid);

meas.formulaGlobal = 'y2Global = 1000 * sum(alpha_i * abs(w(x_i,t))), alpha_i = 1/N';
meas.formulaIntegral = 'same as formulaGlobal under the uniform-weight setting';
meas.weightNote = ['alpha_i are uniform measured-point weights with alpha_i = 1/N; ' ...
                   'the root point x = 0 is not included in the sum.'];
end
