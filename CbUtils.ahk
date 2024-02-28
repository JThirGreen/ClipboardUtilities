#Requires AutoHotkey v2.0
;===========================================================#
;                      AutoHotKey Init                      #
;===========================================================#
#Include Utilities\General.ahk
#Include Utilities\Text.ahk
#Include Utilities\XML.ahk
#Include ContextMenu.ahk
#Include CbManager.ahk

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

/**
 * Global variable to store mouse X-coord
 * @type {Number}
 */
global mPosX := 0

/**
 * Global variable to store mouse Y-coord
 * @type {Number}
 */
global mPosY := 0
