% Function per trasformare il secondo della settimana, nell'orario UTC.

% HELP INPUT

% a = secondo della settimana GPS [s];

% HELP OUTPUT

% HR = Hour.

% MN = Minute.

% SS = Second.

%%
function [HR,MN,SS] = ToW_to_UTC (a)

c = fix(a/86400);
d = a-c*86400;
HR = fix(d/3600);
e = d-HR*3600;
MN = fix(e/60);
SS = e-MN*60;

end