function ref = reference_command(t, p)
%REFERENCE_COMMAND Desired output and derivatives.
% Optional channel-1 shaping is applied in a paper-inspired way using a
% standard ZVD shaper built from the first flexible mode.

ref = base_reference_command(t, p);

if ~isfield(p, 'shaper') || ~isfield(p.shaper, 'enable') || ~p.shaper.enable
    return;
end

shapeChannel1 = true;
if isfield(p.shaper, 'channel1Only')
    shapeChannel1 = p.shaper.channel1Only;
end
if ~shapeChannel1
    return;
end

if isfield(p.shaper, 'type') && strcmpi(p.shaper.type, 'zvd')
    sh = get_zvd_shaper(p.shaper.wn, p.shaper.zeta);
else
    error('Unsupported shaper type.');
end

refShaped = ref;
refShaped.y(1) = 0;
refShaped.dy(1) = 0;
refShaped.ddy(1) = 0;

for k = 1:numel(sh.A)
    tk = t - sh.tDelay(k);
    if tk < 0
        continue;
    end
    rk = base_reference_command(tk, p);
    refShaped.y(1) = refShaped.y(1) + sh.A(k) * rk.y(1);
    refShaped.dy(1) = refShaped.dy(1) + sh.A(k) * rk.dy(1);
    refShaped.ddy(1) = refShaped.ddy(1) + sh.A(k) * rk.ddy(1);
end

ref = refShaped;
ref.shaper = sh;
end
