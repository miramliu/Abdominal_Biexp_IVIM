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
        ADCfit=polyfit(bvalues(bvalues>100),log(currcurve(bvalues>100)),1);
       
        %goodness of ADC fit
        curveADC=currcurve(bvalues>100);
        ADCf=curveADC(1)*exp(-bvalues(bvalues>100).*abs(ADCfit(1)));
        yresidADC=curveADC'-ADCf;
        SSresidADC=sum(yresidADC.^2);
        SStotalADC = (length(curveADC)-1) * var(curveADC);
        rsqADC = 1 - SSresidADC/SStotalADC;

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
                        mean(ADCvalues), median(ADCvalues), std(ADCvalues), kurtosis(ADCvalues), skewness(ADCvalues)};
                
    %{
    %pathtodata = '/Users/miraliu/Desktop/Data/PartialNephrectomy_fit_IVIM';
    %ExcelFileName=[pathtodata, '/','PN_IVIM_fit.xlsx']; % All results will save in excel file

    % voxel wise kidney baseline
    %pathtodata = '/Users/miraliu/Desktop/Data/ML_PartialNephrectomy_Export';
    %ExcelFileName=[pathtodata, '/','PN_IVIM_RigidBiexponential.xlsx']; % All results will save in excel file

    % interobserver
    pathtodata = '/Users/miraliu/Desktop/Data/Arthi Test ROIs';
    ExcelFileName=[pathtodata, '/','PN_Arthi_IVIM_RigidBiexponential.xlsx']; % All results will save in excel file


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

    % for test-retest
    disp('saving test-retest')
    pathtodata = '/Users/miraliu/Desktop/Data/PartialNephrectomy_TestRetest/';
    ExcelFileName=[pathtodata, '/','PN_TestRetesting.xlsx']; % All results will save in excel file


    %Patient ID	ROI Type	mean	stdev	median	skew	kurtosis	size n

    Identifying_Info = {['PN_' PatientNum], 'IVIM_retest', [PatientNum '_' ROItype]}
    Existing_Data = readcell(ExcelFileName,'Range','A:C','Sheet','Voxelwise bi-IVIM'); %read only identifying info that already exists
    MatchFunc = @(A,B)cellfun(@isequal,A,B);
    idx = cellfun(@(Existing_Data)all(MatchFunc(Identifying_Info,Existing_Data)),num2cell(Existing_Data,2));

    if sum(idx)==0
        disp('saving data in excel')
        Export_Cell = [Identifying_Info,dataarray];
        writecell(Export_Cell,ExcelFileName,'WriteMode','append','Sheet','Voxelwise bi-IVIM')
    end
    

   % save(['/Users/miraliu/Desktop/Data/PartialNephrectomy_T2Star/' 'PN_' PatientNumber '_IVIM_fit.mat'],"IVIM_Map")

end

