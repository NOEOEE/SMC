function phi = beam_mode_shape(modeIdx, x, beam)
%BEAM_MODE_SHAPE Cantilever beam mode shape normalized so phi(L)=1.

beta = beam.beta(modeIdx);
L = beam.L;
sigma = (sinh(beta) - sin(beta)) / (cosh(beta) + cos(beta));
xi = x ./ L;
raw = cosh(beta .* xi) - cos(beta .* xi) ...
    - sigma .* (sinh(beta .* xi) - sin(beta .* xi));
rawL = cosh(beta) - cos(beta) ...
     - sigma .* (sinh(beta) - sin(beta));
phi = raw ./ rawL;
end
