%% calcSSR_ECEF_mod
% Computes SSR triad in the ECEF frame considering Galileo ephemeris
%
%%
function [ssr] = calcSSR_ECEF_mod(t, eph, mu, omega_e)
%% input:  
%
% * t: epoch [s]
% * eph: broadcast ephemeris block
% * mu: gravitational constant [m3/sec2]
% * omega_e: Earth rotation [rad/sec]
%
%% output:
%
% * ssr: array containing the triad unit vectors ssr (same as in HAS) 
%
   [x0, y0, z0] = becp(t-0.5, eph, mu, omega_e);
   [x1, y1, z1] = becp(t+0.5, eph, mu, omega_e);
   
   [x, y, z] = becp(t, eph, mu, omega_e);
   
   xdot = x1 - x0;
   ydot = y1 - y0;
   zdot = z1 - z0;

% Print on screen (for the Excel validation):
%fprintf('BRDM, ECEF XYZ (m)/VXYZ (m/s):  %14.3f %14.3f %14.3f %14.3f %14.3f %14.3f\n', x, y, z, xdot, ydot, zdot)

%% Along track vector ($t$): compute the module of the velocity ($|v| = \sqrt[]{v_x^2+v_y^2+v_z^2}$) and its x, y, z unitary components ($\dot{i}=v_i$):
% $$x_{t} = \frac{\dot{x}}{|v|}$$; 
% $$y_{t} = \frac{\dot{y}}{|v|}$$; 
% $$z_{t} = \frac{\dot{z}}{|v|}$$

v_mod = (xdot^2 + ydot^2 + zdot^2)^0.5;
x_t = xdot/v_mod;
y_t = ydot/v_mod;
z_t = zdot/v_mod;

%% Positional vector ($r$): compute the module of the positions ($|r| = \sqrt[]{x^2+y^2+z^2}$) and its x, y, z unitary components:
% $$x_{r} = \frac{x}{|r|}$$; 
% $$y_{r} = \frac{y}{|r|}$$; 
% $$z_{r} = \frac{z}{|r|}$$

r_mod = (x^2 + y^2 + z^2)^0.5;
x_r = x/r_mod;
y_r = y/r_mod;
z_r = z/r_mod;

%% Off-track vector ($w$): cross product between the position and the velocity vectors.
% $$w = \frac{t \times r}{|t \times r|}$$
w = cross([x_r, y_r, z_r], [x_t, y_t, z_t]);
x_w = w(1);
y_w = w(2);
z_w = w(3);
w_mod = (x_w^2 + y_w^2 + z_w^2)^0.5;
x_w = w(1)/w_mod;
y_w = w(2)/w_mod;
z_w = w(3)/w_mod;


%% RADIAL unit vector ($r$): cross product between the velocity and the off-track vectors.
% $$r = \frac{t \times r}{|t \times r|}$$
r = cross([x_t, y_t, z_t] , [x_w, y_w, z_w]);
x_r = r(1);
y_r = r(2);
z_r = r(3);


%ssr = [x_t, y_t, z_t; x_r, y_r, z_r; x_w, y_w, z_w];
% As in HAS: RTW
ssr = [x_r, y_r, z_r ,x_t, y_t, z_t, x_w, y_w, z_w];

% Print on screen (for Excel validations):
%fprintf('BRDM, ECEF XYZ (m)/VXYZ (m/s); Unit r, t, w:  %14.3f %14.3f %14.3f %10.3f %10.3f %10.3f ;', x, y, z, xdot, ydot, zdot)
%fprintf(' %8.4f %8.4f %8.4f; %8.4f %8.4f %8.4f; %8.4f %8.4f %8.4f', ssr(1, 1:3), ssr(2, 1:3), ssr(3, 1:3));
%fprintf('\n');

end


