#EVOS File Manager script
#From a single output folder of .tif files, create a sub-folder for each well
#move .tif files to the corresponding sub-folder
#FIJI can then import the images in each sub-folder into a stack
#then the stack can be converted to a hyper-stack with the correct number of channels and timepoints

$inputPath = $null
If((Test-Path "HKCU:\Software\EVOS_Converter") -eq $false) {New-Item -Path HKCU:\Software\EVOS_Converter -name Default -Value "default value" -Force -ErrorAction SilentlyContinue} #Check if the Windows registry folder exists, otherwise create it.
$inputPath = (Get-ItemPropertyValue -Path HKCU:\Software\EVOS_Converter -name inputPath -ErrorAction SilentlyContinue) #read from registry the starting input file path
If ([string]::IsNullOrEmpty($inputPath)) {$inputPath = [Environment]::GetFolderPath('Desktop')} #if the registry value doesnt exist, set to Desktop

#Configure File browser settings
$inputBrowser = New-Object System.Windows.Forms.FolderBrowserDialog 
$inputBrowser.SelectedPath = $inputPath 
$inputBrowser.Description = "Select a Folder that contains your EVOS .tif files"
$inputResult = $inputBrowser.ShowDialog() #Display file browser

#If user selects a file and clicks "OK" open output folder selection GUI
if($inputResult -eq "OK") {
    $inputPath = $inputBrowser.selectedpath #get selected input file path
    New-ItemProperty -Path HKCU:\Software\EVOS_Converter -name inputPath -Value $inputPath -Force > $null #save folder path of input file to registry for next time

    #get properties of tif files in folder
    $tifProperties = (get-childitem $inputPath -file |group Extension |sort Count -Unique) | Where-Object {($_.Name -eq ".TIF")}
    $tifCount = $tifProperties.Count
    $tifGroup = $tifProperties.Group
    $tifNames = ($tifGroup).name

    #get unique well names and create an array
    $wellPrefix = "_0_"
    $wellList = @()
    foreach($tif in $tifNames){
        $well = $tif.Substring($($tif.IndexOf($prefix))+3, 3) 
        if($wellList -notcontains $well){$wellList += $well}
    }

    #create a folder for each well and copy files for that well into the matching folder
    $runError = $false
    if($tifCount -gt 0){
        foreach($well in $wellList){
            if(test-path $inputPath\$well){ #if well sub-folder already exists, dont do anything
                $runError = $true
            }Else{
                New-Item $inputPath\$well -ItemType Directory #create well sub-folder
                foreach($tif in $tifNames){
                    if($tif -match $well){ #if file belongs to well, move file to sub-folder
                        Move-Item -Path $inputPath\$tif -Destination $inputPath\$well
                    }
                }
            }
        } 
    }
    else{$runError = $true}
    if($runError){ #display error popup
        Add-Type -AssemblyName PresentationCore,PresentationFramework
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        $MessageTitle = "Warning"
        if($tifCount -eq 0){$MessageBody = "Sorry, Something went wrong`r`nThere are no .tif files to process"}
        Else{$MessageBody = "Sorry, Something went wrong`r`nHas this folder already been processed?"}
        $result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    }      
} else {Write-Host "Select Input Folder Cancelled!"} 

