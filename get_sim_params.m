function p = get_sim_params(caseName)
%GET_SIM_PARAMS Final reconciled parameter set for:
% 1) pure vibration-suppression nominal case,
% 2) tracking with disturbances,
% 3) stress case,
% 4) true large-initial-displacement free vibration.
%
% This version is aligned with the final base_reference_command.m and
% true_plant.m logic:
%   - nominal      : hold attitude constant, zero external disturbance,
%                    nonzero initial flexible displacement only.
%   - disturbance  : same tracking task with bounded external disturbance.
%   - stress       : faster maneuver + stronger disturbances + moderate
%                    flexible initial displacement.
%   - freevib_large: zero reference, zero external disturbance, large
%                    flexible initial displacement.

if nargin < 1
    caseName = 'nominal';
end

p.caseName = lower(caseName);
beam = get_literature_beam_params_local();

% -------------------------------------------------------------------------
% Simulation
% -------------------------------------------------------------------------
p.sim.solver   = 'ode23tb';
p.sim.outputDt = 0.01;
p.sim.ode      = odeset('RelTol',1e-6,'AbsTol',1e-8, ...
                        'MaxStep',0.02,'InitialStep',1e-4,'Refine',1);
p.sim.tEnd     = 60.0;

% -------------------------------------------------------------------------
% Plant / beam data
% -------------------------------------------------------------------------
p.beam = beam;
p.plant.M       = beam.M;
p.plant.C       = beam.C;
p.plant.K       = beam.K;
p.plant.Phi_s   = beam.Phi_s(:).';
p.plant.Phi_tip = beam.Phi_tip(:).';
p.plant.Gamma_p = beam.Gamma_p(:);
p.plant.Bp      = beam.Bp(:);

% Controller-side normalized second-channel gain:
%   y2dd = 1000 * Phi_s * qdd ≈ bTrue(2) * Vp + lumped terms
p.plant.bTrue = [4.80;
                 1000 * (p.plant.Phi_s * (p.plant.M \ p.plant.Gamma_p))];
p.plant.b0 = [4.50;
              0.95 * p.plant.bTrue(2)];
p.plant.umax = [6.0; 45.0];

% Multiple-point measurement object used by the current visualization chain.
p.measure = build_beam_measurement(beam);

% -------------------------------------------------------------------------
% Reference definition
% -------------------------------------------------------------------------
% New reference generator uses y1Target / Tmove. Old fields are kept for
% backward compatibility with any helper code that still reads them.
p.ref.y1Target = 0.02;   % rad
p.ref.Tmove    = 8.0;    % s, finite-time smooth rest-to-rest maneuver
p.ref.y2d      = 0.0;    % mm

% Backward-compatible fields
p.ref.a1 = p.ref.y1Target;
p.ref.b1 = p.ref.Tmove;
p.ref.a2 = 0.0;
p.ref.w1 = 0.0;

% Keep input shaper disabled for the final "pure-tracking nominal" version.
p.shaper.enable = false;
p.shaper.type = 'zvd';
p.shaper.channel1Only = true;
p.shaper.wn = beam.wn(1);
p.shaper.zeta = beam.zeta(1);

% -------------------------------------------------------------------------
% ESO settings
% -------------------------------------------------------------------------
p.eso.wo = [14.0; 9.0];
p.eso.rhoMap.lnftsmc_eso    = [1.0; 0.55];
p.eso.rhoMap.lnftsmc_noeso  = [0.0; 0.0];
p.eso.rhoMap.ntsmc_eso      = [1.0; 0.30];
p.eso.rhoMap.pd_eso         = [1.0; 0.30];
p.eso.rhoMap.smc_eso        = [1.0; 0.30];

% -------------------------------------------------------------------------
% Controller parameters
% -------------------------------------------------------------------------
p.ctrl.prop.k1    = [0.85; 1.20];
p.ctrl.prop.k2    = [0.10; 0.35];
p.ctrl.prop.k3    = [0.22; 0.15];
p.ctrl.prop.tau   = [0.75; 0.78];
p.ctrl.prop.alpha = [1.15; 1.08];
p.ctrl.prop.beta  = [1.20; 1.10];
p.ctrl.prop.eb    = [0.08; 25.0];
p.ctrl.prop.r     = [3.0; 7.0];
p.ctrl.prop.K     = [0.35; 18.0];
p.ctrl.prop.phi   = [0.010; 0.35];

% Conservative no-ESO branch
p.ctrl.noeso.k1    = [0.70; 0.70];
p.ctrl.noeso.k2    = [0.06; 0.08];
p.ctrl.noeso.k3    = [0.18; 0.10];
p.ctrl.noeso.tau   = [0.75; 0.80];
p.ctrl.noeso.alpha = [1.10; 1.05];
p.ctrl.noeso.beta  = [1.18; 1.05];
p.ctrl.noeso.eb    = [0.08; 25.0];
p.ctrl.noeso.r     = [2.2; 3.0];
p.ctrl.noeso.K     = [0.22; 6.0];
p.ctrl.noeso.phi   = [0.015; 0.80];

p.ctrl.nts.k1    = [0.82; 0.18];
p.ctrl.nts.k2    = [0.08; 0.10];
p.ctrl.nts.k3    = [0.22; 0.14];
p.ctrl.nts.tau   = [0.75; 0.72];
p.ctrl.nts.alpha = [1.12; 1.12];
p.ctrl.nts.beta  = [1.20; 1.15];
p.ctrl.nts.r     = [2.6; 4.8];
p.ctrl.nts.K     = [0.30; 15.0];
p.ctrl.nts.phi   = [0.012; 0.50];

p.ctrl.smc.lambda = [2.0; 1.5];
p.ctrl.smc.K      = [0.25; 12.0];
p.ctrl.smc.phi    = [0.012; 0.45];

p.ctrl.lin.lambda = [1.8; 1.3];
p.ctrl.lin.r      = [1.5; 1.5];
p.ctrl.lin.K      = [0.18; 8.0];
p.ctrl.lin.phi    = [0.015; 0.60];

% -------------------------------------------------------------------------
% Safety / saturation monitors
% -------------------------------------------------------------------------
p.safe.maxError = [0.12; 35.0];
p.safe.maxErrorRate = [0.30; 120.0];
p.safe.maxVirtualCtrl = [15.0; 1000.0];
p.safe.maxVirtualCtrlNoESO = [8.0; 400.0];
p.safe.maxInputNoESO = [6.0; 25.0];
p.safe.maxSlidingNoESO = [1.0; 40.0];
p.safe.maxStateRate = [0.5; 2.0; 0.10; 0.10; 0.50; 2.0];
p.safe.maxEsoRate = [10.0; 100.0; 1000.0; 50.0; 500.0; 5000.0];
p.safe.distCompCapScale = [1.20; 0.95];
p.safe.maxDistComp = p.safe.distCompCapScale .* (p.plant.b0 .* p.plant.umax);

% -------------------------------------------------------------------------
% Case definitions
% -------------------------------------------------------------------------
switch p.caseName

    case 'nominal'
        % Pure vibration-suppression comparison:
        % hold attitude constant, no external disturbance,
        % inject only an initial flexible displacement.
        p.ref.y1Target = 0.02;
        p.ref.a1 = p.ref.y1Target;
        p.ref.Tmove = 0.0;
        p.ref.b1 = p.ref.Tmove;
        p.plant.distScale = [0.0; 0.0];
        p.sim.tEnd = 80.0;
        xPlant0 = initial_plant_state_local(p, 0.02, 20.0, -0.10, 0.0, 0.0, 0.0);

    case 'disturbance'
        % Same tracking task, but with sustained bounded disturbances.
        p.ref.y1Target = 0.02;
        p.ref.a1 = p.ref.y1Target;
        p.ref.Tmove = 8.0;
        p.ref.b1 = p.ref.Tmove;
        p.plant.distScale = [1.0; 1.0];
        p.sim.tEnd = 80.0;
        xPlant0 = initial_plant_state_local(p, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

    case 'stress'
        % Faster maneuver + stronger disturbances + moderate flexible preload.
        p.ref.y1Target = 0.02;
        p.ref.a1 = p.ref.y1Target;
        p.ref.Tmove = 5.0;
        p.ref.b1 = p.ref.Tmove;
        p.plant.distScale = [1.6; 1.8];
        p.plant.umax(2) = 55.0;
        p.sim.tEnd = 100.0;
        xPlant0 = initial_plant_state_local(p, 0.0, 12.0, -0.10, 0.0, 0.0, 0.0);

    case 'freevib_large'
        % True free vibration: zero reference, zero disturbance, large flexible IC.
        p.ref.y1Target = 0.0;
        p.ref.a1 = p.ref.y1Target;
        p.ref.Tmove = 0.0;
        p.ref.b1 = p.ref.Tmove;
        p.plant.distScale = [0.0; 0.0];
        p.sim.tEnd = 120.0;
        xPlant0 = initial_plant_state_local(p, 0.0, 120.0, -0.10, 0.0, 0.0, 0.0);

    otherwise
        error('Unknown caseName: %s', caseName);
end

p.init.xPlant = xPlant0;
y0 = state_to_outputs(xPlant0, p);
p.init.z0 = [y0.y(1); 0; 0; y0.y(2); 0; 0];

p.notes.y2CtrlUnit   = 'mm';
p.notes.y2GlobalUnit = 'mm';
p.notes.y2CtrlDef    = 'y2_ctrl = 1000 * Phi_s * q';
p.notes.y2GlobalDef  = 'y2_global = 1000 * Phi_tip * q';
p.notes.model        = ['final reconciled low-frequency single-beam model, ' ...
                         'pure-tracking nominal + true free-vibration case'];

p.plot.enableMainPlots = false;
end

% =========================================================================
function beam = get_literature_beam_params_local()
% Low-frequency single-beam equivalent model inspired by aerospace flexible
% appendage studies, but reduced to a two-mode model consistent with the
% current controller interface.

beam.L    = 5.0;
beam.b    = 0.05;
beam.h    = 0.035;
beam.Eb   = 0.689e9;
beam.rhob = 6500;
beam.nu_b = 0.30;
beam.A    = beam.b * beam.h;
beam.I    = beam.b * beam.h^3 / 12;
beam.xs   = 0.35 * beam.L;
beam.xt   = beam.L;
beam.beta = [1.875104068711; 4.694091132974];

% Two-mode low-frequency equivalent dynamics
beam.M = diag([1.00, 1.00]);
beam.fn = [0.070; 0.450];           % Hz  -> periods about 14.3 s and 2.2 s
beam.wn = 2*pi*beam.fn;
beam.zeta = [0.030; 0.040];
beam.K = diag(beam.wn.^2) .* diag(beam.M);
beam.C = diag(2 .* beam.zeta .* beam.wn) .* diag(beam.M);
beam.K = diag(diag(beam.K));
beam.C = diag(diag(beam.C));

% Output maps
beam.Phi_s   = [0.75, 0.16];
beam.Phi_tip = [1.0, 1.0];

% PZT equivalent generalized input vector
beam.Gamma_p = [ 0.040;
                -0.055];

% Keep Bp as modal-acceleration per volt for compatibility with legacy code.
beam.Bp = beam.M \ beam.Gamma_p;
end

% =========================================================================
function xPlant0 = initial_plant_state_local(p, theta0, y2mm0, q2q1Ratio, dtheta0, dq1_0, dq2_0)
Phi = p.plant.Phi_s;
y2m0 = y2mm0 / 1000;

den = Phi(1) + q2q1Ratio * Phi(2);
if abs(den) < 1e-12
    q1_0 = 0.0;
    q2_0 = 0.0;
else
    q1_0 = y2m0 / den;
    q2_0 = q2q1Ratio * q1_0;
end

xPlant0 = [theta0; dtheta0; q1_0; q2_0; dq1_0; dq2_0];
end
