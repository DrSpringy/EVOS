//launch EVOSfilemanager from imagej
fs = File.separator;
imagejPath = getDirectory("imagej");
scriptsPath = imagejPath + "scripts" + fs;
execPath = scriptsPath + "IMB_" + fs + "EVOS" + fs + "launcher.bat";
exec("cmd", "/c", "start", execPath);
