%% gave up because matlab is being dumb and randomly reading in some columns as cells. 

% this is to do ivim without  needing xml. just reading from excel 
%based off of wha was done for R2*

% mira sept 2023

% also done for arthi interobserver analysis
function AllVoxelsDecay_total = ReadPatientDWIData_Lesion(varargin)

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


    %{
    % for original baseline
    pathtodata = '/Users/miraliu/Desktop/Data/ML_PartialNephrectomy_Export/';
    pathtoCSV = [pathtodata '/' PatientNum '/' PatientNum '_Scan1.csv'];

    
    % for interobserver
    %pathtodata = '/Users/miraliu/Desktop/Data/Arthi Test ROIs/';
    %pathtoCSV = [pathtodata PatientNum '_Arthi_IVIM.csv'];
    %}

    disp('for test-retest')
    %for test-retest
    pathtodata = '/Users/miraliu/Desktop/Data/PartialNephrectomy_TestRetest/';
    pathtoCSV = [pathtodata '/P004_IVIM_Scan1_test.csv']


    %ROItype = string(PatientNum) + '_' + string(ROItypes)

    ROItype = string(ROItypes); %just whatever ROI has the term 'lesion' in it
    
    %read data
    DataFrame = readtable(pathtoCSV,'PreserveVariableNames', true, 'Range','A:end','Delimiter', ',');    
    ROITypeTable = DataFrame(contains(DataFrame.RoiName, ROItype),:);

    totalslices = nnz(~ROITypeTable.Dynamic); %the number of zeros (i.e. slices)
    slices = unique(ROITypeTable.ImageNo);
    
    if ROITypeTable.Dynamic(1:totalslices:end) == [0;1;2;3;4;5;6;7;8]
        count = 0;
        for slice = 1:length(slices)
            ROITypeTablesub = ROITypeTable(ismember(ROITypeTable.ImageNo, slices(slice)),:); %this will get all lesion on slice, 
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
                AllVoxelsDecay_total = [AllVoxelsDecay_total, AllVoxelsDecay]; %creating one long list of 12 x N, 
            end
            %AllVoxelsDecay = AllVoxelsDecay(:,any(~cellfun('isempty',AllVoxelsDecay),1)); %remove all empty columns
            count = count + 1;
            size(AllVoxelsDecay_total);
           % AllVoxelsDecay = AllVoxelsDecay(:,any(~cellfun(@isnan,AllVoxelsDecay,'UniformOutput',false),1)); %remove all NAN columns
        end
    end

end