% FUNCTION PER IL CALCOLO DELL'OFFSET TRA APC e CoM NELLE DIREZIONI ALONG
% TRACK E ACROSS TRACK PER LE COSTELLAZIONI GPS E GALILEO

function [apof_in_track,apof_cross_track] = calc_APC2CoM_t_w (costellazione,YR,DoM,MN,ToW,eph,mu,apo,SAT)

    au = 149597870.699; % Unità astronomica [km]
    
    % Calcolo della posizione del stallite nella terna x-y-z inerziale
    [x, y, z] = becp_i(ToW, eph, mu);
    
    xi = x/1000;
    yi = y/1000;
    zi = z/1000;
    
    % Calcolo della velocità dei satelliti nella terna x-y-z inerziale
    [x0, y0, z0] = becp_i(ToW-0.5, eph, mu); 
    [x1, y1, z1] = becp_i(ToW+0.5, eph, mu);
              
    xdot_i = (x1-x0)/1000;
    ydot_i = (y1-y0)/1000;
    zdot_i = (z1-z0)/1000;
    
    % calcolo della terna TRW inerziale
    et_x = xdot_i/(xdot_i^2+ydot_i^2+zdot_i^2)^0.5;
    et_y = ydot_i/(xdot_i^2+ydot_i^2+zdot_i^2)^0.5;
    et_z = zdot_i/(xdot_i^2+ydot_i^2+zdot_i^2)^0.5;
    
    er_x = xi/(xi^2+yi^2+zi^2)^0.5;
    er_y = yi/(xi^2+yi^2+zi^2)^0.5;
    er_z = zi/(xi^2+yi^2+zi^2)^0.5;
    
    ew_x = er_y*et_z-er_z*et_y;
    ew_y = er_z*et_x-er_x*et_z;
    ew_z = er_x*et_y-er_y*et_x;
    
    % Calcolo del versore inerziale che punta al sole
    [dl, dr, rasc, decl, rsun] = beta_sun(YR+2000,DoM,MN);
    
    esun_x = cos(rasc)*cos(decl);
    esun_y = sin(rasc)*cos(decl);
    esun_z = sin(decl);
    
    % Beta = asin(ew_x*esun_x+ew_y*esun_y+ew_z*esun_z)*180/3.14;
    
    ZYS_x = -er_x;
    ZYS_y = -er_y;
    ZYS_z = -er_z;
    
    esat2sun_x = au*esun_x-xi;
    esat2sun_y = au*esun_y-yi;
    esat2sun_z = au*esun_z-zi;
    
    % esat2sun_x_v = esat2sun_x/(esat2sun_x^2+esat2sun_y^2+esat2sun_z^2)^0.5;
    % esat2sun_y_v = esat2sun_y/(esat2sun_x^2+esat2sun_y^2+esat2sun_z^2)^0.5;
    % esat2sun_z_v = esat2sun_z/(esat2sun_x^2+esat2sun_y^2+esat2sun_z^2)^0.5;
    
    % beta = asin(ew_x*esat2sun_x_v+ew_y*esat2sun_y_v+ew_z*esat2sun_z_v)*180/3.1415;
    
    esat2sun_x_r = esat2sun_y*zi - esat2sun_z*yi;
    esat2sun_y_r = -esat2sun_x*zi + esat2sun_z*xi;
    esat2sun_z_r = esat2sun_x*yi - esat2sun_y*xi;
    
    abs = (esat2sun_x_r^2+esat2sun_y_r^2+esat2sun_z_r^2)^0.5;
    
    YYS_x = esat2sun_x_r/abs;
    YYS_y = esat2sun_y_r/abs;
    YYS_z = esat2sun_z_r/abs;
    
    % XYS_x = YYS_y*ZYS_z - YYS_z*ZYS_y;
    % XYS_y = -YYS_x*ZYS_z + YYS_z*ZYS_x;
    % XYS_z = YYS_x*ZYS_y - YYS_y*ZYS_x;
    
    yys_dot_w = - YYS_x*ew_x - YYS_y*ew_y - ZYS_z*ew_z;
    
    z_cross_w_x = ZYS_y*ew_z - ZYS_z*ew_y;
    z_cross_w_y = -ZYS_x*ew_z + ZYS_z*ew_x;
    z_cross_w_z = ZYS_x*ew_y - ZYS_y*ew_x;
    
    y_dot_z_cross_w = YYS_x*z_cross_w_x + YYS_y*z_cross_w_y + YYS_z*z_cross_w_z;
    
    psi = (atan2(y_dot_z_cross_w,yys_dot_w))*180/3.1415;
    
    if costellazione == 2
           
        comp_along = apo(3).north(SAT,1);
            
    end
    
    if costellazione == 0
            
        comp_along = apo(1).north(SAT,1);
            
    end
    
    apof_in_track =  comp_along*cos(psi*3.1415/180);
    apof_cross_track =  comp_along*sin(psi*3.1415/180);

end