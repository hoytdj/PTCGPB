;====================================================================
; INCLUDES AND INITIAL SETUP
;====================================================================
#Include %A_ScriptDir%\Include\Logger_Module.ahk
#Include %A_ScriptDir%\Include\Gdip_All.ahk
#Include %A_ScriptDir%\Include\Gdip_Imagesearch.ahk
#Include *i %A_ScriptDir%\Include\OCR.ahk
#Include %A_ScriptDir%\Include\Utils.ahk
#Include %A_ScriptDir%\Modules\AccountManagement.ahk
#Include %A_ScriptDir%\Modules\FriendManagement.ahk
#Include %A_ScriptDir%\Modules\GameFlow.ahk
#Include %A_ScriptDir%\Modules\PackRecognition.ahk
#Include %A_ScriptDir%\Modules\ImageRecognition.ahk
;====================================================================
; SCRIPT CONFIGURATION AND SETTINGS
;====================================================================
#SingleInstance on
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetBatchLines, -1
SetTitleMatchMode, 3
CoordMode, Pixel, Screen
#NoEnv

; Allocate and hide the console window to reduce flashing
DllCall("AllocConsole")
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")

;====================================================================
; GLOBAL VARIABLES
;====================================================================
global winTitle, changeDate, failSafe, openPack, Delay, failSafeTime, StartSkipTime, Columns, failSafe, scriptName, GPTest, StatusText, defaultLanguage, setSpeed, jsonFileName, pauseToggle, SelectedMonitorIndex, swipeSpeed, godPack, scaleParam, deleteMethod, packs, FriendID, friendIDs, Instances, username, friendCode, stopToggle, friended, runMain, Mains, showStatus, injectMethod, packMethod, loadDir, loadedAccount, nukeAccount, CheckShiningPackOnly, TrainerCheck, FullArtCheck, RainbowCheck, ShinyCheck, dateChange, foundGP, friendsAdded, minStars, PseudoGodPack, Palkia, Dialga, Mew, Pikachu, Charizard, Mewtwo, packArray, CrownCheck, ImmersiveCheck, InvalidCheck, slowMotion, screenShot, accountFile, invalid, starCount, keepAccount, minStarsA1Charizard, minStarsA1Mewtwo, minStarsA1Pikachu, minStarsA1a, minStarsA2Dialga, minStarsA2Palkia, minStarsA2a, minStarsA2b
global DeadCheck, sendAccountXml, applyRoleFilters, MockGodPack, MockSinglePack, gpFoundTime
global statusLastMessage := {}
global statusLastUpdateTime := {}
global statusUpdateInterval := 2 ; Seconds between updates of the same message
global s4tEnabled, s4tSilent, s4t3Dmnd, s4t4Dmnd, s4t1Star, s4tGholdengo, s4tWP, s4tWPMinCards, s4tDiscordWebhookURL, s4tDiscordUserId, s4tSendAccountXml

;====================================================================
; SCRIPT INITIALIZATION AND SETTINGS LOADING
;====================================================================
scriptName := StrReplace(A_ScriptName, ".ahk")
winTitle := scriptName
foundGP := false
injectMethod := false
pauseToggle := false
showStatus := true
friended := false
dateChange := false
jsonFileName := A_ScriptDir . "\..\json\Packs.json"

;--------------------- GENERAL SETTINGS ---------------------
IniRead, FriendID, %A_ScriptDir%\..\Settings.ini, UserSettings, FriendID
IniRead, waitTime, %A_ScriptDir%\..\Settings.ini, UserSettings, waitTime, 5
IniRead, Delay, %A_ScriptDir%\..\Settings.ini, UserSettings, Delay, 250
IniRead, folderPath, %A_ScriptDir%\..\Settings.ini, UserSettings, folderPath, C:\Program Files\Netease
IniRead, Instances, %A_ScriptDir%\..\Settings.ini, UserSettings, Instances, 1
IniRead, DeadCheck, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck, 0
IniRead, ocrLanguage, %A_ScriptDir%\..\Settings.ini, UserSettings, ocrLanguage, en

;--------------------- DISCORD INTEGRATION ---------------------
IniRead, discordWebhookURL, %A_ScriptDir%\..\Settings.ini, UserSettings, discordWebhookURL, ""
IniRead, discordUserId, %A_ScriptDir%\..\Settings.ini, UserSettings, discordUserId, ""
IniRead, sendAccountXml, %A_ScriptDir%\..\Settings.ini, UserSettings, sendAccountXml, 0

;--------------------- UI AND DISPLAY SETTINGS ---------------------
IniRead, Columns, %A_ScriptDir%\..\Settings.ini, UserSettings, Columns, 5
IniRead, defaultLanguage, %A_ScriptDir%\..\Settings.ini, UserSettings, defaultLanguage, Scale125
IniRead, SelectedMonitorIndex, %A_ScriptDir%\..\Settings.ini, UserSettings, SelectedMonitorIndex, 1
IniRead, showStatus, %A_ScriptDir%\..\Settings.ini, UserSettings, showStatus, 1

;--------------------- AUTOMATION SETTINGS ---------------------
IniRead, godPack, %A_ScriptDir%\..\Settings.ini, UserSettings, godPack, Continue
IniRead, swipeSpeed, %A_ScriptDir%\..\Settings.ini, UserSettings, swipeSpeed, 300
IniRead, deleteMethod, %A_ScriptDir%\..\Settings.ini, UserSettings, deleteMethod, 3 Pack
IniRead, runMain, %A_ScriptDir%\..\Settings.ini, UserSettings, runMain, 1
IniRead, Mains, %A_ScriptDir%\..\Settings.ini, UserSettings, Mains, 1
IniRead, nukeAccount, %A_ScriptDir%\..\Settings.ini, UserSettings, nukeAccount, 0
IniRead, packMethod, %A_ScriptDir%\..\Settings.ini, UserSettings, packMethod, 0
IniRead, slowMotion, %A_ScriptDir%\..\Settings.ini, UserSettings, slowMotion, 0
IniRead, applyRoleFilters, %A_ScriptDir%\..\Settings.ini, UserSettings, applyRoleFilters, 0
IniRead, debugMode, %A_ScriptDir%\..\Settings.ini, UserSettings, debugMode, 0

;--------------------- PACK CHECKING SETTINGS ---------------------
IniRead, CheckShiningPackOnly, %A_ScriptDir%\..\Settings.ini, UserSettings, CheckShiningPackOnly, 0
IniRead, TrainerCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, TrainerCheck, 0
IniRead, FullArtCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, FullArtCheck, 0
IniRead, RainbowCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, RainbowCheck, 0
IniRead, ShinyCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, ShinyCheck, 0
IniRead, CrownCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, CrownCheck, 0
IniRead, ImmersiveCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, ImmersiveCheck, 0
IniRead, InvalidCheck, %A_ScriptDir%\..\Settings.ini, UserSettings, InvalidCheck, 0
IniRead, PseudoGodPack, %A_ScriptDir%\..\Settings.ini, UserSettings, PseudoGodPack, 0
IniRead, minStars, %A_ScriptDir%\..\Settings.ini, UserSettings, minStars, 0

;--------------------- BOOSTER SPECIFIC SETTINGS ---------------------
IniRead, Palkia, %A_ScriptDir%\..\Settings.ini, UserSettings, Palkia, 0
IniRead, Dialga, %A_ScriptDir%\..\Settings.ini, UserSettings, Dialga, 0
IniRead, Arceus, %A_ScriptDir%\..\Settings.ini, UserSettings, Arceus, 0
IniRead, Shining, %A_ScriptDir%\..\Settings.ini, UserSettings, Shining, 1
IniRead, Mew, %A_ScriptDir%\..\Settings.ini, UserSettings, Mew, 0
IniRead, Pikachu, %A_ScriptDir%\..\Settings.ini, UserSettings, Pikachu, 0
IniRead, Charizard, %A_ScriptDir%\..\Settings.ini, UserSettings, Charizard, 0
IniRead, Mewtwo, %A_ScriptDir%\..\Settings.ini, UserSettings, Mewtwo, 0
IniRead, minStarsA1Charizard, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA1Charizard, 0
IniRead, minStarsA1Mewtwo, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA1Mewtwo, 0
IniRead, minStarsA1Pikachu, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA1Pikachu, 0
IniRead, minStarsA1a, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA1a, 0
IniRead, minStarsA2Dialga, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA2Dialga, 0
IniRead, minStarsA2Palkia, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA2Palkia, 0
IniRead, minStarsA2a, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA2a, 0
IniRead, minStarsA2b, %A_ScriptDir%\..\Settings.ini, UserSettings, minStarsA2b, 0

;--------------------- S4T FEATURE SETTINGS ---------------------
IniRead, s4tEnabled, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tEnabled, 0
IniRead, s4tSilent, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tSilent, 1
IniRead, s4t3Dmnd, %A_ScriptDir%\..\Settings.ini, UserSettings, s4t3Dmnd, 0
IniRead, s4t4Dmnd, %A_ScriptDir%\..\Settings.ini, UserSettings, s4t4Dmnd, 0
IniRead, s4t1Star, %A_ScriptDir%\..\Settings.ini, UserSettings, s4t1Star, 0
IniRead, s4tGholdengo, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tGholdengo, 0
IniRead, s4tWP, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tWP, 0
IniRead, s4tWPMinCards, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tWPMinCards, 1
IniRead, s4tDiscordWebhookURL, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tDiscordWebhookURL
IniRead, s4tDiscordUserId, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tDiscordUserId
IniRead, s4tSendAccountXml, %A_ScriptDir%\..\Settings.ini, UserSettings, s4tSendAccountXml, 1

InitLogger()

pokemonList := ["Palkia", "Dialga", "Mew", "Pikachu", "Charizard", "Mewtwo", "Arceus", "Shining"]

packArray := []  ; Initialize an empty array

Loop, % pokemonList.MaxIndex()  ; Loop through the array
{
    pokemon := pokemonList[A_Index]  ; Get the variable name as a string
    if (%pokemon%)  ; Dereference the variable using %pokemon%
        packArray.push(pokemon)  ; Add the name to packArray
}

changeDate := getChangeDateTime() ; get server reset time

if(heartBeat)
    IniWrite, 1, %A_ScriptDir%\..\HeartBeat.ini, HeartBeat, Instance%scriptName%

; connect adb
Sleep, % scriptName * 1000

if (InStr(defaultLanguage, "100")) {
    scaleParam := 287
} else {
    scaleParam := 277
}

; Attempt to connect to ADB
ConnectAdb(folderPath)

resetWindows()

if (!godPack)
    godPack = 1
else if (godPack = "Close")
    godPack = 1
else if (godPack = "Pause")
    godPack = 2
if (godPack = "Continue")
    godPack = 3

if (!setSpeed)
    setSpeed = 1
if (setSpeed = "2x")
    setSpeed := 1
else if (setSpeed = "1x/2x")
    setSpeed := 2
else if (setSpeed = "1x/3x")
    setSpeed := 3

setSpeed := 3 ;always 1x/3x

if(InStr(deleteMethod, "Inject"))
    injectMethod := true

rerollTime := A_TickCount

initializeAdbShell()

createAccountList(scriptName)

if(injectMethod) {
    loadedAccount := loadAccount()
    nukeAccount := false
}

if(!injectMethod || !loadedAccount)
    restartGameInstance("Initializing bot...", false)

pToken := Gdip_Startup()
packs := 0

; Define default swipe params.
adbSwipeX1 := Round(35 / 277 * 535)
adbSwipeX2 := Round(267 / 277 * 535)
adbSwipeY := Round((327 - 44) / 489 * 960)
global adbSwipeParams := adbSwipeX1 . " " . adbSwipeY . " " . adbSwipeX2 . " " . adbSwipeY . " " . swipeSpeed

;====================================================================
;MAIN PROGRAM EXECUTION
;====================================================================
if(DeadCheck = 1){
    friended:= true
    menuDeleteStart()
    IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
    Reload
}else{
    Loop {
        Randmax := packArray.Length()
        Random, rand, 1, Randmax
        openPack := packArray[rand]
        friended := false
        IniWrite, 1, %A_ScriptDir%\..\HeartBeat.ini, HeartBeat, Instance%scriptName%
        FormatTime, CurrentTime,, HHmm

        StartTime := changeDate - 45 ; 12:55 AM2355
        EndTime := changeDate + 5 ; 1:01 AM

        ; Adjust for crossing midnight
        if (StartTime < 0)
            StartTime += 2400
        if (EndTime >= 2400)
            EndTime -= 2400

        Random, randomTime, 3, 7

        While(((CurrentTime - StartTime >= 0) && (CurrentTime - StartTime <= randomTime)) || ((EndTime - CurrentTime >= 0) && (EndTime - CurrentTime <= randomTime)))
        {
			CreateStatusMessage("I need a break... Sleeping until " . changeDate + randomTime . " `nto avoid being kicked out from the date change")
			LogInfo("I need a break... Sleeping until " . changeDate + randomTime . " to avoid being kicked out from the date change")
            FormatTime, CurrentTime,, HHmm ; Update the current time after sleep
            Sleep, 5000
            dateChange := true
        }
        if(dateChange)
            createAccountList(scriptName)
        FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
        if(setSpeed = 3)
            FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
        else
            FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
        Delay(1)
        adbClick(41, 296)
        Delay(1)

        packs := 0
        keepAccount := false

        ; BallCity 2025.02.21 - Keep track of additional metrics
        now := A_NowUTC
        IniWrite, %now%, %A_ScriptDir%\%scriptName%.ini, Metrics, LastStartTimeUTC
        EnvSub, now, 1970, seconds
        IniWrite, %now%, %A_ScriptDir%\%scriptName%.ini, Metrics, LastStartEpoch

        if(!injectMethod || !loadedAccount)
            DoTutorial()

        ;    SquallTCGP 2025.03.12 -     Adding the delete method 5 Pack (Fast) to the wonder pick check.
        if(deleteMethod = "5 Pack" || deleteMethod = "5 Pack (Fast)" || packMethod)
            if(!loadedAccount)
                wonderPicked := DoWonderPick()

        friendsAdded := AddFriends()
        SelectPack("First")
        PackOpening()

        if(packMethod) {
            friendsAdded := AddFriends(true)
            SelectPack()
        }

        PackOpening()

        if(!injectMethod || !loadedAccount)
            HourglassOpening() ;deletemethod check in here at the start

        if(wonderPicked) {

            ; SquallTCGP 2025.03.12 - Added a check to not add friends if the delete method is 5 Pack (Fast). When using this method (5 Pack (Fast)),
            ;                         it goes to the social menu and clicks the home button to exit (instead of opening all packs directly)
            ;                         just to get around the checking for a level after opening a pack. This change is made based on the
            ;                         5p-no delete community mod created by DietPepperPhD in the discord server.

            if(deleteMethod != "5 Pack (Fast)") {
                friendsAdded := AddFriends(true)
            } else {
                FindImageAndClick(120, 500, 155, 530, , "Social", 143, 518, 500)
                FindImageAndClick(20, 500, 55, 530, , "Home", 40, 516, 500)
            }
            SelectPack("HGPack")
            PackOpening()
            if(packMethod) {
                friendsAdded := AddFriends(true)
                SelectPack("HGPack")
                PackOpening()
            }
            else {
                HourglassOpening(true)
            }
        }

        if (nukeAccount && !keepAccount && !injectMethod) {
            CreateStatusMessage("Deleting account...")
            menuDelete()
        } else if (friended) {
            CreateStatusMessage("Unfriending...")
            RemoveFriends()
        }

        if (injectMethod)
            loadedAccount := loadAccount()

        if (!loadedAccount)
            if (deleteMethod = "5 Pack" || packMethod)
                packs := 5

        IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck

        ; BallCity 2025.02.21 - Keep track of additional metrics
        now := A_NowUTC
        IniWrite, %now%, %A_ScriptDir%\%scriptName%.ini, Metrics, LastEndTimeUTC
        EnvSub, now, 1970, seconds
        IniWrite, %now%, %A_ScriptDir%\%scriptName%.ini, Metrics, LastEndEpoch

        rerolls++

        totalSeconds := Round((A_TickCount - rerollTime) / 1000) ; Total time in seconds
        avgtotalSeconds := Round(totalSeconds / rerolls) ; Total time in seconds
        minutes := Floor(avgtotalSeconds / 60) ; Total minutes
        seconds := Mod(avgtotalSeconds, 60) ; Remaining seconds within the minute
        mminutes := Floor(totalSeconds / 60) ; Total minutes
        sseconds := Mod(totalSeconds, 60) ; Remaining seconds within the minute
        CreateStatusMessage("Avg: " . minutes . "m " . seconds . "s | Runs: " . rerolls, "AvgRuns", 0, 510, false, true)
        LogInfo("Packs: " . packs . " | Total time: " . mminutes . "m " . sseconds . "s | Avg: " . minutes . "m " . seconds . "s | Runs: " . rerolls)

        if ((!injectMethod || !loadedAccount) && (!nukeAccount || keepAccount)) {
            ; Doing the following because:
            ; - not using the inject method
            ; - or using the inject method but an hasn't been loaded
            ; - and...
            ; - not using menu delete account
            ; - or the current account opened a desirable pack and shouldn't be deleted
            saveAccount("All")
			ResetLogThrottling()
            if (stopToggle) {
                CreateStatusMessage("Stopping...")
                LogInfo("Stopping after completing run")
                ExitApp
            }

            restartGameInstance("New Run", false)
            LogInfo("Restarting game instance...")
            Sleep, 1000
        } else if (nukeAccount && !keepAccount && !injectMethod) {
            ; Doing the following because:
            ; - using the inject method
            ; - or the account was deleted because no desirable packs were found during the last run
            AppendToJsonFile(packs)
            
            ; Check stopToggle before continuing
            if (stopToggle) {
                CreateStatusMessage("Stopping...")
                LogInfo("Stopping after completing run")
                ExitApp
            }
        } else {
            ; Reached here because:
            ; - using the inject method
            ; - or the account was deleted because no desirable packs were found during the last run
            AppendToJsonFile(packs)
			ResetLogThrottling()

            if (stopToggle) {
                CreateStatusMessage("Stopping...")
                LogInfo("Stopping after completing run")
                ExitApp
            }

            CreateStatusMessage("New Run")
			LogInfo("New Run")
        }
    }
}
return
;====================================================================
