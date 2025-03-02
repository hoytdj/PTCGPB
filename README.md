# Hoytdj's Pokemon Trading Card Game Pocket Bot
This bot is an extension (AKA fork) of [Arturo's PTCGP Bot](https://github.com/Arturo-1212/PTCGPB). _Thanks for all the hard work Arturo!_ After any new releases of the main bot, this bot will be updated as soon as possible.

**IMPORTANT:** Tesseract is required for this to work.
* Download/install Tesseract from here: [Tesseract Github Link](https://github.com/UB-Mannheim/tesseract/wiki) 
* I recommend you install Tesseract under `C:\Program Files\Tesseract-OCR`. If you install it elsewhere, you **must** manually open your `Settings.ini` file and add the full path to your Tesseract executable. For example: `tesseractPath=C:\Program Files\Tesseract-OCR\tesseract.exe`

### What features does this add?
A new "GP Test" mode has been added to the Main account script. When toggled on, the bot will automatically remove all non-VIP friends (i.e., friends that may have pulled a live GP). When all non-VIP friends have been removed, the bot will pause, giving you the opportunity to nagivate to Wonder Picks and look for God Packs. When you're ready to continue, simply toggle "GP Test" mode off.
VIP friends are specified in the `vip_ids.txt` file. List friend codes each on their own line.

[YouTube Demo & Brief Tutorial](https://youtu.be/EHEwbdloBjM)

- A new setting "VIP ID URL" has been added. You can add specify a downloadable text file for your vip_ids.txt file.
- vip_ids.txt now also supports FC, IGN, and star count. Including the IGN can improve account matching accuracy. Including the star count will apply additional filtering. For example, if your min 2 star setting is 3, accounts with a GP not meeting the minimum will be ignored (not counted as a VIP).

Example file contents:
```
0735520049083732 | Nate0562 | 0/5
8076495483324199 | CheryS6334 | 3/5
2666277563052062 | CCdarumaka | 3/5
```
or
```
0735520049083732
8076495483324199
2666277563052062
```

## Bonus features:
* _Rayer_3's Scale100_ - Adds support for 100% scale in addition to the standard 125% scale.
* _DietPepperPhD's 5 Pack Method_ - The 5 Pack method is modified to skip the add/remove friend step between packs. This means you may have to test 5P GPs, but your effective packs per minute will be faster.

## License
This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0), which allows you to use, modify, and share the software only for **non-commercial** purposes.
**Commercial use, including using the software to provide paid services or selling it (even if donations are involved), is not allowed under this license.**

------------------------------------------
_A note from Arturo:_

_The bot will always be free and I will update it as long as this method is viable. I've spent many hours creating the PTCGPB, and if it’s helped you complete your collection, consider buying me a coffee to keep me going and adding new features!_
https://buymeacoffee.com/aarturoo

_Thanks for your support, and let’s keep those god packs coming!_ 😄
