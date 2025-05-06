;====================================================================
; GAME FLOW MODULE
; Functions for managing game flow and processes
;====================================================================

; DoTutorial - Completes the tutorial flow
; No parameters
; Returns: Boolean indicating success
DoTutorial() {
	LogInfo("Starting tutorial...")
	FindImageAndClick(105, 396, 121, 406, , "Country", 143, 370) ;select month and year and click

    Delay(1)
    adbClick(80, 400)
    Delay(1)
    adbClick(80, 375)
    Delay(1)
    failSafe := A_TickCount
    failSafeTime := 0

	Loop
	{
		Delay(1)
		if(FindImageAndClick(100, 386, 138, 416, , "Month", , , , 1, failSafeTime))
			break
		Delay(1)
		adbClick(142, 159)
		Delay(1)
		adbClick(80, 400)
		Delay(1)
		adbClick(80, 375)
		Delay(1)
		adbClick(82, 422)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Month. ")
	} ;select month and year and click

	adbClick(200, 400)
	Delay(1)
	adbClick(200, 375)
	Delay(1)
	failSafe := A_TickCount
	failSafeTime := 0
	Loop ;select month and year and click
	{
		Delay(1)
		if(FindImageAndClick(148, 384, 256, 419, , "Year", , , , 1, failSafeTime))
			break
		Delay(1)
		adbClick(142, 159)
		Delay(1)
		adbClick(142, 159)
		Delay(1)
		adbClick(200, 400)
		Delay(1)
		adbClick(200, 375)
		Delay(1)
		adbClick(142, 159)
		Delay(1)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Year. ")
	} ;select month and year and click

	Delay(1)
	if(FindOrLoseImage(93, 471, 122, 485, , "CountrySelect", 0)) {
		FindImageAndClick(110, 134, 164, 160, , "CountrySelect2", 141, 237, 500)
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			countryOK := FindOrLoseImage(93, 450, 122, 470, , "CountrySelect", 0, failSafeTime)
			birthFound := FindOrLoseImage(116, 352, 138, 389, , "Birth", 0, failSafeTime)
			if(countryOK)
				adbClick(124, 250)
			else if(!birthFound)
					adbClick(140, 474)
			else if(birthFound)
				break
			Delay(2)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for country select. ")
		}
	} else {
		FindImageAndClick(116, 352, 138, 389, , "Birth", 140, 474, 1000)
	}

    ;wait date confirmation screen while clicking ok

    FindImageAndClick(210, 285, 250, 315, , "TosScreen", 203, 371, 1000) ;wait to be at the tos screen while confirming birth

    FindImageAndClick(129, 477, 156, 494, , "Tos", 139, 299, 1000) ;wait for tos while clicking it

    FindImageAndClick(210, 285, 250, 315, , "TosScreen", 142, 486, 1000) ;wait to be at the tos screen and click x

    FindImageAndClick(129, 477, 156, 494, , "Privacy", 142, 339, 1000) ;wait to be at the tos screen

    FindImageAndClick(210, 285, 250, 315, , "TosScreen", 142, 486, 1000) ;wait to be at the tos screen, click X

    Delay(1)
    adbClick(261, 374)

    Delay(1)
    adbClick(261, 406)

    Delay(1)
    adbClick(145, 484)

	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		if(FindImageAndClick(30, 336, 53, 370, , "Save", 145, 484, , 2, failSafeTime)) ;wait to be at create save data screen while clicking
			break
		Delay(1)
		adbClick(261, 406)
		if(FindImageAndClick(30, 336, 53, 370, , "Save", 145, 484, , 2, failSafeTime)) ;wait to be at create save data screen while clicking
			break
		Delay(1)
		adbClick(261, 374)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Save. ")
	}

    Delay(1)

    adbClick(143, 348)

    Delay(1)

	FindImageAndClick(51, 335, 107, 359, , "Link") ;wait for link account screen%
	Delay(1)
	failSafe := A_TickCount
	failSafeTime := 0
		Loop {
			if(FindOrLoseImage(51, 335, 107, 359, , "Link", 0, failSafeTime)) {
				adbClick(140, 460)
				Loop {
					Delay(1)
					if(FindOrLoseImage(51, 335, 107, 359, , "Link", 1, failSafeTime)) {
						adbClick(140, 380) ; click ok on the interrupted while opening pack prompt
						break
					}
					failSafeTime := (A_TickCount - failSafe) // 1000
				}
			} else if(FindOrLoseImage(110, 350, 150, 404, , "Confirm", 0, failSafeTime)) {
				adbClick(203, 364)
			} else if(FindOrLoseImage(215, 371, 264, 418, , "Complete", 0, failSafeTime)) {
				adbClick(140, 370)
			} else if(FindOrLoseImage(0, 46, 20, 70, , "Cinematic", 0, failSafeTime)) {
				break
			}
			LogDebug("Looking for Link/Welcome")
			Delay(1)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for Link/Welcome. ")
		}

        if(setSpeed = 3) {
            FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
            FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
            Delay(1)
            adbClick(41, 296)
            Delay(1)
        }

        FindImageAndClick(110, 230, 182, 257, , "Welcome", 253, 506, 110) ;click through cutscene until welcome page

        if(setSpeed = 3) {
            FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings

            FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
            Delay(1)
            adbClick(41, 296)
        }
    FindImageAndClick(190, 241, 225, 270, , "Name", 189, 438) ;wait for name input screen
    ;choose any
    Delay(1)
    if(FindOrLoseImage(147, 160, 157, 169, , "Erika", 1)) {
        AdbClick(143, 207)
        Delay(1)
        AdbClick(143, 207)
        FindImageAndClick(165, 294, 173, 301, , "ChooseErika", 143, 306)
        FindImageAndClick(190, 241, 225, 270, , "Name", 143, 462) ;wait for name input screen
    }
    FindImageAndClick(0, 476, 40, 502, , "OK", 139, 257) ;wait for name input screen

    failSafe := A_TickCount
    failSafeTime := 0
    Loop {
        fileName := A_ScriptDir . "\..\usernames.txt"
        if(FileExist(fileName))
            name := ReadFile("usernames")
        else
            name := ReadFile("usernames_default")

		Random, randomIndex, 1, name.MaxIndex()
		username := name[randomIndex]
		username := SubStr(username, 1, 14)  ;max character limit
		adbInput(username)
		Delay(1)
		if(FindImageAndClick(121, 490, 161, 520, , "Return", 185, 372, , 10)) ;click through until return button on open pack
			break
		adbClick(90, 370)
		Delay(1)
		adbClick(139, 254) ; 139 254 194 372
		Delay(1)
		adbClick(139, 254)
		Delay(1)
		EraseInput() ; incase the random pokemon is not accepted
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Trace. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at name")
			LogRestart("Stuck at name")
	}

    Delay(1)

    adbClick(140, 424)

    FindImageAndClick(225, 273, 235, 290, , "Pack", 140, 424) ;wait for pack to be ready  to trace
        if(setSpeed > 1) {
            FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
            FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
            Delay(1)
        }
    failSafe := A_TickCount
    failSafeTime := 0
    Loop {
        adbSwipe(adbSwipeParams)
        Sleep, 10
        if (FindOrLoseImage(225, 273, 235, 290, , "Pack", 1, failSafeTime)){
            if(setSpeed > 1) {
                if(setSpeed = 3)
                        FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
                else
                        FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
            }
            adbClick(41, 296)
                break
        }
        failSafeTime := (A_TickCount - failSafe) // 1000
        LogDebug("In failsafe for Trace. ")
    }

	FindImageAndClick(34, 99, 74, 131, , "Swipe", 140, 375) ;click through cards until needing to swipe up
		if(setSpeed > 1) {
			FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
			FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
			Delay(1)
		}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbSwipe("266 770 266 355 60")
		Sleep, 10
		if (FindOrLoseImage(120, 70, 150, 95, , "SwipeUp", 0, failSafeTime)){
			if(setSpeed > 1) {
				if(setSpeed = 3)
						FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
				else
						FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
			}
			adbClick(41, 296)
			break
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Swipe up. ")	
		Delay(1)
	}

    Delay(1)
    if(setSpeed > 2) {
        FindImageAndClick(136, 420, 151, 436, , "Move", 134, 375, 500) ; click through until move
        FindImageAndClick(50, 394, 86, 412, , "Proceed", 141, 483, 750) ;wait for menu to proceed then click ok. increased delay in between clicks to fix freezing on 3x speed
    }
    else {
        FindImageAndClick(136, 420, 151, 436, , "Move", 134, 375) ; click through until move
        FindImageAndClick(50, 394, 86, 412, , "Proceed", 141, 483) ;wait for menu to proceed then click ok
    }

    Delay(1)
    adbClick(204, 371)

    FindImageAndClick(46, 368, 103, 411, , "Gray") ;wait for for missions to be clickable

    Delay(1)
    adbClick(247, 472)

    FindImageAndClick(115, 97, 174, 150, , "Pokeball", 247, 472, 5000) ; click through missions until missions is open

    Delay(1)
    adbClick(141, 294)
    Delay(1)
    adbClick(141, 294)
    Delay(1)
    FindImageAndClick(124, 168, 162, 207, , "Register", 141, 294, 1000) ; wait for register screen
    Delay(6)
    adbClick(140, 500)

    FindImageAndClick(115, 255, 176, 308, , "Mission") ; wait for mission complete screen

    FindImageAndClick(46, 368, 103, 411, , "Gray", 143, 360) ;wait for for missions to be clickable

    FindImageAndClick(170, 160, 220, 200, , "Notifications", 145, 194) ;click on packs. stop at booster pack tutorial

    Delay(3)
    adbClick(142, 436)
    Delay(3)
    adbClick(142, 436)
    Delay(3)
    adbClick(142, 436)
    Delay(3)
    adbClick(142, 436)

    FindImageAndClick(225, 273, 235, 290, , "Pack", 239, 497) ;wait for pack to be ready  to Trace
        if(setSpeed > 1) {
            FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
            FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
            Delay(1)
        }
    failSafe := A_TickCount
    failSafeTime := 0
    Loop {
        adbSwipe(adbSwipeParams)
        Sleep, 10
        if (FindOrLoseImage(225, 273, 235, 290, , "Pack", 1, failSafeTime)){
        if(setSpeed > 1) {
            if(setSpeed = 3)
                        FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
            else
                        FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
        }
                adbClick(41, 296)
                break
            }
        failSafeTime := (A_TickCount - failSafe) // 1000
        LogDebug("In failsafe for Pack. ")
        Delay(1)
    }

    FindImageAndClick(0, 98, 116, 125, 5, "Opening", 239, 497) ;skip through cards until results opening screen

    FindImageAndClick(233, 486, 272, 519, , "Skip", 146, 496) ;click on next until skip button appears

    FindImageAndClick(120, 70, 150, 100, , "Next", 239, 497, , 2)

    FindImageAndClick(53, 281, 86, 310, , "Wonder", 146, 494) ;click on next until skip button appearsstop at hourglasses tutorial

    Delay(3)

    adbClick(140, 358)

    FindImageAndClick(191, 393, 211, 411, , "Shop", 146, 444) ;click until at main menu

    FindImageAndClick(87, 232, 131, 266, , "Wonder2", 79, 411) ; click until wonder pick tutorial screen

    FindImageAndClick(114, 430, 155, 441, , "Wonder3", 190, 437) ; click through tutorial

    Delay(2)

    FindImageAndClick(155, 281, 192, 315, , "Wonder4", 202, 347, 500) ; confirm wonder pick selection

    Delay(2)

    adbClick(208, 461)

    if(setSpeed = 3) ;time the animation
        Sleep, 1500
    else
        Sleep, 2500

    FindImageAndClick(60, 130, 202, 142, 10, "Pick", 208, 461, 350) ;stop at pick a card

    Delay(1)

    adbClick(187, 345)

    failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		if(setSpeed = 3)
			continueTime := 1
		else
			continueTime := 3

		if(FindOrLoseImage(233, 486, 272, 519, , "Skip", 0, failSafeTime)) {
			adbClick(239, 497)
		} else if(FindOrLoseImage(110, 230, 182, 257, , "Welcome", 0, failSafeTime)) { ;click through to end of tut screen
			break
		} else if(FindOrLoseImage(120, 70, 150, 100, , "Next", 0, failSafeTime)) {
			adbClick(146, 494) ;146, 494
		} else if(FindOrLoseImage(120, 70, 150, 100, , "Next2", 0, failSafeTime)) {
			adbClick(146, 494) ;146, 494
		}
		else {
			adbClick(187, 345)
			Delay(1)
			adbClick(143, 492)
			Delay(1)
			adbClick(143, 492)
			Delay(1)
		}
		Delay(1)

		; adbClick(66, 446)
		; Delay(1)
		; adbClick(66, 446)
		; Delay(1)
		; adbClick(66, 446)
		; Delay(1)
		; adbClick(187, 345)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for End. ")
	}

    FindImageAndClick(120, 316, 143, 335, , "Main", 192, 449) ;click until at main menu

	return true
	LogInfo("Tutorial completed.")
}

; SelectPack - Selects a pack to open
; Parameters:
;   HG - If true, selects hourglass pack
SelectPack(HG := false) {
    global openPack, packArray
	LogInfo("Opening pack...")
    packy := 196
    if(openPack = "Shining") {
        packx := 145
    } else if(openPack = "Arceus") {
        packx := 200
    } else {
        packx := 80
    }
    FindImageAndClick(233, 400, 264, 428, , "Points", packx, packy)
    if(openPack = "Pikachu" || openPack = "Mewtwo" || openPack = "Charizard" || openPack = "Mew") {
        FindImageAndClick(115, 140, 160, 155, , "SelectExpansion", 245, 475)
        packy := 442
        if(openPack = "Pikachu" || openPack = "Mewtwo" || openPack = "Charizard"){
            Sleep, 500
            adbSwipe("266 770 266 355 160")
            Sleep, 500
        }
        if(openPack = "Pikachu"){
            packx := 125
        } else if(openPack = "Mewtwo"){
            packx := 85
        } else if(openPack = "Charizard"){
            packx := 45
        } else if(openPack = "Mew"){
            packx := 205
        }
		FindImageAndClick(233, 400, 264, 428, , "Points", packx, packy)
	} else if(openPack = "Palkia") {
		Sleep, 500 
		adbClick(245, 245) ;temp
		Sleep, 500 
	}
	if(HG = "Tutorial") {
		FindImageAndClick(236, 198, 266, 226, , "Hourglass2", 180, 436, 500) ;stop at hourglasses tutorial 2 180 to 203?
	}
	else if(HG = "HGPack") {
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			if(FindOrLoseImage(60, 440, 90, 480, , "HourglassPack", 0, failSafeTime)) {
				break
			}
			adbClick(146, 439)
			Delay(1)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for HourglassPack3. ")
		}
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			if(FindOrLoseImage(60, 440, 90, 480, , "HourglassPack", 1, failSafeTime)) {
				break
			}
			adbClick(205, 458)
			Delay(1)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for HourglassPack4. ")
		}
	}
	;if(HG != "Tutorial")
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			if(FindImageAndClick(233, 486, 272, 519, , "Skip2", 130, 430, , 2)) ;click on next until skip button appears
				break
			Delay(1)
			adbClick(200, 451)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for Skip2. ")
		}
}

; PackOpening - Handles the pack opening process
; No parameters
PackOpening() {
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbClick(146, 439)
		Delay(1)
		if(FindOrLoseImage(225, 273, 235, 290, , "Pack", 0, failSafeTime))
			break ;wait for pack to be ready to Trace and click skip
		else
			adbClick(239, 497)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Pack. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at Pack")
	}

	if(setSpeed > 1) {
	FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
	FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
		Delay(1)
	}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbSwipe(adbSwipeParams)
		Sleep, 10
		if (FindOrLoseImage(225, 273, 235, 290, , "Pack", 1, failSafeTime)){
		if(setSpeed > 1) {
			if(setSpeed = 3)
					FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
			else
					FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
		}
			adbClick(41, 296)
			break
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Trace. ")
		Delay(1)
	}

    FindImageAndClick(0, 98, 116, 125, 5, "Opening", 239, 497) ;skip through cards until results opening screen

    CheckPack()

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
		} else if(FindOrLoseImage(178, 193, 251, 282, , "Hourglass", 0, failSafeTime)) {
			break
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Home. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at Home")
	}
}

; HourglassOpening - Handles hourglass pack opening
; Parameters:
;   HG - If true, uses existing hourglass setup
HourglassOpening(HG := false) {
    if(!HG) {
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

		if(packMethod) {
			AddFriends(true)
			SelectPack("Tutorial")
		}
		else {
			FindImageAndClick(236, 198, 266, 226, , "Hourglass2", 180, 436, 500) ;stop at hourglasses tutorial 2 180 to 203?
		}
	}
	if(!packMethod) {
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			if(FindOrLoseImage(60, 440, 90, 480, , "HourglassPack", 0, failSafeTime)) {
				break
			}
			adbClick(146, 439)
			Delay(1)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for HourglassPack. ")
		}
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			if(FindOrLoseImage(60, 440, 90, 480, , "HourglassPack", 1, failSafeTime)) {
				break
			}
			adbClick(205, 458)
			Delay(1)
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for HourglassPack2. ")
		}
	}
	Loop {
		adbClick(146, 439)
		Delay(1)
		if(FindOrLoseImage(225, 273, 235, 290, , "Pack", 0, failSafeTime))
			break ;wait for pack to be ready to Trace and click skip
		else
			adbClick(239, 497)
		clickButton := FindOrLoseImage(145, 440, 258, 480, 80, "Button", 0, failSafeTime)
		if(clickButton) {
			StringSplit, pos, clickButton, `,  ; Split at ", "
			if (scaleParam = 287) {
				pos2 += 5
			}
			adbClick(pos1, pos2)
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Pack. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at Pack")
	}

	if(setSpeed > 1) {
	FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
	FindImageAndClick(9, 170, 25, 190, , "One", 26, 180) ; click mod settings
		Delay(1)
	}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbSwipe(adbSwipeParams)
		Sleep, 10
		if (FindOrLoseImage(225, 273, 235, 290, , "Pack", 1, failSafeTime)){
		if(setSpeed > 1) {
			if(setSpeed = 3)
					FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
			else
					FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
		}
			adbClick(41, 296)
			break
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Trace. ")
		Delay(1)
	}

    FindImageAndClick(0, 98, 116, 125, 5, "Opening", 239, 497) ;skip through cards until results opening screen

    CheckPack()

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
		}
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for ConfirmPack. ")
		if(failSafeTime > 45)
			restartGameInstance("Stuck at ConfirmPack")
	}
}

; DoWonderPick - Completes the wonder pick process
; No parameters
; Returns: Boolean indicating success
; DoWonderPick - Completes the wonder pick process
; No parameters
; Returns: Boolean indicating success
DoWonderPick() {
	LogInfo("WonderPick")
	FindImageAndClick(191, 393, 211, 411, , "Shop", 40, 515) ;click until at main menu
	FindImageAndClick(240, 80, 265, 100, , "WonderPick", 59, 429) ;click until in wonderpick Screen
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbClick(80, 460)
		if(FindOrLoseImage(240, 80, 265, 100, , "WonderPick", 1, failSafeTime)) {
			clickButton := FindOrLoseImage(100, 367, 190, 480, 100, "Button", 0, failSafeTime)
			if(clickButton) {
				StringSplit, pos, clickButton, `,  ; Split at ", "
					; Adjust pos2 if scaleParam is 287 for 100%
					if (scaleParam = 287) {
						pos2 += 5
					}
					adbClick(pos1, pos2)
				Delay(3)
			}
			if(FindOrLoseImage(160, 330, 200, 370, , "Card", 0, failSafeTime))
				break
		}
		Delay(1)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for WonderPick. ")
	}
	Sleep, 300
	if(slowMotion)
		Sleep, 3000
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbClick(183, 350) ; click card
		if(FindOrLoseImage(160, 330, 200, 370, , "Card", 1, failSafeTime)) {
			break
		}
		Delay(1)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Card. ")
	}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		adbClick(146, 494)
		if(FindOrLoseImage(233, 486, 272, 519, , "Skip", 0, failSafeTime) || FindOrLoseImage(240, 80, 265, 100, , "WonderPick", 0, failSafeTime))
			break
		if(FindOrLoseImage(160, 330, 200, 370, , "Card", 0, failSafeTime)) {
			adbClick(183, 350) ; click card
		}
		delay(1)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Shop. ")
	}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		Delay(2)
		if(FindOrLoseImage(191, 393, 211, 411, , "Shop", 0, failSafeTime))
			break
		else if(FindOrLoseImage(233, 486, 272, 519, , "Skip", 0, failSafeTime))
			adbClick(239, 497)
		else
			adbInputEvent("111") ;send ESC
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Shop. ")
	}
	FindImageAndClick(2, 85, 34, 120, , "Missions", 261, 478, 500)
	;FindImageAndClick(130, 170, 170, 205, , "WPMission", 150, 286, 1000)
	FindImageAndClick(120, 185, 150, 215, , "FirstMission", 150, 286, 1000)
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
        Delay(1)
        adbClick(139, 424)
        Delay(1)
        clickButton := FindOrLoseImage(145, 447, 258, 480, 80, "Button", 0, failSafeTime)
        if(clickButton) {
            adbClick(110, 369)
        }
        else if(FindOrLoseImage(191, 393, 211, 411, , "Shop", 1, failSafeTime))
            adbInputEvent("111") ;send ESC
        else
            break
        failSafeTime := (A_TickCount - failSafe) // 1000
        LogDebug("In failsafe for WonderPick. ")
	}
	return true
	LogInfo("WonderPick completed.")
}


; restartGameInstance - Restarts the game
; Parameters:
;   reason - Reason for restarting
;   RL - If true, reloads the script
restartGameInstance(reason, RL := true){
    AppendToJsonFile(packs)

    if (debugMode)
        CreateStatusMessage("Restarting game reason:`n" . reason)
    else if (InStr(reason, "Stuck"))
        CreateStatusMessage("Stuck! Restarting game...")
    else
        CreateStatusMessage("Restarting game...")

    if (RL = "GodPack") {
        LogRestart("Restarted game for reason: " . reason)
        IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck

        Reload
    } else {
        adbShell.StdIn.WriteLine("am force-stop jp.pokemon.pokemontcgp")
        waitadb()
        if (!RL && DeadCheck = 0) {
            adbShell.StdIn.WriteLine("rm /data/data/jp.pokemon.pokemontcgp/shared_prefs/deviceAccount:.xml") ; delete account data
        }
        waitadb()
        adbShell.StdIn.WriteLine("am start -n jp.pokemon.pokemontcgp/com.unity3d.player.UnityPlayerActivity")
        waitadb()
        Sleep, 5000

        if (RL) {
            if (menuDeleteStart()) {
                IniWrite, 0, %A_ScriptDir%\%scriptName%.ini, UserSettings, DeadCheck
                logMessage := "\n" . username . "\n[" . (starCount ? starCount : "0") . "/5][" . (packs ? packs : 0) . "P][" . openPack . "] " . (invalid ? invalid . " God Pack" : "Some sort of pack") . " found, file name: " . accountFile . "\nGot stuck doing something"
                LogInfo(Trim(StrReplace(logMessage, "\n", " ")))
                ; Logging to Discord is temporarily disabled until all of the scenarios which could cause the script to end up here are fully understood.
                ;LogToDiscord(logMessage,, true)
            }
            LogRestart("Restarted game for reason: " . reason)

            Reload
        }
    }
}

; menuDelete - Deletes the current account via the menu
; No parameters
menuDelete() {
	sleep, %Delay%
	failSafe := A_TickCount
	failSafeTime := 0
	
	; Flush any pending log messages before menu delete operations
	FlushLogMessages()
	
	LogInfo("Menu Delete...")
	Loop
	{
		sleep, %Delay%
		sleep, %Delay%
		adbClick(245, 518)
		if(FindImageAndClick(90, 260, 126, 290, , "Settings", , , , 1, failSafeTime)) ;wait for settings menu
			break
		sleep, %Delay%
		sleep, %Delay%
		adbClick(50, 100)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Settings. ")
	}
	Sleep,%Delay%
	FindImageAndClick(24, 158, 57, 189, , "Account", 140, 440, 2000) ;wait for other menu
	Sleep,%Delay%
	FindImageAndClick(56, 435, 108, 460, , "Account2", 79, 256, 1000) ;wait for account menu
	Sleep,%Delay%

	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		failSafe := A_TickCount
		failSafeTime := 0
		Loop {
			clickButton := FindOrLoseImage(75, 340, 195, 530, 40, "Button2", 0, failSafeTime)
			if(!clickButton) {
				clickImage := FindOrLoseImage(200, 340, 250, 530, 60, "DeleteAll", 0, failSafeTime) ; fix https://discord.com/channels/1330305075393986703/1354775917288882267/1355090394307887135
				if(clickImage) {
					StringSplit, pos, clickImage, `,  ; Split at ", "
					if (scaleParam = 287) {
						pos2 += 5
					}
					adbClick(pos1, pos2)
				}
				else {
					adbClick(230, 506)
				}
				Delay(1)
				failSafeTime := (A_TickCount - failSafe) // 1000
				LogDebug("In failsafe for clicking to delete. ")
			}
			else {
				break
			}
			Sleep,%Delay%
		}
		StringSplit, pos, clickButton, `,  ; Split at ", "
		if (scaleParam = 287) {
			pos2 += 5
		}
		adbClick(pos1, pos2)
		break
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for clicking to delete. ")
	}

    Sleep, 2500
}

; menuDeleteStart - Initial logic for menu deletion
; No parameters
; Returns: Boolean indicating if a god pack was found
menuDeleteStart() {
	LogInfo("Start...")
	global friended
	if(gpFound) {
		; Don't re-process God Pack information on restart
		if(A_TickCount - gpFoundTime < 120000) { ; Check if it's been less than 2 minutes
			return false ; Return false to prevent reprocessing
		}
		return gpFound
	}
	if(friended) {
		FindImageAndClick(65, 195, 100, 215, , "Platin", 18, 109, 2000) ; click mod settings
		if(setSpeed = 3)
			FindImageAndClick(182, 170, 194, 190, , "Three", 187, 180) ; click mod settings
		else
			FindImageAndClick(100, 170, 113, 190, , "Two", 107, 180) ; click mod settings
		Delay(1)
		adbClick(41, 296)
		Delay(1)
	}
	failSafe := A_TickCount
	failSafeTime := 0
	Loop {
		if(!friended)
			break
		adbClick(255, 83)
		if(FindOrLoseImage(105, 396, 121, 406, , "Country", 0, failSafeTime)) { ;if at country continue
			break
		}
		else if(FindOrLoseImage(20, 120, 50, 150, , "Menu", 0, failSafeTime)) { ; if the clicks in the top right open up the game settings menu then continue to delete account
			Sleep,%Delay%
			FindImageAndClick(56, 435, 108, 460, , "Account2", 79, 256, 1000) ;wait for account menu
			Sleep,%Delay%
			failSafe := A_TickCount
			failSafeTime := 0
			Loop {
				clickButton := FindOrLoseImage(75, 340, 195, 530, 80, "Button", 0, failSafeTime)
				if(!clickButton) {
					clickImage := FindOrLoseImage(200, 340, 250, 530, 60, "DeleteAll", 0, failSafeTime)
					if(clickImage) {
						StringSplit, pos, clickImage, `,  ; Split at ", "
						if (scaleParam = 287) {
							pos2 += 5
						}
						adbClick(pos1, pos2)
					}
					else {
						adbClick(230, 506)
					}
					Delay(1)
					failSafeTime := (A_TickCount - failSafe) // 1000
					LogDebug("In failsafe for clicking to delete. ")
				}
				else {
					break
				}
				Sleep,%Delay%
			}
			StringSplit, pos, clickButton, `,  ; Split at ", "
			if (scaleParam = 287) {
				pos2 += 5
			}
			adbClick(pos1, pos2)
			break
			failSafeTime := (A_TickCount - failSafe) // 1000
			LogDebug("In failsafe for clicking to delete. ")
		}
		CreateStatusMessage("Looking for Country/Menu")
		LogInfo("Looking for Country/Menu")
		Delay(3)
		failSafeTime := (A_TickCount - failSafe) // 1000
		LogDebug("In failsafe for Country/Menu. ")
	}
	if(loadedAccount) {
		FileDelete, %loadedAccount%
	}
}

; getChangeDateTime - Gets the server reset time
; No parameters
; Returns: String time in HHMM format
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
; ChooseTag - Changes the player tag when a god pack is found
; No parameters
ChooseTag() {
    FindImageAndClick(120, 500, 155, 530, , "Social", 143, 518, 500)
    FindImageAndClick(20, 500, 55, 530, , "Home", 40, 516, 500)
    FindImageAndClick(209, 277, 225, 292, , "Profile", 143, 95, 500)
    FindImageAndClick(205, 310, 220, 319, , "ChosenTag", 143, 306, 1000)
    FindImageAndClick(209, 277, 225, 292, , "Profile", 143, 505, 1000)
    if (FindOrLoseImage(145, 140, 157, 155, , "Eevee", 1)) {
        FindImageAndClick(163, 200, 173, 207, , "ChooseEevee", 147, 207, 1000)
        FindImageAndClick(53, 218, 63, 228, , "Badge", 143, 466, 500)
    }
}
; TradeTutorial - Handles the trade tutorial if detected during friend operations
; No parameters
TradeTutorial() {
	if(FindOrLoseImage(100, 120, 175, 145, , "Trade", 0)) {
		LogDebug("Trade tutorial detected, handling...")
		FindImageAndClick(15, 455, 40, 475, , "Add2", 188, 449)
		Sleep, 1000
		FindImageAndClick(226, 100, 270, 135, , "Add", 38, 460, 500)
	}
	Delay(1)
}