function label = controller_label(controllerName)
%CONTROLLER_LABEL  Human-readable controller labels.

switch lower(controllerName)
    case 'lnftsmc_eso'
        label = 'ln-NFTSMC+ESO';
    case 'ntsmc_eso'
        label = 'NTSMC+ESO';
    case 'smc_eso'
        label = 'Classic SMC+ESO';
    case 'pd_eso'
        label = 'PD+ESO';
    case 'lnftsmc_noeso'
        label = 'ln-NFTSMC(no ESO)';
    case 'open_loop'
        label = 'Open-loop / no control';
    otherwise
        label = controllerName;
end
end
