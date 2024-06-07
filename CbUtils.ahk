#Requires AutoHotkey v2.0

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
FileInstall("Images\tray.png", "Images\tray.png", 1)
FileInstall("Images\XML.png", "Images\XML.png", 1)

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
