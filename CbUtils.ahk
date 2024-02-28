﻿#Requires AutoHotkey v2.0
;===========================================================#
;                      AutoHotKey Init                      #
;===========================================================#
#Include Utilities\XML.ahk
#Include ContextMenu.ahk
#Include CbManager.ahk
#Include Utilities\General.ahk
#Include Utilities\Text.ahk

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
FileInstall("Images\tray.png", "Images\tray.png", 1)
FileInstall("Images\XML.png", "Images\XML.png", 1)

TraySetIcon("Images\tray.png")
;===========================================================#
;                     Global Variables                      #
;===========================================================#
; Global variables for holding debug values
; Not to be used otherwise
global tempGlobal := ""

global mPosX := 0
global mPosY := 0
