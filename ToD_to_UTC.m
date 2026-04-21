% Function per trasformare il secondo del giorno, nell'orario UTC.

% HELP INPUT

% a = secondo del giorno [s];

% HELP OUTPUT

% HR = Hour.

% MN = Minute.

% SS = Second.

%%

function [HR,MN,SS] = ToD_to_UTC (a)

HR = fix(a/3600);
e = a-HR*3600;
MN = fix(e/60);
SS = e-MN*60;

end