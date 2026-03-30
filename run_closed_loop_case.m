function out = run_closed_loop_case(p, controllerName)
%RUN_CLOSED_LOOP_CASE Run one closed-loop simulation.
% R2021b-stable path: use a stiff solver and a fixed output grid to prevent
% excessive memory growth / very dense adaptive output on hard cases.

x0 = [p.init.xPlant; p.init.z0];

if strcmpi(controllerName, 'lnftsmc_noeso')
    % Older MATLAB releases are more fragile on the no-ESO branch because
    % the closed loop is less damped and the barrier term is still active.
    solverName = 'ode15s';
    odeOpts = odeset(p.sim.ode, 'MaxStep', 0.01, 'InitialStep', 5e-5);
else
    if isfield(p, 'sim') && isfield(p.sim, 'solver') && ~isempty(p.sim.solver)
        solverName = p.sim.solver;
    else
        solverName = 'ode23tb';
    end
    odeOpts = p.sim.ode;
end
solverFcn = str2func(solverName);

if isfield(p.sim, 'outputDt') && p.sim.outputDt > 0
    tSpan = 0:p.sim.outputDt:p.sim.tEnd;
    if tSpan(end) < p.sim.tEnd
        tSpan = [tSpan, p.sim.tEnd]; %#ok<AGROW>
    end
else
    tSpan = [0 p.sim.tEnd];
end

odefun = @(tt, xx) closed_loop_ode(tt, xx, p, controllerName);
[t, x] = solverFcn(odefun, tSpan, x0, odeOpts);

N = numel(t);
y        = zeros(N, 2);
dy       = zeros(N, 2);
yGlobal  = zeros(N, 2);
dyGlobal = zeros(N, 2);
yd       = zeros(N, 2);
dyd      = zeros(N, 2);
ddyd     = zeros(N, 2);
u        = zeros(N, 2);
v        = zeros(N, 2);
s        = zeros(N, 2);
z1       = zeros(N, 2);
z2       = zeros(N, 2);
z3       = zeros(N, 2);
dTrue    = zeros(N, 2);
residual = zeros(N, 2);
yBeamIntegral = zeros(N, 1);
yBeamWeightedLinear = zeros(N, 1);
wPointsMm = zeros(N, p.measure.numPoints);
pointContribGlobalMm = zeros(N, p.measure.numPoints);

for k = 1:N
    xx = x(k, :).';
    ctrl = controller_eval(t(k), xx, p, controllerName);
    [~, aux] = true_plant(t(k), xx(1:6), p, ctrl.u);

    y(k, :)        = ctrl.y.';
    dy(k, :)       = ctrl.dy.';
    yGlobal(k, :)  = ctrl.yGlobal(:).';
    dyGlobal(k, :) = ctrl.dyGlobal(:).';
    yd(k, :)       = ctrl.ref.y.';
    dyd(k, :)      = ctrl.ref.dy.';
    ddyd(k, :)     = ctrl.ref.ddy.';
    u(k, :)        = ctrl.u.';
    v(k, :)        = ctrl.v.';
    s(k, :)        = ctrl.s.';
    z1(k, :)       = ctrl.z1.';
    z2(k, :)       = ctrl.z2.';
    z3(k, :)       = ctrl.z3.';
    dTrue(k, :)    = aux.dTrue.';
    residual(k, :) = (aux.dTrue - ctrl.z3Used).';
    yBeamIntegral(k) = ctrl.yBeamIntegral;
    yBeamWeightedLinear(k) = ctrl.yBeamWeightedLinear;
    wPointsMm(k, :) = ctrl.wMeasurePointsMm(:).';
    pointContribGlobalMm(k, :) = ctrl.pointContribGlobalMm(:).';
end

out.t        = t;
out.x        = x;
out.y        = y;
out.dy       = dy;
out.yCtrl    = y;
out.dyCtrl   = dy;
out.yGlobal  = yGlobal;
out.dyGlobal = dyGlobal;
out.yBeamIntegral = yBeamIntegral;
out.yBeamWeightedLinear = yBeamWeightedLinear;
out.wPointsMm = wPointsMm;
out.pointContribGlobalMm = pointContribGlobalMm;
out.measure  = p.measure;
out.yd       = yd;
out.dyd      = dyd;
out.ddyd     = ddyd;
out.u        = u;
out.v        = v;
out.s        = s;
out.z1       = z1;
out.z2       = z2;
out.z3       = z3;
out.dTrue    = dTrue;
out.residual = residual;
out.controllerName = controllerName;
out.label    = controller_label(controllerName);
out.metrics  = calc_metrics(t, y, yd, u, residual, yGlobal(:,2));
end

