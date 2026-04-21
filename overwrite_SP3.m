% Function per creare il file contenente i dati SP3 con la posizione
% e il clock corretti con HAS, ottenendo file in formato sp3, avendo noti
% gli input: anno, DoY, mese, giorno del mese, satellite, oltre che i dati
% da sostituire.

% HELP INPUT

% SAT_ID = vettore contenente l'ID dei satelliti della costellazione nel
% file SP3;

% WN = GPS Week Number;

% DoW = Day of Week;

% YR = ultime due cifre dell'anno in considerazione;

% DoY = Day of Year;

% MN = Month;

% DoM = Day of Month;

% SAT = satellite;

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

% HELP OUTPUT

% AC(Analysis Center Abbreviation)(WN)(DoW).est = file sp3 contenente la posizione e la deriva del clock 
% corrette con correzioni HAS

% caricamento del file contenente i dati SP3 per tutti i satelliti Galileo 
% nel DoY e sostituzione con BRDM+HAS

function [] = overwrite_SP3 (out_sp3_abb,est,SAT_ID,WN,DoW,YR,SAT,x_brdm_plus_HAS,y_brdm_plus_HAS,z_brdm_plus_HAS,dc_brdm_plus_HAS)

    abb_sat = SAT_ID(SAT); % abbreviazione del satellite nel file SP3
    
    % Apertura del file SP3 originale rinominato con UPH e del file
    % temporaneo
    
    filename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\',out_sp3_abb,num2str(WN),num2str(DoW),est);
    tempFilename = strcat('C:\multiGNSS_v3\HAS\',out_sp3_abb,'\',num2str(YR+2000),'\temp.txt');

    FID = fopen(filename, 'r');
    FID_temp = fopen(tempFilename, 'w');

    % Trovo le righe dove c'è il satellite e modifico sovrascrivendo ai
    % dati SP3 i dati BRDM+HAS passando per il file temporaneo

    line = fgetl(FID);
    i = 1;

    while ischar(line)

        if ~isempty(strfind(line, abb_sat))

            fprintf(FID_temp, '%.5s %13.6f %13.6f %13.6f %13.6f\n', abb_sat, x_brdm_plus_HAS(i), y_brdm_plus_HAS(i), z_brdm_plus_HAS(i), dc_brdm_plus_HAS(i));
            i = i+1;

        else

            fprintf(FID_temp, '%s\n', line);

        end

        line = fgetl(FID);

    end

    fclose(FID);
    fclose(FID_temp);
    fclose('all');
    movefile(tempFilename, filename);

end
    
