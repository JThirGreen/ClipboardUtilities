#Requires AutoHotkey v2.0
#Include Utilities\General.ahk
#Include Utilities\Text.ahk
#Include Utilities\XML.ahk
#Include ContextMenu.ahk
#Include ClipboardManager\CbManager.ahk

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
FileInstall("Images\tray.png", "Images\tray.png", 1)
FileInstall("Images\XML.png", "Images\XML.png", 1)

TraySetIcon("Images\tray.png")

/**
 * Global variable used exclusively for debugging
 * @type {Any}
 */
global tempGlobal := ""

ListLines(false)

MainInit()

MainInit() {
	InitCbManager()
}