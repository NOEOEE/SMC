function p = apply_param_perturbation_case(p, caseTag)
%APPLY_PARAM_PERTURBATION_CASE Apply parameter/model mismatch scenarios.
% Keep the controller-side nominal model unchanged and perturb only the
% true plant parameters used by true_plant.m.

caseTag = lower(strtrim(caseTag));

% Preserve nominal references for repeatable perturbations.
if ~isfield(p, 'nominalPlant')
    p.nominalPlant = p.plant;
end
p.plant = p.nominalPlant;
p.perturbationTag = caseTag;

switch caseTag
    case {'nominal','nominal_ref','baseline'}
        p.perturbationLabel = 'nominal reference';

    case {'btrue2_minus20','gain_minus20'}
        p.plant.Bp = 0.80 * p.nominalPlant.Bp;
        p.plant.Gamma_p = 0.80 * p.nominalPlant.Gamma_p;
        p.plant.bTrue(2) = 0.80 * p.nominalPlant.bTrue(2);
        p.perturbationLabel = 'input gain mismatch: piezo channel x 0.80';

    case {'btrue2_plus20','gain_plus20'}
        p.plant.Bp = 1.20 * p.nominalPlant.Bp;
        p.plant.Gamma_p = 1.20 * p.nominalPlant.Gamma_p;
        p.plant.bTrue(2) = 1.20 * p.nominalPlant.bTrue(2);
        p.perturbationLabel = 'input gain mismatch: piezo channel x 1.20';

    case {'soft_beam','beam_soft'}
        p.plant.M = 1.15 * p.nominalPlant.M;
        p.plant.C = 0.85 * p.nominalPlant.C;
        p.plant.K = 0.85 * p.nominalPlant.K;
        p.perturbationLabel = 'structural mismatch: M x 1.15, C x 0.85, K x 0.85';

    case {'stiff_beam','beam_stiff'}
        p.plant.M = 0.90 * p.nominalPlant.M;
        p.plant.C = 1.20 * p.nominalPlant.C;
        p.plant.K = 1.20 * p.nominalPlant.K;
        p.perturbationLabel = 'structural mismatch: M x 0.90, C x 1.20, K x 1.20';

    case {'modal_shift'}
        p.plant.K = diag([0.90, 1.10]) * p.nominalPlant.K;
        p.plant.C = diag([1.10, 0.95]) * p.nominalPlant.C;
        p.perturbationLabel = 'modal mismatch: K1 x 0.90, K2 x 1.10, C1 x 1.10, C2 x 0.95';

    otherwise
        error('Unknown perturbation case: %s', caseTag);
end
end
