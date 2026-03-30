function [dxPlant, aux] = true_plant(t, xPlant, p, u)
%TRUE_PLANT Final reconciled plant for:
% - pure-tracking nominal,
% - disturbed tracking,
% - stress case,
% - true large-initial-displacement free vibration.
%
% xPlant = [theta; dtheta; q1; q2; dq1; dq2]

theta  = xPlant(1);
dtheta = xPlant(2);
q      = xPlant(3:4);
dq     = xPlant(5:6);

Vm = u(1);   % rigid / attitude channel input
Vp = u(2);   % piezo / flexible channel input

% -------------------------------------------------------------------------
% External disturbances by case
% -------------------------------------------------------------------------
switch lower(p.caseName)

    case 'nominal'
        % Pure tracking: no external disturbance.
        extRigid = 0.0;
        extFlex  = [0.0; 0.0];

    case 'disturbance'
        ds = p.plant.distScale;
        extRigid = ds(1) * ( ...
            0.0030 * sin(0.55 * t) + ...
            0.0015 * cos(1.25 * t) );
        extFlex = ds(2) * [ ...
            0.00012 * sin(0.50 * t) + 0.00006 * cos(1.10 * t); ...
            0.00018 * sin(2.80 * t) - 0.00008 * cos(3.60 * t) ];

    case 'stress'
        ds = p.plant.distScale;
        pulse = 0.40 * exp(-((t - 18.0) / 2.5)^2) ...
              - 0.25 * exp(-((t - 28.0) / 3.0)^2);
        extRigid = ds(1) * ( ...
            0.0045 * sin(0.70 * t) + ...
            0.0035 * cos(1.60 * t) + ...
            0.0040 * pulse );
        extFlex = ds(2) * [ ...
            0.00018 * sin(0.60 * t) + 0.00012 * pulse; ...
            0.00028 * sin(3.00 * t) + 0.00018 * pulse ];

    case 'freevib_large'
        % True free vibration: no external disturbance.
        extRigid = 0.0;
        extFlex  = [0.0; 0.0];

    otherwise
        error('Unknown p.caseName: %s', p.caseName);
end

% -------------------------------------------------------------------------
% Rigid channel
% -------------------------------------------------------------------------
% Mild rigid-flex coupling. Once the maneuver is over and theta_dd -> 0,
% the flexible response decays instead of being perpetually re-excited.
fRigid = ...
      -0.25 * theta ...
      -0.55 * dtheta ...
      -0.12 * (p.plant.Phi_tip * q) ...
      -0.03 * (p.plant.Phi_tip * dq) ...
      +0.004 * tanh(4.0 * theta) ...
      +extRigid;

theta_dd = p.plant.bTrue(1) * Vm + fRigid;

% -------------------------------------------------------------------------
% Flexible channel
% -------------------------------------------------------------------------
% The maneuver excites the flexible modes mainly through rigid acceleration.
% After the maneuver, theta_dd becomes small and only the flexible dynamics
% remain, so nominal acts like "maneuver then decay" instead of sustained
% forced vibration.
dFlex = [0.0040; -0.0060] * theta_dd ...
      + [0.0008; -0.0010] * dtheta ...
      + extFlex;

qdd = p.plant.M \ ( ...
    -p.plant.C * dq ...
    -p.plant.K * q ...
    +p.plant.Gamma_p * Vp ...
    +dFlex );

% Controller-side second output acceleration
y2dd = 1000 * (p.plant.Phi_s * qdd);

out = state_to_outputs(xPlant, p);
ydd = [theta_dd; y2dd];

dTrue = [ ...
    theta_dd - p.plant.b0(1) * Vm; ...
    y2dd     - p.plant.b0(2) * Vp ];

dxPlant = [dtheta; theta_dd; dq; qdd];

aux.y      = out.y;
aux.dy     = out.dy;
aux.ydd    = ydd;
aux.dTrue  = dTrue;
aux.fRigid = fRigid;
aux.dFlex  = dFlex;
end
