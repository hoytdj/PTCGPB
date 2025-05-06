;====================================================================
; FRIEND MANAGEMENT MODULE
; Functions for managing friend lists and interactions
;====================================================================

; RemoveFriends - Removes friends from the friends list
; Parameters:
;   filterByPreference - Boolean, if true, only remove friends who don't want the found card type
RemoveFriends(filterByPreference := false) {
	LogInfo("RemoveFriends called with filterByPreference: " . filterByPreference)
	global friendIDs, stopToggle, friended, foundLabel, openPack, rawFriendIDs
	
	; Early exit conditions
	if (filterByPreference && !friendIDs) {
		CreateStatusMessage("No friends to filter - friendIDs is empty")
		LogDebug("No friends to filter - friendIDs is empty")
		friended := false
		return
	}
	
	; God pack handling
    if (foundLabel = "God Pack") {
        CreateStatusMessage("Found God Pack")
        LogGP("Found God Pack")
        friended := false
        return
    }
    
    ; Friend removal logic
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbClick(143, 518)
		if(FindOrLoseImage(120, 500, 155, 530, , "Social", 0, failSafeTime))
			break
		else if(FindOrLoseImage(175, 165, 255, 235, , "Hourglass3", 0)) {
			Delay(3)
			adbClick(146, 441) ; 146 440
			Delay(3)
			adbClick(146, 441)
			Delay(3)
			adbClick(146, 441)
			Delay(3)

			FindImageAndClick(98, 184, 151, 224, , "Hourglass1", 168, 438, 500, 5) ;stop at hourglasses tutorial 2
			Delay(1)

			adbClick(203, 436) ; 203 436
		}
		Sleep, 500
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Social. ")
	}
	FindImageAndClick(226, 100, 270, 135, , "Add", 38, 460, 500)
	FindImageAndClick(205, 430, 255, 475, , "Search", 240, 120, 1500)
	FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
	
    ; Use the global rawFriendIDs variable instead of reading the file again
    filteredIDs := []
    
    if (filterByPreference && foundLabel) {
        ; Loop through each friend ID
        for index, id in friendIDs {
            shouldKeep := false
            
            ; Find this ID in the raw friends data
            for _, line in rawFriendIDs {
                if (InStr(line, id)) {
                    ; Check if this ID has no pipe character (no preferences)
                    if (!InStr(line, "|")) {
                        shouldKeep := true
                        LogDebug("Keeping friend " . id . " (no preferences specified)")
                        break
                    }
                    
                    ; Extract the preferences part
                    parts := StrSplit(line, "|", " ")
                    if (parts.MaxIndex() >= 2) {
                        preferences := Trim(parts[2])
                        
                        ; If preferences is "No preferences", always keep the friend
                        if (InStr(preferences, "No preferences")) {
                            shouldKeep := true
                            LogDebug("Keeping friend " . id . " (no preferences specified)")
                            break
                        }
                        
                        ; Look for the current openPack in the preferences
                        boosters := StrSplit(preferences, ";", " ")
                        for _, boosterData in boosters {
                            boosterInfo := StrSplit(boosterData, ":", " ")
                            boosterName := Trim(boosterInfo[1])
                            
                            ; If this is the current booster
                            if (boosterName = openPack) {
                                ; Check if the found card type is in the preferences
                                boosterPrefs := Trim(boosterInfo[2])
                                prefList := StrSplit(boosterPrefs, ",", " ")
                                
                                for _, pref in prefList {
                                    if (Trim(pref) = foundLabel) {
                                        shouldKeep := true
                                        LogDebug("Keeping friend " . id . " (wants " . foundLabel . " in " . openPack . ")")
                                        break
                                    }
                                }
                                
                                ; No need to check other boosters
                                break
                            }
                        }
                    }
                    
                    ; Found the line for this ID, no need to check other lines
                    break
                }
            }
            
            ; If we shouldn't keep this friend, add to filtered list for removal
            if (!shouldKeep) {
                filteredIDs.Push(id)
                LogDebug("Will remove friend " . id . " (doesn't want " . foundLabel . " in " . openPack . ")")
            }
        }
    } else {
        ; If not filtering by preference, remove all friends
        filteredIDs := friendIDs
    }

	 ; Process filtered IDs for removal
	for index, value in filteredIDs {
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			adbInput(value)
			Delay(1)
			if(FindOrLoseImage(205, 430, 255, 475, , "Search", 0, failSafeTime)) {
				FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
				EraseInput()
			} else if(FindOrLoseImage(205, 430, 255, 475, , "Search2", 0, failSafeTime)) {
				break
			}
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for RemoveFriends-1. ")
		}
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			adbClick(232, 453)
			if(FindOrLoseImage(165, 250, 190, 275, , "Send", 0, failSafeTime)) {
				break
			} else if(FindOrLoseImage(165, 250, 190, 275, , "Accepted", 0, failSafeTime)) {
				FindImageAndClick(135, 355, 160, 385, , "Remove", 193, 258, 500)
				FindImageAndClick(165, 250, 190, 275, , "Send", 200, 372, 2000)
				break
			} else if(FindOrLoseImage(165, 240, 255, 270, , "Withdraw", 0, failSafeTime)) {
				FindImageAndClick(165, 250, 190, 275, , "Send", 243, 258, 2000)
				break
			}
			Sleep, 750
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for RemoveFriends-2. ")
		}
		
		if(index != filteredIDs.maxIndex()) {
			FindImageAndClick(205, 430, 255, 475, , "Search2", 150, 50, 1500)
			FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
			EraseInput(index, filteredIDs.MaxIndex())
		}
	}
	
	if(stopToggle) {
		IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
		ExitApp
	}
	LogInfo("Removed " . filteredIDs.MaxIndex() . " friends")
	friended := false
}

; AddFriends - Adds friends from IDs file or single friend ID
; Parameters:
;   renew - Boolean, if true, renews friend requests
;   getFC - Boolean, if true, gets the friend code instead of adding friends
; Returns: Number of friends added or friend code
AddFriends(renew := false, getFC := false) {
	global FriendID, friendIds, waitTime, friendCode, scriptName
	IniWrite, 1, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
	LogInfo("AddFriends called with renew: " . renew . ", getFC: " . getFC)
    ; Skip processing IDs if we're just getting the friend code
    if (!getFC) {
        ; Modify the reading of IDs to store in global variable
        rawFriendIDs := ReadFile("ids")
        friendIDs := [] ; Initialize an empty array to store friend IDs
        
        if (rawFriendIDs) {
            LogDebug("Found " . rawFriendIDs.MaxIndex() . " lines in ids.txt")
            CreateStatusMessage("Checking for IDs in ids.txt")
            LogDebug("Checking for IDs in ids.txt")

            for index, value in rawFriendIDs {
                ; Skip empty lines
                if (value = "") {
                    continue
                }
                
                LogDebug("Processing line: " . value)
                
                ; Extract the ID part (everything before | or the whole line if no |)
                if (InStr(value, "|")) {
                    parts := StrSplit(value, "|", " ")
                    id := Trim(parts[1])
                    
                    ; If the ID is not valid (not 16 digits), skip it
                    if (StrLen(id) != 16) {
                        LogWarning("ID " . id . " is invalid (wrong length)")
                        continue
                    }
                    
                    preferences := Trim(parts[2])
                    
                    ; Only filter by preferences if role filtering is enabled
                    if (applyRoleFilters) {
                        ; If preferences is "No preferences", always add the ID
                        if (InStr(preferences, "No preferences")) {
                            friendIDs.Push(id)
                            LogDebug("ADDING: " . id . " (no preferences specified)")
                            continue
                        }
                        
                        boosters := StrSplit(preferences, ";", " ")
                        
                        ; Check if the current openPack is in the boosters list
                        hasCurrentBooster := false
                        for _, boosterData in boosters {
                            if (InStr(boosterData, openPack . ":")) {
                                hasCurrentBooster := true
                                break
                            }
                        }
                        
                        if (hasCurrentBooster) {
                            friendIDs.Push(id)
                            LogDebug("ADDING: " . id . " wants the booster " . openPack)
                        } else {
                            LogDebug("SKIPPING: " . id . " doesn't want booster " . openPack)
                        }
                    } else {
                        ; If role filtering is disabled, add all IDs
                        friendIDs.Push(id)
                        LogDebug("ADDING: " . id . " (role filtering disabled)")
                    }
                } else {
                    id := RegExReplace(value, "[^a-zA-Z0-9]")
                    ; If there is no pipe character, check if it's a valid ID (length = 16)
                    if (StrLen(id) = 16) {
                        ; If no preferences are specified, add the ID (it accepts all boosters)
                        friendIDs.Push(id)
                        LogDebug("ADDING: " . id . " (no preferences specified)")
                    } else {
                        LogWarning("SKIPPING: " . id . " is invalid (wrong length)")
                    }
                }
            }
        }
        
        ; Handle single FriendID, rather than ids.txt file
        if (friendIDs.MaxIndex() = "" && FriendID != "") {
            friendIDs.Push(FriendID)
        }
        
        LogInfo("Final list contains " . friendIDs.MaxIndex() . " friends")
    }
	
	count := 0
	friended := true
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		if(count > waitTime) {
			break
		}
		if(count = 0) {
			failSafe := A_TickCount
			failSafeTime := 0
			Loop {
				adbClick(143, 518)
				Delay(1)
				if(FindOrLoseImage(120, 500, 155, 530, , "Social", 0, failSafeTime)) {
					break
				}
				else if(!renew && !getFC) {
					clickButton := FindOrLoseImage(75, 340, 195, 530, 80, "Button", 0)
					if(clickButton) {
						StringSplit, pos, clickButton, `,  ; Split at ", "
						if (scaleParam = 287) {
							pos2 += 5
						}
						adbClick(pos1, pos2)
					}
				}
				else if(FindOrLoseImage(175, 165, 255, 235, , "Hourglass3", 0)) {
					Delay(3)
					adbClick(146, 441) ; 146 440
					Delay(3)
					adbClick(146, 441)
					Delay(3)
					adbClick(146, 441)
					Delay(3)

                    FindImageAndClick(98, 184, 151, 224, , "Hourglass1", 168, 438, 500, 5) ;stop at hourglasses tutorial 2
                    Delay(1)

					adbClick(203, 436) ; 203 436
				}
				failSafeTime := (A_TickCount - failSafe) // 1000
				LogDebug("In failsafe for Social. ")
			}
			FindImageAndClick(226, 100, 270, 135, , "Add", 38, 460, 500)
			FindImageAndClick(205, 430, 255, 475, , "Search", 240, 120, 1500)
			if(getFC) {
				Delay(3)
				adbClick(210, 342)
				Delay(3)
				friendCode := Clipboard
				return friendCode
			}
			FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
			;randomize friend id list to not back up mains if running in groups since they'll be sent in a random order.
			n := friendIDs.MaxIndex()
			Loop % n
			{
				i := n - A_Index + 1
				Random, j, 1, %i%
				; Force string assignment with quotes
				temp := friendIDs[i] . ""  ; Concatenation ensures string type
				friendIDs[i] := friendIDs[j] . ""
				friendIDs[j] := temp . ""
			}
			for index, value in friendIDs {
				if (StrLen(value) != 16) {
					; Wrong id value
					continue
				}
				failSafe := A_TickCount
				failSafeTime := 0
				Loop {
					adbInput(value)
					Delay(1)
					if(FindOrLoseImage(205, 430, 255, 475, , "Search", 0, failSafeTime)) {
						FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
						EraseInput()
					} else if(FindOrLoseImage(205, 430, 255, 475, , "Search2", 0, failSafeTime)) {
						break
					}
					failSafeTime := (A_TickCount - failSafe) // 1000
					LogDebug("In failsafe for AddFriends3. ")
				}
				failSafe := A_TickCount
				failSafeTime := 0
				Loop {
					adbClick(232, 453)
					if(FindOrLoseImage(165, 250, 190, 275, , "Send", 0, failSafeTime)) {
						adbClick(243, 258)
						Delay(2)
						break
					}
					else if(FindOrLoseImage(165, 240, 255, 270, , "Withdraw", 0, failSafeTime)) {
						break
					}
					else if(FindOrLoseImage(165, 250, 190, 275, , "Accepted", 0, failSafeTime)) {
						if(renew){
							FindImageAndClick(135, 355, 160, 385, , "Remove", 193, 258, 500)
							FindImageAndClick(165, 250, 190, 275, , "Send", 200, 372, 500)
							Delay(2)
							adbClick(243, 258)
						}
						break
					}
					Sleep, 750
					failSafeTime := (A_TickCount - failSafe) // 1000
					LogDebug("In failsafe for AddFriends4. ")
				}
				if(index != friendIDs.maxIndex()) {
					FindImageAndClick(205, 430, 255, 475, , "Search2", 150, 50, 1500)
					FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
					EraseInput(index, n)
				}
			}
			FindImageAndClick(120, 500, 155, 530, , "Social", 143, 518, 500)
			FindImageAndClick(20, 500, 55, 530, , "Home", 40, 516, 500)
		}
		LogDebug("Waiting for friends to accept request. " . count . "/" . waitTime . " seconds.")
		sleep, 1000
		count++
	}
	LogInfo("Added " . n . " friends.")
	return n ;return added friends so we can dynamically update the .txt in the middle of a run without leaving friends at the end
}

; EraseInput - Clears input fields
; Parameters:
;   num - Current number in removal process
;   total - Total number to remove
EraseInput(num := 0, total := 0) {
	if(num)
		LogDebug("Removing friend ID " . num . "/" . total)
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		FindImageAndClick(0, 475, 25, 495, , "OK2", 138, 454)
	    adbClick(52, 512)
        Sleep, 10
	    adbClick(52, 512)
        Sleep, 10
        adbInputEvent("67")
		if(FindOrLoseImage(15, 500, 68, 520, , "Erase", 0, failSafeTime))
			break
	}
	failSafeTime := (A_TickCount - failSafe) // 1000
	LogDebug("In failsafe for Erase. ")
}

; getFriendCode - Gets the friend code
; No parameters
; Returns: Friend code string
getFriendCode() {
	global friendCode
	CreateStatusMessage("Getting friend code")
	LogInfo("Getting friend code")
	Sleep, 2000
	FindImageAndClick(233, 486, 272, 519, , "Skip", 146, 494) ;click on next until skip button appears
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		Delay(1)
		if(FindOrLoseImage(233, 486, 272, 519, , "Skip", 0, failSafeTime)) {
			adbClick(239, 497)
		} else if(FindOrLoseImage(120, 70, 150, 100, , "Next", 0, failSafeTime)) {
			adbClick(146, 494) ;146, 494
		} else if(FindOrLoseImage(120, 70, 150, 100, , "Next2", 0, failSafeTime)) {
			adbClick(146, 494) ;146, 494
		} else if(FindOrLoseImage(121, 465, 140, 485, , "ConfirmPack", 0, failSafeTime)) {
			break
		} else if(FindOrLoseImage(20, 500, 55, 530, , "Home", 0, failSafeTime)) {
			break
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Home. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at Home")
	}
	friendCode := AddFriends(false, true)

	return friendCode
}