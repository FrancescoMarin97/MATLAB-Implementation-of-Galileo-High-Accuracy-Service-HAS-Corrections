% Function per trasformare il secondo della settimana GPS, nel secondo del
% giorno.

% HELP INPUT

% a = secondo della settimana GPS [s];

% HELP OUTPUT

% ToD = Time of Day - secondo del giorno [s].

%%

function [ToD] = ToW_to_ToD (a)

c = fix(a/86400);
d = a-c*86400;
HR = fix(d/3600);
e = d-HR*3600;
MN = fix(e/60);
SS = e-MN*60;
ToD = HR*3600+MN*60+SS;

end