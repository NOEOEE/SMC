function out = controller_eval(t, x, p, controllerName)
%CONTROLLER_EVAL Evaluate control law for all controller variants.

plant = state_to_outputs(x(1:6), p);
y  = plant.y;
dy = plant.dy;

z1 = [x(7);  x(10)];
z2 = [x(8);  x(11)];
z3 = [x(9);  x(12)];

ref = reference_command(t, p);
e  = y  - ref.y;
ed = dy - ref.dy;

if isfield(p, 'safe') && isfield(p.safe, 'maxError')
    e  = min(max(e,  -p.safe.maxError),  p.safe.maxError);
    ed = min(max(ed, -p.safe.maxErrorRate), p.safe.maxErrorRate);
end

useESO = ~any(strcmpi(controllerName, {'lnftsmc_noeso', 'open_loop'}));
rho = local_get_rho(p, controllerName);

if useESO
    z3Used = rho .* z3;
    if isfield(p, 'safe') && isfield(p.safe, 'maxDistComp')
        z3Cap = p.safe.maxDistComp(:);
        z3Used = z3Cap .* tanh(z3Used ./ max(z3Cap, eps));
    end
else
    z3Used = zeros(2,1);
end

switch lower(controllerName)
    case 'lnftsmc_eso'
        prm = p.ctrl.prop;
        s = zeros(2,1);
        v = zeros(2,1);
        for i = 1:2
            eAbs  = max(abs(e(i)), 1e-6);
            edAbs = max(abs(ed(i)), 1e-6);
            [Lval, extraBase] = safe_log_barrier(e(i), prm.eb(i));
            s(i) = e(i) + ed(i) ...
                 + prm.k1(i) * sig_pow(e(i), prm.tau(i)) ...
                 + prm.k2(i) * sig_pow(e(i), prm.alpha(i)) * Lval ...
                 + prm.k3(i) * sig_pow(ed(i), prm.beta(i));
            barrierCoef = prm.alpha(i) * eAbs^(prm.alpha(i) - 1) * Lval ...
                        + eAbs^(prm.alpha(i)) * extraBase;
            H = (1 ...
                + prm.k1(i) * prm.tau(i) * eAbs^(prm.tau(i) - 1) ...
                + prm.k2(i) * barrierCoef) * ed(i);
            J = 1 + prm.k3(i) * prm.beta(i) * edAbs^(prm.beta(i) - 1);
            J = sign(J) * max(abs(J), 0.10);
            v(i) = ref.ddy(i) ...
                 - (H + prm.r(i) * s(i) + prm.K(i) * tanh(s(i) / prm.phi(i))) / J;
        end

    case 'lnftsmc_noeso'
        prm = p.ctrl.noeso;
        s = zeros(2,1);
        v = zeros(2,1);
        for i = 1:2
            eAbs  = max(abs(e(i)), 1e-6);
            edAbs = max(abs(ed(i)), 1e-6);
            [Lval, extraBase] = safe_log_barrier(e(i), prm.eb(i));
            % The no-ESO branch needs extra numerical damping on R2021b.
            Lval = min(Lval, 4.0);
            extraBase = min(extraBase, 20.0);
            s(i) = e(i) + ed(i) ...
                 + prm.k1(i) * sig_pow(e(i), prm.tau(i)) ...
                 + prm.k2(i) * sig_pow(e(i), prm.alpha(i)) * Lval ...
                 + prm.k3(i) * sig_pow(ed(i), prm.beta(i));
            if isfield(p, 'safe') && isfield(p.safe, 'maxSlidingNoESO')
                s(i) = min(max(s(i), -p.safe.maxSlidingNoESO(i)), p.safe.maxSlidingNoESO(i));
            end
            barrierCoef = prm.alpha(i) * eAbs^(prm.alpha(i) - 1) * Lval ...
                        + eAbs^(prm.alpha(i)) * extraBase;
            H = (1 ...
                + prm.k1(i) * prm.tau(i) * eAbs^(prm.tau(i) - 1) ...
                + prm.k2(i) * barrierCoef) * ed(i);
            J = 1 + prm.k3(i) * prm.beta(i) * edAbs^(prm.beta(i) - 1);
            J = sign(J) * max(abs(J), 0.25);
            v(i) = ref.ddy(i) ...
                 - (H + prm.r(i) * s(i) + prm.K(i) * tanh(s(i) / prm.phi(i))) / J;
        end

    case 'ntsmc_eso'
        prm = p.ctrl.nts;
        s = zeros(2,1);
        v = zeros(2,1);
        for i = 1:2
            eAbs  = max(abs(e(i)), 1e-6);
            edAbs = max(abs(ed(i)), 1e-6);
            s(i) = e(i) + ed(i) ...
                 + prm.k1(i) * sig_pow(e(i), prm.tau(i)) ...
                 + prm.k2(i) * sig_pow(e(i), prm.alpha(i)) ...
                 + prm.k3(i) * sig_pow(ed(i), prm.beta(i));
            H = (1 ...
                + prm.k1(i) * prm.tau(i) * eAbs^(prm.tau(i) - 1) ...
                + prm.k2(i) * prm.alpha(i) * eAbs^(prm.alpha(i) - 1)) * ed(i);
            J = 1 + prm.k3(i) * prm.beta(i) * edAbs^(prm.beta(i) - 1);
            J = sign(J) * max(abs(J), 0.10);
            v(i) = ref.ddy(i) ...
                 - (H + prm.r(i) * s(i) + prm.K(i) * tanh(s(i) / prm.phi(i))) / J;
        end

    case 'smc_eso'
        prm = p.ctrl.smc;
        s = ed + prm.lambda .* e;
        v = ref.ddy - prm.lambda .* ed - prm.K .* tanh(s ./ prm.phi);

    case 'pd_eso'
        prm = p.ctrl.lin;
        s = ed + prm.lambda .* e;
        v = ref.ddy - prm.lambda .* ed - prm.r .* s - prm.K .* tanh(s ./ prm.phi);

    case 'open_loop'
        s = zeros(2,1);
        v = zeros(2,1);

    otherwise
        error('Unknown controllerName: %s', controllerName);
end

if strcmpi(controllerName, 'lnftsmc_noeso') && isfield(p, 'safe') && isfield(p.safe, 'maxVirtualCtrlNoESO')
    v = min(max(v, -p.safe.maxVirtualCtrlNoESO), p.safe.maxVirtualCtrlNoESO);
elseif isfield(p, 'safe') && isfield(p.safe, 'maxVirtualCtrl')
    v = min(max(v, -p.safe.maxVirtualCtrl), p.safe.maxVirtualCtrl);
end

u = (v - z3Used) ./ p.plant.b0;
if strcmpi(controllerName, 'lnftsmc_noeso') && isfield(p, 'safe') && isfield(p.safe, 'maxInputNoESO')
    u = min(max(u, -p.safe.maxInputNoESO), p.safe.maxInputNoESO);
else
    u = min(max(u, -p.plant.umax), p.plant.umax);
end

out.y      = y;
out.dy     = dy;
out.e      = e;
out.ed     = ed;
out.s      = s;
out.v      = v;
out.u      = u;
out.z1     = z1;
out.z2     = z2;
out.z3     = z3;
out.z3Used = z3Used;
out.useESO = useESO;
out.ref    = ref;
out.rho    = rho;

% Pass through the whole-beam descriptor so post-processing and plotting do
% not need to recompute it.
out.yCtrl = plant.yCtrl;
out.dyCtrl = plant.dyCtrl;
out.yGlobal = plant.yGlobal;
out.dyGlobal = plant.dyGlobal;
out.yBeamGlobal = plant.yBeamGlobal;
out.dyBeamGlobal = plant.dyBeamGlobal;
out.yBeamIntegral = plant.yBeamIntegral;
out.dyBeamIntegral = plant.dyBeamIntegral;
out.yBeamWeightedLinear = plant.yBeamWeightedLinear;
out.dyBeamWeightedLinear = plant.dyBeamWeightedLinear;
out.wMeasurePointsMm = plant.wMeasurePointsMm;
out.pointContribGlobalMm = plant.pointContribGlobalMm;
out.measurePointX = plant.measurePointX;
out.measurePointXNorm = plant.measurePointXNorm;
end

function rho = local_get_rho(p, controllerName)
rho = [1.0; 1.0];
if isfield(p, 'eso') && isfield(p.eso, 'rhoMap')
    key = lower(controllerName);
    if isfield(p.eso.rhoMap, key)
        rho = p.eso.rhoMap.(key);
        return;
    end
end
if isfield(p, 'eso') && isfield(p.eso, 'rho')
    rho = p.eso.rho;
end
end

