setBatchMode(true);  //run in background for speed
run("Collect Garbage"); //free imagej memory
setOption("ExpandableArrays", true); //allow expandable arrays
print("\\Clear");  //clear log window
fs = File.separator; // To handle different OSs file systems
runError = processed = false;  //set flags for handling errors
FOVexist = false;
rawFileCount = 0;

//get file paths
inputPath = getDirectory("Please select the Folder which contains the scan data");    //Folder containing the scan images
parentPath = File.getParent(inputPath) + fs;  //Folder which contains the inputPath
outputPath = inputPath + "Processed" + fs;  //Output folder path to save well sub-folders into
print("input Path = " + inputPath);
print("output Path = " + outputPath);

//if the files have already been processed, set flag
if(File.exists(outputPath)){
	runError = true;
	processed = true;
}else{  //otherwise process files

	//dialog window to ask user if they wish to move of copy the files
	Dialog.createNonBlocking("Move/Copy Files");
	Dialog.addMessage("Would you like to Move or Copy the .tif files?");
	choice = newArray("Move","Copy");
	Dialog.setInsets(10, 80, 20);
	Dialog.addRadioButtonGroup("", choice, 1,0, "Move");
	Dialog.show();
	fileCopy = Dialog.getRadioButton();
	if(fileCopy == "Copy"){print("Copy Files to well sub-folders");}
	else{print("Move Files to well sub-folders");}
	startTime = getTime();  //time run
	
	//create empty arrays
	fileList = newArray();
	rawFiles = newArray();
	fullWellList = newArray();
		
	//get a list of well names including the field number
	fileList = getFileList(inputPath);  //create an array of unfiltered files in the inputPath
	fileList = Array.sort(fileList);  //sort files alphabetically
	wellPrefix = "_0_";  //search string to find the well name
	for (i = 0; i < fileList.length; i++) {  //check every file/folder
	    if(!File.isDirectory(inputPath + fileList[i])) { //if it's not a directory
			if((endsWith(fileList[i], ".TIF"))||(endsWith(fileList[i], ".tif"))) { //filter for .tif files
	    		if(fileList[i].matches(".*_.*R_.*")) { //Process only RAW files
	    			rawFileCount++;  //count number of RAW files
	    			rawFiles = Array.concat(rawFiles,fileList[i]);  //add RAW files to new array
	    			startPos = (indexOf(fileList[i], wellPrefix)+3); 
	    			fullWellName = substring(fileList[i], startPos, startPos+6);  //get the full well name including field number
	    			fullWellList = Array.concat(fullWellList,fullWellName);	//add full well name to new array
	    			if(fullWellName.matches(".*f01.*")) {  //if there are multiple fields in the well, set a flag for later processing
	    				FOVexist = true;
	    			}
				}
			}
		}
	}
	
	//find unique full well names for unfiltered list
	fullWellList = ArrayUnique(fullWellList);
	
	//tidy up folder names if theres only one FOV per well
	wellList = newArray();
	if(FOVexist == false){  //if there arent multiple FOVs/well, shorten the well name to remove the field number
		for (i = 0; i < fullWellList.length; i++) {
			wellList[i] = substring(fullWellList[i],0,3);
		}
		wellList = ArrayUnique(wellList);
	}else{ wellList = fullWellList;} //else leave the full well name including field number
	
	print("wells in experiment");
	Array.print(wellList);
	
	//create a folder for each well and copy files for that well in the matching folder
	if(rawFileCount > 0){  //if there are raw tif files to process
		print("Processing files...");
		File.makeDirectory(outputPath); //create processed folder
		for (i = 0; i < wellList.length; i++) { //for each well
			newFilePath = outputPath + wellList[i] + fs;  //create sub-folder path for well
			if(File.exists(newFilePath)){ //if the sub-folder already exists, set error flag
				print("sub-folder already exists, dont do anything");
				runError = true;
			}else {
				File.makeDirectory(newFilePath);  //make well subfolder
				for (j = 0; j < rawFiles.length; j++) {  //for all raw files
					searchString = ".*" + wellList[i] + ".*";  //create search string for this well
					if(rawFiles[j].matches(searchString)){  //if the file belongs to the well
						startPath = inputPath + rawFiles[j];  //get start path of file
						endPath = newFilePath + rawFiles[j];  //create end path of file
						if(fileCopy == "Copy"){
							File.copy(startPath, endPath);  //copy file to subfolder
						}else {
							File.rename(startPath, endPath);  //move file to subfolder
						}
					}
				}
			}
		}
	}else {
		runError = true;
	}
}


// function to find unique values in an array
function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}

setBatchMode(false);//disable batch mode to allow popups etc
if(runError == true){
	if(rawFileCount == 0 && processed == false){
		showMessage("Attention", "Sorry, Something went wrong\r\nThere are no .tif files to process");
	}if(processed == true) {
		showMessage("Attention", "Sorry, Something went wrong\r\nHas this folder already been processed?");
	}
}else {
	showMessage("Success", "Congratulations, your files have been processed in "+runTime+"s");
	runTime = ((getTime() - startTime)/1000);  //calculate runtime in secs
	print("run time = "+runTime);
}

exit;