#Requires AutoHotkey v2.0

;@Ahk2Exe-Obey U_Version, = FileRead("%A_ScriptDir%" . "\Version.txt")
;@Ahk2Exe-SetVersion %U_Version%
A_ScriptName := "Clipboard Utilities"
;@Ahk2Exe-Obey U_Name, = "%A_PriorLine~U)^(.+")(.*)".*$~$2%"
;@Ahk2Exe-SetName %U_Name%
;@Ahk2Exe-SetDescription %U_Name%
;@Ahk2Exe-SetCompanyName JThirGreen
;@Ahk2Exe-SetMainIcon Images\tray.ico
;@Ahk2Exe-AddResource Images\tray.ico, 160
;@Ahk2Exe-AddResource Images\suspend.ico, 206
;@Ahk2Exe-AddResource Images\pause.ico, 207
;@Ahk2Exe-AddResource Images\pause_suspend.ico, 208
;@Ahk2Exe-AddResource *10 Images\tray.ico
;@Ahk2Exe-AddResource *10 Images\XML.ico
;@Ahk2Exe-AddResource *10 Images\cb1.ico
;@Ahk2Exe-AddResource *10 Images\cb2.ico
;@Ahk2Exe-AddResource *10 Images\cb3.ico
;@Ahk2Exe-AddResource *10 Images\cb4.ico
;@Ahk2Exe-AddResource *10 Images\cb5.ico
;@Ahk2Exe-AddResource *10 Images\cb6.ico
;@Ahk2Exe-AddResource *10 Images\cb7.ico
;@Ahk2Exe-AddResource *10 Images\cb8.ico
;@Ahk2Exe-AddResource *10 Images\cb9.ico
;@Ahk2Exe-AddResource  *6 ConfigsManager\gui.xml

A_IconTip := A_ScriptName

Resource("Images\tray.ico", 14)
Resource("Images\XML.ico", 14)
Resource("Images\cb1.ico", 14)
Resource("Images\cb2.ico", 14)
Resource("Images\cb3.ico", 14)
Resource("Images\cb4.ico", 14)
Resource("Images\cb5.ico", 14)
Resource("Images\cb6.ico", 14)
Resource("Images\cb7.ico", 14)
Resource("Images\cb8.ico", 14)
Resource("Images\cb9.ico", 14)
Resource("ConfigsManager\gui.xml", 6)
