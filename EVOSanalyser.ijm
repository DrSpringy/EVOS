//ImageJ Macro to analyse COVID infected cells
hideWindows = false;  //set to true for normal use, false for debugging
run("Collect Garbage");
setOption("ExpandableArrays", true); //allow expandable arrays
fs = File.separator; // To handle different OSs file systems
filePath = File.openDialog("Select a Well Hyperstack to Display"); //ask user to select an image
parentPath = File.getParent(filePath);  //define parent folder of images
fileList = getFileList(parentPath);  //get list of files in folder
fileList = Array.sort(fileList);  //sort alphabetically
open(filePath);  //open the selected image
print("\\Clear");
print("EVOS Analyser is Running");

//Get info about the current image
Stack.getDimensions(width, height, channels, slices, frames);
channelList = newArray();
for (i = 0; i < channels; i++) {
	channelList[i] = "" + i+1;
}

//create array of timepoints
timeArray = newArray();
for (i = 0; i < frames; i++) {
	timeArray[i] = i;
}

//create popup 
Dialog.createNonBlocking("COVID Analysis");
Dialog.addMessage("Assign Channels for Analysis");
Dialog.addChoice("Select Nuclear Marker Channel", channelList, 3);
Dialog.addMessage("");
Dialog.addMessage("Select the analysis required");
Dialog.addCheckbox("Infection", false);
Dialog.addMessage("Mortality Analysis requires Infection Analysis");
Dialog.addCheckbox("Mortality", false);
Dialog.addMessage("");
Dialog.addChoice("Select Infection Marker Channel", channelList, 2);
Dialog.addChoice("Select Mortality Marker Channel", channelList, 1);
Dialog.show();

//get values from dialog window
nuclearChannel = Dialog.getChoice();
infectionCheckBox = Dialog.getCheckbox();
mortalityCheckBox = Dialog.getCheckbox();
infectionChannel = Dialog.getChoice();
mortalityChannel = Dialog.getChoice();

if(mortalityCheckBox >0){infectionCheckBox = 1;} //mortality analysis requires infection analysis

//close current image
close("*");

//create results file with column titles
output = "Well\tTimepoint\tMarked Nucleii Count";
if(infectionCheckBox >0){ output = output + "\tInfection Count\tInfected Marked Nucleii Count\t% of Marked Nucleii Infected"; }
if(mortalityCheckBox >0){output = output + "\tMortality Count\tInfected Mortality Count\t% of Marked Nucleii Mortality\t% of Infected Mortality";}
output = output + "\r\n";
File.saveString(output, parentPath + "_results.txt");

startTime = getTime();  //time run
//Process images
for (i = 0; i < fileList.length; i++) {
	if(hideWindows == true){setBatchMode(true);}else{setBatchMode(false);}  //enable background processing if true
	//filter for .tif files
	if ((endsWith(fileList[i], ".TIF"))||(endsWith(fileList[i], ".tif"))){ 
		open(fileList[i]); //open file
		fileName = getInfo("image.filename"); //get filename
		nameLength=fileName.length;
		wellName = substring(fileName, 0, nameLength-4);  //get well name without .tif
		
		//Count Nucleii
		print("analyse "+fileName);
		print("Count Nucleii using Channel "+nuclearChannel);
		selectWindow(fileName);
		nucleiiCount = analyseChannel(nuclearChannel);  //get number of nucleii using function analyseChannel
		print("Marked Nucleii");
		Array.print(nucleiiCount);
				
		//run infection analysis
		if(infectionCheckBox > 0){
			print("Analyse Infection using Channel "+infectionChannel);
			selectWindow(fileName);
			infectionCount = analyseChannel(infectionChannel);  //get all infected cells
			print("total Infected Cells");
			Array.print(infectionCount);
			
			//get infected cells that coloc with nucleii marker
			selectWindow("MASK_Channel-"+infectionChannel);
			imageCalculator("AND create stack", "MASK_Channel-"+nuclearChannel,"MASK_Channel-"+infectionChannel);		
			rename("Infected Cells");
			run("Analyze Particles...", "size=50-5000 pixel show=Outlines display exclude clear summarize add stack");
		
			//copy summary to results for processing
			selectWindow("Summary of Infected Cells");
			IJ.renameResults("Results");
			
			//put results into arrays for later use
			infectedMarkedNucleiiArray = newArray(nResults);
			percentInfectedArray = newArray(nResults);
			for (j = 0; j < nResults; j++) {
				count = getResultString("Count", j);
				infectedMarkedNucleiiArray[j] = count;
				percentInfectedArray[j] = (infectionCount[j])/(nucleiiCount[j]);
			}
			print("Infected Cells with Marked Nucleii");
			Array.print(infectedMarkedNucleiiArray);
			print("Percent of Infected Cells with Marked Nucleii");
			Array.print(percentInfectedArray);
			
		}
		//run mortality analysis
		if(mortalityCheckBox > 0){
			print("Analyse Mortality using Channel "+mortalityChannel);
			selectWindow(fileName);
			mortalityCount = analyseChannel(mortalityChannel);  //get dead cells
			print("Mortality Count");
			Array.print(mortalityCount);
			
			//get number of infected dead cells
			selectWindow("MASK_Channel-"+mortalityChannel);
			imageCalculator("AND create stack", "MASK_Channel-"+infectionChannel,"MASK_Channel-"+mortalityChannel);
			rename("Dead Infected Cells");
			run("Analyze Particles...", "size=50-5000 pixel show=Outlines display exclude clear summarize add stack");

			selectWindow("Summary of Dead Infected Cells");
			IJ.renameResults("Results");

			//put results into arrays for later use
			infectedMortalityArray = newArray(nResults);
			percentMortalityArray = newArray(nResults);
			percentInfectedMortalityArray = newArray(nResults);
			for (k = 0; k < nResults; k++) {
				count = getResultString("Count", k);
				infectedMortalityArray[k] = count;
				percentMortalityArray[k] = (mortalityCount[k])/(nucleiiCount[k]);
				if(infectionCheckBox >0){percentInfectedMortalityArray[k] = (infectedMortalityArray[k])/(infectedMarkedNucleiiArray[k]);}
			}
			print("Infected Mortality Count");
			Array.print(infectedMortalityArray);
			print("Percent Mortality");
			Array.print(percentMortalityArray);
			print("Percent Infected Mortality");
			Array.print(percentInfectedMortalityArray);
		}
		
 		output = "";
		for (l = 0; l < timeArray.length; l++) {
			//create a string with all of the array values
			output = output + "" + wellName + "\t" + timeArray[l] + "\t" + nucleiiCount[l];
			if(infectionCheckBox >0){ output = output + "\t" + infectionCount[l] + "\t" + infectedMarkedNucleiiArray[l] + "\t" + percentInfectedArray[l]; }
			if(mortalityCheckBox >0){output = output + "\t" + mortalityCount[l] + "\t" + infectedMortalityArray[l] + "\t" + percentMortalityArray[l] + "\t" + percentInfectedMortalityArray[l];}
			output = output + "\r\n";
		}
		File.append(output, parentPath + "_results.txt"); //write results to file		
		if(hideWindows == true) close("*");  //close all image windows	
	}
}
if(hideWindows == true) close("Results");

//function to detect particles and count them
function analyseChannel(channelNumber){
	//configure results table
	roiManager("reset");
	run("Clear Results");
	run("Set Measurements...", "stack redirect=None decimal=3");
	
	//process channel
	run("Duplicate...", "title=Channel-"+channelNumber + " duplicate" + " channels="+channelNumber); //duplicate nuclear marker channel
	run("Subtract Background...", "rolling=50 stack");  
	run("Make Binary", "method=Triangle background=Dark calculate black create");
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Watershed", "stack");
	run("Duplicate...", "duplicate");
	rename("Channel-"+channelNumber + "-ROIs");
	run("Analyze Particles...", "size=50-5000 pixel show=Outlines display exclude clear summarize add stack");
	
	//copy summary to results for processing
	selectWindow("Summary of Channel-"+channelNumber + "-ROIs");
	IJ.renameResults("Results");
	
	//put results into arrays for later use
	countArray = newArray(nResults);
	for (a = 0; a < nResults; a++) {
		count = getResultString("Count", a);
		countArray[a] = count;
	}
	
	//close windows
	if(hideWindows == true) {
		close("Channel-"+channelNumber);
		close("Channel-"+channelNumber+"-ROIs");
		close("Drawing of Channel-"+channelNumber+"-ROIs");
	}
	return countArray;
}

//finish up script
runTime = ((getTime() - startTime)/1000);  //calculate runtime in secs
print("run time = "+runTime);
setBatchMode(false);
showMessage("Analysis Complete", "Put down that whiskey, your analysis completed in "+runTime+"s");
exit;