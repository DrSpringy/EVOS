setBatchMode(true);  //run in background for speed
run("Collect Garbage");  //free imagej memory
setOption("ExpandableArrays", true); //allow expandable arrays
fs = File.separator; // To handle different OSs file systems
inputPath = getDirectory("Please select the 'Processed' Folder");    //top level directory
parentPath = File.getParent(inputPath) + fs;
outputPath = parentPath + formatTime() + "_" + "Hyperstacks" + fs;  //Output folder path
File.makeDirectory(outputPath); //create output folder for hyperstacks
print("\\Clear");  //clear log window
print("EVOS Converter is Running");
startTime = getTime();  //time run
processFolder(inputPath,outputPath);  //Process images using function
close("*"); //close all open windows

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
			
			a = "Processing Well "+folderName;
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

//finish up script
runTime = ((getTime() - startTime)/1000);  //calculate runtime in secs
print("run time = "+runTime);
setBatchMode(false);//disable batch mode to allow popups etc
showMessage("Finished", "Congratulations, your files have been processed in "+runTime+"s"); //show message
exit;
