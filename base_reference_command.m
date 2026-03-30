function ref = base_reference_command(t, p)
%BASE_REFERENCE_COMMAND Reference generator for angle/second-output channels.
%   ref.y   = [y1d;  y2d]
%   ref.dy  = [dy1d; dy2d]
%   ref.ddy = [ddy1d; ddy2d]
%
% This version supports two modes:
%   1) Hold mode: if p.ref.Tmove <= 0, y1d is directly held at p.ref.y1Target.
%   2) Rest-to-rest mode: if p.ref.Tmove > 0, y1d follows a quintic profile
%      from y1Start to y1Target over [0, Tmove], then stays constant.
%
% Expected fields in p.ref (missing fields are auto-filled with defaults):
%   y1Target : final commanded angle
%   y1Start  : initial reference angle (default 0)
%   y2d      : second-channel reference (default 0)
%   Tmove    : maneuver duration; <=0 means direct constant hold (default 0)

    if nargin < 2
        error('base_reference_command requires inputs (t, p).');
    end

    % -----------------------
    % defaults / compatibility
    % -----------------------
    if ~isfield(p, 'ref')
        p.ref = struct();
    end
    if ~isfield(p.ref, 'y1Target')
        if isfield(p.ref, 'a1')
            p.ref.y1Target = p.ref.a1;
        else
            p.ref.y1Target = 0.0;
        end
    end
    if ~isfield(p.ref, 'y1Start')
        p.ref.y1Start = 0.0;
    end
    if ~isfield(p.ref, 'y2d')
        p.ref.y2d = 0.0;
    end
    if ~isfield(p.ref, 'Tmove')
        if isfield(p.ref, 'b1')
            p.ref.Tmove = p.ref.b1;
        else
            p.ref.Tmove = 0.0;
        end
    end

    % -------------------------------------------------
    % Put the user's requested if-block exactly HERE:
    % after defaults are resolved, before any trajectory
    % polynomial / smooth-step calculation.
    % -------------------------------------------------
    if p.ref.Tmove <= 0
        y1d   = p.ref.y1Target;
        dy1d  = 0;
        ddy1d = 0;
        y2d   = p.ref.y2d;
        dy2d  = 0;
        ddy2d = 0;
        ref.y   = [y1d; y2d];
        ref.dy  = [dy1d; dy2d];
        ref.ddy = [ddy1d; ddy2d];
        return;
    end

    % -----------------------
    % quintic rest-to-rest law
    % -----------------------
    T = p.ref.Tmove;
    y0 = p.ref.y1Start;
    yf = p.ref.y1Target;

    if t <= 0
        s = 0; ds = 0; dds = 0;
    elseif t >= T
        s = 1; ds = 0; dds = 0;
    else
        tau = t / T;
        s   = 10*tau^3 - 15*tau^4 + 6*tau^5;
        ds  = (30*tau^2 - 60*tau^3 + 30*tau^4) / T;
        dds = (60*tau - 180*tau^2 + 120*tau^3) / T^2;
    end

    y1d   = y0 + (yf - y0) * s;
    dy1d  = (yf - y0) * ds;
    ddy1d = (yf - y0) * dds;

    y2d   = p.ref.y2d;
    dy2d  = 0;
    ddy2d = 0;

    ref.y   = [y1d; y2d];
    ref.dy  = [dy1d; dy2d];
    ref.ddy = [ddy1d; ddy2d];
end
