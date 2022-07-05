setBatchMode(true);  //run in background for speed
run("Collect Garbage"); //free imagej memory
setOption("ExpandableArrays", true); //allow expandable arrays
print("\\Clear");  //clear log window
print("ImageJ script to sort EVOS .tif files into well sub-folders, then convert to Hyperstacks");
fs = File.separator; // To handle different OSs file systems
runError = processed = false;  //set flags for handling errors
FOVexist = false;
rawFileCount = 0;

//get file paths
inputPath = getDirectory("Please select the Folder which contains the scan data");    //Folder containing the scan images
parentPath = File.getParent(inputPath) + fs;  //Folder which contains the inputPath
processedPath = inputPath + "Sorted-Images" + fs;  //Output folder path to save well sub-folders into
print("input Path = " + inputPath);
print("output Path = " + processedPath);

//if the files have already been processed, set flag
if(File.exists(processedPath)){
	runError = true;
	processed = true;
}
else{  //otherwise process files
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
	print("Sorting EVOS .tif files...");
	
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
	
	print("Wells in experiment");
	Array.print(wellList);
	
	//create a folder for each well and copy files for that well in the matching folder
	if(rawFileCount > 0){  //if there are raw tif files to process
		if(fileCopy == "Copy"){print("Copying and sorting files...");}else{print("Moving and sorting files...");}
		File.makeDirectory(processedPath); //create processed folder
		for (i = 0; i < wellList.length; i++) { //for each well
			newFilePath = processedPath + wellList[i] + fs;  //create sub-folder path for well
			if(File.exists(newFilePath)){ //if the sub-folder already exists, set error flag
				print("sub-folder already exists, dont do anything");
				runError = true;
				break;
			}else {
				File.makeDirectory(newFilePath);  //make well subfolder
				print("Sorting files into well " + newFilePath);
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
		runTime = ((getTime() - startTime)/1000);  //calculate runtime in secs
		print("EVOS .tif files have been successfully sorted in " + runTime + "s");
	}else {
		runError = true;
	}
}

//Convert images to hyperstacks
run("Collect Garbage");  //free imagej memory
inputPath = processedPath;    //path to well sub-folders
parentPath = File.getParent(inputPath) + fs;
outputPath = parentPath + "Hyperstacks" + fs;  //Output folder path
if(!File.exists(outputPath)){  //if the hyperstacks havent already been generated
	if(runError == false){  //if the files were sorted successfully
		//Convert .tif files to hyperstacks
		File.makeDirectory(outputPath); //create output folder for hyperstacks
		print("EVOS Converter is Running...");
		processFolder(inputPath,outputPath);  //Process images using function
		close("*"); //close all open windows
	}
}else{
	print("Hyperstacks have already been generated");
	processed = true;
	runError = true;
}


// declare Functions
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

//Function to process the images into Hyperstacks
function processFolder(input, output) {
    fileList = getFileList(input);
    fileList = Array.sort(fileList);  //sort alphabetically
    for (i = 0; i < fileList.length; i++) {  //check every file/folder
        if(File.isDirectory(input + fileList[i]))   //if it's a directory
        	folderNameLength = (lengthOf(fileList[i])-1);  // get the directories name length without the "/"
        	folderName = substring(fileList[i], 0, folderNameLength); //remove the "/" from the end of it's name
			wellPath = input + folderName + fs; //create well path to check for files to process
			wellFileList = getFileList(wellPath);	//get list of files in the well folder	
			wellFileList = Array.sort(wellFileList); //sort names alphabetically	
			wellFileCount = tifFileCount = channelCount = zCount = 0;  //reset counters
			channelNumberArray = newArray();
			wellFileCount = wellFileList.length;  //get total number of files in the folder

			for(j = 0; j < wellFileCount; j++) { //for every file
				if ((endsWith(wellFileList[j], ".TIF"))||(endsWith(wellFileList[j], ".tif"))){ //filter for .tif files
					tifFileCount++;  //count the number of .tif files
					if(wellFileList[j].matches(".*_p00_.*")){ //if the file is from timepoint zero
						if(wellFileList[j].matches(".*_z.*_.*")){ //if there are z slices
							zCount++; //count number of z slices
							if(wellFileList[j].matches(".*_z00_.*")){
								channelCount++; //channel number = count number of filenames with p00
							}
						}else {
							// no z slices
							channelCount++; //channel number = count number of filenames with p00
						}
						channelPos = (lengthOf(wellFileList[j]) - 5); 
						channelNumber = substring(wellFileList[j], channelPos, channelPos+1); //get the channel number from filename
						channelNumberArray[channelCount-1] = channelNumber;  //store channel number in array for use later
					}
				}			
			}

			//timepoint number = total number of files/channel number
			if(zCount > 1){
				zCount = zCount/channelCount;
				timePoints = tifFileCount/channelCount/zCount;
			}else{
				zCount = 1;
				timePoints = tifFileCount/channelCount; 
			}	
			
			a = "Converting Well "+folderName;
			b = "total stack size = "+tifFileCount;
			c = "Channels = "+channelCount;
			d = "Z Slices = "+zCount;
			e = "Timepoints = "+timePoints;
			print(a + " : " + b + ", " + c + ", " + d + ", " + e);
			
			//import images into a stack
			File.openSequence(wellPath, "count="+tifFileCount+",sort");

			//Create a Hyperstack
			if(nSlices == tifFileCount){  //if the files all imported correctly
				run("Stack to Hyperstack...", "order=xyczt(default) channels=" + channelCount + " slices=" + zCount + " frames=" + timePoints + " display=Color");
				
				//False colour the Hyperstack channels
				for(k=1;k<=channelCount;k++){
					setColours(k,channelNumberArray[k-1]);
				}
				
				//adjust pixel size
				getPixelSize(unit, pw, ph, pd);
				if(unit == "inches"){
					xSize = pw*25400;
					ySize = ph*25400;
					zSize = pd*25400;
					Stack.setXUnit("micron");
					Stack.setYUnit("micron");
					Stack.setZUnit("micron");
					run("Properties...", "pixel_width=" + xSize + " pixel_height=" + ySize + " voxel_depth=" + zSize);
				}
			}

			// save hyperstack to common output folder and close window	
			saveAs("Tiff", outputPath + "/" + folderName + ".tif");
			close();
			run("Collect Garbage");
    }
}

//set channel colours
function setColours(Channel, Colour){
	Stack.setChannel(Channel);
	if(Colour == 0) run("Blue");
	if(Colour == 1) run("Green");
	if(Colour == 2) run("Red");
	if(Colour == 3) run("Magenta");
	if(Colour == 4) run("Grays");		
}

//Finish script
setBatchMode(false);//disable batch mode to allow popups etc
if(runError == true){
	if(rawFileCount == 0 && processed == false){
		showMessage("Attention", "Sorry, Something went wrong\r\nThere are no .tif files to process");
	}if(processed == true) {
		showMessage("Attention", "Sorry, Something went wrong\r\nHas this folder already been processed?");
	}
}else {
	runTime = ((getTime() - startTime)/1000);  //calculate runtime in secs
	print("Congratulations, your files have been processed in "+runTime+"s");
	showMessage("Success", "Congratulations, your files have been processed in "+runTime+"s");
}
print("Script has finished");
exit;
