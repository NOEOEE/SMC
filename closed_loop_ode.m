function dx = closed_loop_ode(t, x, p, controllerName)
%CLOSED_LOOP_ODE  Closed-loop dynamics with plant + ESO.
% Includes defensive clamps so older MATLAB versions do not get trapped in
% non-finite adaptive-step failures.

ctrl = controller_eval(t, x, p, controllerName);
[dxPlant, aux] = true_plant(t, x(1:6), p, ctrl.u);

if any(~isfinite(dxPlant)) || any(~isfinite(ctrl.u)) || any(~isfinite(aux.y))
    dx = zeros(12,1);
    return;
end

dx = zeros(12,1);
dx(1:6) = dxPlant;

if ctrl.useESO
    eObs1 = aux.y(1) - x(7);
    eObs2 = aux.y(2) - x(10);

    l1 = 3 * p.eso.wo;
    l2 = 3 * (p.eso.wo .^ 2);
    l3 = p.eso.wo .^ 3;

    dx(7)  = x(8)  + l1(1) * eObs1;
    dx(8)  = x(9)  + p.plant.b0(1) * ctrl.u(1) + l2(1) * eObs1;
    dx(9)  = l3(1) * eObs1;

    dx(10) = x(11) + l1(2) * eObs2;
    dx(11) = x(12) + p.plant.b0(2) * ctrl.u(2) + l2(2) * eObs2;
    dx(12) = l3(2) * eObs2;

    if isfield(p, 'safe') && isfield(p.safe, 'maxEsoRate')
        dx(7:12) = min(max(dx(7:12), -p.safe.maxEsoRate), p.safe.maxEsoRate);
    end
else
    dx(7:12) = 0;
end

if isfield(p, 'safe') && isfield(p.safe, 'maxStateRate')
    dx(1:6) = min(max(dx(1:6), -p.safe.maxStateRate), p.safe.maxStateRate);
end
end
