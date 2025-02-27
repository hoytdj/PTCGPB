#SingleInstance on
;SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
;SetWinDelay, -1
;SetControlDelay, -1
SetBatchLines, -1
SetTitleMatchMode, 3

global adbShell, adbPath, adbPorts, winTitle, folderPath

IniRead, winTitle, InjectAccount.ini, UserSettings, winTitle, 1
IniRead, fileName, InjectAccount.ini, UserSettings, fileName, name
IniRead, folderPath, InjectAccount.ini, UserSettings, folderPath, C:\Program Files\Netease

Gui, Add, Text,, This tool is to INJECT the account into the instance.`nIt will OVERWRITE any current account in that instance and you will LOSE it!
Gui, Add, Text,, Instance Name:
Gui, Add, Edit, vwinTitle w200, %winTitle%
Gui, Add, Text,, File Name (without spaces and without .xml):
Gui, Add, Edit, vfileName w200, %fileName%
Gui, Add, Text,, MuMu Folder same as main script (C:\Program Files\Netease)
Gui, Add, Edit, vfolderPath w200, %folderPath%
Gui, Add, Button, gSaveSettings, Submit
Gui, Show, , Arturo's Account Injection Tool ;'
Return

SaveSettings:
	Gui, Submit, NoHide
	Gui, Destroy
	IniWrite, %winTitle%, InjectAccount.ini, UserSettings, winTitle
	IniWrite, %fileName%, InjectAccount.ini, UserSettings, fileName
	IniWrite, %folderPath%, InjectAccount.ini, UserSettings, folderPath

	MsgBox, Settings submitted!`nClosing the game and  injecting the account. `nIt takes a few seconds. `nYou'll get another message box telling you it's ready.

	adbPath := folderPath . "\MuMuPlayerGlobal-12.0\shell\adb.exe"
	findAdbPorts(folderPath)

	if(!WinExist(winTitle)) {
		Msgbox, 16, , Can't find instance: %winTitle%. Make sure that instance is running.;'
		ExitApp
	}

	if !FileExist(adbPath) ;if international mumu file path isn't found look for chinese domestic path
		adbPath := folderPath . "\MuMu Player 12\shell\adb.exe"

	if !FileExist(adbPath) {
		MsgBox, 16, , Double check your folder path! It should be the one that contains the MuMuPlayer 12 folder! `nDefault is just C:\Program Files\Netease
		ExitApp
	}

	if(!adbPorts) {
		Msgbox, 16, , Invalid port... Check the common issues section in the readme/github guide.
		ExitApp
	}

	filePath := A_ScriptDir . "\" . fileName . ".xml"
	if(!FileExist(filePath)) {
		filePath := A_ScriptDir . "\GodPacks\" . fileName . ".xml"
		if(!FileExist(filePath)) {
			filePath := A_ScriptDir . "\SpecificCards\" . fileName . ".xml"
			if(!FileExist(filePath)) {
				Msgbox, 16, , Can't find XML file: %filePath% ;'
				ExitApp
			}
		}
	}
	RunWait, %adbPath% connect 127.0.0.1:%adbPorts%,, Hide

	MaxRetries := 10
	RetryCount := 0
	Loop {
		try {
			if (!adbShell) {
				adbShell := ComObjCreate("WScript.Shell").Exec(adbPath . " -s 127.0.0.1:" . adbPorts . " shell")
				; Extract the Process ID
				processID := adbShell.ProcessID

				; Wait for the console window to open using the process ID
				WinWait, ahk_pid %processID%

				; Minimize the window using the process ID
				WinMinimize, ahk_pid %processID%

				adbShell.StdIn.WriteLine("su")
			}
			else if (adbShell.Status != 0) {
				Sleep, 1000
			}
			else {
				Sleep, 1000
				break
			}
		}
		catch {
			RetryCount++
			if(RetryCount > MaxRetries) {
				Pause
			}
		}
		Sleep, 1000
	}

	loadAccount()

	MsgBox Injected account %fileName%.xml into instance: %winTitle%

ExitApp
return

findAdbPorts(baseFolder := "C:\Program Files\Netease") {
	global adbPorts, winTitle
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
				if(playerName1 = winTitle) {
					adbPorts := adbPort
				}
			}
		}
	}
}

loadAccount() {
	global adbShell, adbPath, adbPorts, fileName
	if (!adbShell) {
		adbShell := ComObjCreate("WScript.Shell").Exec(adbPath . " -s 127.0.0.1:" . adbPorts . " shell")
		; Extract the Process ID
		processID := adbShell.ProcessID

		; Wait for the console window to open using the process ID
		WinWait, ahk_pid %processID%

		; Minimize the window using the process ID
		WinMinimize, ahk_pid %processID%
	}

	adbShell.StdIn.WriteLine("am force-stop jp.pokemon.pokemontcgp")

	loadDir := A_ScriptDir . "\" . fileName
	if (!FileExist(loadDir))
		loadDir := A_ScriptDir . "\GodPacks\" . fileName
	if (!FileExist(loadDir))
		loadDir := A_ScriptDir . "\SpecificCards\" . fileName

	RunWait, % adbPath . " -s 127.0.0.1:" . adbPorts . " push """ . loadDir . ".xml""" . " /sdcard/deviceAccount.xml",, Hide

	Sleep, 500

	adbShell.StdIn.WriteLine("cp /sdcard/deviceAccount.xml /data/data/jp.pokemon.pokemontcgp/shared_prefs/deviceAccount:.xml")

	Sleep, 500

	adbShell.StdIn.WriteLine("rm /sdcard/deviceAccount.xml")
	adbShell.StdIn.WriteLine("am start -n jp.pokemon.pokemontcgp/com.unity3d.player.UnityPlayerActivity")
}
