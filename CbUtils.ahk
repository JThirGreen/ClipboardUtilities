#Requires AutoHotkey v2.0
Suspend(true)
#Include CompilerDirectives.ahk

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
FileEncoding("UTF-8")
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.


/**
 * Global variable used exclusively for debugging
 * @type {Any}
*/
global tempGlobal := ""

#Include Updater.ahk
#Include Utilities\Resource.ahk
#Include ConfigsManager\main.ahk
#Include ClipboardManager\main.ahk

TraySetIcon(Resource("Images\tray.ico", 14).Handle)

MainInit()

ListLines(false)

return

;-----------------------------+
;    function definitions     |
;-----------------------------+
MainInit() {
	InitCbManager()
	TrayMenuInit()
	Suspend(false)
	Updater()

	; Check for updates every 2 hours
	SetTimer((*) => Updater.CheckForUpdate(), 2*60*60*1000)
}

TrayMenuInit() {
	A_TrayMenu.Insert("1&", "Configure", configureFromMenu)
	A_TrayMenu.Default := "Configure"

	configureFromMenu(*) {
		configsManager.ShowGui()
	}

	A_TrayMenu.Insert("2&", "Select Clip List", BuildClipChangerMenu())
}
