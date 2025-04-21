;====================================================================
; PACK RECOGNITION MODULE
; Functions for detecting and handling packs and cards
;====================================================================

; CheckPack - Checks the current pack for special cards
; No parameters
CheckPack() {
	LogDebug("Checking pack...")
    ; Wait for cards to render before checking.
    Loop {
        if (FindBorders("lag") = 0)
            break
        Delay(1)
    }

    ; Update pack count.
    ; SquallTCGP 2025.03.12 - Just checking the packs count and setting them to 0 if it's number of packs is 3.
    ;                         This applies to any Delete Method except 5 Pack (Fast). This change is made based
    ;                         on the 5p-no delete community mod created by DietPepperPhD in the discord server.
    if (deleteMethod != "5 Pack (Fast)") {
        if (packs = 3)
            packs := 0
    }

    packs += 1
    if (packMethod)
        packs := 1

    ; Define a variable to contain whatever is found based on settings.
    foundLabel := false

    ; Before doing anything else, check if the current pack is valid.
    foundShiny := FindBorders("shiny2star") + FindBorders("shiny1star")
    foundCrown := FindBorders("crown")
    foundImmersive := FindBorders("immersive")
    foundInvalid := foundShiny + foundCrown + foundImmersive

    if (foundInvalid) {
        ; Pack is invalid...
        if (!InvalidCheck) {
            ; Check if the current pack could have been a god pack.
            foundInvalidGP := FindGodPack(true)
        } else {
            ; If required, check what cards the current pack contains which make it invalid.
            if (ShinyCheck && foundShiny && !foundLabel)
                foundLabel := "Shiny"
            if (ImmersiveCheck && foundImmersive && !foundLabel)
                foundLabel := "Immersive"
            if (CrownCheck && foundCrown && !foundLabel)
                foundLabel := "Crown"

            ; Report invalid cards found.
            if (foundLabel) {
                FoundStars(foundLabel)
                restartGameInstance(foundLabel . " found. Continuing...", "GodPack")
				LogRestart("Restarted game, reason: " . foundLabel . " found")
			} else {
				; If no invalid cards were found, check if the pack is a god pack.
				foundInvalidGP := FindGodPack(true)
            }
        }

        IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck

        return
    }

    ; Check for god pack.
    foundGP := FindGodPack()

    if (foundGP) {
        if (loadedAccount) {
            FileDelete, %loadedAccount%
            IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
        }

        restartGameInstance("God Pack found. Continuing...", "GodPack")
		LogRestart("Restarted game, reason: God Pack found")
        return
    }
    if (!CheckShiningPackOnly || openPack = "Shining") {
        ; Check for 2-star cards.
        foundTrainer := (MockSinglePack == "Trainer")
        foundRainbow := (MockSinglePack == "Rainbow")
        foundFullArt := (MockSinglePack == "Full Art")
        2starCount := (MockSinglePack == "Double two star") ? 2 : 0

        if (MockSinglePack)
            foundLabel := MockSinglePack

        if (TrainerCheck && !foundLabel) {
            foundTrainer := FindBorders("trainer")
            if (foundTrainer)
                foundLabel := "Trainer"
        }
        if (RainbowCheck && !foundLabel) {
            foundRainbow := FindBorders("rainbow")
            if (foundRainbow)
                foundLabel := "Rainbow"
        }
        if (FullArtCheck && !foundLabel) {
            foundFullArt := FindBorders("fullart")
            if (foundFullArt)
                foundLabel := "Full Art"
        }
        if (PseudoGodPack && !foundLabel) {
            2starCount := FindBorders("trainer") + FindBorders("rainbow") + FindBorders("fullart")
            if (2starCount > 1)
                foundLabel := "Double two star"
        }

        if (foundLabel) {
            if (loadedAccount) {
                FileDelete, %loadedAccount% ;delete xml file from folder if using inject method
                IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
            }

            FoundStars(foundLabel)
            restartGameInstance(foundLabel . " found. Continuing...", "GodPack")
            LogRestart("Restarted game, reason: " . foundLabel . " found")
        }
    }
    ; Check for tradeable cards.
    if (s4tEnabled) {
        found3Dmnd := 0
        found4Dmnd := 0
        found1Star := 0
        foundGimmighoul := 0

        if (s4t3Dmnd) {
            found3Dmnd += FindBorders("3diamond")
        }
        if (s4t1Star) {
            found1Star += FindBorders("1star")
        }

        if (s4t4Dmnd) {
            ; Detecting a 4-diamond EX card isn't possible using a needle.
            ; Start with 5 and substract other card types as efficiently as possible.
            found4Dmnd := 5 - FindBorders("normal")

            if (found4Dmnd > 0) {
                if (s4t3Dmnd)
                    found4Dmnd -= found3Dmnd
                else
                    found4Dmnd -= FindBorders("3diamond")
            }
            if (found4Dmnd > 0) {
                if (s4t1Star)
                    found4Dmnd -= found1Star
                else
                    found4Dmnd -= FindBorders("1star")
            }

            if (found4Dmnd > 0 && PseudoGodPack) {
                found4Dmnd -= 2starCount
            } else {
                if (found4Dmnd > 0) {
                    if (TrainerCheck)
                        found4Dmnd -= foundTrainer
                    else
                        found4Dmnd -= FindBorders("trainer")
                }
                if (found4Dmnd > 0) {
                    if (RainbowCheck)
                        found4Dmnd -= foundRainbow
                    else
                        found4Dmnd -= FindBorders("rainbow")
                }
                if (found4Dmnd > 0) {
                    if (FullArtCheck)
                        found4Dmnd -= foundFullArt
                    else
                        found4Dmnd -= FindBorders("fullart")
                }
            }
        }

        if (s4tGholdengo && openPack = "Shining") {
            foundGimmighoul += FindCard("gimmighoul")
        }

        foundTradeable := found3Dmnd + found4Dmnd + found1Star + foundGimmighoul

        if (foundTradeable > 0)
            FoundTradeable(found3Dmnd, found4Dmnd, found1Star, foundGimmighoul)
    }
}

; FoundTradeable - Handles when tradeable cards are found
; Parameters:
;   found3Dmnd - Number of 3-diamond cards found
;   found4Dmnd - Number of 4-diamond cards found
;   found1Star - Number of 1-star cards found
;   foundGimmighoul - Number of Gimmighoul cards found
FoundTradeable(found3Dmnd := 0, found4Dmnd := 0, found1Star := 0, foundGimmighoul := 0) {
    ; Not dead.
    IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck

    ; Keep account.
    keepAccount := true

    foundTradeable := found3Dmnd + found4Dmnd + found1Star + foundGimmighoul

    packDetailsFile := ""
    packDetailsMessage := ""

    if (found3Dmnd > 0) {
        packDetailsFile .= "3DmndX" . found3Dmnd . "_"
        packDetailsMessage .= "Three Diamond (x" . found3Dmnd . "), "
    }
    if (found4Dmnd > 0) {
        packDetailsFile .= "4DmndX" . found4Dmnd . "_"
        packDetailsMessage .= "Four Diamond EX (x" . found4Dmnd . "), "
    }
    if (found1Star > 0) {
        packDetailsFile .= "1StarX" . found1Star . "_"
        packDetailsMessage .= "One Star (x" . found1Star . "), "
    }
    if (foundGimmighoul > 0) {
        packDetailsFile .= "GimmighoulX" . foundGimmighoul . "_"
        packDetailsMessage .= "Gimmighoul (x" . foundGimmighoul . "), "
    }

    packDetailsFile := RTrim(packDetailsFile, "_")
    packDetailsMessage := RTrim(packDetailsMessage, ", ")

    accountFullPath := ""
    accountFile := saveAccount("Tradeable", accountFullPath, packDetailsFile)
    screenShot := Screenshot("Tradeable", "Trades", screenShotFileName)

    statusMessage := "Tradeable cards found"
    if (username)
        statusMessage .= " by " . username

    if (!s4tWP || (s4tWP && foundTradeable < s4tWPMinCards)) {
        CreateStatusMessage("Tradeable cards found! Continuing...")
		LogDebug("Tradeable cards found! Continuing...")

        logMessage := statusMessage . " in instance: " . scriptName . " (" . packs . " packs, " . openPack . ") File name: " . accountFile . " Screenshot file: " . screenShotFileName . " Backing up to the Accounts\\Trades folder and continuing..."
        LogTrade( . packs . " packs, " . openPack . ") File name: " . accountFile . " Screenshot file: " . screenShotFileName . " Backing up to the Accounts\\Trades folder and continuing...")

        if (!s4tSilent && s4tDiscordWebhookURL) {
            discordMessage := statusMessage . " in instance: " . scriptName . " (" . packs . " packs, " . openPack . ")\nFound: " . packDetailsMessage . "\nFile name: " . accountFile . "\nBacking up to the Accounts\\Trades folder and continuing..."
            LogToDiscord(discordMessage, screenShot, true, (s4tSendAccountXml ? accountFullPath : ""),, s4tDiscordWebhookURL, s4tDiscordUserId)
        }

        return
    }

    friendCode := getFriendCode()

    Sleep, 8000
    fcScreenshot := Screenshot("FRIENDCODE", "Trades")

    ; If we're doing the inject method, try to OCR our Username
    try {
        if (injectMethod && IsFunc("ocr")) {
            ocrText := Func("ocr").Call(fcScreenshot, ocrLanguage)
            ocrLines := StrSplit(ocrText, "`n")
            len := ocrLines.MaxIndex()
            if(len > 1) {
                playerName := ocrLines[1]
                playerID := RegExReplace(ocrLines[2], "[^0-9]", "")
                ; playerID := SubStr(ocrLines[2], 1, 19)
                username := playerName
            }
        }
    } catch e {
        LogError("Failed to OCR the friend code: " . e.message)
    }

    statusMessage := "Tradeable cards found"
    if (username)
        statusMessage .= " by " . username
    if (friendCode)
        statusMessage .= " (" . friendCode . ")"

    logMessage := statusMessage . " in instance: " . scriptName . " (" . packs . " packs, " . openPack . ")\nFile name: " . accountFile . "\nScreenshot file: " . screenShotFileName . "\nBacking up to the Accounts\\Trades folder and continuing..."
    LogTrade( . packs . " packs, " . openPack . ")\nFile name: " . accountFile . "\nScreenshot file: " . screenShotFileName . "\nBacking up to the Accounts\\Trades folder and continuing...")

    if (s4tDiscordWebhookURL) {
        discordMessage := statusMessage . " in instance: " . scriptName . " (" . packs . " packs, " . openPack . ")\nFound: " . packDetailsMessage . "\nFile name: " . accountFile . "\nBacking up to the Accounts\\Trades folder and continuing..."
        LogToDiscord(discordMessage, screenShot, true, (s4tSendAccountXml ? accountFullPath : ""), fcScreenshot, s4tDiscordWebhookURL, s4tDiscordUserId)
    }

    restartGameInstance("Tradeable cards found. Continuing...", "GodPack")
	LogRestart("Restarted game, reason: Tradeable cards found")
	return
}

; FoundStars - Handles when special cards are found
; Parameters:
;   star - Type of special card found
FoundStars(star) {
	LogInfo("Found " . star)
    global scriptName, DeadCheck, ocrLanguage, injectMethod, openPack

    ; Not dead.
    IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck

    ; Keep account.
    keepAccount := true

    screenShot := Screenshot(star)
    accountFullPath := ""
    accountFile := saveAccount(star, accountFullPath)
    friendCode := getFriendCode()

    ; Pull back screenshot of the friend code/name (good for inject method)
    Sleep, 8000
    fcScreenshot := Screenshot("FRIENDCODE")

	if(star = "Crown" || star = "Immersive" || star = "Shiny")
		RemoveFriends()
	else {
		; If we're doing the inject method, try to OCR our Username
		try {
			if(injectMethod && IsFunc("ocr"))
			{
					ocrText := Func("ocr").Call(fcScreenshot, ocrLanguage)
					ocrLines := StrSplit(ocrText, "`n")
					len := ocrLines.MaxIndex()
					if(len > 1) {
						playerName := ocrLines[1]
						playerID := RegExReplace(ocrLines[2], "[^0-9]", "")
						; playerID := SubStr(ocrLines[2], 1, 19)
						username := playerName
					}
			}
		} catch e {
			LogError("Failed to OCR the friend code: " . e.message)
		}
	}

    CreateStatusMessage(star . " found!")
    LogInfo(star . " found!")

    statusMessage := star . " found"
    if (username)
        statusMessage .= " by " . username
    if (friendCode)
        statusMessage .= " (" . friendCode . ")"

    logMessage := statusMessage . " in instance: " . scriptName . " (" . packs . " packs, " . openPack . ")\nFile name: " . accountFile . "\nBacking up to the Accounts\\SpecificCards folder and continuing..."
    LogToDiscord(logMessage, screenShot, true, (sendAccountXml ? accountFullPath : ""), fcScreenshot)
    LogGP(star . " found :(" . packs . " packs, " . openPack . ") File name: " . accountFile)
	
	if(star != "Crown" && star != "Immersive" && star != "Shiny") {
		ChooseTag()
		; Use the filtered removal function
		if (applyRoleFilters)
			RemoveFriends(true)
	}
}

; FindBorders - Finds card borders of specific types
; Parameters:
;   prefix - Type of border to find
; Returns: Count of borders found
FindBorders(prefix) {
    count := 0
    searchVariation := 40
    borderCoords := [[30, 284, 83, 286]
        ,[113, 284, 166, 286]
        ,[196, 284, 249, 286]
        ,[70, 399, 123, 401]
        ,[155, 399, 208, 401]]
    if (prefix = "shiny1star" || prefix = "shiny2star") {
        ; TODO: Need references images for these coordinates (right side, bottom corner)
        borderCoords := [[90, 261, 93, 283]
        ,[173, 261, 176, 283]
        ,[255, 261, 258, 283]
        ,[130, 376, 133, 398]
        ,[215, 376, 218, 398]]
    }
    ; 100% scale changes
    if (scaleParam = 287) {
        if (prefix = "shiny1star" || prefix = "shiny2star") {
            borderCoords := [[91, 253, 95, 278]
            ,[175, 253, 179, 278]
            ,[259, 253, 263, 278]
            ,[132, 370, 136, 395]
            ,[218, 371, 222, 394]]
        } else {
            borderCoords := [[26, 278, 84, 280]
            ,[110, 278, 168, 280]
            ,[194, 278, 252, 280]
            ,[67, 395, 125, 397]
            ,[153, 395, 211, 397]]
        }
    }
    pBitmap := from_window(WinExist(winTitle))
    ; imagePath := "C:\Users\Arturo\Desktop\PTCGP\GPs\" . Clipboard . ".png"
    ; pBitmap := Gdip_CreateBitmapFromFile(imagePath)
    for index, value in borderCoords {
        coords := borderCoords[A_Index]
        Path = %A_ScriptDir%\%defaultLanguage%\%prefix%%A_Index%.png
        if (FileExist(Path)) {
            pNeedle := GetNeedle(Path)
            vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, coords[1], coords[2], coords[3], coords[4], searchVariation)
            if (vRet = 1) {
                count += 1
            }
        }
    }
    Gdip_DisposeImage(pBitmap)
    return count
}

; FindCard - Finds specific cards
; Parameters:
;   prefix - Type of card to find
; Returns: Count of cards found
FindCard(prefix) {
    count := 0
    searchVariation := 40
    borderCoords := [[23, 191, 76, 193]
        ,[106, 191, 159, 193]
        ,[189, 191, 242, 193]
        ,[63, 306, 116, 308]
        ,[146, 306, 199, 308]]
    ; 100% scale changes
    if (scaleParam = 287) {
        borderCoords := [[23, 184, 81, 186]
            ,[107, 184, 165, 186]
            ,[191, 184, 249, 186]
            ,[64, 301, 122, 303]
            ,[148, 301, 206, 303]]
    }
    pBitmap := from_window(WinExist(winTitle))
    for index, value in borderCoords {
        coords := borderCoords[A_Index]
        Path = %A_ScriptDir%\%defaultLanguage%\%prefix%%A_Index%.png
        if (FileExist(Path)) {
            pNeedle := GetNeedle(Path)
            vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, coords[1], coords[2], coords[3], coords[4], searchVariation)
            if (vRet = 1) {
                count += 1
            }
        }
    }
    Gdip_DisposeImage(pBitmap)
    return count
}

; FindGodPack - Checks if current pack is a god pack
; Parameters:
;   invalidPack - If true, checks for invalid god packs
; Returns: Boolean indicating if a god pack was found
FindGodPack(invalidPack := false) {
	LogInfo("Finding God Pack")
    ; Check for normal borders.
    normalBorders := MockGodPack ? 0 : FindBorders("normal")
    if (normalBorders) {
        CreateStatusMessage("Not a God Pack...")
		LogInfo("Not a God Pack...")
        ; Clear bitmap cache after checks
        ClearBitmapCache()
        return false
    }

    ; A god pack (although possibly invalid) has been found.
    keepAccount := true

    ; Count stars if required.
    packMinStars := minStars
    if (openPack = "Shining") {
        packMinStars := minStarsA2b
    } else if (openPack = "Arceus") {
        packMinStars := minStarsA2a
    } else if (openPack = "Palkia") {
        packMinStars := minStarsA2Palkia
    } else if (openPack = "Dialga") {
        packMinStars := minStarsA2Dialga
    } else if (openPack = "Mew") {
        packMinStars := minStarsA1a
    } else if (openPack = "Pikachu") {
        packMinStars := minStarsA1Pikachu
    } else if (openPack = "Charizard") {
        packMinStars := minStarsA1Charizard
    } else if (openPack = "Mewtwo") {
        packMinStars := minStarsA1Mewtwo
    }

    if (!invalidPack && packMinStars > 0) {
        starCount := MockGodPack ? 5 : (5 - FindBorders("1star"))
        if (starCount < packMinStars) {
            CreateStatusMessage("Pack doesn't contain enough 2 stars...")
			LogInfo("Pack doesn't contain enough 2 stars...")
            invalidPack := true
        }
    }

    if (invalidPack) {
        GodPackFound("Invalid")

        RemoveFriends()
        IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
    } else {
        GodPackFound("Valid")
    }

    return keepAccount
}

; GodPackFound - Handles when a god pack is found
; Parameters:
;   validity - "Valid" or "Invalid"
GodPackFound(validity) {
	; Flush any pending log messages before reporting a God Pack
	FlushLogMessages()
	LogInfo("God Pack found ")
	global scriptName, DeadCheck, ocrLanguage, injectMethod, openPack, gpFoundTime
	; Set the timestamp of when we found the God Pack
	gpFoundTime := A_TickCount

	if(validity = "Valid") {
		IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
		Praise := ["Congrats!", "Congratulations!", "GG!", "Whoa!", "Praise Helix! ༼ つ ◕_◕ ༽つ", "Way to go!", "You did it!", "Awesome!", "Nice!", "Cool!", "You deserve it!", "Keep going!", "This one has to be live!", "No duds, no duds, no duds!", "Fantastic!", "Bravo!", "Excellent work!", "Impressive!", "You're amazing!", "Well done!", "You're crushing it!", "Keep up the great work!", "You're unstoppable!", "Exceptional!", "You nailed it!", "Hats off to you!", "Sweet!", "Kudos!", "Phenomenal!", "Boom! Nailed it!", "Marvelous!", "Outstanding!", "Legendary!", "Youre a rock star!", "Unbelievable!", "Keep shining!", "Way to crush it!", "You're on fire!", "Killing it!", "Top-notch!", "Superb!", "Epic!", "Cheers to you!", "Thats the spirit!", "Magnificent!", "Youre a natural!", "Gold star for you!", "You crushed it!", "Incredible!", "Shazam!", "You're a genius!", "Top-tier effort!", "This is your moment!", "Powerful stuff!", "Wicked awesome!", "Props to you!", "Big win!", "Yesss!", "Champion vibes!", "Spectacular!"]
		invalid := ""
	} else {
		Praise := ["Uh-oh!", "Oops!", "Not quite!", "Better luck next time!", "Yikes!", "That didn’t go as planned.", "Try again!", "Almost had it!", "Not your best effort.", "Keep practicing!", "Oh no!", "Close, but no cigar.", "You missed it!", "Needs work!", "Back to the drawing board!", "Whoops!", "That’s rough!", "Don’t give up!", "Ouch!", "Swing and a miss!", "Room for improvement!", "Could be better.", "Not this time.", "Try harder!", "Missed the mark.", "Keep at it!", "Bummer!", "That’s unfortunate.", "So close!", "Gotta do better!"]
		invalid := validity
	}
    Randmax := Praise.Length()
    Random, rand, 1, Randmax
    Interjection := Praise[rand]
    starCount := 5 - FindBorders("1star") - FindBorders("shiny1star")
    screenShot := Screenshot(validity)
    accountFullPath := ""
    accountFile := saveAccount(validity, accountFullPath)
    friendCode := getFriendCode()

    ; Pull screenshot of the Friend code page; wait so we don't get the clipboard pop up; good for the inject method
    Sleep, 8000
    fcScreenshot := Screenshot("FRIENDCODE")

	; If we're doing the inject method, try to OCR our Username
	try {
		if(injectMethod && IsFunc("ocr"))
		{
				ocrText := Func("ocr").Call(fcScreenshot, ocrLanguage)
				ocrLines := StrSplit(ocrText, "`n")
				len := ocrLines.MaxIndex()
				if(len > 1) {
					playerName := ocrLines[1]
					playerID := RegExReplace(ocrLines[2], "[^0-9]", "")
					; playerID := SubStr(ocrLines[2], 1, 19)
					username := playerName
				}
		}
	} catch e {
		LogError("Failed to OCR the friend code: " . e.message)
	}

	logMessage := Interjection . "\n" . username . " (" . friendCode . ")\n[" . starCount . "/5][" . packs . "P][" . openPack . " Booster] " . invalid . " God pack found in instance: " . scriptName . "\nFile name: " . accountFile . "\nBacking up to the Accounts\\GodPacks folder and continuing..."
	LogGP(username . "[" . starCount . "/5][" . packs . "P] " . invalid . " God pack found, File name: " . accountFile . "Backing up to the Accounts\\GodPacks folder and continuing...")
	;Run, http://google.com, , Hide ;Remove the ; at the start of the line and replace your url if you want to trigger a link when finding a god pack.

    ; Adjust the below to only send a 'ping' to Discord friends on Valid packs
    if (validity = "Valid") {
        LogToDiscord(logMessage, screenShot, true, (sendAccountXml ? accountFullPath : ""), fcScreenshot)
        LogDiscord("Sended a message to Discord")
        ChooseTag()
    } else if (!InvalidCheck) {
        LogToDiscord(logMessage, screenShot, true, (sendAccountXml ? accountFullPath : ""), fcScreenshot)
        LogDiscord("Sended a message to Discord")
    }
}