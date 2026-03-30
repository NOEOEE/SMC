function sh = get_zvd_shaper(wn, zeta)
%GET_ZVD_SHAPER Build a standard ZVD input shaper from modal parameters.
%
% Reference form:
%   A = [1, 2K, K^2] / (1 + 2K + K^2)
%   t = [0, 0.5 Td, Td]
%   Td = pi / (wn * sqrt(1 - zeta^2))
%   K  = exp(-zeta * pi / sqrt(1 - zeta^2))

wn = max(wn, eps);
zeta = min(max(zeta, 0), 0.99);
rootTerm = sqrt(max(1 - zeta^2, eps));
K = exp(-zeta * pi / rootTerm);
Td = pi / (wn * rootTerm);
A = [1, 2*K, K^2] / (1 + 2*K + K^2);
tDelay = [0, 0.5 * Td, Td];

sh.type = 'ZVD';
sh.wn = wn;
sh.zeta = zeta;
sh.K = K;
sh.Td = Td;
sh.A = A(:);
sh.tDelay = tDelay(:);
end
