%% get bi-exponential fit of ivim from anatomic kidneys

%now voxelwise

% based on Anatomic_Voxelwise but for renal allograft now (only 1 kidney,
% no left or right)

% Mira Nov 2023
function RA_BayesianBiexp_IVIM(varargin)
    %PatientNum = ['RA_01_'  varargin{1}]; % for MS data
    PatientNum = ['RA_02_'  varargin{1}]; % for cornell data
    if nargin == 1 || nargin == 2 && varargin{2} > 10
       
        RoiTypes = {'LP_C','LP_M','MP_C','MP_M','UP_C','UP_M'};
        medulreg = regexp(RoiTypes, '^.*.M$','match'); medulreg = medulreg(~cellfun('isempty',medulreg));
        cortreg = regexp(RoiTypes, '^.*.C$','match'); cortreg = cortreg(~cellfun('isempty',cortreg)); 

        if nargin == 2
            ab = varargin{2};
        else
            ab = 12; %expect only 1,2
        end

        % get average medullar ROI
        SignalInput = ReadPatientDWIData_voxelwise(PatientNum, medulreg, ab); 
        %fit that and save it
        RunandSaveIVIM(PatientNum,'M',SignalInput)
        % get average cortical ROI
        SignalInput = ReadPatientDWIData_voxelwise(PatientNum, cortreg, ab); 
        %fit that and save it
        RunandSaveIVIM(PatientNum,'C',SignalInput)
    else
        error('incorrect input')
    end
end


%% gave up because matlab is being dumb and randomly reading in some columns as cells. 

% this is to do ivim without  needing xml. just reading from excel 
%based off of wha was done for R2*

% mira sept 2023

% also done for arthi interobserver analysis
function AllVoxelsDecay_total = ReadPatientDWIData_voxelwise(varargin)

    if nargin == 2
        PatientNum = varargin{1} ;
        ROItypes = varargin{2};
        a = 1; b = 4; %if there are 1 - 4 ROI (so C1 - C4 for example)
    elseif nargin ==3
        PatientNum = varargin{1} ;
        ROItypes = varargin{2};
        if varargin{3} == 12
            a = 1; b = 2; %if only 1-2 ROIs per type (so C1-C2 for example)
        elseif varargin{3} == 34
            a = 3; b = 4; %if only 3-4 ROIs per type (so C3 - C4)
        elseif varargin{3} == 14
            a = 1; b = 4;
        end
    end


    
    % for Renal Allograft baseline
    pathtodata = '/Users/miraliu/Desktop/Data/RA/RenalAllograft_IVIM/';
    pathtoCSV = [pathtodata '/' PatientNum '_IVIM.csv'];

    
    %% for each type, this is Poles
    count = 0;
    for type = 1:size(ROItypes,2)
        ROItype = string(PatientNum) + '_' + string(ROItypes{1,type});
        %read data
        DataFrame = readtable(pathtoCSV,'PreserveVariableNames', true, 'Range','A:end','Delimiter', ',');    
        ROITypeTable = DataFrame(startsWith(DataFrame.RoiName, ROItype),:);
        %size(ROITypeTable)
        %% for ecah of the slices of these poles
        %average all four ROIs for analysis (CHECK IF I SHOULD DO THIS)
        for k = a:b %for each of the 4 ROIs of every type (%%CHECK!!!!!!)
            ROITypeTablesub = ROITypeTable(strcmp(ROITypeTable.RoiName, ROItype + string(k)),:); %so for example you want LK_LP_C, will check LK_LP_C1, LK_LP_C2 etc.
            ROITypeTablesub = sortrows(ROITypeTablesub,'Dynamic'); %order them according to dynamic, and get the mean from that
            %SignalInput =  SignalInput + ROITypeTablesub.RoiMean;
            %AllVoxelsDecay = table2cell(ROITypeTablesub(1:end,13:end));
            AllVoxelsDecay = ROITypeTablesub(1:end,13:end);
            AllVoxelsDecay = rmmissing(AllVoxelsDecay,2);

            % really shit because matlab does not read this correctly. will
            % slow down a lot just because matlab performs poorly. 
            myvarnames = AllVoxelsDecay.Properties.VariableNames;
            for ii = 1:size(myvarnames,2)
                %AllVoxelsDecay.(myvarnames{ii});
                if iscell(AllVoxelsDecay.(myvarnames{ii}))
                    % If your table variable contains strings then we will have a cell
                    % array. If it's numeric data it will just be in a numeric array
                    AllVoxelsDecay.(myvarnames{ii}) = str2double(AllVoxelsDecay.(myvarnames{ii}));
                end
            end
            AllVoxelsDecay;

            % now convert to an array
            AllVoxelsDecay = table2array(AllVoxelsDecay);
            if count == 0
                AllVoxelsDecay_total = AllVoxelsDecay;
            else
                AllVoxelsDecay_total = [AllVoxelsDecay_total, AllVoxelsDecay]; %creating one long list of 12 x N, for N voxels
            end
            %AllVoxelsDecay = AllVoxelsDecay(:,any(~cellfun('isempty',AllVoxelsDecay),1)); %remove all empty columns
            count = count + 1;
            size(AllVoxelsDecay_total);
           % AllVoxelsDecay = AllVoxelsDecay(:,any(~cellfun(@isnan,AllVoxelsDecay,'UniformOutput',false),1)); %remove all NAN columns
        end
    end
end


function RunandSaveIVIM(PatientNum, ROItype,SignalInput)

%% saving and running on signal input
    disp([PatientNum '_' ROItype])
    %% trying tri-exponential!
    
    fvalues = zeros(size(SignalInput,2),1);
    Dsvalues = zeros(size(SignalInput,2),1);
    Dvalues = zeros(size(SignalInput,2),1);
    ADCvalues = zeros(size(SignalInput,2),1);
    bvalues = [0,10,30,50,80,120,200,400,800];
    for voxelj = 1:size(SignalInput,2)
        
        currcurve = squeeze(double(SignalInput(:,voxelj))); %get signal from particular voxel for all images along z axis
        currcurve = currcurve(:)/currcurve(1);
        [MMSE,~,~,~,~,~,~,~,~,~,~,~]=IVIMBayesianEstimation(bvalues,currcurve);
      
        %goodness of ADC fit
        curveADC=currcurve(bvalues>100);
        curveADC = curveADC(:)/curveADC(1); %normalize
        ADCfit=polyfit(bvalues(bvalues>100),log(curveADC),1);
       
        %goodness of ADC fit
        ADCf=curveADC(1)*exp(-bvalues(bvalues>100).*abs(ADCfit(1)));
        yresidADC=curveADC'-ADCf;
        SSresidADC=sum(yresidADC.^2);
        SStotalADC = (length(curveADC)-1) * var(curveADC);
        rsqADC = 1 - SSresidADC/SStotalADC;

        %{
        scatter(bvalues(bvalues>100), curveADC)
        hold on;
        plot(bvalues(bvalues>100), ADCf)
        pause()
        hold off;
        

        scatter(bvalues, currcurve)
        hold on;
        IVIMfit = MMSE.f*exp(-bvalues*MMSE.Ds) + (1-MMSE.f)*exp(-bvalues*MMSE.D);
        plot(bvalues, IVIMfit)
        pause()
        hold off;
        %}

        if rsqADC >.7
            ADCvalues(voxelj,1) = 1000000*abs(ADCfit(1));
        else
            ADCvalues(voxelj,1) = NaN;
        end

        %fit curve from IVIM Bayesian
        curveFit=currcurve(1)*(exp(-MMSE.Ds.*bvalues)*MMSE.f+exp(-MMSE.D.*bvalues)*(1-MMSE.f));
        yresid = minus(currcurve' ,curveFit);
        SSresid = sum(yresid.^2);
        SStotal = (length(currcurve)-1) * var(currcurve);
        rsq = 1 - SSresid/SStotal;
        %MMSE
        % code that constrains writing the map only if rsq>0.7
        if rsq>0.7
            Dvalues(voxelj,1)=1000000*MMSE.D;
            Dsvalues(voxelj,1)=1000000*MMSE.Ds;
            fvalues(voxelj,1)=100*MMSE.f;
        else
            Dvalues(voxelj,1)=NaN;
            Dsvalues(voxelj,1)=NaN;
            fvalues(voxelj,1)= NaN;
        end
    end

    %remove NaN before doing stats
    ADCvalues=ADCvalues(~isnan(ADCvalues));
    Dvalues=Dvalues(~isnan(Dvalues));
    Dsvalues=Dsvalues(~isnan(Dsvalues));
    fvalues=fvalues(~isnan(fvalues));

    dataarray={mean(Dvalues), median(Dvalues), std(Dvalues), kurtosis(Dvalues), skewness(Dvalues),...
                        mean(Dsvalues), median(Dsvalues), std(Dsvalues), kurtosis(Dsvalues), skewness(Dsvalues),...
                        mean(fvalues), median(fvalues), std(fvalues), kurtosis(fvalues), skewness(fvalues),...
                        mean(ADCvalues), median(ADCvalues), std(ADCvalues), kurtosis(ADCvalues), skewness(ADCvalues),...
                        size(Dsvalues,1),size(ADCvalues,1),size(SignalInput,2)}; % number of successful IVIM fits, number of successful aDC fits, number of initial voxels
                
    
    pathtodata = '/Users/miraliu/Desktop/Data/RA/RenalAllograft_IVIM';
    ExcelFileName=[pathtodata, '/','RA_biexponential_IVIM.xlsx']; % All results will save in excel file

   
    %Patient ID	ROI Type	mean	stdev	median	skew	kurtosis	size n

    Identifying_Info = {['PN_' PatientNum], [PatientNum '_' ROItype]};
    Existing_Data = readcell(ExcelFileName,'Range','A:B','Sheet','Voxelwise'); %read only identifying info that already exists
    MatchFunc = @(A,B)cellfun(@isequal,A,B);
    idx = cellfun(@(Existing_Data)all(MatchFunc(Identifying_Info,Existing_Data)),num2cell(Existing_Data,2));

    if sum(idx)==0
        disp('saving data in excel')
        Export_Cell = [Identifying_Info,dataarray];
        writecell(Export_Cell,ExcelFileName,'WriteMode','append','Sheet','Voxelwise')
    end


    %}

end

