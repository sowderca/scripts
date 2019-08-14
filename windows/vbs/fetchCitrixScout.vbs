option explicit

set shell   = WScript.CreateObject("WScript.Shell")

set fileUrl = "https://taas.citrix.com/tools/Scout/update/Scout.zip"

set payload = shell.ExpandEnvironmentStrings("%UserProfile%\" & "Downloads\scout.zip")

set xmlHTTP = CreateObject("MSXML2.XMLHTTP")

xmlHTTP.open("GET", fileUrl, false)
xmlHTTP.send()

if xmlHTTP.Status = 200 then
    set adoStream = CreateObject("ADODB.Stream")

    adoStream.Open()
    adoStream.Type = 1
    adoStream.Write(xmlHTTP.ResponseBody)
    adoStream.Position = 0

    set fso = CreateObject("Scripting.FileSystemObject")
    if fso.FileExists("") then fso.DeleteFile(payload)
    set fso = nothing
    adoStream.SaveToFile(payload)
    adoStream.Close()
    set adoStream = nothing
end if

set xmlHTTP = nothing
set shell   = nothing
