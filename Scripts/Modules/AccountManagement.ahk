;====================================================================
; ACCOUNT MANAGEMENT MODULE
; Functions for managing accounts and screenshots
;====================================================================

; loadAccount - Loads an account from saved files
; No parameters
; Returns: Path to loaded account or false if failed
loadAccount() {
	global adbShell, adbPath, adbPort, loadDir
	CreateStatusMessage("Loading account...")
	LogInfo("Loading account...")
	currentDate := A_Now
	year := SubStr(currentDate, 1, 4)
	month := SubStr(currentDate, 5, 2)
	day := SubStr(currentDate, 7, 2)

    daysSinceBase := (year - 1900) * 365 + Floor((year - 1900) / 4)
    daysSinceBase += MonthToDays(year, month)
    daysSinceBase += day

    remainder := Mod(daysSinceBase, 3)

    saveDir := A_ScriptDir "\..\Accounts\Saved\" . remainder . "\" . winTitle

    outputTxt := saveDir . "\list.txt"

    if FileExist(outputTxt) {
        FileRead, fileContent, %outputTxt%  ; Read entire file
        fileLines := StrSplit(fileContent, "`n", "`r")  ; Split into lines

		if (fileLines.MaxIndex() >= 1) {
			cycle := 0
			Loop {
				CreateStatusMessage("Making sure XML is > 24 hours old: " . cycle . " attempts.")
				LogInfo("Making sure XML is > 24 hours old: " . cycle . " attempts.")	
				loadDir := saveDir . "\" . fileLines[1]  ; Store the first line
				test := fileExist(loadDir)

                if(!InStr(loadDir, "xml"))
                    return false
                newContent := ""
                Loop, % fileLines.MaxIndex() - 1  ; Start from the second line
                    newContent .= fileLines[A_Index + 1] "`r`n"

                FileDelete, %outputTxt%  ; Delete old file
                FileAppend, %newContent%, %outputTxt%  ; Write back without the first line

                FileGetTime, fileTime, %loadDir%, M  ; Get last modified time
                timeDiff := A_Now - fileTime

                if (timeDiff > 86400)
                    break
                cycle++
                Delay(1)
            }
        } else return false
    } else return false

    adbShell.StdIn.WriteLine("am force-stop jp.pokemon.pokemontcgp")

    RunWait, % adbPath . " -s 127.0.0.1:" . adbPort . " push " . loadDir . " /sdcard/deviceAccount.xml",, Hide

    Sleep, 500

    adbShell.StdIn.WriteLine("cp /sdcard/deviceAccount.xml /data/data/jp.pokemon.pokemontcgp/shared_prefs/deviceAccount:.xml")
    waitadb()
    adbShell.StdIn.WriteLine("rm /sdcard/deviceAccount.xml")
    waitadb()
    adbShell.StdIn.WriteLine("am start -n jp.pokemon.pokemontcgp/com.unity3d.player.UnityPlayerActivity")
    waitadb()
    Sleep, 1000

    FileSetTime,, %loadDir%

    return loadDir
}

; saveAccount - Saves the current account
; Parameters:
;   file - Type of account to save
;   filePath - Reference to store the full path
;   packDetails - Additional details for tradeable packs
; Returns: Name of saved XML file
saveAccount(file := "Valid", ByRef filePath := "", packDetails := "") {
	LogInfo("Saving account...")
    currentDate := A_Now
    year := SubStr(currentDate, 1, 4)
    month := SubStr(currentDate, 5, 2)
    day := SubStr(currentDate, 7, 2)

    daysSinceBase := (year - 1900) * 365 + Floor((year - 1900) / 4)
    daysSinceBase += MonthToDays(year, month)
    daysSinceBase += day

    remainder := Mod(daysSinceBase, 3)

    filePath := ""

    if (file = "All") {
        saveDir := A_ScriptDir "\..\Accounts\Saved\" . remainder . "\" . winTitle
        filePath := saveDir . "\" . A_Now . "_" . winTitle . ".xml"
    } else if (file = "Valid" || file = "Invalid") {
        saveDir := A_ScriptDir "\..\Accounts\GodPacks\"
        xmlFile := A_Now . "_" . winTitle . "_" . file . "_" . packs . "_packs.xml"
        filePath := saveDir . xmlFile
    } else if (file = "Tradeable") {
        saveDir := A_ScriptDir "\..\Accounts\Trades\"
        xmlFile := A_Now . "_" . winTitle . "_" . file . (packDetails ? "_" . packDetails : "") . "_" . packs . "_packs.xml"
        filePath := saveDir . xmlFile
    } else {
        saveDir := A_ScriptDir "\..\Accounts\SpecificCards\"
        xmlFile := A_Now . "_" . winTitle . "_" . file . "_" . packs . "_packs.xml"
        filePath := saveDir . xmlFile
    }

    if !FileExist(saveDir) ; Check if the directory exists
        FileCreateDir, %saveDir% ; Create the directory if it doesn't exist

	count := 0
	Loop {
		CreateStatusMessage("Attempting to save account XML. " . count . "/10")
		LogDebug("Attempting to save account XML. " . count . "/10")	

        adbShell.StdIn.WriteLine("cp -f /data/data/jp.pokemon.pokemontcgp/shared_prefs/deviceAccount:.xml /sdcard/deviceAccount.xml")
        waitadb()
        Sleep, 500

        RunWait, % adbPath . " -s 127.0.0.1:" . adbPort . " pull /sdcard/deviceAccount.xml """ . filePath,, Hide

        Sleep, 500

        adbShell.StdIn.WriteLine("rm /sdcard/deviceAccount.xml")

        Sleep, 500

        FileGetSize, OutputVar, %filePath%

        if(OutputVar > 0)
            break

        if(count > 10 && file != "All") {
            CreateStatusMessage("Account not saved. Pausing...")
			LogWarning("Account not saved. Pausing...")
            LogToDiscord("Attempted to save account in " . scriptName . " but was unsuccessful. Pausing. You will need to manually extract.", Screenshot(), true)
            LogDiscord("Attempted to save account but was unsuccessful. Pausing. You will need to manually extract.")
            Pause, On
        }
        count++
    }

    return xmlFile
}

; Screenshot - Takes a screenshot of the current pack
; Parameters:
;   fileType - Type of screenshot
;   subDir - Subdirectory to save in
;   fileName - Reference to store the filename
; Returns: Path to saved screenshot
Screenshot(fileType := "Valid", subDir := "", ByRef fileName := "") {
    global packs
    SetWorkingDir %A_ScriptDir%  ; Ensures the working directory is the script's directory

    ; Define folder and file paths
    fileDir := A_ScriptDir "\..\Screenshots"
    if (subDir) {
        fileDir .= "\" . subDir
    }
    if !FileExist(fileDir)
        FileCreateDir, fileDir

    ; File path for saving the screenshot locally
    fileName := A_Now . "_" . winTitle . "_" . fileType . "_" . packs . "_packs.png"
    filePath := fileDir "\" . fileName

    pBitmapW := from_window(WinExist(winTitle))
    pBitmap := Gdip_CloneBitmapArea(pBitmapW, 18, 175, 240, 227)
    ;scale 100%
    if (scaleParam = 287) {
    pBitmap := Gdip_CloneBitmapArea(pBitmapW, 17, 168, 245, 230)
    }
    Gdip_DisposeImage(pBitmapW)
    Gdip_SaveBitmapToFile(pBitmap, filePath)
    Gdip_DisposeImage(pBitmap)

    return filePath
}

; createAccountList - Creates a list of accounts
; Parameters:
;   instance - Instance number
createAccountList(instance) {
    currentDate := A_Now
    year := SubStr(currentDate, 1, 4)
    month := SubStr(currentDate, 5, 2)
    day := SubStr(currentDate, 7, 2)

    daysSinceBase := (year - 1900) * 365 + Floor((year - 1900) / 4)
    daysSinceBase += MonthToDays(year, month)
    daysSinceBase += day

    remainder := Mod(daysSinceBase, 3)

    saveDir := A_ScriptDir "\..\Accounts\Saved\" . remainder . "\" . instance
    outputTxt := saveDir . "\list.txt"

    if FileExist(outputTxt) {
        FileGetTime, fileTime, %outputTxt%, M  ; Get last modified time
        timeDiff := A_Now - fileTime  ; Calculate time difference
        if (timeDiff > 86400)  ; 24 hours in seconds (60 * 60 * 24)
            FileDelete, %outputTxt%
    }
    if (!FileExist(outputTxt)) {
        Loop, %saveDir%\*.xml {
            xml := saveDir . "\" . A_LoopFileName
            FileGetTime, fileTime, %xml%, M
            timeDiff := A_Now - fileTime  ; Calculate time difference
            if (timeDiff > 86400) {  ; 24 hours in seconds (60 * 60 * 24)
                FileAppend, % A_LoopFileName "`n", %outputTxt%  ; Append file path to output.txt\
            }
        }
    }
}

; AppendToJsonFile - Add data to the JSON log file
; Parameters:
;   variableValue - The value to add to the JSON file
AppendToJsonFile(variableValue) {
    global jsonFileName
    if (!jsonFileName || !variableValue) {
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