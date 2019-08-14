option explicit

set strComputer = "."

set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate,(Security)}!\\.\root\cimv2")
set colLogFiles   = objWMIService.ExecQuery("select * from Win32_NTEventLogFile")

for each objLogFile in colLogFiles
    strLogFileName = objLogFile.Name
    set wmiSWbemObject = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\.\root\cimv2:" & "Win32_NTEventlogFile.Name='" & strLogFileName & "'")
    wmiSWbemObject.MaxFileSize = 5000000
    wmiSWbemObject.OverwriteOutdated = 14
    wmiSWbemObject.Put_
    set wmiSWbemObject = nothing
next

set strComputer   = nothing
set colLogFiles   = nothing
set objWMIService = nothing