% Function per identificare i satelliti per cui  siano disponibli
% contemporaneamente i file contenenti i dati: HAS, BRDM e SP3; permette
% inoltre di caricare i file corrispondenti.

% HELP INPUT

% ACC_abb = Analysis Center abbreviation per indicare l'interstazione dei
% file SP3 utilizzati per la valutazione delle correzioni HAS

% est = estensione del file SP3

% HAS_abb = abbreviation dei file contenenti le correzioni HAS

% WN = Week Number

% DoW = Day of Week

% DoY = day of year

% YR = year (ultime due cifre dell'anno in considerazione)

% AC(Analysis Center abbreviation)(WN)(DoW).(est) = file sp3 contenente i dati SP3 dell'AC del DoY; 

% brdm0(DoY)0gal.(YR)P = file contenente le efemeridi broadcast Galileo 
% del DoY;

% brdm0(DoY)0gps.(YR)P = file contenente le efemeridi broadcast GPS 
% del DoY;

% brdm0(DoY-1)0gal.(YR)P = file contenente le efemeridi broadcast Galileo 
% del DoY-1;

% brdm0(DoY-1)0gps.(YR)P = file contenente le efemeridi broadcast GPS 
% del DoY-1;

% (HAS_abb)(DoY)0.(YR)_has_orb.csv = file.csv di tipo string array contenente le
% correzioni HAS orbitali del Doy

% (HAS_abb)(DoY)0.(YR)_has_clk.csv = file.csv di tipo string array contenente le
% correzioni HAS del clock del DoY

% HELP OUTPUT

% SAT_disponibili = satelliti per cui sono disponibili: HAS, BRDM e SP3

% mat = file .mat (cell) contenente le efemeridi broadcast per tutti i
% satelliti nel DoY

% mat_i = file .mat (cell) contenente le efemeridi broadcast per tutti i
% satelliti nel DoY-1

% sp3_disp,_v = file .mat co i satelliti disponibili nel file SP3

function [SAT_disponibili,mat,mat_i,sp3_disp_v,sp3_disp] = SAT_disp (HAS_abb,est,AC_abb,WN,DoW,YR,DoY,costellazione,DoM,MN)

    % SATELLITI PER CUI SONO DISPONIBILI: SP3, HAS E BRDM

    %% SP3

    % Caricamento del file contenente i dati SP3 per tutti i satelliti Galileo 
    % e GPS nel DoY e creazione del file .mat

    filename = strcat('C:\multiGNSS_v3\input\sp3\',AC_abb,num2str(WN),num2str(DoW),est);

    FID = fopen (filename);

    line = fgetl(FID);

    if DoM > 9 && MN > 9

        str_DoM_2 = strcat('*',{'  '},num2str(YR+2000),{' '},num2str(MN),{' '},num2str(DoM),{'  '},'0',{'  '},'0',{'  '},'0.00000000');

    end

    if DoM > 9 && MN < 10

        str_DoM_2 = strcat('*',{'  '},num2str(YR+2000),{'  '},num2str(MN),{' '},num2str(DoM),{'  '},'0',{'  '},'0',{'  '},'0.00000000');

    end

    if DoM < 10 && MN < 10

        str_DoM_2 = strcat('*',{'  '},num2str(YR+2000),{'  '},num2str(MN),{'  '},num2str(DoM),{'  '},'0',{'  '},'0',{'  '},'0.00000000');

    end

    if DoM < 10 && MN > 9

        str_DoM_2 = strcat('*',{'  '},num2str(YR+2000),{' '},num2str(MN),{'  '},num2str(DoM),{'  '},'0',{'  '},'0',{'  '},'0.00000000');

    end

    i = 1;

    while ischar(line)

        if ~isempty(strfind(line,str_DoM_2 ))

            break

        end

        i = i+1;
        line = fgetl(FID);

    end

    clear str_DoM_2
    clear line

    i_date = i;

    fclose(FID);

    clear FID

    % Creazione del file .mat contenente i dati sp3

    A = readtable(filename,'FileType','text');

    clear filename

    B = A((i_date):end,2:5);

    matsp3_i = cell(height(B),4);
    matsp3_i(:,1) = table2cell(A(i_date:end,1));

    for i = 1:width(B)

        a = table2array(B(:,i));
        matsp3_i(:,i+1) = num2cell(a);

    end

    clear A
    clear B
    clear a
    clear i
    clear i_date

    %% HAS

    % Caricamento del file contenente i dati HAS per tutti i satelliti Galileo 
    % e GPS nel DoY e creazione del file .mat, suddivisione in due file
    % separati

    if DoY < 100

        if YR == 22

            filename2 = strcat('D:\Università\Borsa di studio post-lauream CISAS\Risultati\188 - 232 (2022)\Input file Matlab\HAS\',num2str(DoY),'\SEPT0',num2str(DoY),'0.',num2str(YR),'_has_orb.csv');
            filename3 = strcat('D:\Università\Borsa di studio post-lauream CISAS\Risultati\188 - 232 (2022)\Input file Matlab\HAS\',num2str(DoY),'\SEPT0',num2str(DoY),'0.',num2str(YR),'_has_clk.csv');

        end

        if YR == 23

            filename2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_orb.csv');
            filename3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_clk.csv');

        end

        if YR == 24

            filename2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_orb.csv');
            filename3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,'0',num2str(DoY),'0.',num2str(YR),'__has_clk.csv');

        end

        D = readtable(filename2,'FileType','text');
        E = readtable(filename3,'FileType','text');

    end

    if DoY > 100 || DoY == 100

        if YR == 22

            filename2 = strcat('D:\Università\Borsa di studio post-lauream CISAS\Risultati\188 - 232 (2022)\Input file Matlab\HAS\',num2str(DoY),'\SEPT',num2str(DoY),'0.',num2str(YR),'_has_orb.csv');
            filename3 = strcat('D:\Università\Borsa di studio post-lauream CISAS\Risultati\188 - 232 (2022)\Input file Matlab\HAS\',num2str(DoY),'\SEPT',num2str(DoY),'0.',num2str(YR),'_has_clk.csv');

        end

        if YR == 23

            filename2 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY),'0.',num2str(YR),'__has_orb.csv');
            filename3 = strcat('E:\ASIAGO HAS\SBF\',num2str(WN),'\',HAS_abb,num2str(DoY),'0.',num2str(YR),'__has_clk.csv');

        end
    
        D = readtable(filename2,'FileType','text');
        E = readtable(filename3,'FileType','text');

    end

    clear filename2
    clear filename3

    matHASorb_comp = zeros(height(D),width(D));
    matHASclk_comp = zeros(height(E),width(E));

    for i = 1:width(D)

        a = table2array(D(:,i));
        matHASorb_comp(:,i) = (a);

    end

    for i = 1:width(E)

        a = table2array(E(:,i));
        matHASclk_comp(:,i) = (a);

    end

    clear a
    clear D
    clear E

    [matHASorb,matHASclk] = divisione_HAS (matHASorb_comp,matHASclk_comp,costellazione);
    
    matHASorb = string(matHASorb);
    matHASclk = string(matHASclk);

    clear matHASorb_comp
    clear matHASclk_comp

    %% BRDM 

    % Dati BRDM presi dalla cartella ...input\brdm, in questa cartella i file sono già spacchettati per costellazione

    % Caricamento del file contenente le efemeridi BROADCAST per tutti i 
    % satelliti della costellazione nel DoY 

    DoY_2 = DoY-1;
    
    % Galileo

    % è importante che brdm186gal.22p sia sempre presente nella directory
    % BRDM\ref
    
    if costellazione == 2

        opt = detectImportOptions('C:\multiGNSS_v3\HAS\BRDM\ref\brdm1860gal.22p', 'FileType','fixedWidth', 'VariableNamesLine',1,'VariableNamingRule','preserve', 'ExpectedNumVariables',36);
    
        if DoY < 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY),'0gal.',num2str(YR),'p');
          
            F = readtable(filename,opt);
        
        end
    
        if DoY > 100 || DoY == 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY),'0gal.',num2str(YR),'p');

            F = readtable(filename,opt);

        end
        
        if DoY_2 < 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY_2),'0gal.',num2str(YR),'p');

            G = readtable(filename,opt);
            
        end
        
        if DoY_2 > 100 || DoY_2 == 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY_2),'0gal.',num2str(YR),'p');

            G = readtable(filename,opt);

        end

        clear DoY_2
        clear filename1

        mat = cell(height(F),width(F));
        mat_i = cell(height(G),width(G));

        for i = 1:width(F)

            a = table2array(F(:,i));   
            mat(:,i) = num2cell(a);
            
        end

        for i = 1:width(G)

            b = table2array(G(:,i));
            mat_i(:,i) = num2cell(b);

        end

        clear F
        clear G
        clear a
        clear b
        clear i
            
    end

    % GPS

    if costellazione == 0
    
        if DoY < 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY),'0gps.',num2str(YR),'p');
          
            F = readtable(filename,'FileType','text');
            
        end
    
        if DoY > 100 || DoY == 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY),'0gps.',num2str(YR),'p');
         
            F = readtable(filename,'FileType','text');
            
        end
        
        if DoY_2 < 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm0',num2str(DoY_2),'0gps.',num2str(YR),'p');
    
            G = readtable(filename,'FileType','text');
            
        end
        
        if DoY_2 > 100 || DoY_2 == 100

            filename = strcat('C:\multiGNSS_v3\input\brdm\brdm',num2str(DoY_2),'0gps.',num2str(YR),'p');
    
            G = readtable(filename,'FileType','text');
            
        end

        clear DoY_2
        clear filename1

        mat = cell(height(F),width(F));
        mat_i = cell(height(G),width(G));

        for i = 1:width(F)

            a = table2array(F(:,i));   
            mat(:,i) = num2cell(a);
            
        end

        for i = 1:width(G)

            b = table2array(G(:,i));
            mat_i(:,i) = num2cell(b);

        end

        clear F
        clear G
        clear a
        clear b
       
    end

    %% Verifica dei satelliti della costellazione per cui sono disponibili i 
    % dati SP3 alle ore 00:00:00 del DoY

    if costellazione == 2

        SAT_ID = ["PE01","PE02","PE03","PE04","PE05","PE06","PE07","PE08","PE09","PE10","PE11","PE12","PE13","PE14","PE15","PE16","PE17","PE18","PE19","PE20","PE21","PE22","PE23","PE24","PE25","PE26","PE27","PE28","PE29","PE30","PE31","PE32","PE33","PE34","PE35","PE36"];

    end

    if costellazione == 0

        SAT_ID = ["PG01","PG02","PG03","PG04","PG05","PG06","PG07","PG08","PG09","PG10","PG11","PG12","PG13","PG14","PG15","PG16","PG17","PG18","PG19","PG20","PG21","PG22","PG23","PG24","PG25","PG26","PG27","PG28","PG29","PG30","PG31","PG32","PG33","PG34","PG35","PG36"];

    end

    SAT_v = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36];

    a = matsp3_i(:,1);

    found_i = [];

    for i = 1:length(a)

            if matsp3_i(i,1) == SAT_ID(1)

                found_i = i;
                break

            end

    end

    if isempty(found_i)

        for i = 1:length(a)

            if matsp3_i(i,1) == SAT_ID(2)

                found_i = i;
                break

            end

        end

    end

    if isempty(found_i)

        for i = 1:length(a)

            if matsp3_i(i,1) == SAT_ID(3)

                found_i = i;
                break

            end

        end

    end

    if isempty(found_i)

        for i = 1:length(a)

            if matsp3_i(i,1) == SAT_ID(4)

                found_i = i;
                break

            end

        end

    end

    for g = 1:length(SAT_ID)

        for i = 1:height(matsp3_i)

            if matsp3_i(i,1) == SAT_ID(g)

                found_f = i;
                break

            end

        end

    end

    sp3_disp = string(matsp3_i(found_i:found_f,1));

    clear found_f
    clear found_i
    clear g

    for i = 1:length(sp3_disp)

        for j = 1:length(SAT_v)

            if sp3_disp(i) == SAT_ID(j)

               sp3_disp_v(i) = SAT_v(j);

            end

        end

    end

    % sp3_disp_v(i) vettore con i satelliti per cui sono disponibili i dati
    % sp3 alle ore 00:00:00 del DoY
    
    %% Verifica dei satelliti per cui sono disponibili le efemeridi BROADCAST 
    % alle ore 00:00:00 del DoY
    
    if costellazione == 2
    
        SAT_ID = ["E01","E02","E03","E04","E05","E06","E07","E08","E09","E10","E11","E12","E13","E14","E15","E16","E17","E18","E19","E20","E21","E22","E23","E24","E25","E26","E27","E28","E29","E30","E31","E32","E33","E34","E35","E36"];
    
    end
    
    if costellazione == 0
    
        SAT_ID = ["G01","G02","G03","G04","G05","G06","G07","G08","G09","G10","G11","G12","G13","G14","G15","G16","G17","G18","G19","G20","G21","G22","G23","G24","G25","G26","G27","G28","G29","G30","G31","G32","G33","G34","G35","G36"];
    
    end

    SAT_v = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36];
    
    q = 1;
    
    for i = 1:height(mat)
    
       for j = 1:length(SAT_ID) 
    
           if string(mat(i,1)) == SAT_ID(j) 
               
              brdm_disp_vet(q) = SAT_v(j);
              q = q+1;
              break
               
           end
           
       end
        
    end
    
    clear SAT_v
    clear SAT_ID
    clear SAT_ID_num
    
    a = brdm_disp_vet(1);
    q = 2;
    brdm_disp_v = [];
    brdm_disp_v(1) = brdm_disp_vet(1);
    
    for i = 1:length(brdm_disp_vet)
        
        if brdm_disp_vet(i) > a 
            
            brdm_disp_v(q) = brdm_disp_vet(i); 
            q = q+1;
            a = brdm_disp_vet(i);
            
        end
        
    end
    
    clear brdm_disp_vet
    clear a
    clear q

    % brdm_disp_v(i) vettore con i satelliti per cui sono disponibili i dati
    % BRDM alle ore 00:00:00 del DoY

    %% Verifica dei satelliti per cui sono disponibili le correzioni HAS 
    % orbitali e del clock per il DoY, il cui valore sia diversa da 'nan'
    
    HAS_disp_vet = str2double(matHASorb(:,8));
    
    a = (HAS_disp_vet(1));
    
    HAS_disp_ve = [];
    HAS_disp_ve(1) = a;
    q = 2;
    
    for i = 1:length(HAS_disp_vet)
        
        if (HAS_disp_vet(i)) > a
            
            HAS_disp_ve(q) = HAS_disp_vet(i);
            a = (HAS_disp_vet(i));
            q = q+1;
    
        end
        
    end
    
    clear HAS_disp_vet
    clear a
    
    controllo = 'nan';
    q = 1;
    HAS_disp_v = [];
    
    for i = 1:length(HAS_disp_ve)
    
        if matHASorb(i,9) == controllo
            
        else
            
            HAS_disp_v(q) = HAS_disp_ve(i);
            q = q+1;
            
        end
        
    end
    
    clear q
    clear HAS_disp_ve
    clear controllo

    % HAS_disp_v(i) vettore con i satelliti per cui sono disponibili i dati
    % HAS alle ore 00:00:00 del DoY
    
    % Creazione di un vettore con i satelliti per cui sono disponibili:
    % HAS, BRDM

    a = intersect(HAS_disp_v,brdm_disp_v);
    SAT_disponibili = intersect(a,sp3_disp_v);
    
end

