#Include %A_ScriptDir%\Scripts\Include\Logger_Module.ahk
#Include %A_ScriptDir%\Scripts\Include\Gdip_All.ahk
#Include %A_ScriptDir%\Scripts\Include\Gdip_Imagesearch.ahk
#Include %A_ScriptDir%\Scripts\Include\Utils.ahk
#Include %A_ScriptDir%\Scripts\Include\Gdip_Extra.ahk
#Include %A_ScriptDir%\Scripts\Include\StringCompare.ahk
#Include %A_ScriptDir%\Scripts\Include\OCR.ahk
#Include %A_ScriptDir%\Scripts\Include\ImagePut.ahk

version = Arturos PTCGP Bot
#SingleInstance, force
CoordMode, Mouse, Screen
SetTitleMatchMode, 3

; Add custom message handlers for button coloring
OnMessage(0x0133, "WM_CTLCOLORSTATIC")  ; Add handler for static controls
OnMessage(0x0135, "WM_CTLCOLORBTN")      ; Add handler for button controls
OnMessage(0x0138, "WM_CTLCOLORSTATIC")   ; Add handler for listbox controls

; Declare brush handles to clean up properly
global STATIC_BRUSH := 0
global BTN_BRUSH := 0
global EDIT_BRUSH := 0
global g_ButtonColors := {}  ; Store button colors by hwnd

githubUser := "gfrcr"
repoName := "PTCGPB"
localVersion := "v1.4.5.9"
scriptFolder := A_ScriptDir
zipPath := A_Temp . "\update.zip"
extractPath := A_Temp . "\update"

; GUI dimensions constants
global GUI_WIDTH := 480  ; Adjusted from 510 to 480
global GUI_HEIGHT := 750 ; Adjusted from 850 to 750

; Image scaling and ratio constants for 720p compatibility
global IMG_SCALE_RATIO := 0.5625 ; 720/1280 for aspect ratio preservation
global UI_ELEMENT_SCALE := 0.85  ; Scale UI elements to fit smaller dimensions

; Added new global variable for background image toggle
global useBackgroundImage := true

global scriptName, winTitle, FriendID, Instances, instanceStartDelay, jsonFileName, PacksText, runMain, Mains, scaleParam
global CurrentVisibleSection
global FriendID_Divider, Instance_Divider3
global System_Divider1, System_Divider2, System_Divider3, System_Divider4
global Pack_Divider1, Pack_Divider2, Pack_Divider3
global SaveForTradeDivider_1, SaveForTradeDivider_2
global Discord_Divider3
global tesseractPath, applyRoleFilters, debugMode
global tesseractOption

if not A_IsAdmin
{
    ; Relaunch script with admin rights
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; Check for debugMode and display license notification if not in debug mode
IniRead, debugMode, Settings.ini, UserSettings, debugMode, 0
if (!debugMode)
{
    MsgBox, 64, The project is now licensed under CC BY-NC 4.0, The original intention of this project was not for it to be used for paid services even those disguised as 'donations.' I hope people respect my wishes and those of the community. `nThe project is now licensed under CC BY-NC 4.0, which allows you to use, modify, and share the software only for non-commercial purposes. Commercial use, including using the software to provide paid services or selling it (even if donations are involved), is not allowed under this license. The new license applies to this and all future releases.
    CheckForUpdate()
}

; Define refined global color variables for consistent theming
global DARK_BG := "232736"          ; Deeper blue-gray background
global DARK_CONTROL_BG := "2E3440"  ; Slightly lighter panel background
global DARK_ACCENT := "5E81AC"      ; Softer blue accent
global DARK_TEXT := "ECEFF4"        ; Crisp white text with slight blue tint
global DARK_TEXT_SECONDARY := "D8DEE9" ; Slightly dimmed secondary text

global LIGHT_BG := "F0F5F9"         ; Soft light background with blue hint
global LIGHT_CONTROL_BG := "FFFFFF" ; Pure white for controls
global LIGHT_ACCENT := "5E81AC"     ; Same accent for consistency
global LIGHT_TEXT := "2E3440"       ; Dark text that matches dark mode background
global LIGHT_TEXT_SECONDARY := "4C566A" ; Medium gray with blue tint

; Define input field colors for light and dark themes
global DARK_INPUT_BG := "3B4252"    ; Slightly lighter than control background
global DARK_INPUT_TEXT := "ECEFF4"  ; Same as main text
global LIGHT_INPUT_BG := "ECEFF4"   ; Light gray with blue tint
global LIGHT_INPUT_TEXT := "2E3440" ; Dark text

; Section colors - Dark theme
global DARK_SECTION_COLORS := {}
DARK_SECTION_COLORS["RerollSettings"] := "5E81AC"   ; Blue (NEW)
DARK_SECTION_COLORS["FriendID"] := "5E81AC"       ; Blue
DARK_SECTION_COLORS["InstanceSettings"] := "81A1C1" ; Lighter blue
DARK_SECTION_COLORS["TimeSettings"] := "88C0D0"     ; Cyan
DARK_SECTION_COLORS["SystemSettings"] := "8FBCBB"   ; Teal
DARK_SECTION_COLORS["PackSettings"] := "B48EAD"  ; Purple (renamed from GodPackSettings)
DARK_SECTION_COLORS["SaveForTrade"] := "D08770"     ; Orange
DARK_SECTION_COLORS["DiscordSettings"] := "7289DA"  ; Discord Blue
DARK_SECTION_COLORS["DownloadSettings"] := "A3BE8C"   ; Green

; Section colors - Light theme
global LIGHT_SECTION_COLORS := {}
LIGHT_SECTION_COLORS["RerollSettings"] := "5E81AC"   ; Blue (NEW)
LIGHT_SECTION_COLORS["FriendID"] := "5E81AC"       ; Blue
LIGHT_SECTION_COLORS["InstanceSettings"] := "81A1C1" ; Lighter blue
LIGHT_SECTION_COLORS["TimeSettings"] := "88C0D0"     ; Cyan
LIGHT_SECTION_COLORS["SystemSettings"] := "8FBCBB"   ; Teal
LIGHT_SECTION_COLORS["PackSettings"] := "B48EAD"  ; Purple (renamed from GodPackSettings)
LIGHT_SECTION_COLORS["SaveForTrade"] := "EBCB8B"     ; Yellow
LIGHT_SECTION_COLORS["DiscordSettings"] := "7289DA"  ; Discord Blue
LIGHT_SECTION_COLORS["DownloadSettings"] := "A3BE8C"   ; Green

; Button colors - Initially undefined, will be set in ApplyTheme()
global BTN_START := ""
global BTN_LAUNCH := ""
global BTN_ARRANGE := ""
global BTN_COFFEE := ""
global BTN_DISCORD := ""
global BTN_UPDATE := ""
global BTN_RELOAD := ""

; Button coloring functions
; Function to create a solid color brush
CreateSolidBrush(RGB_value) {
    return DllCall("CreateSolidBrush", "UInt", RGB_value, "UPtr")
}

; Function to convert RGB to BGR for Windows API
RGB(r, g, b) {
    return (b << 16) | (g << 8) | r
}

; Function to convert hex color to RGB value
HexToRGB(color) {
    ; Check if the color has a # prefix and remove it
    if (SubStr(color, 1, 1) = "#")
        color := SubStr(color, 2)
    
    ; Convert hex to RGB integer
    return "0x" . SubStr(color, 5, 2) . SubStr(color, 3, 2) . SubStr(color, 1, 2)
}

; Message handler for button controls
WM_CTLCOLORBTN(wParam, lParam) {
    global g_ButtonColors, BTN_BRUSH
    hwnd := lParam
    
    ; If we have a color saved for this button, use it
    if (g_ButtonColors.HasKey(hwnd)) {
        color := g_ButtonColors[hwnd]
        
        ; Delete old brush if exists to prevent memory leaks
        if (BTN_BRUSH)
            DllCall("DeleteObject", "Ptr", BTN_BRUSH)
        
        ; Create new brush with the saved color
        BTN_BRUSH := CreateSolidBrush(HexToRGB(color))
        return BTN_BRUSH
    }
    return 0  ; Default handling
}

; Message handler for static controls
WM_CTLCOLORSTATIC(wParam, lParam) {
    global isDarkTheme, STATIC_BRUSH, DARK_TEXT, LIGHT_TEXT, DARK_BG, LIGHT_BG
    
    ; Get the background color based on theme
    bgColor := isDarkTheme ? DARK_BG : LIGHT_BG
    textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
    
    ; Set text color for the static control
    DllCall("SetTextColor", "Ptr", wParam, "UInt", HexToRGB(textColor))
    
    ; Set background color for the static control
    DllCall("SetBkColor", "Ptr", wParam, "UInt", HexToRGB(bgColor))
    
    ; Delete old brush to prevent memory leaks
    if (STATIC_BRUSH)
        DllCall("DeleteObject", "Ptr", STATIC_BRUSH)
    
    ; Create and return a brush with the background color
    STATIC_BRUSH := CreateSolidBrush(HexToRGB(bgColor))
    return STATIC_BRUSH
}

; Function to set button color
SetButtonColor(hwnd, color) {
    global g_ButtonColors
    g_ButtonColors[hwnd] := color
    
    ; Force redraw to apply color immediately
    WinSet, Redraw,, ahk_id %hwnd%
}

; Improved font functions with better hierarchy and reduced sizes
SetArturoFont() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    if (isDarkTheme)
        Gui, Font, s12 bold c%DARK_TEXT%, Segoe UI
    else
        Gui, Font, s12 bold c%LIGHT_TEXT%, Segoe UI
}

SetTitleFont() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    if (isDarkTheme)
        Gui, Font, s10 bold c%DARK_TEXT%, Segoe UI
    else
        Gui, Font, s10 bold c%LIGHT_TEXT%, Segoe UI
}

IsNumeric(var) {
    if var is number
        return true
    return false
}

SetSectionFont() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    if (isDarkTheme)
        Gui, Font, s10 bold c%DARK_TEXT%, Segoe UI  ; Reduced from s12
    else
        Gui, Font, s10 bold c%LIGHT_TEXT%, Segoe UI
}

SetHeaderFont() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    if (isDarkTheme)
        Gui, Font, s9 bold c%DARK_TEXT%, Segoe UI  ; Reduced from s10
    else
        Gui, Font, s9 bold c%LIGHT_TEXT%, Segoe UI
}

SetNormalFont() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    if (isDarkTheme)
        Gui, Font, s8 c%DARK_TEXT%, Segoe UI       ; Reduced from s9
    else
        Gui, Font, s8 c%LIGHT_TEXT%, Segoe UI
}

SetSmallFont() {
    global isDarkTheme, DARK_TEXT_SECONDARY, LIGHT_TEXT_SECONDARY
    if (isDarkTheme)
        Gui, Font, s7 c%DARK_TEXT_SECONDARY%, Segoe UI  ; Reduced from s8
    else
        Gui, Font, s7 c%LIGHT_TEXT_SECONDARY%, Segoe UI
}

SetInputFont() {
    global isDarkTheme, DARK_INPUT_TEXT, LIGHT_INPUT_TEXT
    if (isDarkTheme)
        Gui, Font, s8 c%DARK_INPUT_TEXT%, Segoe UI  ; Reduced from s9
    else
        Gui, Font, s8 c%LIGHT_INPUT_TEXT%, Segoe UI
}

; Function to update ALL text controls with appropriate color
SetAllTextColors(textColor) {
    ; List all text controls that need color updates
    GuiControl, +c%textColor%, Txt_Instances
    GuiControl, +c%textColor%, Txt_InstanceStartDelay
    GuiControl, +c%textColor%, Txt_Columns
    GuiControl, +c%textColor%, runMain

    GuiControl, +c%textColor%, Txt_Delay
    GuiControl, +c%textColor%, Txt_WaitTime
    GuiControl, +c%textColor%, Txt_SwipeSpeed
    GuiControl, +c%textColor%, slowMotion

    GuiControl, +c%textColor%, Txt_Monitor
    GuiControl, +c%textColor%, Txt_Scale
    GuiControl, +c%textColor%, Txt_FolderPath
    GuiControl, +c%textColor%, Txt_OcrLanguage
    GuiControl, +c%textColor%, Txt_ClientLanguage
    GuiControl, +c%textColor%, Txt_InstanceLaunchDelay
    GuiControl, +c%textColor%, autoLaunchMonitor

    GuiControl, +c%textColor%, Txt_MinStars
    GuiControl, +c%textColor%, Txt_A2bMinStar
    GuiControl, +c%textColor%, Txt_DeleteMethod
    GuiControl, +c%textColor%, packMethod
    GuiControl, +c%textColor%, nukeAccount

    GuiControl, +c%textColor%, Shining
    GuiControl, +c%textColor%, Arceus
    GuiControl, +c%textColor%, Palkia
    GuiControl, +c%textColor%, Dialga
    GuiControl, +c%textColor%, Pikachu
    GuiControl, +c%textColor%, Charizard
    GuiControl, +c%textColor%, Mewtwo
    GuiControl, +c%textColor%, Mew

    GuiControl, +c%textColor%, FullArtCheck
    GuiControl, +c%textColor%, TrainerCheck
    GuiControl, +c%textColor%, RainbowCheck
    GuiControl, +c%textColor%, PseudoGodPack
    GuiControl, +c%textColor%, CheckShiningPackOnly
    GuiControl, +c%textColor%, InvalidCheck
    GuiControl, +c%textColor%, CrownCheck
    GuiControl, +c%textColor%, ShinyCheck
    GuiControl, +c%textColor%, ImmersiveCheck

    GuiControl, +c%textColor%, s4tEnabled
    GuiControl, +c%textColor%, s4tSilent
    GuiControl, +c%textColor%, s4t3Dmnd
    GuiControl, +c%textColor%, s4t4Dmnd
    GuiControl, +c%textColor%, s4t1Star
    GuiControl, +c%textColor%, s4tGholdengo
    GuiControl, +c%textColor%, s4tWP
    GuiControl, +c%textColor%, s4tWPMinCardsLabel
    GuiControl, +c%textColor%, s4tGholdengoArrow

    GuiControl, +c%textColor%, Txt_DiscordID
    GuiControl, +c%textColor%, Txt_DiscordWebhook
    GuiControl, +c%textColor%, sendAccountXml

    GuiControl, +c%textColor%, heartBeat
    GuiControl, +c%textColor%, hbName
    GuiControl, +c%textColor%, hbURL
    GuiControl, +c%textColor%, hbDelay

    GuiControl, +c%textColor%, Txt_S4T_DiscordID
    GuiControl, +c%textColor%, Txt_S4T_DiscordWebhook
    GuiControl, +c%textColor%, s4tSendAccountXml

    GuiControl, +c%textColor%, DownloadSettingsHeading
    GuiControl, +c%textColor%, Txt_MainIdsURL
    GuiControl, +c%textColor%, Txt_VipIdsURL

    GuiControl, +c%textColor%, ActiveSection
    GuiControl, +c%textColor%, VersionInfo

    GuiControl, +c%textColor%, HeaderTitle

    ; Add additional text controls for new separators
    GuiControl, +c%textColor%, FriendIDLabel
    GuiControl, +c%textColor%, InstanceSettingsLabel
    GuiControl, +c%textColor%, TimeSettingsLabel
    GuiControl, +c%textColor%, SystemSettingsLabel
    GuiControl, +c%textColor%, PackSettingsLabel
    GuiControl, +c%textColor%, SaveForTradeLabel
    GuiControl, +c%textColor%, DiscordSettingsLabel
    GuiControl, +c%textColor%, DownloadSettingsLabel
    
    ; Extra Settings
    GuiControl, +c%textColor%, ExtraSettingsHeading
    GuiControl, +c%textColor%, tesseractOption
    GuiControl, +c%textColor%, Txt_TesseractPath
    GuiControl, +c%textColor%, applyRoleFilters
    GuiControl, +c%textColor%, debugMode
}

; Function to update all button colors
UpdateAllButtonColors() {
    global isDarkTheme
    global BTN_START, BTN_LAUNCH, BTN_ARRANGE, BTN_COFFEE, BTN_DISCORD, BTN_UPDATE, BTN_RELOAD

    ; Update colors for action buttons
    GuiControlGet, hwnd, Hwnd, StartBot
    SetButtonColor(hwnd, BTN_START)

    GuiControlGet, hwnd, Hwnd, LaunchAllMumu
    SetButtonColor(hwnd, BTN_LAUNCH)

    GuiControlGet, hwnd, Hwnd, ArrangeWindows
    SetButtonColor(hwnd, BTN_ARRANGE)

    GuiControlGet, hwnd, Hwnd, BuyMeACoffee
    SetButtonColor(hwnd, BTN_COFFEE)

    GuiControlGet, hwnd, Hwnd, JoinDiscord
    SetButtonColor(hwnd, BTN_DISCORD)

    GuiControlGet, hwnd, Hwnd, CheckUpdates
    SetButtonColor(hwnd, BTN_UPDATE)

    GuiControlGet, hwnd, Hwnd, ReloadBtn
    SetButtonColor(hwnd, BTN_RELOAD)

    ; Update background toggle button
    GuiControlGet, hwnd, Hwnd, BackgroundToggle
    SetButtonColor(hwnd, isDarkTheme ? "81A1C1" : "5E81AC")

    ; Update tab buttons
    UpdateTabButtonColors()
}

; Function to update tab button colors
UpdateTabButtonColors() {
    global CurrentVisibleSection, isDarkTheme
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
    global DARK_CONTROL_BG, LIGHT_CONTROL_BG

    ; Define tab list (updated to new structure)
    tabs := []
    tabs.Push("RerollSettings")
    tabs.Push("SystemSettings")
    tabs.Push("PackSettings")
    tabs.Push("SaveForTrade")
    tabs.Push("DiscordSettings")
    tabs.Push("DownloadSettings")

    ; Update each tab button color
    for i, tabName in tabs {
        GuiControlGet, hwnd, Hwnd, Btn_%tabName%

        if (tabName = CurrentVisibleSection) {
            ; Active tab uses section color
            sectionColor := isDarkTheme ? DARK_SECTION_COLORS[tabName] : LIGHT_SECTION_COLORS[tabName]
            SetButtonColor(hwnd, sectionColor)
        } else {
            ; Inactive tab uses default background
            inactiveColor := isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG
            SetButtonColor(hwnd, inactiveColor)
        }
    }
}

; Function to apply theme colors to the GUI
ApplyTheme() {
    global isDarkTheme, DARK_BG, DARK_CONTROL_BG, DARK_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT
    global LIGHT_BG, LIGHT_CONTROL_BG, LIGHT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global BTN_START, BTN_LAUNCH, BTN_ARRANGE, BTN_COFFEE, BTN_DISCORD, BTN_UPDATE, BTN_RELOAD
    global CurrentVisibleSection, DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    if (isDarkTheme) {
        ; Dark theme with better contrast
        Gui, Color, %DARK_BG%, %DARK_CONTROL_BG%
        GuiControl, +Background%DARK_CONTROL_BG% +c%DARK_TEXT%, ThemeToggle

        ; Update button colors for dark theme
        BTN_START := "8FBCBB"      ; Teal
        BTN_LAUNCH := "81A1C1"     ; Blue
        BTN_ARRANGE := "B48EAD"    ; Purple
        BTN_COFFEE := "EBCB8B"     ; Yellow
        BTN_DISCORD := "7289DA"    ; Discord blue
        BTN_UPDATE := "BF616A"     ; Red
        BTN_RELOAD := "A3BE8C"     ; Green

        ; Update input fields for dark theme
        SetInputBackgrounds(DARK_INPUT_BG, DARK_INPUT_TEXT)

        ; Update all text labels with dark theme colors
        SetAllTextColors(DARK_TEXT)
    } else {
        ; Light theme with better contrast
        Gui, Color, %LIGHT_BG%, %LIGHT_CONTROL_BG%
        GuiControl, +Background%LIGHT_CONTROL_BG% +c%LIGHT_TEXT%, ThemeToggle

        ; Update button colors for light theme
        BTN_START := "8FBCBB"      ; Teal
        BTN_LAUNCH := "81A1C1"     ; Blue
        BTN_ARRANGE := "B48EAD"    ; Purple
        BTN_COFFEE := "EBCB8B"     ; Yellow
        BTN_DISCORD := "7289DA"    ; Discord blue
        BTN_UPDATE := "BF616A"     ; Red
        BTN_RELOAD := "A3BE8C"     ; Green

        ; Update input fields for light theme
        SetInputBackgrounds(LIGHT_INPUT_BG, LIGHT_INPUT_TEXT)

        ; Update all text labels with light theme colors
        SetAllTextColors(LIGHT_TEXT)
    }

    ; Apply section-specific color to active section title (if any)
    if (CurrentVisibleSection != "") {
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS[CurrentVisibleSection] : LIGHT_SECTION_COLORS[CurrentVisibleSection]
        GuiControl, +c%sectionColor%, ActiveSection
    }

    ; Update all button colors using the Windows API approach
    UpdateAllButtonColors()

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()

    ; Force a redraw of the GUI to apply colors immediately
    WinSet, Redraw,, A
}

; Helper function to update all input field backgrounds
SetInputBackgrounds(bgColor, textColor) {
    ; List of all edit and input controls that need theming
    GuiControl, +Background%bgColor% +c%textColor%, FriendID
    GuiControl, +Background%bgColor% +c%textColor%, Instances
    GuiControl, +Background%bgColor% +c%textColor%, instanceStartDelay
    GuiControl, +Background%bgColor% +c%textColor%, Columns
    GuiControl, +Background%bgColor% +c%textColor%, Mains

    GuiControl, +Background%bgColor% +c%textColor%, Delay
    GuiControl, +Background%bgColor% +c%textColor%, waitTime
    GuiControl, +Background%bgColor% +c%textColor%, swipeSpeed
    GuiControl, +Background%bgColor% +c%textColor%, folderPath
    GuiControl, +Background%bgColor% +c%textColor%, instanceLaunchDelay
    GuiControl, +Background%bgColor% +c%textColor%, minStars
    GuiControl, +Background%bgColor% +c%textColor%, minStarsA2b
    GuiControl, +Background%bgColor% +c%textColor%, discordUserId
    GuiControl, +Background%bgColor% +c%textColor%, discordWebhookURL
    GuiControl, +Background%bgColor% +c%textColor%, heartBeatName
    GuiControl, +Background%bgColor% +c%textColor%, heartBeatWebhookURL
    GuiControl, +Background%bgColor% +c%textColor%, heartBeatDelay
    GuiControl, +Background%bgColor% +c%textColor%, mainIdsURL
    GuiControl, +Background%bgColor% +c%textColor%, vipIdsURL
    GuiControl, +Background%bgColor% +c%textColor%, s4tWPMinCards
    GuiControl, +Background%bgColor% +c%textColor%, s4tDiscordUserId
    GuiControl, +Background%bgColor% +c%textColor%, s4tDiscordWebhookURL
    GuiControl, +Background%bgColor% +c%textColor%, SelectedMonitorIndex
    GuiControl, +Background%bgColor% +c%textColor%, defaultLanguage
    GuiControl, +Background%bgColor% +c%textColor%, ocrLanguage
    GuiControl, +Background%bgColor% +c%textColor%, clientLanguage
    GuiControl, +Background%bgColor% +c%textColor%, deleteMethod
    GuiControl, +Background%bgColor% +c%textColor%, tesseractPath
}

; Add this function near other GUI helper functions
AddSectionDivider(x, y, w, vName) {
    ; Create a subtle divider line with a variable name for showing/hiding
    Gui, Add, Text, x%x% y%y% w%w% h1 +0x10 v%vName% Hidden, ; Horizontal line divider
}

; Add this function to apply section-specific colors to section headers
UpdateSectionHeaders() {
    global isDarkTheme, CurrentVisibleSection
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    if (CurrentVisibleSection = "")
        return

    ; Get the appropriate color for the current section
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS[CurrentVisibleSection] : LIGHT_SECTION_COLORS[CurrentVisibleSection]

    ; Apply color to section headers based on current section
    if (CurrentVisibleSection = "RerollSettings") {
        GuiControl, +c%sectionColor%, FriendIDLabel
    }
    else if (CurrentVisibleSection = "FriendID") {
        GuiControl, +c%sectionColor%, FriendIDLabel
    }
    else if (CurrentVisibleSection = "InstanceSettings") {
        GuiControl, +c%sectionColor%, Txt_Instances
    }
    else if (CurrentVisibleSection = "TimeSettings") {
        GuiControl, +c%sectionColor%, Txt_Delay
    }
    else if (CurrentVisibleSection = "SystemSettings") {
        GuiControl, +c%sectionColor%, Txt_Monitor
    }
    else if (CurrentVisibleSection = "PackSettings") {
        GuiControl, +c%sectionColor%, PackSettingsLabel
    }
    else if (CurrentVisibleSection = "SaveForTrade") {
        GuiControl, +c%sectionColor%, s4tEnabled
    }
    else if (CurrentVisibleSection = "DiscordSettings") {
        GuiControl, +c%sectionColor%, Txt_DiscordID
    }
    else if (CurrentVisibleSection = "DownloadSettings") {
        GuiControl, +c%sectionColor%, DownloadSettingsHeading
    }
}

; Function to toggle background image visibility
ToggleBackgroundImage() {
    global useBackgroundImage, isDarkTheme

    ; Toggle the setting
    useBackgroundImage := !useBackgroundImage

    ; Save the setting
    IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage

    ; Update the GUI
    if (useBackgroundImage) {
        ; Update button text
        GuiControl,, BackgroundToggle, Background Off
        ; Show background image if it exists
        GuiControl, Show, BackgroundPic
    } else {
        ; Update button text
        GuiControl,, BackgroundToggle, Background On
        ; Hide background image
        GuiControl, Hide, BackgroundPic
    }

    ; Update the solid background color to ensure it shows through
    bgColor := isDarkTheme ? DARK_BG : LIGHT_BG
    Gui, Color, %bgColor%
}

; Trace hide and show
global CurrentVisibleSection := ""

; ========== hide all section ==========
HideAllSections() {
    ; hide any section headings that might be showing
    GuiControl, Hide, PackSettingsLabel

    ; hide Friend ID section
    GuiControl, Hide, FriendIDHeading
    GuiControl, Hide, FriendID
    GuiControl, Hide, FriendIDLabel
    GuiControl, Hide, FriendIDSeparator

    ; hide Instance Settings section
    GuiControl, Hide, InstanceSettingsHeading
    GuiControl, Hide, Txt_Instances
    GuiControl, Hide, Instances
    GuiControl, Hide, Txt_InstanceStartDelay
    GuiControl, Hide, instanceStartDelay
    GuiControl, Hide, Txt_Columns
    GuiControl, Hide, Columns
    GuiControl, Hide, runMain
    GuiControl, Hide, Mains
    

    ; hide Time Settings section
    GuiControl, Hide, TimeSettingsHeading
    GuiControl, Hide, Txt_Delay
    GuiControl, Hide, Delay
    GuiControl, Hide, Txt_WaitTime
    GuiControl, Hide, waitTime
    GuiControl, Hide, Txt_SwipeSpeed
    GuiControl, Hide, swipeSpeed
    GuiControl, Hide, slowMotion
    GuiControl, Hide, TimeSettingsSeparator

    ; hide System Settings section
    GuiControl, Hide, SystemSettingsHeading
    GuiControl, Hide, Txt_Monitor
    GuiControl, Hide, SelectedMonitorIndex
    GuiControl, Hide, Txt_Scale
    GuiControl, Hide, defaultLanguage
    GuiControl, Hide, Txt_FolderPath
    GuiControl, Hide, folderPath
    GuiControl, Hide, Txt_OcrLanguage
    GuiControl, Hide, ocrLanguage
    GuiControl, Hide, Txt_ClientLanguage
    GuiControl, Hide, clientLanguage
    GuiControl, Hide, Txt_InstanceLaunchDelay
    GuiControl, Hide, instanceLaunchDelay
    GuiControl, Hide, autoLaunchMonitor
    GuiControl, Hide, SystemSettingsSeparator

    ; Extra Settings Section
    GuiControl, Hide, ExtraSettingsHeading

; hide Pack Settings section (merged God Pack, Pack Selection and Card Detection)
    GuiControl, Hide, PackSettingsHeading
    GuiControl, Hide, PackSettingsSubHeading1

    ; God Pack Settings
    GuiControl, Hide, Txt_MinStars
    GuiControl, Hide, minStars
    GuiControl, Hide, Txt_A2bMinStar
    GuiControl, Hide, minStarsA2b
    GuiControl, Hide, Txt_DeleteMethod
    GuiControl, Hide, deleteMethod
    GuiControl, Hide, packMethod
    GuiControl, Hide, nukeAccount
    GuiControl, Hide, Pack_Divider1

    ; Pack Selection
    GuiControl, Hide, PackSettingsSubHeading2
    GuiControl, Hide, Shining
    GuiControl, Hide, Arceus
    GuiControl, Hide, Palkia
    GuiControl, Hide, Dialga
    GuiControl, Hide, Pikachu
    GuiControl, Hide, Charizard
    GuiControl, Hide, Mewtwo
    GuiControl, Hide, Mew
    GuiControl, Hide, Pack_Divider2

    ; Card Detection
    GuiControl, Hide, PackSettingsSubHeading3
    GuiControl, Hide, ShinyCheck
    GuiControl, Hide, FullArtCheck
    GuiControl, Hide, TrainerCheck
    GuiControl, Hide, RainbowCheck
    GuiControl, Hide, PseudoGodPack
    GuiControl, Hide, Txt_vector
    GuiControl, Hide, Txt_Save
    GuiControl, Hide, InvalidCheck
    GuiControl, Hide, CheckShiningPackOnly
    GuiControl, Hide, CrownCheck
    GuiControl, Hide, ImmersiveCheck
    GuiControl, Hide, Pack_Divider3

    ; hide Save For Trade section (with integrated S4T Discord settings)
    GuiControl, Hide, SaveForTradeHeading
    GuiControl, Hide, s4tEnabled
    GuiControl, Hide, s4tSilent
    GuiControl, Hide, s4t3Dmnd
    GuiControl, Hide, s4t4Dmnd
    GuiControl, Hide, s4t1Star
    GuiControl, Hide, s4tGholdengo
    GuiControl, Hide, s4tGholdengoEmblem
    GuiControl, Hide, s4tGholdengoArrow
    GuiControl, Hide, Txt_S4TSeparator
    GuiControl, Hide, s4tWP
    GuiControl, Hide, s4tWPMinCardsLabel
    GuiControl, Hide, s4tWPMinCards

    ; S4T Discord Settings (now under Save For Trade)
    GuiControl, Hide, S4TDiscordSettingsSubHeading
    GuiControl, Hide, Txt_S4T_DiscordID
    GuiControl, Hide, s4tDiscordUserId
    GuiControl, Hide, Txt_S4T_DiscordWebhook
    GuiControl, Hide, s4tDiscordWebhookURL
    GuiControl, Hide, s4tSendAccountXml
    GuiControl, Hide, SaveForTradeDivider_1
    GuiControl, Hide, SaveForTradeDivider_2

    ; hide Discord Settings section (with integrated Heartbeat settings)
    GuiControl, Hide, DiscordSettingsHeading
    GuiControl, Hide, Txt_DiscordID
    GuiControl, Hide, discordUserId
    GuiControl, Hide, Txt_DiscordWebhook
    GuiControl, Hide, discordWebhookURL
    GuiControl, Hide, sendAccountXml

    ; Heartbeat Settings (now under Discord)
    GuiControl, Hide, HeartbeatSettingsSubHeading
    GuiControl, Hide, heartBeat
    GuiControl, Hide, hbName
    GuiControl, Hide, heartBeatName
    GuiControl, Hide, hbURL
    GuiControl, Hide, heartBeatWebhookURL
    GuiControl, Hide, heartBeatDelay
    GuiControl, Hide, hbDelay
    GuiControl, Hide, DiscordSettingsSeparator

    ; hide Download Settings section
    GuiControl, Hide, DownloadSettingsHeading
    GuiControl, Hide, Txt_MainIdsURL
    GuiControl, Hide, mainIdsURL
    GuiControl, Hide, Txt_VipIdsURL
    GuiControl, Hide, vipIdsURL

    ; hide Reroll Settings separator
    GuiControl, Hide, RerollSettingsSeparator
    
    ; hide Extra Settings section
    GuiControl, Hide, ExtraSettingsHeading
    GuiControl, Hide, tesseractOption
    GuiControl, Hide, Txt_TesseractPath
    GuiControl, Hide, tesseractPath
    GuiControl, Hide, applyRoleFilters
    GuiControl, Hide, debugMode
    
    ; Hide ALL divider elements - this is the key part that was missing!
    GuiControl, Hide, FriendID_Divider
    GuiControl, Hide, Instance_Divider3
    GuiControl, Hide, System_Divider1
    GuiControl, Hide, System_Divider2
    GuiControl, Hide, System_Divider3
    GuiControl, Hide, System_Divider4
    GuiControl, Hide, Pack_Divider1
    GuiControl, Hide, Pack_Divider2
    GuiControl, Hide, Pack_Divider3
    GuiControl, Hide, Discord_Divider3
    GuiControl, Hide, SaveForTrade_Divider1
    GuiControl, Hide, SaveForTrade_Divider2
}

; ========== show Reroll Settings section (Updated) ==========
ShowRerollSettingsSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    ; Get the section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS["RerollSettings"] : LIGHT_SECTION_COLORS["RerollSettings"]

    ; === Friend ID Section with Heading ===
    ; Show and style existing heading for Friend ID
    GuiControl, Show, FriendIDHeading
    GuiControl, +c%sectionColor%, FriendIDHeading

    ; Show Friend ID controls with adjusted positions
    GuiControl, Show, FriendIDLabel
    GuiControl, Show, FriendID

    ; Show FriendID divider
    GuiControl, Show, FriendID_Divider

    ; === Instance Settings Section with Heading ===
    ; Show and style existing heading for Instance Settings
    GuiControl, Show, InstanceSettingsHeading
    GuiControl, +c%sectionColor%, InstanceSettingsHeading

    ; Show Instance Settings controls with adjusted positions
    GuiControl, Show, Txt_Instances
    GuiControl, Show, Instances

    GuiControl, Show, Txt_Columns
    GuiControl, Show, Columns

    GuiControl, Show, Txt_InstanceStartDelay
    GuiControl, Show, instanceStartDelay

    GuiControl, Show, runMain

    ; Show Mains if runMain is checked
    GuiControlGet, runMain
    if (runMain) {
        GuiControl, Show, Mains
    }
    
    GuiControl, Show, Instance_Divider3

    ; === Time Settings Section with Heading ===
    ; Show and style existing heading for Time Settings
    GuiControl, Show, TimeSettingsHeading
    GuiControl, +c%sectionColor%, TimeSettingsHeading

    ; Show Time Settings controls with adjusted positions
    GuiControl, Show, Txt_Delay
    GuiControl, Show, Delay

    GuiControl, Show, Txt_WaitTime
    GuiControl, Show, waitTime

    GuiControl, Show, Txt_SwipeSpeed
    GuiControl, Show, swipeSpeed

    GuiControl, Show, slowMotion

    ; Apply proper text coloring and styling based on the theme
    if (isDarkTheme) {
        ; Friend ID styling
        GuiControl, +c%sectionColor%, FriendIDLabel
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, FriendID

        ; Instance Settings styling
        GuiControl, +c%DARK_TEXT%, Txt_Instances
        GuiControl, +c%DARK_TEXT%, Txt_InstanceStartDelay
        GuiControl, +c%DARK_TEXT%, Txt_Columns
        GuiControl, +c%DARK_TEXT%, runMain
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Instances
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, instanceStartDelay
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Columns
        if (runMain)
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Mains

        ; Time Settings styling
        GuiControl, +c%DARK_TEXT%, Txt_Delay
        GuiControl, +c%DARK_TEXT%, Txt_WaitTime
        GuiControl, +c%DARK_TEXT%, Txt_SwipeSpeed
        GuiControl, +c%DARK_TEXT%, slowMotion
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Delay
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, waitTime
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, swipeSpeed
    } else {
        ; Friend ID styling
        GuiControl, +c%sectionColor%, FriendIDLabel
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, FriendID

        ; Instance Settings styling
        GuiControl, +c%LIGHT_TEXT%, Txt_Instances
        GuiControl, +c%LIGHT_TEXT%, Txt_InstanceStartDelay
        GuiControl, +c%LIGHT_TEXT%, Txt_Columns
        GuiControl, +c%LIGHT_TEXT%, runMain
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Instances
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, instanceStartDelay
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Columns
        if (runMain)
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Mains

        ; Time Settings styling
        GuiControl, +c%LIGHT_TEXT%, Txt_Delay
        GuiControl, +c%LIGHT_TEXT%, Txt_WaitTime
        GuiControl, +c%LIGHT_TEXT%, Txt_SwipeSpeed
        GuiControl, +c%LIGHT_TEXT%, slowMotion
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Delay
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, waitTime
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, swipeSpeed
    }

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

; ========== show System Settings Section (updated with dividers) ==========
ShowSystemSettingsSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    ; Get the section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS["SystemSettings"] : LIGHT_SECTION_COLORS["SystemSettings"]

    GuiControl, Show, SystemSettingsHeading
    GuiControl, +c%sectionColor%, SystemSettingsHeading

    GuiControl, Show, Txt_Monitor
    GuiControl, Show, SelectedMonitorIndex

    GuiControl, Show, Txt_Scale
    GuiControl, Show, defaultLanguage

    GuiControl, Show, Txt_FolderPath
    GuiControl, Show, folderPath

    GuiControl, Show, Txt_OcrLanguage
    GuiControl, Show, ocrLanguage
    GuiControl, Show, Txt_ClientLanguage
    GuiControl, Show, clientLanguage

    GuiControl, Show, Txt_InstanceLaunchDelay
    GuiControl, Show, instanceLaunchDelay
    GuiControl, Show, autoLaunchMonitor
    GuiControl, Show, SystemSettingsSeparator

    ; Apply proper text coloring to labels and checkboxes
    if (isDarkTheme) {
        GuiControl, +c%sectionColor%, Txt_Monitor
        GuiControl, +c%DARK_TEXT%, Txt_Scale
        GuiControl, +c%DARK_TEXT%, Txt_FolderPath
        GuiControl, +c%DARK_TEXT%, Txt_OcrLanguage
        GuiControl, +c%DARK_TEXT%, Txt_ClientLanguage
        GuiControl, +c%DARK_TEXT%, Txt_InstanceLaunchDelay
        GuiControl, +c%DARK_TEXT%, autoLaunchMonitor
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, folderPath
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, instanceLaunchDelay
    } else {
        GuiControl, +c%sectionColor%, Txt_Monitor
        GuiControl, +c%LIGHT_TEXT%, Txt_Scale
        GuiControl, +c%LIGHT_TEXT%, Txt_FolderPath
        GuiControl, +c%LIGHT_TEXT%, Txt_OcrLanguage
        GuiControl, +c%LIGHT_TEXT%, Txt_ClientLanguage
        GuiControl, +c%LIGHT_TEXT%, Txt_InstanceLaunchDelay
        GuiControl, +c%LIGHT_TEXT%, autoLaunchMonitor
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, folderPath
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, instanceLaunchDelay
    }
    
    SetHeaderFont()
    GuiControl, Show, ExtraSettingsHeading
    if (isDarkTheme) {
        GuiControl, +c%sectionColor%, ExtraSettingsHeading
    } else {
        GuiControl, +c%sectionColor%, ExtraSettingsHeading
    }

    SetNormalFont()
    GuiControl, Show, Txt_TesseractPath
    GuiControl, Show, tesseractPath
    GuiControl, Show, applyRoleFilters
    GuiControl, Show, debugMode

    if (isDarkTheme) {
        GuiControl, +c%DARK_TEXT%, Txt_TesseractPath
        GuiControl, +c%DARK_TEXT%, applyRoleFilters
        GuiControl, +c%DARK_TEXT%, debugMode
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, tesseractPath
    } else {
        GuiControl, +c%LIGHT_TEXT%, Txt_TesseractPath
        GuiControl, +c%LIGHT_TEXT%, applyRoleFilters
        GuiControl, +c%LIGHT_TEXT%, debugMode
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, tesseractPath
    }
    SetHeaderFont()
    GuiControl, Show, ExtraSettingsHeading
    if (isDarkTheme) {
        GuiControl, +c%sectionColor%, ExtraSettingsHeading
    } else {
        GuiControl, +c%sectionColor%, ExtraSettingsHeading
    }

    SetNormalFont()
    ; Show the tesseract option checkbox
    GuiControl, Show, tesseractOption
    
    ; Show tesseract path controls conditionally based on checkbox state
    GuiControlGet, tesseractOption
    if (tesseractOption) {
        GuiControl, Show, Txt_TesseractPath
        GuiControl, Show, tesseractPath
    } else {
        GuiControl, Hide, Txt_TesseractPath
        GuiControl, Hide, tesseractPath
    }
    
    GuiControl, Show, applyRoleFilters
    GuiControl, Show, debugMode

    if (isDarkTheme) {
        GuiControl, +c%DARK_TEXT%, tesseractOption
        if (tesseractOption) {
            GuiControl, +c%DARK_TEXT%, Txt_TesseractPath
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, tesseractPath
        }
        GuiControl, +c%DARK_TEXT%, applyRoleFilters
        GuiControl, +c%DARK_TEXT%, debugMode
    } else {
        GuiControl, +c%LIGHT_TEXT%, tesseractOption
        if (tesseractOption) {
            GuiControl, +c%LIGHT_TEXT%, Txt_TesseractPath
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, tesseractPath
        }
        GuiControl, +c%LIGHT_TEXT%, applyRoleFilters
        GuiControl, +c%LIGHT_TEXT%, debugMode
    }

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

; ========== Show Pack Settings Section (IMPROVED LAYOUT with dividers) ==========
ShowPackSettingsSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    ; Get the section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS["PackSettings"] : LIGHT_SECTION_COLORS["PackSettings"]

    ; === God Pack Settings Subsection ===
    ; Show the God Pack Settings subheading with proper styling
    GuiControl, Show, PackSettingsSubHeading1
    GuiControl, +c%sectionColor%, PackSettingsSubHeading1

    ; Show God Pack Settings controls with adjusted positions
    GuiControl, Show, Txt_MinStars
    GuiControl, Show, minStars

    GuiControl, Show, Txt_A2bMinStar
    GuiControl, Show, minStarsA2b

    GuiControl, Show, Txt_DeleteMethod
    GuiControl, Show, deleteMethod

    GuiControl, Show, packMethod

    ; Check if deleteMethod is "inject"
    GuiControlGet, deleteMethod
    if (!InStr(deleteMethod, "Inject")) {
        GuiControl, Show, nukeAccount
    }

    ; Show subsection separator
    GuiControl, Show, Pack_Divider1

    ; === Pack Selection Subsection ===
    ; Show the Pack Selection subheading with adjusted position
    GuiControl, Show, PackSettingsSubHeading2
    GuiControl, +c%sectionColor%, PackSettingsSubHeading2

    ; Show Pack Selection controls in a 3-column layout
    ; Column 1
    GuiControl, Show, Shining
    GuiControl, Show, Dialga
    GuiControl, Show, Mewtwo

    ; Column 2
    GuiControl, Show, Arceus
    GuiControl, Show, Pikachu
    GuiControl, Show, Mew

    ; Column 3
    GuiControl, Show, Palkia
    GuiControl, Show, Charizard

    ; Show subsection separator
    GuiControl, Show, Pack_Divider2

    ; === Card Detection Subsection ===
    ; Show the Card Detection subheading with adjusted position
    GuiControl, Show, PackSettingsSubHeading3
    GuiControl, +c%sectionColor%, PackSettingsSubHeading3

    ; Left Column
    GuiControl, Show, FullArtCheck
    GuiControl, Show, TrainerCheck
    GuiControl, Show, RainbowCheck
    GuiControl, Show, PseudoGodPack

    ; Show the divider between columns
    GuiControl, Show, Txt_vector

    ; Right Column with section header
    GuiControl, Show, Txt_Save
    GuiControl, Show, CrownCheck
    GuiControl, Show, ShinyCheck
    GuiControl, Show, ImmersiveCheck

    ; Bottom options
    GuiControl, Show, InvalidCheck
    GuiControl, Show, CheckShiningPackOnly

    ; Apply proper styling based on the theme
    if (isDarkTheme) {
        ; God Pack Settings styling
        GuiControl, +c%sectionColor%, Txt_MinStars
        GuiControl, +c%DARK_TEXT%, Txt_A2bMinStar
        GuiControl, +c%DARK_TEXT%, Txt_DeleteMethod
        GuiControl, +c%DARK_TEXT%, packMethod
        if (!InStr(deleteMethod, "Inject")) {
            GuiControl, +c%DARK_TEXT%, nukeAccount
        }
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, minStars
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, minStarsA2b

        ; Pack Selection styling
        GuiControl, +c%sectionColor%, Shining
        GuiControl, +c%DARK_TEXT%, Arceus
        GuiControl, +c%DARK_TEXT%, Palkia
        GuiControl, +c%DARK_TEXT%, Dialga
        GuiControl, +c%DARK_TEXT%, Pikachu
        GuiControl, +c%DARK_TEXT%, Charizard
        GuiControl, +c%DARK_TEXT%, Mewtwo
        GuiControl, +c%DARK_TEXT%, Mew

        ; Card Detection styling
        GuiControl, +c%DARK_TEXT%, FullArtCheck
        GuiControl, +c%DARK_TEXT%, TrainerCheck
        GuiControl, +c%DARK_TEXT%, RainbowCheck
        GuiControl, +c%DARK_TEXT%, PseudoGodPack
        GuiControl, +c%sectionColor%, Txt_Save
        GuiControl, +c%DARK_TEXT%, CrownCheck
        GuiControl, +c%DARK_TEXT%, ShinyCheck
        GuiControl, +c%DARK_TEXT%, ImmersiveCheck
        GuiControl, +c%DARK_TEXT%, InvalidCheck
        GuiControl, +c%DARK_TEXT%, CheckShiningPackOnly
    } else {
        ; God Pack Settings styling
        GuiControl, +c%sectionColor%, Txt_MinStars
        GuiControl, +c%LIGHT_TEXT%, Txt_A2bMinStar
        GuiControl, +c%LIGHT_TEXT%, Txt_DeleteMethod
        GuiControl, +c%LIGHT_TEXT%, packMethod
        if (!InStr(deleteMethod, "Inject")) {
            GuiControl, +c%LIGHT_TEXT%, nukeAccount
        }
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, minStars
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, minStarsA2b

        ; Pack Selection styling
        GuiControl, +c%sectionColor%, Shining
        GuiControl, +c%LIGHT_TEXT%, Arceus
        GuiControl, +c%LIGHT_TEXT%, Palkia
        GuiControl, +c%LIGHT_TEXT%, Dialga
        GuiControl, +c%LIGHT_TEXT%, Pikachu
        GuiControl, +c%LIGHT_TEXT%, Charizard
        GuiControl, +c%LIGHT_TEXT%, Mewtwo
        GuiControl, +c%LIGHT_TEXT%, Mew

        ; Card Detection styling
        GuiControl, +c%LIGHT_TEXT%, FullArtCheck
        GuiControl, +c%LIGHT_TEXT%, TrainerCheck
        GuiControl, +c%LIGHT_TEXT%, RainbowCheck
        GuiControl, +c%LIGHT_TEXT%, PseudoGodPack
        GuiControl, +c%sectionColor%, Txt_Save
        GuiControl, +c%LIGHT_TEXT%, CrownCheck
        GuiControl, +c%LIGHT_TEXT%, ShinyCheck
        GuiControl, +c%LIGHT_TEXT%, ImmersiveCheck
        GuiControl, +c%LIGHT_TEXT%, InvalidCheck
        GuiControl, +c%LIGHT_TEXT%, CheckShiningPackOnly
    }

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

; ========== Show Save For Trade Section (Updated with dividers) ==========
ShowSaveForTradeSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_TEXT_SECONDARY, LIGHT_TEXT_SECONDARY
    global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    ; Get the section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS["SaveForTrade"] : LIGHT_SECTION_COLORS["SaveForTrade"]

    ; Show the main Save For Trade heading
    GuiControl, Show, SaveForTradeHeading
    GuiControl, +c%sectionColor%, SaveForTradeHeading

    ; === Save For Trade main settings ===
    GuiControl, Show, s4tEnabled
    GuiControl, +c%sectionColor%, s4tEnabled

    ; Check if s4tEnabled is checked to show related controls
    ; And replace the existing divider visibility logic with this clearer approach:
    GuiControl, Show, SaveForTradeHeading
    GuiControl, +c%sectionColor%, SaveForTradeHeading
    GuiControl, Show, s4tEnabled
    GuiControl, +c%sectionColor%, s4tEnabled
    
    ; Always hide the dividers initially
    GuiControl, Hide, SaveForTradeDivider_1
    GuiControl, Hide, SaveForTradeDivider_2

    GuiControlGet, s4tEnabled
    if (s4tEnabled) {
        GuiControl, Show, s4tSilent
        GuiControl, Show, s4t3Dmnd
        GuiControl, Show, s4t4Dmnd
        GuiControl, Show, s4t1Star
        GuiControl, Show, Txt_S4TSeparator
        GuiControl, Show, s4tWP
        GuiControl, Show, SaveForTradeDivider_1
        GuiControl, Show, SaveForTradeDivider_2

        ; Apply proper text coloring
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, s4tSilent
            GuiControl, +c%DARK_TEXT%, s4t3Dmnd
            GuiControl, +c%DARK_TEXT%, s4t4Dmnd
            GuiControl, +c%DARK_TEXT%, s4t1Star
            GuiControl, +c%DARK_TEXT%, s4tWP
            GuiControl, +c%DARK_TEXT_SECONDARY%, Txt_S4TSeparator
        } else {
            GuiControl, +c%LIGHT_TEXT%, s4tSilent
            GuiControl, +c%LIGHT_TEXT%, s4t3Dmnd
            GuiControl, +c%LIGHT_TEXT%, s4t4Dmnd
            GuiControl, +c%LIGHT_TEXT%, s4t1Star
            GuiControl, +c%LIGHT_TEXT%, s4tWP
            GuiControl, +c%LIGHT_TEXT_SECONDARY%, Txt_S4TSeparator
        }

        ; Check if Shining is enabled to show Gholdengo - This is the important change from PTCGPB_New.ahk
        GuiControlGet, Shining
        if (Shining) {
            GuiControl, Show, s4tGholdengo
            GuiControl, Show, s4tGholdengoEmblem
            GuiControl, Show, s4tGholdengoArrow

            if (isDarkTheme) {
                GuiControl, +c%DARK_TEXT%, s4tGholdengo
                GuiControl, +c%DARK_TEXT%, s4tGholdengoArrow
            } else {
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengo
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengoArrow
            }
        }

        ; Check if s4tWP is checked to show min cards
        GuiControlGet, s4tWP
        if (s4tWP) {
            GuiControl, Show, s4tWPMinCardsLabel
            GuiControl, Show, s4tWPMinCards

            if (isDarkTheme) {
                GuiControl, +c%DARK_TEXT%, s4tWPMinCardsLabel
                GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tWPMinCards
            } else {
                GuiControl, +c%LIGHT_TEXT%, s4tWPMinCardsLabel
                GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tWPMinCards
            }
        }

        ; === S4T Discord Settings (now part of Save For Trade) ===
        GuiControl, Show, S4TDiscordSettingsSubHeading
        GuiControl, +c%sectionColor%, S4TDiscordSettingsSubHeading

        GuiControl, Show, Txt_S4T_DiscordID
        GuiControl, Show, s4tDiscordUserId
        GuiControl, Show, Txt_S4T_DiscordWebhook
        GuiControl, Show, s4tDiscordWebhookURL
        GuiControl, Show, s4tSendAccountXml

        ; Apply proper styling
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, Txt_S4T_DiscordID
            GuiControl, +c%DARK_TEXT%, Txt_S4T_DiscordWebhook
            GuiControl, +c%DARK_TEXT%, s4tSendAccountXml
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tDiscordUserId
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tDiscordWebhookURL
        } else {
            GuiControl, +c%LIGHT_TEXT%, Txt_S4T_DiscordID
            GuiControl, +c%LIGHT_TEXT%, Txt_S4T_DiscordWebhook
            GuiControl, +c%LIGHT_TEXT%, s4tSendAccountXml
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tDiscordUserId
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tDiscordWebhookURL
        }
    }

    ; Show dividers
    GuiControl, Show, SaveForTradeDivider_1
    GuiControl, Show, SaveForTradeDivider_2

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

; ========== Show Discord Settings Section (Updated with dividers) ==========
ShowDiscordSettingsSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    ; Get the section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS["DiscordSettings"] : LIGHT_SECTION_COLORS["DiscordSettings"]

    ; Show the main Discord Settings heading
    GuiControl, Show, DiscordSettingsHeading
    GuiControl, +c%sectionColor%, DiscordSettingsHeading

    ; Show Discord Settings controls
    GuiControl, Show, Txt_DiscordID
    GuiControl, Show, discordUserId

    GuiControl, Show, Txt_DiscordWebhook
    GuiControl, Show, discordWebhookURL

    GuiControl, Show, sendAccountXml

    ; Apply proper text coloring to Discord labels
    if (isDarkTheme) {
        GuiControl, +c%sectionColor%, Txt_DiscordID
        GuiControl, +c%DARK_TEXT%, Txt_DiscordWebhook
        GuiControl, +c%DARK_TEXT%, sendAccountXml
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, discordUserId
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, discordWebhookURL
    } else {
        GuiControl, +c%sectionColor%, Txt_DiscordID
        GuiControl, +c%LIGHT_TEXT%, Txt_DiscordWebhook
        GuiControl, +c%LIGHT_TEXT%, sendAccountXml
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, discordUserId
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, discordWebhookURL
    }

    ; === Heartbeat Settings (now part of Discord) ===
    GuiControl, Show, HeartbeatSettingsSubHeading
    GuiControl, +c%sectionColor%, HeartbeatSettingsSubHeading

    ; Show third divider after heading
    GuiControl, Show, Discord_Divider3

    GuiControl, Show, heartBeat

    ; Apply proper text coloring to heartbeat checkbox
    if (isDarkTheme) {
        GuiControl, +c%DARK_TEXT%, heartBeat
    } else {
        GuiControl, +c%LIGHT_TEXT%, heartBeat
    }

    ; Check if heartBeat is enabled to show related controls
    GuiControlGet, heartBeat
    if (heartBeat) {
        GuiControl, Show, hbName
        GuiControl, Show, heartBeatName
        GuiControl, Show, hbURL
        GuiControl, Show, heartBeatWebhookURL
        GuiControl, Show, hbDelay
        GuiControl, Show, heartBeatDelay

        ; Apply proper text coloring to heartbeat labels
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, hbName
            GuiControl, +c%DARK_TEXT%, hbURL
            GuiControl, +c%DARK_TEXT%, hbDelay
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatName
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatWebhookURL
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatDelay
        } else {
            GuiControl, +c%LIGHT_TEXT%, hbName
            GuiControl, +c%LIGHT_TEXT%, hbURL
            GuiControl, +c%LIGHT_TEXT%, hbDelay
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatName
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatWebhookURL
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatDelay
        }
    }

    ; Show the bottom separator
    GuiControl, Show, DiscordSettingsSeparator

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

; ========== Show Download Settings Section (updated with divider) ==========
ShowDownloadSettingsSection() {
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT
    global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS

    SetNormalFont()

    ; First, make sure all other sections are hidden
    HideAllSections()

    GuiControl, Show, DownloadSettingsHeading
    GuiControl, Show, Txt_MainIdsURL
    GuiControl, Show, mainIdsURL

    GuiControl, Show, Txt_VipIdsURL
    GuiControl, Show, vipIdsURL

    ; Apply proper text coloring to labels
    if (isDarkTheme) {
        sectionColor := DARK_SECTION_COLORS["DownloadSettings"]
        GuiControl, +c%sectionColor%, DownloadSettingsHeading
        GuiControl, +c%sectionColor%, Txt_MainIdsURL
        GuiControl, +c%DARK_TEXT%, Txt_VipIdsURL
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, mainIdsURL
        GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, vipIdsURL
    } else {
        sectionColor := LIGHT_SECTION_COLORS["DownloadSettings"]
        GuiControl, +c%sectionColor%, DownloadSettingsHeading
        GuiControl, +c%sectionColor%, Txt_MainIdsURL
        GuiControl, +c%LIGHT_TEXT%, Txt_VipIdsURL
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, mainIdsURL
        GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, vipIdsURL
    }

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
}

HandleKeyboardShortcut(sectionIndex) {
    ; Create array for sections (updated to new structure)
    sections := []
    sections.Push("RerollSettings")
    sections.Push("SystemSettings")
    sections.Push("PackSettings")
    sections.Push("SaveForTrade")
    sections.Push("DiscordSettings")
    sections.Push("DownloadSettings")

    ; Check if the index is valid
    if (sectionIndex > 0 && sectionIndex <= sections.MaxIndex()) {
        ; Get the section name
        sectionName := sections[sectionIndex]

        ; Hide all sections
        HideAllSections()

        ; Show the selected section based on its name
        if (sectionName = "RerollSettings")
            ShowRerollSettingsSection()
        else if (sectionName = "SystemSettings")
            ShowSystemSettingsSection()
        else if (sectionName = "PackSettings")
            ShowPackSettingsSection()
        else if (sectionName = "SaveForTrade")
            ShowSaveForTradeSection()
        else if (sectionName = "DiscordSettings")
            ShowDiscordSettingsSection()
        else if (sectionName = "DownloadSettings")
            ShowDownloadSettingsSection()

        ; Update current section and tab highlighting
        CurrentVisibleSection := sectionName
        UpdateTabButtonColors()

        ; Set section title
        friendlyName := GetFriendlyName(sectionName)
        GuiControl,, ActiveSection, Current Section: %friendlyName%

        ; Update section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS[sectionName] : LIGHT_SECTION_COLORS[sectionName]
        GuiControl, +c%sectionColor%, ActiveSection
    }
}

HandleFunctionKeyShortcut(functionIndex) {
    if (functionIndex = 1)
        gosub, LaunchAllMumu     ; F1: Launch all Mumu
    else if (functionIndex = 2)
        gosub, ArrangeWindows    ; F2: Arrange Windows
    else if (functionIndex = 3)
        gosub, StartBot          ; F3: Start Bot
}

; Function to show help menu with keyboard shortcuts
ShowHelpMenu() {
    global isDarkTheme, useBackgroundImage

    helpText := "Keyboard Shortcuts:`n`n"
    helpText .= "Ctrl+1: Reroll Settings`n"
    helpText .= "Ctrl+2: System Settings`n"
    helpText .= "Ctrl+3: Pack Settings`n"     ; Updated
    helpText .= "Ctrl+4: Save For Trade`n"    ; Updated
    helpText .= "Ctrl+5: Discord Settings`n"  ; Updated
    helpText .= "Ctrl+6: Download Settings`n" ; Updated
    helpText .= "`nFunction Keys:`n"
    helpText .= "F1: Launch All Mumu`n"
    helpText .= "F2: Arrange Windows`n"
    helpText .= "F3: Start Bot`n"
    helpText .= "F4: Show This Help Menu`n"
    helpText .= "Shift+F7: Send All Offline Status & Exit`n`n"
    helpText .= "Interface Settings:`n"
    helpText .= "Current Theme: " . (isDarkTheme ? "Dark" : "Light") . "`n"
    helpText .= "Background Image: " . (useBackgroundImage ? "Enabled" : "Disabled") . "`n"
    helpText .= "Toggle theme with the button at the top of the window."
    helpText .= "Toggle background image with the BG button."

    MsgBox, 64, Keyboard Shortcuts Help, %helpText%
}

; Helper function to convert section names to friendly names
GetFriendlyName(sectionName) {
    if (sectionName = "RerollSettings")
        return "Reroll Settings"
    else if (sectionName = "SystemSettings")
        return "System Settings"
    else if (sectionName = "PackSettings")   ; Updated
        return "Pack Settings"
    else if (sectionName = "SaveForTrade")
        return "Save For Trade"
    else if (sectionName = "DiscordSettings")
        return "Discord Settings"
    else if (sectionName = "DownloadSettings")
        return "Download Settings"
    else
        return sectionName
}

; Function to load settings from INI file
LoadSettingsFromIni() {
    global

    ; Check if Settings.ini exists
    if (FileExist("Settings.ini")) {
        ; Read basic settings with default values if they don't exist in the file
        IniRead, FriendID, Settings.ini, UserSettings, FriendID, ""
        IniRead, waitTime, Settings.ini, UserSettings, waitTime, 5
        IniRead, Delay, Settings.ini, UserSettings, Delay, 250
        IniRead, folderPath, Settings.ini, UserSettings, folderPath, C:\Program Files\Netease
        IniRead, discordWebhookURL, Settings.ini, UserSettings, discordWebhookURL, ""
        IniRead, discordUserId, Settings.ini, UserSettings, discordUserId, ""
        IniRead, Columns, Settings.ini, UserSettings, Columns, 5
        IniRead, godPack, Settings.ini, UserSettings, godPack, Continue
        IniRead, Instances, Settings.ini, UserSettings, Instances, 1
        IniRead, instanceStartDelay, Settings.ini, UserSettings, instanceStartDelay, 0
        IniRead, defaultLanguage, Settings.ini, UserSettings, defaultLanguage, Scale125
        IniRead, SelectedMonitorIndex, Settings.ini, UserSettings, SelectedMonitorIndex, 1
        IniRead, swipeSpeed, Settings.ini, UserSettings, swipeSpeed, 300
        IniRead, deleteMethod, Settings.ini, UserSettings, deleteMethod, 3 Pack
        IniRead, runMain, Settings.ini, UserSettings, runMain, 1
        IniRead, Mains, Settings.ini, UserSettings, Mains, 1
        IniRead, heartBeat, Settings.ini, UserSettings, heartBeat, 0

        ; Continue reading all other settings
        IniRead, heartBeatWebhookURL, Settings.ini, UserSettings, heartBeatWebhookURL, ""
        IniRead, heartBeatName, Settings.ini, UserSettings, heartBeatName, ""
        IniRead, nukeAccount, Settings.ini, UserSettings, nukeAccount, 0
        IniRead, packMethod, Settings.ini, UserSettings, packMethod, 0
        IniRead, CheckShiningPackOnly, Settings.ini, UserSettings, CheckShiningPackOnly, 0
        IniRead, TrainerCheck, Settings.ini, UserSettings, TrainerCheck, 0
        IniRead, FullArtCheck, Settings.ini, UserSettings, FullArtCheck, 0
        IniRead, RainbowCheck, Settings.ini, UserSettings, RainbowCheck, 0
        IniRead, ShinyCheck, Settings.ini, UserSettings, ShinyCheck, 0
        IniRead, CrownCheck, Settings.ini, UserSettings, CrownCheck, 0
        IniRead, ImmersiveCheck, Settings.ini, UserSettings, ImmersiveCheck, 0
        IniRead, InvalidCheck, Settings.ini, UserSettings, InvalidCheck, 0
        IniRead, PseudoGodPack, Settings.ini, UserSettings, PseudoGodPack, 0
        IniRead, minStars, Settings.ini, UserSettings, minStars, 0
        IniRead, Palkia, Settings.ini, UserSettings, Palkia, 0
        IniRead, Dialga, Settings.ini, UserSettings, Dialga, 0
        IniRead, Arceus, Settings.ini, UserSettings, Arceus, 0
        IniRead, Shining, Settings.ini, UserSettings, Shining, 1
        IniRead, Mew, Settings.ini, UserSettings, Mew, 0
        IniRead, Pikachu, Settings.ini, UserSettings, Pikachu, 0
        IniRead, Charizard, Settings.ini, UserSettings, Charizard, 0
        IniRead, Mewtwo, Settings.ini, UserSettings, Mewtwo, 0
        IniRead, slowMotion, Settings.ini, UserSettings, slowMotion, 0
        IniRead, ocrLanguage, Settings.ini, UserSettings, ocrLanguage, en
        IniRead, clientLanguage, Settings.ini, UserSettings, clientLanguage, en
        IniRead, autoLaunchMonitor, Settings.ini, UserSettings, autoLaunchMonitor, 1
        IniRead, mainIdsURL, Settings.ini, UserSettings, mainIdsURL, ""
        IniRead, vipIdsURL, Settings.ini, UserSettings, vipIdsURL, ""
        IniRead, instanceLaunchDelay, Settings.ini, UserSettings, instanceLaunchDelay, 5

        ; Read S4T settings
        IniRead, s4tEnabled, Settings.ini, UserSettings, s4tEnabled, 0
        IniRead, s4tSilent, Settings.ini, UserSettings, s4tSilent, 1
        IniRead, s4t3Dmnd, Settings.ini, UserSettings, s4t3Dmnd, 0
        IniRead, s4t4Dmnd, Settings.ini, UserSettings, s4t4Dmnd, 0
        IniRead, s4t1Star, Settings.ini, UserSettings, s4t1Star, 0
        IniRead, s4tGholdengo, Settings.ini, UserSettings, s4tGholdengo, 0
        IniRead, s4tWP, Settings.ini, UserSettings, s4tWP, 0
        IniRead, s4tWPMinCards, Settings.ini, UserSettings, s4tWPMinCards, 1
        IniRead, s4tDiscordWebhookURL, Settings.ini, UserSettings, s4tDiscordWebhookURL, ""
        IniRead, s4tDiscordUserId, Settings.ini, UserSettings, s4tDiscordUserId, ""
        IniRead, s4tSendAccountXml, Settings.ini, UserSettings, s4tSendAccountXml, 1

        ; Advanced settings
        IniRead, minStarsA1Charizard, Settings.ini, UserSettings, minStarsA1Charizard, 0
        IniRead, minStarsA1Mewtwo, Settings.ini, UserSettings, minStarsA1Mewtwo, 0
        IniRead, minStarsA1Pikachu, Settings.ini, UserSettings, minStarsA1Pikachu, 0
        IniRead, minStarsA1a, Settings.ini, UserSettings, minStarsA1a, 0
        IniRead, minStarsA2Dialga, Settings.ini, UserSettings, minStarsA2Dialga, 0
        IniRead, minStarsA2Palkia, Settings.ini, UserSettings, minStarsA2Palkia, 0
        IniRead, minStarsA2a, Settings.ini, UserSettings, minStarsA2a, 0
        IniRead, minStarsA2b, Settings.ini, UserSettings, minStarsA2b, 0
        IniRead, heartBeatDelay, Settings.ini, UserSettings, heartBeatDelay, 30
        IniRead, sendAccountXml, Settings.ini, UserSettings, sendAccountXml, 0

        ; Theme setting
        IniRead, isDarkTheme, Settings.ini, UserSettings, isDarkTheme, 1

        ; Background image setting
        IniRead, useBackgroundImage, Settings.ini, UserSettings, useBackgroundImage, 1
        
        ; Extra Settings
        IniRead, tesseractPath, Settings.ini, UserSettings, tesseractPath, C:\Program Files\Tesseract-OCR\tesseract.exe
        IniRead, applyRoleFilters, Settings.ini, UserSettings, applyRoleFilters, 0
        IniRead, debugMode, Settings.ini, UserSettings, debugMode, 0
        IniRead, tesseractOption, Settings.ini, UserSettings, tesseractOption, 0
        ; Validate numeric values
        if (!IsNumeric(Instances) || Instances < 1)
            Instances := 1
        if (!IsNumeric(Columns) || Columns < 1)
            Columns := 5
        if (!IsNumeric(waitTime) || waitTime < 1)
            waitTime := 5
        if (!IsNumeric(Delay) || Delay < 10)
            Delay := 250

        ; Return success
        return true
    } else {
        ; Settings file doesn't exist, will use defaults
        return false
    }
}
; Function to create the default settings file if it doesn't exist
CreateDefaultSettingsFile() {
    if (!FileExist("Settings.ini")) {
        ; Create default settings file
        IniWrite, "", Settings.ini, UserSettings, FriendID
        IniWrite, 5, Settings.ini, UserSettings, waitTime
        IniWrite, 250, Settings.ini, UserSettings, Delay
        IniWrite, C:\Program Files\Netease, Settings.ini, UserSettings, folderPath
        IniWrite, 5, Settings.ini, UserSettings, Columns
        IniWrite, Continue, Settings.ini, UserSettings, godPack
        IniWrite, 1, Settings.ini, UserSettings, Instances
        IniWrite, 0, Settings.ini, UserSettings, instanceStartDelay
        IniWrite, Scale125, Settings.ini, UserSettings, defaultLanguage
        IniWrite, 1, Settings.ini, UserSettings, SelectedMonitorIndex
        IniWrite, 300, Settings.ini, UserSettings, swipeSpeed
        IniWrite, 1, Settings.ini, UserSettings, runMain
        IniWrite, 1, Settings.ini, UserSettings, Mains
        IniWrite, 0, Settings.ini, UserSettings, heartBeat
        IniWrite, "", Settings.ini, UserSettings, heartBeatWebhookURL
        IniWrite, "", Settings.ini, UserSettings, heartBeatName
        IniWrite, C:\Program Files\Tesseract-OCR\tesseract.exe, Settings.ini, UserSettings, tesseractPath
        IniWrite, 0, Settings.ini, UserSettings, applyRoleFilters
        IniWrite, 0, Settings.ini, UserSettings, debugMode

        ; Add the rest of default settings here
        IniWrite, 1, Settings.ini, UserSettings, isDarkTheme
        IniWrite, 1, Settings.ini, UserSettings, useBackgroundImage

        return true
    }
    return false
}
; First, try to load existing settings
settingsLoaded := LoadSettingsFromIni()

; If no settings were loaded, create a default settings file
if (!settingsLoaded) {
    CreateDefaultSettingsFile()
    ; Now load the default settings we just created
    LoadSettingsFromIni()
}

CheckForUpdate()
KillADBProcesses()
scriptName := StrReplace(A_ScriptName, ".ahk")
winTitle := scriptName
showStatus := true
totalFile := A_ScriptDir . "\json\total.json"
backupFile := A_ScriptDir . "\json\total-backup.json"
if FileExist(totalFile) ; Check if the file exists
{
    FileCopy, %totalFile%, %backupFile%, 1 ; Copy source file to target
    if (ErrorLevel)
        MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}
FileDelete, %totalFile%
packsFile := A_ScriptDir . "\json\Packs.json"
backupFile := A_ScriptDir . "\json\Packs-backup.json"
if FileExist(packsFile) ; Check if the file exists
{
    FileCopy, %packsFile%, %backupFile%, 1 ; Copy source file to target
    if (ErrorLevel)
        MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}
InitializeJsonFile() ; Create or open the JSON file


; Initialize with dark theme
if (isDarkTheme)
    Gui, Color, %DARK_BG%, %DARK_CONTROL_BG%  ; Dark theme
else
    Gui, Color, %LIGHT_BG%, %LIGHT_CONTROL_BG%  ; Light theme

; Header section with enhanced styling
SetArturoFont()

if (isDarkTheme) {
    Gui, Add, Text, x15 y15 c%DARK_TEXT% vHeaderTitle, % "Arturo's PTCGP Bot"
} else {
    Gui, Add, Text, x15 y15 c%LIGHT_TEXT% vHeaderTitle, % "Arturo's PTCGP Bot"
}

; Better styled theme toggle button - adjusted position and size
Gui, Font, s8, Segoe UI  ; Smaller font size

; Add theme toggle button and background toggle button
Gui, Add, Button, x250 y15 w100 h25 gToggleTheme vThemeToggle hwndhThemeToggle, % isDarkTheme ? "Light Mode" : "Dark Mode"
SetButtonColor(hThemeToggle, isDarkTheme ? "81A1C1" : "5E81AC")

; Add background toggle button next to theme toggle
Gui, Add, Button, x+15 w100 h25 gToggleBackground vBackgroundToggle hwndhBackgroundToggle, % useBackgroundImage ? "Background Off" : "Background On"
SetButtonColor(hBackgroundToggle, isDarkTheme ? "81A1C1" : "5E81AC")

; Status indicator for active section - moved above Reroll Settings
SetTitleFont()
Gui, Add, Edit, x15 y+15 w450 h28 vActiveSection +Center +ReadOnly -Border -VScroll, Ready to start

; Navigation sidebar with improved styling and adjusted sizes
SetHeaderFont()

; Navigation buttons with updated structure
Gui, Add, Button, x15 y100 w140 h25 gToggleSection vBtn_RerollSettings hwndhBtnReroll, Reroll Settings
SetButtonColor(hBtnReroll, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, y+5 w140 h25 gToggleSection vBtn_SystemSettings hwndhBtn2, System Settings
SetButtonColor(hBtn2, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, y+5 w140 h25 gToggleSection vBtn_PackSettings hwndhBtn3, Pack Settings
SetButtonColor(hBtn3, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, y+20 w140 h25 gToggleSection vBtn_SaveForTrade hwndhBtn4, Save For Trade
SetButtonColor(hBtn4, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, y+20 w140 h25 gToggleSection vBtn_DiscordSettings hwndhBtn5, Discord Settings
SetButtonColor(hBtn5, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, y+5 w140 h25 gToggleSection vBtn_DownloadSettings hwndhBtn6, Download Settings
SetButtonColor(hBtn6, isDarkTheme ? DARK_CONTROL_BG : LIGHT_CONTROL_BG)

Gui, Add, Button, gOpenDiscord y+20 w140 h25 vJoinDiscord hwndhDiscordBtn, Join Discord
SetButtonColor(hDiscordBtn, BTN_DISCORD)

Gui, Add, Button, gOpenLink y+5 w140 h25 vBuyMeACoffee hwndhCoffeeBtn, Buy Me a Coffee
SetButtonColor(hCoffeeBtn, BTN_COFFEE)

Gui, Add, Button, gCheckForUpdate y+5 w140 h25 vCheckUpdates hwndhUpdateBtn, Check for Updates
SetButtonColor(hUpdateBtn, BTN_UPDATE)

; ========== Friend ID Section with better layout ==========
SetHeaderFont()
Gui, Add, Text, x170 y100 vFriendIDHeading Hidden, Friend ID Settings

SetInputFont()
Gui, Add, Text, x170 y+20 vFriendIDLabel, Your Friend ID:
if(FriendID = "ERROR" || FriendID = "") {
    Gui, Add, Edit, vFriendID w290 y+10 h25 Hidden
} else {
    Gui, Add, Edit, vFriendID w290 y+10 h25 Hidden, %FriendID%
}

; Add divider for Friend ID section
AddSectionDivider(170, "+20", 290, "FriendID_Divider")

; ========== Instance Settings Section ==========
SetHeaderFont()
Gui, Add, Text, y+17 vInstanceSettingsHeading Hidden, Instance Settings

SetNormalFont()
Gui, Add, Text, y+17 Hidden vTxt_Instances, Instances:
Gui, Add, Edit, vInstances w45 x260 y+-17 h25 Center Hidden, %Instances%

Gui, Add, Text, x170 y+17 Hidden vTxt_InstanceStartDelay, Start Delay:
Gui, Add, Edit, vinstanceStartDelay w45 x260 y+-17 h25 Center Hidden, %instanceStartDelay%

Gui, Add, Text, x170 y+17 Hidden vTxt_Columns, Columns:
Gui, Add, Edit, vColumns w45 x260 y+-17 h25 Center Hidden, %Columns%

Gui, Add, Checkbox, % "vrunMain gmainSettings x170 y+17 Hidden" . (runMain ? " Checked" : ""), % "Run Main(s)"
Gui, Add, Edit, % "vMains w45 x260 y+-17 h25 Center Hidden " . (runMain ? "" : "Hidden"), %Mains%

; Add dividers for Instance Settings section
AddSectionDivider(170, "+25", 290, "Instance_Divider3")

; ========== Time Settings Section ==========
SetHeaderFont()
Gui, Add, Text, y+20 vTimeSettingsHeading Hidden, Time Settings

SetNormalFont()
Gui, Add, Text, y+20 Hidden vTxt_Delay, Delay:
Gui, Add, Edit, vDelay w45 x260 y+-17 h25 Center Hidden, %Delay%

Gui, Add, Text, x170 y+17 Hidden vTxt_WaitTime, Wait Time:
Gui, Add, Edit, vwaitTime w45 x260 y+-17 h25 Center Hidden, %waitTime%

Gui, Add, Text, x170 y+17  Hidden vTxt_SwipeSpeed, Swipe Speed:
Gui, Add, Edit, vswipeSpeed w45 x260 y+-17 h25 Center Hidden, %swipeSpeed%

Gui, Add, Checkbox, % (slowMotion ? "Checked" : "") " vslowMotion x170 y+12 Hidden", Base Game Compatibility

; ========== System Settings Section ==========
SetSectionFont()
Gui, Add, Text, x170 y100 vSystemSettingsHeading Hidden, System Settings

SetNormalFont()
SysGet, MonitorCount, MonitorCount
MonitorOptions := ""
Loop, %MonitorCount% {
    SysGet, MonitorName, MonitorName, %A_Index%
    SysGet, Monitor, Monitor, %A_Index%
    MonitorOptions .= (A_Index > 1 ? "|" : "") "" A_Index ": (" MonitorRight - MonitorLeft "x" MonitorBottom - MonitorTop ")"
}
SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")

Gui, Add, Text, y+20 Hidden vTxt_Monitor, Monitor:
Gui, Add, DropDownList, x285 y+-17 w95 h300 vSelectedMonitorIndex Choose%SelectedMonitorIndex% Hidden, %MonitorOptions%

Gui, Add, Text, x170 y+17 Hidden vTxt_Scale, Scale:
if (defaultLanguage = "Scale125") {
    defaultLang := 1
    scaleParam := 277
} else if (defaultLanguage = "Scale100") {
    defaultLang := 2
    scaleParam := 287
}

Gui, Add, DropDownList, x285 y+-17 w95 vdefaultLanguage choose%defaultLang% Hidden, Scale125|Scale100

Gui, Add, Text, x170 y+17 Hidden vTxt_FolderPath, Folder Path:
Gui, Add, Edit, vfolderPath x285 y+-17 w180 h25 Hidden, %folderPath%

Gui, Add, Text, x170 y+17 Hidden vTxt_OcrLanguage, OCR:
; ========== Language Pack list ==========
ocrLanguageList := "en|zh|es|de|fr|ja|ru|pt|ko|it|tr|pl|nl|sv|ar|uk|id|vi|th|he|cs|no|da|fi|hu|el|zh-TW"
if (ocrLanguage != "")
{
    index := 0
    Loop, Parse, ocrLanguageList, |
    {
        index++
        if (A_LoopField = ocrLanguage)
        {
            defaultOcrLang := index
            break
        }
    }
}

Gui, Add, DropDownList, vocrLanguage choose%defaultOcrLang% x285 y+-17 w65 Hidden, %ocrLanguageList%

Gui, Add, Text, x170 y+17 Hidden vTxt_ClientLanguage, Client:

; ========== Client Language Pack list ==========
clientLanguageList := "en|es|fr|de|it|pt|jp|ko|cn"

if (clientLanguage != "")
{
    index := 0
    Loop, Parse, clientLanguageList, |
    {
        index++
        if (A_LoopField = clientLanguage)
        {
            defaultClientLang := index
            break
        }
    }
}
Gui, Add, DropDownList, vclientLanguage choose%defaultClientLang% x285 y+-17 w65 Hidden, %clientLanguageList%

Gui, Add, Text, x170 y+17 Hidden vTxt_InstanceLaunchDelay, Launch Mumu Delay:
Gui, Add, Edit, vinstanceLaunchDelay x285 y+-17 w55 h25 Center Hidden, %instanceLaunchDelay%

Gui, Add, Checkbox, % (autoLaunchMonitor ? "Checked" : "") " vautoLaunchMonitor x170 y+17 Hidden", Auto Launch Monitor

SetHeaderFont()
Gui, Add, Text, x170 y+30 Hidden vExtraSettingsHeading, Extra Settings
SetNormalFont()

; First add Role-Based Filters
Gui, Add, Checkbox, % (applyRoleFilters ? "Checked" : "") " vapplyRoleFilters x170 y+10 Hidden", Use Role-Based Filters

; Then add Debug Mode
Gui, Add, Checkbox, % (debugMode ? "Checked" : "") " vdebugMode x170 y+10 Hidden", Debug Mode

; Then add the Use Tesseract checkbox
Gui, Add, Checkbox, % (tesseractOption ? "Checked" : "") " vtesseractOption gTesseractOptionSettings x170 y+10 Hidden", Use Tesseract

; Keep Tesseract Path at the end
Gui, Add, Text, x170 y+20 Hidden vTxt_TesseractPath, Tesseract Path:
Gui, Add, Edit, vtesseractPath w290 x170 y+5 h25 Hidden, %tesseractPath%

; ========== Pack Settings Section (Merged God Pack, Pack Selection and Card Detection) ==========
SetHeaderFont()
Gui, Add, Text, x170 y100 Hidden vPackSettingsSubHeading1, God Pack Settings

SetNormalFont()
Gui, Add, Text, y+20 Hidden vTxt_MinStars, Min. 2 Stars:
Gui, Add, Edit, vminStars w55 x260 y+-17 h25 Center Hidden, %minStars%

Gui, Add, Text, x170 y+17 Hidden vTxt_A2bMinStar, 2* for SR:
Gui, Add, Edit, vminStarsA2b w55 x260 y+-17 h25 Center Hidden, %minStarsA2b%

Gui, Add, Text, x170 y+17 Hidden vTxt_DeleteMethod, Method:
if (deleteMethod = "5 Pack")
    defaultDelete := 1
else if (deleteMethod = "3 Pack")
    defaultDelete := 2
else if (deleteMethod = "Inject")
    defaultDelete := 3
else if (deleteMethod = "5 Pack (Fast)")
    defaultDelete := 4

Gui, Add, DropDownList, vdeleteMethod gdeleteSettings choose%defaultDelete% x260 y+-17 w95 Hidden, 5 Pack|3 Pack|Inject|5 Pack (Fast)

Gui, Add, Checkbox, % (packMethod ? "Checked" : "") " vpackMethod x170 y+17 Hidden", 1 Pack Method
Gui, Add, Checkbox, % (nukeAccount ? "Checked" : "") " vnukeAccount x170 y+20 Hidden", Menu Delete

; Add divider for God Pack Settings section
AddSectionDivider(170, "+20", 290, "Pack_Divider1")

; === Pack Selection Subsection ===
SetHeaderFont()
Gui, Add, Text, y+20 Hidden vPackSettingsSubHeading2, Pack Selection

SetNormalFont()
; 3-Column Layout for Pack Selection
; Column 1
Gui, Add, Checkbox, % (Shining ? "Checked" : "") " vShining y+15 Hidden", Shining
Gui, Add, Checkbox, % (Dialga ? "Checked" : "") " vDialga y+10 Hidden", Dialga
Gui, Add, Checkbox, % (Mewtwo ? "Checked" : "") " vMewtwo y+10 Hidden", Mewtwo

; Column 2
Gui, Add, Checkbox, % (Arceus ? "Checked" : "") " vArceus x260 y+-61 Hidden", Arceus
Gui, Add, Checkbox, % (Pikachu ? "Checked" : "") " vPikachu y+10 Hidden", Pikachu
Gui, Add, Checkbox, % (Mew ? "Checked" : "") " vMew y+10 Hidden", Mew

; Column 3
Gui, Add, Checkbox, % (Palkia ? "Checked" : "") " vPalkia x350 y+-61 Hidden", Palkia
Gui, Add, Checkbox, % (Charizard ? "Checked" : "") " vCharizard y+10 Hidden", Charizard

; Add divider for Pack Selection section
AddSectionDivider(170, "+41", 290, "Pack_Divider2")

; === Card Detection Subsection ===
SetHeaderFont()
Gui, Add, Text, x170 y+20 Hidden vPackSettingsSubHeading3, Card Detection

SetNormalFont()
; Left Column
Gui, Add, Checkbox, % (FullArtCheck ? "Checked" : "") " vFullArtCheck y+15 Hidden", Single Full Art
Gui, Add, Checkbox, % (TrainerCheck ? "Checked" : "") " vTrainerCheck y+10 Hidden", Single Trainer
Gui, Add, Checkbox, % (RainbowCheck ? "Checked" : "") " vRainbowCheck y+10 Hidden", Single Rainbow
Gui, Add, Checkbox, % (PseudoGodPack ? "Checked" : "") " vPseudoGodPack y+10 Hidden", Double 2 Star

; Show the divider between columns
Gui, Add, Text, x260 y450 w2 h140 Hidden vTxt_vector +0x10  ; Creates a vertical line

; Right Column
Gui, Add, Checkbox, % (CrownCheck ? "Checked" : "") " vCrownCheck x320 y+-86 Hidden", Save Crowns
Gui, Add, Checkbox, % (ShinyCheck ? "Checked" : "") " vShinyCheck y+10 Hidden", Save Shiny
Gui, Add, Checkbox, % (ImmersiveCheck ? "Checked" : "") " vImmersiveCheck y+10 Hidden", Save Immersives

; Bottom options
Gui, Add, Checkbox, % (CheckShiningPackOnly ? "Checked" : "") " vCheckShiningPackOnly x170 y+44 Hidden", Only Shining Boost
Gui, Add, Checkbox, % (InvalidCheck ? "Checked" : "") " vInvalidCheck x320 y+-16 Hidden", Ignore Invalid Packs

; Add divider for Card Detection section
AddSectionDivider(170, "+41", 290, "Pack_Divider3")

; ========== Save For Trade Section (with integrated S4T Discord settings) ==========
SetSectionFont()
; Add main heading for Save For Trade section
Gui, Add, Text, x170 y100 Hidden vSaveForTradeHeading, Save For Trade

SetNormalFont()
Gui, Add, Checkbox, % "vs4tEnabled gs4tSettings y+20 Hidden " . (s4tEnabled ? "Checked " : ""), Enable S4T

Gui, Add, Checkbox, % "vs4tSilent y+20 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled ? "Hidden " : "") . (s4tSilent ? "Checked " : ""), Silent (No Ping)

Gui, Add, Checkbox, % "vs4t3Dmnd y+20 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled ? "Hidden " : "") . (s4t3Dmnd ? "Checked " : ""), 3 Diamond
Gui, Add, Checkbox, % "vs4t4Dmnd y+20 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled ? "Hidden " : "") . (s4t4Dmnd ? "Checked " : ""), 4 Diamond
Gui, Add, Checkbox, % "vs4t1Star y+20 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled ? "Hidden " : "") . (s4t1Star ? "Checked " : ""), 1 Star

Gui, Add, Checkbox, % ((!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled || !Shining) ? "Hidden " : "") . "vs4tGholdengo x395 y+-14" . (s4tGholdengo ? "Checked " : ""), % "--->"
Gui, Add, Picture, % ((!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled || !Shining) ? "Hidden " : "") . "vs4tGholdengoEmblem w25 h25 x+0 y+-18", % A_ScriptDir . "\Scripts\Scale125\GholdengoEmblem.png"

AddSectionDivider(170, "+15", 290, "SaveForTradeDivider_1")

Gui, Add, Checkbox, % "vs4tWP gs4tWPSettings x170 y+20 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled ? "Hidden " : "") . (s4tWP ? "Checked " : ""), Wonder Pick

Gui, Add, Text, % "vs4tWPMinCardsLabel x280 y+-14 " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled || !s4tWP ? "Hidden " : ""), Min. Cards:
Gui, Add, Edit, % "vs4tWPMinCards w35 x+20 y+-17 h25 Center " . (!CurrentVisibleSection = "SaveForTrade" || !s4tEnabled || !s4tWP ? "Hidden" : ""), %s4tWPMinCards%

AddSectionDivider(170, "+15", 290, "SaveForTradeDivider_2")

; === S4T Discord Settings (now part of Save For Trade) ===
SetHeaderFont()
Gui, Add, Text, x170 y+20 Hidden vS4TDiscordSettingsSubHeading, S4T Discord Settings

SetNormalFont()
if(StrLen(s4tDiscordUserId) < 3)
    s4tDiscordUserId =
if(StrLen(s4tDiscordWebhookURL) < 3)
    s4tDiscordWebhookURL =

Gui, Add, Text, y+20 Hidden vTxt_S4T_DiscordID, Discord ID:
Gui, Add, Edit, vs4tDiscordUserId w290 y+10 h25 Center Hidden, %s4tDiscordUserId%
Gui, Add, Text, y+20 Hidden vTxt_S4T_DiscordWebhook, Webhook URL:
Gui, Add, Edit, vs4tDiscordWebhookURL w290 y+10 h25 Center Hidden, %s4tDiscordWebhookURL%
Gui, Add, Checkbox, % (s4tSendAccountXml ? "Checked" : "") " vs4tSendAccountXml y+20 Hidden", Send Account XML

; ========== Discord Settings Section (with integrated Heartbeat settings) ==========
SetSectionFont()
; Add main heading for Discord Settings section
Gui, Add, Text, x170 y100 Hidden vDiscordSettingsHeading, Discord Settings

SetNormalFont()
if(StrLen(discordUserID) < 3)
    discordUserID =
if(StrLen(discordWebhookURL) < 3)
    discordWebhookURL =

Gui, Add, Text, y+20 Hidden vTxt_DiscordID, Discord ID:
Gui, Add, Edit, vdiscordUserId w290 y+10 h25 Hidden, %discordUserId%

Gui, Add, Text, y+20 Hidden vTxt_DiscordWebhook, Webhook URL:
Gui, Add, Edit, vdiscordWebhookURL w290 y+10 h25 Hidden, %discordWebhookURL%

Gui, Add, Checkbox, % (sendAccountXml ? "Checked" : "") " vsendAccountXml y+20 Hidden", Send Account XML

; Add divider after heading
AddSectionDivider(170, "+20", 290, "Discord_Divider3")

; === Heartbeat Settings (now part of Discord) ===
SetHeaderFont()
Gui, Add, Text, y+20 Hidden vHeartbeatSettingsSubHeading, Heartbeat Settings

SetNormalFont()
Gui, Add, Checkbox, % (heartBeat ? "Checked" : "") " vheartBeat gdiscordSettings y+20 Hidden", Discord Heartbeat

if(StrLen(heartBeatName) < 3)
    heartBeatName =
if(StrLen(heartBeatWebhookURL) < 3)
    heartBeatWebhookURL =

Gui, Add, Text, vhbName y+20 Hidden, Name:
Gui, Add, Edit, vheartBeatName w220 w290 y+10 h25 Center Hidden, %heartBeatName%
Gui, Add, Text, vhbURL y+20 Hidden, Webhook URL:
Gui, Add, Edit, vheartBeatWebhookURL w290 y+10 h25 Center Hidden, %heartBeatWebhookURL%
Gui, Add, Text, vhbDelay y+20 Hidden, Heartbeat Delay (min):
Gui, Add, Edit, vheartBeatDelay x300 y+-17 w55 h25 Center Hidden, %heartBeatDelay%

; ========== Download Settings Section ==========
SetHeaderFont()
Gui, Add, Text, x170 y100 Hidden vDownloadSettingsHeading, Download Settings

SetNormalFont()
if(StrLen(mainIdsURL) < 3)
    mainIdsURL =
if(StrLen(vipIdsURL) < 3)
    vipIdsURL =

Gui, Add, Text, y+20 Hidden vTxt_MainIdsURL, ids.txt API:
Gui, Add, Edit, vmainIdsURL w290 y+10 h25 Center Hidden, %mainIdsURL%

Gui, Add, Text, y+20 Hidden vTxt_VipIdsURL, vip_ids.txt API:
Gui, Add, Edit, vvipIdsURL w290 y+10 h25 Center Hidden, %vipIdsURL%

; ========== Action Buttons with New 3-Row Layout - Adjusted Positioning ==========
SetHeaderFont()

; Row 1 - Three buttons side by side - adjusted positions and sizes
Gui, Add, Button, gLaunchAllMumu x15 y655 w140 h25 vLaunchAllMumu hwndhLaunchBtn, Launch All Mumu
SetButtonColor(hLaunchBtn, BTN_LAUNCH)

Gui, Add, Button, gArrangeWindows x+15 y655 w140 h25 vArrangeWindows hwndhArrangeBtn, Arrange Windows
SetButtonColor(hArrangeBtn, BTN_ARRANGE)

Gui, Add, Button, gSaveReload x+15 y655 w140 h25 vReloadBtn hwndhReloadBtn, Reload
SetButtonColor(hReloadBtn, BTN_RELOAD)

; Row 2 - Full width button for Start Bot - adjusted position and size
Gui, Add, Button, gStartBot x15 y+10 w450 h30 vStartBot hwndhStartBtn, Start Bot
SetButtonColor(hStartBtn, BTN_START)

; Version info moved to the bottom - adjusted position
SetSmallFont()
Gui, Add, Text, x15 y+10 w450 vVersionInfo Center, PTCGPB %localVersion% (Licensed under CC BY-NC 4.0 International License)

; Add Reroll Settings separator
Gui, Add, Text, x170 y350 w220 h2 +0x10 vRerollSettingsSeparator Hidden  ; Horizontal separator - adjusted width

; Check for different possible background image files based on current theme
backgroundImagePath := ""

; Look for theme-specific backgrounds first (GUI_Dark.png or GUI_Light.png)
themeImageName := isDarkTheme ? "GUI_Dark" : "GUI_Light"

; Check for various file formats in order of preference
imageExtensions := ["png", "jpg", "jpeg", "bmp", "gif"]
for index, ext in imageExtensions {
    if FileExist(A_ScriptDir . "\" . themeImageName . "." . ext) {
        backgroundImagePath := A_ScriptDir . "\" . themeImageName . "." . ext
        break
    }
}

; If no theme-specific background found, fall back to generic GUI image
if (backgroundImagePath = "") {
    for index, ext in imageExtensions {
        if FileExist(A_ScriptDir . "\GUI." . ext) {
            backgroundImagePath := A_ScriptDir . "\GUI." . ext
            break
        }
    }
}

; Add the background image if a valid file was found
if (backgroundImagePath != "") {
    ; Add the "Hidden" option based on useBackgroundImage
    hiddenState := useBackgroundImage ? "" : "Hidden"
    Gui, Add, Picture, x0 y0 w%GUI_WIDTH% h%GUI_HEIGHT% +0x4000000 vBackgroundPic %hiddenState%, %backgroundImagePath%
}

; Initialize GUI with no section selected
Gui, Show, w%GUI_WIDTH% h%GUI_HEIGHT%, PTCGPB Bot Setup [Non-Commercial 4.0 International License]

; Hide all sections on startup
CurrentVisibleSection := ""
HideAllSections()
UpdateTabButtonColors()
ApplyTheme()  ; Ensure everything is colored properly on startup

; Update the section title to indicate welcome screen
GuiControl,, ActiveSection, Welcome to PTCGP Bot - Select a section from the sidebar

; Update keyboard shortcuts for sections (updated to new structure)
^1::HandleKeyboardShortcut(1)    ; Reroll Settings
^2::HandleKeyboardShortcut(2)    ; System Settings
^3::HandleKeyboardShortcut(3)    ; Pack Settings
^4::HandleKeyboardShortcut(4)    ; Save For Trade
^5::HandleKeyboardShortcut(5)    ; Discord Settings
^6::HandleKeyboardShortcut(6)    ; Download Settings

; Function key shortcuts with the requested mapping
F1::HandleFunctionKeyShortcut(1)  ; Launch All Mumu
F2::HandleFunctionKeyShortcut(2)  ; Arrange Windows
F3::HandleFunctionKeyShortcut(3)  ; Start Bot
F4::ShowHelpMenu()                ; Help Menu
Return

ToggleTheme:
    ; Toggle the theme
    global isDarkTheme
    isDarkTheme := !isDarkTheme

    ; Update theme toggle button text
    GuiControl,, ThemeToggle, % isDarkTheme ? "Light Mode" : "Dark Mode"

    ; Update background toggle button color
    GuiControlGet, hwnd, Hwnd, BackgroundToggle
    SetButtonColor(hwnd, isDarkTheme ? "81A1C1" : "5E81AC")

    ; Apply the new theme - ensure all colors update
    ApplyTheme()

    ; Update header text and colors
    GuiControl,, HeaderTitle, % "Arturo's PTCGP Bot"
    if (isDarkTheme) {
        GuiControl, +c%DARK_TEXT%, HeaderTitle
    } else {
        GuiControl, +c%LIGHT_TEXT%, HeaderTitle
    }

    ; Make sure current section is properly colored based on new structure
    if (CurrentVisibleSection = "RerollSettings")
        ShowRerollSettingsSection()
    else if (CurrentVisibleSection = "SystemSettings")
        ShowSystemSettingsSection()
    else if (CurrentVisibleSection = "PackSettings")
        ShowPackSettingsSection()
    else if (CurrentVisibleSection = "SaveForTrade")
        ShowSaveForTradeSection()
    else if (CurrentVisibleSection = "DiscordSettings")
        ShowDiscordSettingsSection()
    else if (CurrentVisibleSection = "DownloadSettings")
        ShowDownloadSettingsSection()

    ; Save the theme setting
    IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme

    ; Check for theme-specific background and update if needed
    themeImageName := isDarkTheme ? "GUI_Dark" : "GUI_Light"
    newBackgroundPath := ""

    ; Check for various file formats in preferred order
    imageExtensions := ["png", "jpg", "jpeg", "bmp", "gif"]
    for index, ext in imageExtensions {
        if FileExist(A_ScriptDir . "\" . themeImageName . "." . ext) {
            newBackgroundPath := A_ScriptDir . "\" . themeImageName . "." . ext
            break
        }
    }

    ; If theme-specific background found, update it
    if (newBackgroundPath != "") {
        GuiControl,, BackgroundPic, %newBackgroundPath%
    }
Return

ToggleBackground:
    ToggleBackgroundImage()
Return

ToggleSection:
    ; Get clicked button name
    ClickedButton := A_GuiControl

    ; Extract just the section name without the "Btn_" prefix
    StringTrimLeft, SectionName, ClickedButton, 4

    ; Hide all sections
    HideAllSections()

    ; Show section based on new structure
    if (SectionName = "RerollSettings") {
        ShowRerollSettingsSection()
    } else if (SectionName = "SystemSettings") {
        ShowSystemSettingsSection()
    } else if (SectionName = "PackSettings") {
        ShowPackSettingsSection()
    } else if (SectionName = "SaveForTrade") {
        ShowSaveForTradeSection()
    } else if (SectionName = "DiscordSettings") {
        ShowDiscordSettingsSection()
    } else if (SectionName = "DownloadSettings") {
        ShowDownloadSettingsSection()
    }

    ; Update current section and tab highlighting
    CurrentVisibleSection := SectionName
    UpdateTabButtonColors()

    ; Set section title with section-specific color
    friendlyName := GetFriendlyName(SectionName)
    GuiControl,, ActiveSection, Current Section: %friendlyName%

    ; Get section color
    sectionColor := isDarkTheme ? DARK_SECTION_COLORS[SectionName] : LIGHT_SECTION_COLORS[SectionName]
    GuiControl, +c%sectionColor%, ActiveSection

    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
Return

mainSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT

    if (runMain) {
        GuiControl, Show, Mains

        ; Apply theme-specific styling
        if (isDarkTheme) {
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Mains
        } else {
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Mains
        }
    }
    else {
        GuiControl, Hide, Mains
    }
return

discordSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT

    if (heartBeat) {
        GuiControl, Show, heartBeatName
        GuiControl, Show, heartBeatWebhookURL
        GuiControl, Show, heartBeatDelay
        GuiControl, Show, hbName
        GuiControl, Show, hbURL
        GuiControl, Show, hbDelay

        ; Apply theme-specific styling
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, hbName
            GuiControl, +c%DARK_TEXT%, hbURL
            GuiControl, +c%DARK_TEXT%, hbDelay
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatName
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatWebhookURL
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, heartBeatDelay
        } else {
            GuiControl, +c%LIGHT_TEXT%, hbName
            GuiControl, +c%LIGHT_TEXT%, hbURL
            GuiControl, +c%LIGHT_TEXT%, hbDelay
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatName
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatWebhookURL
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, heartBeatDelay
        }
    }
    else {
        GuiControl, Hide, heartBeatName
        GuiControl, Hide, heartBeatWebhookURL
        GuiControl, Hide, heartBeatDelay
        GuiControl, Hide, hbName
        GuiControl, Hide, hbURL
        GuiControl, Hide, hbDelay
    }
return

s4tSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global SaveForTradeDivider_1, SaveForTradeDivider_2

    if (s4tEnabled) {
        GuiControl, Show, s4tSilent
        GuiControl, Show, s4t3Dmnd
        GuiControl, Show, s4t4Dmnd
        GuiControl, Show, s4t1Star
        GuiControl, Show, Txt_S4TSeparator
        GuiControl, Show, s4tWP
        GuiControl, Show, S4TDiscordSettingsSubHeading
        GuiControl, Show, Txt_S4T_DiscordID
        GuiControl, Show, s4tDiscordUserId
        GuiControl, Show, Txt_S4T_DiscordWebhook
        GuiControl, Show, s4tDiscordWebhookURL
        GuiControl, Show, s4tSendAccountXml
        GuiControl, Show, SaveForTradeDivider_1
        GuiControl, Show, SaveForTradeDivider_2
        GuiControl, Show, SaveForTradeHeading
        GuiControl, Show, SaveForTradeDivider_1
        GuiControl, Show, SaveForTradeDivider_2


        ; Apply theme-specific styling
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, s4tSilent
            GuiControl, +c%DARK_TEXT%, s4t3Dmnd
            GuiControl, +c%DARK_TEXT%, s4t4Dmnd
            GuiControl, +c%DARK_TEXT%, s4t1Star
            GuiControl, +c%DARK_TEXT%, s4tWP

            ; S4T Discord settings styling
            sectionColor := DARK_SECTION_COLORS["SaveForTrade"]
            GuiControl, +c%sectionColor%, S4TDiscordSettingsSubHeading
            GuiControl, +c%DARK_TEXT%, Txt_S4T_DiscordID
            GuiControl, +c%DARK_TEXT%, Txt_S4T_DiscordWebhook
            GuiControl, +c%DARK_TEXT%, s4tSendAccountXml
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tDiscordUserId
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tDiscordWebhookURL
        } else {
            GuiControl, +c%LIGHT_TEXT%, s4tSilent
            GuiControl, +c%LIGHT_TEXT%, s4t3Dmnd
            GuiControl, +c%LIGHT_TEXT%, s4t4Dmnd
            GuiControl, +c%LIGHT_TEXT%, s4t1Star
            GuiControl, +c%LIGHT_TEXT%, s4tWP

            ; S4T Discord settings styling
            sectionColor := LIGHT_SECTION_COLORS["SaveForTrade"]
            GuiControl, +c%sectionColor%, S4TDiscordSettingsSubHeading
            GuiControl, +c%LIGHT_TEXT%, Txt_S4T_DiscordID
            GuiControl, +c%LIGHT_TEXT%, Txt_S4T_DiscordWebhook
            GuiControl, +c%LIGHT_TEXT%, s4tSendAccountXml
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tDiscordUserId
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tDiscordWebhookURL
        }

        ; Check if Shining is enabled to show Gholdengo - Important logic from PTCGPB.ahk
        GuiControlGet, Shining
        if (Shining) {
            GuiControl, Show, s4tGholdengo
            GuiControl, Show, s4tGholdengoEmblem
            GuiControl, Show, s4tGholdengoArrow

            if (isDarkTheme) {
                GuiControl, +c%DARK_TEXT%, s4tGholdengo
                GuiControl, +c%DARK_TEXT%, s4tGholdengoArrow
            } else {
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengo
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengoArrow
            }
        } else {
            GuiControl, Hide, s4tGholdengo
            GuiControl, Hide, s4tGholdengoEmblem
            GuiControl, Hide, s4tGholdengoArrow
        }

        if (s4tWP) {
            GuiControl, Show, s4tWPMinCardsLabel
            GuiControl, Show, s4tWPMinCards

            if (isDarkTheme) {
                GuiControl, +c%DARK_TEXT%, s4tWPMinCardsLabel
                GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tWPMinCards
            } else {
                GuiControl, +c%LIGHT_TEXT%, s4tWPMinCardsLabel
                GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tWPMinCards
            }
        } else {
            GuiControl, Hide, s4tWPMinCardsLabel
            GuiControl, Hide, s4tWPMinCards
        }
    } else {
        GuiControl, Hide, s4tSilent
        GuiControl, Hide, s4t3Dmnd
        GuiControl, Hide, s4t4Dmnd
        GuiControl, Hide, s4t1Star
        GuiControl, Hide, s4tGholdengo
        GuiControl, Hide, s4tGholdengoEmblem
        GuiControl, Hide, s4tGholdengoArrow
        GuiControl, Hide, Txt_S4TSeparator
        GuiControl, Hide, s4tWP
        GuiControl, Hide, s4tWPMinCardsLabel
        GuiControl, Hide, s4tWPMinCards
        GuiControl, Hide, S4TDiscordSettingsSubHeading
        GuiControl, Hide, Txt_S4T_DiscordID
        GuiControl, Hide, s4tDiscordUserId
        GuiControl, Hide, Txt_S4T_DiscordWebhook
        GuiControl, Hide, s4tDiscordWebhookURL
        GuiControl, Hide, s4tSendAccountXml
        GuiControl, Hide, SaveForTradeDivider_1
        GuiControl, Hide, SaveForTradeDivider_2
    }
return

s4tWPSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT

    if (s4tWP) {
        GuiControl, Show, s4tWPMinCardsLabel
        GuiControl, Show, s4tWPMinCards

        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, s4tWPMinCardsLabel
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, s4tWPMinCards
        } else {
            GuiControl, +c%LIGHT_TEXT%, s4tWPMinCardsLabel
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, s4tWPMinCards
        }
    } else {
        GuiControl, Hide, s4tWPMinCardsLabel
        GuiControl, Hide, s4tWPMinCards
    }
return

TesseractOptionSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    if (tesseractOption) {
        GuiControl, Show, Txt_TesseractPath
        GuiControl, Show, tesseractPath
        
        ; Apply theme-specific styling
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, Txt_TesseractPath
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, tesseractPath
        } else {
            GuiControl, +c%LIGHT_TEXT%, Txt_TesseractPath
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, tesseractPath
        }
    } else {
        GuiControl, Hide, Txt_TesseractPath
        GuiControl, Hide, tesseractPath
    }
return

deleteSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT

    if(InStr(deleteMethod, "Inject")) {
        GuiControl, Hide, nukeAccount
        nukeAccount = false
    }
    else {
        GuiControl, Show, nukeAccount
        ; Make sure the checkbox is colored properly
        if (isDarkTheme) {
            GuiControl, +c%DARK_TEXT%, nukeAccount
        } else {
            GuiControl, +c%LIGHT_TEXT%, nukeAccount
        }
    }
return

defaultLangSetting:
    global scaleParam
    GuiControlGet, defaultLanguage,, defaultLanguage
    if (defaultLanguage = "Scale125")
        scaleParam := 277
    else if (defaultLanguage = "Scale100")
        scaleParam := 287
return

ArrangeWindows:
    GuiControlGet, runMain,, runMain
    GuiControlGet, Mains,, Mains
    GuiControlGet, Instances,, Instances
    GuiControlGet, Columns,, Columns
    GuiControlGet, SelectedMonitorIndex,, SelectedMonitorIndex
    
    windowsPositioned := 0
    
    if (runMain && Mains > 0) {
        Loop %Mains% {
            mainInstanceName := "Main" . (A_Index > 1 ? A_Index : "")
            if (WinExist(mainInstanceName)) {
                resetWindows(mainInstanceName, SelectedMonitorIndex, false)
                windowsPositioned++
                sleep, 10
            }
        }
    }
    
    if (Instances > 0) {
        Loop %Instances% {
            if (WinExist(A_Index)) {
                resetWindows(A_Index, SelectedMonitorIndex, false)
                windowsPositioned++
                sleep, 10
            }
        }
    }
    
    if (debugMode && windowsPositioned == 0) {
        MsgBox, No windows found to arrange
    } else {
        MsgBox, Arranged %windowsPositioned% windows
    }
return

LaunchAllMumu:
    GuiControlGet, Instances,, Instances
    GuiControlGet, folderPath,, folderPath
    GuiControlGet, runMain,, runMain
    GuiControlGet, Mains,, Mains
    GuiControlGet, instanceLaunchDelay,, instanceLaunchDelay

    IniWrite, %Instances%, Settings.ini, UserSettings, Instances
    IniWrite, %folderPath%, Settings.ini, UserSettings, folderPath
    IniWrite, %runMain%, Settings.ini, UserSettings, runMain
    IniWrite, %Mains%, Settings.ini, UserSettings, Mains
    IniWrite, %instanceLaunchDelay%, Settings.ini, UserSettings, instanceLaunchDelay

    launchAllFile := "LaunchAllMumu.ahk"
    if(FileExist(launchAllFile)) {
        Run, %launchAllFile%
    }
return

; Handle the link click
OpenLink:
    Run, https://buymeacoffee.com/aarturoo
return

OpenDiscord:
    Run, https://discord.gg/C9Nyf7P4sT
return

SaveReload:
    Gui, Submit

    IniWrite, %FriendID%, Settings.ini, UserSettings, FriendID
    IniWrite, %waitTime%, Settings.ini, UserSettings, waitTime
    IniWrite, %Delay%, Settings.ini, UserSettings, Delay
    IniWrite, %folderPath%, Settings.ini, UserSettings, folderPath
    IniWrite, %discordWebhookURL%, Settings.ini, UserSettings, discordWebhookURL
    IniWrite, %discordUserId%, Settings.ini, UserSettings, discordUserId
    IniWrite, %Columns%, Settings.ini, UserSettings, Columns
    IniWrite, %godPack%, Settings.ini, UserSettings, godPack
    IniWrite, %Instances%, Settings.ini, UserSettings, Instances
    IniWrite, %instanceStartDelay%, Settings.ini, UserSettings, instanceStartDelay
    IniWrite, %defaultLanguage%, Settings.ini, UserSettings, defaultLanguage
    IniWrite, %SelectedMonitorIndex%, Settings.ini, UserSettings, SelectedMonitorIndex
    IniWrite, %swipeSpeed%, Settings.ini, UserSettings, swipeSpeed
    IniWrite, %deleteMethod%, Settings.ini, UserSettings, deleteMethod
    IniWrite, %runMain%, Settings.ini, UserSettings, runMain
    IniWrite, %Mains%, Settings.ini, UserSettings, Mains
    IniWrite, %heartBeat%, Settings.ini, UserSettings, heartBeat
    IniWrite, %heartBeatWebhookURL%, Settings.ini, UserSettings, heartBeatWebhookURL
    IniWrite, %heartBeatName%, Settings.ini, UserSettings, heartBeatName
    IniWrite, %nukeAccount%, Settings.ini, UserSettings, nukeAccount
    IniWrite, %packMethod%, Settings.ini, UserSettings, packMethod
    IniWrite, %CheckShiningPackOnly%, Settings.ini, UserSettings, CheckShiningPackOnly
    IniWrite, %TrainerCheck%, Settings.ini, UserSettings, TrainerCheck
    IniWrite, %FullArtCheck%, Settings.ini, UserSettings, FullArtCheck
    IniWrite, %RainbowCheck%, Settings.ini, UserSettings, RainbowCheck
    IniWrite, %ShinyCheck%, Settings.ini, UserSettings, ShinyCheck
    IniWrite, %CrownCheck%, Settings.ini, UserSettings, CrownCheck
    IniWrite, %InvalidCheck%, Settings.ini, UserSettings, InvalidCheck
    IniWrite, %ImmersiveCheck%, Settings.ini, UserSettings, ImmersiveCheck
    IniWrite, %PseudoGodPack%, Settings.ini, UserSettings, PseudoGodPack
    IniWrite, %minStars%, Settings.ini, UserSettings, minStars
    IniWrite, %Palkia%, Settings.ini, UserSettings, Palkia
    IniWrite, %Dialga%, Settings.ini, UserSettings, Dialga
    IniWrite, %Arceus%, Settings.ini, UserSettings, Arceus
    IniWrite, %Shining%, Settings.ini, UserSettings, Shining
    IniWrite, %Mew%, Settings.ini, UserSettings, Mew
    IniWrite, %Pikachu%, Settings.ini, UserSettings, Pikachu
    IniWrite, %Charizard%, Settings.ini, UserSettings, Charizard
    IniWrite, %Mewtwo%, Settings.ini, UserSettings, Mewtwo
    IniWrite, %slowMotion%, Settings.ini, UserSettings, slowMotion

    IniWrite, %ocrLanguage%, Settings.ini, UserSettings, ocrLanguage
    IniWrite, %clientLanguage%, Settings.ini, UserSettings, clientLanguage
    IniWrite, %mainIdsURL%, Settings.ini, UserSettings, mainIdsURL
    IniWrite, %vipIdsURL%, Settings.ini, UserSettings, vipIdsURL
    IniWrite, %autoLaunchMonitor%, Settings.ini, UserSettings, autoLaunchMonitor
    IniWrite, %instanceLaunchDelay%, Settings.ini, UserSettings, instanceLaunchDelay

    minStarsA1Charizard := minStars
    minStarsA1Mewtwo := minStars
    minStarsA1Pikachu := minStars
    minStarsA1a := minStars
    minStarsA2Dialga := minStars
    minStarsA2Palkia := minStars
    minStarsA2a := minStars

    IniWrite, %minStarsA1Charizard%, Settings.ini, UserSettings, minStarsA1Charizard
    IniWrite, %minStarsA1Mewtwo%, Settings.ini, UserSettings, minStarsA1Mewtwo
    IniWrite, %minStarsA1Pikachu%, Settings.ini, UserSettings, minStarsA1Pikachu
    IniWrite, %minStarsA1a%, Settings.ini, UserSettings, minStarsA1a
    IniWrite, %minStarsA2Dialga%, Settings.ini, UserSettings, minStarsA2Dialga
    IniWrite, %minStarsA2Palkia%, Settings.ini, UserSettings, minStarsA2Palkia
    IniWrite, %minStarsA2a%, Settings.ini, UserSettings, minStarsA2a
    IniWrite, %minStarsA2b%, Settings.ini, UserSettings, minStarsA2b

    IniWrite, %heartBeatDelay%, Settings.ini, UserSettings, heartBeatDelay
    IniWrite, %sendAccountXml%, Settings.ini, UserSettings, sendAccountXml

    IniWrite, %s4tEnabled%, Settings.ini, UserSettings, s4tEnabled
    IniWrite, %s4tSilent%, Settings.ini, UserSettings, s4tSilent
    IniWrite, %s4t3Dmnd%, Settings.ini, UserSettings, s4t3Dmnd
    IniWrite, %s4t4Dmnd%, Settings.ini, UserSettings, s4t4Dmnd
    IniWrite, %s4t1Star%, Settings.ini, UserSettings, s4t1Star
    IniWrite, %s4tGholdengo%, Settings.ini, UserSettings, s4tGholdengo
    IniWrite, %s4tWP%, Settings.ini, UserSettings, s4tWP
    IniWrite, %s4tWPMinCards%, Settings.ini, UserSettings, s4tWPMinCards
    IniWrite, %s4tDiscordUserId%, Settings.ini, UserSettings, s4tDiscordUserId
    IniWrite, %s4tDiscordWebhookURL%, Settings.ini, UserSettings, s4tDiscordWebhookURL
    IniWrite, %s4tSendAccountXml%, Settings.ini, UserSettings, s4tSendAccountXml
    
    ; Extra Settings
    IniWrite, %tesseractPath%, Settings.ini, UserSettings, tesseractPath
    IniWrite, %applyRoleFilters%, Settings.ini, UserSettings, applyRoleFilters
    IniWrite, %debugMode%, Settings.ini, UserSettings, debugMode
    IniWrite, %tesseractOption%, Settings.ini, UserSettings, tesseractOption

    ; Save theme setting
    IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme

    ; Save background image setting
    IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage

    Reload
return

StartBot:
    Gui, Submit  ; Collect the input values from the first page
    Instances := Instances  ; Directly reference the "Instances" variable

    ; Create the second page dynamically based on the number of instances
    Gui, Destroy ; Close the first page

    IniWrite, %FriendID%, Settings.ini, UserSettings, FriendID
    IniWrite, %waitTime%, Settings.ini, UserSettings, waitTime
    IniWrite, %Delay%, Settings.ini, UserSettings, Delay
    IniWrite, %folderPath%, Settings.ini, UserSettings, folderPath
    IniWrite, %discordWebhookURL%, Settings.ini, UserSettings, discordWebhookURL
    IniWrite, %discordUserId%, Settings.ini, UserSettings, discordUserId
    IniWrite, %Columns%, Settings.ini, UserSettings, Columns
    IniWrite, %godPack%, Settings.ini, UserSettings, godPack
    IniWrite, %Instances%, Settings.ini, UserSettings, Instances
    IniWrite, %instanceStartDelay%, Settings.ini, UserSettings, instanceStartDelay
    IniWrite, %defaultLanguage%, Settings.ini, UserSettings, defaultLanguage
    IniWrite, %SelectedMonitorIndex%, Settings.ini, UserSettings, SelectedMonitorIndex
    IniWrite, %swipeSpeed%, Settings.ini, UserSettings, swipeSpeed
    IniWrite, %deleteMethod%, Settings.ini, UserSettings, deleteMethod
    IniWrite, %runMain%, Settings.ini, UserSettings, runMain
    IniWrite, %Mains%, Settings.ini, UserSettings, Mains
    IniWrite, %heartBeat%, Settings.ini, UserSettings, heartBeat
    IniWrite, %heartBeatWebhookURL%, Settings.ini, UserSettings, heartBeatWebhookURL
    IniWrite, %heartBeatName%, Settings.ini, UserSettings, heartBeatName
    IniWrite, %nukeAccount%, Settings.ini, UserSettings, nukeAccount
    IniWrite, %packMethod%, Settings.ini, UserSettings, packMethod
    IniWrite, %CheckShiningPackOnly%, Settings.ini, UserSettings, CheckShiningPackOnly
    IniWrite, %TrainerCheck%, Settings.ini, UserSettings, TrainerCheck
    IniWrite, %FullArtCheck%, Settings.ini, UserSettings, FullArtCheck
    IniWrite, %RainbowCheck%, Settings.ini, UserSettings, RainbowCheck
    IniWrite, %ShinyCheck%, Settings.ini, UserSettings, ShinyCheck
    IniWrite, %CrownCheck%, Settings.ini, UserSettings, CrownCheck
    IniWrite, %InvalidCheck%, Settings.ini, UserSettings, InvalidCheck
    IniWrite, %ImmersiveCheck%, Settings.ini, UserSettings, ImmersiveCheck
    IniWrite, %PseudoGodPack%, Settings.ini, UserSettings, PseudoGodPack
    IniWrite, %minStars%, Settings.ini, UserSettings, minStars
    IniWrite, %Palkia%, Settings.ini, UserSettings, Palkia
    IniWrite, %Dialga%, Settings.ini, UserSettings, Dialga
    IniWrite, %Arceus%, Settings.ini, UserSettings, Arceus
    IniWrite, %Shining%, Settings.ini, UserSettings, Shining
    IniWrite, %Mew%, Settings.ini, UserSettings, Mew
    IniWrite, %Pikachu%, Settings.ini, UserSettings, Pikachu
    IniWrite, %Charizard%, Settings.ini, UserSettings, Charizard
    IniWrite, %Mewtwo%, Settings.ini, UserSettings, Mewtwo
    IniWrite, %slowMotion%, Settings.ini, UserSettings, slowMotion

    IniWrite, %ocrLanguage%, Settings.ini, UserSettings, ocrLanguage
    IniWrite, %clientLanguage%, Settings.ini, UserSettings, clientLanguage
    IniWrite, %mainIdsURL%, Settings.ini, UserSettings, mainIdsURL
    IniWrite, %vipIdsURL%, Settings.ini, UserSettings, vipIdsURL
    IniWrite, %autoLaunchMonitor%, Settings.ini, UserSettings, autoLaunchMonitor
    IniWrite, %instanceLaunchDelay%, Settings.ini, UserSettings, instanceLaunchDelay

    minStarsA1Charizard := minStars
    minStarsA1Mewtwo := minStars
    minStarsA1Pikachu := minStars
    minStarsA1a := minStars
    minStarsA2Dialga := minStars
    minStarsA2Palkia := minStars
    minStarsA2a := minStars

    IniWrite, %minStarsA1Charizard%, Settings.ini, UserSettings, minStarsA1Charizard
    IniWrite, %minStarsA1Mewtwo%, Settings.ini, UserSettings, minStarsA1Mewtwo
    IniWrite, %minStarsA1Pikachu%, Settings.ini, UserSettings, minStarsA1Pikachu
    IniWrite, %minStarsA1a%, Settings.ini, UserSettings, minStarsA1a
    IniWrite, %minStarsA2Dialga%, Settings.ini, UserSettings, minStarsA2Dialga
    IniWrite, %minStarsA2Palkia%, Settings.ini, UserSettings, minStarsA2Palkia
    IniWrite, %minStarsA2a%, Settings.ini, UserSettings, minStarsA2a
    IniWrite, %minStarsA2b%, Settings.ini, UserSettings, minStarsA2b
    
    IniWrite, %heartBeatDelay%, Settings.ini, UserSettings, heartBeatDelay
    IniWrite, %sendAccountXml%, Settings.ini, UserSettings, sendAccountXml

    IniWrite, %s4tEnabled%, Settings.ini, UserSettings, s4tEnabled
    IniWrite, %s4tSilent%, Settings.ini, UserSettings, s4tSilent
    IniWrite, %s4t3Dmnd%, Settings.ini, UserSettings, s4t3Dmnd
    IniWrite, %s4t4Dmnd%, Settings.ini, UserSettings, s4t4Dmnd
    IniWrite, %s4t1Star%, Settings.ini, UserSettings, s4t1Star
    IniWrite, %s4tWP%, Settings.ini, UserSettings, s4tWP
    IniWrite, %s4tWPMinCards%, Settings.ini, UserSettings, s4tWPMinCards
    IniWrite, %s4tDiscordUserId%, Settings.ini, UserSettings, s4tDiscordUserId
    IniWrite, %s4tDiscordWebhookURL%, Settings.ini, UserSettings, s4tDiscordWebhookURL
    IniWrite, %s4tSendAccountXML%, Settings.ini, UserSettings, s4tSendAccountXML
    IniWrite, %s4tGholdengo%, Settings.ini, UserSettings, s4tGholdengo
    
    ; Extra Settings
    IniWrite, %tesseractPath%, Settings.ini, UserSettings, tesseractPath
    IniWrite, %applyRoleFilters%, Settings.ini, UserSettings, applyRoleFilters
    IniWrite, %debugMode%, Settings.ini, UserSettings, debugMode
    IniWrite, %tesseractOption%, Settings.ini, UserSettings, tesseractOption
        
    IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme
    IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage

; Using FriendID field to provide a URL to download ids.txt is deprecated.
    if (inStr(FriendID, "http")) {
        MsgBox, To provide a URL for friend IDs, please use the ids.txt API field and leave the Friend ID field empty.

        if (mainIdsURL = "") {
            IniWrite, "", Settings.ini, UserSettings, FriendID
            IniWrite, %FriendID%, Settings.ini, UserSettings, mainIdsURL
        }

        Reload
    }

    ; Download a new Main ID file prior to running the rest of the below
    if (mainIdsURL != "") {
        DownloadFile(mainIdsURL, "ids.txt")
    }

; Run main before instances to account for instance start delay
    if (runMain) {
        Loop, %Mains%
        {
            if (A_Index != 1) {
                SourceFile := "Scripts\Main.ahk" ; Path to the source .ahk file
                TargetFolder := "Scripts\" ; Path to the target folder
                TargetFile := TargetFolder . "Main" . A_Index . ".ahk" ; Generate target file path
                FileDelete, %TargetFile%
                FileCopy, %SourceFile%, %TargetFile%, 1 ; Copy source file to target
                if (ErrorLevel)
                    MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
            }

            mainInstanceName := "Main" . (A_Index > 1 ? A_Index : "")
            FileName := "Scripts\" . mainInstanceName . ".ahk"
            Command := FileName

            if (A_Index > 1 && instanceStartDelay > 0) {
                instanceStartDelayMS := instanceStartDelay * 1000
                Sleep, instanceStartDelayMS
            }

            Run, %Command%
        }
    }

; Loop to process each instance
    Loop, %Instances%
    {
        if (A_Index != 1) {
            SourceFile := "Scripts\1.ahk" ; Path to the source .ahk file
            TargetFolder := "Scripts\" ; Path to the target folder
            TargetFile := TargetFolder . A_Index . ".ahk" ; Generate target file path
            if(Instances > 1) {
                FileDelete, %TargetFile%
                FileCopy, %SourceFile%, %TargetFile%, 1 ; Copy source file to target
            }
            if (ErrorLevel)
                MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
        }

        FileName := "Scripts\" . A_Index . ".ahk"
        Command := FileName

        if ((Mains > 1 || A_Index > 1) && instanceStartDelay > 0) {
            instanceStartDelayMS := instanceStartDelay * 1000
            Sleep, instanceStartDelayMS
        }

        ; Clear out the last run time so that our monitor script doesn't try to kill and refresh this instance right away
        metricFile := A_ScriptDir . "\Scripts\" . A_Index . ".ini"
        if (FileExist(metricFile)) {
            IniWrite, 0, %metricFile%, Metrics, LastEndEpoch
        }

        Run, %Command%
    }

    if(autoLaunchMonitor) {
        monitorFile := "Monitor.ahk"
        if(FileExist(monitorFile)) {
            Run, %monitorFile%
        }
    }

SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
    SysGet, Monitor, Monitor, %SelectedMonitorIndex%
    rerollTime := A_TickCount

    typeMsg := "\nType: " . deleteMethod
    injectMethod := false
    if(InStr(deleteMethod, "Inject"))
        injectMethod := true
    if(packMethod)
        typeMsg .= " (1P Method)"
    if(nukeAccount && !injectMethod)
        typeMsg .= " (Menu Delete)"

    Selected := []
    selectMsg := "\nOpening: "
    if(Shining)
        Selected.Push("Shining")
    if(Arceus)
        Selected.Push("Arceus")
    if(Palkia)
        Selected.Push("Palkia")
    if(Dialga)
        Selected.Push("Dialga")
    if(Mew)
        Selected.Push("Mew")
    if(Pikachu)
        Selected.Push("Pikachu")
    if(Charizard)
        Selected.Push("Charizard")
    if(Mewtwo)
        Selected.Push("Mewtwo")

    for index, value in Selected {
        if(index = Selected.MaxIndex())
            commaSeparate := ""
        else
            commaSeparate := ", "
        if(value)
            selectMsg .= value . commaSeparate
        else
            selectMsg .= value . commaSeparate
    }

Loop {
        Sleep, 30000

        ; Check if Main toggled GP Test Mode and send notification if needed
        IniRead, mainTestMode, HeartBeat.ini, TestMode, Main, -1
        if (mainTestMode != -1) {
            ; Main has toggled test mode, get status and send notification
            IniRead, mainStatus, HeartBeat.ini, HeartBeat, Main, 0
            
            onlineAHK := ""
            offlineAHK := ""
            Online := []

            Loop %Instances% {
                IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
                if(value)
                    Online.Push(1)
                else
                    Online.Push(0)
                IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
            }

            for index, value in Online {
                if(index = Online.MaxIndex())
                    commaSeparate := ""
                else
                    commaSeparate := ", "
                if(value)
                    onlineAHK .= A_Index . commaSeparate
                else
                    offlineAHK .= A_Index . commaSeparate
            }

            if (runMain) {
                if(mainStatus) {
                    if (onlineAHK)
                        onlineAHK := "Main, " . onlineAHK
                    else
                        onlineAHK := "Main"
                }
                else {
                    if (offlineAHK)
                        offlineAHK := "Main, " . offlineAHK
                    else
                        offlineAHK := "Main"
                }
            }

            if(offlineAHK = "")
                offlineAHK := "Offline: none"
            else
                offlineAHK := "Offline: " . RTrim(offlineAHK, ", ")
            if(onlineAHK = "")
                onlineAHK := "Online: none"
            else
                onlineAHK := "Online: " . RTrim(onlineAHK, ", ")

            ; Create status message with all regular heartbeat info
            discMessage := heartBeatName ? "\n" . heartBeatName : ""
            discMessage .= "\n" . onlineAHK . "\n" . offlineAHK
            
            total := SumVariablesInJsonFile()
            totalSeconds := Round((A_TickCount - rerollTime) / 1000)
            mminutes := Floor(totalSeconds / 60)
            packStatus := "Time: " . mminutes . "m | Packs: " . total
            packStatus .= " | Avg: " . Round(total / mminutes, 2) . " packs/min"
            
            discMessage .= "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
            discMessage .= typeMsg
            discMessage .= selectMsg
            
            ; Add special note about Main's test mode status
            if (mainTestMode == "1")
                discMessage .= "\n\nMain entered GP Test Mode ✕" ;We can change this later
            else
                discMessage .= "\n\nMain exited GP Test Mode ✓" ;We can change this later
                
            ; Send the message
            LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
            
            ; Clear the flag
            IniDelete, HeartBeat.ini, TestMode, Main
        }

; Every 5 minutes, pull down the main ID list
        if(mainIdsURL != "" && Mod(A_Index, 10) = 0) {
            DownloadFile(mainIdsURL, "ids.txt")
        }

        ; Sum all variable values and write to total.json
        total := SumVariablesInJsonFile()
        totalSeconds := Round((A_TickCount - rerollTime) / 1000) ; Total time in seconds
        mminutes := Floor(totalSeconds / 60)

        packStatus := "Time: " . mminutes . "m Packs: " . total
        packStatus .= "   |   Avg: " . Round(total / mminutes, 2) . " packs/min"

        ; Display pack status at the bottom of the first reroll instance
        DisplayPackStatus(packStatus, ((runMain ? Mains * scaleParam : 0) + 5), 490)

        if(heartBeat)
            if((A_Index = 1 || (Mod(A_Index, (heartBeatDelay // 0.5)) = 0))) {
                onlineAHK := ""
                offlineAHK := ""
                Online := []

                Loop %Instances% {
                    IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
                    if(value)
                        Online.Push(1)
                    else
                        Online.Push(0)
                    IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
                }

                for index, value in Online {
                    if(index = Online.MaxIndex())
                        commaSeparate := ""
                    else
                        commaSeparate := ", "
                    if(value)
                        onlineAHK .= A_Index . commaSeparate
                    else
                        offlineAHK .= A_Index . commaSeparate
                }

                if(runMain) {
                    IniRead, value, HeartBeat.ini, HeartBeat, Main
                    if(value) {
                        if (onlineAHK)
                            onlineAHK := "Main, " . onlineAHK
                        else
                            onlineAHK := "Main"
                    }
                    else {
                        if (offlineAHK)
                            offlineAHK := "Main, " . offlineAHK
                        else
                            offlineAHK := "Main"
                    }
                    IniWrite, 0, HeartBeat.ini, HeartBeat, Main
                }

                if(offlineAHK = "")
                    offlineAHK := "Offline: none"
                else
                    offlineAHK := "Offline: " . RTrim(offlineAHK, ", ")
                if(onlineAHK = "")
                    onlineAHK := "Online: none"
                else
                    onlineAHK := "Online: " . RTrim(onlineAHK, ", ")

                discMessage := heartBeatName ? "\n" . heartBeatName : ""
                discMessage .= "\n" . onlineAHK . "\n" . offlineAHK . "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
                discMessage .= typeMsg
                discMessage .= selectMsg

                LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
            }
    }
Return

GuiClose:
ExitApp
return

; Improved status display function
DisplayPackStatus(Message, X := 0, Y := 80) {
    global SelectedMonitorIndex
    static GuiName := "PackStatusGUI"

    ; Fixed light theme colors
    bgColor := "F0F5F9"      ; Light background
    textColor := "2E3440"    ; Dark text for contrast

    MaxRetries := 10
    RetryCount := 0

    try {
        ; Get monitor origin from index
        SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
        SysGet, Monitor, Monitor, %SelectedMonitorIndex%
        X := MonitorLeft + X
        Y := MonitorTop + Y

        ; Check if GUI already exists
        Gui %GuiName%:+LastFoundExist
        if WinExist() {
            GuiControl, %GuiName%:, PacksText, %Message%
        }
        else {
            ; Create a new GUI with light theme styling
            OwnerWND := WinExist(1)
            if(!OwnerWND)
                Gui, %GuiName%:New, +ToolWindow -Caption +LastFound
            else
                Gui, %GuiName%:New, +Owner%OwnerWND% +ToolWindow -Caption +LastFound

            Gui, %GuiName%:Color, %bgColor%  ; Light background
            Gui, %GuiName%:Margin, 2, 2
            Gui, %GuiName%:Font, s8 c%textColor% ; Dark text
            Gui, %GuiName%:Add, Text, vPacksText c%textColor%, %Message%

            ; Show the GUI without activating it
            Gui, %GuiName%:Show, NoActivate x%X% y%Y%, %GuiName%
        }
    } catch e {
        ; Silent error handling
    }
}

; New hotkey for sending "All Offline" status message
~+F7::
    SendAllInstancesOfflineStatus()
ExitApp
return

; Function to send a Discord message with all instances marked as offline
SendAllInstancesOfflineStatus() {
    global heartBeatName, heartBeatWebhookURL, localVersion, githubUser, Instances, runMain, Mains
    global typeMsg, selectMsg, rerollTime, scaleParam
    
    ; Display visual feedback that the hotkey was triggered
    DisplayPackStatus("Shift+F7 pressed - Sending offline heartbeat to Discord...", ((runMain ? Mains * scaleParam : 0) + 5), 490)
    
    ; Create message showing all instances as offline
    offlineInstances := ""
    if (runMain) {
        offlineInstances := "Main"
        if (Mains > 1) {
            Loop, % Mains - 1
                offlineInstances .= ", Main" . (A_Index + 1)
        }
        if (Instances > 0)
            offlineInstances .= ", "
    }
    
    Loop, %Instances% {
        offlineInstances .= A_Index
        if (A_Index < Instances)
            offlineInstances .= ", "
    }
    
    ; Create status message with heartbeat info
    discMessage := heartBeatName ? "\n" . heartBeatName : ""
    discMessage .= "\nOnline: none"
    discMessage .= "\nOffline: " . offlineInstances
    
    ; Add pack statistics
    total := SumVariablesInJsonFile()
    totalSeconds := Round((A_TickCount - rerollTime) / 1000)
    mminutes := Floor(totalSeconds / 60)
    packStatus := "Time: " . mminutes . "m | Packs: " . total
    packStatus .= " | Avg: " . Round(total / mminutes, 2) . " packs/min"
    
    discMessage .= "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
    discMessage .= typeMsg
    discMessage .= selectMsg
    discMessage .= "\n\n All instances marked as OFFLINE"
    
    ; Send the message
    LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
    
    ; Display confirmation in the status bar
    DisplayPackStatus("Discord notification sent: All instances marked as OFFLINE", ((runMain ? Mains * scaleParam : 0) + 5), 490)
}

; Global variable to track the current JSON file
global jsonFileName := ""

; Function to create or select the JSON file
InitializeJsonFile() {
    global jsonFileName
    fileName := A_ScriptDir . "\json\Packs.json"
    
    ; Add this line to create the directory if it doesn't exist
    FileCreateDir, %A_ScriptDir%\json
    
    if FileExist(fileName)
        FileDelete, %fileName%
    if !FileExist(fileName) {
        ; Create a new file with an empty JSON array
        FileAppend, [], %fileName%  ; Write an empty JSON array
        jsonFileName := fileName
        return
    }
}

; Function to append a time and variable pair to the JSON file
AppendToJsonFile(variableValue) {
    global jsonFileName
    if (jsonFileName = "") {
        MsgBox, JSON file not initialized. Call InitializeJsonFile() first.
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

; Function to sum all variable values in the JSON file
SumVariablesInJsonFile() {
    global jsonFileName
    if (jsonFileName = "") {
        return 0  ; Return 0 instead of nothing if jsonFileName is empty
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
    if(sum > 0) {
        totalFile := A_ScriptDir . "\json\total.json"
        totalContent := "{""total_sum"": " sum "}"
        FileDelete, %totalFile%
        FileAppend, %totalContent%, %totalFile%
    }

    return sum
}

CheckForUpdate() {

global updateCheckPerformed, githubUser, repoName, localVersion, zipPath, extractPath, scriptFolder
    
    ; Skip if already performed
    if (updateCheckPerformed)
        return
    
    updateCheckPerformed := true

    global githubUser, repoName, localVersion, zipPath, extractPath, scriptFolder
    url := "https://api.github.com/repos/" githubUser "/" repoName "/releases/latest"

    response := HttpGet(url)
    if !response
    {
        MsgBox, Failed to fetch release info.
        return
    }
    latestReleaseBody := FixFormat(ExtractJSONValue(response, "body"))
    latestVersion := ExtractJSONValue(response, "tag_name")
    zipDownloadURL := ExtractJSONValue(response, "zipball_url")
    Clipboard := latestReleaseBody
    if (zipDownloadURL = "" || !InStr(zipDownloadURL, "http"))
    {
        MsgBox, Failed to find the ZIP download URL in the release.
        return
    }

    if (latestVersion = "")
    {
        MsgBox, Failed to retrieve version info.
        return
    }

    if (VersionCompare(latestVersion, localVersion) > 0)
    {
        ; Get release notes from the JSON (ensure this is populated earlier in the script)
        releaseNotes := latestReleaseBody  ; Assuming `latestReleaseBody` contains the release notes

        ; Show a message box asking if the user wants to download
        MsgBox, 4, Update Available %latestVersion%, %releaseNotes%`n`nDo you want to download the latest version?

        ; If the user clicks Yes (return value 6)
        IfMsgBox, Yes
        {
            MsgBox, 64, Downloading..., Downloading the latest version...

            ; Proceed with downloading the update
            URLDownloadToFile, %zipDownloadURL%, %zipPath%
            if ErrorLevel
            {
                MsgBox, Failed to download update.
                return
            }
            else {
                MsgBox, Download complete. Extracting...

                ; Create a temporary folder for extraction
                tempExtractPath := A_Temp "\PTCGPB_Temp"
                FileCreateDir, %tempExtractPath%

                ; Extract the ZIP file into the temporary folder
                RunWait, powershell -Command "Expand-Archive -Path '%zipPath%' -DestinationPath '%tempExtractPath%' -Force",, Hide

                ; Check if extraction was successful
                if !FileExist(tempExtractPath)
                {
                    MsgBox, Failed to extract the update.
                    return
                }

                ; Get the first subfolder in the extracted folder
                Loop, Files, %tempExtractPath%\*, D
                {
                    extractedFolder := A_LoopFileFullPath
                    break
                }

                ; Check if a subfolder was found and move its contents recursively to the script folder
                if (extractedFolder)
                {
                    MoveFilesRecursively(extractedFolder, scriptFolder)

                    ; Clean up the temporary extraction folder
                    FileRemoveDir, %tempExtractPath%, 1
                    MsgBox, Update installed. Restarting...
                    Reload
                }
                else
                {
                    MsgBox, Failed to find the extracted contents.
                    return
                }
            }
        }
        else
        {
            MsgBox, The update was canceled.
            return
        }
    }
    else
    {
        MsgBox, You are running the latest version (%localVersion%).
    }
}

MoveFilesRecursively(srcFolder, destFolder) {
    ; Loop through all files and subfolders in the source folder
    Loop, Files, % srcFolder . "\*", R
    {
        ; Get the relative path of the file/folder from the srcFolder
        relativePath := SubStr(A_LoopFileFullPath, StrLen(srcFolder) + 2)

        ; Create the corresponding destination path
        destPath := destFolder . "\" . relativePath

        ; If it's a directory, create it in the destination folder
        if (A_LoopIsDir)
        {
            ; Ensure the directory exists, if not, create it
            FileCreateDir, % destPath
        }
        else
        {
            if ((relativePath = "ids.txt" && FileExist(destPath))
                || (relativePath = "usernames.txt" && FileExist(destPath))
                || (relativePath = "discord.txt" && FileExist(destPath))
                || (relativePath = "vip_ids.txt" && FileExist(destPath))) {
                continue
            }
            ; If it's a file, move it to the destination folder
            ; Ensure the directory exists before moving the file
            FileCreateDir, % SubStr(destPath, 1, InStr(destPath, "\", 0, 0) - 1)
            FileMove, % A_LoopFileFullPath, % destPath, 1
        }
    }
}

HttpGet(url) {
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    http.Send()
    return http.ResponseText
}

; Existing function to extract value from JSON
ExtractJSONValue(json, key1, key2:="", ext:="") {
    value := ""
    json := StrReplace(json, """", "")
    lines := StrSplit(json, ",")

    Loop, % lines.MaxIndex()
    {
        if InStr(lines[A_Index], key1 ":") {
            ; Take everything after the first colon as the value
            value := SubStr(lines[A_Index], InStr(lines[A_Index], ":") + 1)
            if (key2 != "")
            {
                if InStr(lines[A_Index+1], key2 ":") && InStr(lines[A_Index+1], ext)
                    value := SubStr(lines[A_Index+1], InStr(lines[A_Index+1], ":") + 1)
            }
            break
        }
    }
    return Trim(value)
}

FixFormat(text) {
    ; Replace carriage return and newline with an actual line break
    text := StrReplace(text, "\r\n", "`n")  ; Replace \r\n with actual newlines
    text := StrReplace(text, "\n", "`n")    ; Replace \n with newlines

    ; Remove unnecessary backslashes before other characters like "player" and "None"
    text := StrReplace(text, "\player", "player")   ; Example: removing backslashes around words
    text := StrReplace(text, "\None", "None")       ; Remove backslash around "None"
    text := StrReplace(text, "\Welcome", "Welcome") ; Removing \ before "Welcome"

    ; Escape commas by replacing them with %2C (URL encoding)
    text := StrReplace(text, ",", "")

    return text
}

VersionCompare(v1, v2) {
    ; Remove non-numeric characters (like 'alpha', 'beta')
    cleanV1 := RegExReplace(v1, "[^\d.]")
    cleanV2 := RegExReplace(v2, "[^\d.]")

    v1Parts := StrSplit(cleanV1, ".")
    v2Parts := StrSplit(cleanV2, ".")

    Loop, % Max(v1Parts.MaxIndex(), v2Parts.MaxIndex()) {
        num1 := v1Parts[A_Index] ? v1Parts[A_Index] : 0
        num2 := v2Parts[A_Index] ? v2Parts[A_Index] : 0
        if (num1 > num2)
            return 1
        if (num1 < num2)
            return -1
    }

    ; If versions are numerically equal, check if one is an alpha version
    isV1Alpha := InStr(v1, "alpha") || InStr(v1, "beta")
    isV2Alpha := InStr(v2, "alpha") || InStr(v2, "beta")

    if (isV1Alpha && !isV2Alpha)
        return -1 ; Non-alpha version is newer
    if (!isV1Alpha && isV2Alpha)
        return 1 ; Alpha version is older

    return 0 ; Versions are equal
}