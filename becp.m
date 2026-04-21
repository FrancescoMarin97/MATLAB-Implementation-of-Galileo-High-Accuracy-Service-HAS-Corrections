%% becp
% retrieves satellite position from broadcast ephemerides:
%
%%
function [x, y, z] = becp(t, eph, mu, omega_e)
%% input:  
%
% * t: epoch [s]
% * eph: broadcast ephemeris block
% * mu: gravitational constant [m3/sec2]
% * omega_e: Earth rotation [rad/sec]
%
%% output:
%
% * x, y, z: satellite coordinates [m]
%
% Last changes:
% 20210310: JZ, add more iterations in the Kepler Equation (for E14 and E18)

%% constants
Pi = 3.1415926535898;

%% solving for coordinates
tk = t - eph(12);
a = (eph(11)) ^ 2;
n0 = (mu / a ^ 3) ^ 0.5;
n = n0 + eph(6);
Mk = eph(7) + n * tk;
Ek = Mk + eph(9) * sin(Mk);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);

%fprintf('\nNew Ek itrations:\n');
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);

Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);
Ek = Mk + eph(9) * sin(Ek);



Cek = cos(Ek);
Sek = sin(Ek);
Cvk = (Cek - eph(9)) / (1 - eph(9) * Cek);
Svk = sqrt(1 - eph(9) ^ 2) * Sek / (1 - eph(9) * Cek);
if (Svk > 0) && (Cvk > 0)
  vk = atan(Svk / Cvk);
elseif (Svk > 0) && (Cvk < 0)
  vk = Pi + atan(Svk / Cvk);
elseif (Svk < 0 ) && (Cvk > 0)
  vk = atan(Svk / Cvk);
elseif (Svk < 0) && (Cvk < 0)
  vk = Pi + atan(Svk / Cvk);
end
% if ~exist('vk', 'var')
%     fprintf('Mk = %f; eph7 = %f; n = %d; tk = %f\n', Mk, eph(7), n, tk);
%     fprintf('n0 = %f; eph6 = %f; eph11 = %f\n', n0, eph(6), eph(11));
% end

uk = vk + eph(18);
s2uk = sin(2 * uk);
c2uk = cos(2 * uk);
duk = eph(8) * c2uk + eph(10) * s2uk;
drk = eph(17) * c2uk + eph(5) * s2uk;
dik = eph(13) * c2uk + eph(15) * s2uk;
omk = eph(18) + duk;
rk = a * (1 - eph(9) * cos(Ek)) + drk;
ik = eph(16) + dik + eph(20) * tk;
xpk = rk * cos(omk + vk);
ypk = rk * sin(omk + vk);

if (eph(16) < deg2rad(12))
    
    lk = eph(14) + eph(19) * tk - omega_e * eph(12);
    clk = cos(lk);
    slk = sin(lk);
    cik = cos(ik);
    sik = sin(ik);

    xpk2 = xpk * clk - ypk * cik * slk;
    ypk2 = xpk * slk + ypk * cik * clk;
    zpk2 = ypk * sik;
    
    %% GEO specific processing
    % orbital plane is tilted by 5°
    lk2 = - omega_e * tk;
    clk2 = cos(lk2);
    slk2 = sin(lk2);
    cik2 = cos(5*Pi/180);
    sik2 = sin(5*Pi/180);
    
    x = xpk2 * clk2 - ypk2 * cik2 * slk2 + zpk2 * sik2 * slk2;
    y = xpk2 * slk2 + ypk2 * cik2 * clk2 - zpk2 * sik2 * clk2;
    z =               ypk2 * sik2        + zpk2 * cik2;
    
else

    lk = eph(14) + eph(19) * tk - omega_e * t;
    clk = cos(lk);
    slk = sin(lk);
    cik = cos(ik);
    sik = sin(ik);
    
    x = xpk * clk - ypk * cik * slk;
    y = xpk * slk + ypk * cik * clk;
    z = ypk * sik;

end