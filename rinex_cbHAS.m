% Function to generate RINEX files with Code Bias HAS corrections; it works
% with HASCodeBiasCorr2RNX304.m

% INPUT
% filename_RNX = RINEX obs original file
% rinexdataHAS = strcutre file import with rinexread modified with HAS
% Code Bias corrections (GPS and Galileo)
% STA_abb = station abbreviation
% yr4 = 4 digits year
% doy = Day of year

function [] = rinex_cbHAS(filename_RNX,rinexdataHAS,STA_abb,STA_abb_n, yr4, doy)

    fileName = filename_RNX;
    % fileInfo = rinexinfo(fileName);
    rinexData = rinexdataHAS;

    % Verify if the filed with GNSS exist in RINEX file

    if isfield(rinexData,'GPS') == 1
        GPS = rinexData.GPS;
    end

    if isfield(rinexData,'GLONASS') == 1
        GLONASS = rinexData.GLONASS;
    end

    if isfield(rinexData,'Galileo') == 1
        GALILEO = rinexData.Galileo;
    end

    if isfield(rinexData,'BeiDou') == 1
        BeiDou = rinexData.BeiDou;
    end

    if isfield(rinexData,'NavIC') == 1
        NavIC = rinexData.NavIC;
    end

    if isfield(rinexData,'SBAS') == 1
        SBAS = rinexData.SBAS;
    end

    if isfield(rinexData,'QZSS') == 1
        QZSS = rinexData.QZSS;
    end

    % Eliminating NaN values, substitue with 0

    % GPS

    if isfield(rinexData,'GPS') == 1

        x = isnan(GPS.ReceiverClockOffset);
        GPS.ReceiverClockOffset(x) = 0;
        x = isnan(GPS.SatelliteID);
        GPS.SatelliteID(x) = 0;

        for i = 4:length(GPS.Properties.VariableNames)

            a = strcat('x = isnan(GPS.',GPS.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('GPS.',GPS.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % GLONASS

    if isfield(rinexData,'GLONASS') == 1

        x = isnan(GLONASS.ReceiverClockOffset);
        GLONASS.ReceiverClockOffset(x) = 0;
        x = isnan(GLONASS.SatelliteID);
        GLONASS.SatelliteID(x) = 0;

        for i = 4:length(GLONASS.Properties.VariableNames)

            a = strcat('x = isnan(GLONASS.',GLONASS.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('GLONASS.',GLONASS.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % BeiDou

    if isfield(rinexData,'BeiDou') == 1

        x = isnan(BeiDou.ReceiverClockOffset);
        BeiDou.ReceiverClockOffset(x) = 0;
        x = isnan(BeiDou.SatelliteID);
        BeiDou.SatelliteID(x) = 0;

        for i = 4:length(BeiDou.Properties.VariableNames)

            a = strcat('x = isnan(BeiDou.',BeiDou.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('BeiDou.',BeiDou.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % Galileo

    if isfield(rinexData,'Galileo') == 1

        x = isnan(GALILEO.ReceiverClockOffset);
        GALILEO.ReceiverClockOffset(x) = 0;
        x = isnan(GALILEO.SatelliteID);
        GALILEO.SatelliteID(x) = 0;

        for i = 4:length(GALILEO.Properties.VariableNames)

            a = strcat('x = isnan(GALILEO.',GALILEO.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('GALILEO.',GALILEO.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % NavIC

    if isfield(rinexData,'NavIC') == 1

        x = isnan(NavIC.ReceiverClockOffset);
        NavIC.ReceiverClockOffset(x) = 0;
        x = isnan(NavIC.SatelliteID);
        NavIC.SatelliteID(x) = 0;

        for i = 4:length(NavIC.Properties.VariableNames)

            a = strcat('x = isnan(NavIC.',NavIC.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('NavIC.',NavIC.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % SBAS

    if isfield(rinexData,'SBAS') == 1

        x = isnan(SBAS.ReceiverClockOffset);
        SBAS.ReceiverClockOffset(x) = 0;
        x = isnan(SBAS.SatelliteID);
        SBAS.SatelliteID(x) = 0;

        for i = 4:length(SBAS.Properties.VariableNames)

            a = strcat('x = isnan(SBAS.',SBAS.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('SBAS.',SBAS.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % QZSS

    if isfield(rinexData,'QZSS') == 1

        x = isnan(QZSS.ReceiverClockOffset);
        QZSS.ReceiverClockOffset(x) = 0;
        x = isnan(QZSS.SatelliteID);
        QZSS.SatelliteID(x) = 0;

        for i = 4:length(QZSS.Properties.VariableNames)

            a = strcat('x = isnan(QZSS.',QZSS.Properties.VariableNames(i),');');
            command = string(a);
            eval(command);
            a = strcat('QZSS.',QZSS.Properties.VariableNames(i),'(x) = 0;');
            command = string(a);
            eval(command);

        end

    end

    % OPEN THE OUTPUT FILE

    fileID = fopen(fileName);

    first_line = fgetl(fileID); % first line of header of original RINEX file
    outputFileNamefl = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\first_line.rnx');
    fileID = fopen(outputFileNamefl, 'w');
    fprintf(fileID,'%s',first_line); % save the first_line.rnx  

    last_line = "END OF HEADER"; % last line of the header
    outputFileNamell = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\last_line.rnx');
    fileID = fopen(outputFileNamell, 'w');
    fprintf(fileID,'%s',last_line); % save the last_line.rnx

    txt_RNX = extractFileText(fileName);
    header = extractBetween(txt_RNX,first_line,last_line);

    % Sobstiute city abbreviation with new city abbreviation in header RINEX 
    % city_abb = extractBetween(STA_abb,1,4); % city abbreviation
    % city_abb_n = extractBetween(STA_abb_n,1,4); % city abbreviation new
    % header = strrep(header,city_abb,city_abb_n);

    outputFileNameHeader = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\header.rnx');
    fileID = fopen(outputFileNameHeader, 'w');
    fprintf(fileID,'%s',header); % save the header.rnx

    % open temp HAS RINEX file

    outputFileName = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\temp.rnx');
    fileID = fopen(outputFileName, 'w');

    % WRITE THE OBSERVATION DATA TO THE NEW RINEX FILE
    time = unique(GPS.Time);
    sizeTime = size(time, 1);

    if isfield(rinexData,'GPS') == 1
    countG = 1;
    flagG = 0;
    contG = 0;
    end

    if isfield(rinexData,'GLONASS') == 1
    countR = 1;
    flagR = 0;
    contR = 0;
    end

    if isfield(rinexData,'BeiDou') == 1
    countC = 1;
    flagC = 0;
    contC = 0;
    end

    if isfield(rinexData,'Galileo') == 1
    countE = 1;
    flagE = 0;
    contE = 0;
    end

    if isfield(rinexData,'NavIC') == 1
    countI = 1;
    flagI = 0;
    contI = 0;
    end

    if isfield(rinexData,'SBAS') == 1
    countS = 1;
    flagS = 0;
    contS = 0;
    end

    if isfield(rinexData,'QZSS') == 1
    countJ = 1;
    flagJ = 0;
    contJ = 0;
    end

    for i = 1:sizeTime % iterate on the all time block in RINEX file
    % for i = 5000 % iterate on the all time block in RINEX file

        [y, m, d] = ymd(time(i));
        [h, min, s] = hms(time(i));
        flag = 0;

        numSat = 0;

        if isfield(rinexData,'GPS') == 1

            auxG = countG;
            sizeG = size(GPS, 1);
            while GPS.Time(auxG) == time(i) && flagG == 0
                auxG = auxG + 1;
                numSat = numSat + 1;
                if auxG > sizeG
                    contG = contG + 1;
                    if contG == 1
                        flagG = 1;
                        auxG = sizeG;
                    end
                end
            end

        end

        if isfield(rinexData,'GLONASS') == 1

            auxR = countR;
            sizeR = size(GLONASS, 1);
            while GLONASS.Time(auxR) == time(i) && flagR == 0
                auxR = auxR + 1;
                numSat = numSat + 1;
                if auxR > sizeR
                    contR = contR + 1;
                    if contR == 1
                        flagR = 1;
                        auxR = sizeR;
                    end
                end
            end

        end

        if isfield(rinexData,'BeiDou') == 1

            auxC = countC;
            sizeC = size(BeiDou, 1);
            while BeiDou.Time(auxC) == time(i) && flagC == 0
                auxC = auxC + 1;
                numSat = numSat + 1;
                if auxC > sizeC
                    contC = contC + 1;
                    if contC == 1
                        flagC = 1;
                        auxC = sizeC;
                    end
                end
            end

        end

        if isfield(rinexData,'Galileo') == 1

            auxE = countE;
            sizeE = size(GALILEO, 1);
            while GALILEO.Time(auxE) == time(i) && flagE == 0
                auxE = auxE + 1;
                numSat = numSat + 1;
                if auxE > sizeE
                    contE = contE + 1;
                    if contE == 1
                        flagE = 1;
                        auxE = sizeE;
                    end
                end
            end

        end

        if isfield(rinexData,'NavIC') == 1

            auxI = countI;
            sizeI = size(NavIC, 1);
            while NavIC.Time(auxI) == time(i) && flagI == 0
                auxI = auxI + 1;
                numSat = numSat + 1;
                if auxI > sizeI
                    contI = contI + 1;
                    if contI == 1
                        flagI = 1;
                        auxI = sizeI;
                    end
                end
            end

        end

        if isfield(rinexData,'SBAS') == 1

            auxS = countS;
            sizeS = size(SBAS, 1);

            if auxS < sizeS

                while SBAS.Time(auxS) == time(i) && flagS == 0
                    auxS = auxS + 1;
                    numSat = numSat + 1;
                    if auxS > sizeS
                        contS = contS + 1;
                        if contS == 1
                            flagS = 1;
                            auxS = sizeS;
                        end
                    end
                end

            end

        end

        if isfield(rinexData,'QZSS') == 1

            auxJ = countJ;
            sizeJ = size(QZSS, 1);

            if auxJ < sizeJ

                while QZSS.Time(auxJ) == time(i) && flagJ == 0
                    auxJ = auxJ + 1;
                    numSat = numSat + 1;
                    if auxJ > sizeJ
                        contJ = contJ + 1;
                        if contJ == 1
                            flagJ = 1;
                            auxJ = sizeJ;
                        end
                    end
                end

            end

        end

        % BRUX00BEL

        if STA_abb == "BRUX00BEL"

            fprintf(fileID,'\n> %1i %.2d %.2d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end

            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'NavIC';
            cost_abb = 'I';
            count = 'countI';
            cost_TT = NavIC;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countI <= height(NavIC.Time)
                while NavIC.Time(countI) == time(i)
                    if flagI == 0 || flagI == 1
                        eval(str_def);
                        countI = countI + 1;
                        if countI >= size(NavIC, 1)
                            contI = contI + 1;
                            if contI == 2
                                flagI = 1;
                                countI = size(NavIC, 1);
                            end
                        end
                    end

                    if countI > size(NavIC, 1)
                            break
                    end
                end

            end

            cost = 'QZSS';
            cost_abb = 'J';
            count = 'countJ';
            cost_TT = QZSS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countJ <= height(QZSS.Time)
                while QZSS.Time(countJ) == time(i)
                    if flagJ == 0 || flagJ == 1
                        eval(str_def);
                        countJ = countJ + 1;
                        if countJ >= size(QZSS, 1)
                            countJ = countJ + 1;
                            if countJ == 2
                                flagJ = 1;
                                countJ = size(QZSS, 1);
                            end
                        end
                    end

                    if countJ > size(QZSS, 1)
                            break
                    end
                end

            end

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end            

        end

        % PADO00ITA

        if STA_abb == "PADO00ITA"

            clockOffset_str = '.000000000000';
            fprintf(fileID,'\n> %1i %.2d %.2d %.2d %.2d %10.7f %2i %2i %20s\n', y, m, d, h, min, s, flag, numSat, clockOffset_str);     

            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end

            cost = 'NavIC';
            cost_abb = 'I';
            count = 'countI';
            cost_TT = NavIC;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countI <= height(NavIC.Time)
                while NavIC.Time(countI) == time(i)
                    if flagI == 0 || flagI == 1
                        eval(str_def);
                        countI = countI + 1;
                        if countI >= size(NavIC, 1)
                            contI = contI + 1;
                            if contI == 2
                                flagI = 1;
                                countI = size(NavIC, 1);
                            end
                        end
                    end

                    if countI > size(NavIC, 1)
                            break
                    end
                end

            end

        end

        % ASIA00ITA

        if STA_abb == "ASIA00ITA"

            fprintf(fileID,'\n> %1i %.2d %.2d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end

            cost = 'SBAS';
            cost_abb = 'S';
            count = 'countS';
            cost_TT = SBAS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countS <= height(SBAS.Time)
                while SBAS.Time(countS) == time(i) 
                    if flagS == 0 || flagS == 1
                        eval(str_def);
                        countS = countS + 1;
                        if countS >= size(SBAS, 1)
                            contS = contS + 1;
                            if contS == 2
                                flagS = 1;
                                countS = size(SBAS, 1);
                            end
                        end
                    end

                    if countS > size(SBAS, 1)
                        break
                    end
                end

            end 

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

            cost = 'QZSS';
            cost_abb = 'J';
            count = 'countJ';
            cost_TT = QZSS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countJ <= height(QZSS.Time)
                while QZSS.Time(countJ) == time(i)
                    if flagJ == 0 || flagJ == 1
                        eval(str_def);
                        countJ = countJ + 1;
                        if countJ >= size(QZSS, 1)
                            countJ = countJ + 1;
                            if countJ == 2
                                flagJ = 1;
                                countJ = size(QZSS, 1);
                            end
                        end
                    end

                    if countJ > size(QZSS, 1)
                            break
                    end
                end

            end

            cost = 'NavIC';
            cost_abb = 'I';
            count = 'countI';
            cost_TT = NavIC;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countI <= height(NavIC.Time)
                while NavIC.Time(countI) == time(i)
                    if flagI == 0 || flagI == 1
                        eval(str_def);
                        countI = countI + 1;
                        if countI >= size(NavIC, 1)
                            contI = contI + 1;
                            if contI == 2
                                flagI = 1;
                                countI = size(NavIC, 1);
                            end
                        end
                    end

                    if countI > size(NavIC, 1)
                            break
                    end
                end

            end

        end

        % TLSG00FRA

        if STA_abb == "TLSG00FRA"

            fprintf(fileID,'\n> %1i %.2d %.2d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end

            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'NavIC';
            cost_abb = 'I';
            count = 'countI';
            cost_TT = NavIC;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countI <= height(NavIC.Time)
                while NavIC.Time(countI) == time(i)
                    if flagI == 0 || flagI == 1
                        eval(str_def);
                        countI = countI + 1;
                        if countI >= size(NavIC, 1)
                            contI = contI + 1;
                            if contI == 2
                                flagI = 1;
                                countI = size(NavIC, 1);
                            end
                        end
                    end

                    if countI > size(NavIC, 1)
                            break
                    end
                end

            end

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end 

            cost = 'SBAS';
            cost_abb = 'S';
            count = 'countS';
            cost_TT = SBAS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countS <= height(SBAS.Time)
                while SBAS.Time(countS) == time(i) 
                    if flagS == 0 || flagS == 1
                        eval(str_def);
                        countS = countS + 1;
                        if countS >= size(SBAS, 1)
                            contS = contS + 1;
                            if contS == 2
                                flagS = 1;
                                countS = size(SBAS, 1);
                            end
                        end
                    end

                    if countS > size(SBAS, 1)
                        break
                    end
                end

            end 

        end

        % EKAR00ITA

        if STA_abb == "EKAR00ITA"

            fprintf(fileID,'\n> %1i %.2d %.2d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);      

            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end 

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

            cost = 'SBAS';
            cost_abb = 'S';
            count = 'countS';
            cost_TT = SBAS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countS <= height(SBAS.Time)
                while SBAS.Time(countS) == time(i) 
                    if flagS == 0 || flagS == 1
                        eval(str_def);
                        countS = countS + 1;
                        if countS >= size(SBAS, 1)
                            contS = contS + 1;
                            if contS == 2
                                flagS = 1;
                                countS = size(SBAS, 1);
                            end
                        end
                    end

                    if countS > size(SBAS, 1)
                        break
                    end
                end

            end 

            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

        end

        % ALTC00NOR

        if STA_abb == "ALTC00NOR"

             if d > 9 && h > 9 && min > 9

                fprintf(fileID,'\n> %1i  %.1d %.2d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end     

             if d > 9 && h > 9 && min < 10

                fprintf(fileID,'\n> %1i  %.1d %.2d %.2d  %.1d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end

             if d > 9 && h < 10 && min > 9

                fprintf(fileID,'\n> %1i  %.1d %.2d  %.1d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end   

             if d > 9 && h < 10 && min < 10

                fprintf(fileID,'\n> %1i  %.1d %.2d  %.1d  %.1d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end

             if d < 10 && h > 9 && min > 9

                fprintf(fileID,'\n> %1i  %.1d  %.1d %.2d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end 

             if d < 10 && h > 9 && min < 10

                fprintf(fileID,'\n> %1i  %.1d  %.1d %.2d  %.1d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

             end 

             if d < 10 && h < 10 && min > 9

                fprintf(fileID,'\n> %1i  %.1d  %.1d  %.1d %.2d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

            end

            if d < 10 && h < 10 && min < 10

                fprintf(fileID,'\n> %1i  %.1d  %.1d  %.1d  %.1d %10.7f %2i %2i\n', y, m, d, h, min, s, flag, numSat);     

            end
            
            cost = 'GPS';
            cost_abb = 'G';
            count = 'countG';
            cost_TT = GPS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countG <= height(GPS.Time) 

                while GPS.Time(countG) == time(i) 
                    if flagG == 0 || flagG == 1
                        eval(str_def); % comando che con fprintf stampa i nuovi valori delle osservazioni RNX+HAS nel file RINEX
                        countG = countG + 1;
                        if countG >= size(GPS, 1)
                            contG = contG + 1;
                            if contG == 2
                                flagG = 1;
                                countG = size(GPS, 1);
                            end
                        end
                    end

                    if countG > size(GPS, 1)
                        break
                    end
                end

            end

            cost = 'GLONASS';
            cost_abb = 'R';
            count = 'countR';
            cost_TT = GLONASS;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countR <= height(GLONASS.Time)
                while GLONASS.Time(countR) == time(i) 
                    if flagR == 0 || flagR == 1
                        eval(str_def);
                        countR = countR + 1;
                        if countR >= size(GLONASS, 1)
                            contR = contR + 1;
                            if contR == 2
                                flagR = 1;
                                countR = size(GLONASS, 1);
                            end
                        end
                    end

                    if countR > size(GLONASS, 1)
                        break
                    end
                end

            end 

            cost = 'GALILEO';
            cost_abb = 'E';
            count = 'countE';
            cost_TT = GALILEO;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countE <= height(GALILEO.Time)
                while GALILEO.Time(countE) == time(i)
                    if flagE == 0 || flagE == 1
                        eval(str_def);
                        countE = countE + 1;
                        if countE >= size(GALILEO, 1)
                            contE = contE + 1;
                            if contE == 2
                                flagE = 1;
                                countE = size(GALILEO, 1);
                            end
                        end
                    end

                    if countE > size(GALILEO, 1)
                        break
                    end
                end

            end
            
            cost = 'BeiDou';
            cost_abb = 'C';
            count = 'countC';
            cost_TT = BeiDou;

            [str_def] = command_str_RINEX (cost,cost_abb,count,cost_TT,STA_abb);

            if countC <= height(BeiDou.Time)
                while BeiDou.Time(countC) == time(i)
                    if flagC == 0 || flagC == 1
                        eval(str_def);
                        countC = countC + 1;
                        if countC >= size(BeiDou, 1)
                            contC = contC + 1;
                            if contC == 2
                                flagC = 1;
                                countC = size(BeiDou, 1);
                            end
                        end
                    end

                    if countC > size(BeiDou, 1)
                        break
                    end
                end
            end

        end

    end

    % CLOSE THE OUTPUT FILE
    fclose(fileID);

    command = strcat("chdir 'C:\\multiGNSS_v3\\HAS\\RINEX\\",num2str(yr4),"\\new RINEX';");
    eval(command);

    % Merge the different .rnx file

    A = fileread('first_line.rnx');
    B = fileread('header.rnx');
    C = fileread('last_line.rnx');
    D = fileread('temp.rnx');
    fid = fopen('final.rnx','w');
    fprintf(fid,'%s\n',[A B C D]);
    fclose(fid);

    % Delete the blank lines and save with proper name HAS RNX file

    filecontent = fileread('final.rnx');
    newcontent = regexprep(filecontent, {'\r', '\n\n+'}, {'', '\n'});

    if doy < 100 && doy > 9

        filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_R_',num2str(yr4),'0',num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path

        if STA_abb_n == "ALTH00NOR"
    
            filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_S_',num2str(yr4),'0',num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path
    
        end

    end

    if doy < 9

        filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_R_',num2str(yr4),'00',num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path

        if STA_abb_n == "ALTH00NOR"
    
            filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_S_',num2str(yr4),'00',num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path
    
        end

    end

    if doy > 99

        filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_R_',num2str(yr4),num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path
        
        if STA_abb_n == "ALTH00NOR"
    
            filename_HASRNX = strcat('C:\multiGNSS_v3\HAS\RINEX\',num2str(yr4),'\new RINEX\',STA_abb_n,'_S_',num2str(yr4),num2str(doy),'0000_01D_30S_MO.rnx'); % HAS RNX path
    
        end

    end
    
    fid = fopen(filename_HASRNX, 'w');
    fwrite(fid, newcontent);
    fclose(fid);

end