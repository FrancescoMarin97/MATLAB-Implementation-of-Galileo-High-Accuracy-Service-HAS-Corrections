% Function per il calcolo della settimana GPS e del giorno della settimana
% GPS

% INPUT
% DoM = Day of Month;
% MN = Month;
% YR = Year;

% OUTPUT
% WN = GPS Week Number;
% DoW = Day of week;

function [WN,DoW] = GPS_date (DoM,MN,YR)

    date = strcat(num2str(DoM),'.',num2str(MN),'.',num2str(YR));
    t = datetime(date,'TimeZone','UTC');
    GPS0 = datetime(1980,1,6,0,0,0,'TimeZone','UTCLeapSeconds');
    tLS = t;
    tLS.TimeZone = 'UTCLeapSeconds';
    deltaT = tLS - GPS0; deltaT.Format = 's';
    WN = floor(seconds(deltaT)/(7*86400));
    secs = rem(deltaT,seconds(7*86400));
    day = seconds(secs);
    DoW = fix(day/86400);

end
