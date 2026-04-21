% Function per calcolare il mese e il giorno del mese a partire dal giorno
% dell'anno.

% HELP INPUT

% DoY = Day of Year;

% HELP OUTPUT

% DoM = Day of Month;

% Month 

function [DoM,Month] = DoY_to_DoM(DoY,YR)

    if DoY < 0
        
      disp('DoY deve essere > 0')  
    
    else
    
    if YR == 24

        d = [31,29,31,30,31,30,31,31,30,31,30,31];

    else

        d = [31,28,31,30,31,30,31,31,30,31,30,31];

    end

    somma = 0;
    
    somm_d = zeros(1,length(d));
    
    for i = 1:length(d)
        
       somm_d(i) = d(i)+ somma;
       somma = somm_d(i);
       
    end
    
    for i = 1:length(somm_d)
    
        if  DoY < somm_d(i) || DoY == somm_d(i) 
    
            Month = i;
            
            break
    
        end
    
    end
    
    if Month == 1
        
        DoM = DoY;
        
    end
    
    if Month > 1
    
        DoM = DoY - somm_d(Month-1);
    
    end
    
    
    end

end