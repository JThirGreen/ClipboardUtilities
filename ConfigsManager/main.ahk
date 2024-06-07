#Requires AutoHotkey v2.0 
#Include ConfigurationManager.ahk

global configsManager := ConfigurationManager()

; Ctrl + Alt + Shift + G
^!+g:: {
	configsManager.ShowGui()
}

A_TrayMenu.Insert("1&", "Configure", configureFromMenu)
A_TrayMenu.Default := "Configure"

configureFromMenu(vars*) {
	configsManager.ShowGui()
}