tic;

% Return to ephConv
chdir 'C:\\multiGNSS_v3\\HAS';

% Script per la valutazione delle correzioni HAS della costellazione 
% Galileo e GPS; function richiamate: DoY_to_DoM.m, 
% SAT_disp.m, ToW_to_ToD.m, ToW_to_UTC.m, ToD_to_UTC, becp.m, 
% calcSSR_ECEF_mod.m, readATXoffsets.m, overwrite_SP3.m, readSP3.m,
% readDCB.m, GPS_date.m, calc_APC2CoM_t_w

% HELP INPUT

% costellazioni =  (Galileo: 2, GPS: 0)
% controllo =   se = 1, considera i termini aggiuntivi della [48] e [100] PFN-MEMO-232-3889-CNES Ed. 1 / Rev. 3 Date: 13/10/2023
% c_grafici =  (= 1 si grafici, = 0 no grafici)
% c_overwrite  (= 1 sovrascrivi BRDM+HAS in SP3, = 0 non sovrascrivere)
% c_SISRE  = (= 1 si SISRE, = 0 no SISRE); 
% AC_abb = abbreviazione del file SP3
% HAS_abb = abbreviazione delle correzioni HAS
% out_sp3_abb = abbreviazione del nuovo file SP3 con BRDM+HAS
% est = estensione file SP3 
% YR =  2-digit year
% dt = intervallo in minuti del file SP3 originale
% brdm_type =  Importante solo per la costellazione Galileo (513--> I/NAV, 258--> F/NAV)
% clite = 299792458; % [m/s]  
% omega_e = 0.000072921151467;

% HELP OUTPUT

% x_brdm_plus_HAS [km] = file .mat contenente la coordinata x ECEF con brdm 
% corretta con HAS del CoM del SAT ad intervalli di dt minuti a partire 
% da 00:00:00 del DoY

% y_brdm_plus_HAS [km] = file .mat contenente la coordinata y ECEF con brdm 
% corretta con HAS del CoM del SAT ad intervalli di dt minuti a partire 
% da 00:00:00 del DoY

% z_brdm_plus_HAS [km] = file .mat contenente la coordinata z ECEF con brdm 
% corretta con HAS del CoM del SAT ad intervalli di dt minuti a partire 
% da 00:00:00 del DoY

% dc_brdm_plus_HAS [microsecondi] = file .mat contenente la deriva del 
% clock con brdm corretta con HAS del CoM del SAT ad intervalli di dt 
% minuti a partire da 00:00:00 del DoY

% (out_sp3_abb)(WN)(DoW).est = file sp3 contenente la posizione e
% le deriva del clock corrette con correzioni HAS, nella directory
% (out_sp3_abb --> PPH)

% In Risultati/YR_DOY --> SISRE.mat

% SISRE_mat_orb_GPS --> SISRE orbitale (Montenbruck 2014) per i satelliti
% GPS di quel giorno

% SISRE_mat_orb_Gal --> SISRE orbitale (Montenbruck 2014) per i satelliti
% Gal di quel giorno

% SISRE_orb_GPS_tutti_SAT --> SISRE orbitale (Montenbruck 2014) per tutti i
% satelliti GPS di quel giorno

% SISRE_orb_Gal_tutti_SAT --> SISRE orbitale (Montenbruck 2014) per tutti i
% satelliti Gal di quel giorno

% SISRE_mat_tot_GPS --> SISRE totale (Montenbruck 2014) per i satelliti
% GPS di quel giorno

% SISRE_mat_tot_Gal --> SISRE totale (Montenbruck 2014) per i satelliti
% Gal di quel giorno

% SISRE_tot_GPS_tutti_SAT --> SISRE totale (Montenbruck 2014) per tutti i
% satelliti GPS di quel giorno

% SISRE_tot_Gal_tutti_SAT --> SISRE totale (Montenbruck 2014) per tutti i
% satelliti Gal di quel giorno

clc
clear 
clear vars

%% DEFINIZIONE DEGLI INPUT

for iter = 26:34 % iterno sul giorno da analizzare

    DoY = iter;

    % INPUT

    costellazioni = [0,2]; %(Galileo: 2, GPS: 0)
    
    controllo = 1; % se = 1, considera i termini aggiuntivi della [48] e [100] PFN-MEMO-232-3889-CNES Ed. 1 / Rev. 3 Date: 13/10/2023

    c_grafici = 1; % (= 1 si grafici, = 0 no grafici)

    c_overwrite = 1; % (= 1 sovrascrivi SP3 con BRDM+HAS, = 0 non sovrascrivere)

    c_SISRE = 1; % (= 1 si SISRE, = 0 no SISRE); 

    AC_abb = "cne";

    HAS_abb = 'ASIA';

    out_sp3_abb = "PPH";

    est = ".SP3";
        
    YR = 24;
        
    dt = 5;
        
    brdm_type = "I/NAV"; % Importante solo per la costellazione Galileo (513--> I/NAV, 258--> F/NAV)

    clite = 299792458; % [m/s] 
           
    omega_e = 0.000072921151467;

    % Selezione del DCB nel caso di GPS

    OBS_L1CA = "C1C";
    OBS_L1P = "C1W";

    % Selezione del DCB nel caso di Galileo

    OBS_E1 = "C1C";
    OBS_E5b = "C7Q";
    OBS_E5a = "C5Q";

    [DoM,MN] = DoY_to_DoM(DoY); % Calcolo giorno del mese e mese dato il DoY
    [WN,DoW] = GPS_date (DoM,MN,YR+2000); % Calcolo della settimana GPS e del giorno della settimana
    
    for v = 1:length(costellazioni) % Itero su costellazioni
    
        costellazione = costellazioni(1,v);
    
        % Costruzione dei file in formato matlab contenenti: HAS, BRDM e SP3 
        % per il DoY e verifica per quali satelliti sono disponibili 
        % contemporaneamente mediante la function SAT_disp.m
        
        [SAT_disponibili,mat,mat_i,sp3_disp_v,sp3_disp] = SAT_disp (HAS_abb,est,AC_abb,WN,DoW,YR,DoY,costellazione,DoM,MN); 
        
        % porzione per rimuovere uno specifico satellite in base al giorno,
        % sono satelliti che hanno presentato delle problematiche

        % if costellazione == 2 % Galileo
        % 
        %     if DoY == 82 || DoY == 155 || DoY == 156
        % 
        %         temp = SAT_disponibili;
        %         clear SAT_disponibili;
        % 
        %         conta = 1;
        % 
        %         for i = 1:length(temp)
        % 
        %             if DoY == 82 % si toglie il satellite 1 Galileo
        % 
        %                 if temp(i) ~= 1
        % 
        %                     SAT_disponibili(conta) = temp(i);
        %                     conta = conta+1;
        % 
        %                 end
        % 
        %             end
        % 
        %             if DoY == 155 || DoY == 156 % si toglie il satellite 11 Galileo
        % 
        %                 if temp(i) ~= 11
        % 
        %                     SAT_disponibili(conta) = temp(i);
        %                     conta = conta+1;
        % 
        %                 end
        % 
        %             end
        % 
        %         end
        % 
        %         clear temp 
        % 
        %     end
        % 
        % end % Rimozione satellite fino a qui

        % if costellazione == 0 % GPS
        % 
        %     if DoY == 106
        % 
        %         temp = SAT_disponibili;
        %         clear SAT_disponibili;
        % 
        %         conta = 1;
        % 
        %         for i = 1:length(temp)
        % 
        %             if DoY == 106 % si toglie il satellite 6 Galileo
        % 
        %                 if temp(i) ~= 6
        % 
        %                     SAT_disponibili(conta) = temp(i);
        %                     conta = conta+1;
        % 
        %                 end
        % 
        %             end
        % 
        %         end
        % 
        %         clear temp 
        % 
        %     end
        % 
        % end % Rimozione satellite fino a qui
        
        % Salvataggio dei satelliti disponibili nella directory "Risultati"
    
        str2 = num2str(DoY);
        cont = strcat(num2str(YR),'_',num2str(DoY));
    
        % Verifica se esiste la directory YR_DoY nella directory Risultati,
        % se non esiste verrà creata, con le sottodirectory GPS e Galileo, che 
        % a loro volta hanno le sotto directory con il numero del satellite in
        % questione
    
        if ~exist(strcat('Risultati\',cont),'dir')
    
            mkdir (strcat('Risultati\',cont)) % creazione della sottodirectory YR_DoY
    
        end
        
        % Verifica se esiste la directory YR nella directory PPH,
        % se non esiste verrà creata
    
        if ~exist(strcat('PPH\',num2str(YR+2000)),'dir')
            
            mkdir (strcat('PPH\',num2str(YR+2000))) % creazione della sottodirectory YR
        
        end
        
        % Definizione delle frequenze per definire l'APC offset con CoM dei
        % satelliti Galileo e GPS
    
        % Gal
            
        if costellazione == 2
            
            f1 = 1575.42; % E1, prima freqeunza del segnale per la comninazione iono-free APC2CoM
                    
            f2 = 1207.14; % E5b, seconda freqeunza del segnale per la comninazione iono-free APC2CoM
                
            f3 = 1176.45; % E5a
    
            mu = 398600441800000;
            
        end
        
        % GPS
            
        if costellazione == 0
            
            f1 = 1575.42; % prima freqeunza del segnale per la comninazione iono-free APC2CoM
                    
            f2 = 1227.6; % seconda freqeunza del segnale per la comninazione iono-free APC2CoM
                
            mu = 398600500000000;
            
        end
        
        % Creazione della sotto directory in \Risultati se non esiste
               
        % GPS
        
        if costellazione == 0
        
            if ~exist(strcat('Risultati\',cont,'\GPS'),'dir')
            
                mkdir (strcat('Risultati\',cont,'\GPS')) % creazione della sottodirectory GPS
            
                for i = 1:length(SAT_disponibili)
            
                    mkdir (strcat('Risultati\',cont,'\GPS\',num2str(SAT_disponibili(i)))); % creazione delle sotto directory dei singoli satelliti
            
                end
            
            end
        
        end
        
        % Galileo
        
        if costellazione == 2
        
            if ~exist(strcat('Risultati\',cont,'\Galileo'),'dir')
            
                mkdir (strcat('Risultati\',cont,'\Galileo')) % creazione della sottodirectory Galileo
            
                for i = 1:length(SAT_disponibili)
            
                    mkdir (strcat('Risultati\',cont,'\Galileo\',num2str(SAT_disponibili(i)))); % creazione delle sotto directory dei singoli satelliti
            
                end
            
            end
        
        end
    
        % Salvataggio dei satelliti dipsonibili (BRDM e HAS)
        
        if costellazione == 0 % GPS
            
            str3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',cont,'\GPS\SAT_disp_GPS_');
        
        end
        
        if costellazione == 2 % Gal
            
            str3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',cont,'\Galileo\SAT_disp_Galileo_');
        
        end
            
        path = strcat(str3,str2);     
        save(path,'SAT_disponibili');
        
        % Copia e rinomina il file sp3 originale con l'abbreviazione necessaria
        % per il Bernese nella directory giusta
    
        if v == 1
        
            source =  strcat('C:\multiGNSS_v3\input\sp3\',AC_abb,num2str(WN),num2str(DoW),est);
            destination =  strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\',out_sp3_abb,num2str(WN),num2str(DoW),est);
    
            if ~exist(destination, 'file') == 1
            
                copyfile (source,destination)
            
            end
    
        end
        
        % Se non esiste crea la directory con l'abbreviazione specifica 
        % (out_sp3_abb) dei file sp3 da analizzare con il Bernese all'interno della 
        % directory HAS, dove saranno contenuti i file da dare in pasto al
        % Bernese
        
        if ~exist(strcat(out_sp3_abb,'\',num2str(YR+2000)), 'dir')
        
              mkdir (strcat(out_sp3_abb,'\',num2str(YR+2000))) % directory out_sp3_abb
        
        end
        
        if ~exist(strcat(out_sp3_abb,'\',num2str(YR+2000),'\log file'), 'dir')
        
              mkdir (strcat(out_sp3_abb,'\',num2str(YR+2000),'\log file')) % crea anche la directory log file
        
        end
        
        % Vettori per identificare i singoli satelliti dai vari file (SP3, BRDM e
        % HAS)
        
        if costellazione == 2
        
            SAT_ID = ["E01","E02","E03","E04","E05","E06","E07","E08","E09","E10","E11","E12","E13","E14","E15","E16","E17","E18","E19","E20","E21","E22","E23","E24","E25","E26","E27","E28","E29","E30","E31","E32","E33","E34","E35","E36"];
        
        end
        
        if costellazione == 0
        
            SAT_ID = ["G01","G02","G03","G04","G05","G06","G07","G08","G09","G10","G11","G12","G13","G14","G15","G16","G17","G18","G19","G20","G21","G22","G23","G24","G25","G26","G27","G28","G29","G30","G31","G32","G33","G34","G35","G36"];
        
        end
        
        brdm_type_iniz = brdm_type; % variabile che viene salvata che contiene il tipo di efemeridi da utilizzare per Galileo (INAV o FNAV)
        
        %% LOG FILE, INTESTAZIONE

        % log file HAS and OS availability, ORBITAL
        
        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file\');
        
        if costellazione == 2
                
            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
        
        end
        
        if costellazione == 0
                
            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
        
        end
        
        fid_a = fopen(fullfile(filename, name_log), 'w'); % Con questo comando: nel caso esista già un file log, allora si sovrascrive il contenuto precedente e se nel genera uno nuovo
        % fid_a = fopen(fullfile(filename, name_log), 'a'); % Con questo comando: nel caso esista già un file log, allora si aggiunge al contenuto già esistente quello nuovo
        
        if fid_a == -1
              error('Cannot open log file.');
        end
        
        % 1 riga
        
        msg_log = "---------------------------------------------------------------";
        
        fprintf(fid_a, '%s\n', msg_log{1,1});
        
        % 3 riga
        
        if costellazione == 2
        
            msg_log = strcat('GIORNO',{' '},num2str(DoY),{' '},'ANNO',{' '},num2str(YR+2000),{' '},'-',{' '},'GALILEO');
        
        end
        
        if costellazione == 0
        
            msg_log = strcat('GIORNO',{' '},num2str(DoY),{' '},'ANNO',{' '},num2str(YR+2000),{' '},'-',{' '},'GPS');
        
        end
        
        fprintf(fid_a, '\n%s %s %s %s\n', msg_log{1,1});
        
        % 4 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '\n%s\n' , msg_log{1,1});
        
        % 6 riga
        
        if costellazione == 2
        
            if DoY < 100
            
                msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm0',num2str(DoY),'0gal.',num2str(YR),'P',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
            
            if DoY > 100 || DoY == 100
            
                msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm',num2str(DoY),'0gal.',num2str(YR),'P',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
        
        end
        
        if costellazione == 0
        
            if DoY < 100
            
                 msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm0',num2str(DoY),'0gps.',num2str(YR),'P',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
        
            end
            
            if DoY > 100 || DoY == 100
            
                  msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm',num2str(DoY),'0gps.',num2str(YR),'P',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
        
        end
        
        fprintf(fid_a, '\n%s %s %s %s \n', msg_log{1,1});
        
        % 7 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 8 riga
                    
        msg_log = strcat('INPUT:',{' '},'DoY',{' '},num2str(DoY),{' '},'Year',{' '},num2str(YR+2000),{' '},'Brdm',{' '},brdm_type,{' '},'c [m/s]',{' '},num2str(clite),{' '},'u [m^3/s^2]',{' '},num2str(mu),{' '},'omega_e [rad/s]',{' '},num2str(omega_e),'.');
        
        fprintf(fid_a, '\n%s %s %s %s %s %s %s %s %s\n', msg_log{1,1});
        
        % 9 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 10 riga
        
        msg_log = "OUTPUT: x_brdm_plus_HAS y_brdm_plus_HAS z_brdm_plus_HAS dc_brdm_plus_HAS.";
        
        fprintf(fid_a, '\n%s\n' , msg_log{1,1});
        
        % 11 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 12 riga
        
        if costellazione == 2
        
            msg_log = strcat('OUTPUT FILE:',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,' (brdm+HAS al posto dei dati sp3 per i satelliti indicati nelle NOTE)',{' '},out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt (log file).');
        
        end
        
        if costellazione == 0
        
            msg_log = strcat('OUTPUT FILE:',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,' (brdm+HAS al posto dei dati sp3 per i satelliti indicati nelle NOTE)',{' '},out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt (log file).');
        
        end
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 13 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 14 riga
        
        msg_log = "MATLAB: script val_HAS.m che richiama le function: DoY_to_DoM.m SAT_disp.m divisione_HAS ToW_to_ToD.m becp.m calcSSR_ECEF_mod.m readATXoffsets.m overwrite_SP3.m.";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 15 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 16 riga
        
        msg_log = "NOTE:";
        
        fprintf(fid_a, '\n %s\n' , msg_log{1,1});
        
        % 17 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        sp3_disp_v = sp3_disp_v';
        n = 1;
        
        SAT_disp_str = strings(1,length(sp3_disp_v));
        
        for i = 1:length(sp3_disp_v)
        
            for p = 1:length(SAT_disponibili)
        
                if sp3_disp_v(i) == SAT_disponibili(p)
        
                    SAT_disp_str(n) = sp3_disp(i);
                    n = n+1;
        
                end
        
            end
        
        end
        
        if isempty(SAT_disp_str)
        
            a = "Nessun satellite disponibile";
        
        else
        
            a = SAT_disp_str(1);
        
        end
        
        if ~isempty(SAT_disp_str)
        
            for i = 2:length(SAT_disp_str)
            
                msg_a = strcat(a{1,1},{' '},num2str(SAT_disp_str(i)));
                a = msg_a;
            
            end
        
        else
        
            msg_a = a;
        
        end
        
        % 18 riga
        
        msg_log = strcat('* Satelliti per cui vengono sostituiti i dati sp3 con brdm+HAS nel file di output',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,':',{' '},msg_a);
        
        fprintf(fid_a, '\n %s\n', msg_log{1,1});
    
        % 19 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 20 riga

        msg_log = "LEGENDA: 0 --> HAS disponibile (valori finiti delle correzioni HAS orbitali). Sul file SP3 vengono inseriti BRDM+HAS orbitali";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 21 riga

        msg_log = "LEGENDA: 1 --> blocco BRDM in modalità HAS non esistente. Sul file SP3 per le orbite vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 22 riga

        msg_log = "LEGENDA: 2 --> correzioni HAS valide sono solo NaN. Sul file SP3 per le orbite vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 23 riga

        msg_log = "LEGENDA: 3 --> correzioni HAS che non rispettano la validity. Sul file SP3 per le orbite vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 24 riga

        msg_log = "LEGENDA: 4 --> nessun record HAS per quel satellite per quel giorno. Sul file SP3 per le orbite vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 25 riga

        msg_log = "LEGENDA: 5 --> blocco BRDM in modalità HAS relativo al giorno precedente. Sul file SP3 per le orbite vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 26 riga

        msg_log = "LEGENDA: 6 --> Al posto di BRDM+HAS è stato messo BRDM OS che però è fuori dalla validity del blocco BRDM OS. Sul file SP3 per le orbite vengono inseriti i dati SP3 CNES";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 27 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 28 riga

        msg_log = ({'        ,'});

        for b = 1:(86400/(dt*60))
            
            if b < 10

            msg_log = strcat(msg_log,{'  '},num2str(b),',');

            end

            if b > 9 && b < 100

            msg_log = strcat(msg_log,{' '},num2str(b),',');

            end

            if b > 99

            msg_log = strcat(msg_log,num2str(b),',');

            end

        end

        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % log file HAS and OS availability, CLOCK
        
        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file\');
        
        if costellazione == 2
                
            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
        
        end
        
        if costellazione == 0
                
            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
        
        end
        
        fid_a = fopen(fullfile(filename, name_log), 'w'); % Con questo comando: nel caso esista già un file log, allora si sovrascrive il contenuto precedente e se nel genera uno nuovo
        % fid_a = fopen(fullfile(filename, name_log), 'a'); % Con questo comando: nel caso esista già un file log, allora si aggiunge al contenuto già esistente quello nuovo
        
        if fid_a == -1
              error('Cannot open log file.');
        end
        
        % 1 riga
        
        msg_log = "---------------------------------------------------------------";
        
        fprintf(fid_a, '%s\n', msg_log{1,1});
        
        % 3 riga
        
        if costellazione == 2
        
            msg_log = strcat('GIORNO',{' '},num2str(DoY),{' '},'ANNO',{' '},num2str(YR+2000),{' '},'-',{' '},'GALILEO');
        
        end
        
        if costellazione == 0
        
            msg_log = strcat('GIORNO',{' '},num2str(DoY),{' '},'ANNO',{' '},num2str(YR+2000),{' '},'-',{' '},'GPS');
        
        end
        
        fprintf(fid_a, '\n%s %s %s %s\n', msg_log{1,1});
        
        % 4 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '\n%s\n' , msg_log{1,1});
        
        % 6 riga
        
        if costellazione == 2
        
            if DoY < 100
            
                msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm0',num2str(DoY),'0gal.',num2str(YR),'P',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
            
            if DoY > 100 || DoY == 100
            
                msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm',num2str(DoY),'0gal.',num2str(YR),'P',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
        
        end
        
        if costellazione == 0
        
            if DoY < 100
            
                 msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm0',num2str(DoY),'0gps.',num2str(YR),'P',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
        
            end
            
            if DoY > 100 || DoY == 100
            
                  msg_log = strcat('INPUT FILE:',{' '},AC_abb,num2str(WN),num2str(DoW),est,' (contenente dati sp3)',{' '},{' '},'brdm',num2str(DoY),'0gps.',num2str(YR),'P',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_orb.csv',{' '},HAS_abb,num2str(DoY),'0.',num2str(YR),'_has_clk.csv','.');
            
            end
        
        end
        
        fprintf(fid_a, '\n%s %s %s %s \n', msg_log{1,1});
        
        % 7 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 8 riga
                    
        msg_log = strcat('INPUT:',{' '},'DoY',{' '},num2str(DoY),{' '},'Year',{' '},num2str(YR+2000),{' '},'Brdm',{' '},brdm_type,{' '},'c [m/s]',{' '},num2str(clite),{' '},'u [m^3/s^2]',{' '},num2str(mu),{' '},'omega_e [rad/s]',{' '},num2str(omega_e),'.');
        
        fprintf(fid_a, '\n%s %s %s %s %s %s %s %s %s\n', msg_log{1,1});
        
        % 9 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 10 riga
        
        msg_log = "OUTPUT: x_brdm_plus_HAS y_brdm_plus_HAS z_brdm_plus_HAS dc_brdm_plus_HAS.";
        
        fprintf(fid_a, '\n%s\n' , msg_log{1,1});
        
        % 11 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 12 riga
        
        if costellazione == 2
        
            msg_log = strcat('OUTPUT FILE:',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,' (brdm+HAS al posto dei dati sp3 per i satelliti indicati nelle NOTE)',',',{' '},out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt (log file).');
        
        end
        
        if costellazione == 0
        
            msg_log = strcat('OUTPUT FILE:',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,' (brdm+HAS al posto dei dati sp3 per i satelliti indicati nelle NOTE)',',',{' '},out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt (log file).');
        
        end
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 13 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 14 riga
        
        msg_log = "MATLAB: script val_HAS.m che richiama le function: DoY_to_DoM.m SAT_disp.m divisione_HAS ToW_to_ToD.m becp.m calcSSR_ECEF_mod.m readATXoffsets.m overwrite_SP3.m.";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        % 15 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 16 riga
        
        msg_log = "NOTE:";
        
        fprintf(fid_a, '\n %s\n' , msg_log{1,1});
        
        % 17 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        sp3_disp_v = sp3_disp_v';
        n = 1;
        
        SAT_disp_str = strings(1,length(sp3_disp_v));
        
        for i = 1:length(sp3_disp_v)
        
            for p = 1:length(SAT_disponibili)
        
                if sp3_disp_v(i) == SAT_disponibili(p)
        
                    SAT_disp_str(n) = sp3_disp(i);
                    n = n+1;
        
                end
        
            end
        
        end
        
        if isempty(SAT_disp_str)
        
            a = "Nessun satellite disponibile";
        
        else
        
            a = SAT_disp_str(1);
        
        end
        
        if ~isempty(SAT_disp_str)
        
            for i = 2:length(SAT_disp_str)
            
                msg_a = strcat(a{1,1},{' '},num2str(SAT_disp_str(i)));
                a = msg_a;
            
            end
        
        else
        
            msg_a = a;
        
        end
        
        % 18 riga
        
        msg_log = strcat('* Satelliti per cui vengono sostituiti i dati sp3 con brdm+HAS nel file di output',{' '},out_sp3_abb,num2str(WN),num2str(DoW),est,':',{' '},msg_a);
        
        fprintf(fid_a, '\n %s\n', msg_log{1,1});
    
        % 19 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 20 riga

        msg_log = "LEGENDA: 0 --> HAS disponibile (valori finiti delle correzioni HAS orbitali). Sul file SP3 vengono inseriti BRDM+HAS del clock";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 21 riga

        msg_log = "LEGENDA: 1 --> blocco BRDM in modalità HAS non esistente. Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 22 riga

        msg_log = "LEGENDA: 2 --> correzioni HAS valide sono solo NaN. Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 23 riga

        msg_log = "LEGENDA: 3 --> correzioni HAS che non rispettano la validity. Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 24 riga

        msg_log = "LEGENDA: 4 --> nessun record HAS per quel satellite per quel giorno. Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 25 riga

        msg_log = "LEGENDA: 5 --> blocco BRDM in modalità HAS relativo al giorno precedente. Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 26 riga

        msg_log = "LEGENDA: 6 --> correzioni HAS valide valide sono solo staus = 1 (shall not be used). Sul file SP3 per il clock vengono inseriti i dati BRDM OS";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 27 riga

        msg_log = "LEGENDA: 7 --> Al posto di BRDM+HAS è stato messo BRDM OS che però è fuori dalla validity del blocco BRDM OS. Sul file SP3 per il clock vengono inseriti i dati SP3 CNES";
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 28 riga
        
        msg_log = ({' '});
        
        fprintf(fid_a, '%s\n' , msg_log{1,1});

        % 29 riga

        msg_log = ({'        ,'});

        for b = 1:(86400/(dt*60))
            
            if b < 10

            msg_log = strcat(msg_log,{'  '},num2str(b),',');

            end

            if b > 9 && b < 100

            msg_log = strcat(msg_log,{' '},num2str(b),',');

            end

            if b > 99

            msg_log = strcat(msg_log,num2str(b),',');

            end

        end

        fprintf(fid_a, '%s\n' , msg_log{1,1});
        
        %% CARICAMENTO FILE SP3
        
        % Caricamento del file contenente i dati SP3 peril DoY per tutti i satelliti e
        % creazione del file struct sp3Sys
        
        fileName = strcat('C:\multiGNSS_v3\input\sp3\',AC_abb,num2str(WN),num2str(DoW),est);
        
        epoch0 = [YR+2000,MN,DoM,0,0,0];
        sp3Sys = readSP3(fileName,epoch0,DoW,dt);
        
        %% CARICAMENTO CORREZIONI HAS
        
        % Caricamento del file contenente i dati HAS per tutti i satelliti Galileo 
        % e GPS nel DoY e creazione del file table
        
        if DoY < 100
            
            fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_orb.csv');
            fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_clk.csv');
            fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_cb.csv');
            
        end
        
        if DoY > 100 || DoY == 100
            
            fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY),'0.',num2str(YR),'__has_orb.csv');
            fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY),'0.',num2str(YR),'__has_clk.csv');
            fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY),'0.',num2str(YR),'__has_cb.csv');
            
        end
        
        % Importazione HAS data dal .csv file
        
        % Correzioni orbitali
                
        % Setup the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 11);
                
        % Specify range and delimiter
        opts.DataLines = [2, inf];
        opts.Delimiter = ",";
                
        % Specify column names and types
        opts.VariableNames = ["ToW", "WN", "ToH", "IOD", "gnssIOD", "validity", "gnssID", "PRN", "delta_radial", "delta_in_track", "delta_cross_track"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
                
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
                
        % Import the data
        
        HAS_table_orb_comp = readtable(fileName1, opts);
        
        % Correzioni clock
                
        % Setup the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 11);
                
        % Specify range and delimiter
        opts.DataLines = [2, inf];
        opts.Delimiter = ",";
                
        % Specify column names and types
        opts.VariableNames = ["ToW", "WN", "ToH", "IOD", "gnssIOD", "validity", "gnssID", "PRN", "multiplier", "delta_clock_c0", "status"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
                
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
                
        % Import the data
        
        HAS_table_clk_comp = readtable(fileName2, opts);
    
        % Correzioni code bias
                
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
        
        HAS_table_code_bias_comp = readtable(fileName3, opts);

        % Importo le correzioni HAS del giorno precedente

        % Caricamento del file contenente i dati HAS per tutti i satelliti Galileo 
        % e GPS nel DoY e creazione del file table
        
        if DoY < 100

            if DoW == 0
            
                fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_orb.csv');
                fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_clk.csv');
                fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_cb.csv');

            else

                fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_orb.csv');
                fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_clk.csv');
                fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY-1),'0.',num2str(YR),'__has_cb.csv');

            end
        
        end
        
        if DoY > 100 || DoY == 100

            if DoW == 0
                
                fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_orb.csv');
                fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_clk.csv');
                fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN-1),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_cb.csv');
        
            else
    
                fileName1 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_orb.csv');
                fileName2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_clk.csv');
                fileName3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY-1),'0.',num2str(YR),'__has_cb.csv');
        
            end
            
        end
        
        % Importazione HAS data dal .csv file
        
        % Correzioni orbitali
                
        % Setup the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 11);
                
        % Specify range and delimiter
        opts.DataLines = [2, inf];
        opts.Delimiter = ",";
                
        % Specify column names and types
        opts.VariableNames = ["ToW", "WN", "ToH", "IOD", "gnssIOD", "validity", "gnssID", "PRN", "delta_radial", "delta_in_track", "delta_cross_track"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
                
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
                
        % Import the data
        
        HAS_table_orb_comp_i = readtable(fileName1, opts);
        
        % Correzioni clock
                
        % Setup the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 11);
                
        % Specify range and delimiter
        opts.DataLines = [2, inf];
        opts.Delimiter = ",";
                
        % Specify column names and types
        opts.VariableNames = ["ToW", "WN", "ToH", "IOD", "gnssIOD", "validity", "gnssID", "PRN", "multiplier", "delta_clock_c0", "status"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
                
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
                
        % Import the data
        
        HAS_table_clk_comp_i = readtable(fileName2, opts);
    
        % Correzioni code bias
                
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
        
        HAS_table_code_bias_comp_i = readtable(fileName3, opts);
        
        %% CARICAMENTO FILE BRDM  
            
        % Dati BRDM presi dalla cartella ...input\brdm, in questa cartella i file sono già spacchettati per costellazione
            
        % Caricamento del file contenente le efemeridi BROADCAST per tutti i 
        % satelliti della costellazione nel DoY 
            
        DoY_pre = DoY-1;
                
        % Galileo
            
        % è importante che brdm186gal.22p sia sempre presente nella directory
        % BRDM\ref
                
        if costellazione == 2
            
            opt = detectImportOptions('C:\multiGNSS_v3\HAS\BRDM\ref\brdm1860gal.22p', 'FileType','fixedWidth', 'VariableNamesLine',1,'VariableNamingRule','preserve', 'ExpectedNumVariables',36);
                
            if DoY < 100
                
                fileName3 = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY),'0gal.',num2str(YR),'p');
                          
                F = readtable(fileName3,opt);
                    
            end
                
            if DoY > 100 || DoY == 100
            
                fileName3 = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY),'0gal.',num2str(YR),'p');
                
                F = readtable(fileName3,opt);
            
            end
                    
            if DoY_pre < 100
            
                fileName4 = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY_pre),'0gal.',num2str(YR),'p');
                
                G = readtable(fileName4,opt);
                        
            end
                    
            if DoY_pre > 100 || DoY_pre == 100
                        
                fileName4 = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY_pre),'0gal.',num2str(YR),'p');
            
                G = readtable(fileName4,opt);
            
            end
        
            clear DoY_pre
            
            mat = cell(height(F),width(F));
            mat_i = cell(height(G),width(G));
            
            for i = 1:width(F)
            
                a = table2array(F(:,i));   
                mat(:,i) = num2cell(a);
                        
            end
            
            for i = 1:width(G)
                
                b = table2array(G(:,i));
                mat_i(:,i) = num2cell(b);
            
            end
            
            clear F
            clear G
            clear a
            clear b
            clear i
        
            % BRDM_table contiene le efemeridi broadcast nel DoY
        
            BRDM_table = cell2table(mat,'VariableNames',{'SAT' 'YEAR' 'MO' 'DY' 'HR' 'MN' 'SS' 'BIAS [s]' 'DRIFT [s/s]' 'RATE [s/s^2]' 'IODnav [-]' 'CRS [m]' 'Delta n [rad/s]' 'M0 [rad]' 'CUC [rad]' 'E [-]' 'CUS [rad]' 'A^1/2 [m^1/2]' 'TOE [s]' 'CIC [rad]' 'OMEGA0 [rad]' 'CIS [rad]' 'I0 [rad]' 'CRC [m]' 'omega [rad]' 'OMEGA DOT [rad/s]' 'IDOT [rad/s]' 'Data Sources [-]' 'GAL week [#]' ' ' 'SISA [m]' 'SV health [-]' 'BGD E5a/E1 [s]' 'BGD E5b/E1 [s]' 'TIME MSG [s]' 'Message Type'});
            BRDM_table_comp = BRDM_table; % tabella completa avente I/NAV e F/NAV
            clear BRDM_table
            idata_brdm = find(BRDM_table_comp.("Message Type") == brdm_type);
            BRDM_table = BRDM_table_comp(idata_brdm,:); % tabella con solo le efemeridi brdm_type
            
            % BRDM_table contiene le efemeridi broadcast nel DoY-1
            BRDM_table_i = cell2table(mat_i,'VariableNames',{'SAT' 'YEAR' 'MO' 'DY' 'HR' 'MN' 'SS' 'BIAS [s]' 'DRIFT [s/s]' 'RATE [s/s^2]' 'IODnav [-]' 'CRS [m]' 'Delta n [rad/s]' 'M0 [rad]' 'CUC [rad]' 'E [-]' 'CUS [rad]' 'A^1/2 [m^1/2]' 'TOE [s]' 'CIC [rad]' 'OMEGA0 [rad]' 'CIS [rad]' 'I0 [rad]' 'CRC [m]' 'omega [rad]' 'OMEGA DOT [rad/s]' 'IDOT [rad/s]' 'Data Sources [-]' 'GAL week [#]' ' ' 'SISA [m]' 'SV health [-]' 'BGD E5a/E1 [s]' 'BGD E5b/E1 [s]' 'TIME MSG [s]' 'Message Type'});
            BRDM_table_comp_i = BRDM_table_i; % tabella completa avente I/NAV e F/NAV
            clear BRDM_table_i
            idata_brdm = find(BRDM_table_comp_i.("Message Type") == brdm_type);
            BRDM_table_i = BRDM_table_comp_i(idata_brdm,:); % tabella con solo le efemeridi brdm_type
    
        end
            
        % GPS
            
        if costellazione == 0
                
            if DoY < 100
                    
                fileName3 = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY),'0gps.',num2str(YR),'p');
                          
                F = readtable(fileName3,'FileType','text');
                    
            end
                
            if DoY > 100 || DoY == 100
            
                fileName3 = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY),'0gps.',num2str(YR),'p');
                
                F = readtable(fileName3,'FileType','text');
            
            end
                    
            if DoY_pre < 100
            
                fileName4 = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY_pre),'0gps.',num2str(YR),'p');
                
                G = readtable(fileName4,'FileType','text');
                        
            end
                    
            if DoY_pre > 100 || DoY_pre == 100
                        
                fileName4 = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY_pre),'0gps.',num2str(YR),'p');
            
                G = readtable(fileName4,'FileType','text');
            
            end
        
            clear DoY_pre
            
            mat = cell(height(F),width(F));
            mat_i = cell(height(G),width(G));
            
            for i = 1:width(F)
            
                a = table2array(F(:,i));   
                mat(:,i) = num2cell(a);
                        
            end
            
            for i = 1:width(G)
                
                b = table2array(G(:,i));
                mat_i(:,i) = num2cell(b);
            
            end
            
            clear F
            clear G
            clear a
            clear b
            clear i 
        
            % BRDM_table contiene le efemeridi broadcast nel DoY
        
            BRDM_table = cell2table(mat,'VariableNames',{'SAT' 'YEAR' 'MO' 'DY' 'HR' 'MN' 'SS' 'BIAS [s]' 'DRIFT [s/s]' 'RATE [s/s^2]' 'IODE [-]' 'CRS [m]' 'Delta n [rad/s]' 'M0 [rad]' 'CUC [rad]' 'E [-]' 'CUS [rad]' 'A^1/2 [m^1/2]' 'TOE [s]' 'CIC [rad]' 'OMEGA0 [rad]' 'CIS [rad]' 'I0 [rad]' 'CRC [m]' 'omega [rad]' 'OMEGA DOT [rad/s]' 'IDOT [rad/s]' '# CODE L2 [#]' 'GPS week [#]' 'L2 P [-]' 'SV accuracy [m]' 'SV health [-]' 'TGD [s]' 'IODC [-]' 'TIME MSG [s]' 'Fit interval [hr]'});
            BRDM_table_i = cell2table(mat_i,'VariableNames',{'SAT' 'YEAR' 'MO' 'DY' 'HR' 'MN' 'SS' 'BIAS [s]' 'DRIFT [s/s]' 'RATE [s/s^2]' 'IODE [-]' 'CRS [m]' 'Delta n [rad/s]' 'M0 [rad]' 'CUC [rad]' 'E [-]' 'CUS [rad]' 'A^1/2 [m^1/2]' 'TOE [s]' 'CIC [rad]' 'OMEGA0 [rad]' 'CIS [rad]' 'I0 [rad]' 'CRC [m]' 'omega [rad]' 'OMEGA DOT [rad/s]' 'IDOT [rad/s]' '# CODE L2 [#]' 'GPS week [#]' 'L2 P [-]' 'SV accuracy [m]' 'SV health [-]' 'TGD [s]' 'IODC [-]' 'TIME MSG [s]' 'Fit interval [hr]'});
        
        end
    
        %% CARICAMENTO FILE DCB
    
        if DoY > 99
    
                fileName5 = strcat('C:\multiGNSS_v3\input\DCB\CAS0MGXRAP_',num2str(YR+2000),num2str(DoY),'0000_01D_01D_DCB.BSX');
         
        end
         
        if DoY < 100 && DoY > 9
    
                fileName5 = strcat('C:\multiGNSS_v3\input\DCB\CAS0MGXRAP_',num2str(YR+2000),'0',num2str(DoY),'0000_01D_01D_DCB.BSX');
         
        end
    
        if DoY < 10
    
                fileName5 = strcat('C:\multiGNSS_v3\input\DCB\CAS0MGXRAP_',num2str(YR+2000),'00',num2str(DoY),'0000_01D_01D_DCB.BSX');
         
        end
    
        % DCBSys contiene i DCB
    
        DCBSys = readDCB(fileName5);
    
        %% INIZIALIZZAZIONE DEI VETTORI PER IL CALCOLO DEL SISRE 
        
        diff_r_tutti_SAT_GPS = [];
        diff_t_tutti_SAT_GPS = [];
        diff_w_tutti_SAT_GPS = [];
        diff_dc_tutti_SAT_GPS = [];
        diff_r_tutti_SAT_Gal = [];
        diff_t_tutti_SAT_Gal = [];
        diff_w_tutti_SAT_Gal = [];
        diff_dc_tutti_SAT_Gal = [];
            
        path_SISRE = strcat('C:\multiGNSS_v3\HAS\Risultati\calc_SISRE');
            
        % GPS
            
        if costellazione == 0
            
            diff_r_mat_GPS = zeros(289,length(SAT_disponibili));
            diff_t_mat_GPS = zeros(289,length(SAT_disponibili));
            diff_w_mat_GPS = zeros(289,length(SAT_disponibili));
            diff_dc_mat_GPS = zeros(289,length(SAT_disponibili));
                    
            for i = 1:length(SAT_disponibili)
                    
                diff_r_mat_GPS(1,i) = SAT_disponibili(i);
                diff_t_mat_GPS(1,i) = SAT_disponibili(i);
                diff_w_mat_GPS(1,i) = SAT_disponibili(i);
                diff_dc_mat_GPS(1,i) = SAT_disponibili(i);
                    
            end
                
            SISRE_mat_orb_GPS = zeros(length(SAT_disponibili),2);
            SISRE_mat_tot_GPS = zeros(length(SAT_disponibili),2);
                
            % salvataggio dati per il calcolo SISRE su tutti i satelliti
                
            save(path_SISRE,'diff_r_tutti_SAT_GPS','diff_t_tutti_SAT_GPS','diff_w_tutti_SAT_GPS','diff_dc_tutti_SAT_GPS','SISRE_mat_orb_GPS','diff_r_mat_GPS','diff_t_mat_GPS','diff_w_mat_GPS','diff_dc_mat_GPS');
            
        end
            
        % Gal
            
        if costellazione == 2
            
            diff_r_mat_Gal = zeros(289,length(SAT_disponibili));
            diff_t_mat_Gal = zeros(289,length(SAT_disponibili));
            diff_w_mat_Gal = zeros(289,length(SAT_disponibili));
            diff_dc_mat_Gal = zeros(289,length(SAT_disponibili));
                
            for i = 1:length(SAT_disponibili)
                    
                diff_r_mat_Gal(1,i) = SAT_disponibili(i);
                diff_t_mat_Gal(1,i) = SAT_disponibili(i);
                diff_w_mat_Gal(1,i) = SAT_disponibili(i);
                diff_dc_mat_Gal(1,i) = SAT_disponibili(i);
                    
            end
                
            SISRE_mat_orb_Gal = zeros(length(SAT_disponibili),2);
            SISRE_mat_tot_Gal = zeros(length(SAT_disponibili),2);

            % salvataggio dati per il calcolo SISRE su tutti i satelliti
                
            save(path_SISRE,'diff_r_tutti_SAT_Gal','diff_t_tutti_SAT_Gal','diff_w_tutti_SAT_Gal','diff_dc_tutti_SAT_Gal','SISRE_mat_orb_Gal','diff_r_mat_Gal','diff_t_mat_Gal','diff_w_mat_Gal','diff_dc_mat_Gal');
            
        end
        
        %% ITERAZIONE SUI SATELLITI PER CUI SONO DISPONIBILI SP3, BRDM e HAS NEL DoY
        
        % Importazione del contenuto del file ATX per il calcolo dell' APCO(Antenna Phase Center Offset) tra APC e CoM
            
        date = [YR+2000 MN DoY 0 0 0];
        
        apo = readATXoffsets(date);
    
        % Inizzializzazione dei vettori per le statistiche SP3-BRDM-HAS, per il
        % clock grandezze in ns, per x y x in m
    
        avg_brdm_plus_HAS_sp3_dc = zeros(n,2);
        avg_brdm_plus_HAS_sp3_x = zeros(n,2);
        avg_brdm_plus_HAS_sp3_y = zeros(n,2);
        avg_brdm_plus_HAS_sp3_z = zeros(n,2);
        rms_brdm_plus_HAS_sp3_x = zeros(n,2);
        rms_brdm_plus_HAS_sp3_y = zeros(n,2);
        rms_brdm_plus_HAS_sp3_z = zeros(n,2);
        rms_brdm_plus_HAS_sp3_dc = zeros(n,2);
    
        if costellazione == 0 % GPS
    
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_dc.mat');
            save(path,"avg_brdm_plus_HAS_sp3_dc");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_x.mat');
            save(path,"avg_brdm_plus_HAS_sp3_x");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_y.mat');
            save(path,"avg_brdm_plus_HAS_sp3_y");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_z.mat');
            save(path,"avg_brdm_plus_HAS_sp3_z");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_x.mat');
            save(path,"rms_brdm_plus_HAS_sp3_x");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_y.mat');
            save(path,"rms_brdm_plus_HAS_sp3_y");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_z.mat');
            save(path,"rms_brdm_plus_HAS_sp3_z");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_dc.mat');
            save(path,"rms_brdm_plus_HAS_sp3_dc");
    
        end
    
        if costellazione == 2 % Galileo
    
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_dc.mat');
            save(path,"avg_brdm_plus_HAS_sp3_dc");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_x.mat');
            save(path,"avg_brdm_plus_HAS_sp3_x");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_y.mat');
            save(path,"avg_brdm_plus_HAS_sp3_y");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_z.mat');
            save(path,"avg_brdm_plus_HAS_sp3_z");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_x.mat');
            save(path,"rms_brdm_plus_HAS_sp3_x");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_y.mat');
            save(path,"rms_brdm_plus_HAS_sp3_y");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_z.mat');
            save(path,"rms_brdm_plus_HAS_sp3_z");
            
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_dc.mat');
            save(path,"rms_brdm_plus_HAS_sp3_dc");
    
        end
        
        % Valutazione delle correzioni HAS per i satelliti disponibili nel DoY,
        % ciclo che itera sui satelliti disponibili per quel giorno
    
        for k = 1:length(SAT_disponibili) % k rappresenta la posizione del satellite nel vettore SAT_disponibili   
    
            SAT = SAT_disponibili(k); % SAT è il satellite k-esimo tra i satelliti disponibili     
            SAT_str = num2str(SAT);

            % Visualizza a video quale satellite si sta processando

            % if costellazione == 0
            % 
            %     frase = string(strcat('GPS ',SAT_str,': BRDM+HAS in SP3 giorno',{' '},num2str(DoY),{' '},'del',{' '},num2str(YR+2000))); 
            %     fig = uifigure;
            %     d = uiprogressdlg(fig,'Title',frase);
            %     pause(1)
            % 
            % end
            % 
            % if costellazione == 2
            % 
            %     frase = string(strcat('Galileo ',SAT_str,': BRDM+HAS in SP3 giorno',{' '},num2str(DoY),{' '},'del',{' '},num2str(YR+2000))); 
            %     fig = uifigure;
            %     d = uiprogressdlg(fig,'Title',frase);
            %     pause(1)
            % 
            % end
    
            % SELEZIONE DEL DCB PER IMPLEMENTAZIONE [68] - [100] - [105] per
            % calcolo dei termini con DCB
    
            if costellazione == 0 % GPS
    
                % Andiamo a selezionare il DCB per il satellite in fase di
                % conisderazione nel caso di GPS
            
                if SAT < 10
            
                    SAT_ID_str = strcat('G0',SAT_str);
            
                else
            
                    SAT_ID_str = strcat('G',SAT_str);
            
                end
            
                DCB_pos = find(DCBSys(:,1) == SAT_ID_str & DCBSys(:,4) == OBS_L1CA & DCBSys(:,5) == OBS_L1P);
                DCB = DCBSys(DCB_pos,2); % DCB del satellite GPS
    
            end
    
            if costellazione == 2 % Galileo
    
                % Andiamo a selezionare il DCB per i satelliti in fase di
                % conisderazione nel caso di Galileo
            
                if SAT < 10
            
                    SAT_ID_str = strcat('E0',SAT_str);
            
                else
            
                    SAT_ID_str = strcat('E',SAT_str);
            
                end
            
                DCB_pos_E1_E5b = find(DCBSys(:,1) == SAT_ID_str & DCBSys(:,4) == OBS_E1 & DCBSys(:,5) == OBS_E5b);
                DCB_E1_E5b = DCBSys(DCB_pos_E1_E5b,2); % DCB del satellite Galileo
                DCB_pos_E1_E5a = find(DCBSys(:,1) == SAT_ID_str & DCBSys(:,4) == OBS_E1 & DCBSys(:,5) == OBS_E5a);
                DCB_E1_E5a = DCBSys(DCB_pos_E1_E5a,2); % DCB del satellite Galileo
    
            end
    
            intervallo = k/length(SAT_disponibili);

            % Visualizza a video quale satellite si sta processando
            
            % d.Value =  intervallo;
            % d.Message = strcat(SAT_ID(SAT));
            % pause(1)

            % file log HAS and OS availability, all'inizo della riga si
            % inserisce il satellite, ORBITAL
        
            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                       
            if costellazione == 0 % GPS
    
                name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                           
                if SAT < 10
                               
                    msg_log = strcat('* PG0',num2str(SAT),{' '},':,');
                           
                end
                           
                if SAT > 10 || SAT == 10
                               
                    msg_log = strcat('* PG',num2str(SAT),{' '},':,');
                           
                end
    
            end
    
            if costellazione == 2 % GPS
    
                name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                           
                if SAT < 10
                               
                    msg_log = strcat('* PE0',num2str(SAT),{' '},':,');
                           
                end
                           
                if SAT > 10 || SAT == 10
                               
                    msg_log = strcat('* PE',num2str(SAT),{' '},':,');
                           
                end
    
            end
    
            fid_a = fopen(fullfile(filename, name_log), 'a');
    
            if fid_a == -1
            error('Cannot open log file.');
            end
    
            fprintf(fid_a, '\n%s', msg_log{1,1});
            fclose(fid_a);

            % file log HAS and OS availability, all'inizo della riga si
            % inserisce il satellite, CLOCK
        
            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                       
            if costellazione == 0 % GPS
    
                name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                           
                if SAT < 10
                               
                    msg_log = strcat('* PG0',num2str(SAT),{' '},':,');
                           
                end
                           
                if SAT > 10 || SAT == 10
                               
                    msg_log = strcat('* PG',num2str(SAT),{' '},':,');
                           
                end
    
            end
    
            if costellazione == 2 % GPS
    
                name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                           
                if SAT < 10
                               
                    msg_log = strcat('* PE0',num2str(SAT),{' '},':,');
                           
                end
                           
                if SAT > 10 || SAT == 10
                               
                    msg_log = strcat('* PE',num2str(SAT),{' '},':,');
                           
                end
    
            end
    
            fid_a = fopen(fullfile(filename, name_log), 'a');
    
            if fid_a == -1
            error('Cannot open log file.');
            end
    
            fprintf(fid_a, '\n%s', msg_log{1,1});
            fclose(fid_a);
    
            % Vettori per il calcolo del SISRE
    
            new_diff_r_rms = [];
            new_diff_t_rms = [];
            new_diff_w_rms = [];
            new_diff_dc_rms = [];
        
            % Creo delle sotto tabelle contenenti le correzioni HAS solo per il
            % satellite in fase di analisi
        
            clear idata
            idata = find(HAS_table_orb_comp.gnssID == costellazione & HAS_table_orb_comp.PRN == SAT);
            HAS_table_orb = HAS_table_orb_comp(idata,:);
            clear idata
            idata = find(HAS_table_clk_comp.gnssID == costellazione & HAS_table_clk_comp.PRN == SAT);
            HAS_table_clk = HAS_table_clk_comp(idata,:);
            clear idata
            idata = find(HAS_table_code_bias_comp.gnssID == costellazione & HAS_table_code_bias_comp.PRN == SAT);
            HAS_table_code_bias = HAS_table_code_bias_comp(idata,:);

            HAS_table_orb_DoY = HAS_table_orb; % salvo le correzioni HAS per il DoY
            HAS_table_clk_DoY = HAS_table_clk; % salvo le correzioni HAS per il DoY
            HAS_table_code_bias_DoY = HAS_table_code_bias; % salvo le correzioni HAS per il DoY

            % Spacchetto anche i dati HAS del giorno precedente

            clear idata
            idata = find(HAS_table_orb_comp_i.gnssID == costellazione & HAS_table_orb_comp_i.PRN == SAT);
            HAS_table_orb_i = HAS_table_orb_comp_i(idata,:);
            clear idata
            idata = find(HAS_table_clk_comp_i.gnssID == costellazione & HAS_table_clk_comp_i.PRN == SAT);
            HAS_table_clk_i = HAS_table_clk_comp_i(idata,:);
            clear idata
            idata = find(HAS_table_code_bias_comp_i.gnssID == costellazione & HAS_table_code_bias_comp_i.PRN == SAT);
            HAS_table_code_bias_i = HAS_table_code_bias_comp_i(idata,:);
            
            % Inizzializzazione vettori
        
            pos_found_brdm = []; % definisco pos_found_brdm come la posizione del blocco di efemeridi nella table contenente tutte le efemeridi broadcast per il DoY
            pos_found_HAS = []; % definisco pos_found_HAS come la posizione della correzione HAS orbitale nella table contenente tutte le correzioni HAS per il DoY
            n = 86400/(dt*60); % numero di istanti da considerare nel DoY
            x_brdm_plus_HAS = zeros(n,1);
            y_brdm_plus_HAS = zeros(n,1);
            z_brdm_plus_HAS = zeros(n,1);
            dc_brdm_plus_HAS = zeros(n,1);
            x_brdm_m = zeros(n,1);
            y_brdm_m = zeros(n,1);
            z_brdm_m = zeros(n,1);
            x_brdm_m_OS = zeros(n,1);
            y_brdm_m_OS = zeros(n,1);
            z_brdm_m_OS = zeros(n,1);
            x_brdm_m_OS_CoM = zeros(n,1);
            y_brdm_m_OS_CoM = zeros(n,1);
            z_brdm_m_OS_CoM = zeros(n,1);
            r_brdm_m = zeros(n,1);
            t_brdm_m = zeros(n,1);
            w_brdm_m = zeros(n,1);
            r_brdm_m_OS_CoM = zeros(n,1);
            t_brdm_m_OS_CoM = zeros(n,1);
            w_brdm_m_OS_CoM = zeros(n,1);
            dc_brdm_m = zeros(n,1);
            dc_brdm_m_OS = zeros(n,1);
            x_sp3_m = zeros(n,1);
            y_sp3_m = zeros(n,1);
            z_sp3_m = zeros(n,1);
            r_sp3_m = zeros(n,1);
            t_sp3_m = zeros(n,1);
            w_sp3_m = zeros(n,1);
            dc_sp3_m = zeros(n,1);
            x_brdm_plus_HAS_sp3 = zeros(n,1);
            y_brdm_plus_HAS_sp3 = zeros(n,1);
            z_brdm_plus_HAS_sp3 = zeros(n,1);
            dc_brdm_plus_HAS_sp3 = zeros(n,1);
            sp3_brdm_r = zeros(n,1);
            sp3_brdm_t = zeros(n,1);
            sp3_brdm_w = zeros(n,1);
            sp3_brdm_dc = zeros(n,1);
            ToW_v = zeros(n,1);
            diff_r = zeros(n,1);
            diff_t = zeros(n,1);
            diff_w = zeros(n,1);
            diff_x = zeros(n,1);
            diff_y = zeros(n,1);
            diff_z = zeros(n,1);
            diff_dc = zeros(n,1);
            corr_r = zeros(n,1);
            corr_t = zeros(n,1);
            corr_w = zeros(n,1);
            corr_x = zeros(n,1);
            corr_y = zeros(n,1);
            corr_z = zeros(n,1);
            corr_ra = zeros(n,1);
            corr_ta = zeros(n,1);
            corr_wa = zeros(n,1);
            corr_dc = zeros(n,1);
            corr_dc_t = zeros(n,1);
            ssr_OS = zeros(n,9);
            dtr = zeros(n,1);
            brdm_vet = zeros(n,20);
            gnssIOD_orb = zeros(n,1);
            gnssIOD_clk = zeros(n,1);
            gnssIOD_OS = zeros(n,1);
            controllo_brdm = 0;
            delta_h_HAS = zeros(n,1);
            delta_h_E1_E5b = zeros(n,1);
            delta_h_L1P_L2P = zeros(n,1);
            controllo_OS = zeros(n,1);
            controllo_HAS = zeros(n,1);
            controllo_HAS_clk = zeros(n,1);

            %% CALCOLO BRDM MODALITA OS

            % Effetuo un ciclo for per calcolare le grandezze BRDM sulla
            % base del ToW definito dal file SP3 originale. Ovvero se il
            % file SP3 ha un sampling rate di 5 minuti, definisco ogni
            % istante il ToW e calcolo la posizione orbitale del satellite
            % considerano il blocco di efemerdi in corsi validità.

            % è necessario effettuare un controllo riguardo la validità dei
            % blocchi di efemeridi ovvero se per calcolare le grandezze
            % BRDM OS vengono usati blocchi di efemeridi nel limite di
            % validità --> da Implementare

            % Definisco la table BRDM_table_SAT come selezione della
            % BRDM_table 
            
            clear idata
            idata = find(BRDM_table.SAT == string(SAT_ID_str));
            BRDM_table_SAT = BRDM_table(idata,:); % BRDM_table che contiene tutte le efemeridi broadcast per quel satellite in quel giorno
            
            % Elimino i blocchi di efemeridi del giorno precedente e li
            % riordino per ToE crescente

            clear idata
            idata = find(BRDM_table_SAT.DY == DoM);
            temp = BRDM_table_SAT;
            clear BRDM_table_SAT
            BRDM_table_SAT = temp(idata,:);
            clear temp

            % Riordino secondo TOE crescente

            temp_toe = BRDM_table_SAT.("TOE [s]");
            temp_toe = sort(temp_toe);
            temp = BRDM_table_SAT;
            clear BRDM_table_SAT
            for q = 1:length(temp_toe)
                idata = find(temp.("TOE [s]") == temp_toe(q));
                BRDM_table_SAT(q,:) = temp(idata,:);
            end
            clear temp

            % Estraggo le efemeridi BRDM del SAT del giorno precedente

            clear idata
            idata = find(BRDM_table_i.SAT == string(SAT_ID_str));
            BRDM_table_SAT_i = BRDM_table_i(idata,:); % BRDM_table che contiene tutte le efemeridi broadcast per quel satellite nel giorno precedente

            % Elimino i blocchi di efemeridi del giorno precedente e li
            % riordino per ToE crescente

            DoY_i = DoY-1;
            [DoM_i,MN_i] = DoY_to_DoM(DoY_i); % Calcolo giorno del mese e mese dato il DoY
            [WN_i,DoW_i] = GPS_date (DoM_i,MN_i,YR+2000); % Calcolo della settimana GPS e del 

            clear idata
            idata = find(BRDM_table_SAT_i.DY == DoM_i);
            
            temp = BRDM_table_SAT_i;
            clear BRDM_table_SAT_i
            BRDM_table_SAT_i = temp(idata,:);
            clear temp

            % Riordino secondo TOE crescente

            temp_toe = BRDM_table_SAT_i.("TOE [s]");
            temp_toe = sort(temp_toe);
            temp = BRDM_table_SAT_i;
            clear BRDM_table_SAT_i
            for q = 1:length(temp_toe)
                idata = find(temp.("TOE [s]") == temp_toe(q));
                BRDM_table_SAT_i(q,:) = temp(idata,:);
            end
            clear temp

            % Definisco il TOE di tutti i blocchi di efemeridi

            TOE_v = BRDM_table_SAT.("TOE [s]");

            % Iterazione su tutti gli istanti definiti dal file SP3 
        
            for i = 1:n

                % Definizione del ToW per ogni istante considerato

                ToW = DoW*86400 + dt*60*i-dt*60;
                ToW_v(i) = ToW; % vettore che contiene tutti gli istanti considerati per il satellite

                % Definisco il TOE di tutti i blocchi di efemeridi

                TOE_v = BRDM_table_SAT.("TOE [s]");

                pos_found_brdm = [];

                % Strategia di selezione delle efemeridi broadcast: ogni 2
                % ore è disponibile un nuovo blocco di efemeridi broadcast
                % per GPS. Passate le due ore si considera il nuovo blocco
                % di efemeridi. LA stessa strategia può essere applicata
                % anche a Galileo anche se le efemeridi vengono agggiornate
                % più di frequente

                for b = 2:length(TOE_v)

                    if ToW < TOE_v(b)

                        pos_found_brdm = b-1; % numero della riga della efemeride broadcast selezionata da BRDM_table_SAT
                        break

                    end

                end

                if isempty(pos_found_brdm)

                    pos_found_brdm = b;

                end

                % Controllo se le efemeridi broadcsat sono usate entro il
                % limite di validità di 2 ore, in alcuni casi le correzioni
                % HAS riescono a stare dietro a efemeridi broadcast usate
                % fuori dal limite di validità. Nei casi in cui non ci sono
                % correzioni HAS valide e le efemerifdi broadcast sono
                % usate fuori dal limite di validità, le quantità BRDM OS
                % si discostano molto da SP3. 

                TOE_select = TOE_v(pos_found_brdm);
                diff_TOE = ToW - TOE_select;

                if diff_TOE > 7200

                    controllo_OS(i) = 1; % % se controllo_OS = 1 allora le efemeridi broadcast sono usate fuori dal limite di validità di 2 h. Rilevante nel caso in cui non cis siano HAS valide 

                else

                    controllo_OS(i) = 0;

                end
                
                % Calcolo la posizione del satellite grazie alle efemeridi
                % broadcast all'istante ToW definito dal file SP3
                        
                % CALCOLO POSIZIONE E CLOCK DEL SATELLITE i-esimo CON BRDM
                     
                brdm_block = BRDM_table_SAT(pos_found_brdm,:);
                brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la posizione con becp                            
                [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);
                        
                % Salvo il IODnav o IODE del blocco di efemeridi

                if costellazione == 2
                    gnssIOD_OS(i) = brdm_block.("IODnav [-]");
                elseif costellazione == 0
                    gnssIOD_OS(i) = brdm_block.("IODE [-]");
                end

                % coordinate del satellite i-esimo ottenute con le
                % efemeridi broadcast nel ToW e clock correction us. 

                % CASO IN CUI SI VOGLIANO LE GRANDEZZE BRDM RISETTO AL CoM
                % Sono riferite all'IONO-free APC. Bisogna trasformare in CoM
                                                            
                x_brdm_m_OS(i) = round(x/1000,6); % [km], IF APC
                y_brdm_m_OS(i) = round(y/1000,6); % [km], IF APC
                z_brdm_m_OS(i) = round(z/1000,6); % [km], IF APC
                dc_brdm_m_OS(i) = round((brdm_vet(i,1) + brdm_vet (i,2)*(ToW - brdm_vet(i,12)))*10^6,6); % [us], deriva del clock con BRDM
    
                % Le grandezze OS devono essere trasformate in CoM

                % Calcolo della terna SSR nel cao BRDM OS

                ssr_OS(i,:) = calcSSR_ECEF_mod(ToW, brdm_vet(i,:), mu, omega_e);

                % Calcolo dell'APCO lungo la direzione radial
        
                if costellazione == 2
                
                    apof_radial = (apo(3).up(SAT,1)*f1^2-apo(3).up(SAT,7)*f2^2)/(f1^2-f2^2);
                
                end
            
                if costellazione == 0
                
                    apof_radial = (apo(1).up(SAT,1)*f1^2-apo(1).up(SAT,2)*f2^2)/(f1^2-f2^2);
                
                end

                % calcolo dell ionofree APCO (Antenna Phase Center Offset) tra APC e CoM in
                % direzione in-track e cross-track
            
                eph = brdm_vet(i,:);
                                                
                [apof_in_track,apof_cross_track] = calc_APC2CoM_t_w (costellazione,YR,DoM,MN,ToW,eph,mu,apo,SAT);

                % trasformazione delle posizioni BRDM calcolate da ECEF in TRW 
                                                                   
                r_brdm_m_OS_CoM(i) = ssr_OS(i,1)*x_brdm_m_OS(i)+ ssr_OS(i,2)*y_brdm_m_OS(i) + ssr_OS(i,3)*z_brdm_m_OS(i) + apof_radial/1000; % [km], CoM
                t_brdm_m_OS_CoM(i) = ssr_OS(i,4)*x_brdm_m_OS(i)+ ssr_OS(i,5)*y_brdm_m_OS(i) + ssr_OS(i,6)*z_brdm_m_OS(i) + apof_in_track/1000; % [km], CoM
                w_brdm_m_OS_CoM(i) = ssr_OS(i,7)*x_brdm_m_OS(i)+ ssr_OS(i,8)*y_brdm_m_OS(i) + ssr_OS(i,9)*z_brdm_m_OS(i) + apof_cross_track/1000; % [km], CoM

                % Ora trovo X Y Z di OS rispetto al CoM

                x_brdm_m_OS_CoM(i) = r_brdm_m_OS_CoM(i)*ssr_OS(1,1)+t_brdm_m_OS_CoM(i)*ssr_OS(1,4)+w_brdm_m_OS_CoM(i)*ssr_OS(1,7); % [km], CoM
                y_brdm_m_OS_CoM(i) = r_brdm_m_OS_CoM(i)*ssr_OS(1,2)+t_brdm_m_OS_CoM(i)*ssr_OS(1,5)+w_brdm_m_OS_CoM(i)*ssr_OS(1,8); % [km], CoM 
                z_brdm_m_OS_CoM(i) = r_brdm_m_OS_CoM(i)*ssr_OS(1,3)+t_brdm_m_OS_CoM(i)*ssr_OS(1,6)+w_brdm_m_OS_CoM(i)*ssr_OS(1,9); % [km], CoM

                % Nel file SP3, quando non sono disponibili l correzioni
                % HAS, bisogna mettere le grandezze BRDM APC e non CoM. Le
                % grandezze CoM vanno considerate solo quando c'è il
                % confronto con SP3

            end
       
            %% CALCOLO BRDM+HAS (BRDM in modalià HAS)
            
            % Iterazione su tutti gli istanti definiti dal file SP3, calcolo delle grandezze BRDM+HAS 
        
            for i = 1:n
        
                % Definizione del ToW per ogni istante considerato
    
                ToW = DoW*86400 + dt*60*i-dt*60;
                ToW_v(i) = ToW; % vettore che contiene tutti gli istanti considerati per il satellite
    
                % DATI SP3 NEL ToW
        
                % grandezze SP3 nel ToW

                if costellazione == 0 % GPS

                    x_sp3_m(i) = sp3Sys(1).data(SAT).SP3data(i,2); % [km] 
                    y_sp3_m(i) = sp3Sys(1).data(SAT).SP3data(i,3); % [km]
                    z_sp3_m(i) = sp3Sys(1).data(SAT).SP3data(i,4); % [km]
                    dc_sp3_m(i) = sp3Sys(1).data(SAT).SP3data(i,5); % [us]
    
                end
    
                if costellazione == 2 % Galileo
        
                    x_sp3_m(i) = sp3Sys(3).data(SAT).SP3data(i,2); % [km] 
                    y_sp3_m(i) = sp3Sys(3).data(SAT).SP3data(i,3); % [km]
                    z_sp3_m(i) = sp3Sys(3).data(SAT).SP3data(i,4); % [km]
                    dc_sp3_m(i) = sp3Sys(3).data(SAT).SP3data(i,5); % [us]
    
                end
    
                % Calcolo dell'APCO lungo la direzione radial
        
                if costellazione == 2
                
                    apof_radial = (apo(3).up(SAT,1)*f1^2-apo(3).up(SAT,7)*f2^2)/(f1^2-f2^2);
                
                end
            
                if costellazione == 0
                
                    apof_radial = (apo(1).up(SAT,1)*f1^2-apo(1).up(SAT,2)*f2^2)/(f1^2-f2^2);
                
                end
        
                % Per l'istante in fase di considerazione trovo se ci sono
                % correzioni valide
        
                %% CORREZIONE ORBITALE
        
                % Se la SEPT_table_orb (or ASIA_table_orb) non è vuota allora potrebbero esserci delle
                % correzioni valide per i vari ToW
    
                if ~isempty(HAS_table_orb_DoY) % se HAS_table_orb_DoY è vuoto allora non c'è una correzione HAS orbitale per il satellite in fase di considerazione
    
                    % Ogni record HAS ha una validità a partire dal ToW
                    % della correzione + la validity. Quindi definito il
                    % ToW di cui vogliamo determinare BRDM+HAS,
                    % selezioniamo le correzioni HAS aventi ToW precedente
                    % e nel limite di validità
                    
                    clear a;
                    a = HAS_table_orb.ToW; % seleziono le correzioni HAS valide per quel ToW. Nei primi istanti le correzioni HAS saranno del DoY precedente
                    q_found = [];
                    q_found_i = [];

                    for q = 1:length(a)
    
                        if a(q) > (ToW - HAS_table_orb.validity(q)) && a(q) < ToW % trovo le correzioi HAS valide per quel ToW. Sicuramente saranno correzioi HAS con ToW precdente
           
                            q_found = q;
                            break
           
                        end
    
                    end

                    for q = 1:length(a)
    
                        if a(q) > ToW

                            q_found_i = q-1;
                            break

                        end
    
                    end

                    if ~isempty(q_found)

                        HAS_table_orb_ToW = a(q_found:q_found_i); % ToW delle correzioni HAS che rispettano la validity rispetto al ToW di SP3
        
                        else
    
                        % Se non ci sono correzioni nel limite validity, allora
                        % q_found è vuoto
    
                        HAS_table_orb_ToW = [];

                    end

                    % Se HAS_table_orb_ToW è vuoto allora vuol dire che non ci sono
                    % correzioni HAS valide per quel ToW
        
                    if  ~isempty(HAS_table_orb_ToW) % caso in cui la correzione c'è ma non si sa che valore abbia (NaN o valore numerico o se abbia validità)              

                        % Trovo il valore minimo tra il ToW SP3 considerato e tra tutti i ToW delle correzioni
                        % HAS disponibili per quel giorno che siano nel limite
                        % di validità

                        diff_min = min (ToW - HAS_table_orb_ToW);
        
                        % Trovo la posizione della correzione HAS corrispondente nella
                        % table che contiene tutte le correzioni orbitali per quel giorno
        
                        clear idata
                        idata = find(HAS_table_orb.ToW == (ToW - diff_min));
        
                        pos_found_HAS = (idata);
                
                        % Controllo se la correzione è NaN, in questo caso
                        % cerco se ci sono altre correzioni nel limite di
                        % validità che non siano NaN.

                        HAS_block_orb = HAS_table_orb(pos_found_HAS,:); % blocco che contiene la correzione orbitale selezionata più vicina al ToW SP3. Ora vediamo se è NaN
                        
                        % Caso in cui la correzione selezionata è NaN

                        if isnan(HAS_block_orb.delta_radial)

                            % Allora cerco una correzione nel limite di
                            % validità che sia non NaN. Riduco
                            % HAS_table_orb_ToW a quelle coorrezioni valide
                            % che non sono NaN

                            % Trovo dove le coorezioni orbitali sono not
                            % NaN

                            clear idata idata2
                            idata = find(~isnan(HAS_table_orb.delta_radial));

                            % Trovo l'intervallo nella table HAS_table_orb
                            % dove ci sono le correzioni valide per quel
                            % ToW SP3

                            for q = 1:length(HAS_table_orb_ToW)

                                idata2(q) = find(HAS_table_orb.ToW == HAS_table_orb_ToW(q));

                            end

                            % Trovo le correzioni valide per ToW SP3 che
                            % non siano NaN

                            I = intersect(idata,idata2);

                            if ~isempty(I) % siamo nel caso in cui ci sono correzioni HAS non NaN valide

                                clear HAS_table_orb_ToW
                                HAS_table_orb_ToW = HAS_table_orb.ToW(I(1):I(end)); % questo vettore contiene il ToW delle correzioni HAS valide per quel ToW SP3 non NaN
                                diff_min = min (ToW - HAS_table_orb_ToW);
        
                                % Trovo la posizione della correzione HAS corrispondente nella
                                % table che contiene tutte le correzioni orbitali per quel giorno
                
                                clear idata
                                idata = find(HAS_table_orb.ToW == (ToW - diff_min));
                
                                pos_found_HAS = (idata);
                        
                                % Controllo se la correzione è NaN, in questo caso
                                % cerco se ci sono altre correzioni nel limite di
                                % validità che non siano NaN.
        
                                HAS_block_orb = HAS_table_orb(pos_found_HAS,:); % blocco che contiene la correzione orbitale selezionata più vicina al ToW SP3. Ora vediamo se è NaN
                        
                                % Trovo il gnssIOD della correzione HAS orbitale selezionata
                    
                                gnssIOD_orb(i) = HAS_table_orb.gnssIOD(pos_found_HAS);
                    
                                % SELEZIONE EFEMERIDI BROADCAST
                        
                                % Trovo il blocco di efemeridi broadcast con gnssIOD della
                                % correzione HAS orbitale selezionata, se esiste
                        
                                % trovo la posizione del gnssIOD nella BRDM_table
                        
                                if costellazione == 0 % GPS
                        
                                    pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODE [-]") == gnssIOD_orb(i));
                                    temp_pos_found_brdm = [];
            
                                    % consideriamo il caso in cui ci siano più blocchi
                                    % di efemeridi con lo stesso IODnav
            
                                    if length(pos_found_brdm) > 1
            
                                        % dei due blocchi seleziono quello con ToE
                                        % più vicino al ToW
            
                                        ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                        diff_T_1 = abs(ToE_1 - ToW);
                                        ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                        diff_T_2 = abs(ToE_2 - ToW);
            
                                        if diff_T_1 < diff_T_2
            
                                            temp_pos_found_brdm = pos_found_brdm(1,1);
            
                                        else
            
                                            temp_pos_found_brdm = pos_found_brdm(2,1);
            
                                        end
                                          
                                    end
            
                                    if ~isempty(temp_pos_found_brdm)
            
                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm
            
                                     end
            
                                 end
                        
                                 if costellazione == 2 % Galileo
                    
                                      pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODnav [-]") == gnssIOD_orb(i));
                                      temp_pos_found_brdm = [];
            
                                      if length(pos_found_brdm) > 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav
            
                                          % dei due blocchi seleziono quello con ToE
                                          % più vicino al ToW
            
                                          ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                          diff_T_1 = abs(ToE_1 - ToW);
                                          ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                          diff_T_2 = abs(ToE_2 - ToW);
            
                                          if diff_T_1 < diff_T_2
            
                                              temp_pos_found_brdm = pos_found_brdm(1,1);
            
                                          else
            
                                              temp_pos_found_brdm = pos_found_brdm(2,1);
            
                                          end
                                          
                                      end
            
                                      if ~isempty(temp_pos_found_brdm)
            
                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm
            
                                      end
    
                                      % Ci può essere il caso in cui
                                      % pos_found_brdm sia di lunghezza 1, e
                                      % nel caso in cui il gnss_IOD della
                                      % correzione HAS all'inizio della
                                      % giornata sia riferito a un blocco di
                                      % efemeridi del giorno precedente e ci
                                      % sia un blocco di efemeridi con lo
                                      % stesso gnss_IOD ma non valido per
                                      % quell'istante. In questo caso si cerca
                                      % di confrontare i ToW con il ToE
    
                                      if length(pos_found_brdm) == 1
    
                                          ToE = BRDM_table.("TOE [s]")(pos_found_brdm);
    
                                          if abs(ToW - ToE) > (3600*2)
    
                                              pos_found_brdm = [];
    
                                          end
                                          
                                      end
            
                                 end  
                        
                                 if ~isempty(pos_found_brdm) % se esiste quel blocco di efemeridi
                        
                                    if controllo_brdm == 0
            
                                        brdm_block = BRDM_table(pos_found_brdm,:);
                        
                                    else
            
                                        brdm_block = BRDM_table_i(pos_found_brdm,:);
            
                                    end
            
                                    % Calcolo la posizione del satellite grazie alle efemeridi
                                    % broadcast all'istante ToW definito dal file SP3
                            
                                    % CALCOLO POSIZIONE DEL SATELLITE i-esimo CON BRDM
                                   
                                    addpath 'C:\multiGNSS_v3\mgnssUtil'
                                                    
                                    brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la posizione con becp                            
                                    [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);
                            
                                    % coordinate del satellite i-esimo ottenute con le
                                    % efemeridi broadcast nel ToW
    
                                    x_brdm_m(i) = x/1000; % [km]
                                    y_brdm_m(i) = y/1000; % [km]
                                    z_brdm_m(i) = z/1000; % [km]
                                                                                                 
                                    ssr = calcSSR_ECEF_mod(ToW, brdm_vet(i,:), mu, omega_e);
                                                
                                    % calcolo dell ionofree APCO (Antenna Phase Center Offset) tra APC e CoM in
                                    % direzione in-track e cross-track
            
                                    eph = brdm_vet(i,:);
                                                
                                    [apof_in_track,apof_cross_track] = calc_APC2CoM_t_w (costellazione,YR,DoM,MN,ToW,eph,mu,apo,SAT);
                        
                                    % trasformazione delle posizioni BRDM calcolate da ECEF in TRW 
                                                                   
                                    r_brdm_m(i) = ssr(1,1)*x_brdm_m(i)+ ssr(1,2)*y_brdm_m(i) + ssr(1,3)*z_brdm_m(i) + apof_radial/1000; % [km], CoM
                                    t_brdm_m(i) = ssr(1,4)*x_brdm_m(i)+ ssr(1,5)*y_brdm_m(i) + ssr(1,6)*z_brdm_m(i) + apof_in_track/1000; % [km], CoM
                                    w_brdm_m(i) = ssr(1,7)*x_brdm_m(i)+ ssr(1,8)*y_brdm_m(i) + ssr(1,9)*z_brdm_m(i) + apof_cross_track/1000; % [km], CoM
                                    
                                    % trasformazione grandezze SP3 in rtw
                      
                                    r_sp3_m(i) = ssr(1,1)*x_sp3_m(i)+ ssr(1,2)*y_sp3_m(i) + ssr(1,3)*z_sp3_m(i); % [km], CoM
                                    t_sp3_m(i) = ssr(1,4)*x_sp3_m(i)+ ssr(1,5)*y_sp3_m(i) + ssr(1,6)*z_sp3_m(i); % [km], CoM
                                    w_sp3_m(i) = ssr(1,7)*x_sp3_m(i)+ ssr(1,8)*y_sp3_m(i) + ssr(1,9)*z_sp3_m(i); % [km], CoM
                                
                                    % SP3-BRDM CoM
                                
                                    sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m(i))*10^3; % [m], CoM
                                    sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m(i))*10^3; % [m], CoM 
                                    sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m(i))*10^3; % [m], CoM
                                
                                    % CREAZIONE BRDM+HAS DA SOSTITUIRE A SP3
                                
                                    corr_r(i) = HAS_block_orb.delta_radial+apof_radial; % [m], correzione che comprende anche APCO
                                    corr_ra(i) = HAS_block_orb.delta_radial; % [m], pura correzione
                                    corr_t(i) = HAS_block_orb.delta_in_track+apof_in_track; % [m], correzione che comprende anche APCO
                                    corr_ta(i) = HAS_block_orb.delta_in_track; % [m], pura correzione
                                    corr_w(i) = HAS_block_orb.delta_cross_track+apof_cross_track; % [m], correzione che comprende anche APCO
                                    corr_wa(i) = HAS_block_orb.delta_cross_track; % [m], pura correzione
                                    corr_x(i)  = corr_r(i)*ssr(1,1)+corr_t(i)*ssr(1,4)+corr_w(i)*ssr(1,7); % [m], correzione che comprende anche APCO
                                    corr_y(i)  = corr_r(i)*ssr(1,2)+corr_t(i)*ssr(1,5)+corr_w(i)*ssr(1,8); % [m], correzione che comprende anche APCO
                                    corr_z(i)  = corr_r(i)*ssr(1,3)+corr_t(i)*ssr(1,6)+corr_w(i)*ssr(1,9); % [m], correzione che comprende anche APCO
                                
                                    % SP3-BRDM-HAS CoM
                                
                                    diff_r(i) = sp3_brdm_r(i)-corr_ra(i); % [m], CoM 
                                    diff_t(i) = sp3_brdm_t(i)-corr_ta(i); % [m], CoM
                                    diff_w(i) = sp3_brdm_w(i)-corr_wa(i); % [m], CoM
                                    diff_x(i)  = diff_r(i)*ssr(1,1)+diff_t(i)*ssr(1,4)+diff_w(i)*ssr(1,7); % [m], SP3-BRDM-HAS, CoM
                                    diff_y(i)  = diff_r(i)*ssr(1,2)+diff_t(i)*ssr(1,5)+diff_w(i)*ssr(1,8); % [m], SP3-BRDM-HAS, CoM
                                    diff_z(i)  = diff_r(i)*ssr(1,3)+diff_t(i)*ssr(1,6)+diff_w(i)*ssr(1,9); % [m], SP3-BRDM-HAS, CoM
                                
                                    % BRDM+HAS CoM
                                
                                    x_brdm_plus_HAS(i) = round(x_brdm_m(i) + corr_x(i)/1000,6); % [km], CoM
                                    y_brdm_plus_HAS(i) = round(y_brdm_m(i) + corr_y(i)/1000,6); % [km], CoM
                                    z_brdm_plus_HAS(i) = round(z_brdm_m(i) + corr_z(i)/1000,6); % [km], CoM
                                
                                    % BRDM+HAS-SP3 CoM
                                
                                    x_brdm_plus_HAS_sp3(i) = (x_brdm_plus_HAS(i) - x_sp3_m(i))*10^3; % [m], CoM
                                    y_brdm_plus_HAS_sp3(i) = (y_brdm_plus_HAS(i) - y_sp3_m(i))*10^3; % [m], CoM
                                    z_brdm_plus_HAS_sp3(i) = (z_brdm_plus_HAS(i) - z_sp3_m(i))*10^3; % [m], CoM
    
                                    % file log HAS and OS availability,
                                    % correzioni HAS con valori finiti (0)
                    
                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                               
                                    if costellazione == 0 % GPS
            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
            
                                    end
            
                                    if costellazione == 2 % GPS
            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                               
                                    end
                           
                                    fid_a = fopen(fullfile(filename, name_log), 'a');
            
                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end
    
                                    % Creo il giusto numero di spazi che mi
                                    % registrano il record nel punto giusto
                                    % della tabella
            
                                    msg_log = strcat({'  '},'0,');
                                 
                                    fprintf(fid_a, '%s', msg_log{1,1});
                                    fclose(fid_a);

                                    % Se controllo_HAS = 1, allora BRDM+HAS
                                    % è andato abuon fine ovvero ci sono
                                    % correzioni HAS valide. Potrebbe essere
                                    % che il blocco BRDM sia usato oltre
                                    % il limite di validity ma le correzioni HAS riescono a stargli dietro

                                    controllo_HAS(i) = 1;
    
                                 else
                        
                                    % Caso in cui non ci sia il blocco di efemeridi
                                    % broadcast, in questo caso si mettono i
                                    % valori calcolati con BRDM in modalità OS
                        
                                    % BRDM+HAS CoM
                                
                                    x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                                    y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                                    z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC

                                    % trasformazione grandezze SP3 in rtw
                      
                                    r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                                    t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                                    w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                                
                                    % SP3-BRDM CoM
                                
                                    sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                                    sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                                    sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                                    % SP3 - BRDM

                                    diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                                    diff_t(i) = sp3_brdm_t(i); % [m], CoM
                                    diff_w(i) = sp3_brdm_w(i); % [m], CoM
                                    diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                                    diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                                    diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM
    
                                    % file log HAS and OS availability, blocco di efemeridi non
                                    % esistente (1)
                    
                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                               
                                    if costellazione == 0 % GPS
            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
            
                                    end
            
                                    if costellazione == 2 % GPS
            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                               
                                    end
                           
                                    fid_a = fopen(fullfile(filename, name_log), 'a');
            
                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end
    
                                    % Vediamo se per GPS questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).
    
                                    if costellazione == 0
    
                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente
    
                                        IODE = BRDM_table_SAT_i.("IODE [-]");
    
                                        if gnssIOD_orb(i) == IODE(end) ||gnssIOD_orb(i) == IODE(end-1) || gnssIOD_orb(i) == IODE(end-2) || gnssIOD_orb(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente
    
                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS
                        
                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)
                                        
                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                               
                                            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                                            
                                            fid_a = fopen(fullfile(filename, name_log), 'a');
                               
                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end
                        
                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella
    
                                            msg_log = strcat({'  '},'5,');
    
                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);
    
                                        else
    
                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella
                    
                                            msg_log = strcat({'  '},'1,');
                                         
                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);
    
                                        end
    
                                    end
    
                                    % Vediamo se per Galileo questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).
    
                                    if costellazione == 2
    
                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente
    
                                        IODE = BRDM_table_SAT_i.("IODnav [-]");
    
                                        if gnssIOD_orb(i) == IODE(end) ||gnssIOD_orb(i) == IODE(end-1) || gnssIOD_orb(i) == IODE(end-2) || gnssIOD_orb(i) == IODE(end-3)  % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente
    
                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS
                        
                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)
                                        
                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                               
                                            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                                            
                                            fid_a = fopen(fullfile(filename, name_log), 'a');
                               
                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end
                        
                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella
    
                                            msg_log = strcat({'  '},'5,');
    
                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);
    
                                        else
    
                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella
                    
                                            msg_log = strcat({'  '},'1,');
                                         
                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);
    
                                        end
    
                                    end
         
                                 end
                    
                            else

                                % In questo caso non ci sono correzioni HAS
                                % orbitali valide non NaN

                                % Siamo nel caso in cui una correzione orbitale è NaN, 
                                % in questo caso si lasciano i valori BRDM
                                % in modalità OS
            
                                % BRDM+HAS CoM
                               
                                x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                                y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                                z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC

                                % trasformazione grandezze SP3 in rtw
                      
                                r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                                t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                                w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                                
                                % SP3-BRDM CoM
                                
                                sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                                sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                                sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                                % SP3 - BRDM

                                diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                                diff_t(i) = sp3_brdm_t(i); % [m], CoM
                                diff_w(i) = sp3_brdm_w(i); % [m], CoM
                                diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                                diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                                diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM

                                % file log HAS and OS availability,
                                % correzioni HAS NaN (2)
               
                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                          
                                if costellazione == 0 % GPS
       
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
       
                                end
       
                                if costellazione == 2 % GPS
       
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                          
                                end
                      
                                fid_a = fopen(fullfile(filename, name_log), 'a');
       
                                if fid_a == -1
                                error('Cannot open log file.');
                                end
       
                                msg_log = strcat({'  '},'2,');
                            
                                fprintf(fid_a, '%s', msg_log{1,1});
                                fclose(fid_a);

                            end

                        else % caso in cui la correzione selezionata non è NaN

                            % Trovo il gnssIOD della correzione HAS orbitale selezionata
                       
                            gnssIOD_orb(i) = HAS_table_orb.gnssIOD(pos_found_HAS);
                       
                            % SELEZIONE EFEMERIDI BROADCAST
                           
                            % Trovo il blocco di efemeridi broadcast con gnssIOD della
                            % correzione HAS orbitale selezionata, se esiste
                           
                            % trovo la posizione del gnssIOD nella BRDM_table
                       
                            if costellazione == 0 % GPS
                       
                                pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODE [-]") == gnssIOD_orb(i));
                                temp_pos_found_brdm = [];
           
                                % consideriamo il caso in cui ci siano più blocchi
                                % di efemeridi con lo stesso IODnav
           
                                if length(pos_found_brdm) > 1
           
                                    % dei due blocchi seleziono quello con ToE
                                    % più vicino al ToW
           
                                    ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                    diff_T_1 = abs(ToE_1 - ToW);
                                    ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                    diff_T_2 = abs(ToE_2 - ToW);
           
                                    if diff_T_1 < diff_T_2
           
                                        temp_pos_found_brdm = pos_found_brdm(1,1);
           
                                    else
           
                                        temp_pos_found_brdm = pos_found_brdm(2,1);
           
                                    end
                                      
                                end
           
                                if ~isempty(temp_pos_found_brdm)
           
                                      clear pos_found_brdm
                                      pos_found_brdm = temp_pos_found_brdm;
                                      clear temp_pos_found_brdm
           
                                 end
           
                             end
                       
                             if costellazione == 2 % Galileo
                   
                                  pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODnav [-]") == gnssIOD_orb(i));
                                  temp_pos_found_brdm = [];
           
                                  if length(pos_found_brdm) > 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav
           
                                      % dei due blocchi seleziono quello con ToE
                                      % più vicino al ToW
           
                                      ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                      diff_T_1 = abs(ToE_1 - ToW);
                                      ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                      diff_T_2 = abs(ToE_2 - ToW);
           
                                      if diff_T_1 < diff_T_2
           
                                          temp_pos_found_brdm = pos_found_brdm(1,1);
           
                                      else
           
                                          temp_pos_found_brdm = pos_found_brdm(2,1);
           
                                      end
                                      
                                  end
           
                                  if ~isempty(temp_pos_found_brdm)
           
                                      clear pos_found_brdm
                                      pos_found_brdm = temp_pos_found_brdm;
                                      clear temp_pos_found_brdm
           
                                  end
   
                                  % Ci può essere il caso in cui
                                  % pos_found_brdm sia di lunghezza 1, e
                                  % nel caso in cui il gnss_IOD della
                                  % correzione HAS all'inizio della
                                  % giornata sia riferito a un blocco di
                                  % efemeridi del giorno precedente e ci
                                  % sia un blocco di efemeridi con lo
                                  % stesso gnss_IOD ma non valido per
                                  % quell'istante. In questo caso si cerca
                                  % di confrontare i ToW con il ToE
   
                                  if length(pos_found_brdm) == 1
   
                                      ToE = BRDM_table.("TOE [s]")(pos_found_brdm);
   
                                      if abs(ToW - ToE) > (3600*2)
   
                                          pos_found_brdm = [];
   
                                      end
                                      
                                  end
           
                             end  
                       
                             if ~isempty(pos_found_brdm) % se esiste quel blocco di efemeridi
                       
                                if controllo_brdm == 0
           
                                    brdm_block = BRDM_table(pos_found_brdm,:);
                       
                                else
           
                                    brdm_block = BRDM_table_i(pos_found_brdm,:);
           
                                end
           
                                % Calcolo la posizione del satellite grazie alle efemeridi
                                % broadcast all'istante ToW definito dal file SP3
                           
                                % CALCOLO POSIZIONE DEL SATELLITE i-esimo CON BRDM
                               
                                addpath 'C:\multiGNSS_v3\mgnssUtil'
                                                
                                brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la posizione con becp                            
                                [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);
                           
                                % coordinate del satellite i-esimo ottenute con le
                                % efemeridi broadcast nel ToW
   
                                x_brdm_m(i) = x/1000; % [km]
                                y_brdm_m(i) = y/1000; % [km]
                                z_brdm_m(i) = z/1000; % [km]
                                                                                             
                                ssr = calcSSR_ECEF_mod(ToW, brdm_vet(i,:), mu, omega_e);
                                            
                                % calcolo dell ionofree APCO (Antenna Phase Center Offset) tra APC e CoM in
                                % direzione in-track e cross-track
           
                                eph = brdm_vet(i,:);
                                            
                                [apof_in_track,apof_cross_track] = calc_APC2CoM_t_w (costellazione,YR,DoM,MN,ToW,eph,mu,apo,SAT);
                       
                                % trasformazione delle posizioni BRDM calcolate da ECEF in TRW 
                                                               
                                r_brdm_m(i) = ssr(1,1)*x_brdm_m(i)+ ssr(1,2)*y_brdm_m(i) + ssr(1,3)*z_brdm_m(i) + apof_radial/1000; % [km], CoM
                                t_brdm_m(i) = ssr(1,4)*x_brdm_m(i)+ ssr(1,5)*y_brdm_m(i) + ssr(1,6)*z_brdm_m(i) + apof_in_track/1000; % [km], CoM
                                w_brdm_m(i) = ssr(1,7)*x_brdm_m(i)+ ssr(1,8)*y_brdm_m(i) + ssr(1,9)*z_brdm_m(i) + apof_cross_track/1000; % [km], CoM
                                
                                % trasformazione grandezze SP3 in rtw
                     
                                r_sp3_m(i) = ssr(1,1)*x_sp3_m(i)+ ssr(1,2)*y_sp3_m(i) + ssr(1,3)*z_sp3_m(i); % [km], CoM
                                t_sp3_m(i) = ssr(1,4)*x_sp3_m(i)+ ssr(1,5)*y_sp3_m(i) + ssr(1,6)*z_sp3_m(i); % [km], CoM
                                w_sp3_m(i) = ssr(1,7)*x_sp3_m(i)+ ssr(1,8)*y_sp3_m(i) + ssr(1,9)*z_sp3_m(i); % [km], CoM
                            
                                % SP3-BRDM CoM
                            
                                sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m(i))*10^3; % [m], CoM
                                sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m(i))*10^3; % [m], CoM 
                                sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m(i))*10^3; % [m], CoM
                            
                                % CREAZIONE BRDM+HAS DA SOSTITUIRE A SP3
                            
                                corr_r(i) = HAS_block_orb.delta_radial+apof_radial; % [m], correzione che comprende anche APCO
                                corr_ra(i) = HAS_block_orb.delta_radial; % [m], pura correzione
                                corr_t(i) = HAS_block_orb.delta_in_track+apof_in_track; % [m], correzione che comprende anche APCO
                                corr_ta(i) = HAS_block_orb.delta_in_track; % [m], pura correzione
                                corr_w(i) = HAS_block_orb.delta_cross_track+apof_cross_track; % [m], correzione che comprende anche APCO
                                corr_wa(i) = HAS_block_orb.delta_cross_track; % [m], pura correzione
                                corr_x(i)  = corr_r(i)*ssr(1,1)+corr_t(i)*ssr(1,4)+corr_w(i)*ssr(1,7); % [m], correzione che comprende anche APCO
                                corr_y(i)  = corr_r(i)*ssr(1,2)+corr_t(i)*ssr(1,5)+corr_w(i)*ssr(1,8); % [m], correzione che comprende anche APCO
                                corr_z(i)  = corr_r(i)*ssr(1,3)+corr_t(i)*ssr(1,6)+corr_w(i)*ssr(1,9); % [m], correzione che comprende anche APCO
                            
                                % SP3-BRDM-HAS CoM
                            
                                diff_r(i) = sp3_brdm_r(i)-corr_ra(i); % [m], CoM 
                                diff_t(i) = sp3_brdm_t(i)-corr_ta(i); % [m], CoM
                                diff_w(i) = sp3_brdm_w(i)-corr_wa(i); % [m], CoM
                                diff_x(i)  = diff_r(i)*ssr(1,1)+diff_t(i)*ssr(1,4)+diff_w(i)*ssr(1,7); % [m], SP3-BRDM-HAS, CoM
                                diff_y(i)  = diff_r(i)*ssr(1,2)+diff_t(i)*ssr(1,5)+diff_w(i)*ssr(1,8); % [m], SP3-BRDM-HAS, CoM
                                diff_z(i)  = diff_r(i)*ssr(1,3)+diff_t(i)*ssr(1,6)+diff_w(i)*ssr(1,9); % [m], SP3-BRDM-HAS, CoM
                            
                                % BRDM+HAS CoM
                            
                                x_brdm_plus_HAS(i) = round(x_brdm_m(i) + corr_x(i)/1000,6); % [km], CoM
                                y_brdm_plus_HAS(i) = round(y_brdm_m(i) + corr_y(i)/1000,6); % [km], CoM
                                z_brdm_plus_HAS(i) = round(z_brdm_m(i) + corr_z(i)/1000,6); % [km], CoM
                            
                                % BRDM+HAS-SP3 CoM
                            
                                x_brdm_plus_HAS_sp3(i) = (x_brdm_plus_HAS(i) - x_sp3_m(i))*10^3; % [m], CoM
                                y_brdm_plus_HAS_sp3(i) = (y_brdm_plus_HAS(i) - y_sp3_m(i))*10^3; % [m], CoM
                                z_brdm_plus_HAS_sp3(i) = (z_brdm_plus_HAS(i) - z_sp3_m(i))*10^3; % [m], CoM
   
                                % file log HAS and OS availability,
                                % correzioni HAS con valori finiti (0)
                   
                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                            
                                if costellazione == 0 % GPS
           
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
           
                                end
           
                                if costellazione == 2 % GPS
           
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                            
                                end
                          
                                fid_a = fopen(fullfile(filename, name_log), 'a');
           
                                if fid_a == -1
                                error('Cannot open log file.');
                                end
   
                                % Creo il giusto numero di spazi che mi
                                % registrano il record nel punto giusto
                                % della tabella
           
                                msg_log = strcat({'  '},'0,');
                             
                                fprintf(fid_a, '%s', msg_log{1,1});
                                fclose(fid_a);

                                % Se controllo_HAS = 1, allora BRDM+HAS
                                % è andato abuon fine ovvero ci sono
                                % correzioni HAS valide. Potrebbe essere
                                % che il blocco BRDM sia usato oltre
                                % il limite di validity ma le correzioni HAS riescono a stargli dietro

                                controllo_HAS(i) = 1;
   
                             else
                       
                                % Caso in cui non ci sia il blocco di efemeridi
                                % broadcast, in questo caso si mettono i
                                % valori calcolati con BRDM in modalità OS
                       
                                % BRDM+HAS CoM
                            
                                x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                                y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                                z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC

                                % trasformazione grandezze SP3 in rtw
                      
                                r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                                t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                                w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                               
                                % SP3-BRDM CoM
                               
                                sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                                sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                                sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                                % SP3 - BRDM

                                diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                                diff_t(i) = sp3_brdm_t(i); % [m], CoM
                                diff_w(i) = sp3_brdm_w(i); % [m], CoM
                                diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                                diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                                diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM
   
                                % file log HAS and OS availability, blocco di efemeridi non
                                % esistente (1)
                   
                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                            
                                if costellazione == 0 % GPS
           
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
           
                                end
           
                                if costellazione == 2 % GPS
           
                                    name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                            
                                end
                          
                                fid_a = fopen(fullfile(filename, name_log), 'a');
           
                                if fid_a == -1
                                error('Cannot open log file.');
                                end
   
                                % Vediamo se per GPS questo caso in cui non
                                % esiste il blocco diefemeridi ricade nel
                                % caso in cui il blocco di efemeridi sia
                                % del giorno precedente (5).
   
                                if costellazione == 0
   
                                    % Estraggo l'IODE dei blocchi di
                                    % efemeridi del giorno precedente
   
                                    IODE = BRDM_table_SAT_i.("IODE [-]");
   
                                    if gnssIOD_orb(i) == IODE(end) ||gnssIOD_orb(i) == IODE(end-1) || gnssIOD_orb(i) == IODE(end-2) || gnssIOD_orb(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente
   
                                        % In questo caso, nel file availability viene messo il
                                        % valore 5, si tiene traccia del fatto che il blocco di
                                        % efemeridi BRDM in modalità HAS è del giorno
                                        % precedente. Si considerano i dati BRDM in modalità OS
                       
                                        % file log HAS and OS availability, blocco di efemeridi
                                        % del giorno precedente (5)
                                    
                                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                                        
                                        fid_a = fopen(fullfile(filename, name_log), 'a');
                            
                                        if fid_a == -1
                                        error('Cannot open log file.');
                                        end
                       
                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella
   
                                        msg_log = strcat({'  '},'5,');
   
                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);
   
                                    else
   
                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella
                   
                                        msg_log = strcat({'  '},'1,');
                                     
                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);
   
                                    end
   
                                end
   
                                % Vediamo se per Galileo questo caso in cui non
                                % esiste il blocco diefemeridi ricade nel
                                % caso in cui il blocco di efemeridi sia
                                % del giorno precedente (5).
   
                                if costellazione == 2
   
                                    % Estraggo l'IODE dei blocchi di
                                    % efemeridi del giorno precedente
   
                                    IODE = BRDM_table_SAT_i.("IODnav [-]");
   
                                    if gnssIOD_orb(i) == IODE(end) ||gnssIOD_orb(i) == IODE(end-1) || gnssIOD_orb(i) == IODE(end-2) || gnssIOD_orb(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente
   
                                        % In questo caso, nel file availability viene messo il
                                        % valore 5, si tiene traccia del fatto che il blocco di
                                        % efemeridi BRDM in modalità HAS è del giorno
                                        % precedente. Si considerano i dati BRDM in modalità OS
                       
                                        % file log HAS and OS availability, blocco di efemeridi
                                        % del giorno precedente (5)
                                    
                                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                            
                                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                                        
                                        fid_a = fopen(fullfile(filename, name_log), 'a');
                            
                                        if fid_a == -1
                                        error('Cannot open log file.');
                                        end
                       
                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella
   
                                        msg_log = strcat({'  '},'5,');
   
                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);
   
                                    else
   
                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella
                   
                                        msg_log = strcat({'  '},'1,');
                                     
                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);
   
                                    end
   
                                end
        
                             end

                        end

                    else

                        % Caso in cui non ci sono correzioni orbitali che rispettano il
                        % limite di validità, in questo caso si lasciano i valori BRDM
                        % in modalità OS
           
                        % BRDM+HAS CoM
                       
                        x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                        y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                        z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC 

                        % trasformazione grandezze SP3 in rtw
                      
                        r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                        t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                        w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                        
                        % SP3-BRDM CoM
                        
                        sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                        sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                        sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                        % SP3 - BRDM

                        diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                        diff_t(i) = sp3_brdm_t(i); % [m], CoM
                        diff_w(i) = sp3_brdm_w(i); % [m], CoM
                        diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                        diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                        diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM

                        % file log HAS and OS availability,
                        % correzioni HAS che non rispettano la validity (3)
                  
                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                       
                        if costellazione == 0 % GPS
          
                            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
          
                        end
          
                        if costellazione == 2 % GPS
          
                            name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                       
                        end
                       
                        fid_a = fopen(fullfile(filename, name_log), 'a');
          
                        if fid_a == -1
                        error('Cannot open log file.');
                        end
          
                        msg_log = strcat({'  '},'3,');
                       
                        fprintf(fid_a, '%s', msg_log{1,1});
                        fclose(fid_a);

                    end

                else

                    % Caso in cui non ci sono correzioni valide per il SAT nel
                    % DoY, no record delle correzioni HAS. 
                    % in questo caso si lasciano i valori BRDM in modalità OS
                
                    % BRDM+HAS CoM
                        
                    x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                    y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                    z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC  

                    % trasformazione grandezze SP3 in rtw
                      
                    r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                    t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                    w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                                
                    % SP3-BRDM CoM
                                
                    sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                    sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                    sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                    % SP3 - BRDM

                    diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                    diff_t(i) = sp3_brdm_t(i); % [m], CoM
                    diff_w(i) = sp3_brdm_w(i); % [m], CoM
                    diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                    diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                    diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM

                    % file log HAS and OS availability,
                    % satellite con nessun  record HAS (4)
               
                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                      
                    if costellazione == 0 % GPS
      
                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
      
                    end
      
                    if costellazione == 2 % GPS
      
                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                    
                    end
                    
                    fid_a = fopen(fullfile(filename, name_log), 'a');
      
                    if fid_a == -1
                    error('Cannot open log file.');
                    end
      
                    msg_log = strcat({'  '},'4,');
                    
                    fprintf(fid_a, '%s', msg_log{1,1});
                    fclose(fid_a);

                end

                % Nel caso in cui sp3_brdm_r, t, w il valore sia
                % superiore ai 50 metri allora è stato selezionato
                % il blocco di efemeridi errato (le prime
                % correzioni sono riferite a u blocco di efemeridi
                % del giorno precedente). In questo caso vado a sostituire
                % le grandezze calcolate con BRDM in modalità OS. Funziona
                % nel caso Galileo. Nel caso GPS non si riesce a loggare
                % questo caso. Viene integrato il caso (1) di GPS per le
                % orbite (vedi sopra).
              
                if (abs(sp3_brdm_r(i)) + abs(sp3_brdm_t(i)) + abs(sp3_brdm_w(i)))  > 30 

                    % BRDM+HAS
                        
                    x_brdm_plus_HAS(i) = x_brdm_m_OS(i); % [km], IF APC
                    y_brdm_plus_HAS(i) = y_brdm_m_OS(i); % [km], IF APC
                    z_brdm_plus_HAS(i) = z_brdm_m_OS(i); % [km], IF APC

                    % trasformazione grandezze SP3 in rtw
                    
                    r_sp3_m(i) = ssr_OS(i,1)*x_sp3_m(i)+ ssr_OS(i,2)*y_sp3_m(i) + ssr_OS(i,3)*z_sp3_m(i); % [km], CoM
                    t_sp3_m(i) = ssr_OS(i,4)*x_sp3_m(i)+ ssr_OS(i,5)*y_sp3_m(i) + ssr_OS(i,6)*z_sp3_m(i); % [km], CoM
                    w_sp3_m(i) = ssr_OS(i,7)*x_sp3_m(i)+ ssr_OS(i,8)*y_sp3_m(i) + ssr_OS(i,9)*z_sp3_m(i); % [km], CoM
                    
                    % SP3-BRDM CoM
                    
                    sp3_brdm_r(i) = (r_sp3_m(i) - r_brdm_m_OS_CoM(i))*10^3; % [m], CoM
                    sp3_brdm_t(i) = (t_sp3_m(i) - t_brdm_m_OS_CoM(i))*10^3; % [m], CoM 
                    sp3_brdm_w(i) = (w_sp3_m(i) - w_brdm_m_OS_CoM(i))*10^3; % [m], CoM

                    % SP3 - BRDM

                    diff_r(i) = sp3_brdm_r(i); % [m], CoM 
                    diff_t(i) = sp3_brdm_t(i); % [m], CoM
                    diff_w(i) = sp3_brdm_w(i); % [m], CoM
                    diff_x(i)  = diff_r(i)*ssr_OS(i,1)+diff_t(i)*ssr_OS(i,4)+diff_w(i)*ssr_OS(i,7); % [m], SP3-BRDM, CoM
                    diff_y(i)  = diff_r(i)*ssr_OS(i,2)+diff_t(i)*ssr_OS(i,5)+diff_w(i)*ssr_OS(i,8); % [m], SP3-BRDM, CoM
                    diff_z(i)  = diff_r(i)*ssr_OS(i,3)+diff_t(i)*ssr_OS(i,6)+diff_w(i)*ssr_OS(i,9); % [m], SP3-BRDM, CoM
                
                end

                % Se controllo_OS(i) = 1 e controllo_HAS(i) = 0, allora al
                % posto di BRDM+HAS è stato messo BRDM OS calcolato fuori
                % dal limite di validity

                if controllo_OS(i) == 1 && controllo_HAS(i) == 0

                    % in questo caso le grandezze OS sono calcolate non rispettando la validity del blocco OS BRDM
    
                    % Lasciamo i dati SP3 CNES
                    % BRDM+HAS CoM
                
                    x_brdm_plus_HAS(i) = x_sp3_m(i); % [km], CoM
                    y_brdm_plus_HAS(i) = y_sp3_m(i); % [km], CoM
                    z_brdm_plus_HAS(i) = z_sp3_m(i); % [km], CoM
       
                    % trasformazione grandezze SP3 in rtw
                
                    r_sp3_m(i) = 0;
                    t_sp3_m(i) = 0;
                    w_sp3_m(i) = 0; 
                    
                    % SP3-BRDM CoM
                    
                    sp3_brdm_r(i) = 0;
                    sp3_brdm_t(i) = 0;
                    sp3_brdm_w(i) = 0;
       
                    % SP3 - BRDM
       
                    diff_r(i) = 0;
                    diff_t(i) = 0;
                    diff_w(i) = 0;
                    diff_x(i)  = 0;
                    diff_y(i)  = 0;
                    diff_z(i)  = 0;
           
                    % file log HAS and OS availability,
                    % blocco di efemeridi OS usato
                    % oltre il limite di validità. Si
                    % lasciano i dati SP3 originali (6)
                    
                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                    
                    if costellazione == 0 % GPS
                   
                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                   
                    end
                   
                    if costellazione == 2 % GPS
                   
                        name_log = strcat('ORBITAL_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                    
                    end
                    
                    fid_a = fopen(fullfile(filename, name_log), 'a');
                   
                    if fid_a == -1
                    error('Cannot open log file.');
                    end

                    msg_log = strcat({'  '},'6,');
                    
                    fprintf(fid_a, '%s', msg_log{1,1});
                    fclose(fid_a);

                    % Sostituisco a 3,  6 --> 6
                    fid_a = fopen(fullfile(filename, name_log), 'r');
                    f = fread(fid_a,'*char')';
                    fclose(fid_a);
                    f = strrep(f,'3,  6','6');
                    fid_a  = fopen(fullfile(filename, name_log), 'w');
                    fprintf(fid_a,'%s',f);
                    fclose(fid_a);

                end

                %% CORREZIONE DEL CLOCK
        
                % Seleziono le correzioni del satellite i-esimo della costellazione
                % considerata
        
                if ~isempty(HAS_table_clk_DoY) % se HAS_table_clk_DoY è vuoto allora non c'è una correzione HAS orbitale per il satellite in fase di considerazione
        
                    % Per determinare BRDM+HAS del clock è necessario implementare la [48]
                    % e la [100] del file: PFN-MEMO-232-3889-CNES_Galileo_HAS_clock_error_computation_method_v1_4    
            
                    if costellazione == 0 % GPS, calcolo del termine aggiuntivo della [100]
        
                        % Signal INDEX 9
        
                        HAS_code_bias_signal_index_9_pos = find(HAS_table_code_bias.signal == 9);
                        HAS_table_code_bias_signal_index_9 = HAS_table_code_bias(HAS_code_bias_signal_index_9_pos,:); % table con i code bias con signal index 9
                        
                        % Trovo la correzione di code bias più vicina al Tow in
                        % considerazione
        
                        diff_min = min (abs(ToW - HAS_table_code_bias_signal_index_9.ToW));
                        idata_9 = [];
                        idata_9 = find(HAS_table_code_bias_signal_index_9.ToW == ToW+diff_min);
        
                        if isempty(idata_9)
        
                            idata_9 = find(HAS_table_code_bias_signal_index_9.ToW == ToW-diff_min);
                        
                        end
        
                        HAS_block_code_bias_signal_index_9 = HAS_table_code_bias_signal_index_9 (idata_9,:);
                        HAS_block_code_bias_signal_index_9_ns = (HAS_block_code_bias_signal_index_9.code_bias/clite)*10^9;
        
                        % Signal INDEX 0
        
                        HAS_code_bias_signal_index_0_pos = find(HAS_table_code_bias.signal == 0);
                        HAS_table_code_bias_signal_index_0 = HAS_table_code_bias(HAS_code_bias_signal_index_0_pos,:); % table con i code bias con signal index 9
                        
                        % Trovo la correzione di code bias più vicina al Tow in
                        % considerazione
        
                        diff_min = min (abs(ToW - HAS_table_code_bias_signal_index_0.ToW));
                        idata_0 = [];
                        idata_0 = find(HAS_table_code_bias_signal_index_0.ToW == ToW+diff_min);
        
                        if isempty(idata_0)
        
                            idata_0 = find(HAS_table_code_bias_signal_index_0.ToW == ToW-diff_min);
                        
                        end
        
                        HAS_block_code_bias_signal_index_0 = HAS_table_code_bias_signal_index_0 (idata_0,:);
                        HAS_block_code_bias_signal_index_0_ns = (HAS_block_code_bias_signal_index_0.code_bias/clite)*10^9;
        
                        gamma = f1^2/f2^2;
        
                        % Implementazione della [100], calcolo dell'ultimo membro
        
                        agg = (HAS_block_code_bias_signal_index_9_ns - gamma*(HAS_block_code_bias_signal_index_0_ns + str2double(DCB)))/(gamma-1); % [ns]
                        
                    end
        
                    if costellazione == 2 % Galileo
        
                        % Signal INDEX 1
        
                        HAS_code_bias_signal_index_1_pos = find(HAS_table_code_bias.signal == 1);
                        HAS_table_code_bias_signal_index_1 = HAS_table_code_bias(HAS_code_bias_signal_index_1_pos,:); % table con i code bias con signal index 1
                        
                        % Trovo la correzione di code bias più vicina al Tow in
                        % considerazione
        
                        diff_min = min (abs(ToW - HAS_table_code_bias_signal_index_1.ToW));
                        idata_1 = [];
                        idata_1 = find(HAS_table_code_bias_signal_index_1.ToW == ToW+diff_min);
        
                        if isempty(idata_1)
        
                            idata_1 = find(HAS_table_code_bias_signal_index_1.ToW == ToW-diff_min);
                        
                        end
        
                        HAS_block_code_bias_signal_index_1 = HAS_table_code_bias_signal_index_1 (idata_1,:);
                        HAS_block_code_bias_signal_index_1_ns = (HAS_block_code_bias_signal_index_1.code_bias/clite)*10^9;
        
                        % Signal INDEX 7
        
                        HAS_code_bias_signal_index_7_pos = find(HAS_table_code_bias.signal == 7);
                        HAS_table_code_bias_signal_index_7 = HAS_table_code_bias(HAS_code_bias_signal_index_7_pos,:); % table con i code bias con signal index 7
                        
                        % Trovo la correzione di code bias più vicina al Tow in
                        % considerazione
        
                        diff_min = min (abs(ToW - HAS_table_code_bias_signal_index_7.ToW));
                        idata_7 = [];
                        idata_7 = find(HAS_table_code_bias_signal_index_7.ToW == ToW+diff_min);
        
                        if isempty(idata_7)
        
                            idata_7 = find(HAS_table_code_bias_signal_index_7.ToW == ToW-diff_min);
                        
                        end
        
                        HAS_block_code_bias_signal_index_7 = HAS_table_code_bias_signal_index_7 (idata_7,:);
                        HAS_block_code_bias_signal_index_7_ns = (HAS_block_code_bias_signal_index_7.code_bias/clite)*10^9;
        
                        gamma = f1^2/f2^2;
        
                        % Implementazione della [48], calcolo dell'ultimo membro
        
                        agg = (HAS_block_code_bias_signal_index_7_ns - gamma*(HAS_block_code_bias_signal_index_1_ns ))/(gamma-1); % [ns]
        
                    end
    
                    % Ogni record HAS ha una validità a partire dal ToW
                    % della correzione + la validity. Quindi definito il
                    % ToW di cui vogliamo determinare BRDM+HAS,
                    % selezioniamo le correzioni HAS aventi ToW precedente
                    % e nel limite di validità
                    
                    clear a;
                    a = HAS_table_clk.ToW; % seleziono le correzioni HAS valide per quel ToW. Nei primi istanti le correzioni HAS saranno del DoY precedente
                    q_found = [];
                    q_found_i = [];

                    for q = 1:length(a)
    
                        if a(q) > (ToW - HAS_table_clk.validity(q)) && a(q) < ToW % trovo le correzioi HAS valide per quel ToW. Sicuramente saranno correzioi HAS con ToW precdente
           
                            q_found = q;
                            break
           
                        end
    
                    end

                    for q = 1:length(a)
    
                        if a(q) > ToW

                            q_found_i = q-1;
                            break

                        end
    
                    end

                    if ~isempty(q_found)

                        HAS_table_clk_ToW = a(q_found:q_found_i); % ToW delle correzioni HAS che rispettano la validity rispetto al ToW di SP3
        
                        else
    
                        % Se non ci sono correzioni nel limite validity, allora
                        % q_found è vuoto
    
                        HAS_table_clk_ToW = [];

                    end

                    % Se HAS_table_orb_ToW è vuoto allora vuol dire che non ci sono
                    % correzioni HAS valide per quel ToW

                    if  ~isempty(HAS_table_clk_ToW) % caso in cui la correzione c'è ma non si sa che valore abbia (NaN o valore numerico o se abbia validità)              

                    % Trovo il valore minimo tra il ToW SP3 considerato e tra tutti i ToW delle correzioni
                    % HAS disponibili per quel giorno che siano nel limite
                    % di validità

                        diff_min = min (ToW - HAS_table_clk_ToW);

                        % Trovo la posizione della correzione HAS corrispondente nella
                        % table che contiene tutte le correzioni orbitali per quel giorno

                        clear idata
                        idata = find(HAS_table_clk.ToW == (ToW - diff_min));

                        pos_found_HAS = (idata);

                        % Controllo se la correzione è NaN, in questo caso
                        % cerco se ci sono altre correzioni nel limite di
                        % validità che non siano NaN.

                        HAS_block_clk = HAS_table_clk(pos_found_HAS,:); % blocco che contiene la correzione orbitale selezionata più vicina al ToW SP3. Ora vediamo se è NaN

                        % Caso in cui la correzione selezionata è NaN e lo
                        % status è diverso da 1

                        if isnan(HAS_block_clk.delta_clock_c0) && HAS_block_clk.status ~= 1

                            % Allora cerco una correzione nel limite di
                            % validità che sia non NaN. Riduco
                            % HAS_table_clk_ToW a quelle coorrezioni valide
                            % che non sono NaN

                            % Trovo dove le coorezioni del clock che sono not
                            % NaN

                            clear idata idata2

                            idata = find(~isnan(HAS_block_clk.delta_clock_c0));

                            % Trovo l'intervallo nella table HAS_table_clk
                            % dove ci sono le correzioni valide per quel
                            % ToW SP3

                            for q = 1:length(HAS_table_clk_ToW)

                                idata2(q) = find(HAS_table_clk.ToW == HAS_table_clk_ToW(q));

                            end

                            % Trovo le correzioni valide per ToW SP3 che
                            % non siano NaN

                            I = intersect(idata,idata2);

                            if ~isempty(I) % siamo nel caso in cui ci sono correzioni HAS non NaN valide

                                clear HAS_table_clk_ToW
                                HAS_table_clk_ToW = HAS_table_clk.ToW(I(1):I(end)); % questo vettore contiene il ToW delle correzioni HAS valide per quel ToW SP3 non NaN
                                diff_min = min (ToW - HAS_table_clk_ToW);

                                % Trovo la posizione della correzione HAS corrispondente nella
                                % table che contiene tutte le correzioni del clock per quel giorno

                                clear idata
                                idata = find(HAS_table_clk.ToW == (ToW - diff_min));

                                pos_found_HAS = (idata);

                                % Controllo se la correzione è NaN, in questo caso
                                % cerco se ci sono altre correzioni nel limite di
                                % validità che non siano NaN.

                                HAS_block_clk = HAS_table_clk(pos_found_HAS,:); % blocco che contiene la correzione orbitale selezionata più vicina al ToW SP3. Ora vediamo se è NaN

                                % Trovo il gnssIOD della correzione HAS orbitale selezionata

                                gnssIOD_clk(i) = HAS_table_clk.gnssIOD(pos_found_HAS);

                                % SELEZIONE EFEMERIDI BROADCAST

                                % Trovo il blocco di efemeridi broadcast con gnssIOD della
                                % correzione HAS orbitale selezionata, se esiste

                                % trovo la posizione del gnssIOD nella BRDM_table

                                if costellazione == 0 % GPS

                                    pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODE [-]") == gnssIOD_clk(i));
                                    temp_pos_found_brdm = [];

                                    % consideriamo il caso in cui ci siano più blocchi
                                    % di efemeridi con lo stesso IODnav

                                    if length(pos_found_brdm) > 1

                                        % dei due blocchi seleziono quello con ToE
                                        % più vicino al ToW

                                        ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                        diff_T_1 = abs(ToE_1 - ToW);
                                        ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                        diff_T_2 = abs(ToE_2 - ToW);

                                        if diff_T_1 < diff_T_2

                                            temp_pos_found_brdm = pos_found_brdm(1,1);

                                        else

                                            temp_pos_found_brdm = pos_found_brdm(2,1);

                                        end

                                    end

                                    if ~isempty(temp_pos_found_brdm)

                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm

                                     end

                                 end

                                 if costellazione == 2 % Galileo

                                      pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODnav [-]") == gnssIOD_clk(i));
                                      temp_pos_found_brdm = [];

                                      if length(pos_found_brdm) > 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                          % dei due blocchi seleziono quello con ToE
                                          % più vicino al ToW

                                          ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                          diff_T_1 = abs(ToE_1 - ToW);
                                          ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                          diff_T_2 = abs(ToE_2 - ToW);

                                          if diff_T_1 < diff_T_2

                                              temp_pos_found_brdm = pos_found_brdm(1,1);

                                          else

                                              temp_pos_found_brdm = pos_found_brdm(2,1);

                                          end

                                      end

                                      if ~isempty(temp_pos_found_brdm)

                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm

                                      end

                                      % Caso in cui ci sia un blocco di
                                      % efeemridi con lo stesso gnss_IOD del
                                      % blocco di efemeridi relativr al giorno
                                      % precednete. Si guarda ToW-ToE

                                      if length(pos_found_brdm) == 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                          ToE = BRDM_table.("TOE [s]")(pos_found_brdm);

                                          if abs(ToW-ToE) > (3600*2)

                                                pos_found_brdm = [];

                                          end

                                      end

                                 end

                                 if ~isempty(pos_found_brdm) % se esiste quel blocco di efemeridi

                                    if controllo_brdm == 0

                                        brdm_block = BRDM_table(pos_found_brdm,:);

                                    else

                                        brdm_block = BRDM_table_i(pos_found_brdm,:);

                                    end

                                    % Calcolo la posizione del satellite grazie alle efemeridi
                                    % broadcast all'istante ToW definito dal file SP3

                                    % CALCOLO DERIVA CLOCK DEL SATELLITE i-esimo CON BRDM

                                    addpath 'C:\multiGNSS_v3\mgnssUtil'

                                    brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la deriva del clock con BRDM

                                    dc_brdm_m(i) = (brdm_vet(i,1) + brdm_vet (i,2)*(ToW - brdm_vet(i,12)))*10^6; % [us], deriva del clock con BRDM

                                    % Calcolo effetto relativitico

                                    [x0, y0, z0] = becp(ToW-0.5, brdm_vet(i,:), mu, omega_e);
                                    [x1, y1, z1] = becp(ToW+0.5, brdm_vet(i,:), mu, omega_e); 
                                    [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);

                                    xdot = (x1-x0); % [m/s]
                                    ydot = (y1-y0); % [m/s]
                                    zdot = (z1-z0); % [m/s]

                                    dtr(i) = (-2*(x*xdot + y*ydot + z*zdot)/(clite^2))*10^6; % [us]

                                    % SP3-BRDM

                                    sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m(i))*10^3; % [ns]

                                    % CREAZIONE BRDM+HAS DA SOSTITUIRE A SP3

                                    corr_dc(i) = HAS_block_clk.delta_clock_c0*HAS_block_clk.multiplier; % [m]
                                    corr_dc_t(i) = (corr_dc(i)/clite)*10^9; % [ns]

                                    % BRDM+HAS

                                    dc_brdm_plus_HAS(i) = round(dc_brdm_m(i) + corr_dc_t(i)/1000 - (agg/1000)*controllo,6); % [us], se controllo = 0 allora non cosiderare il termine aggiuntivo nella [100] e [48] per il calcolo di BRDM+HAS del clock

                                    % file log HAS and OS availability,
                                    % correzioni HAS con valori finiti (0)

                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                    if costellazione == 0 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                    end

                                    if costellazione == 2 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                    end

                                    fid_a = fopen(fullfile(filename, name_log), 'a');

                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end

                                    % Creo il giusto numero di spazi che mi
                                    % registrano il record nel punto giusto
                                    % della tabella

                                    msg_log = strcat({'  '},'0,');

                                    fprintf(fid_a, '%s', msg_log{1,1});
                                    fclose(fid_a);

                                    % Calcolo clock adjustement HAS

                                    delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns], [68] meno clock adjustement e DCB e [105]

                                    % Calcolo clock adjustement OS

                                    if costellazione == 2

                                        delta_h_E1_E5b(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    if costellazione == 0

                                        delta_h_L1P_L2P(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    % BRDM+HAS-SP3

                                    if costellazione == 0 % GPS

                                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us], implementazione della [105]

                                    end

                                    if costellazione == 2 % Galileo

                                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) + (str2double(DCB_E1_E5a)/(1-(f1^2/f3^2)))/1000 - (str2double(DCB_E1_E5b)/(1-(f1^2/f2^2)))/1000 - dc_sp3_m(i); % [us], implementazione della [68] meno clock_adjustment

                                    end

                                    % SP3-BRDM-HAS

                                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo

                                    % controllo in cui il clock SP3 sia 999999.999999

                                    if abs(diff_dc(i)) > 10000

                                        diff_dc(i) = 0;
                                        delta_h_HAS(i) = 0;

                                        if costellazione == 2

                                            delta_h_E1_E5b(i) = 0;

                                        end

                                        if costellazione == 0

                                            delta_h_L1P_L2P (i) = 0;

                                        end

                                    end

                                    % Se controllo_HAS_clk = 1, allora BRDM+HAS
                                    % è andato abuon fine ovvero ci sono
                                    % correzioni HAS valide. Potrebbe essere
                                    % che il blocco BRDM sia usato oltre
                                    % il limite di validity ma le correzioni HAS riescono a stargli dietro

                                    controllo_HAS_clk(i) = 1;

                                 else

                                    % Caso in cui non ci sia il blocco di efemeridi
                                    % broadcast, in questo caso si lasciano i valori BRDM in modalità OS

                                    % BRDM+HAS

                                    dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us]

                                    % Calcolo clock adjustement HAS

                                    delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                                    % SP3-BRDM

                                    sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                                    % BRDM+HAS-SP3

                                    dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                                    % Calcolo clock adjustement OS

                                    if costellazione == 2

                                        delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    if costellazione == 0

                                        delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]

                                    end

                                    % SP3-BRDM-HAS

                                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo

                                    % controllo in cui il clock SP3 sia 999999.999999

                                    if abs(diff_dc(i)) > 10000

                                        diff_dc(i) = 0;
                                        delta_h_HAS(i) = 0;

                                        if costellazione == 2

                                            delta_h_E1_E5b(i) = 0;

                                        end

                                        if costellazione == 0

                                            delta_h_L1P_L2P (i) = 0;

                                        end

                                    end
                                    
                                    % file log HAS and OS availability, blocco di efemeridi non
                                    % esistente (1)

                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                    if costellazione == 0 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                    end

                                    if costellazione == 2 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                    end

                                    fid_a = fopen(fullfile(filename, name_log), 'a');

                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end

                                    % Vediamo se per GPS questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).

                                    if costellazione == 0

                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente

                                        IODE = BRDM_table_SAT_i.("IODE [-]");

                                        if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS

                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)

                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                            fid_a = fopen(fullfile(filename, name_log), 'a');

                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'5,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        else

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'1,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        end

                                    end

                                    % Vediamo se per Galileo questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).

                                    if costellazione == 2

                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente

                                        IODE = BRDM_table_SAT_i.("IODnav [-]");

                                        if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS

                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)

                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                            fid_a = fopen(fullfile(filename, name_log), 'a');

                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'5,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        else

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'1,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        end

                                    end

                                end

                            else

                                % In questo caso non ci sono correzioni HAS
                                % del clock valide non NaN

                                % Siamo nel caso in cui una correzione clk è NaN, 
                                % in questo caso si lasciano i valori BRDM
                                % in modalità OS

                                % BRDM+HAS

                                dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us]
                               
                                % Calcolo clock adjustement HAS

                                delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                                % SP3-BRDM

                                sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                                % BRDM+HAS-SP3

                                dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                                % Calcolo clock adjustement OS

                                if costellazione == 2

                                    delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                end

                                if costellazione == 0

                                    delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]

                                end

                                % SP3-BRDM-HAS

                                diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                                
                                % controllo in cui il clock SP3 sia 999999.999999

                                if abs(diff_dc(i)) > 10000
                                    diff_dc(i) = 0;
                                    delta_h_HAS(i) = 0;
                                    if costellazione == 2
                                        delta_h_E1_E5b(i) = 0;
                                    end
                                    if costellazione == 0
                                        delta_h_L1P_L2P (i) = 0;
                                    end
                                end

                                 % file log HAS and OS availability,
                                 % correzioni HAS NaN (2)

                                 filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                 if costellazione == 0 % GPS

                                     name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                 end

                                 if costellazione == 2 % GPS

                                     name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                 end

                                 fid_a = fopen(fullfile(filename, name_log), 'a');

                                 if fid_a == -1
                                 error('Cannot open log file.');
                                 end

                                 msg_log = strcat({'  '},'2,');

                                 fprintf(fid_a, '%s', msg_log{1,1});
                                 fclose(fid_a);

                            end

                        elseif ~isnan(HAS_block_clk.delta_clock_c0) && HAS_block_clk.status ~= 1 % caso in cui la correzione selezionata non è NaN e lo status è diverso da 1

                            % Trovo il gnssIOD della correzione HAS orbitale selezionata

                            gnssIOD_clk(i) = HAS_table_clk.gnssIOD(pos_found_HAS);

                            % SELEZIONE EFEMERIDI BROADCAST

                            % Trovo il blocco di efemeridi broadcast con gnssIOD della
                            % correzione HAS orbitale selezionata, se esiste

                            % trovo la posizione del gnssIOD nella BRDM_table

                            if costellazione == 0 % GPS

                                pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODE [-]") == gnssIOD_clk(i));
                                temp_pos_found_brdm = [];

                                % consideriamo il caso in cui ci siano più blocchi
                                % di efemeridi con lo stesso IODnav

                                if length(pos_found_brdm) > 1

                                    % dei due blocchi seleziono quello con ToE
                                    % più vicino al ToW

                                    ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                    diff_T_1 = abs(ToE_1 - ToW);
                                    ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                    diff_T_2 = abs(ToE_2 - ToW);

                                    if diff_T_1 < diff_T_2

                                        temp_pos_found_brdm = pos_found_brdm(1,1);

                                    else

                                        temp_pos_found_brdm = pos_found_brdm(2,1);

                                    end

                                end

                                if ~isempty(temp_pos_found_brdm)

                                      clear pos_found_brdm
                                      pos_found_brdm = temp_pos_found_brdm;
                                      clear temp_pos_found_brdm

                                 end

                             end

                             if costellazione == 2 % Galileo

                                  pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODnav [-]") == gnssIOD_clk(i));
                                  temp_pos_found_brdm = [];

                                  if length(pos_found_brdm) > 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                      % dei due blocchi seleziono quello con ToE
                                      % più vicino al ToW

                                      ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                      diff_T_1 = abs(ToE_1 - ToW);
                                      ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                      diff_T_2 = abs(ToE_2 - ToW);

                                      if diff_T_1 < diff_T_2

                                          temp_pos_found_brdm = pos_found_brdm(1,1);

                                      else

                                          temp_pos_found_brdm = pos_found_brdm(2,1);

                                      end

                                  end

                                  if ~isempty(temp_pos_found_brdm)

                                      clear pos_found_brdm
                                      pos_found_brdm = temp_pos_found_brdm;
                                      clear temp_pos_found_brdm

                                  end

                                  % Caso in cui ci sia un blocco di
                                  % efeemridi con lo stesso gnss_IOD del
                                  % blocco di efemeridi relativr al giorno
                                  % precednete. Si guarda ToW-ToE

                                  if length(pos_found_brdm) == 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                      ToE = BRDM_table.("TOE [s]")(pos_found_brdm);

                                      if abs(ToW-ToE) > (3600*2)

                                            pos_found_brdm = [];

                                      end

                                  end

                             end

                             if ~isempty(pos_found_brdm) % se esiste quel blocco di efemeridi

                                if controllo_brdm == 0

                                    brdm_block = BRDM_table(pos_found_brdm,:);

                                else

                                    brdm_block = BRDM_table_i(pos_found_brdm,:);

                                end

                                % Calcolo la posizione del satellite grazie alle efemeridi
                                % broadcast all'istante ToW definito dal file SP3

                                % CALCOLO DERIVA CLOCK DEL SATELLITE i-esimo CON BRDM

                                addpath 'C:\multiGNSS_v3\mgnssUtil'

                                brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la deriva del clock con BRDM

                                dc_brdm_m(i) = (brdm_vet(i,1) + brdm_vet (i,2)*(ToW - brdm_vet(i,12)))*10^6; % [us], deriva del clock con BRDM

                                % Calcolo effetto relativitico

                                [x0, y0, z0] = becp(ToW-0.5, brdm_vet(i,:), mu, omega_e);
                                [x1, y1, z1] = becp(ToW+0.5, brdm_vet(i,:), mu, omega_e); 
                                [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);

                                xdot = (x1-x0); % [m/s]
                                ydot = (y1-y0); % [m/s]
                                zdot = (z1-z0); % [m/s]

                                dtr(i) = (-2*(x*xdot + y*ydot + z*zdot)/(clite^2))*10^6; % [us]

                                % SP3-BRDM

                                sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m(i))*10^3; % [ns]

                                % CREAZIONE BRDM+HAS DA SOSTITUIRE A SP3

                                corr_dc(i) = HAS_block_clk.delta_clock_c0*HAS_block_clk.multiplier; % [m]
                                corr_dc_t(i) = (corr_dc(i)/clite)*10^9; % [ns]

                                % BRDM+HAS

                                dc_brdm_plus_HAS(i) = round(dc_brdm_m(i) + corr_dc_t(i)/1000 - (agg/1000)*controllo,6); % [us], se controllo = 0 allora non cosiderare il termine aggiuntivo nella [100] e [48] per il calcolo di BRDM+HAS del clock

                                % file log HAS and OS availability,
                                % correzioni HAS con valori finiti (0)

                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                if costellazione == 0 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                end

                                if costellazione == 2 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                end

                                fid_a = fopen(fullfile(filename, name_log), 'a');

                                if fid_a == -1
                                error('Cannot open log file.');
                                end

                                % Creo il giusto numero di spazi che mi
                                % registrano il record nel punto giusto
                                % della tabella

                                msg_log = strcat({'  '},'0,');

                                fprintf(fid_a, '%s', msg_log{1,1});
                                fclose(fid_a);

                                % Calcolo clock adjustement HAS

                                delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns], [68] meno clock adjustement e DCB e [105]

                                % Calcolo clock adjustement OS

                                if costellazione == 2

                                    delta_h_E1_E5b(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                end

                                if costellazione == 0

                                    delta_h_L1P_L2P(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                end

                                % BRDM+HAS-SP3

                                if costellazione == 0 % GPS

                                    dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us], implementazione della [105]

                                end

                                if costellazione == 2 % Galileo

                                    dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) + (str2double(DCB_E1_E5a)/(1-(f1^2/f3^2)))/1000 - (str2double(DCB_E1_E5b)/(1-(f1^2/f2^2)))/1000 - dc_sp3_m(i); % [us], implementazione della [68] meno clock_adjustment

                                end

                                % SP3-BRDM-HAS

                                diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo

                                % controllo in cui il clock SP3 sia 999999.999999

                                if abs(diff_dc(i)) > 10000

                                    diff_dc(i) = 0;
                                    delta_h_HAS(i) = 0;

                                    if costellazione == 2

                                        delta_h_E1_E5b(i) = 0;

                                    end

                                    if costellazione == 0

                                        delta_h_L1P_L2P (i) = 0;

                                    end

                                end

                                % Se controllo_HAS_clk = 1, allora BRDM+HAS
                                % è andato abuon fine ovvero ci sono
                                % correzioni HAS valide. Potrebbe essere
                                % che il blocco BRDM sia usato oltre
                                % il limite di validity ma le correzioni HAS riescono a stargli dietro

                                controllo_HAS_clk(i) = 1;

                             else

                                % Caso in cui non ci sia il blocco di efemeridi
                                % broadcast, in questo caso si lasciano i valori BRDM in modalità OS

                                % BRDM+HAS

                                dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us]

                                % Calcolo clock adjustement HAS

                                delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                                % SP3-BRDM

                                sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                                % BRDM+HAS-SP3

                                dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                                % Calcolo clock adjustement OS

                                if costellazione == 2
                                    delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]
                                end
                                if costellazione == 0
                                    delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]
                                end

                                % SP3-BRDM-HAS

                                diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                                
                                % controllo in cui il clock SP3 sia 999999.999999

                                if abs(diff_dc(i)) > 10000
                                    diff_dc(i) = 0;
                                    delta_h_HAS(i) = 0;
                                    if costellazione == 2
                                        delta_h_E1_E5b(i) = 0;
                                    end
                                    if costellazione == 0
                                        delta_h_L1P_L2P (i) = 0;
                                    end
                                end

                                % file log HAS and OS availability, blocco di efemeridi non
                                % esistente (1)

                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                if costellazione == 0 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                end

                                if costellazione == 2 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                end

                                fid_a = fopen(fullfile(filename, name_log), 'a');

                                if fid_a == -1
                                error('Cannot open log file.');
                                end

                                % Vediamo se per GPS questo caso in cui non
                                % esiste il blocco diefemeridi ricade nel
                                % caso in cui il blocco di efemeridi sia
                                % del giorno precedente (5).

                                if costellazione == 0

                                    % Estraggo l'IODE dei blocchi di
                                    % efemeridi del giorno precedente

                                    IODE = BRDM_table_SAT_i.("IODE [-]");

                                    if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                        % In questo caso, nel file availability viene messo il
                                        % valore 5, si tiene traccia del fatto che il blocco di
                                        % efemeridi BRDM in modalità HAS è del giorno
                                        % precedente. Si considerano i dati BRDM in modalità OS

                                        % file log HAS and OS availability, blocco di efemeridi
                                        % del giorno precedente (5)

                                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                        fid_a = fopen(fullfile(filename, name_log), 'a');

                                        if fid_a == -1
                                        error('Cannot open log file.');
                                        end

                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella

                                        msg_log = strcat({'  '},'5,');

                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);

                                    else

                                         % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella

                                        msg_log = strcat({'  '},'1,');

                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);

                                    end

                                end

                                % Vediamo se per Galileo questo caso in cui non
                                % esiste il blocco diefemeridi ricade nel
                                % caso in cui il blocco di efemeridi sia
                                % del giorno precedente (5).

                                if costellazione == 2

                                    % Estraggo l'IODE dei blocchi di
                                    % efemeridi del giorno precedente

                                    IODE = BRDM_table_SAT_i.("IODnav [-]");

                                    if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                        % In questo caso, nel file availability viene messo il
                                        % valore 5, si tiene traccia del fatto che il blocco di
                                        % efemeridi BRDM in modalità HAS è del giorno
                                        % precedente. Si considerano i dati BRDM in modalità OS

                                        % file log HAS and OS availability, blocco di efemeridi
                                        % del giorno precedente (5)

                                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                        fid_a = fopen(fullfile(filename, name_log), 'a');

                                        if fid_a == -1
                                        error('Cannot open log file.');
                                        end

                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella

                                        msg_log = strcat({'  '},'5,');

                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);

                                    else

                                        % Creo il giusto numero di spazi che mi
                                        % registrano il record nel punto giusto
                                        % della tabella

                                        msg_log = strcat({'  '},'1,');

                                        fprintf(fid_a, '%s', msg_log{1,1});
                                        fclose(fid_a);

                                    end

                                end

                             end

                        elseif HAS_block_clk.status == 1 % caso in cui la correzione selezionata ha status = 1

                            % Allora cerco una correzione nel limite di
                            % validità che abbai status diverso da 1. Riduco
                            % HAS_table_clk_ToW a quelle coorrezioni valide
                            % che non sono status = 1

                            % Trovo dove le coorezioni del clock che sono not
                            % status = 1

                            clear idata idata2
                            idata = find(HAS_table_clk.status ~= 1);

                            % Trovo l'intervallo nella table HAS_table_clk
                            % dove ci sono le correzioni valide per quel
                            % ToW SP3

                            for q = 1:length(HAS_table_clk_ToW)

                                idata2(q) = find(HAS_table_clk.ToW == HAS_table_clk_ToW(q));

                            end

                            % Trovo le correzioni valide per ToW SP3 che
                            % non siano status = 1

                            I = intersect(idata,idata2);

                            if ~isempty(I) % siamo nel caso in cui ci sono correzioni HAS non status = 1 valide

                                clear HAS_table_clk_ToW
                                HAS_table_clk_ToW = HAS_table_clk.ToW(I(1):I(end)); % questo vettore contiene il ToW delle correzioni HAS valide per quel ToW SP3 non status = 1
                                diff_min = min (ToW - HAS_table_clk_ToW);

                                % Trovo la posizione della correzione HAS corrispondente nella
                                % table che contiene tutte le correzioni del clock per quel giorno

                                clear idata
                                idata = find(HAS_table_clk.ToW == (ToW - diff_min));

                                pos_found_HAS = (idata);

                                HAS_block_clk = HAS_table_clk(pos_found_HAS,:); % blocco che contiene la correzione orbitale selezionata più vicina al ToW SP3.

                                % Trovo il gnssIOD della correzione HAS orbitale selezionata

                                gnssIOD_clk(i) = HAS_table_clk.gnssIOD(pos_found_HAS);

                                % SELEZIONE EFEMERIDI BROADCAST

                                % Trovo il blocco di efemeridi broadcast con gnssIOD della
                                % correzione HAS orbitale selezionata, se esiste

                                % trovo la posizione del gnssIOD nella BRDM_table

                                if costellazione == 0 % GPS

                                    pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODE [-]") == gnssIOD_clk(i));
                                    temp_pos_found_brdm = [];

                                    % consideriamo il caso in cui ci siano più blocchi
                                    % di efemeridi con lo stesso IODnav

                                    if length(pos_found_brdm) > 1

                                        % dei due blocchi seleziono quello con ToE
                                        % più vicino al ToW

                                        ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                        diff_T_1 = abs(ToE_1 - ToW);
                                        ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                        diff_T_2 = abs(ToE_2 - ToW);

                                        if diff_T_1 < diff_T_2

                                            temp_pos_found_brdm = pos_found_brdm(1,1);

                                        else

                                            temp_pos_found_brdm = pos_found_brdm(2,1);

                                        end

                                    end

                                    if ~isempty(temp_pos_found_brdm)

                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm

                                     end

                                 end

                                 if costellazione == 2 % Galileo

                                      pos_found_brdm = find(BRDM_table.SAT == SAT_ID(SAT) & BRDM_table.("IODnav [-]") == gnssIOD_clk(i));
                                      temp_pos_found_brdm = [];

                                      if length(pos_found_brdm) > 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                          % dei due blocchi seleziono quello con ToE
                                          % più vicino al ToW

                                          ToE_1 = BRDM_table.("TOE [s]")(pos_found_brdm(1,1));
                                          diff_T_1 = abs(ToE_1 - ToW);
                                          ToE_2 = BRDM_table.("TOE [s]")(pos_found_brdm(2,1));
                                          diff_T_2 = abs(ToE_2 - ToW);

                                          if diff_T_1 < diff_T_2

                                              temp_pos_found_brdm = pos_found_brdm(1,1);

                                          else

                                              temp_pos_found_brdm = pos_found_brdm(2,1);

                                          end

                                      end

                                      if ~isempty(temp_pos_found_brdm)

                                          clear pos_found_brdm
                                          pos_found_brdm = temp_pos_found_brdm;
                                          clear temp_pos_found_brdm

                                      end

                                      % Caso in cui ci sia un blocco di
                                      % efeemridi con lo stesso gnss_IOD del
                                      % blocco di efemeridi relativr al giorno
                                      % precednete. Si guarda ToW-ToE

                                      if length(pos_found_brdm) == 1 % in Galileo può essere che ci siano due blocchi di efemeridi con lo stesso IODnav

                                          ToE = BRDM_table.("TOE [s]")(pos_found_brdm);

                                          if abs(ToW-ToE) > (3600*2)

                                                pos_found_brdm = [];

                                          end

                                      end

                                 end

                                 if ~isempty(pos_found_brdm) % se esiste quel blocco di efemeridi

                                    if controllo_brdm == 0

                                        brdm_block = BRDM_table(pos_found_brdm,:);

                                    else

                                        brdm_block = BRDM_table_i(pos_found_brdm,:);

                                    end

                                    % Calcolo la posizione del satellite grazie alle efemeridi
                                    % broadcast all'istante ToW definito dal file SP3

                                    % CALCOLO DERIVA CLOCK DEL SATELLITE i-esimo CON BRDM

                                    addpath 'C:\multiGNSS_v3\mgnssUtil'

                                    brdm_vet(i,:) = brdm_block{1,8:27}; % estraggo da brdm_block i dati da utilizzare per calcolare la deriva del clock con BRDM

                                    dc_brdm_m(i) = (brdm_vet(i,1) + brdm_vet (i,2)*(ToW - brdm_vet(i,12)))*10^6; % [us], deriva del clock con BRDM

                                    % Calcolo effetto relativitico

                                    [x0, y0, z0] = becp(ToW-0.5, brdm_vet(i,:), mu, omega_e);
                                    [x1, y1, z1] = becp(ToW+0.5, brdm_vet(i,:), mu, omega_e); 
                                    [x, y, z] = becp(ToW, brdm_vet(i,:), mu, omega_e);

                                    xdot = (x1-x0); % [m/s]
                                    ydot = (y1-y0); % [m/s]
                                    zdot = (z1-z0); % [m/s]

                                    dtr(i) = (-2*(x*xdot + y*ydot + z*zdot)/(clite^2))*10^6; % [us]

                                    % SP3-BRDM

                                    sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m(i))*10^3; % [ns]

                                    % CREAZIONE BRDM+HAS DA SOSTITUIRE A SP3

                                    corr_dc(i) = HAS_block_clk.delta_clock_c0*HAS_block_clk.multiplier; % [m]
                                    corr_dc_t(i) = (corr_dc(i)/clite)*10^9; % [ns]

                                    % BRDM+HAS

                                    dc_brdm_plus_HAS(i) = round(dc_brdm_m(i) + corr_dc_t(i)/1000 - (agg/1000)*controllo,6); % [us], se controllo = 0 allora non cosiderare il termine aggiuntivo nella [100] e [48] per il calcolo di BRDM+HAS del clock

                                    % file log HAS and OS availability,
                                    % correzioni HAS con valori finiti (0)

                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                    if costellazione == 0 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                    end

                                    if costellazione == 2 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                    end

                                    fid_a = fopen(fullfile(filename, name_log), 'a');

                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end

                                    % Creo il giusto numero di spazi che mi
                                    % registrano il record nel punto giusto
                                    % della tabella

                                    msg_log = strcat({'  '},'0,');

                                    fprintf(fid_a, '%s', msg_log{1,1});
                                    fclose(fid_a);

                                    % Calcolo clock adjustement HAS

                                    delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns], [68] meno clock adjustement e DCB e [105]

                                    % Calcolo clock adjustement OS

                                    if costellazione == 2

                                        delta_h_E1_E5b(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    if costellazione == 0

                                        delta_h_L1P_L2P(i) = (dc_brdm_m(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    % BRDM+HAS-SP3

                                    if costellazione == 0 % GPS

                                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us], implementazione della [105]

                                    end

                                    if costellazione == 2 % Galileo

                                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) + (str2double(DCB_E1_E5a)/(1-(f1^2/f3^2)))/1000 - (str2double(DCB_E1_E5b)/(1-(f1^2/f2^2)))/1000 - dc_sp3_m(i); % [us], implementazione della [68] meno clock_adjustment

                                    end

                                    % SP3-BRDM-HAS

                                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo

                                    % controllo in cui il clock SP3 sia 999999.999999

                                    if abs(diff_dc(i)) > 10000

                                        diff_dc(i) = 0;
                                        delta_h_HAS(i) = 0;

                                        if costellazione == 2

                                            delta_h_E1_E5b(i) = 0;

                                        end

                                        if costellazione == 0

                                            delta_h_L1P_L2P (i) = 0;

                                        end

                                    end

                                    % Se controllo_HAS_clk = 1, allora BRDM+HAS
                                    % è andato abuon fine ovvero ci sono
                                    % correzioni HAS valide. Potrebbe essere
                                    % che il blocco BRDM sia usato oltre
                                    % il limite di validity ma le correzioni HAS riescono a stargli dietro
    
                                    controllo_HAS_clk(i) = 1;

                                 else

                                    % Caso in cui non ci sia il blocco di efemeridi
                                    % broadcast, in questo caso si lasciano i valori BRDM in modalità OS

                                    % BRDM+HAS

                                    dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us]

                                    % Calcolo clock adjustement HAS

                                    delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                                    % SP3-BRDM

                                    sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                                    % BRDM+HAS-SP3

                                    dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                                    % Calcolo clock adjustement OS

                                    if costellazione == 2

                                        delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]

                                    end

                                    if costellazione == 0

                                        delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]

                                    end

                                    % SP3-BRDM-HAS

                                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo

                                    % controllo in cui il clock SP3 sia 999999.999999

                                    if abs(diff_dc(i)) > 10000

                                        diff_dc(i) = 0;
                                        delta_h_HAS(i) = 0;

                                        if costellazione == 2

                                            delta_h_E1_E5b(i) = 0;

                                        end

                                        if costellazione == 0

                                            delta_h_L1P_L2P (i) = 0;

                                        end

                                    end

                                    % file log HAS and OS availability, blocco di efemeridi non
                                    % esistente (1)

                                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                    if costellazione == 0 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                    end

                                    if costellazione == 2 % GPS

                                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                    end

                                    fid_a = fopen(fullfile(filename, name_log), 'a');

                                    if fid_a == -1
                                    error('Cannot open log file.');
                                    end

                                    % Vediamo se per GPS questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).

                                    if costellazione == 0

                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente

                                        IODE = BRDM_table_SAT_i.("IODE [-]");

                                        if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS

                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)

                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                            fid_a = fopen(fullfile(filename, name_log), 'a');

                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'5,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        else

                                             % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'1,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        end

                                    end

                                    % Vediamo se per Galileo questo caso in cui non
                                    % esiste il blocco diefemeridi ricade nel
                                    % caso in cui il blocco di efemeridi sia
                                    % del giorno precedente (5).

                                    if costellazione == 2

                                        % Estraggo l'IODE dei blocchi di
                                        % efemeridi del giorno precedente

                                        IODE = BRDM_table_SAT_i.("IODnav [-]");

                                        if gnssIOD_clk(i) == IODE(end) ||gnssIOD_clk(i) == IODE(end-1) || gnssIOD_clk(i) == IODE(end-2) || gnssIOD_clk(i) == IODE(end-3) % se l'IODE del penultimo blocco di efemeridi del giorno precedente corrsiponde al gnssIOD_orb delle correzioni HAS relative ai primi istanti del DoY, allora la correzione HAS fa riferimento ad un blocco di efemeridi del giorno precedente

                                            % In questo caso, nel file availability viene messo il
                                            % valore 5, si tiene traccia del fatto che il blocco di
                                            % efemeridi BRDM in modalità HAS è del giorno
                                            % precedente. Si considerano i dati BRDM in modalità OS

                                            % file log HAS and OS availability, blocco di efemeridi
                                            % del giorno precedente (5)

                                            filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                            fid_a = fopen(fullfile(filename, name_log), 'a');

                                            if fid_a == -1
                                            error('Cannot open log file.');
                                            end

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'5,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        else

                                            % Creo il giusto numero di spazi che mi
                                            % registrano il record nel punto giusto
                                            % della tabella

                                            msg_log = strcat({'  '},'1,');

                                            fprintf(fid_a, '%s', msg_log{1,1});
                                            fclose(fid_a);

                                        end

                                    end

                                end

                            else

                                % In questo caso non ci sono correzioni HAS
                                % del clock valide non status = 1

                                % Siamo nel caso in cui una correzione clk status = 1, 
                                % in questo caso si lasciano i valori BRDM
                                % in modalità OS

                                % BRDM+HAS

                                dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us] 

                                % Calcolo clock adjustement HAS

                                delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                                % SP3-BRDM

                                sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                                % BRDM+HAS-SP3

                                dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                                % Calcolo clock adjustement OS

                                if costellazione == 2
                                    delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]
                                end
                                if costellazione == 0
                                    delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]
                                end

                                % SP3-BRDM-HAS

                                diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                                
                                % controllo in cui il clock SP3 sia 999999.999999

                                if abs(diff_dc(i)) > 10000
                                    diff_dc(i) = 0;
                                    delta_h_HAS(i) = 0;
                                    if costellazione == 2
                                        delta_h_E1_E5b(i) = 0;
                                    end
                                    if costellazione == 0
                                        delta_h_L1P_L2P (i) = 0;
                                    end
                                end

                                 % file log HAS and OS availability,
                                 % satellite status pari a 1 (6)

                                filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                                if costellazione == 0 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                                end

                                if costellazione == 2 % GPS

                                    name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                                end

                                fid_a = fopen(fullfile(filename, name_log), 'a');

                                if fid_a == -1
                                error('Cannot open log file.');
                                end

                                msg_log = strcat({'  '},'6,');

                                fprintf(fid_a, '%s', msg_log{1,1});
                                fclose(fid_a);

                            end

                        end

                    else

                        % Caso in cui non ci sono correzioni clock che rispettano il
                        % limite di validità, in questo caso si lasciano i valori BRDM
                        % in modalità OS

                        % BRDM+HAS

                        dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us]

                        % Calcolo clock adjustement HAS

                        delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                        % SP3-BRDM

                        sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                        % BRDM+HAS-SP3

                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                        % Calcolo clock adjustement OS

                        if costellazione == 2
                            delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]
                        end
                        if costellazione == 0
                            delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]
                        end

                        % SP3-BRDM-HAS

                        diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                        
                        % controllo in cui il clock SP3 sia 999999.999999

                        if abs(diff_dc(i)) > 10000
                            diff_dc(i) = 0;
                            delta_h_HAS(i) = 0;
                            if costellazione == 2
                                delta_h_E1_E5b(i) = 0;
                            end
                            if costellazione == 0
                                delta_h_L1P_L2P (i) = 0;
                            end
                        end

                        % file log HAS and OS availability,
                        % correzioni HAS che non rispettano la validity (3)

                        filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                        if costellazione == 0 % GPS

                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                        end

                        if costellazione == 2 % GPS

                            name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                        end

                        fid_a = fopen(fullfile(filename, name_log), 'a');

                        if fid_a == -1
                        error('Cannot open log file.');
                        end

                        msg_log = strcat({'  '},'3,');

                        fprintf(fid_a, '%s', msg_log{1,1});
                        fclose(fid_a);

                    end

                else

                    % Caso in cui non ci sono correzioni valide per il SAT nel
                    % DoY, no record delle correzioni HAS. 
                    % in questo caso si lasciano i valori BRDM in modalità OS

                    % BRDM+HAS

                    dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us] 

                    % Calcolo clock adjustement HAS

                    delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]
                    
                    % SP3-BRDM

                    sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                    % BRDM+HAS-SP3

                    dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                    % Calcolo clock adjustement OS

                    if costellazione == 2
                        delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]
                    end
                    if costellazione == 0
                        delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]
                    end

                    % SP3-BRDM-HAS

                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                    
                    % controllo in cui il clock SP3 sia 999999.999999

                    if abs(diff_dc(i)) > 10000
                        diff_dc(i) = 0;
                        delta_h_HAS(i) = 0;
                        if costellazione == 2
                            delta_h_E1_E5b(i) = 0;
                        end
                        if costellazione == 0
                            delta_h_L1P_L2P (i) = 0;
                        end
                    end

                    % file log HAS and OS availability,
                    % satellite con nessun  record HAS (4)

                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');

                    if costellazione == 0 % GPS

                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');

                    end

                    if costellazione == 2 % GPS

                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');

                    end

                    fid_a = fopen(fullfile(filename, name_log), 'a');

                    if fid_a == -1
                    error('Cannot open log file.');
                    end

                    msg_log = strcat({'  '},'4,');

                    fprintf(fid_a, '%s', msg_log{1,1});
                    fclose(fid_a);

                end

                % Nel caso in cui ToW - ToE sia maggiore di 50000 allora è 
                % stato selezionato il blocco di efemeridi errato (le prime
                % correzioni sono riferite a un blocco di efemeridi
                % del giorno precedente). In questo caso vado a sostituire
                % le grandezze calcolate con BRDM in modalità OS

                if ~isempty(pos_found_brdm)

                    if  abs(brdm_block.("TOE [s]") - ToW) > 50000

                        % BRDM+HAS

                        dc_brdm_plus_HAS(i) = dc_brdm_m_OS(i); % [us] 

                        % Calcolo clock adjustement HAS

                        delta_h_HAS(i) = (dc_brdm_plus_HAS(i) - dc_sp3_m(i))*10^3; % [ns]

                        % SP3-BRDM

                        sp3_brdm_dc(i) = (dc_sp3_m(i) - dc_brdm_m_OS(i))*10^3; % [ns]

                        % BRDM+HAS-SP3

                        dc_brdm_plus_HAS_sp3(i) = dc_brdm_plus_HAS(i) - dc_sp3_m(i); % [us]

                        % Calcolo clock adjustement OS

                        if costellazione == 2
                            delta_h_E1_E5b(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns], [52]
                        end
                        if costellazione == 0
                            delta_h_L1P_L2P(i) = (dc_brdm_m_OS(i) - dc_sp3_m(i))*10^3; % [ns]
                        end

                        % SP3-BRDM-HAS

                        diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns] grandezza SP3-BRDM-HAS [105] meno clock adjustment per GPS e [68] meno clock adjustment per Galileo
                        
                        % controllo in cui il clock SP3 sia 999999.999999

                        if abs(diff_dc(i)) > 10000
                            diff_dc(i) = 0;
                            delta_h_HAS(i) = 0;
                            if costellazione == 2
                                delta_h_E1_E5b(i) = 0;
                            end
                            if costellazione == 0
                                delta_h_L1P_L2P (i) = 0;
                            end
                        end

                    end

                end

                % Se controllo_OS_clk(i) = 1 e controllo_HAS(i) = 0, allora al
                % posto di BRDM+HAS è stato messo BRDM OS calcolato fuori
                % dal limite di validity

                if controllo_OS(i) == 1 && controllo_HAS_clk(i) == 0

                    % in questo caso le grandezze OS sono calcolate non rispettando la validity del blocco OS BRDM
    
                    % Lasciamo i dati SP3 CNES

                    % BRDM+HAS

                    dc_brdm_plus_HAS(i) = dc_sp3_m(i); % [us] 

                    % Calcolo clock adjustement HAS

                    delta_h_HAS(i) = 0; % [ns]

                    % SP3-BRDM

                    sp3_brdm_dc(i) = 0; % [ns]

                    % BRDM+HAS-SP3

                    dc_brdm_plus_HAS_sp3(i) = 0; % [us]

                    % Calcolo clock adjustement OS

                    if costellazione == 2

                        delta_h_E1_E5b(i) = 0; % [ns]

                    end

                    if costellazione == 0

                        delta_h_L1P_L2P(i) = 0; % [ns]

                    end

                    % SP3-BRDM-HAS

                    diff_dc(i) = - dc_brdm_plus_HAS_sp3(i)*10^3; % [ns]
          
                    % file log HAS and OS availability,
                    % blocco di efemeridi OS usato
                    % oltre il limite di validità. Si
                    % lasciano i dati SP3 originali (7)
                    
                    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\log file');
                    
                    if costellazione == 0 % GPS
                   
                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gps_log_availability.txt');
                   
                    end
                   
                    if costellazione == 2 % GPS
                   
                        name_log = strcat('CLOCK_',out_sp3_abb,num2str(WN),num2str(DoW),'_gal_log_availability.txt');
                    
                    end
                    
                    fid_a = fopen(fullfile(filename, name_log), 'a');
                   
                    if fid_a == -1
                    error('Cannot open log file.');
                    end

                    msg_log = strcat({'  '},'7,');
                    
                    fprintf(fid_a, '%s', msg_log{1,1});
                    fclose(fid_a);

                    % Sostituisco a 3,  7 --> 7
                    fid_a = fopen(fullfile(filename, name_log), 'r');
                    f = fread(fid_a,'*char')';
                    fclose(fid_a);
                    f = strrep(f,'3,  7','7');
                    fid_a  = fopen(fullfile(filename, name_log), 'w');
                    fprintf(fid_a,'%s',f);
                    fclose(fid_a);

                    % Dopo la sfilza di 7, rimande un 3 che in realtà
                    % dovrebbe seere uno 0 --> da correggere

                end

            end
    
            % Matrici contenenti i dati raggruppati
    
            brdm_plus_HAS(:,1) = x_brdm_plus_HAS;
            brdm_plus_HAS(:,2) = y_brdm_plus_HAS;
            brdm_plus_HAS(:,3) = z_brdm_plus_HAS;
            brdm_plus_HAS(:,4) = dc_brdm_plus_HAS;
    
            brdm(:,1) = x_brdm_m;
            brdm(:,2) = y_brdm_m;
            brdm(:,3) = z_brdm_m;
            brdm(:,4) = dc_brdm_m;

            brdm_OS(:,1) = x_brdm_m_OS;
            brdm_OS(:,2) = y_brdm_m_OS;
            brdm_OS(:,3) = z_brdm_m_OS;
            brdm_OS(:,4) = dc_brdm_m_OS;
    
            sp3(:,1) = x_sp3_m;
            sp3(:,2) = y_sp3_m;
            sp3(:,3) = z_sp3_m;
            sp3(:,4) = dc_sp3_m;
        
            %% SOSTITUZIONE DI BRDM+HAS NEL FILE .SP3
    
            % Arrivati a questo punto abbiamo BRDM+HAS per x y z t lunghi
            % (86400/dt*60)
                
            % Sostituzione della posizione e del clock corretti con HAS nel file in
            % formato SP3
        
            if c_overwrite == 1 % in questo caso sovrascrivi nel file SP3 
    
                if costellazione == 2 % Gal
        
                    SAT_ID = ["PE01","PE02","PE03","PE04","PE05","PE06","PE07","PE08","PE09","PE10","PE11","PE12","PE13","PE14","PE15","PE16","PE17","PE18","PE19","PE20","PE21","PE22","PE23","PE24","PE25","PE26","PE27","PE28","PE29","PE30","PE31","PE32","PE33","PE34","PE35","PE36"];
               
                end
        
                if costellazione == 0 % GPS
        
                     SAT_ID = ["PG01","PG02","PG03","PG04","PG05","PG06","PG07","PG08","PG09","PG10","PG11","PG12","PG13","PG14","PG15","PG16","PG17","PG18","PG19","PG20","PG21","PG22","PG23","PG24","PG25","PG26","PG27","PG28","PG29","PG30","PG31","PG32","PG33","PG34","PG35","PG36"];
        
                end
    
                % function per sostituire BRDM+HAS in SP3
            
                overwrite_SP3 (out_sp3_abb,est,SAT_ID,WN,DoW,YR,SAT,x_brdm_plus_HAS,y_brdm_plus_HAS,z_brdm_plus_HAS,dc_brdm_plus_HAS);
        
            end
        
            %% SALVATAGGIO RISULTATI PER SINGOLI SATELLITI
    
            % Una volta calcolate le grandezze per tutti i satelliti si possono
            % salvare e importare per calcolare: clock_adjustment, SISRE e tracciare i grafici
    
            if costellazione == 0  % GPS
    
                comm = strcat('sp3_brdm_r_G',num2str(SAT),' = sp3_brdm_r;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_r_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_r_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_t_G',num2str(SAT),' = sp3_brdm_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_t_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_t_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_w_G',num2str(SAT),' = sp3_brdm_w;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_w_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_w_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_dc_G',num2str(SAT),' = sp3_brdm_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_dc_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_dc_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_ra_G',num2str(SAT),' = corr_ra;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_ra_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_ra_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_ta_G',num2str(SAT),' = corr_ta;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_ta_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_ta_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_wa_G',num2str(SAT),' = corr_wa;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_wa_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_wa_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_dc_t_G',num2str(SAT),' = corr_dc_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_dc_t_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_dc_t_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_dc_G',num2str(SAT),' = corr_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_dc_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_dc_G',num2str(SAT),'")');
                eval(comm);            
                comm = strcat('diff_r_G',num2str(SAT),' = diff_r;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_r_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_r_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_t_G',num2str(SAT),' = diff_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_t_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_t_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_w_G',num2str(SAT),' = diff_w;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_w_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_w_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_x_G',num2str(SAT),' = diff_x;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_x_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_x_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_y_G',num2str(SAT),' = diff_y;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_y_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_y_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_z_G',num2str(SAT),' = diff_z;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_z_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_z_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_dc_G',num2str(SAT),' = diff_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_dc_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_dc_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('x_brdm_plus_HAS_sp3_G',num2str(SAT),' = x_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\x_brdm_plus_HAS_sp3_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"x_brdm_plus_HAS_sp3_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('y_brdm_plus_HAS_sp3_G',num2str(SAT),' = y_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\y_brdm_plus_HAS_sp3_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"y_brdm_plus_HAS_sp3_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('z_brdm_plus_HAS_sp3_G',num2str(SAT),' = z_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\z_brdm_plus_HAS_sp3_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"z_brdm_plus_HAS_sp3_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('dc_brdm_plus_HAS_sp3_G',num2str(SAT),' = dc_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\dc_brdm_plus_HAS_sp3_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"dc_brdm_plus_HAS_sp3_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('x_brdm_plus_HAS_G',num2str(SAT),' = x_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\x_brdm_plus_HAS_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"x_brdm_plus_HAS_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('y_brdm_plus_HAS_G',num2str(SAT),' = y_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\y_brdm_plus_HAS_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"y_brdm_plus_HAS_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('z_brdm_plus_HAS_G',num2str(SAT),' = z_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\z_brdm_plus_HAS_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"z_brdm_plus_HAS_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('dc_brdm_plus_HAS_G',num2str(SAT),' = dc_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\dc_brdm_plus_HAS_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"dc_brdm_plus_HAS_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('delta_h_HAS_G',num2str(SAT),' = delta_h_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\delta_h_HAS_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"delta_h_HAS_G',num2str(SAT),'")');
                eval(comm);
                comm = strcat('delta_h_L1P_L2P_G',num2str(SAT),' = delta_h_L1P_L2P;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\delta_h_L1P_L2P_G",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"delta_h_L1P_L2P_G',num2str(SAT),'")');
                eval(comm);            
    
            end
    
            if costellazione == 2  % GPS
    
                comm = strcat('sp3_brdm_r_E',num2str(SAT),' = sp3_brdm_r;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_r_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_r_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_t_E',num2str(SAT),' = sp3_brdm_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_t_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_t_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_w_E',num2str(SAT),' = sp3_brdm_w;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_w_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_w_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('sp3_brdm_dc_E',num2str(SAT),' = sp3_brdm_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_dc_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"sp3_brdm_dc_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_ra_E',num2str(SAT),' = corr_ra;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_ra_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_ra_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_ta_E',num2str(SAT),' = corr_ta;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_ta_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_ta_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_wa_E',num2str(SAT),' = corr_wa;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_wa_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_wa_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_dc_t_E',num2str(SAT),' = corr_dc_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_dc_t_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_dc_t_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('corr_dc_E',num2str(SAT),' = corr_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_dc_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"corr_dc_E',num2str(SAT),'")');
                eval(comm);  
                comm = strcat('diff_r_E',num2str(SAT),' = diff_r;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_r_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_r_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_t_E',num2str(SAT),' = diff_t;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_t_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_t_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_w_E',num2str(SAT),' = diff_w;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_w_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_w_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_x_E',num2str(SAT),' = diff_x;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_x_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_x_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_y_E',num2str(SAT),' = diff_y;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_y_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_y_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_z_E',num2str(SAT),' = diff_z;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_z_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_z_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('diff_dc_E',num2str(SAT),' = diff_dc;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_dc_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"diff_dc_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('x_brdm_plus_HAS_sp3_E',num2str(SAT),' = x_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\x_brdm_plus_HAS_sp3_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"x_brdm_plus_HAS_sp3_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('y_brdm_plus_HAS_sp3_E',num2str(SAT),' = y_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\y_brdm_plus_HAS_sp3_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"y_brdm_plus_HAS_sp3_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('z_brdm_plus_HAS_sp3_E',num2str(SAT),' = z_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\z_brdm_plus_HAS_sp3_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"z_brdm_plus_HAS_sp3_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('dc_brdm_plus_HAS_sp3_E',num2str(SAT),' = dc_brdm_plus_HAS_sp3;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\dc_brdm_plus_HAS_sp3_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"dc_brdm_plus_HAS_sp3_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('x_brdm_plus_HAS_E',num2str(SAT),' = x_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\x_brdm_plus_HAS_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"x_brdm_plus_HAS_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('y_brdm_plus_HAS_E',num2str(SAT),' = y_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\y_brdm_plus_HAS_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"y_brdm_plus_HAS_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('z_brdm_plus_HAS_E',num2str(SAT),' = z_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\z_brdm_plus_HAS_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"z_brdm_plus_HAS_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('dc_brdm_plus_HAS_E',num2str(SAT),' = dc_brdm_plus_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\dc_brdm_plus_HAS_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"dc_brdm_plus_HAS_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('delta_h_HAS_E',num2str(SAT),' = delta_h_HAS;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\delta_h_HAS_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"delta_h_HAS_E',num2str(SAT),'")');
                eval(comm);
                comm = strcat('delta_h_E1_E5b_E',num2str(SAT),' = delta_h_E1_E5b;');
                eval(comm);
                comm = strcat("path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\delta_h_E1_E5b_E",num2str(SAT),".mat');");
                eval(comm);
                comm = strcat('save(path,"delta_h_E1_E5b_E',num2str(SAT),'")');
                eval(comm);
    
            end
    
           % close(fig)
        
           %% Pulizia del workspace per iterare su k, satelliti della costellazione

           clc
           clearvars -except DoY DoYs controllo c_grafici c_overwrite c_SISRE ...
           AC_abb HAS_abb out_sp3_abb est costellazioni costellazione YR dt brdm_type...
           clite omega_e OBS_L1CA OBS_L1P OBS_E1 OBS_E5b OBS_E5a DoM MN WN DoW...
           v HAS_table_orb_comp HAS_table_code_bias_comp HAS_table_clk_comp sp3Sys...
           DCBSys BRDM_table BRDM_table_i apo ToW_v SAT_disponibili mat mat_i...
           sp3_disp_v sp3_disp f1 f2 f3 mu brdm_type_iniz HAS_table_clk_comp_i...
           HAS_table_orb_comp_i HAS_table_code_bias_comp_i

           if costellazione == 2

                SAT_ID = ["E01","E02","E03","E04","E05","E06","E07","E08","E09","E10","E11","E12","E13","E14","E15","E16","E17","E18","E19","E20","E21","E22","E23","E24","E25","E26","E27","E28","E29","E30","E31","E32","E33","E34","E35","E36"];

           end

           if costellazione == 0

                SAT_ID = ["G01","G02","G03","G04","G05","G06","G07","G08","G09","G10","G11","G12","G13","G14","G15","G16","G17","G18","G19","G20","G21","G22","G23","G24","G25","G26","G27","G28","G29","G30","G31","G32","G33","G34","G35","G36"];

           end
           
        end % fine dei ciclo per iterare sui satelliti disponibili per quella costellazione per quel giorno
    
        %% CALCOLO CLOCK ADJUSTMENT

        if costellazione == 0 % GPS

            B = [];
            B1 = [];

            for cont = 1:length(SAT_disponibili) % carica sp3_brdm per tutti i satelliti GPS

                file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\delta_h_HAS_G',num2str(SAT_disponibili(cont)));
                load(file);
                file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\delta_h_L1P_L2P_G',num2str(SAT_disponibili(cont)));
                load(file);

            end

            for cont = 1:288

                for cont_i = 1:length(SAT_disponibili)

                    comm = strcat('A(cont_i,cont) = delta_h_HAS_G',num2str(SAT_disponibili(cont_i)),'(cont);');
                    eval(comm);
                    comm = strcat('A1(cont_i,cont) = delta_h_L1P_L2P_G',num2str(SAT_disponibili(cont_i)),'(cont);');
                    eval(comm);

                end

            end

            for cont = 1:288

                conta = 1;

                for cont_i = 1:length(SAT_disponibili)

                    if (A(cont_i,cont)) ~= 0

                        B(conta) = A(cont_i,cont);
                        B1(conta) = A1(cont_i,cont);
                        conta = conta+1;

                    end

                end

                if isempty(B)

                        clock_adjusted_GPS_HAS(cont) = 0; % [ns]

                    else

                        clock_adjusted_GPS_HAS(cont) = mean(B); % [ns]

                end

                if isempty(B1)

                        clock_adjusted_GPS_OS(cont) = 0; % [ns]

                    else

                        clock_adjusted_GPS_OS(cont) = mean(B1); % [ns]

                end

            end

            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\clock_adjusted_GPS_HAS.mat');
            save(path,"clock_adjusted_GPS_HAS");
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\clock_adjusted_GPS_OS.mat');
            save(path,"clock_adjusted_GPS_OS");

        end

        if costellazione == 2 % Galileo

            B = [];
            B1 = [];

            for cont = 1:length(SAT_disponibili) % carica sp3_brdm per tutti i satelliti Galileo

                file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\delta_h_HAS_E',num2str(SAT_disponibili(cont)));
                load(file);
                file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\delta_h_E1_E5b_E',num2str(SAT_disponibili(cont)));
                load(file);

            end

            for cont = 1:288

                for cont_i = 1:length(SAT_disponibili)

                    comm = strcat('A(cont_i,cont) = delta_h_HAS_E',num2str(SAT_disponibili(cont_i)),'(cont);');
                    eval(comm);
                    comm = strcat('A1(cont_i,cont) = delta_h_E1_E5b_E',num2str(SAT_disponibili(cont_i)),'(cont);');
                    eval(comm);

                end

            end

            for cont = 1:288

                conta = 1;

                for cont_i = 1:length(SAT_disponibili)

                    if A(cont_i,cont) ~= 0

                        B(conta) = A(cont_i,cont);
                        B1(conta) = A1(cont_i,cont);
                        conta = conta+1;

                    end

                end

                if isempty(B)

                        clock_adjusted_Galileo_HAS(cont) = 0; % [ns]

                    else

                        clock_adjusted_Galileo_HAS(cont) = mean(B); % [ns]

                end

                if isempty(B1)

                        clock_adjusted_Galileo_OS(cont) = 0; % [ns]

                    else

                        clock_adjusted_Galileo_OS(cont) = mean(B1); % [ns]

                end

            end

            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\clock_adjusted_Galileo_HAS.mat');
            save(path,"clock_adjusted_Galileo_HAS");
            path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\clock_adjusted_Galileo_OS.mat');
            save(path,"clock_adjusted_Galileo_OS");

        end
    
        %% CARICAMENTO DATI PER IL CALCOLO DEL SISRE E TRACCIAMENTO GRAFICI

        % Andiamo a tracciare i grafici per cui abbiamo sia BRDM, HAS che
        % SP3. 

        if c_grafici == 1

            % Andiamo a calcolare il SISRE e tracciare i grafici iterativamente sui
            % SAT_disponibili (HAS, BRDM, SP3)

            for k = 1:length(SAT_disponibili) % tracciamo i grafici per tutti i satelliti disponibili

                SAT = SAT_disponibili(k);

                % una volta calcolate le grandezze per tutti i satelliti e calcolati i
                % clock adjustment allora si possono tracciare i grafici e calcolare i
                % SISRE

                % caricamento dei dati utili per il calcolo del SISRE e per il
                % tracciamento dei grafici

                if costellazione == 0

                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_r_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_t_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_w_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\sp3_brdm_dc_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_ra_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_ta_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_wa_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\corr_dc_t_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_x_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_y_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_z_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_r_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_t_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_w_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\diff_dc_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\x_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\y_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\z_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\dc_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\x_brdm_plus_HAS_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\y_brdm_plus_HAS_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\z_brdm_plus_HAS_G',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\dc_brdm_plus_HAS_G',num2str(SAT_disponibili(k)));
                    load(file);

                    % Cambio nome alle variabili, tolgo la parte nella stringa del
                    % nome che si riferisce allo specifico satellite

                    comm = strcat(' sp3_brdm_r = sp3_brdm_r_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_t = sp3_brdm_t_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_w = sp3_brdm_w_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_dc = sp3_brdm_dc_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_ra = corr_ra_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_ta = corr_ta_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_wa = corr_wa_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_dc_t = corr_dc_t_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_r = diff_r_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_t = diff_t_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_w = diff_w_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_x = diff_x_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_y = diff_y_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_z = diff_z_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_dc = diff_dc_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' x_brdm_plus_HAS_sp3 = x_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' y_brdm_plus_HAS_sp3 = y_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' z_brdm_plus_HAS_sp3 = z_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' dc_brdm_plus_HAS_sp3 = dc_brdm_plus_HAS_sp3_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' x_brdm_plus_HAS = x_brdm_plus_HAS_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' y_brdm_plus_HAS = y_brdm_plus_HAS_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' z_brdm_plus_HAS = z_brdm_plus_HAS_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' dc_brdm_plus_HAS = dc_brdm_plus_HAS_G',num2str(SAT_disponibili(k)),';');
                    eval(comm);

                end

                if costellazione == 2

                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_r_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_t_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_w_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\sp3_brdm_dc_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_ra_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_ta_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_wa_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\corr_dc_t_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_r_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_t_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_w_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_x_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_y_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_z_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\diff_dc_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\x_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\y_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\z_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\dc_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\x_brdm_plus_HAS_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\y_brdm_plus_HAS_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\z_brdm_plus_HAS_E',num2str(SAT_disponibili(k)));
                    load(file);
                    file = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\dc_brdm_plus_HAS_E',num2str(SAT_disponibili(k)));
                    load(file);

                    % Cambio nome alle variabili, tolgo la parte nella stringa del
                    % nome che si riferisce allo specifico satellite

                    comm = strcat(' sp3_brdm_r = sp3_brdm_r_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_t = sp3_brdm_t_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_w = sp3_brdm_w_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' sp3_brdm_dc = sp3_brdm_dc_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_ra = corr_ra_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_ta = corr_ta_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_wa = corr_wa_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' corr_dc_t = corr_dc_t_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_r = diff_r_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_t = diff_t_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_w = diff_w_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_x = diff_x_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_y = diff_y_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_z = diff_z_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' diff_dc = diff_dc_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' x_brdm_plus_HAS_sp3 = x_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' y_brdm_plus_HAS_sp3 = y_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' z_brdm_plus_HAS_sp3 = z_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' dc_brdm_plus_HAS_sp3 = dc_brdm_plus_HAS_sp3_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' x_brdm_plus_HAS = x_brdm_plus_HAS_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' y_brdm_plus_HAS = y_brdm_plus_HAS_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' z_brdm_plus_HAS = z_brdm_plus_HAS_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);
                    comm = strcat(' dc_brdm_plus_HAS = dc_brdm_plus_HAS_E',num2str(SAT_disponibili(k)),';');
                    eval(comm);

                end
    
                % Prima di tracciare i grafici e calcolare il SISRE, sostituiamo ai valori nulli dei
                % vari vettori (o non c'è il blocco di efemeridi, o non c'è la
                % correzione o è NaN o con status = 1) il termine " "

                for i = 1:length(sp3_brdm_r)

                    if sp3_brdm_r(i) == 0
                        sp3_brdm_r(i) = " ";
                    end

                    if sp3_brdm_t(i) == 0
                        sp3_brdm_t(i) = " ";
                    end

                    if sp3_brdm_w(i) == 0
                        sp3_brdm_w(i) = " ";
                    end

                    if sp3_brdm_dc(i) == 0
                        sp3_brdm_dc(i) = " ";
                    end

                    if diff_r(i) == 0
                        diff_r(i) = " ";
                    end

                    if diff_t(i) == 0
                        diff_t(i) = " ";
                    end

                    if diff_w(i) == 0
                        diff_w(i) = " ";
                    end

                    if diff_x(i) == 0
                        diff_x(i) = " ";
                    end

                    if diff_y(i) == 0
                        diff_y(i) = " ";
                    end

                    if diff_z(i) == 0
                        diff_z(i) = " ";
                    end

                    if x_brdm_plus_HAS_sp3(i) == 0
                        x_brdm_plus_HAS_sp3(i) = " ";
                    end

                    if y_brdm_plus_HAS_sp3(i) == 0
                        y_brdm_plus_HAS_sp3(i) = " ";
                    end

                    if z_brdm_plus_HAS_sp3(i) == 0
                        z_brdm_plus_HAS_sp3(i) = " ";
                    end

                    if dc_brdm_plus_HAS_sp3(i) == 0
                        dc_brdm_plus_HAS_sp3(i) = " ";
                    end

                    if diff_dc(i) == 0
                        diff_dc(i) = " ";
                    end

                    if corr_ra(i) == 0
                        corr_ra(i) = " ";
                    end

                    if corr_ta(i) == 0
                        corr_ta(i) = " ";
                    end

                    if corr_wa(i) == 0
                        corr_wa(i) = " ";
                    end

                    if corr_dc_t(i) == 0
                        corr_dc_t(i) = " ";
                    end

                end

                % CALCOLO SISRE

                if c_SISRE == 1

                    % CALCOLO SISRE
                    % orbit and total
                    % diff_r, diff_t, diff_w sono SP3-BRDM-HAS per le orbite

                    vet_cont = isnan(diff_r);
                    vet_cont_dc = isnan(diff_dc); % diff_dc è la [68] Galileo o la [105] GPS meno il clock adjustment
                    new_diff_r = zeros(length(diff_r),1);
                    new_diff_t = zeros(length(diff_r),1);
                    new_diff_w = zeros(length(diff_r),1);
                    new_diff_x = zeros(length(diff_r),1);
                    new_diff_y = zeros(length(diff_r),1);
                    new_diff_z = zeros(length(diff_r),1);
                    new_diff_dc = zeros(length(diff_dc),1);

                    % I vettori diff_r,t,w,dc sono stati modificati con NaN dove prima
                    % c'era il valore nullo (mancanza di blocco di efemeridi broadcast,
                    % correzioni non valide,...)
                    % Consideriamo solo le posizione in cui diff_r, t,w dc sono
                    % contemporaneamente diverse da NaN
                    % Eliminiamo i valori NaN da diff_r,t,w

                    % orbit and clock

                    for i = 1:length(diff_r)

                         if vet_cont(i) == 0 && vet_cont_dc(i) == 0

                             new_diff_r(i) = diff_r(i);
                             new_diff_t(i) = diff_t(i);
                             new_diff_w(i) = diff_w(i);
                             new_diff_x(i) = diff_x(i);
                             new_diff_y(i) = diff_y(i);
                             new_diff_z(i) = diff_z(i);

                             if costellazione == 2

                                 new_diff_dc(i) = diff_dc(i) + clock_adjusted_Galileo_HAS(i); % SP3-BRDM-HAS, aggiunta del clock adjustment [68]

                             end

                             if costellazione == 0

                                 new_diff_dc(i) = diff_dc(i) + clock_adjusted_GPS_HAS(i); % SP3-BRDM-HAS, aggiunta del clock adjustment [105]

                             end

                         else

                             new_diff_r(i) = 0;
                             new_diff_t(i) = 0;
                             new_diff_w(i) = 0;
                             new_diff_dc(i) = 0;

                         end

                    end

                    conta = 1;

                    for i = 1:length(diff_r)

                        if new_diff_r(i) ~= 0

                             new_diff_r_rms(conta) = new_diff_r(i);
                             new_diff_t_rms(conta) = new_diff_t(i);
                             new_diff_w_rms(conta) = new_diff_w(i);
                             new_diff_x_rms(conta) = new_diff_x(i);
                             new_diff_y_rms(conta) = new_diff_y(i);
                             new_diff_z_rms(conta) = new_diff_z(i);
                             new_diff_dc_rms(conta) = new_diff_dc(i);
                             conta = conta+1;

                        end

                    end

                    % Gal   

                    if costellazione == 2

                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_orb_Gal.mat');
                        % load(path,"SISRE_mat_orb_Gal");
                        % 
                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_tot_Gal.mat');
                        % load(path,"SISRE_mat_tot_Gal");

                        % Componimento unico vettore diff_r,t,w,dc per tutti i satelliti del giorno
                        load('C:\multiGNSS_v3\HAS\Risultati\calc_SISRE.mat');

                        temp_diff_r_tutti_SAT_Gal = diff_r_tutti_SAT_Gal;
                        temp_diff_t_tutti_SAT_Gal = diff_t_tutti_SAT_Gal;
                        temp_diff_w_tutti_SAT_Gal = diff_w_tutti_SAT_Gal;
                        temp_diff_dc_tutti_SAT_Gal = diff_dc_tutti_SAT_Gal;

                        clear diff_r_tutti_SAT_Gal diff_t_tutti_SAT_Gal diff_w_tutti_SAT_Gal diff_dc_tutti_SAT_Gal

                        diff_r_tutti_SAT_Gal = horzcat(temp_diff_r_tutti_SAT_Gal,new_diff_r_rms);
                        diff_t_tutti_SAT_Gal = horzcat(temp_diff_t_tutti_SAT_Gal,new_diff_t_rms);
                        diff_w_tutti_SAT_Gal = horzcat(temp_diff_w_tutti_SAT_Gal,new_diff_w_rms);
                        diff_dc_tutti_SAT_Gal = horzcat(temp_diff_dc_tutti_SAT_Gal,new_diff_dc_rms);

                        % SISRE singolo satellite
                        wr = 0.98;
                        wac = (1/61);
                        R = rms(new_diff_r_rms);
                        A = rms(new_diff_t_rms);
                        C = rms(new_diff_w_rms);
                        DC = rms(wr*new_diff_r_rms - new_diff_dc_rms*10^-9*clite); 
                        SISRE_orb_Gal = sqrt((wr^2)*(R^2)+wac*(A^2+C^2));
                        SISRE_tot_Gal = sqrt(DC^2+wac*(A^2+C^2));
                        SISRE_mat_orb_Gal(k,1) = SAT_disponibili(k);
                        SISRE_mat_orb_Gal(k,2) = SISRE_orb_Gal;
                        SISRE_mat_tot_Gal(k,1) = SAT_disponibili(k);
                        SISRE_mat_tot_Gal(k,2) = SISRE_tot_Gal;
                        diff_r_mat_Gal(2:(length(new_diff_r)+1),k) = new_diff_r;
                        diff_t_mat_Gal(2:(length(new_diff_t)+1),k) = new_diff_t;
                        diff_w_mat_Gal(2:(length(new_diff_w)+1),k) = new_diff_w;
                        diff_dc_mat_Gal(2:(length(new_diff_dc)+1),k) = new_diff_dc;

                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_orb_Gal.mat');
                        % save(path,"SISRE_mat_orb_Gal");
                        % 
                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_tot_Gal.mat');
                        % save(path,"SISRE_mat_tot_Gal");

                    end

                    % GPS

                    if costellazione == 0

                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_orb_GPS.mat');
                        % load(path,"SISRE_mat_orb_GPS");
                        % 
                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_tot_GPS.mat');
                        % load(path,"SISRE_mat_tot_GPS");

                        % Componimento unico vettore diff_r per tutti i satelliti del giorno
                        load('C:\multiGNSS_v3\HAS\Risultati\calc_SISRE.mat');

                        temp_diff_r_tutti_SAT_GPS = diff_r_tutti_SAT_GPS;
                        temp_diff_t_tutti_SAT_GPS = diff_t_tutti_SAT_GPS;
                        temp_diff_w_tutti_SAT_GPS = diff_w_tutti_SAT_GPS;
                        temp_diff_dc_tutti_SAT_GPS = diff_dc_tutti_SAT_GPS;

                        clear diff_r_tutti_SAT_GPS diff_t_tutti_SAT_GPS diff_w_tutti_SAT_GPS diff_dc_tutti_SAT_GPS

                        diff_r_tutti_SAT_GPS = horzcat(temp_diff_r_tutti_SAT_GPS,new_diff_r_rms);
                        diff_t_tutti_SAT_GPS = horzcat(temp_diff_t_tutti_SAT_GPS,new_diff_t_rms);
                        diff_w_tutti_SAT_GPS = horzcat(temp_diff_w_tutti_SAT_GPS,new_diff_w_rms);
                        diff_dc_tutti_SAT_GPS = horzcat(temp_diff_dc_tutti_SAT_GPS,new_diff_dc_rms);

                        % SISRE singolo satellite
                        wr = 0.98;
                        wac = (1/49);
                        R = rms(new_diff_r_rms);
                        A = rms(new_diff_t_rms);
                        C = rms(new_diff_w_rms);
                        DC = rms(wr*new_diff_r_rms - new_diff_dc_rms*(10^-9)*clite); %new_diff_dc_rms è BRDM+HAS-SP3 e new_diff_r_rms è SP3-BRDM-HAS
                        SISRE_orb_GPS = sqrt((wr^2)*(R^2)+wac*(A^2+C^2));
                        SISRE_tot_GPS = sqrt(DC^2+wac*(A^2+C^2));
                        SISRE_mat_orb_GPS(k,1) = SAT_disponibili(k);
                        SISRE_mat_orb_GPS(k,2) = SISRE_orb_GPS;
                        SISRE_mat_tot_GPS(k,1) = SAT_disponibili(k);
                        SISRE_mat_tot_GPS(k,2) = SISRE_tot_GPS;
                        diff_r_mat_GPS(2:(length(new_diff_r)+1),k) = new_diff_r;
                        diff_t_mat_GPS(2:(length(new_diff_t)+1),k) = new_diff_t;
                        diff_w_mat_GPS(2:(length(new_diff_w)+1),k) = new_diff_w;
                        diff_dc_mat_GPS(2:(length(new_diff_dc)+1),k) = new_diff_dc;

                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_orb_GPS.mat');
                        % save(path,"SISRE_mat_orb_GPS");
                        % 
                        % path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_mat_tot_GPS.mat');
                        % save(path,"SISRE_mat_tot_GPS");

                    end

                    % Salvataggio dati per il calcolo SISRE su tutti i satelliti

                    path_SISRE = strcat('C:\multiGNSS_v3\HAS\Risultati\calc_SISRE');

                    if costellazione == 0

                        save(path_SISRE,'diff_r_tutti_SAT_GPS','diff_t_tutti_SAT_GPS','diff_w_tutti_SAT_GPS','diff_dc_tutti_SAT_GPS','SISRE_mat_orb_GPS','SISRE_mat_tot_GPS','diff_r_mat_GPS','diff_t_mat_GPS','diff_w_mat_GPS','diff_dc_mat_GPS');

                    end

                    if costellazione == 2

                        save(path_SISRE,'diff_r_tutti_SAT_Gal','diff_t_tutti_SAT_Gal','diff_w_tutti_SAT_Gal','diff_dc_tutti_SAT_Gal','SISRE_mat_orb_Gal','SISRE_mat_tot_Gal','diff_r_mat_Gal','diff_t_mat_Gal','diff_w_mat_Gal','diff_dc_mat_Gal');

                    end

                    % GPS

                    if costellazione == 0

                        R = rms(diff_r_tutti_SAT_GPS); % calcolo rms per tutti
                        A = rms(diff_t_tutti_SAT_GPS);
                        C = rms(diff_w_tutti_SAT_GPS);
                        wr = 0.98;
                        DC = rms(wr*diff_r_tutti_SAT_GPS - diff_dc_tutti_SAT_GPS*10^-9*clite);
                        wac = (1/49);
                        SISRE_orb_GPS_tutti_SAT = sqrt((wr^2)*(R^2)+wac*(A^2+C^2));
                        SISRE_tot_GPS_tutti_SAT = sqrt(DC^2+wac*(A^2+C^2));

                        path_SISRE = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_GPS');

                        save(path_SISRE,'SISRE_mat_orb_GPS','SISRE_mat_tot_GPS','SISRE_orb_GPS_tutti_SAT','SISRE_tot_GPS_tutti_SAT','diff_r_mat_GPS','diff_t_mat_GPS','diff_w_mat_GPS','diff_dc_mat_GPS','diff_r_tutti_SAT_GPS','diff_w_tutti_SAT_GPS','diff_t_tutti_SAT_GPS','diff_dc_tutti_SAT_GPS');

                    end

                    % Gal

                    if costellazione == 2

                        R = rms(diff_r_tutti_SAT_Gal); % calcolo rms per tutti
                        A = rms(diff_t_tutti_SAT_Gal);
                        C = rms(diff_w_tutti_SAT_Gal);
                        wr = 0.98;
                        DC = rms(wr*diff_r_tutti_SAT_Gal - diff_dc_tutti_SAT_Gal*10^-9*clite);
                        wac = (1/61);
                        SISRE_orb_Gal_tutti_SAT = sqrt((wr^2)*(R^2)+wac*(A^2+C^2));
                        SISRE_tot_Gal_tutti_SAT = sqrt(DC^2+wac*(A^2+C^2));

                        path_SISRE = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_Gal');

                        save(path_SISRE,'SISRE_mat_orb_Gal','SISRE_mat_tot_Gal','SISRE_orb_Gal_tutti_SAT','SISRE_tot_Gal_tutti_SAT','diff_r_mat_Gal','diff_t_mat_Gal','diff_w_mat_Gal','diff_dc_mat_Gal','diff_r_tutti_SAT_Gal','diff_w_tutti_SAT_Gal','diff_t_tutti_SAT_Gal','diff_dc_tutti_SAT_Gal');

                    end

                end

                % STATISTICHE BRDM+HAS-SP3 DI TUTTI I SATELLITI DELLA COSTELLAZIONE PER QUEL GIORNO

                % Carica i file .mat e sostituisci con le statistiche SP3-BRDM-HAS

                if costellazione == 0 % GPS

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_dc.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_dc");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_x.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_y.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_z.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_x.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_y.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_z.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_dc.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_dc");

                end

                if costellazione == 2 % Galileo

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_dc.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_dc");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_x.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_y.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_z.mat');
                    load(path,"avg_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_x.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_y.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_z.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_dc.mat');
                    load(path,"rms_brdm_plus_HAS_sp3_dc");

                end

                avg_brdm_plus_HAS_sp3_dc(k,1) = SAT;
                avg_brdm_plus_HAS_sp3_dc(k,2) = -mean(new_diff_dc_rms)*(10^3); 
                avg_brdm_plus_HAS_sp3_x(k,1) = SAT;
                avg_brdm_plus_HAS_sp3_x(k,2) = -mean(new_diff_x_rms);
                avg_brdm_plus_HAS_sp3_y(k,1) = SAT;
                avg_brdm_plus_HAS_sp3_y(k,2) = -mean(new_diff_y_rms);
                avg_brdm_plus_HAS_sp3_z(k,1) = SAT;
                avg_brdm_plus_HAS_sp3_z(k,2) = -mean(new_diff_z_rms);

                rms_brdm_plus_HAS_sp3_dc(k,1) = SAT;
                rms_brdm_plus_HAS_sp3_dc(k,2) = rms(new_diff_dc_rms)*(10^3); 
                rms_brdm_plus_HAS_sp3_x(k,1) = SAT;
                rms_brdm_plus_HAS_sp3_x(k,2) = rms(new_diff_x_rms);
                rms_brdm_plus_HAS_sp3_y(k,1) = SAT;
                rms_brdm_plus_HAS_sp3_y(k,2) = rms(new_diff_y_rms);
                rms_brdm_plus_HAS_sp3_z(k,1) = SAT;
                rms_brdm_plus_HAS_sp3_z(k,2) = rms(new_diff_z_rms);

                if costellazione == 0 % GPS

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_dc.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_dc");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_x.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_y.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\avg_brdm_plus_HAS_sp3_z.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_x.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_y.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_z.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\rms_brdm_plus_HAS_sp3_dc.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_dc");

                end

                if costellazione == 2 % Galileo

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_dc.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_dc");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_x.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_y.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\avg_brdm_plus_HAS_sp3_z.mat');
                    save(path,"avg_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_x.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_x");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_y.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_y");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_z.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_z");

                    path = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\rms_brdm_plus_HAS_sp3_dc.mat');
                    save(path,"rms_brdm_plus_HAS_sp3_dc");

                end

                clear new_diff_r_rms new_diff_t_rms new_diff_w_rms new_diff_dc_rms new_diff_x_rms new_diff_y_rms new_diff_z_rms

                % TRACCIAMENTO GRAFICI

                n = 86400/(dt*60); % numero di istanti da considerare nel DoY
                time_h = zeros(n,1);

                if c_grafici == 1

                    for i = 1:length(ToW_v)    

                         time_h(i) = (ToW_v(i)-DoW*86400)/3600; % vettore che contiene il ToW trasformato in ore giornaliere

                    end

                    % Plot separati

                    figure (1)
                    plot(time_h,sp3_brdm_r,'-*')
                    hold on
                    grid on
                    plot(time_h,corr_ra,'-*')
                    hold on
                    grid on
                    plot(time_h,diff_r,'-*')
                    xlabel('Time of Day [h]')
                    ylabel('[m]')
                    legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')  
                    set(gca, 'xlim', [0 24]);
                    set(gca, 'xtick', 0:3:24);
                    set(gca,'FontSize',15)
                    set(gca, 'ylim', [-1.5 1.5]);
                    set(gca, 'ytick', -1.5:0.5:1.5);

                     figure (2)
                     plot(time_h,sp3_brdm_t,'-*')
                     hold on
                     grid on
                     plot(time_h,corr_ta,'-*')
                     hold on
                     grid on
                     plot(time_h,diff_t,'-*')
                     xlabel('Time of Day [h]')
                     ylabel('[m]')
                     legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')
                     set(gca, 'xlim', [0 24]);
                     set(gca, 'xtick', 0:3:24);
                     set(gca,'FontSize',15)
                     set(gca, 'ylim', [-1.5 1.5]);
                     set(gca, 'ytick', -1.5:0.5:1.5);

                     figure (3)
                     plot(time_h,sp3_brdm_w,'-*')
                     hold on
                     grid on
                     plot(time_h,corr_wa,'-*')
                     hold on
                     grid on
                     plot(time_h,diff_w,'-*')
                     xlabel('Time of Day [h]')
                     ylabel('[m]')
                     legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')
                     set(gca, 'xlim', [0 24]);
                     set(gca, 'xtick', 0:3:24);
                     set(gca,'FontSize',15)
                     set(gca, 'ylim', [-1.5 1.5]);
                     set(gca, 'ytick', -1.5:0.5:1.5);

                     figure (4)
                     plot(time_h,sp3_brdm_dc,'-*')
                     hold on
                     grid on
                     plot(time_h,corr_dc_t,'-*')
                     hold on
                     grid on
                     plot(time_h,diff_dc,'-*') % new_diff_dc tiene conto del clock_adjustment_HAS, diff_dc no
                     xlabel('Time of Day [h]')
                     ylabel('[ns]')
                     legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')
                     set(gca, 'xlim', [0 24]);
                     set(gca, 'xtick', 0:3:24);
                     set(gca,'FontSize',15)
                     set(gca, 'ylim', [-5 5]);
                     set(gca, 'ytick', -5:1:5);

                     figure (5)
                     plot(ToW_v,x_brdm_plus_HAS_sp3,'-*')
                     hold on
                     grid on
                     xlabel('Time of Week [s]')
                     ylabel('[m]')
                     legend('BRDM+HAS-SP3','Location','NorthOutside','Orientation','horizontal','Box','off')

                     figure (6)
                     plot(ToW_v,y_brdm_plus_HAS_sp3,'-*')
                     hold on
                     grid on
                     xlabel('Time of Week [s]')
                     ylabel('[m]')
                     legend('BRDM+HAS-SP3','Location','NorthOutside')

                     figure (7)
                     plot(ToW_v,z_brdm_plus_HAS_sp3,'-*')        
                     hold on
                     grid on
                     xlabel('Time of Week [s]')
                     ylabel('[m]')
                     legend('BRDM+HAS-SP3','Location','NorthOutside','Orientation','horizontal','Box','off')

                     figure (8)
                     plot(ToW_v,x_brdm_plus_HAS,'-*')        
                     hold on
                     grid on
                     plot(ToW_v,y_brdm_plus_HAS,'-*') 
                     hold on
                     grid on
                     plot(ToW_v,z_brdm_plus_HAS,'-*') 
                     xlabel('Time of Week [s]')
                     ylabel('[km]')
                     legend('x','y','z')
                     title('BRDM+HAS')

                     figure (9)
                     plot(ToW_v,dc_brdm_plus_HAS,'-*')        
                     hold on
                     grid on
                     xlabel('Time of Week [s]')
                     ylabel('us')
                     title('BRDM+HAS CLOCK')

                     % figure (10)
                     % plot(ToW_v,controllo_OS,'-*')        
                     % hold on
                     % grid on
                     % xlabel('Time of Week [s]')
                     % title('BRDM OS Validity')
                     % legend('1 --> blocco BRDM OS usato fuori dal limite di validità di 2h')

                     % 4 plot insieme, figure(1) figure(2) figure(3) figure(4)
            % 
            %         t = tiledlayout(2,2);
            % 
            %         % RADIAL
            %         nexttile
            %         plot(time_h,sp3_brdm_r,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,corr_ra,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,diff_r,'-*')
            %         hold off 
            %         title('Radial')
            %         xlabel('Time of Day [h]')
            %         ylabel('[m]')
            %         legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')  
            %         set(gca, 'xlim', [0 24]);
            %         set(gca, 'xtick', 0:3:24);
            %         set(gca, 'ylim', [-0.6 0.8]);
            %         set(gca, 'ytick', -0.6:0.2:0.8);
            %         set(gca,'FontSize',20)
            % 
            %         % IN-TRACK
            %         nexttile
            %         plot(time_h,sp3_brdm_t,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,corr_ta,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,diff_t,'-*')
            %         hold off 
            %         title('Along-track')
            %         xlabel('Time of Day [h]')
            %         ylabel('[m]')
            %         legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')  
            %         set(gca, 'xlim', [0 24]);
            %         set(gca, 'xtick', 0:3:24);
            %         set(gca, 'ylim', [-0.6 0.8]);
            %         set(gca, 'ytick', -0.6:0.2:0.8);
            %         set(gca,'FontSize',20)
            % 
            %         % CROSS-TRACK
            %         nexttile
            %         plot(time_h,sp3_brdm_w,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,corr_wa,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,diff_w,'-*')
            %         hold off 
            %         title('Cross-track')
            %         xlabel('Time of Day [h]')
            %         ylabel('[m]')
            %         legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')  
            %         set(gca, 'xlim', [0 24]);
            %         set(gca, 'xtick', 0:3:24);
            %         set(gca, 'ylim', [-0.6 0.8]);
            %         set(gca, 'ytick', -0.6:0.2:0.8);
            %         set(gca,'FontSize',20)
            % 
            %         % CLOCK
            %         nexttile
            %         plot(time_h,sp3_brdm_dc,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,corr_dc_t,'-*')
            %         hold on
            %         grid on
            %         plot(time_h,new_diff_dc,'-*')
            %         hold off 
            %         title('Clock')
            %         xlabel('Time of Day [h]')
            %         ylabel('[ns]')
            %         legend('SP3-BRDM','HAS','SP3-BRDM-HAS','Location','NorthOutside','Orientation','horizontal','Box','off')  
            %         set(gca, 'xlim', [0 24]);
            %         set(gca, 'xtick', 0:3:24);
            %         set(gca, 'ylim', [-2 1]);
            %         set(gca, 'ytick', -2:0.5:1);
            %         set(gca,'FontSize',20)

                     if costellazione == 2 % Galileo

            %              % JPEG
            %                 
            %              filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_radial.jpeg');
            %              print(figure(1),'-djpeg',filename_fig1);
            %              filename_fig2 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_in_track.jpeg');
            %              print(figure(2),'-djpeg',filename_fig2); 
            %              filename_fig3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_cross_track.jpeg');
            %              print(figure(3),'-djpeg',filename_fig3);
            %              filename_fig4 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_deriva_clock.jpeg');
            %              print(figure(4),'-djpeg',filename_fig4);
            %              filename_fig5 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_x.jpeg');
            %              print(figure(5),'-djpeg',filename_fig5);
            %              filename_fig6 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_y.jpeg');
            %              print(figure(6),'-djpeg',filename_fig6); 
            %              filename_fig7 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_z.jpeg');
            %              print(figure(7),'-djpeg',filename_fig7);
            %              filename_fig8 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_pos.jpeg');
            %              print(figure(8),'-djpeg',filename_fig8); 
            %              filename_fig9 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_dc.jpeg');
            %              print(figure(9),'-djpeg',filename_fig9);

                         % TIFF

                         filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_radial.tiff');
                         print(figure(1), '-dtiff', filename_fig1);
                         filename_fig2 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_in_track.tiff');
                         print(figure(2), '-dtiff', filename_fig2);
                         filename_fig3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_cross_track.tiff');
                         print(figure(3), '-dtiff', filename_fig3);
                         filename_fig4 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_deriva_clock.tiff');
                         print(figure(4), '-dtiff', filename_fig4);
                         filename_fig5 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_x.tiff');
                         print(figure(5), '-dtiff', filename_fig5);
                         filename_fig6 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_y.tiff');
                         print(figure(6), '-dtiff', filename_fig6);
                         filename_fig7 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_z.tiff');
                         print(figure(7), '-dtiff', filename_fig7);
                         filename_fig8 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_pos.tiff');
                         print(figure(8), '-dtiff', filename_fig8);
                         filename_fig9 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\',num2str(SAT),'\E',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_dc.tiff');
                         print(figure(9), '-dtiff', filename_fig9);

                     end

                     if costellazione == 0 % GPS

            %              % JPEG
            %                 
            %              filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_radial.jpeg');
            %              print(figure(1),'-djpeg',filename_fig1);
            %              filename_fig2 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_in_track.jpeg');
            %              print(figure(2),'-djpeg',filename_fig2); 
            %              filename_fig3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_cross_track.jpeg');
            %              print(figure(3),'-djpeg',filename_fig3);
            %              filename_fig4 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_deriva_clock.jpeg');
            %              print(figure(4),'-djpeg',filename_fig4);
            %              filename_fig5 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_x.jpeg');
            %              print(figure(5),'-djpeg',filename_fig5);
            %              filename_fig6 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_y.jpeg');
            %              print(figure(6),'-djpeg',filename_fig6); 
            %              filename_fig7 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_z.jpeg');
            %              print(figure(7),'-djpeg',filename_fig7);
            %              filename_fig8 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_pos.jpeg');
            %              print(figure(8),'-djpeg',filename_fig8); 
            %              filename_fig9 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_dc.jpeg');
            %              print(figure(9),'-djpeg',filename_fig9);

                         % TIFF

                         filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_radial.tiff');
                         print(figure(1), '-dtiff', filename_fig1);
                         filename_fig2 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_in_track.tiff');
                         print(figure(2), '-dtiff', filename_fig2);
                         filename_fig3 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_cross_track.tiff');
                         print(figure(3), '-dtiff', filename_fig3);
                         filename_fig4 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_deriva_clock.tiff');
                         print(figure(4), '-dtiff', filename_fig4);
                         filename_fig5 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_x.tiff');
                         print(figure(5), '-dtiff', filename_fig5);
                         filename_fig6 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_y.tiff');
                         print(figure(6), '-dtiff', filename_fig6);
                         filename_fig7 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','val_HAS_z.tiff');
                         print(figure(7), '-dtiff', filename_fig7);
                         filename_fig8 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_pos.tiff');
                         print(figure(8), '-dtiff', filename_fig8);
                         filename_fig9 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\',num2str(SAT),'\G',num2str(SAT),'_doy',num2str(DoY),'_','BRDM_plus_HAS_dc.tiff');
                         print(figure(9), '-dtiff', filename_fig9);

                     end

                     close(figure(1));
                     close(figure(2));
                     close(figure(3));
                     close(figure(4));
                     close(figure(5));
                     close(figure(6));
                     close(figure(7));
                     close(figure(8));
                     close(figure(9));

                end

            end

        end
    
        % Tracciamento grafici SISRE

        if c_grafici == 1

            if costellazione == 2

                path_Gal = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_Gal');

                load(path_Gal)

                SISRE_orb_Gal = SISRE_mat_orb_Gal(:,2);
                SAT_Gal = SISRE_mat_orb_Gal(:,1);
                SISRE_tot_Gal = SISRE_mat_tot_Gal(:,2);

                SISRE(:,1) = SISRE_orb_Gal;
                SISRE(:,2) = SISRE_tot_Gal;

                figure(1)
                bar(SAT_Gal,SISRE);
                hold on
                grid on
                ylabel('[m]');
                set(gca, 'ylim', [0 1]);
                set(gca, 'ytick', 0:0.1:1);
                set(gca, 'xtick', SAT_disponibili);
                xtickangle(90)   
                legend('Orbit SISRE','Total SISRE');

                filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\Galileo\SISRE_Gal_',num2str(DoY),'_',num2str(YR),'.tiff');

                print(figure(1), '-dtiff', filename_fig1);

                close(figure(1));

            end

            if costellazione == 0

                path_GPS = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\SISRE_GPS');

                load(path_GPS)

                SISRE_orb_GPS = SISRE_mat_orb_GPS(:,2);
                SAT_GPS = SISRE_mat_orb_GPS(:,1);
                SISRE_tot_GPS = SISRE_mat_tot_GPS(:,2);

                SISRE(:,1) = SISRE_orb_GPS;
                SISRE(:,2) = SISRE_tot_GPS;

                figure(1)
                bar(SAT_GPS,SISRE);
                hold on
                grid on
                ylabel('[m]');
                set(gca, 'ylim', [0 1]);
                set(gca, 'ytick', 0:0.1:1);
                set(gca, 'xtick', SAT_disponibili);
                xtickangle(90)
                legend('Orbit SISRE','Total SISRE')

                filename_fig1 = strcat('C:\multiGNSS_v3\HAS\Risultati\',num2str(YR),'_',num2str(DoY),'\GPS\SISRE_GPS_',num2str(DoY),'_',num2str(YR),'.tiff');

                print(figure(1), '-dtiff', filename_fig1);

                close(figure(1));

            end

        end

        % Cancelliamo le variabili per iterare sulle costellazioni

        clc
        clearvars -except DoY DoYs controllo c_grafici c_overwrite c_SISRE ...
        AC_abb HAS_abb out_sp3_abb est costellazioni YR dt brdm_type...
        clite omega_e OBS_L1CA OBS_L1P OBS_E1 OBS_E5b OBS_E5a DoM MN WN DoW...
        v costellazione

    end       % Finito questo end abbiamo iterato sulle costellazioni indicate nel vettore costellazioni

    % Rinizzializzazione delle variabili per iterare il procedimento su
    % tutti i giorni.

    clc
    clearvars -except DoY DoYs controllo c_grafici c_overwrite c_SISRE ...
    AC_abb HAS_abb out_sp3_abb est costellazioni YR dt brdm_type...
    clite omega_e OBS_L1CA OBS_L1P OBS_E1 OBS_E5b OBS_E5a DoM MN WN DoW...
    v costellazione
     
end % Finito questo end abbiamo iterato su tutti i giorni indicati nel primo ciclo for

toc;
