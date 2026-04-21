% FUNCTION TO GENERATE OBS RINEX FILES CORRECTED WITH HAS CODE BIAS CORRECTION

clc
close all
clear 
clear vars

%% Input  

yr4 = 2024;
yr2 = yr4-2000;
% STA_abb_v = ["BRUX00BEL","TLSG00FRA"]; % abbreviation for old RINEX file
% STA_abb_n_v = ["BRUH00BEL","TLSH00FRA"]; % abbreviation for new RINEX file
STA_abb_v = ["ASIA00ITA","BRUX00BEL","TLSG00FRA"]; % abbreviation for old RINEX file
STA_abb_n_v = ["ASIH00ITA","BRUH00BEL","TLSH00FRA"]; % abbreviation for new RINEX file
HAS_abb = "ASIA";
doy_i = 26; % doy iniziale
doy_f = 34; % doy finale

for STATION = 1:length(STA_abb_v)

    STA_abb = STA_abb_v(STATION);
    STA_abb_n = STA_abb_n_v(STATION);
    
    % Creation of a directory specific for the doy
    
    if ~exist(strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4)), 'dir')
    
          mkdir(strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4)));
    
    end
    
    if ~exist(strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX'), 'dir')
    
          mkdir (strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX'));
    
    end
    
    for doy = doy_i:doy_f % Iteration on multiple days
    
        chdir 'C:\\multiGNSS_v3\\HAS\\RINEX\';
    
        [DoM,Month] = DoY_to_DoM(doy);
        [WN,DoW] = GPS_date (DoM,Month,yr4);
    
        fig = uifigure;
        d = uiprogressdlg(fig,'Title','Adding HAS code bias corrections to RINEX 3.04 Obs file','Message','Opening the application');
        pause(1)
        
        [gpsweek,ToW_0,rollover] = jd2gps(cal2jd(yr4,1,0) + doy);
    
        % Definition of RINEX OBS files path
    
        if doy < 100 && doy > 9
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_R_',num2str(yr4),'0',num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
        
        end
    
        if doy > 99
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_R_',num2str(yr4),num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
        
        end
    
        if doy < 10
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_R_',num2str(yr4),'00',num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
        
        end
        
        if STA_abb == "ALTC00NOR" && doy > 99
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_S_',num2str(yr4),num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
    
        end
    
        if STA_abb == "ALTC00NOR" && doy < 100 && doy > 9
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_S_',num2str(yr4),'0',num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
    
        end
    
        if STA_abb == "ALTC00NOR" && doy < 10
    
            filename_RNX = strcat('C:\multiGNSS_v3\input\obs\',STA_abb,'_S_',num2str(yr4),'00',num2str(doy),'0000_01D_30S_MO.rnx'); % RNX path
    
        end
    
        % Upload of HAS corrections
    
        if yr4 == 2023
        
            if doy < 100
        
                filename_HAS = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(doy),'0.',num2str(yr2),'__has_cb.csv'); % HAS corrections path
        
            else
        
                filename_HAS = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(doy),'0.',num2str(yr2),'__has_cb.csv'); % HAS corrections path
            
            end
        
        end

        if yr4 == 2024
        
            if doy < 100
        
                filename_HAS = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(doy),'0.',num2str(yr2),'__has_cb.csv'); % HAS corrections path
        
            else
        
                filename_HAS = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(doy),'0.',num2str(yr2),'__has_cb.csv'); % HAS corrections path
            
            end
        
        end
        
        %% Import code bias HAS data from .csv file
        
        % Setup the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 11);
        
        % Specify range and delimiter
        opts.DataLines = [2, inf];
        opts.Delimiter = ",";
        
        % Specify column names and types
        opts.VariableNames = ["ToW", "WN", "ToH", "IOD", "gnssIOD", "validity", "gnssID", "PRN", "signal", "code_bias", "av_flag"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        
        % Import the data
        d.Value = .10; 
        d.Message = strcat('Loading HAS code bias data ',filename_HAS);
        pause(1)
        ASIA_table = readtable(filename_HAS, opts);
        d.Value = .20; 
        d.Message = strcat('Loaded HAS code bias data ',filename_HAS);
        pause(1)
        
        % Clear temporary variables
        clear opts
        
        %% SELECTION OF CODE CORRECTION
        
        % Available signals in RINEX file:
        %     - GPS: C1C, L1C, D1C, S1C, C2W, L2W, D2W, S2W, C2S, L2S, D2S, S2S, C5Q, L5Q, D5Q, S5Q
        %     - GLO: C1C, L1C, D1C, S1C, C2P, L2P, D2P, S2P, C2C, L2C, D2C, S2C, C3Q, L3Q, D3Q, S3Q
        %     - GAL: C1C, L1C, D1C, S1C, C5Q, L5Q, D5Q, S5Q, C7Q, L7Q, D7Q, S7Q, C8Q, L8Q, D8Q, S8Q, C6C, L6C, D6C, S6C
        %     - BDS: C2I, L2I, D2I, S2I, C7I, L7I, D7I, S7I, C7D, L7D, D7D, S7D, C5D, L5D, D5D, S5D, C6I, L6I, D6I, S6I, C1D, L1D, D1D, S1D
        %     - NAV: C5A, L5A, D5A, S5A
        
        % Table 20. Signal Index Table Galileo and GPS --> HAS SIS ICD, Issue 1.0, May 2022                                            
        % Signal Index  Galileo             GPS        
        % 0             E1-B I/NAV  OS      L1 C/A    
        % 1             E1-C                Reserved   
        % 2             E1-B + E1-C         Reser
        % 3             E5a-I F/NAV OS      L1C
        % 4             E5a-Q               L1C(P)     
        % 5             E5a-I+E5a-Q         L1C(D
        % 6             E5b-I I/NAV OS      L2
        % 7             E5b-Q               L2 CL      
        % 8             E5b-I+E5b-Q         L2 CM+C
        % 9             E5-I                L2 P             
        % 10            E5-Q                Reserved
        % 11            E5-I + E5-Q         L5 I
        % 12            E6-B C/NAV HAS      L5 Q
        % 13            E6-C                L5 I + L5 Q                             
        % 14            E6-B + E6-C         Reserved                        
        % 15            Reserved            Reserved
        
        gnssID = [0,2]; % 0=GPS, 2=Galileo
        n_gnssID = length(gnssID);
        PRNE = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,21,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36]; n_PRNE = length(PRNE);
        PRNG = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32];             n_PRNG = length(PRNG);
        signalG = [0,7,9]; % GPS signal index
        n_signalG = length(signalG);
        signalE = [1,4,7,13]; % Galileo signal index
        n_signalE = length(signalE);
        
        %% GPS
        
        d.Value = .40; 
        d.Message = 'Finding epochs and amount of code bias changes in HAS file: GPS L1 C/A, L2 CL, L2 P';
        pause(1)
        
        for i_PRNG = 1 : n_PRNG
        
            % HAS code bias signal index 0, L1 C/A
        
            i_signalG = 1;
        
            % the vector idata points to the selected sv and signal
            clear idata;
        
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalG(i_signalG) & ASIA_table.PRN == PRNG(i_PRNG) & ASIA_table.gnssID == gnssID(1) & ASIA_table.code_bias ~= 0); % start with GPS: gnssID(1))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakG0 and in code_biasG0 the sv of every column
        
            SAT_ID_G0 (i_PRNG) = PRNG(i_PRNG);
        
            if ~isempty(idata)
          
                ToWbreakG0(1:length(idata),i_PRNG) = ASIA_table.ToW(idata);
                code_biasG0(1:length(idata),i_PRNG) = ASIA_table.code_bias(idata);
        
            end
        
            % HAS code bias signal index 7, L2 CL
        
            i_signalG=2;
              
            % the vector idata points to the selected sv and signal
            clear idata;
             
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalG(i_signalG) & ASIA_table.PRN == PRNG(i_PRNG) & ASIA_table.gnssID == gnssID(1) & ASIA_table.code_bias ~= 0); % start with GPS: gnssID(1))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakG7 and in code_biasG7 the sv of every column
        
            SAT_ID_G7 (i_PRNG) = PRNG(i_PRNG);
        
            if ~isempty(idata)
        
                ToWbreakG7(1:length(idata),i_PRNG) = ASIA_table.ToW(idata);
                code_biasG7(1:length(idata),i_PRNG) = ASIA_table.code_bias(idata);
            
            end
        
            % HAS code bias signal index 9, L2 P
        
            i_signalG=3;
              
            % the vector idata points to the selected sv and signal
            clear idata;
             
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalG(i_signalG) & ASIA_table.PRN == PRNG(i_PRNG) & ASIA_table.gnssID == gnssID(1) & ASIA_table.code_bias ~= 0); % start with GPS: gnssID(1))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakG7 and in code_biasG7 the sv of every column
        
            SAT_ID_G9 (i_PRNG) = PRNG(i_PRNG);
        
            if ~isempty(idata)
        
                ToWbreakG9(1:length(idata),i_PRNG) = ASIA_table.ToW(idata);
                code_biasG9(1:length(idata),i_PRNG) = ASIA_table.code_bias(idata);
            
            end
            
        end
        
        %% Galileo
        
        d.Value = .50; 
        d.Message = 'Finding epochs and amount of code changes in HAS file: GAL E1-C, E5a-Q, E5b-Q, E6-C';
        pause(1)
        
        for i_PRNE = 1:n_PRNE
        
            % HAS code bias signal index 1, E1-C
        
            i_signalE = 1;
        
            % the vector idata points to the selected sv and signal
            clear idata;
        
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalE(i_signalE) & ASIA_table.PRN == PRNE(i_PRNE) & ASIA_table.gnssID == gnssID(2) & ASIA_table.code_bias ~= 0); % start with Galileo: gnssID(2))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakE1 and in code_biasE1 the sv of every column
        
            SAT_ID_E1 (i_PRNE) = PRNE(i_PRNE);
        
            if ~isempty(idata)
        
                ToWbreakE1(1:length(idata),i_PRNE) = ASIA_table.ToW(idata);
                code_biasE1(1:length(idata),i_PRNE) = ASIA_table.code_bias(idata);
        
            end
        
            % HAS code bias signal index 4, E5a-Q
        
            i_signalE=2;
              
            % the vector idata points to the selected sv and signal
            clear idata;
             
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalE(i_signalE) & ASIA_table.PRN == PRNE(i_PRNE) & ASIA_table.gnssID == gnssID(2) & ASIA_table.code_bias ~= 0); % start with Galileo: gnssID(2))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakE4 and in code_biasE4 the sv of every column
        
            SAT_ID_E4 (i_PRNE) = PRNE(i_PRNE);
        
            if ~isempty(idata)
        
                ToWbreakE4(1:length(idata),i_PRNE) = ASIA_table.ToW(idata);
                code_biasE4(1:length(idata),i_PRNE) = ASIA_table.code_bias(idata);
            
            end
        
            % HAS code bias signal index 7, E5b-Q
        
            i_signalE=3;
              
            % the vector idata points to the selected sv and signal
            clear idata;
             
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalE(i_signalE) & ASIA_table.PRN == PRNE(i_PRNE) & ASIA_table.gnssID == gnssID(2) & ASIA_table.code_bias ~= 0); % start with Galileo: gnssID(2))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakE7 and in code_biasE7 the sv of every column
        
            SAT_ID_E7 (i_PRNE) = PRNE(i_PRNE);
        
            if ~isempty(idata)
        
                ToWbreakE7(1:length(idata),i_PRNE) = ASIA_table.ToW(idata);
                code_biasE7(1:length(idata),i_PRNE) = ASIA_table.code_bias(idata);
            
            end
        
            % HAS code bias signal index 13, E6-C
        
            i_signalE=4;
              
            % the vector idata points to the selected sv and signal
            clear idata;
             
            idata = find(ASIA_table.av_flag == 1 & ASIA_table.signal == signalE(i_signalE) & ASIA_table.PRN == PRNE(i_PRNE) & ASIA_table.gnssID == gnssID(2) & ASIA_table.code_bias ~= 0); % start with Galileo: gnssID(2))   
            ndata = length(idata);
        
            % Save in a vector the ID of the satellite , so we can understand in
            % ToWbreakE13 and in code_biasE13 the sv of every column
        
            SAT_ID_E13 (i_PRNE) = PRNE(i_PRNE);
        
            if ~isempty(idata)
        
                ToWbreakE13(1:length(idata),i_PRNE) = ASIA_table.ToW(idata);
                code_biasE13(1:length(idata),i_PRNE) = ASIA_table.code_bias(idata);
            
            end
        
        end
        
        %% Loading RINEX Obs file
        
        d.Value = .55; 
        d.Message = strcat('Loading RINEX Obs file ',filename_RNX);
        pause(1)
        rinexdata=rinexread(filename_RNX);
        rinexdataHAS=rinexdata; % Structure with RINEX OBS + HAS
        d.Value = .60; 
        d.Message = strcat('Loaded RINEX Obs file ',filename_RNX);
        pause(1)
        
        %% APPLY HAS CODE BIAS TO GPS OBS RINEX
        
        d.Value = .70; 
        d.Message = 'HAS code bias corrections on GPS data';
        pause(1)
        
        % ADD HAS TO RINEX OBS DATA/GPS
        
        % scan epoch by epoch the GPS rinex data
        i_tstart = 1; % this variable points to the time block
        
        while i_tstart <= length(rinexdata.GPS.Time) % scan the time blocks within the Rinex datafile: for a daily file of 30 sec data
        
            % this loop is for sv's at the same epoch
            i_time=1; % i_time points to the sv within the time block i_tstart
        
            contaG0 = 1;
            contaG7 = 1;
            contaG9 = 1;
        
            while i_time <= find(rinexdata.GPS.Time>rinexdata.GPS.Time(i_tstart),1) % this 'find' is the number of sv - 1 in the time block
                
                if rinexdata.GPS.Time(i_tstart+i_time-1) == rinexdata.GPS.Time(i_tstart)
        
                    % time since the start of the day
                    t_rnx = sscanf(string(duration(rinexdata.GPS.Time(i_tstart+i_time-1)-rinexdata.GPS.Time(1))),'%d %*c %d %*c %d');
                    ToWrnx = ToW_0+(t_rnx(1)*3600+t_rnx(2)*60+t_rnx(3));
        
                    % Apply L1 C/A correction to C1C RINEX OBS
        
                    % Find the position where ToWbreakG0 start with 0, but we have
                    % to select the right column in ToWbreakG0 with SAT_ID_G0
        
                    for i = 1:length(SAT_ID_G0)
        
                        if SAT_ID_G0(i) == rinexdata.GPS.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % column in ToWbreakG0 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_G0 = height(ToWbreakG0);
        
                    for i = 1:height(ToWbreakG0)
                
                        if i > 0 && ToWbreakG0(i,pos_f) == 0
                
                            break_G0 = i; % position in the right column where TowbreakG0 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakG0(1:(break_G0-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakG0(1:(break_G0-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakG0(1:(break_G0-1),pos_f)-ToWrnx+tmin==0);
                    
                    end 
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code bias correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
        
                       if ~isnan(rinexdata.GPS.C1C(i_tstart+i_time-1))
        
                           rinexdataHAS.GPS.C1C(i_tstart+i_time-1) = rinexdata.GPS.C1C(i_tstart+i_time-1)+code_biasG0(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                           code_biasG0_app(contaG0,pos_f) = code_biasG0(indx_tmin,pos_f); % effective applied correction 
                           ToWbreakG0_app(contaG0,pos_f) = ToWbreakG0(indx_tmin,pos_f);
                           contaG0 = contaG0+1;
        
                        end
        
                    end
        
                    % Apply L2 CL correction to C2S RINEX OBS (PADO, ALTC), C2L RINEX
                    % OBS (BRUX, TLSG)
        
                    % Find the position where ToWbreakG7 start with 0, but we have
                    % to select the right column in ToWbreakG7 with SAT_ID_G7
        
                    for i = 1:length(SAT_ID_G7)
        
                        if SAT_ID_G7(i) == rinexdata.GPS.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % column in ToWbreakG0 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_G7 = height(ToWbreakG7);
        
                    for i = 1:height(ToWbreakG7)
                
                        if i > 0 && ToWbreakG7(i,pos_f) == 0
                
                            break_G7 = i; % position in the right column where TowbreakG7 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakG7(1:(break_G7-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakG7(1:(break_G7-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakG7(1:(break_G7-1),pos_f)-ToWrnx+tmin==0);
                    
                    end 
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code bias correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
    
                        if STA_abb == "PADO00ITA" || STA_abb == "ALTC00NOR" || STA_abb == "EKAR00ITA"
        
                           if ~isnan(rinexdata.GPS.C2S(i_tstart+i_time-1))
            
                               rinexdataHAS.GPS.C2S(i_tstart+i_time-1) = rinexdata.GPS.C2S(i_tstart+i_time-1)+code_biasG7(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                               code_biasG7_app(contaG7,pos_f) = code_biasG7(indx_tmin,pos_f); % effective applied correction 
                               ToWbreakG7_app(contaG7,pos_f) = ToWbreakG7(indx_tmin,pos_f);
                               contaG7 = contaG7+1;
            
                           end
    
                        end
    
                        if STA_abb == "BRUX00BEL" || STA_abb == "TLSG00FRA" || STA_abb == "ASIA00ITA"
        
                           if ~isnan(rinexdata.GPS.C2L(i_tstart+i_time-1))
            
                               rinexdataHAS.GPS.C2L(i_tstart+i_time-1) = rinexdata.GPS.C2L(i_tstart+i_time-1)+code_biasG7(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                               code_biasG7_app(contaG7,pos_f) = code_biasG7(indx_tmin,pos_f); % effective applied correction 
                               ToWbreakG7_app(contaG7,pos_f) = ToWbreakG7(indx_tmin,pos_f);
                               contaG7 = contaG7+1;
            
                           end
    
                        end
        
                    end
        
                    % Apply L2 P correction to C2W RINEX OBS (PADO, BRUX, TLSG, ALTC, ASIA) 
        
                    % Find the position where ToWbreakG9 start with 0, but we have
                    % to select the right column in ToWbreakG9 with SAT_ID_G9
        
                    for i = 1:length(SAT_ID_G9)
        
                        if SAT_ID_G9(i) == rinexdata.GPS.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % column in ToWbreakG0 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_G9 = height(ToWbreakG9);
        
                    for i = 1:height(ToWbreakG9)
                
                        if i > 0 && ToWbreakG9(i,pos_f) == 0
                
                            break_G9 = i; % position in the right column where TowbreakG9 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakG9(1:(break_G9-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakG9(1:(break_G9-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakG9(1:(break_G9-1),pos_f)-ToWrnx+tmin==0);
                    
                    end 
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code bias correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
        
                       if ~isnan(rinexdata.GPS.C2W(i_tstart+i_time-1))
        
                           rinexdataHAS.GPS.C2W(i_tstart+i_time-1) = rinexdata.GPS.C2W(i_tstart+i_time-1)+code_biasG9(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                           code_biasG7_app(contaG9,pos_f) = code_biasG9(indx_tmin,pos_f); % effective applied correction 
                           ToWbreakG7_app(contaG9,pos_f) = ToWbreakG9(indx_tmin,pos_f);
                           contaG9 = contaG9+1;
        
                        end
        
                    end
        
                    i_time=i_time+1;
        
                else
        
                    i_tstart=i_tstart+i_time-1;
                    i_time=1;
        
                end
        
            end
        
        break
        
        end
        
        %% APPLY HAS CODE BIAS TO Galileo OBS RINEX
        
        d.Value = .70; 
        d.Message = 'HAS code corrections on Galileo data';
        pause(1)
        
        % ADD HAS TO RINEX DATA/Galileo
        
        % scan epoch by epoch the Galileo rinex data
        i_tstart = 1;
        
        while i_tstart <= length(rinexdata.Galileo.Time)
        
            % this loop is for sv's at the same epoch
            i_time = 1;
        
            contaE1 = 1;
            contaE4 = 1;
            contaE7 = 1;
            contaE13 = 1;
        
            while i_time <= find(rinexdata.Galileo.Time>rinexdata.Galileo.Time(i_tstart),1)
                
                if rinexdata.Galileo.Time(i_tstart+i_time-1)==rinexdata.Galileo.Time(i_tstart)
                        
                    % time since the start of the day
                    t_rnx = sscanf(string(duration(rinexdata.Galileo.Time(i_tstart+i_time-1)-rinexdata.Galileo.Time(1))),'%d %*c %d %*c %d');
                    ToWrnx = ToW_0+(t_rnx(1)*3600+t_rnx(2)*60+t_rnx(3));
        
                    % Apply E1-C correction to C1C RINEX OBS
        
                    % Find the position where ToWbreakE1 start with 0, but we have
                    % to select the right column in ToWbreakE1 with SAT_ID_E1
        
                    for i = 1:length(SAT_ID_E1)
        
                        if SAT_ID_E1(i) == rinexdata.Galileo.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % colum in ToWbreakE1 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_E1 = height(ToWbreakE1);
        
                    for i = 1:height(ToWbreakE1)
                
                        if i > 0 && ToWbreakE1(i,pos_f) == 0
                
                            break_E1 = i; % position in the right column where TowbreakE1 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakE1(1:(break_E1-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    
                    indx_tmin = find(ToWbreakE1(1:(break_E1-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakE1(1:(break_E1-1),pos_f)-ToWrnx+tmin==0);
                    
                    end
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
        
                        if ~isnan(rinexdata.Galileo.C1C(i_tstart+i_time-1))
        
                           rinexdataHAS.Galileo.C1C(i_tstart+i_time-1) = rinexdata.Galileo.C1C(i_tstart+i_time-1)+code_biasE1(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                           code_biasE1_app(contaE1,pos_f) = code_biasE1(indx_tmin,pos_f); % effective applied correction 
                           ToWbreakE1_app(contaE1,pos_f) = ToWbreakE1(indx_tmin,pos_f);
                           contaE1 = contaE1+1;
        
                        end
                   
                    end
        
                    % Apply E5a-Q correction to C5Q RINEX OBS
        
                    % Find the position where ToWbreakE4 start with 0, but we have
                    % to select the right column in ToWbreakE4 with SAT_ID_E4
        
                    for i = 1:length(SAT_ID_E4)
        
                        if SAT_ID_E4(i) == rinexdata.Galileo.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % colum in ToWbreakE1 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_E4 = height(ToWbreakE4);
        
                    for i = 1:height(ToWbreakE4)
                
                        if i > 0 && ToWbreakE4(i,pos_f) == 0
                
                            break_E4 = i; % position in the right column where TowbreakE4 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakE4(1:(break_E4-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakE4(1:(break_E4-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakE4(1:(break_E4-1),pos_f)-ToWrnx+tmin==0);
                    
                    end
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
        
                        if ~isnan(rinexdata.Galileo.C5Q(i_tstart+i_time-1))
        
                           rinexdataHAS.Galileo.C5Q(i_tstart+i_time-1) = rinexdata.Galileo.C5Q(i_tstart+i_time-1)+code_biasE4(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                           code_biasE4_app(contaE4,pos_f) = code_biasE4(indx_tmin,pos_f); % effective applied correction 
                           ToWbreakE4_app(contaE1,pos_f) = ToWbreakE4(indx_tmin,pos_f);
                           contaE4 = contaE4+1;
        
                        end
                   
                    end
        
                   % Apply E5b-Q correction to C7Q RINEX OBS
        
                    % Find the position where ToWbreakE7 start with 0, but we have
                    % to select the right column in ToWbreakE7 with SAT_ID_E7
        
                    for i = 1:length(SAT_ID_E7)
        
                        if SAT_ID_E7(i) == rinexdata.Galileo.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % colum in ToWbreakE1 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_E7 = height(ToWbreakE7);
        
                    for i = 1:height(ToWbreakE7)
                
                        if i > 0 && ToWbreakE7(i,pos_f) == 0
                
                            break_E7 = i; % position in the right column where TowbreakE7 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakE7(1:(break_E7-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakE7(1:(break_E7-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakE7(1:(break_E7-1),pos_f)-ToWrnx+tmin==0);
                    
                    end
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)
        
                        if ~isnan(rinexdata.Galileo.C7Q(i_tstart+i_time-1))
        
                           rinexdataHAS.Galileo.C7Q(i_tstart+i_time-1) = rinexdata.Galileo.C7Q(i_tstart+i_time-1)+code_biasE7(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                           code_biasE7_app(contaE7,pos_f) = code_biasE7(indx_tmin,pos_f); % effective applied correction 
                           ToWbreakE7_app(contaE1,pos_f) = ToWbreakE7(indx_tmin,pos_f);
                           contaE7 = contaE7+1;
        
                        end
                   
                    end
        
                    % Apply E6-C correction to C6C RINEX OBS
        
                    % Find the position where ToWbreakE13 start with 0, but we have
                    % to select the right column in ToWbreakE13 with SAT_ID_E13
        
                    for i = 1:length(SAT_ID_E13)
        
                        if SAT_ID_E13(i) == rinexdata.Galileo.SatelliteID(i_tstart+i_time-1)
        
                            pos_f = i; % colum in ToWbreakE1 where we have rinexdata.GPS.SatelliteID(i_tstart+i_time-1) satellite
                            break
        
                        end
        
                    end
        
                    break_E13 = height(ToWbreakE13);
        
                    for i = 1:height(ToWbreakE13)
                
                        if i > 0 && ToWbreakE13(i,pos_f) == 0
                
                            break_E13 = i; % position in the right column where TowbreakE13 start with 0
                            break
                
                        end
                
                    end
        
                    % distance of rinex epoch from the epoch of the nearest code jump in HAS
                    % file
                    tmin = min(abs(ToWbreakE13(1:(break_E13-1),pos_f)-ToWrnx));
                    
                    % the distance has no sign, so I have to find the position of
                    % the code
                    % break (after or before the rinex epoch): note the sign of tmin below
                    indx_tmin = find(ToWbreakE13(1:(break_E13-1),pos_f)-ToWrnx-tmin==0);
                    
                    if isempty(indx_tmin)
        
                        indx_tmin = find(ToWbreakE13(1:(break_E13-1),pos_f)-ToWrnx+tmin==0);
                    
                    end
    
                    if length(indx_tmin) > 1 % potrebbe succedere che le correzioni HAS abbiano dei dati ripetuti
    
                        temp_indx_tmin = indx_tmin;
                        clear indx_tmin;
                        indx_tmin = temp_indx_tmin(1);
                        clear temp_indx_tmin;
                    
                    end
        
                    % apply code correction only if compatible with the validity time. Assume
                    % the validity time to be the same always (300 sec normally)
        
                    if tmin <= ASIA_table.validity(1)

                        if STA_abb_v ~= "EKAR00ITA" % per ASIAGO non c'è l'osservazione C6C nel RINEX
        
                            if ~isnan(rinexdata.Galileo.C6C(i_tstart+i_time-1))
            
                               rinexdataHAS.Galileo.C6C(i_tstart+i_time-1) = rinexdata.Galileo.C6C(i_tstart+i_time-1)+code_biasE13(indx_tmin,pos_f); % Structure with RINEX OBS + HAS
                               code_biasE13_app(contaE13,pos_f) = code_biasE13(indx_tmin,pos_f); % effective applied correction 
                               ToWbreakE13_app(contaE1,pos_f) = ToWbreakE13(indx_tmin,pos_f);
                               contaE13 = contaE13+1;
            
                            end

                        end
                   
                    end
        
                    i_time=i_time+1;
        
                else
        
                    i_tstart=i_tstart+i_time-1;
                    i_time=1;
        
                end
        
            end
        
        break
        
        end
        
        d.Value = 1;
        d.Message = 'Finished';
        pause(3)
        
        % Close dialog box
        close(d)
        close(fig)
        
        %% Generate rinex new obs file
        
        rinex_cbHAS (filename_RNX,rinexdataHAS,STA_abb,STA_abb_n, yr4, doy);
    
    end

    % Cancello variabili per iterazione su più stazioni
    
    clc
    clearvars -except yr4 yr2 STA_abb_n STA_abb_n_v HAS_abb doy_i doy_f

end

%% JD2GPS

% Converts Julian date to GPS week number (since
%   1980.01.06) and seconds of week. Non-vectorized version.
%   See also CAL2JD, DOY2JD, GPS2JD, JD2CAL, JD2DOW, JD2DOY,
%   JD2YR, YR2JD.
% Version: 05 May 2010
% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

function [gpsweek,sow,rollover]=jd2gps(jd)

% Input:   
%
% * jd       - Julian date
% Output:  
% * gpsweek  - GPS week number
% * sow      - seconds of week since 0 hr, Sun.
% * rollover - number of GPS week rollovers (modulus 1024)

if nargin ~= 1
  warning('Incorrect number of arguments');
  return;
end
if jd < 0
  warning('Julian date must be greater than or equal to zero');
  return;
end

jdgps = cal2jd(1980,1,6);    % beginning of GPS week numbering
nweek = fix((jd-jdgps)/7);
sow = (jd - (jdgps+nweek*7)) * 3600*24;
rollover = fix(nweek/1024);  % rollover every 1024 weeks
%gpsweek = mod(nweek,1024);
gpsweek = nweek;
return
end

%% CAL2JD

function jd=cal2jd(yr,mn,dy)

% CAL2JD  Converts calendar date to Julian date using algorithm
%   from "Practical Ephemeris Calculations" by Oliver Montenbruck
%   (Springer-Verlag, 1989). Uses astronomical year for B.C. dates
%   (2 BC = -1 yr). Non-vectorized version. See also DOY2JD, GPS2JD,
%   JD2CAL, JD2DOW, JD2DOY, JD2GPS, JD2YR, YR2JD.
% Version: 2011-11-13
% Usage:   jd=cal2jd(yr,mn,dy)
% Input:   yr - calendar year (4-digit including century)
%          mn - calendar month
%          dy - calendar day (including factional day)
% Output:  jd - jJulian date

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3
  warning('Incorrect number of input arguments');
  return;
end
if mn < 1 || mn > 12
  warning('Invalid input month');
  return
end
if dy < 1
  if (mn == 2 && dy > 29) || (any(mn == [3 5 9 11]) && dy > 30) || (dy > 31)
    warning('Invalid input day');
    return
  end
end

if mn > 2
  y = yr;
  m = mn;
else
  y = yr - 1;
  m = mn + 12;
end
date1=4.5+31*(10+12*1582);   % Last day of Julian calendar (1582.10.04 Noon)
date2=15.5+31*(10+12*1582);  % First day of Gregorian calendar (1582.10.15 Noon)
date=dy+31*(mn+12*yr);
if date <= date1
  b = -2;
elseif date >= date2
  b = fix(y/400) - fix(y/100);
else
  warning('Dates between October 5 & 15, 1582 do not exist');
  return;
end
if y > 0
  jd = fix(365.25*y) + fix(30.6001*(m+1)) + b + 1720996.5 + dy;
else
  jd = fix(365.25*y-0.75) + fix(30.6001*(m+1)) + b + 1720996.5 + dy;
end
return
end
