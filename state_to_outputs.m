function out = state_to_outputs(xPlant, p)
%STATE_TO_OUTPUTS Map plant states to controller outputs and highlighted outputs.
%
% Controller-side output (kept unchanged):
%   y2_ctrl = 1000 * Phi_s * q
%
% Highlighted global output redefined here as beam-tip linear displacement:
%   y2_g = 1000 * Phi_tip * q

theta  = xPlant(1);
dtheta = xPlant(2);
q      = xPlant(3:4);
dq     = xPlant(5:6);

% Keep the original measurement evaluation, so old fields are still available
beamEval = evaluate_beam_measurement(q, dq, p.measure);

% Controller-side output (unchanged)
yCtrl  = [theta;
          1000 * (p.plant.Phi_s * q)];
dyCtrl = [dtheta;
          1000 * (p.plant.Phi_s * dq)];

% ===== Redefine yGlobal as beam-tip linear displacement =====
yGlobal  = [theta;
            1000 * (p.plant.Phi_tip * q)];
dyGlobal = [dtheta;
            1000 * (p.plant.Phi_tip * dq)];

out.theta  = theta;
out.dtheta = dtheta;
out.q      = q;
out.dq     = dq;

out.yCtrl  = yCtrl;
out.dyCtrl = dyCtrl;
out.y      = yCtrl;
out.dy     = dyCtrl;

out.yGlobal  = yGlobal;
out.dyGlobal = dyGlobal;

% Keep extra fields for compatibility / later analysis
out.yBeamGlobal = yGlobal(2);
out.dyBeamGlobal = dyGlobal(2);

% Preserve the old whole-beam weighted quantities under separate names
out.yBeamDescriptorAbs = beamEval.y2GlobalNormAbs(1);
out.dyBeamDescriptorAbs = beamEval.dy2GlobalNormAbs(1);
out.yBeamIntegral = beamEval.y2GlobalIntegralAbs(1);
out.dyBeamIntegral = beamEval.dy2GlobalIntegralAbs(1);
out.yBeamWeightedLinear = beamEval.y2WeightedLinear(1);
out.dyBeamWeightedLinear = beamEval.dy2WeightedLinear(1);

out.wMeasurePoints = beamEval.wPoints(:,1);
out.dwMeasurePoints = beamEval.dwPoints(:,1);
out.wMeasurePointsMm = beamEval.wPointsMm(:,1);
out.pointContribGlobalMm = beamEval.pointContribNormMm(:,1);
out.pointContribIntegralMm = beamEval.pointContribIntegralMm(:,1);
out.measurePointX = p.measure.x;
out.measurePointXNorm = p.measure.xNorm;
end