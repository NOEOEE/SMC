function axZoom = add_time_zoom_inset(ax, tWin, corner)
%ADD_TIME_ZOOM_INSET Create a separate early-time zoom figure for time-domain axes.
%
%   axZoom = add_time_zoom_inset(ax)
%   axZoom = add_time_zoom_inset(ax, [t0 t1])
%   axZoom = add_time_zoom_inset(ax, [t0 t1], corner)
%
% For compatibility with existing demo scripts, this helper keeps the old
% function name. The previous inset-axes behavior is intentionally removed:
% the zoomed segment is redrawn in a separate figure so it never overlaps
% with legends or important data in the main plot.
%
% The CORNER input is accepted for backward compatibility and ignored.

if nargin < 1 || isempty(ax) || ~ishandle(ax)
    axZoom = [];
    return;
end

if nargin < 2 || isempty(tWin)
    xl = xlim(ax);
    span = max(xl(2) - xl(1), eps);
    tWin = [xl(1), xl(1) + min(0.20 * span, 2.0)];
end

if nargin < 3 %#ok<INUSD>
    corner = 'northeast';
end

if numel(tWin) ~= 2 || tWin(2) <= tWin(1)
    axZoom = [];
    return;
end

xl = xlim(ax);
tWin(1) = max(tWin(1), xl(1));
tWin(2) = min(tWin(2), xl(2));
if tWin(2) <= tWin(1)
    axZoom = [];
    return;
end

lineList = flipud(findobj(ax, 'Type', 'Line'));
if isempty(lineList)
    axZoom = [];
    return;
end

figMain = ancestor(ax, 'figure');
mainName = '';
if ishghandle(figMain)
    try
        mainName = string(get(figMain, 'Name'));
    catch
        mainName = "";
    end
end
mainName = char(mainName);
if isempty(strtrim(mainName))
    mainName = 'Time response';
end

mainTitle = '';
try
    ttl = get(get(ax, 'Title'), 'String');
    if iscell(ttl)
        ttl = strjoin(ttl, ' ');
    end
    mainTitle = char(ttl);
catch
    mainTitle = '';
end
if isempty(strtrim(mainTitle))
    mainTitle = mainName;
end

axZoomFig = figure('Name', [mainName, ' - local zoom'], 'Color', 'w'); %#ok<NASGU>
axZoom = axes; hold(axZoom, 'on'); grid(axZoom, 'on'); box(axZoom, 'on');
set(axZoom, 'FontSize', get(ax, 'FontSize'), 'LineWidth', get(ax, 'LineWidth'));

varyingVals = [];
allVals = [];
hasDisplayName = false;
for k = 1:numel(lineList)
    x = get(lineList(k), 'XData');
    y = get(lineList(k), 'YData');
    if isempty(x) || isempty(y)
        continue;
    end
    x = x(:);
    y = y(:);
    n = min(numel(x), numel(y));
    x = x(1:n);
    y = y(1:n);

    idx = (x >= tWin(1)) & (x <= tWin(2));
    if ~any(idx)
        continue;
    end

    xw = x(idx);
    yw = y(idx);

    dispName = get(lineList(k), 'DisplayName');
    if isstring(dispName)
        dispName = char(dispName);
    end
    if ~isempty(strtrim(dispName)) && ~strcmpi(strtrim(dispName), 'data1')
        hasDisplayName = true;
    end

    args = {
        'LineStyle', get(lineList(k), 'LineStyle'), ...
        'Color', get(lineList(k), 'Color'), ...
        'LineWidth', get(lineList(k), 'LineWidth'), ...
        'Marker', get(lineList(k), 'Marker'), ...
        'MarkerSize', get(lineList(k), 'MarkerSize'), ...
        'DisplayName', dispName};

    if isprop(lineList(k), 'MarkerFaceColor')
        args = [args, {'MarkerFaceColor', get(lineList(k), 'MarkerFaceColor')}]; %#ok<AGROW>
    end
    if isprop(lineList(k), 'MarkerEdgeColor')
        args = [args, {'MarkerEdgeColor', get(lineList(k), 'MarkerEdgeColor')}]; %#ok<AGROW>
    end

    plot(axZoom, xw, yw, args{:});

    allVals = [allVals; yw(:)]; %#ok<AGROW>
    if range(yw) > 1e-10
        varyingVals = [varyingVals; yw(:)]; %#ok<AGROW>
    end
end

xlim(axZoom, tWin);
if isempty(varyingVals)
    useVals = allVals;
else
    useVals = varyingVals;
end

if isempty(useVals)
    ylim(axZoom, get(ax, 'YLim'));
else
    yMin = min(useVals);
    yMax = max(useVals);
    spanY = yMax - yMin;
    if spanY < 1e-12
        padY = max(0.1 * max(abs([yMin; yMax])), 1e-3);
    else
        padY = 0.12 * spanY;
    end
    ylim(axZoom, [yMin - padY, yMax + padY]);
end

xlabel(axZoom, get(get(ax, 'XLabel'), 'String'));
ylabel(axZoom, get(get(ax, 'YLabel'), 'String'));
title(axZoom, sprintf('%s (local zoom, %.3g-%.3g s)', mainTitle, tWin(1), tWin(2)));

if hasDisplayName
    legend(axZoom, 'Location', 'best');
end
end
