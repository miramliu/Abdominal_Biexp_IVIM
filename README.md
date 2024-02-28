# Abdominal_Biexp_IVIM
 Code for abdominal IVIM using the bi-exponential bayesian fit from Octavia Bane. Assumes exported ROI data from Horos. Currently run in kidney, can be adapted to Liver

# Exporting from Horos
1. Open the IVIM images as a 4D stack 
2. Import the ROIs wanted (check placement and labelling for correctness and consistency)
3. Export the ROIs under Plugins > ROI Tools > Export Voxels
4. Save as CSV file with a title that includes patient identifier (you can edit and choose the naming pattern you want, just has to be standardized)
5. Note: This must be done for every patient, so all patients should have on large CSV file with all of the data. (all b-values, all ROIs, all slices)




# Read from all export files 
1. ReadPatientDWIData_voxelwise(PatientNum, ROInameRequirements, RoiNumbering) 
- This is code that will read in a specific patient's CSV file, get the ROIs types of interest, and all of those ROIs. 
- e.g. For case P001, wanting a left kidney, all poles, medulla (LK_LP_M), and you know there are two of them (LK_LP_M1 & LK_LP_M2) you could run: 
>> medulregL = regexp(RoiTypes, '^L.*.M$','match'); medulregL = medulregL(~cellfun('isempty',medulregL));
>> ReadPatientDWIData_voxelwise(PatientNum, medulregL, 12) 



Run 

>> RigidBiexp_Anatomic_voxelwise('P001', 'LK)