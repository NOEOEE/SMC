clearvars -except ans;
clc;

controllers = {'lnftsmc_eso', 'smc_eso', 'ntsmc_eso', 'pd_eso', 'lnftsmc_noeso'};
pertCases   = {'nominal_ref', 'btrue2_minus20', 'btrue2_plus20', 'soft_beam', 'modal_shift'};
pertLabels  = {'nominal ref', 'b_{True,2} x0.80', 'b_{True,2} x1.20', 'soft beam', 'modal shift'};
allResults  = cell(numel(pertCases), numel(controllers));
summaryTabs = cell(numel(pertCases), 1);

fprintf('\n==============================================\n');
fprintf('Experiment 6: parameter perturbation / model mismatch\n');
fprintf('Controllers: ln-NFTSMC+ESO / Classic SMC+ESO / NTSMC+ESO / PD+ESO / ln-NFTSMC(no ESO)\n');
fprintf('Base case: nominal initial condition, perturbed true plant only\n');
fprintf('Reported vibration metric: y2_global = weighted combination of |w(x_i,t)|\n');
fprintf('Boundary occupancy: still checked on controller-side y2_ctrl\n');
fprintf('==============================================\n');

for ic = 1:numel(pertCases)
    p = get_sim_params('nominal');
    p = apply_param_perturbation_case(p, pertCases{ic});

    fprintf('\n--- Perturbation case %d/%d: %s ---\n', ic, numel(pertCases), p.perturbationLabel);

    names   = cell(numel(controllers), 1);
    IAE_y2Global  = NaN(numel(controllers), 1);
    RMS_y2Global  = NaN(numel(controllers), 1);
    PeakY2Global  = NaN(numel(controllers), 1);
    RatioEbCtrl = NaN(numel(controllers), 1);
    OverEbCtrl  = NaN(numel(controllers), 1);
    PeakU2  = NaN(numel(controllers), 1);
    TVU2    = NaN(numel(controllers), 1);
    ISVU2   = NaN(numel(controllers), 1);
    PeakDz2 = NaN(numel(controllers), 1);
    HitBoundaryCtrl = false(numel(controllers), 1);

    for k = 1:numel(controllers)
        fprintf('Running controller %d/%d: %s\n', k, numel(controllers), controllers{k});
        try
            out = run_closed_loop_case(p, controllers{k});
            allResults{ic, k} = out;
            ext = calc_extended_metrics(out, p.ctrl.prop.eb(2), 0.05);

            names{k}            = out.label;
            IAE_y2Global(k)     = ext.IAE_y2Global;
            RMS_y2Global(k)     = ext.RMS_y2Global;
            PeakY2Global(k)     = ext.PeakY2Global;
            RatioEbCtrl(k)      = ext.RatioEbCtrl;
            OverEbCtrl(k)       = ext.OverEbCtrl;
            PeakU2(k)           = ext.PeakAbsU2;
            TVU2(k)             = ext.TVU2;
            ISVU2(k)            = ext.ISVU2;
            PeakDz2(k)          = ext.PeakEstErr2;
            HitBoundaryCtrl(k)  = ext.HitBoundaryCtrl;
        catch ME
            warning('Controller %s failed in case %s: %s', controllers{k}, pertCases{ic}, ME.message);
            names{k} = controller_label(controllers{k});
        end
    end

    T = table(names, IAE_y2Global, RMS_y2Global, PeakY2Global, RatioEbCtrl, OverEbCtrl, HitBoundaryCtrl, PeakU2, TVU2, ISVU2, PeakDz2);
    summaryTabs{ic} = T;
    disp(T);
end

figure('Name', 'Parameter perturbation - whole-beam robustness', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    vals = NaN(numel(pertCases), 1);
    for ic = 1:numel(pertCases)
        r = allResults{ic, k};
        if ~isempty(r)
            vals(ic) = r.metrics.IAE_y2Global;
        end
    end
    plot(ax, 1:numel(pertCases), vals, '-o', 'LineWidth', 1.4, 'DisplayName', controller_label(controllers{k}));
end
set(ax, 'XTick', 1:numel(pertCases), 'XTickLabel', pertLabels);
xtickangle(ax, 15);
ylabel(ax, 'IAE_{y_{2,g}}');
title(ax, 'Whole-beam robustness under parameter perturbation');
legend(ax, 'Location', 'best');

figure('Name', 'Parameter perturbation - control smoothness', 'Color', 'w');
ax = axes; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
for k = 1:numel(controllers)
    vals = NaN(numel(pertCases), 1);
    for ic = 1:numel(pertCases)
        r = allResults{ic, k};
        if ~isempty(r)
            ext = calc_extended_metrics(r, inf, 0.05);
            vals(ic) = ext.TVU2;
        end
    end
    plot(ax, 1:numel(pertCases), vals, '-s', 'LineWidth', 1.4, 'DisplayName', controller_label(controllers{k}));
end
set(ax, 'XTick', 1:numel(pertCases), 'XTickLabel', pertLabels);
xtickangle(ax, 15);
ylabel(ax, 'TV(u_2)');
title(ax, 'Control smoothness under parameter perturbation');
legend(ax, 'Location', 'best');

local_plot_param_perturbation_paper_summary(allResults, controllers, pertLabels);

paperRows = table();
for ic = 1:numel(pertCases)
    Tcase = summaryTabs{ic};
    Tlong = table(repmat(string(pertLabels(ic)), height(Tcase), 1), string(Tcase.names), Tcase.IAE_y2Global, Tcase.RMS_y2Global, ...
        Tcase.PeakY2Global, Tcase.RatioEbCtrl, Tcase.OverEbCtrl, Tcase.HitBoundaryCtrl, Tcase.PeakU2, Tcase.TVU2, Tcase.ISVU2, Tcase.PeakDz2, ...
        'VariableNames', {'Case', 'Controller', 'IAE_y2Global', 'RMS_y2Global', 'PeakY2Global', 'RatioEbCtrl', 'OverEbCtrl', 'HitBoundaryCtrl', 'PeakU2', 'TVU2', 'ISVU2', 'PeakDz2'});
    paperRows = [paperRows; Tlong]; %#ok<AGROW>
end

paperTables = struct( ...
    'name', 'Table06_parameter_perturbation_long', ...
    'table', paperRows, ...
    'purpose', 'Long-format robustness table across all parameter-perturbation cases and controllers.');

paperFigureMap = struct( ...
    'sourceName', 'Parameter perturbation - paper summary', ...
    'exportName', 'Fig04_parameter_robustness_and_smoothness', ...
    'purpose', 'Whole-beam robustness and control smoothness under parameter perturbation.');

paperParamTables = struct('name', {}, 'table', {}, 'purpose', {});
paperNotes = {'Experiment 6 is kept as a paper figure because it shows robustness across model mismatch, while the long-format table keeps the exact per-case numbers for reference.'};


function local_plot_param_perturbation_paper_summary(allResults, controllers, pertLabels)
figure('Name', 'Parameter perturbation - paper summary', 'Color', 'w');
tlo = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tlo);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
for k = 1:numel(controllers)
    vals = NaN(numel(pertLabels), 1);
    for ic = 1:numel(pertLabels)
        r = allResults{ic, k};
        if ~isempty(r)
            vals(ic) = r.metrics.IAE_y2Global;
        end
    end
    plot(ax1, 1:numel(pertLabels), vals, '-o', 'LineWidth', 1.3, 'DisplayName', controller_label(controllers{k}));
end
set(ax1, 'XTick', 1:numel(pertLabels), 'XTickLabel', pertLabels);
xtickangle(ax1, 15);
ylabel(ax1, 'IAE_{y_{2,g}}');
title(ax1, 'Whole-beam robustness');
legend(ax1, 'Location', 'best');

ax2 = nexttile(tlo);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
for k = 1:numel(controllers)
    vals = NaN(numel(pertLabels), 1);
    for ic = 1:numel(pertLabels)
        r = allResults{ic, k};
        if ~isempty(r)
            ext = calc_extended_metrics(r, inf, 0.05);
            vals(ic) = ext.TVU2;
        end
    end
    plot(ax2, 1:numel(pertLabels), vals, '-s', 'LineWidth', 1.3, 'DisplayName', controller_label(controllers{k}));
end
set(ax2, 'XTick', 1:numel(pertLabels), 'XTickLabel', pertLabels);
xtickangle(ax2, 15);
ylabel(ax2, 'TV(u_2)');
title(ax2, 'Control smoothness');
legend(ax2, 'Location', 'best');

title(tlo, 'Parameter perturbation: robustness vs smoothness');
end
