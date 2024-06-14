#Requires AutoHotkey v2.0
Suspend(true)
#Include CompilerDirectives.ahk

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.

TraySetIcon(Resource("Images\tray.ico", 14).Handle)
A_IconTip := "Clipboard Utilities"

/**
 * Global variable used exclusively for debugging
 * @type {Any}
*/
global tempGlobal := ""

#Include Updater.ahk
#Include Utilities\Resource.ahk
#Include ConfigsManager\main.ahk
#Include ClipboardManager\main.ahk

MainInit()

ListLines(false)

return

;-----------------------------+
;    function definitions     |
;-----------------------------+
MainInit() {
	global updateHandler
	InitCbManager()
	TrayMenuInit()
	Suspend(false)
	updateHandler := Updater()
}

TrayMenuInit() {
	A_TrayMenu.Insert("1&", "Configure", configureFromMenu)
	A_TrayMenu.Default := "Configure"

	configureFromMenu(*) {
		configsManager.ShowGui()
	}

	A_TrayMenu.Insert("2&", "Select Clip List", BuildClipChangerMenu())
}
