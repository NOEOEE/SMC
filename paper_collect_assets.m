function info = paper_collect_assets(demoName, outputRoot, cfgPaper)
%PAPER_COLLECT_ASSETS Export the paper-focused figures and tables declared by a demo.
%
% The caller workspace may define any of the following variables:
%   paperFigureMap   : struct array with fields sourceName, exportName, purpose
%   paperTables      : struct array with fields name, table, purpose
%   paperParamTables : struct array with fields name, table, purpose
%   paperNotes       : cellstr / string array with free-form notes
%
% The assets are written to
%   <outputRoot>/paper_exports/{figures,tables,params}
%
% This helper intentionally reads from the caller workspace so it can be
% used directly inside run_all_demos.m after a script demo has finished.

if nargin < 1 || isempty(demoName)
    demoName = 'unnamed_demo';
end
if nargin < 2 || isempty(outputRoot)
    outputRoot = pwd;
end
if nargin < 3 || isempty(cfgPaper)
    cfgPaper = struct();
end

cfgPaper = local_fill_default_cfg(cfgPaper);

paperRoot = fullfile(outputRoot, cfgPaper.rootName);
figRoot   = fullfile(paperRoot, 'figures');
tableRoot = fullfile(paperRoot, 'tables');
paramRoot = fullfile(paperRoot, 'params');
readmePath = fullfile(paperRoot, 'README_paper_assets.txt');

local_ensure_dir(paperRoot);
local_ensure_dir(figRoot);
local_ensure_dir(tableRoot);
local_ensure_dir(paramRoot);
local_init_readme(readmePath, outputRoot);

info = struct();
info.figureCount = 0;
info.tableCount = 0;
info.paramTableCount = 0;

paperFigureMap = local_get_from_caller('paperFigureMap', struct('sourceName', {}, 'exportName', {}, 'purpose', {}));
paperTables = local_get_from_caller('paperTables', struct('name', {}, 'table', {}, 'purpose', {}));
paperParamTables = local_get_from_caller('paperParamTables', struct('name', {}, 'table', {}, 'purpose', {}));
paperNotes = local_get_from_caller('paperNotes', {});

if ~isempty(paperFigureMap)
    figHandles = findall(groot, 'Type', 'figure');
    for k = 1:numel(paperFigureMap)
        spec = paperFigureMap(k);
        if ~isfield(spec, 'sourceName') || ~isfield(spec, 'exportName')
            warning('paper_collect_assets:BadFigureSpec', ...
                'Skipping malformed paperFigureMap entry %d for demo %s.', k, demoName);
            continue;
        end

        h = local_find_figure_by_name(figHandles, spec.sourceName);
        if isempty(h)
            warning('paper_collect_assets:FigureNotFound', ...
                'Could not find figure "%s" for demo %s.', spec.sourceName, demoName);
            continue;
        end

        local_apply_paper_style(h);
        baseName = local_make_valid_filename(spec.exportName);
        local_export_single_figure(h, figRoot, baseName, cfgPaper);
        info.figureCount = info.figureCount + 1;

        purpose = '';
        if isfield(spec, 'purpose') && ~isempty(spec.purpose)
            purpose = char(spec.purpose);
        end
        local_append_readme_line(readmePath, sprintf('[%s] FIG  %s  %s', demoName, baseName, purpose));
    end
end

if ~isempty(paperTables)
    for k = 1:numel(paperTables)
        spec = paperTables(k);
        if ~isfield(spec, 'name') || ~isfield(spec, 'table') || ~istable(spec.table)
            warning('paper_collect_assets:BadTableSpec', ...
                'Skipping malformed paperTables entry %d for demo %s.', k, demoName);
            continue;
        end
        baseName = local_make_valid_filename(spec.name);
        local_write_table(spec.table, tableRoot, baseName);
        info.tableCount = info.tableCount + 1;

        purpose = '';
        if isfield(spec, 'purpose') && ~isempty(spec.purpose)
            purpose = char(spec.purpose);
        end
        local_append_readme_line(readmePath, sprintf('[%s] TABLE %s  %s', demoName, baseName, purpose));
    end
end

if ~isempty(paperParamTables)
    for k = 1:numel(paperParamTables)
        spec = paperParamTables(k);
        if ~isfield(spec, 'name') || ~isfield(spec, 'table') || ~istable(spec.table)
            warning('paper_collect_assets:BadParamSpec', ...
                'Skipping malformed paperParamTables entry %d for demo %s.', k, demoName);
            continue;
        end
        baseName = local_make_valid_filename(spec.name);
        local_write_table(spec.table, paramRoot, baseName);
        info.paramTableCount = info.paramTableCount + 1;

        purpose = '';
        if isfield(spec, 'purpose') && ~isempty(spec.purpose)
            purpose = char(spec.purpose);
        end
        local_append_readme_line(readmePath, sprintf('[%s] PARAM %s  %s', demoName, baseName, purpose));
    end
end

if ~isempty(paperNotes)
    if ischar(paperNotes)
        paperNotes = {paperNotes};
    elseif isstring(paperNotes)
        paperNotes = cellstr(paperNotes(:));
    end
    for k = 1:numel(paperNotes)
        local_append_readme_line(readmePath, sprintf('[%s] NOTE  %s', demoName, char(paperNotes{k})));
    end
end
end

function cfgPaper = local_fill_default_cfg(cfgPaper)
if ~isfield(cfgPaper, 'rootName') || isempty(cfgPaper.rootName)
    cfgPaper.rootName = 'paper_exports';
end
if ~isfield(cfgPaper, 'savePng')
    cfgPaper.savePng = true;
end
if ~isfield(cfgPaper, 'savePdf')
    cfgPaper.savePdf = true;
end
if ~isfield(cfgPaper, 'saveFig')
    cfgPaper.saveFig = true;
end
if ~isfield(cfgPaper, 'pngDpi') || isempty(cfgPaper.pngDpi)
    cfgPaper.pngDpi = 600;
end
end

function value = local_get_from_caller(varName, defaultValue)
existsFlag = evalin('caller', sprintf('exist(''%s'', ''var'')', varName));
if existsFlag
    value = evalin('caller', varName);
else
    value = defaultValue;
end
end

function h = local_find_figure_by_name(figHandles, targetName)
h = [];
if isempty(figHandles)
    return;
end
for k = 1:numel(figHandles)
    if ~ishandle(figHandles(k))
        continue;
    end
    figName = get(figHandles(k), 'Name');
    if isequal(figName, targetName)
        h = figHandles(k);
        return;
    end
end
end

function local_apply_paper_style(hFig)
if isempty(hFig) || ~ishandle(hFig)
    return;
end
set(hFig, 'Color', 'w');
axList = findall(hFig, 'Type', 'axes');
for ia = 1:numel(axList)
    ax = axList(ia);
    try
        set(ax, 'FontSize', 10, 'LineWidth', 1.0, 'Box', 'on');
    catch
    end
    try
        grid(ax, 'on');
    catch
    end

    lineList = findall(ax, 'Type', 'line');
    for il = 1:numel(lineList)
        try
            set(lineList(il), 'LineWidth', max(get(lineList(il), 'LineWidth'), 1.1));
        catch
        end
    end
end
end

function local_export_single_figure(hFig, outDir, baseName, cfgPaper)
if cfgPaper.saveFig
    try
        savefig(hFig, fullfile(outDir, [baseName, '.fig']));
    catch ME
        warning('paper_collect_assets:SaveFigFailed', ...
            'Failed to save FIG for %s: %s', baseName, ME.message);
    end
end

if cfgPaper.savePng
    try
        print(hFig, fullfile(outDir, [baseName, '.png']), '-dpng', sprintf('-r%d', cfgPaper.pngDpi));
    catch ME
        warning('paper_collect_assets:SavePngFailed', ...
            'Failed to save PNG for %s: %s', baseName, ME.message);
    end
end

if cfgPaper.savePdf
    try
        set(hFig, 'PaperPositionMode', 'auto');
        print(hFig, fullfile(outDir, [baseName, '.pdf']), '-dpdf', '-painters');
    catch ME
        warning('paper_collect_assets:SavePdfFailed', ...
            'Failed to save PDF for %s: %s', baseName, ME.message);
    end
end
end

function local_write_table(T, outDir, baseName)
try
    writetable(T, fullfile(outDir, [baseName, '.csv']));
catch ME
    warning('paper_collect_assets:WriteCsvFailed', ...
        'Failed to write CSV for %s: %s', baseName, ME.message);
end

try
    writetable(T, fullfile(outDir, [baseName, '.xlsx']), 'FileType', 'spreadsheet');
catch ME
    warning('paper_collect_assets:WriteXlsxFailed', ...
        'Failed to write XLSX for %s: %s', baseName, ME.message);
end
end

function local_init_readme(readmePath, outputRoot)
if exist(readmePath, 'file')
    return;
end
fid = fopen(readmePath, 'w');
if fid < 0
    warning('paper_collect_assets:ReadmeOpenFailed', ...
        'Could not initialize paper readme: %s', readmePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'Paper-focused exports generated by run_all_demos.m\n');
fprintf(fid, 'Output root: %s\n', outputRoot);
fprintf(fid, 'Each line below records one recommended figure / table / parameter table.\n\n');
end

function local_append_readme_line(readmePath, lineText)
fid = fopen(readmePath, 'a');
if fid < 0
    warning('paper_collect_assets:ReadmeAppendFailed', ...
        'Could not append to paper readme: %s', readmePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', lineText);
end

function local_ensure_dir(folderPath)
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end
end

function nameOut = local_make_valid_filename(nameIn)
nameOut = char(string(nameIn));
nameOut = regexprep(nameOut, '[\\/:*?"<>|]', '_');
nameOut = regexprep(nameOut, '\s+', '_');
nameOut = regexprep(nameOut, '_+', '_');
nameOut = strtrim(nameOut);
if isempty(nameOut)
    nameOut = 'unnamed';
end
end
