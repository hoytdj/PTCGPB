GetTextFromScreen(x, y, width, height, filename)
{
    ; Full path, no quotes
    ; Works when running multiple scripts, but doesn't support spaces
    exePath := % A_ScriptDir "\Utility\parseScreen.exe"
    textFile := % A_ScriptDir "\temp\" filename ".txt"
    imageFile := % A_ScriptDir "\temp\" filename ".png"

    ; Relative path, no quotes
    ; Supports spaces, but doesn't work when running mutiple scripts
    ; exePath := ".\Utility\parseScreen.exe"
    ; textFile := % ".\temp\" filename ".txt"
    ; imageFile := % ".\temp\" filename ".png"

    ; Full path with single quotes
    ; Doesn't work, but seems like it should
    ; exePath := """" A_ScriptDir "\Utility\parseScreen.exe" """"
    ; textFile := """" A_ScriptDir "\temp\" filename ".txt" """"
    ; imageFile := """" A_ScriptDir "\temp\" filename ".png" """"

    ; Full path with double quotes
    ; Never works
    ; exePath := "'" A_ScriptDir "\Utility\parseScreen.exe" "'"
    ; textFile := "'" A_ScriptDir "\temp\" filename ".txt" "'"
    ; imageFile := "'" A_ScriptDir "\temp\" filename ".png" "'"

    ; Construct the command string
    command := exePath " " x " " y " " width " " height " --output " textFile " --screenshot " imageFile
    ; Clipboard := command
    ; MsgBox, %command%

    ; Run the executable with arguments
    ;RunWait, %ComSpec% /c %command%
    RunWait, %command%,, Hide

    ; Read and return the file contents
    FileRead, fileContents, %textFile%
    Return Trim(fileContents)
}