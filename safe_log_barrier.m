function [Lval, extraBase] = safe_log_barrier(e, eb)
%SAFE_LOG_BARRIER  Safe evaluation of the logarithmic barrier.
%
% L(e) = ln((eb + |e|)/(eb - |e|))
% d/de L(e) contributes the extra factor 2*eb/(eb^2 - e^2).

a = min(abs(e), 0.995 * eb);
den1 = max(eb - a, 1e-8);
Lval = log((eb + a) / den1);

den2 = max(eb^2 - a^2, 1e-8);
extraBase = 2 * eb / den2;
end
