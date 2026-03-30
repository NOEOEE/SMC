function m = calc_modal_metrics(out)
%CALC_MODAL_METRICS Individual flexible-mode metrics in mm / mm/s.
%
% q1 = out.x(:,3), q2 = out.x(:,4)
% dq1 = out.x(:,5), dq2 = out.x(:,6)

if isempty(out) || ~isfield(out, 'x') || size(out.x, 2) < 6
    error('calc_modal_metrics:InvalidInput', 'The result struct does not contain the required modal states.');
end

t = out.t(:);
T = max(t(end) - t(1), eps);

qMm = 1000 * out.x(:, 3:4);
dqMm = 1000 * out.x(:, 5:6);

m.PeakAbsQ1 = max(abs(qMm(:,1)));
m.PeakAbsQ2 = max(abs(qMm(:,2)));
m.IAE_Q1 = trapz(t, abs(qMm(:,1)));
m.IAE_Q2 = trapz(t, abs(qMm(:,2)));
m.RMS_Q1 = sqrt(trapz(t, qMm(:,1).^2) / T);
m.RMS_Q2 = sqrt(trapz(t, qMm(:,2).^2) / T);

m.PeakAbsDQ1 = max(abs(dqMm(:,1)));
m.PeakAbsDQ2 = max(abs(dqMm(:,2)));
m.IAE_DQ1 = trapz(t, abs(dqMm(:,1)));
m.IAE_DQ2 = trapz(t, abs(dqMm(:,2)));
m.RMS_DQ1 = sqrt(trapz(t, dqMm(:,1).^2) / T);
m.RMS_DQ2 = sqrt(trapz(t, dqMm(:,2).^2) / T);
end
