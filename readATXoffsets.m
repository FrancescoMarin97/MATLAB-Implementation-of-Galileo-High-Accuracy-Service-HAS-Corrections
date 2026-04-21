%% readATXoffsets
%
% Author: Luca Nicolini
%
% Purpose: legge antenna phase offset (APO) in direzione UP (z) dal file IGS 
%
%% INPUT:
% * date: vettore [YR MN DY 0 0 0], giorno di analisi
%
%% OUTPUT (apo: struttura, un record per ogni gnss, con i campi):
% * sys: stringa [3], nome sistema
% * offsets: values for all the signals of each SVN
% * log file "./log/ARP2CoM[yyyy][mm][dd].log"
%
%% Updates: 
% * 2022/03/31: JZ, to download from EPNCB instead of IGS (credentials needed).
% * 2022/03/31: JZ, Increase GPS and BDS arrays to [60,70].
% * 2022/03/31: JZ, add path valid also for the Helmert Transformation script call
% * 2022/10/14: JZ, output the Up offsets for ALL THE SIGNALS for all the constellations in
% the same variable
%
%% CREATED: 30/10/2017-02/11/2017
%%
function apo = readATXoffsets(date)

% inizializzo struct apo
apo(1) = struct('sys', 'gps', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));
apo(2) = struct('sys', 'glo', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));
apo(3) = struct('sys', 'gal', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));
apo(4) = struct('sys', 'chi', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));
apo(5) = struct('sys', 'jap', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));
apo(6) = struct('sys', 'irn', 'north', zeros(70, 10), 'east', zeros(70, 10), 'up', zeros(70, 10));


yyyy = date(1);
mm   = date(2);
dd   = date(3);
hh   = date(4);
min  = date(5);
sec  = date(6);

% Write the logfile header:

if exist('../input/atx/logs', 'dir')
   logName = sprintf('../input/atx/logs/APC2CoM%04d%02d%02d.log', yyyy, mm, dd);
else % Being called from compEph:
   logName = sprintf('../../input/atx/logs/APC2CoM%04d%02d%02d.log', yyyy, mm, dd);
end

logID = fopen(logName, 'w');
fprintf(logID, 'Get antenna offsets for all the satellites available in the latest available ATX file at EPN CB (script: readATXoffsets.m)\n');
fprintf(logID, 'Input file: latest ANTEX file (downloaded from the EPN CB server\n');
fprintf(logID, 'Output    : variable with all the offsets for all the satellites signals available in the ANTEX file.\n\n');
fprintf(logID, 'ATX Galileo Signal assignment (ANTEX 1.4 definition at: https://igs.org/wg/antenna#files and updated with RINEX 4.0 at: https://files.igs.org/pub/data/format/rinex_4.00.pdf):\n');
fprintf(logID, '   GPS:\n');
fprintf(logID, '      G01 derived from Signal-Component L1\n');
fprintf(logID, '      G02 derived from Signal-Component L2\n');
fprintf(logID, '      G05 derived from Signal-Component L5\n');
fprintf(logID, '   GLONASS:\n');
fprintf(logID, '      R01 derived from Signal-Component G1\n');
fprintf(logID, '      R02 derived from Signal-Component G2\n');
fprintf(logID, '      R03 derived from Signal-Component G3 (as defined in the RNX4 documentation)\n');
fprintf(logID, '      R04 derived from Signal-Component G1a (as defined in the RNX4 documentation)\n');
fprintf(logID, '      R06 derived from Signal-Component G2a (as defined in the RNX4 documentation)\n');
fprintf(logID, '   GALILEO:\n');
fprintf(logID, '      E01 derived from Signal-Component: E1\n');
fprintf(logID, '      E05 derived from Signal-Component: E5a\n');
fprintf(logID, '      E06 derived from Signal-Component: E6\n');
fprintf(logID, '      E07 derived from Signal-Component: E5b\n');
fprintf(logID, '      E08 derived from Signal-Component: E5 (E5a+E5b)\n');
fprintf(logID, '   BeiDou:\n');
fprintf(logID, '      C01 derived from Signal-Component: B1C, B1A\n');
fprintf(logID, '      C02 derived from Signal-Component: B1\n');
fprintf(logID, '      C05 derived from Signal-Component: B2a\n');
fprintf(logID, '      C07 derived from Signal-Component: B2, B2b\n');
fprintf(logID, '      C06 derived from Signal-Component: B3, B3A\n');
fprintf(logID, '      C08 derived from Signal-Component: B2(B2a+B2b)\n');
fprintf(logID, '   QZSS:\n');
fprintf(logID, '      J01 derived from Signal-Component: L1\n');
fprintf(logID, '      J02 derived from Signal-Component: L2\n');
fprintf(logID, '      J05 derived from Signal-Component: L5\n');
fprintf(logID, '      J06 derived from Signal-Component: L6\n');
fprintf(logID, '   SBAS:\n');
fprintf(logID, '      L01 derived from Signal-Component: L1\n');
fprintf(logID, '      L05 derived from Signal-Component: L5\n\n');
fprintf(logID, '   NavIC/IRNSS:\n');
fprintf(logID, '      I05 derived from Signal-Component: L5\n');
fprintf(logID, '      I09 derived from Signal-Component: S-band\n\n');


% definisco nome file atx
[locAtxWeek, ~] = chooseAtx;
checkNewAtx(locAtxWeek);
[~, atxFile] = chooseAtx;

fprintf(logID, 'Used ANTEX file: %s\n', atxFile);
fprintf(logID, 'Offsets valid for date: %d/%02d/%02d\n\n', yyyy, mm, dd);
fprintf(logID, 'ANTEX records:\n');


try 
    atxID = fopen(atxFile, 'r');
catch
    fprintf('WARNING: can not open file "%s"!\n', atxFile);
    return
end

% inizializzo flags:
% * headEnd: falso se non ho finito di leggere header
% * sysSat: falso se non ho letto gnss e PRN satellite
% * dateOk: false se la data di analisi non è compresa tra quelle di inizio
%           e fine validità
headEnd = false;
sysSat = false;
dateOk = false;

line = fgetl(atxID);

while ischar(line)
    if ~isempty(strfind(line, 'END OF HEADER')) 
        headEnd = true;
    end
    
    if headEnd && ~isempty(strfind(line, 'TYPE / SERIAL NO'))
        [sys, sat] = readSysSat(line);
        if (sys > 0) && (sat > 0)
            sysSat = true;
            SVN = line(1:59);
        end    
    end
    
    if sysSat && ~isempty(strfind(line, 'VALID FROM'))
        [dateOk] = readDate(line, atxID, date);
        DateString = line(3:49);
        if dateOk
            fprintf(logID, '   %s', SVN);
            fprintf(logID, '. Data valid since: %s\n', DateString);
        end
    end
    
% Check all the available frequencies:    
    if dateOk && ~isempty(strfind(line, 'START OF FREQUENCY'))
        Signal = str2double(line(5:6));
        STYPE = line(4:6);
    end
    if dateOk && ~isempty(strfind(line, 'NORTH / EAST / UP'))
        neu = strread(line(4:30), '%f');
        % Assegno la componente UP [m] al satellite "sat" del sistema "sys"
        apo(sys).north(sat,Signal) = 0.001*neu(1);
        apo(sys).east(sat,Signal) = 0.001*neu(2);
        apo(sys).up(sat,Signal) = 0.001*neu(3);
            fprintf(logID, '      Signal (North offset): %s (%5.3f m)\n', STYPE, apo(sys).north(sat,Signal));
            fprintf(logID, '      Signal (East offset) : %s (%5.3f m)\n', STYPE, apo(sys).east(sat,Signal));
            fprintf(logID, '      Signal (Up offset)   : %s (%5.3f m)\n', STYPE, apo(sys).up(sat,Signal));

% JZ: no. Do not write data when the SATELLITE is done. We need to read all
% the offsets of all the available signals:
%        dateOk = false;
    end
    
    if dateOk && ~isempty(strfind(line, 'END OF ANTENNA'))
% SVN done. Start with the next set of offsets 
        dateOk = false;
    end
    line = fgetl(atxID);
end

fclose(atxID);
fclose(logID);
end


%% Function readSysSat
%
% INPUT:
% * line: stringa, riga di testo da cui estrarre il tipo di gnss e PRN
%         satellite
%
% OUTPUT:
% * sys: intero, tipo di gnss (1 = GPS, 2 = GLO, 3 = GAL, 4 = CHI, 5 = JAP, 6 = IRN)
% * sat: intero, numero satellite
%%
function [sys, sat] = readSysSat(line)

sys = 0;
sat = 0;

if (strfind(line, 'BLOCK') == 1)
    sys = 1;
    sat = str2double(line(22:23));
elseif (strfind(line, 'GLONASS') == 1)
    sys = 2;
    sat = str2double(line(22:23));
elseif (strfind(line, 'GALILEO') == 1)
    sys = 3;
    sat = str2double(line(22:23));
elseif (strfind(line, 'BEIDOU') == 1)
    sys = 4;
    sat = str2double(line(22:23));
elseif (strfind(line, 'QZSS') == 1)
    sys = 5;
    sat = str2double(line(22:23));
elseif (strfind(line, 'IRNSS') == 1)
    sys = 6;
    sat = str2double(line(22:23));
end

end


%% Function readDate
%
% INPUT: 
% * line: stringa, riga di testo da cuic estrarre data di inizio validità
% * fid: identificatore file IGS
% * date: vettore [YR MN DY 0 0 0], giorno di analisi
%
% OUTPUT:
% * dateOk: logico, vero se giorno di analisi è compreso tra inizio e fine
%           validità
%%
function [dateOk] = readDate(line, fid, date)

dateOk = false;

dateStart = strread(line(3:43), '%f');
% leggo riga successiva
line = fgetl(fid);
% se riga successiva contiene fine validità devo controllare sia data
% inizio che di fine
if ~isempty(strfind(line, 'VALID UNTIL'))
    dateEnd = strread(line(3:43), '%f');
else
    if (etime(date, dateStart') >= 0)
        dateOk = true;
    end
    return
end

if (etime(date, dateStart') >= 0) && (etime(date, dateEnd') <= 0)
    dateOk = true;
end

end


%% Function chooseAtx
%
% INPUT: nessuno
%
% OUTPUT:
% * cWeek: intero, numero settimana file atx, nella cartella '../input' più
%          recente
% * fileName: stringa, nome file atx più recente
%
%%
function [cWeek, fileName] = chooseAtx

cWeek = 0;
fileName = 'none';
% Depending on the script used to call this function, the path chages:
dirPath0 = '../input/atx';
dirPath = '../input/atx/igs14*.atx';
if not(isfolder(dirPath0))
    dirPath0 = '../../input/atx';
    dirPath = '../../input/atx/igs14*.atx';
end

atxList = dir(dirPath);
if isempty(atxList)
    return
end

lWeek = 1000;
for iAtx = 1:length(atxList)
    
    atxInfo = regexp(atxList(iAtx).name, 'igs14_(?<week>\d{4}).atx', 'names');
    if ~isempty(atxInfo)
        cWeek = str2double(atxInfo.week);
    else
        continue
    end
    
    if (cWeek > lWeek)
        lWeek = cWeek;
        % Depending on the script used to call this function, the path chages:
        dirPath = '../input/atx/';
        if not(isfolder(dirPath))
            dirPath = '../../input/atx/';
        end
        fileName = strcat(dirPath, atxList(iAtx).name);
    end
    
end

end


%% Function checkNewAtx
%
% INPUT:
% * lWeek: intero, numero settimana file locale
%
% OUTPUT:
% * file atx, se su ftp ne trova uno più recente della settimana "lWeek" 
%
%%
function checkNewAtx(lWeek)

try
% JZ changed to ftp://ftp.epncb.oma.be/pub/station/general/igs14_2194.atx    
   % igsFtp = ftp('ftp.igs.org');
    igsFtp = ftp('ftp.epncb.oma.be');
catch
    fprintf('WARNING: Could not connect to "%s"\n', igsFtp);
    return
end

cd(igsFtp, 'pub/station/general');
atxList = dir(igsFtp, 'igs*.atx');

if isempty(atxList)
    return
end

newAtx = false;

for iAtx = 1:length(atxList)
    atxInfo = regexp(atxList(iAtx).name, 'igs14_(?<week>\d{4}).atx', 'names');
    if ~isempty(atxInfo)
        cWeek = str2double(atxInfo.week);
    else
        continue
    end
    
    if (cWeek > lWeek)
        newAtx = true;
        lWeek = cWeek;
        fileName = atxList(iAtx).name;
    end
    
end

if newAtx
     % Depending on the script used to call this function, the path chages:
%     dirPath = '../input/atx/igs*.atx';
     dirPath = '../input/atx/';
     if not(isfolder(dirPath))
%         dirPath = '../../input/atx/igs*.atx';
         dirPath = '../../input/atx/';
     end
     mget(igsFtp, fileName, dirPath);
end

end