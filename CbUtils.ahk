#Requires AutoHotkey v2.0

;@Ahk2Exe-SetVersion 0.5.0.0
;@Ahk2Exe-SetName Clipboard Utilities
;@Ahk2Exe-SetDescription Clipboard Utilities
;@Ahk2Exe-SetCompanyName JThirGreen
;@Ahk2Exe-SetMainIcon Images\tray.ico
;@Ahk2Exe-AddResource Images\tray.ico, 160
;@Ahk2Exe-AddResource Images\suspend.ico, 206
;@Ahk2Exe-AddResource Images\pause.ico, 207
;@Ahk2Exe-AddResource Images\pause_suspend.ico, 208

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
FileInstall("Images\tray.png", "Images\tray.png", 1)
FileInstall("Images\XML.png", "Images\XML.png", 1)
FileInstall("Images\cb1.png", "Images\cb1.png", 1)
FileInstall("Images\cb2.png", "Images\cb2.png", 1)
FileInstall("Images\cb3.png", "Images\cb3.png", 1)
FileInstall("Images\cb4.png", "Images\cb4.png", 1)
FileInstall("Images\cb5.png", "Images\cb5.png", 1)
FileInstall("Images\cb6.png", "Images\cb6.png", 1)
FileInstall("Images\cb7.png", "Images\cb7.png", 1)
FileInstall("Images\cb8.png", "Images\cb8.png", 1)
FileInstall("Images\cb9.png", "Images\cb9.png", 1)

TraySetIcon("Images\tray.png")
A_IconTip := "Clipboard Utilities"

/**
 * Global variable used exclusively for debugging
 * @type {Any}
*/
global tempGlobal := ""

#Include ConfigsManager\main.ahk
#Include ClipboardManager\main.ahk


MainInit()

ListLines(false)

return

;-----------------------------+
;    function definitions     |
;-----------------------------+
MainInit() {
	InitCbManager()
	TrayMenuInit()
}

TrayMenuInit() {
	A_TrayMenu.Insert("1&", "Configure", configureFromMenu)
	A_TrayMenu.Default := "Configure"

	configureFromMenu(*) {
		configsManager.ShowGui()
	}

	A_TrayMenu.Insert("2&", "Select Clip List", BuildClipChangerMenu())
	A_TrayMenu.Default := "Configure"	
}
