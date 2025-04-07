; Global variables commonly used across scripts
global statusLastMessage := {}
global statusLastUpdateTime := {}
global statusUpdateInterval := 2 ; Seconds between updates of the same message

; ============================================================================
; Image Recognition Functions
; ============================================================================

FindOrLoseImage(X1, Y1, X2, Y2, searchVariation := "", imageName := "DEFAULT", EL := 1, safeTime := 0) {
    global winTitle, Variation, failSafe, scaleParam, defaultLanguage
    if(searchVariation = "")
        searchVariation := 20
    imagePath := A_ScriptDir . "\" . defaultLanguage . "\"
    confirmed := false

    CreateStatusMessage(imageName)
    LogDebug("Looking for image: " . imageName)
    pBitmap := from_window(WinExist(winTitle))
    Path = %imagePath%%imageName%.png
    pNeedle := GetNeedle(Path)

    ; 100% scale changes
    if (scaleParam = 287) {
        Y1 -= 8 ; offset, should be 44-36 i think?
        Y2 -= 8
        if (Y1 < 0) {
            Y1 := 0
        }
        if (imageName = "Bulba") { ; too much to the left? idk how that happens
            X1 := 200
            Y1 := 220
            X2 := 230
            Y2 := 260
        } else if (imageName = "Erika") { ; 100% fix for Erika avatar
            X1 := 149
            Y1 := 153
            X2 := 159
            Y2 := 162
        } else if (imageName = "DeleteAll") { ; 100% for Deleteall offset
            X1 := 200
            Y1 := 340
            X2 := 265
            Y2 := 530
        }
    }
    ;bboxAndPause(X1, Y1, X2, Y2)

    ; ImageSearch within the region
    vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, X1, Y1, X2, Y2, searchVariation)
    if(EL = 0)
        GDEL := 1
    else
        GDEL := 0
    if (!confirmed && vRet = GDEL && GDEL = 1) {
        confirmed := vPosXY
    } else if(!confirmed && vRet = GDEL && GDEL = 0) {
        confirmed := true
    }
    Path = %imagePath%App.png
    pNeedle := GetNeedle(Path)
    ; ImageSearch within the region
    vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 15, 155, 270, 420, searchVariation)
    Gdip_DisposeImage(pBitmap)
    if (vRet = 1) {
        CreateStatusMessage("At home page. Opening app..." )
        LogWarning("At home page during image search. Opening app...")
        restartGameInstance("At the home page during: `n" imageName)
    }
    
    ; Check for special cases like TradeTutorial or LevelUp based on imageName
    if(imageName = "Social" || imageName = "Add") {
        TradeTutorial()
    }
    
    if(imageName = "Social" || imageName = "Country" || imageName = "Account2" || imageName = "Account") {
        ; Look for No Save Data error message > if loaded account > delete xml > reload
        Path = %imagePath%NoSave.png
        pNeedle := GetNeedle(Path)
        ; ImageSearch within the region
        vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 30, 331, 50, 449, searchVariation)
        if (scaleParam = 287) {
            vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 30, 325, 55, 445, searchVariation)
        }
        if (vRet = 1) {
            adbShell.StdIn.WriteLine("rm -rf /data/data/jp.pokemon.pokemontcgp/cache/*") ; clear cache
            waitadb()
            CreateStatusMessage("Loaded deleted account. Deleting XML." )
            LogError("Loaded deleted account. Deleting XML.")
            if(loadedAccount) {
                FileDelete, %loadedAccount%
                IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
            }
            LogRestart("Restarted game for instance " . scriptName . " Reason: No save data found")
            Reload
        }
    }
    
    if(imageName = "Points" || imageName = "Home") {
        LevelUp()
    }
    
    if(imageName = "Country" || imageName = "Social")
        FSTime := 90
    else if(imageName = "Button")
        FSTime := 240
    else
        FSTime := 45
        
    if (safeTime >= FSTime) {
        CreateStatusMessage("Instance " . scriptName . " has been `nstuck " . imageName . " for " . FSTime . "s. Killing it...")
        LogError("Instance " . scriptName . " has been stuck " . imageName . " for " . FSTime . "s. EL: " . EL . " sT: " . safeTime . " Killing it...")
        restartGameInstance("Instance " . scriptName . " has been stuck " . imageName)
        failSafe := A_TickCount
    }
    
    return confirmed
}

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

CreateStatusMessage(Message, GuiName := 50, X := 0, Y := 80) {
    global scriptName, winTitle, StatusText, showStatus
    global statusLastMessage, statusLastUpdateTime, statusUpdateInterval
    static hwnds = {}
    
    if(!showStatus) {
        return
    }
    
    ; Create a unique key for this GuiName/position combination
    messageKey := GuiName . ":" . X . ":" . Y
    currentTime := A_TickCount / 1000
    
    ; If the same message was displayed recently in the same location, check interval
    if (statusLastMessage.HasKey(messageKey) && statusLastMessage[messageKey] = Message) {
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
        GuiName := GuiName+scriptName
        if !hwnds.HasKey(GuiName) {
            WinGetPos, xpos, ypos, Width, Height, %winTitle%
            X := X + xpos + 5
            Y := Y + ypos
            if(!X)
                X := 0
            if(!Y)
                Y := 0

            ; Create a new GUI with the given name, position, and message
            Gui, %GuiName%:New, -AlwaysOnTop +ToolWindow -Caption
            Gui, %GuiName%:Margin, 2, 2  ; Set margin for the GUI
            Gui, %GuiName%:Font, s8  ; Set the font size to 8 (adjust as needed)
            Gui, %GuiName%:Add, Text, hwndhCtrl vStatusText,
            hwnds[GuiName] := hCtrl
            OwnerWND := WinExist(winTitle)
            Gui, %GuiName%:+Owner%OwnerWND% +LastFound
            DllCall("SetWindowPos", "Ptr", WinExist(), "Ptr", 1  ; HWND_BOTTOM
                , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)  ; SWP_NOSIZE, SWP_NOMOVE, SWP_NOACTIVATE
            Gui, %GuiName%:Show, NoActivate x%X% y%Y% AutoSize
        }
        SetTextAndResize(hwnds[GuiName], Message)
        Gui, %GuiName%:Show, NoActivate AutoSize
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

adbClick(X, Y) {
    global adbShell
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

adbInput(input) {
    global adbShell
    Delay(3)
    adbShell.StdIn.WriteLine("input text " . input )
    Delay(3)
}

adbInputEvent(event) {
    global adbShell
    adbShell.StdIn.WriteLine("input keyevent " . event)
}

adbSwipeUp(speed) {
    global adbShell
    adbShell.StdIn.WriteLine("input swipe 266 770 266 355 " . speed)
    waitadb()
}

adbSwipe() {
    global adbShell, setSpeed, swipeSpeed
    X1 := 35
    Y1 := 327
    X2 := 267
    Y2 := 327
    X1 := Round(X1 / 277 * 535)
    Y1 := Round((Y1 - 44) / 489 * 960)
    X2 := Round(X2 / 277 * 535)
    Y2 := Round((Y2 - 44) / 489 * 960)

    adbShell.StdIn.WriteLine("input swipe " . X1 . " " . Y1 . " " . X2 . " " . Y2 . " " . swipeSpeed)
    waitadb()
}

waitadb() {
    global adbShell
    adbShell.StdIn.WriteLine("echo done")
    while !adbShell.StdOut.AtEndOfStream
    {
        line := adbShell.StdOut.ReadLine()
        if (line = "done")
            break
        Sleep, 50
    }
}

initializeAdbShell() {
    global adbShell, adbPath, adbPort
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
                    throw "ADB path is invalid: " . adbPath
                }
                if (adbPort < 0 || adbPort > 65535) {
                    throw "ADB port is invalid: " . adbPort
                }

                ; Attempt to start adb shell
                adbShell := ComObjCreate("WScript.Shell").Exec(adbPath . " -s 127.0.0.1:" . adbPort . " shell")

                ; Ensure adbShell is running before sending 'su'
                Sleep, 500
                if (adbShell.Status != 0) {
                    throw "Failed to start ADB shell."
                }

                adbShell.StdIn.WriteLine("su")
            }

            ; If adbShell is running, break loop
            if (adbShell.Status = 0) {
                break
            }
        } catch e {
            RetryCount++
            LogError("ADB Shell Error: " . e.message)
            if (RetryCount >= MaxRetries) {
                CreateStatusMessage("Failed to connect to shell after multiple attempts: " . e.message)
                LogCritical("Failed to connect to shell after multiple attempts: " . e.message)
                Pause
            }
        }

        Sleep, BackoffTime
        BackoffTime := Min(BackoffTime + 1000, MaxBackoff)  ; Limit backoff time
    }
}

ConnectAdb() {
    global adbPath, adbPort, StatusText
    MaxRetries := 5
    RetryCount := 0
    connected := false
    ip := "127.0.0.1:" . adbPort ; Specify the connection IP:port

    CreateStatusMessage("Connecting to ADB...")
    LogDebug("Connecting to ADB at " . ip)

    Loop %MaxRetries% {
        ; Attempt to connect using CmdRet
        connectionResult := CmdRet(adbPath . " connect " . ip)

        ; Check for successful connection in the output
        if InStr(connectionResult, "connected to " . ip) {
            connected := true
            CreateStatusMessage("ADB connected successfully.")
            LogDebug("ADB connected successfully to " . ip)
            return true
        } else {
            RetryCount++
            CreateStatusMessage("ADB connection failed. Retrying (" . RetryCount . "/" . MaxRetries . ").")
            LogWarning("ADB connection failed. Retrying (" . RetryCount . "/" . MaxRetries . ").")
            Sleep, 2000
        }
    }

    if !connected {
        CreateStatusMessage("Failed to connect to ADB after multiple retries. Please check your emulator and port settings.")
        LogError("Failed to connect to ADB after multiple retries. Please check your emulator and port settings.")
        Reload
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
    global adbPorts, winTitle, scriptName
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

; ============================================================================
; Window and UI Handling Functions
; ============================================================================

resetWindows(){
    global Columns, winTitle, SelectedMonitorIndex, scaleParam, runMain, Mains, scriptName
    CreateStatusMessage("Arranging window positions and sizes")
    LogDebug("Arranging window positions and sizes")
    RetryCount := 0
    MaxRetries := 10
    Loop
    {
        try {
            ; Get monitor origin from index
            SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
            SysGet, Monitor, Monitor, %SelectedMonitorIndex%
            Title := winTitle

            if (runMain) {
                instanceIndex := (Mains - 1) + Title + 1
            } else {
                instanceIndex := Title
            }

            rowHeight := 533  ; Adjust the height of each row
            currentRow := Floor((instanceIndex - 1) / Columns)
            y := currentRow * rowHeight
            x := Mod((instanceIndex - 1), Columns) * scaleParam
            WinMove, %Title%, , % (MonitorLeft + x), % (MonitorTop + y), scaleParam, 537
            break
        }
        catch {
            RetryCount++
            if (RetryCount > MaxRetries) {
                CreateStatusMessage("Pausing. Can't find window " . winTitle)
                LogError("Pausing. Can't find window " . winTitle)
                Pause
            }
        }
        Sleep, 1000
    }
    return true
}

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

Screenshot(filename := "Valid") {
    global adbShell, adbPath, packs, winTitle, scaleParam
    SetWorkingDir %A_ScriptDir%  ; Ensures the working directory is the script's directory

    ; Define folder and file paths
    screenshotsDir := A_ScriptDir "\..\Screenshots"
    if !FileExist(screenshotsDir)
        FileCreateDir, %screenshotsDir%

    ; File path for saving the screenshot locally
    screenshotFile := screenshotsDir "\" . A_Now . "_" . winTitle . "_" . filename . "_" . packs . "_packs.png"
    pBitmapW := from_window(WinExist(winTitle))
    pBitmap := Gdip_CloneBitmapArea(pBitmapW, 18, 175, 240, 227)
    ;scale 100%
    if (scaleParam = 287) {
        pBitmap := Gdip_CloneBitmapArea(pBitmapW, 17, 168, 245, 230)
    }
    Gdip_DisposeImage(pBitmapW)

    Gdip_SaveBitmapToFile(pBitmap, screenshotFile)

    Gdip_DisposeImage(pBitmap)
    return screenshotFile
}

LogToDiscord(message, screenshotFile := "", ping := false, xmlFile := "", screenshotFile2 := "") {
    global discordUserId, discordWebhookURL, friendCode, sendAccountXml
    LogInfo("Sending message to Discord: " . message)
    
    discordPing := "<@" . discordUserId . "> "
    discordFriends := ReadFile("discord")

    if(ping != false && discordFriends) {
        for index, value in discordFriends {
            if(value = discordUserId)
                continue
            discordPing .= "<@" . value . "> "
        }
    }

    if (discordWebhookURL != "") {
        if (!sendAccountXml)
            xmlFile := ""
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
                curlCommand := curlCommand . discordWebhookURL
                ; Send the message using curl
                RunWait, %curlCommand%,, Hide
                break
            }
            catch e {
                RetryCount++
                if (RetryCount >= MaxRetries) {
                    CreateStatusMessage("Failed to send discord message.")
                    LogError("Failed to send discord message: " . e.message)
                    break
                }
                Sleep, 250
            }
            sleep, 250
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
        return true
    }
    return false
}

; ============================================================================
; JSON Functions
; ============================================================================

InitializeJsonFile() {
    global jsonFileName
    fileName := A_ScriptDir . "\..\json\Packs.json"
    if !FileExist(fileName) {
        ; Create a new file with an empty JSON array
        FileAppend, [], %fileName%  ; Write an empty JSON array
        jsonFileName := fileName
        return
    }
}

AppendToJsonFile(variableValue) {
    global jsonFileName
    if (jsonFileName = "") {
        return
    }

    ; Read the current content of the JSON file
    FileRead, jsonContent, %jsonFileName%
    if (jsonContent = "") {
        jsonContent := "[]"
    }

    ; Parse and modify the JSON content
    jsonContent := SubStr(jsonContent, 1, StrLen(jsonContent) - 1) ; Remove trailing bracket
    if (jsonContent != "[")
        jsonContent .= ","
    jsonContent .= "{""time"": """ A_Now """, ""variable"": " variableValue "}]"

    ; Write the updated JSON back to the file
    FileDelete, %jsonFileName%
    FileAppend, %jsonContent%, %jsonFileName%
}

SumVariablesInJsonFile() {
    global jsonFileName
    if (jsonFileName = "") {
        return 0
    }

    ; Read the file content
    FileRead, jsonContent, %jsonFileName%
    if (jsonContent = "") {
        return 0
    }

    ; Parse the JSON and calculate the sum
    sum := 0
    ; Clean and parse JSON content
    jsonContent := StrReplace(jsonContent, "[", "") ; Remove starting bracket
    jsonContent := StrReplace(jsonContent, "]", "") ; Remove ending bracket
    Loop, Parse, jsonContent, {, }
    {
        ; Match each variable value
        if (RegExMatch(A_LoopField, """variable"":\s*(-?\d+)", match)) {
            sum += match1
        }
    }

    ; Write the total sum to a file called "total.json"
    totalFile := A_ScriptDir . "\json\total.json"
    totalContent := "{""total_sum"": " sum "}"
    FileDelete, %totalFile%
    FileAppend, %totalContent%, %totalFile%

    return sum
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

getChangeDateTime() {
    ; Get system timezone bias and determine local time for 1 AM EST

    ; Retrieve timezone information from Windows registry
    RegRead, TimeBias, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation, Bias
    RegRead, DltBias, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation, ActiveTimeBias

    ; Convert registry values to integers
    Bias := TimeBias + 0
    DltBias := DltBias + 0

    ; Determine if Daylight Saving Time (DST) is active
    IsDST := (Bias != DltBias) ? 1 : 0

    ; EST is UTC-5 (300 minutes offset)
    EST_Offset := 300

    ; Use the correct local offset (DST or Standard)
    Local_Offset := (IsDST) ? DltBias : Bias

    ; Convert 1 AM EST to UTC (UTC = EST + 5 hours)
    UTC_Time := 1 + EST_Offset / 60  ; 06:00 UTC

    ; Convert UTC to local time
    Local_Time := UTC_Time - (Local_Offset / 60)

    ; Round to ensure we get whole numbers
    Local_Time := Floor(Local_Time)

    ; Handle 24-hour wrap-around
    If (Local_Time < 0)
        Local_Time += 24
    Else If (Local_Time >= 24)
        Local_Time -= 24

    ; Format output as HHMM
    FormattedTime := (Local_Time < 10 ? "0" : "") . Local_Time . "00"

    Return FormattedTime
}

; This function needs to be implemented where it's used as it may have script-specific behavior
TradeTutorial() {
    if(FindOrLoseImage(100, 120, 175, 145, , "Trade", 0)) {
        LogDebug("Trade tutorial detected, handling...")
        FindImageAndClick(15, 455, 40, 475, , "Add2", 188, 449)
        Sleep, 1000
        FindImageAndClick(226, 100, 270, 135, , "Add", 38, 460, 500)
    }
    Delay(1)
}

; This function needs to be implemented where it's used as it depends on script-specific variables
LevelUp() {
    Leveled := FindOrLoseImage(100, 86, 167, 116, , "LevelUp", 0)
    if(Leveled) {
        clickButton := FindOrLoseImage(75, 340, 195, 530, 80, "Button", 0, failSafeTime)
        StringSplit, pos, clickButton, `,  ; Split at ", "
        if (scaleParam = 287) {
            pos2 += 5
        }
        adbClick(pos1, pos2)
    }
    Delay(1)
}
