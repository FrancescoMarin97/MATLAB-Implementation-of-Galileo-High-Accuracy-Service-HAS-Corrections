function sp3Sys = readSP3(fileName,epoch0,DoW,dt)

% INPUT:
% * fileName: nome file effemeridi sp3
% * epoch0: epoca a mezzanotte del giorno di analisi
% OUTPUT:
% * sp3Sys: struttura con un record per ogni sistema con i campi:
%   - type
%   - init:
%   - data: struttura con un record per ogni satellite con i campi:
%     - sat: numero satellite
%     - X: matrice coordinate (ogni riga corrisponde ad un epoca)
%     - clock: vettore clock (ogni riga corrisponde ad un epoca)

    % Inizializzo "data", sotto-struttura di "sp3Sys"
    data = struct('sat', [], 'SP3data', []);
    
    % Inizializzo "sp3Sys"
    sp3Sys(1) = struct('type', 'gps', 'init', 'G', 'data', data);
    sp3Sys(2) = struct('type', 'glo', 'init', 'R', 'data', data);
    sp3Sys(3) = struct('type', 'gal', 'init', 'E', 'data', data);
    sp3Sys(4) = struct('type', 'chi', 'init', 'C', 'data', data);
    sp3Sys(5) = struct('type', 'jap', 'init', 'J', 'data', data);
    
    fileID = fopen(fileName, 'r');
    
    % Inizializzo:
    % - okData: logico, se vero posso leggere dati
    % - row: intero, numero di riga della matrice "X" e del vettore "clock"
    % corrispondenti all'epoca corrente
    okData = false;
    row = 0;
    ToW = 0;
    
    tline = fgetl(fileID);
    while ischar(tline)
        if strcmpi(tline(1), 'P')
            % Se okData è vero devo leggere coordinate e clock del sistema
            % individuato dalla 2a lettera
            [init sat x y z dT] = strread(tline, '%*c%c%d %f %f %f %f');
            for iSys = 1:length(sp3Sys)
                if strcmpi(sp3Sys(iSys).init, init) && okData
                    sp3Sys(iSys).data(sat).sat = sat;
                    sp3Sys(iSys).data(sat).SP3data(row, :) = [ToW,x, y,z,dT];
    %                 sp3Sys(iSys).data(sat).Y(row, :) = y;
    %                 sp3Sys(iSys).data(sat).Z(row, :) = z;
    %                 sp3Sys(iSys).data(sat).clock(row, 1) = dT;
                end
            end
        elseif strcmpi(tline(1), '*')
            epoch = strread(tline(2:end), '%f');
            % Calcolo i secondi tra epoch e epoch0: devono essere >= 0 e <=
            % 86400
            sod = etime(epoch', epoch0);
            if (sod < 0) || (sod > 86400)
                okData = false;
                tline = fgetl(fileID);
                continue
            end
            % Controllo che epoch sia multiplo di dt*60 s
            a = dt*60;
            if rem(sod, a)
                okData = false;
            else
                okData = true;
                % Determino numero di riga corrispondente a sod
                row = 1 + sod/(a);
            end
        end
        
        tline = fgetl(fileID);
    end
    
    fclose(fileID);
    
    % Inserimento del ToW nella struct
    
    ToW_i = (DoW)*86400 - dt*60;
    
    for i = 1:(86400/(dt*60))
    
        ToW_i = ToW_i+dt*60;
    
        for k = 1:length(sp3Sys)
    
            for q = 1:length(sp3Sys(k).data)
                
                sp3Sys(k).data(q).SP3data(i) = ToW_i; 
    
            end
    
        end
    
    end

end