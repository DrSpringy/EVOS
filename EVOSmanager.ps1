#EVOS File Manager script
#From a single output folder of .tif files, create a sub-folder for each well
#move .tif files to the corresponding sub-folder
#FIJI can then import the images in each sub-folder into a stack
#then the stack can be converted to a hyper-stack with the correct number of channels and timepoints

Add-Type -AssemblyName PresentationCore,PresentationFramework #load graphics for pop-ups

#load last used filepath if possible
$inputPath = $null
If((Test-Path "HKCU:\Software\EVOS_Converter") -eq $false) {New-Item -Path HKCU:\Software\EVOS_Converter -name Default -Value "default value" -Force -ErrorAction SilentlyContinue} #Check if the Windows registry folder exists, otherwise create it.
$inputPath = (Get-ItemPropertyValue -Path HKCU:\Software\EVOS_Converter -name inputPath -ErrorAction SilentlyContinue) #read from registry the starting input file path
If ([string]::IsNullOrEmpty($inputPath)) {$inputPath = [Environment]::GetFolderPath('Desktop')} #if the registry value doesnt exist, set to Desktop

#Configure File browser settings
$inputBrowser = New-Object System.Windows.Forms.FolderBrowserDialog 
$inputBrowser.SelectedPath = $inputPath 
$inputBrowser.Description = "Select a Folder that contains your EVOS .tif files"
$inputResult = $inputBrowser.ShowDialog() #Display file browser
$inputResult.activate

#If user selects a folder and clicks "OK", process files
if($inputResult -eq "OK") {
    $inputPath = $inputBrowser.selectedpath #get selected input file path
    New-ItemProperty -Path HKCU:\Software\EVOS_Converter -name inputPath -Value $inputPath -Force > $null #save folder path of input file to registry for next time

    #ask user to move or copy files
    $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    $MessageTitle = "Copy/Move Files"
    $MessageBody = "Would you like to Copy the original files to a new sub-directory`r`n`r`nYes = Copy Files, No = Move Files"
    $copyFiles = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    $copyFiles.activate
    if($copyFiles -eq 'Cancel'){
        "user aborted at Copy/Move"
        exit
    }

    #get properties of tif files in folder
    $tifProperties = (get-childitem $inputPath -file |group Extension |sort Count -Unique) | Where-Object {($_.Name -match ".TIF")}
    
    $rawTifProperties = $tifProperties.group -match "_$R_" # process Raw files
    $rawTifCount = $rawTifProperties.Count
    $rawTifNames = $rawTifProperties.name
    
    #get unique well names and create an array
    $wellPrefix = "_0_"
    $wellList = @()
    foreach($tif in $rawTifNames){
        $well = $tif.Substring($($tif.IndexOf($wellPrefix))+3, 3) 
        if($wellList -notcontains $well){$wellList += $well}
    }

    #create a folder for each well and copy files for that well into the matching folder
    $runError = $false
    if($rawTifCount -gt 0){
        foreach($well in $wellList){
            $newPath = "$inputPath\Processed\$well"
            if(test-path $newPath){ #if well sub-folder already exists, dont do anything
                "sub-folders already exist"
                $runError = $true
            }Else{
                New-Item $newPath -ItemType Directory #create well sub-folder
                foreach($tif in $rawTifNames){
                    if($tif -match $well){ #if file belongs to well, move file to sub-folder
                        If($copyFiles -eq 'Yes'){
                            Copy-Item -Path $inputPath\$tif -Destination "$newPath\" #copy files to new sub-folder
                        }Else{
                            Move-Item -Path $inputPath\$tif -Destination $newPath #move files to new sub-folder
                        }
                    }
                }
            }
        } 
    }
    else{
        "There are no matching .tif files to process"
        $runError = $true
    }
    
    if($runError){ #display error popup
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        $MessageTitle = "Warning"
        if($rawTifCount -eq 0){$MessageBody = "Sorry, Something went wrong`r`nThere are no .tif files to process"}
        Else{$MessageBody = "Sorry, Something went wrong`r`nHas this folder already been processed?"}
        $result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        $result.activate
    }Else{
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageIcon = [System.Windows.MessageBoxImage]::Exclamation
        $MessageTitle = "Success"
        $MessageBody = "Congratulations, your files have been processed"
        $result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        $result.activate
    }     
} else {Write-Host "Select Input Folder Cancelled!"} 

