# Abdominal_Biexp_IVIM
Code for abdominal IVIM using the bi-exponential bayesian fit from Octavia Bane. Assumes exported ROI data from Horos. Currently run in kidney, can be adapted to Liver
Mira Liu 2024


# Exporting from Horos
1. Open the IVIM images as a 4D stack 
2. Import the ROIs wanted (check placement and labelling for correctness and consistency)
3. Export the ROIs under Plugins > ROI Tools > Export Voxels
4. Save as CSV file with a title that includes patient identifier (you can edit and choose the naming pattern you want, just has to be standardized)
5. Note: This must be done for every patient, so all patients should have on large CSV file with all of the data. (all b-values, all ROIs, all slices)




# Read from all export files 
This is done in ReadPatientDWIData_voxelwise(PatientNum, ROInameRequirements, RoiNumbering) 
- This is code that will read in a specific patient's CSV file, get the ROIs types of interest, and all of the diffusion decay signal from those ROIs. 
- e.g. For case P001, wanting a left kidney, all poles, medulla (LK_LP_M), and you know there are two of them per pole (e.g. LK_LP_M1 & LK_LP_M2) you could run: 

>> medulregL = regexp(RoiTypes, '^L.*.M$','match'); medulregL = medulregL(~cellfun('isempty',medulregL));
>> ReadPatientDWIData_voxelwise(PatientNum, medulregL, 12) 

- If you're just looking at a lesion, it will be much simpler. Can likely just edit it to read in whatever the lesion ROI is labelled as in the CSV files: 
>> ReadPatientDWIData_voxelwise(PatientNum, 'lesionROIname') 

- It will then read in all of the decay data for the ROIs that you requested (so for lesionROIname, if there are 100 voxels in the lesion ROI it will read in all 100 diffusion decay signals
- It will export them as an array. So for 9bvalues 100 voxels, it will export a 9x100 array for post-processing

# Post-process and save
This is done with RunandSaveIVIM(PatientNum, ROItype, signalcurves)
- It reads in the array and line-by-line performs bayesian bi-exponential estimation 
- Note for liver you may change line 33 in IVIMBayesianEstimation.m to 'liver' from 'kidney'. It will change the assumptions. 
- Also please doublecheck that the b-values (line 14 in RunandSaveIVIM) you are assuming do match the b-values of the sequence. There is not a standardized method yet, so they may vary by sequence. 
- The histogram features will then export to one single excel file added as a new line. 
- This code does NOT save data as a map. Only exported features. Can adjust code though if you'd like that. 
- This code does not save voxel-by-voxel data as it would be massive, but you can write them as 3D volumes of parameters (I've done that before)




# Run one case
>> RigidBiexp_Anatomic_voxelwise('P001')
- see RunAllKidneyProcessing.m for an example of just running all of them at once and leaving it on in the background once it's all set up!


