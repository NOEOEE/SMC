function obs = run_modal_state_eso_analysis(out, p, cfg)
%RUN_MODAL_STATE_ESO_ANALYSIS Analysis-only modal ESO using beam-point measurements.
%
% This helper does NOT modify the main controller. It reconstructs modal
% coordinates from the stored beam measurement points and then runs an
% auxiliary modal ESO on each flexible mode:
%
%   q_m'' = b_{0,m} * u_2 + d_m
%
% The modal outputs q_m are reconstructed from the multi-point beam
% displacement measurements by least squares.

if nargin < 3 || isempty(cfg)
    cfg = struct();
end

if ~isfield(out, 'measure') || ~isfield(out.measure, 'PhiGrid')
    error('run_modal_state_eso_analysis:MissingMeasurement', ...
        'The result struct does not contain out.measure.PhiGrid.');
end
if ~isfield(out, 'wPointsMm') || isempty(out.wPointsMm)
    error('run_modal_state_eso_analysis:MissingBeamPoints', ...
        'The result struct does not contain the stored beam-point measurements.');
end

t = out.t(:);
N = numel(t);
nModes = size(out.measure.PhiGrid, 2);

Phi = out.measure.PhiGrid;
if isfield(cfg, 'PhiPinv') && ~isempty(cfg.PhiPinv)
    PhiPinv = cfg.PhiPinv;
else
    PhiPinv = pinv(Phi);
end

wPoints = out.wPointsMm / 1000;    % meters
qMeas = (PhiPinv * wPoints.').';   % meters
qTrue = out.x(:, 3:(2 + nModes));
dqTrue = out.x(:, (3 + nModes):(2 + 2*nModes));

if isfield(cfg, 'wo') && ~isempty(cfg.wo)
    wo = cfg.wo(:);
else
    wo = [0.85 * p.beam.wn(1);
          0.40 * p.beam.wn(2)];
end
if numel(wo) == 1
    wo = repmat(wo, nModes, 1);
end

if isfield(cfg, 'b0') && ~isempty(cfg.b0)
    b0 = cfg.b0(:);
else
    b0 = p.plant.Bp(:);
end
if numel(b0) == 1
    b0 = repmat(b0, nModes, 1);
end

qHat = zeros(N, nModes);
dqHat = zeros(N, nModes);
dHat = zeros(N, nModes);

qHat(1, :) = qMeas(1, :);
if N >= 2
    dt0 = max(t(2) - t(1), eps);
    dqHat(1, :) = (qMeas(2, :) - qMeas(1, :)) / dt0;
end

for m = 1:nModes
    for k = 1:(N - 1)
        dt = max(t(k + 1) - t(k), eps);
        l1 = 3 * wo(m);
        l2 = 3 * wo(m)^2;
        l3 = wo(m)^3;

        Acl = [-l1, 1, 0;
               -l2, 0, 1;
               -l3, 0, 0];
        Bcl = [0,     l1;
               b0(m), l2;
               0,     l3];

        Md = expm([Acl, Bcl; zeros(2, 5)] * dt);
        Ad = Md(1:3, 1:3);
        Bd = Md(1:3, 4:5);

        zk = [qHat(k, m); dqHat(k, m); dHat(k, m)];
        uk = [out.u(k, 2); qMeas(k, m)];
        zk1 = Ad * zk + Bd * uk;

        qHat(k + 1, m) = zk1(1);
        dqHat(k + 1, m) = zk1(2);
        dHat(k + 1, m) = zk1(3);
    end
end

errQ = qHat - qTrue;
errDQ = dqHat - dqTrue;
T = max(t(end) - t(1), eps);

Mode = cell(nModes, 1);
RMSE_q_mm = zeros(nModes, 1);
IAE_q_mm_s = zeros(nModes, 1);
Peak_q_mm = zeros(nModes, 1);
RMSE_dq_mm_s = zeros(nModes, 1);
IAE_dq_mm = zeros(nModes, 1);
Peak_dq_mm_s = zeros(nModes, 1);
ReconRMSE_q_mm = zeros(nModes, 1);

for m = 1:nModes
    Mode{m} = sprintf('q%d', m);
    RMSE_q_mm(m) = 1000 * sqrt(trapz(t, errQ(:,m).^2) / T);
    IAE_q_mm_s(m) = 1000 * trapz(t, abs(errQ(:,m)));
    Peak_q_mm(m) = 1000 * max(abs(errQ(:,m)));

    RMSE_dq_mm_s(m) = 1000 * sqrt(trapz(t, errDQ(:,m).^2) / T);
    IAE_dq_mm(m) = 1000 * trapz(t, abs(errDQ(:,m)));
    Peak_dq_mm_s(m) = 1000 * max(abs(errDQ(:,m)));

    ReconRMSE_q_mm(m) = 1000 * sqrt(trapz(t, (qMeas(:,m) - qTrue(:,m)).^2) / T);
end

obs.t = t;
obs.qTrue = qTrue;
obs.dqTrue = dqTrue;
obs.qMeas = qMeas;
obs.qHat = qHat;
obs.dqHat = dqHat;
obs.dHat = dHat;
obs.errQ = errQ;
obs.errDQ = errDQ;
obs.wo = wo;
obs.b0 = b0;
obs.PhiPinv = PhiPinv;
obs.metrics = table(Mode, RMSE_q_mm, IAE_q_mm_s, Peak_q_mm, RMSE_dq_mm_s, IAE_dq_mm, Peak_dq_mm_s, ReconRMSE_q_mm);
end
