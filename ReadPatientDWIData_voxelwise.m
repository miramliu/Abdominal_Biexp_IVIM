%% code to force matlab to read every line correctly 
% It's a bit time intensive and line-by-line because matlab would sometimes randomly reading
% in some columns as cells. Sorry.

% this is to do ivim without needing xml file. just reading from excel 

% mira sept 2023

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


    
    % for original baseline
    %pathtodata = '/Users/miraliu/Desktop/Data/ML_PartialNephrectomy_Export/';
    %pathtoCSV = [pathtodata '/' PatientNum '/' PatientNum '_Scan1.csv'];

    
%% for each type, this is kidney Poles
    count = 0;
    for type = 1:size(ROItypes,2)
        ROItype = string(PatientNum) + '_' + string(ROItypes{1,type});
        %read data
        DataFrame = readtable(pathtoCSV,'PreserveVariableNames', true, 'Range','A:end','Delimiter', ',');    
        ROITypeTable = DataFrame(startsWith(DataFrame.RoiName, ROItype),:);
        %size(ROITypeTable)
        %% for ecah of the slices of these poles
        %average all four ROIs for analysis 
        for k = a:b %for each of the 4 ROIs of every type 
            ROITypeTablesub = ROITypeTable(strcmp(ROITypeTable.RoiName, ROItype + string(k)),:); %so for example you want LK_LP_C, will check LK_LP_C1, LK_LP_C2 etc.
            ROITypeTablesub = sortrows(ROITypeTablesub,'Dynamic'); %order them according to dynamic, and get the mean from that
            %SignalInput =  SignalInput + ROITypeTablesub.RoiMean;
            %AllVoxelsDecay = table2cell(ROITypeTablesub(1:end,13:end));
            AllVoxelsDecay = ROITypeTablesub(1:end,13:end);
            AllVoxelsDecay = rmmissing(AllVoxelsDecay,2);

            % really frustrating  matlab does not read this correctly. will
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