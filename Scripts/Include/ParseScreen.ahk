GetTextFromScreen(x, y, width, height, filename)
{
    ;exePath := % A_ScriptDir "\dist\parseScreen.exe"
    ;textFile := % A_ScriptDir "\temp\" filename ".txt"
    ;imageFile := % A_ScriptDir "\temp\" filename ".png"

    exePath := ".\Utility\parseScreen.exe"
    textFile := % ".\temp\" filename ".txt"
    imageFile := % ".\temp\" filename ".png"

    ; Construct the command string
    command := exePath " " x " " y " " width " " height " --output " textFile " --screenshot " imageFile

    ; Run the executable with arguments
    RunWait, %ComSpec% /c %command%

    ; Read and return the file contents
    FileRead, fileContents, %textFile%
    Return Trim(fileContents)
}