; Advanced Logging Module for PTCGPB

; Log levels as global constants
global LOG_DEBUG := 10
global LOG_INFO := 20
global LOG_WARNING := 30
global LOG_ERROR := 40
global LOG_CRITICAL := 50

; Default minimum log level
global logMinLevel := 20  ; Default to INFO level
global logBasePath := A_ScriptDir . "\..\Logs\"

; Log throttling system to prevent repetitive messages
global logThrottleEnabled := true          ; Enable/disable throttling
global logLastMessages := {}               ; Store last message for each level
global logMessageCounter := {}             ; Count occurrences of each message
global logMessageFirstTime := {}           ; Store timestamp of first occurrence

; Initialize the logger
InitLogger() {
    global debugMode, logMinLevel, LOG_DEBUG, LOG_INFO, logBasePath, logThrottleEnabled
    
    ; Set log level based on debug mode
    if (debugMode)
        logMinLevel := LOG_DEBUG
    else
        logMinLevel := LOG_INFO
        
    ; Create log directories if they don't exist
    if !FileExist(logBasePath)
        FileCreateDir, %logBasePath%
    
    Log("Logger initialized. Debug mode: " . (debugMode ? "ON" : "OFF"), LOG_INFO)
    Log("Log throttling: " . (logThrottleEnabled ? "ON" : "OFF"), LOG_INFO)
}

; Check if a message should be throttled
ShouldThrottleMessage(message, level) {
    global logThrottleEnabled, logLastMessages, logMessageCounter, logMessageFirstTime
    
    if (!logThrottleEnabled || level >= LOG_ERROR)
        return false  ; Don't throttle for errors or critical messages
    
    ; Unique key for this message and level combination
    key := level . ":" . message
    
    ; If there's a different previous message for this level
    if (logLastMessages.HasKey(level) && logLastMessages[level] != message) {
        ; We need to log the last occurrence of the previous message
        oldKey := level . ":" . logLastMessages[level]
        if (logMessageCounter.HasKey(oldKey) && logMessageCounter[oldKey] > 1) {
            ; Log the previous message with count
            oldMsg := logLastMessages[level] . " (repeated " . logMessageCounter[oldKey] . " times)"
            _ActuallyLogMessage(oldMsg, level)
        }
    }
    
    ; Update counter for this message
    if (logMessageCounter.HasKey(key)) {
        logMessageCounter[key] += 1
        return true  ; Throttle all but the first occurrence
    } else {
        ; First time seeing this message
        logMessageCounter[key] := 1
        logMessageFirstTime[key] := A_TickCount // 1000
        logLastMessages[level] := message
        return false  ; Allow logging the first occurrence
    }
}

_ActuallyLogMessage(message, level, logCategory := "") {
    global scriptName, debugMode, LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_CRITICAL, logMinLevel, logBasePath
    
    ; Determine level name for log entry
    levelName := "INFO"
    if (level == LOG_DEBUG)
        levelName := "DEBUG"
    else if (level == LOG_WARNING)
        levelName := "WARNING"
    else if (level == LOG_ERROR)
        levelName := "ERROR"
    else if (level == LOG_CRITICAL)
        levelName := "CRITICAL"
    
    ; Determine log file based on category and level
    logFile := ""
    if (logCategory != "") {
        ; Use specific category for the log file
        logFile := logBasePath . logCategory . ".txt"
    }
    else if (level >= LOG_ERROR) {
        ; Errors go by default to Errors.txt
        logFile := logBasePath . "Errors.txt"
    }
    else {
        ; Default logs go to Logs{scriptName}.txt
        logFile := logBasePath . "Logs" . scriptName . ".txt"
    }
    
    ; Format the log entry with timestamp, level, and message
    FormatTime, readableTime, %A_Now%, yyyy-MM-dd HH:mm:ss
    logEntry := % "[" readableTime "][" levelName "][" scriptName "] " message
    
    ; Write to log file
    FileAppend, % logEntry "`n", %logFile%
    
}

; Main logging function
Log(message, level := 20, logCategory := "") {
    global scriptName, debugMode, LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_CRITICAL, logMinLevel, logBasePath
    global logThrottleCount
    
    ; Skip logging if below minimum level
    if (level < logMinLevel)
        return
    
    ; Check if this message should be throttled
    if (ShouldThrottleMessage(message, level))
        return
    
    ; Log the message using our helper function
    _ActuallyLogMessage(message, level, logCategory)
}



; Convenience functions for different log levels
LogDebug(message, logCategory := "") {
    Log(message, LOG_DEBUG, logCategory)
}

LogInfo(message, logCategory := "") {
    Log(message, LOG_INFO, logCategory)
}

LogWarning(message, logCategory := "") {
    Log(message, LOG_WARNING, logCategory)
}

LogError(message, logCategory := "") {
    Log(message, LOG_ERROR, logCategory)
}

LogCritical(message, logCategory := "") {
    global discordWebhookURL, discordUserId
    
    Log(message, LOG_CRITICAL, logCategory)
    
    ; Automatically send critical errors to Discord
    if (discordWebhookURL != "")
        LogToDiscord("CRITICAL ERROR: " . message, , discordUserId)
}

; Category-specific convenience functions
LogGP(message, level := 20) {
    Log(message, level, "GPlog")
}

LogRestart(message, level := 20) {
    Log(message, level, "Restart")
}

LogGPTest(message, level := 20) {
    Log(message, level, "GPTestLog")
}

FlushLogMessages() {
    global logLastMessages, logMessageCounter
    
    ; Log last occurrence of each throttled message
    for level, message in logLastMessages {
        key := level . ":" . message
        if (logMessageCounter.HasKey(key) && logMessageCounter[key] > 1) {
            ; Log the last occurrence with count
            _ActuallyLogMessage(message . " (repeated " . logMessageCounter[key] . " times)", level)
        }
    }
    
    ; Clear the records
    logLastMessages := {}
    logMessageCounter := {}
    logMessageFirstTime := {}
}