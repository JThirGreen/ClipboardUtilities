#Requires AutoHotkey v2.0 
#Include ConfigurationManager.ahk

/**
 * @type {ConfigurationManager}
 */
global configsManager := ConfigurationManager()

; Ctrl + Alt + Shift + G
^!+g:: {
	configsManager.ShowGui()
}