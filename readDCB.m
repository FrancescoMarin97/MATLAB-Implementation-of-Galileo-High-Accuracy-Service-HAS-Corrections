% Function per leggere DCB dal file CAS DCB

% INPUT:
% * fileName: nome file DCB
% OUTPUT:
% * DCBSys: struttura con i campi:
%     - PRN: ID satellite
%     - DCB: estimated value [ns]
%     - UNIT: [ns]
%     - OBS1: osservazione 1
%     - OBS2: osservazione 2

function DCBSys = readDCB(fileName)

    % % Inizializzo "DCBSys"
    % DCBSys = struct('PRN', [], 'DCB', [],'UNIT', [], 'OBS1', [],'OBS2', []);
    
    fileID = fopen(fileName, 'r'); % apertura file CAS DCB
    
    % Inizializzo:
    % - row: intero, numero di riga della matrice DCB
    row = 0;
    
    tline = fgetl(fileID); % leggo tutte le righe del file .BSX

    while ischar(tline) && row < 814 % effetuo le operazioni successive solo in questo caso, 814 è il numero di righe da coniderare nei file CAS DCB dopo 59 righe di header
        
        if strcmpi(tline(2:4), 'DSB') % funzione per trovare delle righe con determinate caratteristiche

            row = row+1;
            [BIAS, SVN, PRN, OBS1, OBS2, BIAS_START, BIAS_END, UNIT, ESTIMATED_VALUE, STD_DEV] = strread(tline, '%s %s %s %s %s %s %s %s %s %s'); % leggo la riga e trovo i dati
            
            % Compongo DCBSys
            % DCBSys(row).PRN = PRN;
            % DCBSys(row).DCB = ESTIMATED_VALUE;
            % DCBSys(row).UNIT = UNIT;
            % DCBSys(row).OBS1 = OBS1;
            % DCBSys(row).OBS2 = OBS2;

            DCBSys_temp(row,1) = PRN;
            DCBSys_temp(row,2) = ESTIMATED_VALUE;
            DCBSys_temp(row,3) = UNIT;
            DCBSys_temp(row,4) = OBS1;
            DCBSys_temp(row,5) = OBS2;

        end

        tline = fgetl(fileID);

    end

    fclose(fileID);

    DCBSys = string(DCBSys_temp);

end