currentdir=Left(WScript.ScriptFullName,InStrRev(WScript.ScriptFullName,"\"))
app = "1_EVOSmanager.exe"
Set objShell = WScript.CreateObject("WScript.Shell")
objShell.Run currentdir + app