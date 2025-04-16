global adbPort, adbShell, adbPath, debugMode
; ============================================================================
; Image Recognition Functions
; ============================================================================
GetNeedle(Path) {
    static NeedleBitmaps := Object()
    if (NeedleBitmaps.HasKey(Path)) {
        return NeedleBitmaps[Path]
    } else {
        pNeedle := Gdip_CreateBitmapFromFile(Path)
        NeedleBitmaps[Path] := pNeedle
        return pNeedle
    }
}
; ============================================================================
; Status Display Functions
; ============================================================================
; filepath: c:\Users\Gabriel\Documents\GitHub\PTCGPB\Scripts\Include\Utils.ahk
; Add this function to the Utils.ahk file

CreateStatusMessage(Message, GuiName := "StatusMessage", X := 0, Y := 80, enableThrottling := true, updateInterval := 0.5) {
    global scriptName, winTitle, StatusText, showStatus
    static statusLastMessage := {}, statusLastUpdateTime := {}, hwnds := {}
    static statusUpdateInterval := updateInterval
    
    if(!showStatus)
        return
    
    ; Handle the different types of GuiName (string or number)
    if GuiName is integer
        uniqueGuiName := GuiName . scriptName
    else
        uniqueGuiName := GuiName
    
    ; Create a unique key for this GuiName/position combination
    messageKey := uniqueGuiName . ":" . X . ":" . Y
    currentTime := A_TickCount / 1000
    
    ; If throttling is enabled and the same message was displayed recently in the same location
    if (enableThrottling && statusLastMessage.HasKey(messageKey) && statusLastMessage[messageKey] = Message) {
        ; Only update if enough time has passed since the last update
        if (currentTime - statusLastUpdateTime[messageKey] < statusUpdateInterval) {
            return
        }
    }
    
    ; Update our record of this message
    statusLastMessage[messageKey] := Message
    statusLastUpdateTime[messageKey] := currentTime
    
    try {
        ; Check if GUI with this name already exists
        if !hwnds.HasKey(uniqueGuiName) {
            WinGetPos, xpos, ypos, Width, Height, %winTitle%
            X := X + xpos + 5
            Y := Y + ypos
            if(!X)
                X := 0
            if(!Y)
                Y := 0

            ; Create a new GUI with the given name, position, and message
            Gui, %uniqueGuiName%:New, -AlwaysOnTop +ToolWindow -Caption
            Gui, %uniqueGuiName%:Margin, 2, 2  ; Set margin for the GUI
            Gui, %uniqueGuiName%:Font, s8  ; Set the font size to 8 (adjust as needed)
            Gui, %uniqueGuiName%:Add, Text, hwndhCtrl vStatusText,
            hwnds[uniqueGuiName] := hCtrl
            OwnerWND := WinExist(winTitle)
            Gui, %uniqueGuiName%:+Owner%OwnerWND% +LastFound
            DllCall("SetWindowPos", "Ptr", WinExist(), "Ptr", 1  ; HWND_BOTTOM
                , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)  ; SWP_NOSIZE, SWP_NOMOVE, SWP_NOACTIVATE
            Gui, %uniqueGuiName%:Show, NoActivate x%X% y%Y% AutoSize
        }
        SetTextAndResize(hwnds[uniqueGuiName], Message)
        Gui, %uniqueGuiName%:Show, NoActivate AutoSize
    }
}

; resetWindows(instanceName := "", monitorOverride := "") {
;     global Columns, winTitle, SelectedMonitorIndex, scaleParam, Delay
    
;     currentWinTitle := instanceName ? instanceName : winTitle
;     currentMonitor := monitorOverride ? monitorOverride : SelectedMonitorIndex
    
;     CreateStatusMessage("Arranging window positions and sizes for " . currentWinTitle)
;     LogDebug("Arranging window positions and sizes for " . currentWinTitle)
    
;     RetryCount := 0
;     MaxRetries := 10
    
;     ; First position the window
;     Loop {
;         try {
;             ; Get monitor origin from index
;             currentMonitor := RegExReplace(currentMonitor, ":.*$")
;             SysGet, MonitorCount, MonitorCount
;             if (currentMonitor > MonitorCount || currentMonitor < 1) {
;                 currentMonitor := 1
;             }
            
;             SysGet, Monitor, Monitor, %currentMonitor%
;             Title := currentWinTitle
            
;             ; Check if window exists
;             if (!WinExist(Title)) {
;                 RetryCount++
;                 if (RetryCount >= MaxRetries) {
;                     CreateStatusMessage("Can't find window " . currentWinTitle)
;                     LogError("Can't find window " . currentWinTitle)
;                     return false
;                 }
;                 Sleep, 1000
;                 continue
;             }

;             ; Extract instance number for positioning
;             if (Title = "Main" || RegExMatch(Title, "^Main\.ahk$")) {
;                 ; First main instance is always 1
;                 instanceIndex := 1
;             } else if (RegExMatch(Title, "^Main(\d+)(\.ahk)?$", match)) {
;                 ; Main2.ahk -> 2, Main3 -> 3, etc.
;                 instanceIndex := match1
;             } else {
;                 ; Regular numbered instances
;                 instanceIndex := Title
;             }

;             rowHeight := 533
;             currentRow := Floor((instanceIndex - 1) / Columns)
;             y := currentRow * rowHeight
;             x := Mod((instanceIndex - 1), Columns) * scaleParam
            
;             WinMove, %Title%, , % (MonitorLeft + x), % (MonitorTop + y), scaleParam, 537
;             Sleep, 500
;             break
;         }
;         catch e {
;             RetryCount++
;             LogError("Error positioning window: " . e.message)
;             if (RetryCount >= MaxRetries) {
;                 return false
;             }
;             Sleep, 1000
;         }
;     }
    
;     ; Create toolbar GUI with proper delays
;     try {
;         WinGetPos, x, y, Width, Height, %Title%
;         x4 := x + 5
;         y4 := y + 44
;         buttonWidth := 40
        
;         if (scaleParam = 287)
;             buttonWidth := buttonWidth + 5
            
;         Gui, Toolbar: New, +ToolWindow -Caption
;         Gui, Toolbar: Default
;         Gui, Toolbar: Margin, 4, 4
;         Gui, Toolbar: Font, s5 cGray Norm Bold, Segoe UI
;         Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 0) . " y0 w" . buttonWidth . " h25 gReloadScript", Reload  (Shift+F5)
;         Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 1) . " y0 w" . buttonWidth . " h25 gPauseScript", Pause (Shift+F6)
;         Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 2) . " y0 w" . buttonWidth . " h25 gResumeScript", Resume (Shift+F6)
;         Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 3) . " y0 w" . buttonWidth . " h25 gStopScript", Stop (Shift+F7)
;         Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 4) . " y0 w" . buttonWidth . " h25 gShowStatusMessages", Status (Shift+F8)
        
;         ; Add GP Test button if it's a main instance
;         if (InStr(Title, "Main")) {
;             Gui, Toolbar: Add, Button, % "x" . (buttonWidth * 5) . " y0 w" . buttonWidth . " h25 gTestScript", GP Test (Shift+F9)
;         }
        
;         Gui, Toolbar: Show, NoActivate x%x4% y%y4% AutoSize
;     }
;     catch e {
;         LogError("Failed to create toolbar: " . e.message)
;     }
    
;     return true
; }


ToggleStatusMessages() {
    global showStatus
    
    if(showStatus) {
        CreateStatusMessage("")
        showStatus := False
    }
    else {
        showStatus := True
    }
}

SetTextAndResize(controlHwnd, newText) {
    dc := DllCall("GetDC", "Ptr", controlHwnd)

    ; 0x31 = WM_GETFONT
    SendMessage 0x31,,,, ahk_id %controlHwnd%
    hFont := ErrorLevel
    oldFont := 0
    if (hFont != "FAIL")
        oldFont := DllCall("SelectObject", "Ptr", dc, "Ptr", hFont)

    VarSetCapacity(rect, 16, 0)
    ; 0x440 = DT_CALCRECT | DT_EXPANDTABS
    h := DllCall("DrawText", "Ptr", dc, "Ptr", &newText, "Int", -1, "Ptr", &rect, "UInt", 0x440)
    ; width = rect.right - rect.left
    w := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")

    if oldFont
        DllCall("SelectObject", "Ptr", dc, "Ptr", oldFont)
    DllCall("ReleaseDC", "Ptr", controlHwnd, "Ptr", dc)

    GuiControl,, %controlHwnd%, %newText%
    GuiControl MoveDraw, %controlHwnd%, % "h" h*96/A_ScreenDPI + 2 " w" w*96/A_ScreenDPI + 2
}

; ============================================================================
; ADB Interface Functions
; ============================================================================
KillADBProcesses() {
    ; Use AHK's Process command to close adb.exe
    Process, Close, adb.exe
    ; Fallback to taskkill for robustness
    RunWait, %ComSpec% /c taskkill /IM adb.exe /F /T,, Hide
}

ControlClick(X, Y) {
	global winTitle
	ControlClick, x%X% y%Y%, %winTitle%
}

; filepath: c:\Users\Gabriel\Documents\GitHub\PTCGPB\Scripts\Include\Utils.ahk

initializeAdbShell() {
    global adbShell, adbPath, adbPort, debugMode
    
    RetryCount := 0
    MaxRetries := 10
    BackoffTime := 1000  ; Initial backoff time in milliseconds
    MaxBackoff := 5000   ; Prevent excessive waiting

    Loop {
        try {
            if (!adbShell || adbShell.Status != 0) {
                adbShell := ""  ; Reset before reattempting

                ; Validate adbPath and adbPort
                if (!FileExist(adbPath)) {
                    throw Exception("ADB path is invalid: " . adbPath)
                }
                if (adbPort < 0 || adbPort > 65535) {
                    throw Exception("ADB port is invalid: " . adbPort)
                }

                ; Attempt to start adb shell
                adbShell := ComObjCreate("WScript.Shell").Exec(adbPath . " -s 127.0.0.1:" . adbPort . " shell")

                ; Ensure adbShell is running before sending 'su'
                Sleep, 500
                if (adbShell.Status != 0) {
                    throw Exception("Failed to start ADB shell.")
                }

                adbShell.StdIn.WriteLine("su")
            }

            ; If adbShell is running, break loop
            if (adbShell.Status = 0) {
                break
            }
        } catch e {
            errorMsg := IsObject(e) && e.HasKey("message") ? e.message : "Unknown error"
            RetryCount++
            LogError("ADB Shell Error: " . errorMsg)
            
            if (RetryCount >= MaxRetries) {
                if (debugMode) {
                    CreateStatusMessage("Failed to connect to shell after multiple attempts: " . errorMsg)
                    LogCritical("Failed to connect to shell after multiple attempts: " . errorMsg)
                } else {
                    CreateStatusMessage("Failed to connect to shell. Pausing.")
                    LogCritical("Failed to connect to shell. Pausing.")
                }
                Pause
            }
        }

        Sleep, BackoffTime
        BackoffTime := Min(BackoffTime + 1000, MaxBackoff)  ; Limit backoff time
    }
}

ConnectAdb(folderPath := "C:\Program Files\Netease") {
    adbPort := findAdbPorts(folderPath)

    adbPath := folderPath . "\MuMuPlayerGlobal-12.0\shell\adb.exe"

    if !FileExist(adbPath) ;if international mumu file path isn't found look for chinese domestic path
        adbPath := folderPath . "\MuMu Player 12\shell\adb.exe"

    if !FileExist(adbPath)
        MsgBox Double check your folder path! It should be the one that contains the MuMuPlayer 12 folder! `nDefault is just C:\Program Files\Netease

    if(!adbPort) {
        Msgbox, Invalid port... Check the common issues section in the readme/github guide.
        ExitApp
    }

    MaxRetries := 5
    RetryCount := 0
    connected := false
    ip := "127.0.0.1:" . adbPort ; Specify the connection IP:port

    CreateStatusMessage("Connecting to ADB...")
    LogDebug("Connecting to ADB...")

    Loop %MaxRetries% {
        ; Attempt to connect using CmdRet
        connectionResult := CmdRet(adbPath . " connect " . ip)

        ; Check for successful connection in the output
        if InStr(connectionResult, "connected to " . ip) {
            connected := true
            CreateStatusMessage("ADB connected successfully.")
            LogDebug("ADB connected successfully.")
            return true
        } else {
            RetryCount++
            CreateStatusMessage("ADB connection failed.`nRetrying (" . RetryCount . "/" . MaxRetries . ")...")
            LogDebug("ADB connection failed. Retrying (" . RetryCount . "/" . MaxRetries . ")...")
            Sleep, 2000
        }
    }

    if !connected {
        if (debugMode){
            CreateStatusMessage("Failed to connect to ADB after multiple retries. Please check your emulator and port settings.")
            LogCritical("Failed to connect to ADB after multiple retries. Please check your emulator and port settings.")
        }else{
            CreateStatusMessage("Failed to connect to ADB.")
            LogCritical("Failed to connect to ADB.")
        }Reload
    }
}

CmdRet(sCmd, callBackFuncObj := "", encoding := "")
{
    static HANDLE_FLAG_INHERIT := 0x00000001, flags := HANDLE_FLAG_INHERIT
        , STARTF_USESTDHANDLES := 0x100, CREATE_NO_WINDOW := 0x08000000

   (encoding = "" && encoding := "cp" . DllCall("GetOEMCP", "UInt"))
   DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
   DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

   VarSetCapacity(STARTUPINFO , siSize :=    A_PtrSize*4 + 4*8 + A_PtrSize*5, 0)
   NumPut(siSize              , STARTUPINFO)
   NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize*4 + 4*7)
   NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*3)
   NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*4)

   VarSetCapacity(PROCESS_INFORMATION, A_PtrSize*2 + 4*2, 0)

   if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
                              , "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION)
   {
      DllCall("CloseHandle", "Ptr", hPipeRead)
      DllCall("CloseHandle", "Ptr", hPipeWrite)
      throw "CreateProcess is failed"
   }
   DllCall("CloseHandle", "Ptr", hPipeWrite)
   VarSetCapacity(sTemp, 4096), nSize := 0
   while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", &sTemp, "UInt", 4096, "UIntP", nSize, "UInt", 0) {
      sOutput .= stdOut := StrGet(&sTemp, nSize, encoding)
      ( callBackFuncObj && callBackFuncObj.Call(stdOut) )
   }
   DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION))
   DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize))
   DllCall("CloseHandle", "Ptr", hPipeRead)
   Return sOutput
}

findAdbPorts(baseFolder := "C:\Program Files\Netease") {
    global scriptName
    ; Initialize variables
    adbPorts := 0  ; Create an empty associative array for adbPorts
    mumuFolder = %baseFolder%\MuMuPlayerGlobal-12.0\vms\*
    if !FileExist(mumuFolder)
        mumuFolder = %baseFolder%\MuMu Player 12\vms\*

    if !FileExist(mumuFolder){
        MsgBox, 16, , Double check your folder path! It should be the one that contains the MuMuPlayer 12 folder! `nDefault is just C:\Program Files\Netease
        ExitApp
    }
    ; Loop through all directories in the base folder
    Loop, Files, %mumuFolder%, D  ; D flag to include directories only
    {
        folder := A_LoopFileFullPath
        configFolder := folder "\configs"  ; The config folder inside each directory

        ; Check if config folder exists
        IfExist, %configFolder%
        {
            ; Define paths to vm_config.json and extra_config.json
            vmConfigFile := configFolder "\vm_config.json"
            extraConfigFile := configFolder "\extra_config.json"

            ; Check if vm_config.json exists and read adb host port
            IfExist, %vmConfigFile%
            {
                FileRead, vmConfigContent, %vmConfigFile%
                ; Parse the JSON for adb host port
                RegExMatch(vmConfigContent, """host_port"":\s*""(\d+)""", adbHostPort)
                adbPort := adbHostPort1  ; Capture the adb host port value
            }

            ; Check if extra_config.json exists and read playerName
            IfExist, %extraConfigFile%
            {
                FileRead, extraConfigContent, %extraConfigFile%
                ; Parse the JSON for playerName
                RegExMatch(extraConfigContent, """playerName"":\s*""(.*?)""", playerName)
                if(playerName1 = scriptName) {
                    return adbPort
                }
            }
        }
    }
}
waitadb() {
    adbShell.StdIn.WriteLine("echo done")
    while !adbShell.StdOut.AtEndOfStream {
        line := adbShell.StdOut.ReadLine()
        if (line = "done")
            break
        Sleep, 50
    }
}

adbClick(X, Y) {
    static clickCommands := Object()
    static convX := 540/277, convY := 960/489, offset := -44

    key := X << 16 | Y

    if (!clickCommands.HasKey(key)) {
        clickCommands[key] := Format("input tap {} {}"
            , Round(X * convX)
            , Round((Y + offset) * convY))
    }
    adbShell.StdIn.WriteLine(clickCommands[key])
}

adbInput(name) {
    adbShell.StdIn.WriteLine("input text " . name)
    waitadb()
}

adbInputEvent(event) {
    adbShell.StdIn.WriteLine("input keyevent " . event)
    waitadb()
}

adbSwipe(params) {
    adbShell.StdIn.WriteLine("input swipe " . params)
    waitadb()
}

; Simulates a touch gesture on an Android device to scroll in a controlled way.
; Not currently supported.
adbGesture(params) {
    ; Example params (a 2-second hold-drag from a lower to an upper Y-coordinate): 0 2000 138 380 138 90 138 90
    adbShell.StdIn.WriteLine("input touchscreen gesture " . params)
    waitadb()
}

; Takes a screenshot of an Android device using ADB and saves it to a file.
adbTakeScreenshot(outputFile) {
    ; ------------------------------------------------------------------------------
    ; Parameters:
    ;   outputFile (String) - The path and filename where the screenshot will be saved.
    ; ------------------------------------------------------------------------------
    deviceAddress := "127.0.0.1:" . adbPort
    command := """" . adbPath . """ -s " . deviceAddress . " exec-out screencap -p > """ .  outputFile . """"
    RunWait, %ComSpec% /c "%command%", , Hide
}

; ============================================================================
; Window and UI Handling Functions
; ============================================================================

from_window(ByRef image) {
    ; Get the handle to the window.
    image := (hwnd := WinExist(image)) ? hwnd : image

    ; Restore the window if minimized! Must be visible for capture.
    if DllCall("IsIconic", "ptr", image)
        DllCall("ShowWindow", "ptr", image, "int", 4)

    ; Get the width and height of the client window.
    VarSetCapacity(Rect, 16) ; sizeof(RECT) = 16
    DllCall("GetClientRect", "ptr", image, "ptr", &Rect)
        , width  := NumGet(Rect, 8, "int")
        , height := NumGet(Rect, 12, "int")

    ; struct BITMAPINFOHEADER - https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
    hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    VarSetCapacity(bi, 40, 0)                ; sizeof(bi) = 40
        , NumPut(       40, bi,  0,   "uint") ; Size
        , NumPut(    width, bi,  4,   "uint") ; Width
        , NumPut(  -height, bi,  8,    "int") ; Height - Negative so (0, 0) is top-left.
        , NumPut(        1, bi, 12, "ushort") ; Planes
        , NumPut(       32, bi, 14, "ushort") ; BitCount / BitsPerPixel
        , NumPut(        0, bi, 16,   "uint") ; Compression = BI_RGB
        , NumPut(        3, bi, 20,   "uint") ; Quality setting (3 = low quality, no anti-aliasing)
    hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", &bi, "uint", 0, "ptr*", pBits:=0, "ptr", 0, "uint", 0, "ptr")
    obm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")

    ; Print the window onto the hBitmap using an undocumented flag. https://stackoverflow.com/a/40042587
    DllCall("PrintWindow", "ptr", image, "ptr", hdc, "uint", 0x3) ; PW_CLIENTONLY | PW_RENDERFULLCONTENT
    ; Additional info on how this is implemented: https://www.reddit.com/r/windows/comments/8ffr56/altprintscreen/

    ; Convert the hBitmap to a Bitmap using a built in function as there is no transparency.
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", pBitmap:=0)

    ; Cleanup the hBitmap and device contexts.
    DllCall("SelectObject", "ptr", hdc, "ptr", obm)
    DllCall("DeleteObject", "ptr", hbm)
    DllCall("DeleteDC",     "ptr", hdc)

    return pBitmap
}

bboxAndPause(X1, Y1, X2, Y2, doPause := False) {
    BoxWidth := X2-X1
    BoxHeight := Y2-Y1
    ; Create a GUI
    Gui, BoundingBox:+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui, BoundingBox:Color, 123456
    Gui, BoundingBox:+LastFound  ; Make the GUI window the last found window for use by the line below. (straght from documentation)
    WinSet, TransColor, 123456 ; Makes that specific color transparent in the gui

    ; Create the borders and show
    Gui, BoundingBox:Add, Progress, x0 y0 w%BoxWidth% h2 BackgroundRed
    Gui, BoundingBox:Add, Progress, x0 y0 w2 h%BoxHeight% BackgroundRed
    Gui, BoundingBox:Add, Progress, x%BoxWidth% y0 w2 h%BoxHeight% BackgroundRed
    Gui, BoundingBox:Add, Progress, x0 y%BoxHeight% w%BoxWidth% h2 BackgroundRed
    Gui, BoundingBox:Show, x%X1% y%Y1% NoActivate
    Sleep, 100

    if (doPause) {
        Pause
    }

    if GetKeyState("F4", "P") {
        Pause
    }

    Gui, BoundingBox:Destroy
}

; ============================================================================
; File and Data Handling Functions
; ============================================================================

EscapeForJson(text) {
    ; First escape backslashes (must come first)
    text := StrReplace(text, "\", "\\")
    ; Then escape quotes
    text := StrReplace(text, """", "\""")
    ; Finally replace newlines
    text := StrReplace(text, "`n", "\n")
    return text
}

LogToDiscord(message, screenshotFile := "", ping := false, xmlFile := "", screenshotFile2 := "", altWebhookURL := "", altUserId := "") {
    discordPing := ""

    if (ping) {
        userId := (altUserId ? altUserId : discordUserId)

        discordPing := "<@" . userId . "> "
        discordFriends := ReadFile("discord")
        if (discordFriends) {
            for index, value in discordFriends {
                if (value = userId)
                    continue
                discordPing .= "<@" . value . "> "
            }
        }
    }

    webhookURL := (altWebhookURL ? altWebhookURL : discordWebhookURL)

    if (webhookURL != "") {
        MaxRetries := 10
        RetryCount := 0
        Loop {
            try {
                ; Base command
                curlCommand := "curl -k "
                    . "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" "

                ; If an screenshot or xml file is provided, send it
                sendScreenshot1 := screenshotFile != "" && FileExist(screenshotFile)
                sendScreenshot2 := screenshotFile2 != "" && FileExist(screenshotFile2)
                sendAccountXml := xmlFile != "" && FileExist(xmlFile)
                if (sendScreenshot1 + sendScreenshot2 + sendAccountXml > 1) {
                    fileIndex := 0
                    if (sendScreenshot1) {
                        fileIndex++
                        curlCommand := curlCommand . "-F ""file" . fileIndex . "=@" . screenshotFile . """ "
                    }
                    if (sendScreenshot2) {
                        fileIndex++
                        curlCommand := curlCommand . "-F ""file" . fileIndex . "=@" . screenshotFile2 . """ "
                    }
                    if (sendAccountXml) {
                        fileIndex++
                        curlCommand := curlCommand . "-F ""file" . fileIndex . "=@" . xmlFile . """ "
                    }
                }
                else if (sendScreenshot1 + sendScreenshot2 + sendAccountXml == 1) {
                    if (sendScreenshot1)
                        curlCommand := curlCommand . "-F ""file=@" . screenshotFile . """ "
                    if (sendScreenshot2)
                        curlCommand := curlCommand . "-F ""file=@" . screenshotFile2 . """ "
                    if (sendAccountXml)
                        curlCommand := curlCommand . "-F ""file=@" . xmlFile . """ "
                }
                ; Add the webhook
                curlCommand := curlCommand . webhookURL

                LogDiscord(curlCommand)

                ; Send the message using curl
                RunWait, %curlCommand%,, Hide
                break
            }
            catch {
                RetryCount++
                if (RetryCount >= MaxRetries) {
                    CreateStatusMessage("Failed to send discord message.")
                    break
                }
                Sleep, 250
            }
            Sleep, 250
        }
    }
}

ReadFile(filename, numbers := false) {
    FileRead, content, %A_ScriptDir%\..\%filename%.txt

    if (!content)
        return false

    values := []
    for _, val in StrSplit(Trim(content), "`n") {
        ; Don't strip non-alphanumeric characters - we need to keep the | and ,
		trimmedVal := Trim(val, " `t`n`r")
        if (trimmedVal != "")
            values.Push(trimmedVal)
    }

    return values.MaxIndex() ? values : false
}
DownloadFile(url, filename) {
    url := url  ; Change to your hosted .txt URL "https://pastebin.com/raw/vYxsiqSs"
    localPath = %A_ScriptDir%\..\%filename% ; Change to the folder you want to save the file
    errored := false
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.Send()
        whr.WaitForResponse()
        ids := whr.ResponseText
    } catch {
        errored := true
    }
    if(!errored) {
        FileDelete, %localPath%
        FileAppend, %ids%, %localPath%
    }
}
; ============================================================================
; Date and Time Functions
; ============================================================================

MonthToDays(year, month) {
    static DaysInMonths := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days := 0
    Loop, % month - 1 {
        days += DaysInMonths[A_Index]
    }
    if (month > 2 && IsLeapYear(year))
        days += 1
    return days
}
IsLeapYear(year) {
    return (Mod(year, 4) = 0 && Mod(year, 100) != 0) || Mod(year, 400) = 0
}
Delay(n) {
    global Delay
    msTime := Delay * n
    Sleep, msTime
}
