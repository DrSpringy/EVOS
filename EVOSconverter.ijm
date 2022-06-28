setBatchMode(true);
run("Collect Garbage");
setOption("ExpandableArrays", true); //allow expandable arrays
fs = File.separator; // To handle different OSs file systems
parentPath = getDirectory("Please select the Topmost Folder");    //top level directory
inputPath = parentPath + "Processed" + fs;  //Input folder path
outputPath = parentPath + formatTime() + "_" + "Hyperstacks" + fs;  //Output folder path
File.makeDirectory(outputPath); //create output folder for hyperstacks
processFolder(inputPath,outputPath);  //Process images using function
close("*"); //close all open windows

//Function to process the images into Hyperstacks
function processFolder(input, output) {
    fileList = getFileList(input);
    for (i = 0; i < fileList.length; i++) {  //check every file/folder
        if(File.isDirectory(input + fileList[i]))   //if it's a directory
        	folderNameLength = lengthOf(fileList[i])-1;  // get the directories name length
        	folderName = substring(fileList[i], 0, folderNameLength); //remove the "/" from the end of it's name

			wellPath = input + folderName + fs; //create well path to check for files to process
			wellFileList = getFileList(wellPath);	//get list of files in the well folder			
			
			wellFileCount = tifFileCount = channelCount = 0;  //reset counters
			channelNumberArray = newArray();
			wellFileCount = wellFileList.length;  //get total number of files in the folder
			for(j = 0; j < wellFileCount; j++) { //for every file
				if ((endsWith(wellFileList[j], ".TIF"))||(endsWith(wellFileList[j], ".tif"))){ //filter for .tif files
					tifFileCount++;  //count the number of .tif files
					if(wellFileList[j].matches(".*_p00_.*")){ //if the file is from timepoint zero
						channelCount++; //channel number = count number of filenames with p00
						channelPos = lengthOf(wellFileList[j]) - 5; 
						channelNumber = substring(wellFileList[j], channelPos, channelPos+1); //get the channel number from filename
						channelNumberArray[channelCount-1] = channelNumber;  //store channel number in array for use later

					}
				}			
			}
			
			timePoints = tifFileCount/channelCount; //timepoint number = total number of files/channel number
			
			//import images into a stack
			File.openSequence(wellPath, "count="+tifFileCount+",sort");

			//Create a Hyperstack
			if(nSlices == tifFileCount){  //if the files all imported correctly
				run("Stack to Hyperstack...", "order=xyczt(default) channels=" + channelCount + " slices=1 frames=" + timePoints + " display=Color");
				
				//False colour the Hyperstack channels
				for(i=1;i<=channelCount;i++){
					setColours(i,channelNumberArray[i-1]);
				}
			}

			// save hyperstack to common output folder and close window	
			saveAs("Tiff", outputPath + "/" + folderName + ".tif");
			close();
			run("Collect Garbage");
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

function formatTime(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	dt = "" + year + "_" + month + "_" + dayOfMonth + "_" + hour + "_" + minute + "_" + second;
	return dt;
}

setBatchMode(0); //disable batch mode to allow popups etc
showMessage("Finished", "Congratulations, your files have been processed"); //show message