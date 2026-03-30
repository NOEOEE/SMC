function y = sig_pow(x, p)
%SIG_POW  Sign-preserving power: |x|^p * sign(x)

y = abs(x).^p .* sign(x);
end
