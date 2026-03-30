% function run_all_demos()
%RUN_ALL_DEMOS Run all demos in live mode with automatic saving.
%
% Features:
%   1) Command-window output is printed live when diary is available
%   2) VS Code / no-desktop sessions fall back to evalc-based log capture
%   3) Command window is not cleared between demos
%   4) Figures, tables, logs, and workspace snapshots are saved automatically
%   5) Temporary demo copies are created with clear/clc/close-all removed
%
% Recommended usage:
%   >> run_all_demos

close all force;

cfg = local_default_config();
local_ensure_dir(cfg.outputRoot);
local_ensure_dir(cfg.tempRoot);
local_ensure_dir(cfg.logRoot);

% Make sure project root stays on MATLAB path.
if ~contains(path, cfg.projectRoot)
    addpath(cfg.projectRoot);
end

demoList = { ...
    'demo_check_physical_params', ...
    'demo_beam_measurement_weights', ...
    'demo_compare_all', ...
    'demo_open_loop_baseline', ...
    'demo_constraint_stress', ...
    'demo_eso_bandwidth', ...
    'demo_strong_disturbance', ...
    'demo_param_perturbation_compare', ...
    'demo_observer_estimation', ...
    'demo_modal_state_eso_estimation', ...
    'demo_chattering_compare', ...
    'demo_paper_style_validation', ...
    'demo_modal_zoom_compare'};

fprintf('\n');
fprintf('============================================================\n');
fprintf('Running all demos in live mode with automatic saving\n');
fprintf('Project root:\n  %s\n', cfg.projectRoot);
fprintf('Output folder:\n  %s\n', cfg.outputRoot);
fprintf('Global log folder:\n  %s\n', cfg.logRoot);
fprintf('Log mode:\n  %s\n', cfg.logMode);
fprintf('============================================================\n');

local_write_run_readme(cfg);

summaryNames = cell(numel(demoList), 1);
summaryStatus = cell(numel(demoList), 1);
summaryOutputDir = cell(numel(demoList), 1);
summaryFigureCount = zeros(numel(demoList), 1);
summaryTableCount = zeros(numel(demoList), 1);
summaryElapsedSec = zeros(numel(demoList), 1);
summaryError = cell(numel(demoList), 1);
summaryPaperFigureCount = zeros(numel(demoList), 1);
summaryPaperTableCount = zeros(numel(demoList), 1);
summaryPaperParamCount = zeros(numel(demoList), 1);

for k = 1:numel(demoList)
    demoName = demoList{k};

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('[%02d/%02d] Starting %s\n', k, numel(demoList), demoName);
    fprintf('============================================================\n');

    info = local_run_single_demo_live(demoName, k, cfg);

    summaryNames{k} = info.demoName;
    summaryStatus{k} = info.status;
    summaryOutputDir{k} = info.demoDir;
    summaryFigureCount(k) = info.figureCount;
    summaryTableCount(k) = info.tableCount;
    summaryElapsedSec(k) = info.elapsedSec;
    summaryError{k} = info.errorMessage;
    summaryPaperFigureCount(k) = info.paperFigureCount;
    summaryPaperTableCount(k) = info.paperTableCount;
    summaryPaperParamCount(k) = info.paperParamTableCount;

    fprintf('\n');
    fprintf('[%s] status : %s\n', info.demoName, info.status);
    fprintf('[%s] figures: %d\n', info.demoName, info.figureCount);
    fprintf('[%s] tables : %d\n', info.demoName, info.tableCount);
    fprintf('[%s] paper  : %d figs, %d tables, %d param tables\n', ...
        info.demoName, info.paperFigureCount, info.paperTableCount, info.paperParamTableCount);
    fprintf('[%s] folder : %s\n', info.demoName, info.demoDir);
    if ~isempty(info.errorMessage)
        fprintf('[%s] error  : %s\n', info.demoName, info.errorMessage);
    end
end

runSummary = table(summaryNames, summaryStatus, summaryFigureCount, summaryTableCount, ...
    summaryPaperFigureCount, summaryPaperTableCount, summaryPaperParamCount, ...
    summaryElapsedSec, summaryOutputDir, summaryError, ...
    'VariableNames', {'Demo', 'Status', 'FigureCount', 'TableCount', ...
    'PaperFigureCount', 'PaperTableCount', 'PaperParamTableCount', ...
    'ElapsedSec', 'OutputDir', 'ErrorMessage'});

disp(runSummary);

local_safe_writetable(runSummary, ...
    fullfile(cfg.outputRoot, 'run_summary.csv'), ...
    fullfile(cfg.outputRoot, 'run_summary.xlsx'));

save(fullfile(cfg.outputRoot, 'run_summary.mat'), 'runSummary');

if isfield(cfg, 'paper') && isfield(cfg.paper, 'enable') && cfg.paper.enable
    paperFigureMap = struct('sourceName', {}, 'exportName', {}, 'purpose', {}); %#ok<NASGU>
    paperTables = struct('name', {}, 'table', {}, 'purpose', {}); %#ok<NASGU>
    paperParamTables = paper_build_param_tables(); %#ok<NASGU>
    paperNotes = {'Global parameter tables were exported from nominal, disturbance, and stress configurations.'}; %#ok<NASGU>
    paperInfoGlobal = paper_collect_assets('global_parameters', cfg.outputRoot, cfg.paper); %#ok<NASGU>
    fprintf('[paper] global parameter tables exported: %d\n', paperInfoGlobal.paramTableCount);
end

fprintf('\nAll demos finished.\n');
fprintf('Results saved to:\n  %s\n', cfg.outputRoot);
if isfield(cfg, 'paper') && isfield(cfg.paper, 'enable') && cfg.paper.enable
    fprintf('Paper exports saved to:\n  %s\n', fullfile(cfg.outputRoot, cfg.paper.rootName));
end

% end

function cfg = local_default_config()
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

cfg.projectRoot = fileparts(mfilename('fullpath'));
cfg.outputRoot  = fullfile(cfg.projectRoot, 'results', ['run_all_demos_', timestamp]);
cfg.tempRoot    = fullfile(tempdir, ['run_all_demos_live_', timestamp]);

cfg.savePng = true;
cfg.savePdf = false;
cfg.saveFig = true;
cfg.saveCsv = true;
cfg.saveXlsx = true;
cfg.saveMat = true;
cfg.keepAllFiguresOpen = false;  % isolate demos and avoid cross-demo figure carry-over
cfg.logRoot = fullfile(cfg.outputRoot, 'logs');
cfg.logMode = local_choose_log_mode();

cfg.paper.enable = true;
cfg.paper.rootName = 'paper_exports';
cfg.paper.savePng = true;
cfg.paper.savePdf = true;
cfg.paper.saveFig = true;
cfg.paper.pngDpi = 600;
end

function mode = local_choose_log_mode()
termProgram = lower(strtrim(getenv('TERM_PROGRAM')));
if contains(termProgram, 'vscode')
    mode = 'evalc';
    return;
end

try
    desktopInUse = desktop('-inuse');
catch
    desktopInUse = false;
end

if usejava('desktop') && desktopInUse
    mode = 'diary';
else
    mode = 'evalc';
end
end

function info = local_run_single_demo_live(demoName, demoIndex, cfg)
info = struct();
info.demoName = demoName;
info.demoIndex = demoIndex;
info.status = 'SUCCESS';
info.errorMessage = '';
info.figureCount = 0;
info.tableCount = 0;
info.paperFigureCount = 0;
info.paperTableCount = 0;
info.paperParamTableCount = 0;
info.elapsedSec = NaN;
info.demoDir = fullfile(cfg.outputRoot, sprintf('%02d_%s', demoIndex, demoName));

logDir = cfg.logRoot;
figDir = fullfile(info.demoDir, 'figures');
tableDir = fullfile(info.demoDir, 'tables');
matDir = fullfile(info.demoDir, 'mats');

local_ensure_dir(info.demoDir);
local_ensure_dir(logDir);
local_ensure_dir(figDir);
local_ensure_dir(tableDir);
local_ensure_dir(matDir);

tempScriptPath = fullfile(cfg.tempRoot, [demoName, '_live_tmp.m']);
local_make_temp_demo_copy(demoName, tempScriptPath);

% Isolate each demo: close any figure left from a previous demo before running.
try
    close(findall(groot, 'Type', 'figure'));
catch
end
drawnow;

beforeFigs = findall(groot, 'Type', 'figure');

logPath = fullfile(logDir, [demoName, '_command_window.txt']);
sourceTxtPath = fullfile(logDir, [demoName, '_source_snapshot.txt']);

local_save_demo_source_snapshot(tempScriptPath, sourceTxtPath);
local_prepare_log_file(logPath, demoName, cfg);

oldDir = pwd;
cleanupObj = onCleanup(@() local_restore_after_demo(oldDir)); %#ok<NASGU>

tStart = tic;
try
    % Critical fix: ensure project root is current folder and on path.
    cd(cfg.projectRoot);
    if ~contains(path, cfg.projectRoot)
        addpath(cfg.projectRoot);
    end

    if strcmpi(cfg.logMode, 'diary')
        diary off;
        diary(logPath);
        diary on;
        run(tempScriptPath);
        diary off;
    else
        capturedText = evalc('run(tempScriptPath);');
        local_append_text(logPath, capturedText);
        fprintf('%s', capturedText);
    end

catch ME
    info.status = 'FAILED';
    info.errorMessage = getReport(ME, 'extended', 'hyperlinks', 'off');
    disp(info.errorMessage);

    if ~isempty(info.errorMessage)
        local_append_text(logPath, sprintf('\n\n[ERROR REPORT]\n%s\n', info.errorMessage));
    end

    fid = fopen(fullfile(logDir, [demoName, '_error.txt']), 'w');
    if fid >= 0
        fprintf(fid, '%s', info.errorMessage);
        fclose(fid);
    end
end
info.elapsedSec = toc(tStart);

diary off;
local_finalize_log_file(logPath, demoName, info, cfg);

info.tableCount = local_export_current_tables(tableDir, cfg);
info.figureCount = local_export_new_figures(beforeFigs, figDir, demoName, cfg);

if isfield(cfg, 'paper') && isfield(cfg.paper, 'enable') && cfg.paper.enable
    paperInfo = paper_collect_assets(info.demoName, cfg.outputRoot, cfg.paper);
    info.paperFigureCount = paperInfo.figureCount;
    info.paperTableCount = paperInfo.tableCount;
    info.paperParamTableCount = paperInfo.paramTableCount;
end

if cfg.saveMat
    local_save_current_workspace_snapshot(matDir, demoName);
end

if ~cfg.keepAllFiguresOpen
    try
        close(findall(groot, 'Type', 'figure'));
    catch
    end
end

end

function out = local_run_with_evalc(tempScriptPath)
out = '';
out = evalc('run(tempScriptPath);');
end

function local_make_temp_demo_copy(demoName, tempScriptPath)
srcPath = which(demoName);
if isempty(srcPath)
    srcPath = fullfile(fileparts(mfilename('fullpath')), [demoName, '.m']);
end
if ~exist(srcPath, 'file')
    error('Could not find demo file: %s.m', demoName);
end

txt = fileread(srcPath);

txt = regexprep(txt, '^\s*clc\s*;\s*$', '', 'lineanchors');
txt = regexprep(txt, '^\s*clear\s*;\s*$', '', 'lineanchors');
txt = regexprep(txt, '^\s*clearvars\s*;\s*$', '', 'lineanchors');
txt = regexprep(txt, '^\s*clearvars\s+-except\s+ans\s*;\s*$', '', 'lineanchors');
txt = regexprep(txt, '^\s*close\s+all\s*;\s*$', '', 'lineanchors');
txt = regexprep(txt, '^\s*close\s+all\s+force\s*;\s*$', '', 'lineanchors');

fid = fopen(tempScriptPath, 'w');
if fid < 0
    error('Could not write temporary demo file: %s', tempScriptPath);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', txt);
end

function tableCount = local_export_current_tables(tableDir, cfg)
vars = evalin('caller', 'whos');
tableCount = 0;

internalNames = { ...
    'cfg', 'demoList', 'summaryNames', 'summaryStatus', 'summaryOutputDir', ...
    'summaryFigureCount', 'summaryTableCount', 'summaryElapsedSec', 'summaryError', ...
    'summaryPaperFigureCount', 'summaryPaperTableCount', 'summaryPaperParamCount', ...
    'runSummary', 'k', 'demoName', 'info', 'timestamp', 'oldDir', 'cleanupObj', ...
    'paperInfoGlobal', 'paperInfo', 'paperFigureMap', 'paperTables', 'paperParamTables', 'paperNotes', ...
    'capturedText', 'logDir', 'figDir', 'tableDir', 'matDir', 'sourceTxtPath', 'logPath', ...
    'tempScriptPath', 'tStart', 'beforeFigs', 'afterFigs', 'newFigs'};

for i = 1:numel(vars)
    varName = vars(i).name;

    if strcmp(varName, 'ans')
        continue;
    end
    if startsWith(varName, 'beforeFig')
        continue;
    end
    if any(strcmp(varName, internalNames))
        continue;
    end

    try
        value = evalin('caller', varName);
    catch
        continue;
    end

    if istable(value)
        tableCount = tableCount + 1;
        baseName = local_make_valid_filename(varName);
        local_save_table(value, tableDir, baseName, cfg);
    elseif iscell(value)
        for j = 1:numel(value)
            try
                item = value{j};
            catch
                continue;
            end
            if istable(item)
                tableCount = tableCount + 1;
                baseName = sprintf('%s_%02d', local_make_valid_filename(varName), j);
                local_save_table(item, tableDir, baseName, cfg);
            end
        end
    end
end
end

function figCount = local_export_new_figures(beforeFigs, figDir, demoName, cfg)
afterFigs = findall(groot, 'Type', 'figure');

if isempty(afterFigs)
    figCount = 0;
    return;
end

% Export only figures created during the current demo.
if isempty(beforeFigs)
    newFigs = afterFigs;
else
    isOld = arrayfun(@(h) any(h == beforeFigs), afterFigs);
    newFigs = afterFigs(~isOld);
end

if isempty(newFigs)
    figCount = 0;
    return;
end

figCount = local_export_figures(newFigs, figDir, demoName, cfg);
end

function num = local_get_figure_number(h)
try
    num = double(h.Number);
catch
    num = NaN;
end
end

function local_save_table(T, tableDir, baseName, cfg)
if cfg.saveCsv
    try
        writetable(T, fullfile(tableDir, [baseName, '.csv']));
    catch ME
        warning('Failed to write CSV for %s: %s', baseName, ME.message);
    end
end

if cfg.saveXlsx
    try
        writetable(T, fullfile(tableDir, [baseName, '.xlsx']), 'FileType', 'spreadsheet');
    catch ME
        warning('Failed to write XLSX for %s: %s', baseName, ME.message);
    end
end
end

function figCount = local_export_figures(figHandles, figDir, demoName, cfg)
figCount = 0;

if isempty(figHandles)
    return;
end

validMask = arrayfun(@ishandle, figHandles);
figHandles = figHandles(validMask);

if isempty(figHandles)
    return;
end

figNums = zeros(numel(figHandles), 1);
for i = 1:numel(figHandles)
    figNums(i) = local_get_figure_number(figHandles(i));
    if isnan(figNums(i))
        figNums(i) = i;
    end
end

[~, order] = sort(figNums);
figHandles = figHandles(order);

for i = 1:numel(figHandles)
    h = figHandles(i);
    if ~ishandle(h)
        continue;
    end

    figCount = figCount + 1;

    figName = get(h, 'Name');
    if isempty(figName)
        figName = sprintf('%s_fig_%02d', demoName, i);
    else
        figName = sprintf('%02d_%s', i, figName);
    end
    figName = local_make_valid_filename(figName);

    if cfg.saveFig
        try
            savefig(h, fullfile(figDir, [figName, '.fig']));
        catch ME
            warning('Failed to save FIG for %s: %s', figName, ME.message);
        end
    end

    if cfg.savePng
        try
            print(h, fullfile(figDir, [figName, '.png']), '-dpng', '-r300');
        catch ME
            warning('Failed to save PNG for %s: %s', figName, ME.message);
        end
    end

    if cfg.savePdf
        try
            set(h, 'PaperPositionMode', 'auto');
            print(h, fullfile(figDir, [figName, '.pdf']), '-dpdf', '-painters');
        catch ME
            warning('Failed to save PDF for %s: %s', figName, ME.message);
        end
    end
end
end

function local_save_current_workspace_snapshot(matDir, demoName)
vars = evalin('caller', 'whos');
keepNames = {};

internalNames = { ...
    'cfg', 'demoList', 'summaryNames', 'summaryStatus', 'summaryOutputDir', ...
    'summaryFigureCount', 'summaryTableCount', 'summaryElapsedSec', 'summaryError', ...
    'summaryPaperFigureCount', 'summaryPaperTableCount', 'summaryPaperParamCount', ...
    'runSummary', 'k', 'demoName', 'info', 'timestamp', 'oldDir', 'cleanupObj', ...
    'paperInfoGlobal', 'paperInfo', 'paperFigureMap', 'paperTables', 'paperParamTables', 'paperNotes', ...
    'capturedText', 'logDir', 'figDir', 'tableDir', 'matDir', 'sourceTxtPath', 'logPath', ...
    'tempScriptPath', 'tStart', 'beforeFigs', 'afterFigs', 'newFigs'};

for i = 1:numel(vars)
    varName = vars(i).name;

    if strcmp(varName, 'ans')
        continue;
    end
    if startsWith(varName, 'beforeFig')
        continue;
    end
    if any(strcmp(varName, internalNames))
        continue;
    end

    keepNames{end+1} = varName; %#ok<AGROW>
end

if isempty(keepNames)
    return;
end

matPath = fullfile(matDir, [demoName, '_workspace_snapshot.mat']);
try
    quotedNames = '';
    for i = 1:numel(keepNames)
        quotedNames = [quotedNames, sprintf(', ''%s''', keepNames{i})]; %#ok<AGROW>
    end
    evalin('caller', sprintf('save(''%s''%s);', matPath, quotedNames));
catch ME
    warning('Failed to save workspace snapshot for %s: %s', demoName, ME.message);
end
end

function local_safe_writetable(T, csvPath, xlsxPath)
try
    writetable(T, csvPath);
catch ME
    warning('Failed to write summary CSV: %s', ME.message);
end

try
    writetable(T, xlsxPath, 'FileType', 'spreadsheet');
catch ME
    warning('Failed to write summary XLSX: %s', ME.message);
end
end

function local_write_run_readme(cfg)
readmePath = fullfile(cfg.outputRoot, 'README_results.txt');

lines = { ...
    'This folder was generated by run_all_demos.m in live mode.', ...
    '', ...
    'The runner saves:', ...
    '  - logs/<demo>_command_window.txt in the global logs folder', ...
    '  - logs/<demo>_source_snapshot.txt in the global logs folder', ...
    '  - logs/<demo>_error.txt in the global logs folder if the demo fails', ...
    '  - <demo>/tables/*.csv and *.xlsx for table variables found after the demo', ...
    '  - <demo>/figures/*.fig *.png *.pdf for figures created by the demo', ...
    '  - <demo>/mats/*_workspace_snapshot.mat for the remaining workspace variables', ...
    '  - paper_exports/ for the curated paper-ready figures and tables', ...
    '', ...
    ['Project root: ', cfg.projectRoot], ...
    ['Result root: ', cfg.outputRoot], ...
    ['Global log root: ', cfg.logRoot], ...
    ['Paper export root: ', fullfile(cfg.outputRoot, cfg.paper.rootName)], ...
    ['Log mode: ', cfg.logMode]};

fid = fopen(readmePath, 'w');
if fid < 0
    warning('Could not open file for writing: %s', readmePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end

function local_prepare_log_file(logPath, demoName, cfg)
folderPath = fileparts(logPath);
local_ensure_dir(folderPath);

if exist(logPath, 'file')
    try
        delete(logPath);
    catch
    end
end

fid = fopen(logPath, 'w');
if fid >= 0
    fprintf(fid, 'Demo: %s\n', demoName);
    fprintf(fid, 'Start time: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'Log mode: %s\n', cfg.logMode);
    fprintf(fid, '============================================================\n\n');
    fclose(fid);
end
end

function local_finalize_log_file(logPath, demoName, info, cfg)
pause(0.05);

fid = fopen(logPath, 'a');
if fid < 0
    return;
end
fprintf(fid, '\n============================================================\n');
fprintf(fid, 'Demo: %s\n', demoName);
fprintf(fid, 'Finish time: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, 'Log mode: %s\n', cfg.logMode);
fprintf(fid, 'Status: %s\n', info.status);
fprintf(fid, 'ElapsedSec: %.6f\n', info.elapsedSec);
if ~isempty(info.errorMessage)
    fprintf(fid, '\nErrorMessage:\n%s\n', info.errorMessage);
end
fclose(fid);
end

function local_save_demo_source_snapshot(srcPath, dstPath)
try
    txt = fileread(srcPath);
    fid = fopen(dstPath, 'w');
    if fid >= 0
        fprintf(fid, '%s', txt);
        fclose(fid);
    end
catch
end
end

function local_append_text(filePath, txt)
if isempty(txt)
    return;
end
fid = fopen(filePath, 'a');
if fid < 0
    return;
end
fprintf(fid, '%s', txt);
fclose(fid);
end

function local_restore_after_demo(oldDir)
try
    diary off;
catch
end
try
    cd(oldDir);
catch
end
end

function local_ensure_dir(folderPath)
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end
end

function name = local_make_valid_filename(raw)
name = char(string(raw));
name = regexprep(name, '[\\/:*?"<>|[:space:]]+', '_');
name = regexprep(name, '_+', '_');
name = regexprep(name, '^_+|_+$', '');
if isempty(name)
    name = 'unnamed';
end
end
