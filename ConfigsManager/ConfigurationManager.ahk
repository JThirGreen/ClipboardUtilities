#Requires AutoHotkey v2.0
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Array.ahk
#Include ..\Utilities\TextTools.ahk
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

		this._gui.Title := "Clipboard Utility Configurations",
		this._gui.MarginX := 8,
		this._gui.MarginY := 8

		titleOptions := "xm ym"
		for config in this._guiXml.selectNodes("Configs/Config") {
			configName := config.getAttribute("Name"),
			configDesc := config.getAttribute("Description")
			configTitle := (configDesc != "") ? configDesc : configName
			
			this._gui.SetFont(configTitle !="" ? "bold underline s12" : "s1")
			this._gui.AddText(titleOptions, (configDesc != "") ? configDesc : configName)
			titleOptions := "xm y+12"
			this._gui.SetFont()

			properties := config.selectNodes("Property"),
			guiPosition := "xm+8 y+4"
			for property in properties {
				propName := property.getAttribute("Name"),
				propType := property.getAttribute("Type"),
				propDesc := property.getAttribute("Description"),
				addedProps := Map()
				addedProps.Set("Note", property.getAttribute("Note")),
				addedProps.Set("Position", property.getAttribute("Position")),
				addedProps.Set("Options", CreateDDOptions(property))
				configPath := (StrLen(configName) ? (configName . ".") : "") . propName
				if (property.getAttribute("Position") = "Inline") {
					guiPosition := "yp"
				}
				this.CreateControl(propName, propType, propDesc, configPath, guiPosition, addedProps)
				guiPosition := "xs"
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
	/** @type {Map<String, Any>} */
	_addedProps := Map()

	/** @type {Map<String, Gui.Control|Array<Gui.Control>>} */
	_ctrlComponents := Map()

	/** @type {Map<String, {x, y, width, height}>} */
	_ctrlPositions := Map()

	__New(Gui, Name, Type, Description, ConfigPath, GuiPosition, AdditionalProperties?) {
		this._gui := Gui,
		this._name := Name,
		this._type := Type,
		this._description := Description,
		this._configPath := ConfigPath,
		this._guiPosition := GuiPosition
		if (IsSet(AdditionalProperties)) {
			this._addedProps := AdditionalProperties
		}
		this.Build()
	}

	NoteFontOptions => "italic"

	Title => (this._description != "") ? this._description : this._name
	TitleFontOptions => "bold"

	Value {
		get {
			value := 0
			if (!this._ctrlComponents.Has("Input")) {
				return ""
			}
			else if (this._ctrlComponents["Input"] is Array) {
				for idx, input in this._ctrlComponents["Input"] {
					if (input.Value = 1) {
						value := idx
						break
					}
				}
			}
			else {
				value := this._ctrlComponents["Input"].Value
			}
			return value
		}
	}

	Build() {
		initialPos := this._guiPosition || "xs"
		switch this._type, false {
			case "Text":
				AddTitle(initialPos, this.Title)
			case "Link":
				this._gui.AddLink(initialPos, "<a id=`"" . this._name . "`">" . this.Title . "</a>").OnEvent("Click", openLink)
				openLink(*) {
					linkPath := this._name
					if (TextTools.StartsWith(linkPath, "\")) {
						linkPath := "C:" . linkPath
					}
					else if (!RegExMatch(linkPath, "i)^[A-Z]:\\")) {
						linkPath := ScriptConfigs.FilePath . "\" . linkPath
					}
					if (DirExist(linkPath)) {
						Run(linkPath)
					}
					else {
						MsgBox("Directory could not be found:`r`n" . linkPath)
					}
				}
			case "Number":
				AddTitle(initialPos, this.Title)
				this._ctrlComponents.Set("Input", this._gui.AddEdit("xp y+4 Section Number Right r1 w50"))
				this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
				this._gui.AddUpDown("Range1-1000", 1)
				if (this._addedProps["Note"] != "") {
					AddNote("yp", "Note: " . this._addedProps["Note"])
				}
			case "Checkbox", "StartUp":
				this._ctrlComponents.Set("Input", this._gui.AddCheckbox(initialPos . " Section", this.Title))
				this._blankDefault := 0
				this._ctrlComponents["Input"].OnEvent("Click", SaveEvent)
				if (this._type = "StartUp") {
					this._gui.AddLink("yp", "<a id=`"StartUpOpen`">Open Startup Folder</a>").OnEvent("Click", openStartUp)
					openStartUp(*) {
						Run(A_Startup)
					}
				}
			case "Dropdown", "Radio":
				AddTitle(initialPos, this.Title)
				listOptions := []
				for option in this._addedProps["Options"] {
					listOptions.Push(option.Text)
				}
				if (this._type = "Radio") {
					radioArray := [],
					ctrlOptions := "xp y+4 Section Group"
					for idx, option in listOptions {
						radioArray.Push(radioBtn := this._gui.AddRadio(ctrlOptions, option))
						radioBtn.OnEvent("Click", SaveEvent)
						ctrlOptions := "yp"
					}
					this._ctrlComponents.Set("Input", radioArray)
				}
				else {
					this._ctrlComponents.Set("Input", this._gui.AddDropDownList("xp y+4 Section w100", listOptions))
					this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
				}
			default:
				AddTitle(initialPos . " Section", this.Title)
				this._ctrlComponents.Set("Input", this._gui.AddEdit("xp r1 w200"))
				this._ctrlComponents["Input"].OnEvent("Change", SaveEvent)
		}
		this.LoadValue()
		SaveEvent(*) {
			this.SaveValue(true)
		}
		AddTitle(Options, Text) {
			this._gui.SetFont(this.TitleFontOptions)
			this._ctrlComponents.Set("Name", this._gui.AddText(Options, Text))
			this._gui.SetFont()
		}
		AddNote(Options, Text) {
			this._gui.SetFont(this.NoteFontOptions)
			this._ctrlComponents.Set("Note", this._gui.AddText(Options, Text))
			this._gui.SetFont()
		}
	}

	LoadValue() {
		global ScriptConfigs
		switch this._type, false {
			case "Text":
			case "Link":
			case "Dropdown","Radio":
				configValue := this._blankDefault
				if (configExists := ScriptConfigs.ConfigExists(this._configPath)) {
					configValue := ScriptConfigs.Get(this._configPath)
				}
				for index, option in this._addedProps["Options"] {
					if (option.Value = configValue) {
						if (!configExists) {
							ScriptConfigs.SetConfigFromPath(this._configPath, configValue, false)
						}
						if (this._type = "Dropdown") {
							this._ctrlComponents["Input"].Value := index
						}
						else if (this._type = "Radio") {
							this._ctrlComponents["Input"][index].Value := 1
						}
						break
					}
				}
			case "StartUp":
				this._ctrlComponents["Input"].Value := HasStartUpShortcut()
			default:
				this._ctrlComponents["Input"].Value := ScriptConfigs.Get(this._configPath, this._blankDefault, true)
		}
	}

	SaveValue(saveToFile := true) {
		global ScriptConfigs
		value := this.Value
		switch this._type, false {
			case "Text":
			case "Link":
			case "Number":
				this._ctrlComponents["Input"].Value := value := Max(1, Min(value, 1000))
				ScriptConfigs.SetConfigFromPath(this._configPath, value, saveToFile)
			case "Dropdown","Radio":
				ScriptConfigs.SetConfigFromPath(this._configPath, this._addedProps["Options"][value].Value, saveToFile)
			case "StartUp":
				if (value = 1) {
					if (!HasStartUpShortcut()) {
						FileCreateShortcut(A_ScriptFullPath, A_Startup . "\" . A_ScriptName . ".lnk")
					}
				}
				else {
					if (HasStartUpShortcut(&startUpFullPath)) {
						FileDelete(startUpFullPath)
					}
				}
			default:
				ScriptConfigs.SetConfigFromPath(this._configPath, value, saveToFile)
		}
	}

	/**
	 * Get position and size of an inner control by name
	 * @param {String} crtlName Name of inner control
	 * @returns {{x, y, width, height, found}}
	 */
	GetPos(crtlName) {
		if (this._ctrlComponents.Has(crtlName)) {
			if (!this._ctrlPositions.Has(crtlName)) {
				x := "", y := "", w := "", h := ""
				try ControlGetPos(&x, &y, &w, &h, this._ctrlComponents[crtlName])
				this._ctrlPositions[crtlName] := {x:x, y:y, width:w, height:h, found:true}
			}
			return this._ctrlPositions[crtlName]
		}
		return {x:0, y:0, width:0, height:0, found:false}
	}
}