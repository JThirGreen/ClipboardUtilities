#Requires AutoHotkey v2.0
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Array.ahk
#Include ..\Utilities\XML.ahk
#Include ..\Utilities\Configs.ahk
#Include ..\Utilities\Resource.ahk

class ConfigurationManager {
	_gui := Gui("")

	/** @type {Map<String,ConfigurationControl>} */
	_controls := Map()
	_guiXml := ""

	__New() {
		/** @type {Configurations} */
		global ScriptConfigs
		if (!IsSet(ScriptConfigs)) {
			ScriptConfigs := Configurations()
		}
		this.CreateGui()
	}

	LoadGuiXml() {
		xmlStr := Resource("ConfigsManager\gui.xml", 6).Value
		this._guiXml := XML.loadXML(xmlStr)
	}

	ShowGui() {
		this.UpdateControls()
		this._gui.Show()
	}

	CreateGui() {
		global ScriptConfigs
		if (this._guiXml = "")
			this.LoadGuiXml()

		this._gui.Title := "Clipboard Utility Configurations"

		for config in this._guiXml.selectNodes("Configs/Config") {
			configName := config.getAttribute("Name")
			properties := config.selectNodes("Property")
			for property in properties {
				propName := property.getAttribute("Name")
				propType := property.getAttribute("Type")
				propDesc := property.getAttribute("Description")
				addedProps := Map()
				addedProps.Set("Note", property.getAttribute("Note"))
				addedProps.Set("Options", CreateDDOptions(property))
				configPath := (StrLen(configName) ? (configName . ".") : "") . propName
				guiPosition := (this._controls.Count = 0) ? "xm" : "xs"
				this.CreateControl(propName, propType, propDesc, configPath, guiPosition, addedProps)
			}
		}


		;reloadBtn := this._gui.Add("Button", "y+16 xm Section Default w80", "Reload Script")
		;reloadBtn.OnEvent("Click", reload_clicked)

		;width := 0
		;height := 0
		;this._gui.Show("Hide")
		;this._gui.GetClientPos(, , &width, &height)
		;xPos := width - 80 - this._gui.MarginX
		;closeBtn := this._gui.Add("Button", "ys x" . xPos . " Default w80", "Close")
		;closeBtn.OnEvent("click", close_clicked)
		
		close_clicked(*) {
			WinClose(this._gui.Title)
			return
		}
		reload_clicked(*) {
			Reload()
			return
		}

		CreateDDOptions(property) {
			optionsList := []
			for options in property.selectNodes("Options") {
				switch options.getAttribute("Type") {
					case "Number":
						start := options.getAttribute("Start")
						end := options.getAttribute("End")
						step := options.getAttribute("Step")
						if (IsNumber(start) && IsNumber(end) && IsNumber(step)) {
							direction := 0
							if ((end - start) > 0 && step > 0) {
								direction := 1
							}
							else if ((end - start) < 0 && step < 0) {
								direction := -1
								start := 0 - start
								end := 0 - end
								step := 0 - step
							}
							if (direction != 0) {
								skipValues := StrSplit(options.getAttribute("Skip"), ",")
								i := start
								while (i <= end) {
									optionValue := i * direction
									if (!InArray(skipValues, String(optionValue))) {
										optionsList.Push({Value:optionValue, Text:optionValue})
									}
									i += step
								}
							}
							else {
								MsgBox("Error occurred when creating dropdown: Steps must go in the same direction as start => end")
							}
						}
						else {
							MsgBox("Error occurred when creating dropdown: Start, end, and step values must be numeric")
						}
					default:
						for option in options.selectNodes("Option") {
							optionsList.Push({Value:option.getAttribute("Value"), Text:option.getAttribute("Text")})
						}
				}
			}
			return optionsList
		}
	}

	CreateControl(Name, Type, Description, configPath, guiPosition, AdditionalProperties?) {
		this._controls.Set(Name, ConfigurationControl(this._gui, Name, Type, Description, configPath, guiPosition, IsSet(AdditionalProperties) ? AdditionalProperties : unset))
	}

	UpdateControls() {
		for name, ctrl in this._controls {
			ctrl.LoadValue()
		}
	}
}

class ConfigurationControl {
	/**
	 * Gui that contains this control
	 * @type {Gui}
	 */
	_gui := ""
	_name := ""
	_type := ""
	_description := ""
	_configPath := ""
	_guiPosition := ""
	_blankDefault := ""
	_addedProps := Map()

	_ctrlComponents := Map()

	__New(Gui, Name, Type, Description, ConfigPath, GuiPosition, AdditionalProperties?) {
		this._gui := Gui
		this._name := Name
		this._type := Type
		this._description := Description
		this._configPath := ConfigPath
		this._guiPosition := GuiPosition
		if (IsSet(AdditionalProperties)) {
			this._addedProps := AdditionalProperties
		}
		this.Build()
	}

	Title => (this._description != "") ? this._description : this._name

	Build() {
		initialPos := this._guiPosition || "xs"
		switch this._type, false {
			case "Number":
				this._ctrlComponents.Set("Name", this._gui.AddText(initialPos, this.Title))
				this._ctrlComponents.Set("Input", this._gui.AddEdit("xp Section Number Right r1 w50"))
				this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
				this._gui.AddUpDown("Range1-1000", 1)
				if (this._addedProps["Note"] != "") {
					this._ctrlComponents.Set("Note", this._gui.AddText("yp", "Note: " . this._addedProps["Note"]))
				}
			case "Checkbox", "StartUp":
				this._ctrlComponents.Set("Input", this._gui.AddCheckbox(initialPos . " Section", this.Title))
				this._blankDefault := 0
				this._ctrlComponents["Input"].OnEvent("Click", SaveEvent)
				if (this._type = "StartUp") {
					this._gui.AddLink("yp", "<a id=`"StartUpOpen`">Open Folder</a>").OnEvent("Click", openStartUp)
					openStartUp(*) {
						Run(A_Startup)
					}
				}
			case "Dropdown":
				this._ctrlComponents.Set("Name", this._gui.AddText(initialPos, this.Title))
				listOptions := []
				for option in this._addedProps["Options"] {
					listOptions.Push(option.Text)
				}
				this._ctrlComponents.Set("Input", this._gui.AddDropDownList("xp Section w100", listOptions))
				this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
			default:
				this._ctrlComponents.Set("Name", this._gui.AddText(initialPos . " Section", this.Title))
				this._ctrlComponents.Set("Input", this._gui.AddEdit("xp r1 w200"))
				this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
		}
		SaveEvent(*) {
			this.SaveValue(true)
		}
		this.LoadValue()
	}

	HasStartUpShortcut(&shortcutPath := "") {
		Loop Files A_Startup . "\*.lnk" {
			FileGetShortcut(A_LoopFileFullPath, &OutTarget, &OutDir, &OutArgs, &OutDescription, &OutIcon, &OutIconNum, &OutRunState)
			if (OutTarget = A_ScriptFullPath) {
				shortcutPath := A_LoopFileFullPath
				return true
			}
		}
		return false
	}

	LoadValue() {
		global ScriptConfigs
		switch this._type, false {
			case "Dropdown":
				configValue := ScriptConfigs.Get(this._configPath, this._blankDefault, true)
				for index, option in this._addedProps["Options"] {
					if (option.Value = configValue) {
						this._ctrlComponents["Input"].Value := index
						break
					}
				}
			case "StartUp":
				this._ctrlComponents["Input"].Value := this.HasStartUpShortcut()
			default:
				this._ctrlComponents["Input"].Value := ScriptConfigs.Get(this._configPath, this._blankDefault, true)
		}
	}

	SaveValue(saveToFile := true) {
		global ScriptConfigs
		value := this._ctrlComponents["Input"].Value
		switch this._type, false {
			case "Number":
				value := Max(1, Min(value, 1000))
				this._ctrlComponents["Input"].Value := value
				ScriptConfigs.SetConfigFromPath(this._configPath, value, saveToFile)
			case "Dropdown":
				ScriptConfigs.SetConfigFromPath(this._configPath, this._addedProps["Options"][value].Value, saveToFile)
			case "StartUp":
				if (value) {
					if (!this.HasStartUpShortcut()) {
						FileCreateShortcut(A_ScriptFullPath, A_Startup . "\" . A_ScriptName . ".lnk")
					}
				}
				else {
					if (this.HasStartUpShortcut(&startUpFullPath)) {
						FileDelete(startUpFullPath)
					}
				}
			default:
				ScriptConfigs.SetConfigFromPath(this._configPath, value, saveToFile)
		}
	}
}