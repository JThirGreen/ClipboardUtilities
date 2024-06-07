#Requires AutoHotkey v2.0
#Include Text.ahk
#Include JSON.ahk

global ScriptConfigs := Configurations()

class Configurations extends ConfigurationFile{

	/**
	 * If configuration file is not in the default location, then this holds the new location in a separate config at the default location
	 * @type {ConfigurationFile}
	 */
	_baseConfigs := ""
	
	__New(category?, fileName?, defaultPath?) {
		this._progressState := "initializing"
		static baseConfigName := "_configs"
		static baseConfigPath := A_ScriptDir . "\_data"
		if (IsSet(fileName)) {
			this._baseConfigs := ConfigurationFile(baseConfigName, baseConfigPath)
			this._baseConfigs.SetConfigRoot(category)
			if (IsSet(defaultPath))
				super.__New(fileName, this._baseConfigs.Get("configsFilePath", category, defaultPath), defaultPath)
			else
				super.__New(fileName, this.FilePath, category)
		}
		else if (IsSet(category)) {
				super.__New(baseConfigName, baseConfigPath, category)
		}
		else {
			super.__New(baseConfigName, baseConfigPath)
		}
	}

	/**
	 * The file path where the current configurations are stored
	 * @type {String}
	 */
	FilePath {
		get {
			if (IsObject(this._baseConfigs)) {
				if (this._progressState = "initializing" && this._configFilePath != "") {
					this._baseConfigs.EditConfigs("configsFilePath", this._configFilePath)
				}
				return this._baseConfigs.Get("configsFilePath", this._baseConfigs.FilePath)
			}
			else {
				return super.FilePath
			}
		}
	}

	/**
	 * Method for changing the file path where the current configurations are stored
	 * @param path The file path to update to
	 */
	SetConfigsFilePath(path) {
		if IsObject(this._baseConfigs) {
			if (FileExist(this.FileName))
				FileMove(this.FileName, path)
			this._baseConfigs.EditConfigs("configsFilePath", path)
		}
	}
}

class ConfigurationFile {

	static _defaultFilePath := A_ScriptDir . "\_data"

	static _configVersion := 0
	_configVersion := 0

	/**
	 * {@link Map} object of assigned config actions
	 * @type {Map}
	 */
	static _configActions := Map()

	/**
	 * The name used for the configuration file
	 * @type {String}
	 */
	_configFileName := ""
	/**
	 * The extension used for the configuration file
	 * @type {String}
	 */
	_configFileExt := "json"
	/**
	 * The file path used for the configuration file
	 * @type {String}
	 */
	_configFilePath := ""
	
	/**
	 * {@link Map} object of current configurations
	 * @type {Map}
	 */
	_configMap := Map()

	/**
	 * Flag for storing state of object during initialization
	 * @type {String}
	 */
	_progressState := ""

	/**
	 * Path to specific config to use as the root
	 * @type {String}
	 */
	_configStartIn := ""

	/**
	 * Load configuration file and create it if nonexistent
	 * @param {String} name Name to use for config file
	 */
	__New(name := "_config", path := A_ScriptDir, defaultRoot := "", defaultPath?) {
		this._progressState := "initializing"
		this._configFilePath := path
		if (!DirExist(this.FilePath)) {
			try {
				DirCreate(this.FilePath)
			} catch Error as e {
				response := MsgBox("Failed to create directory:`r`n" . this.FilePath . "`r`n`r`nReason:`r`n" . e.Message . "`r`n`r`nWould you like to use the default instead?", "Configuration Error", 0x4)
				if (response = "Yes") {
					this._configFilePath := IsSet(defaultPath) ? defaultPath : ConfigurationFile._defaultFilePath
				}
				else {
					this._progressState := "error"
					return
				}
			}
		}

		this._configFileName := Trim(name)
		if (EndsWith(this._configFileName, "." . this._configFileExt, false)) {
			this._configFileName := StrReplace(this._configFileName, "." . this._configFileExt, "")
		}
		if (this._configFileName != "") {
			if (!FileExist(this.FileName)) {
				if (FileExist(this.BackupFileName)) {
					
					FileMove(this.BackupFileName, this.FileName, true)
				}
				else {
					FileAppend("{}", this.FileName)
				}
			}
			this.Load()
		}
		this.SetConfigRoot(defaultRoot)
		this._progressState := ""
	}

	__Item[name] {
		get {
			config := this.GetConfigFromPath(name)
			return (config = "") ? "" : %config%
		}
		set {
			config := this.GetConfigFromPath(name, true)
			if (!(config = "" || config is Map))
				%config% := value
		}
	}

	__Get(Key, Params) {
		if (Params.Length && IsObject(this[Key]))
			return this[Key][Params[1]]
		else
			return this[Key]
	}
	__Set(Key, Params, Value) {
		if (!this.HasProp(Key) && !this.ConfigExists(Key)) {
			if (!Params.Length)
				this.DefineProp(Key, {Value:Value})
		}
		else if (Params.Length) {
			name := Key
			for param in Params {
				name .= "." . param
			}
			this[name] := Value
		}
		else
			this[Key] := Value
	}

	/**
	 * The name used for the configuration file
	 * @type {String}
	 */
	Name => this._configFileName

	/**
	 * The file path where the current configurations are stored
	 * @type {String}
	 */
	FilePath {
		get => (this._configFilePath != "") ? (this._configFilePath) : (ConfigurationFile._defaultFilePath)
	}

	/**
	 * The full file path where the current configurations are stored
	 * @type {String}
	 */
	FileName {
		get => this.FilePath . "\" . this._configFileName . "." . this._configFileExt
	}
	/**
	 * The full file path where the backup configuration file is stored
	 * @type {String}
	 */
	BackupFileName {
		get => this.FilePath . "\" . this._configFileName . "_old." . this._configFileExt
	}

	/**
	 * Save current configuration values to configuration file
	 */
	Save() {
		if (this._progressState = 'error')
			return
		if (FileExist(this.FileName))
			FileMove(this.FileName, this.BackupFileName, true)
		FileAppend(JSON.stringify(this._configMap), this.FileName)
		ConfigurationFile._configVersion++
		this._configVersion := ConfigurationFile._configVersion
	}

	/**
	 * Load configuration values from configuration file
	 */
	Load() {
		if (this._progressState = 'error')
			return
		this._configVersion := ConfigurationFile._configVersion
		this._configMap := JSON.parse(FileRead(this.FileName))
	}

	/**
	 * Get configuration value from config path
	 * @param {String} name Config path to configuration value to retrieve
	 * @param {String|Number|Array} default Default value to return if config path is not found 
	 * @param {true|false} saveIfDefault If 'true' and config path is not found, then create it with the default as the value 
	 * @returns {String|Number|Array} Value found at config path
	 */
	Get(name, default := "", saveIfDefault := false) {
		if (this._progressState = 'error')
			return default

		this.VersionCheck()
		if (this.ConfigExists(name))
			return this[name]
		else {
			if (saveIfDefault)
				this.SetConfigFromPath(name, default, true)
			return default
		}
	}

	/**
	 * Bulk create/update config values. Takes array of values that alternate config path and value to store at that path.
	 * @param {Array} configs ConfigPath1, ConfigValue1, ConfigPath2, ConfigValue2, ...
	 */
	EditConfigs(configs*) {
		configRoot := this.GetConfigFromPath("", true)
		if (configs is Array && IsEven(configs.Length)) {
			Loop (configs.Length / 2) {
				configIndex := (A_Index * 2)
				this.SetConfigFromPath(configs[configIndex - 1], configs[configIndex], false)
			}
			this.Save()
		}
	}

	/**
	 * Checks if config exists at a config path
	 * @param {String} name Config path to check if exists
	 * @returns {true|false}
	 */
	ConfigExists(name) {
		if ((this.HasProp("_progressState") && this._progressState = 'error') || !this.HasProp("_configMap"))
			return false
		
		conf := this.GetConfigFromPath(name)
		return !(conf = "" || %conf% = "")
	}
	
	/**
	 * Given a name or relative path to a config, return the absolute path to the location in the config file that config is found
	 * @param {String} name Name/path of the config
	 * @returns {String}
	 */
	GetConfigPath(name) {
		configPath := ""
		this.GetConfigFromPath(name, , &configPath)
		return configPath
	}
	
	/**
	 * Given a name or relative path to a config, return the absolute path to the location in the config file that config is found
	 * @param {String} name Name/path of the config
	 * @returns {String}
	 */
	GetFullConfigPath(name) {
		return this.FileName . "[" . this.GetConfigPath(name) . "]"
	}

	/**
	 * Get reference to config found at a config path
	 * @param {String} path Config path to search for
	 * @param {true|false} createIfNotFound If 'true' and not found, then create config at config path
	 * @returns {VarRef|String} Reference to config if found or empty string if not
	 */
	GetConfigFromPath(path, createIfNotFound := false, &configFullPath?) {
		if (!this.HasProp("_configMap") || !this.HasProp("_configStartIn"))
			return ""

		mapPoint := this._configMap
		configPath := this._configStartIn . ((this._configStartIn && path) ? "." : "") . path

		if (StrLen(configPath)) {
			steps := StrSplit(configPath, ".")
			for step in steps {
				if (!(mapPoint is Map))
					return ""
				
				if (createIfNotFound && !mapPoint.Has(step))
					mapPoint[step] := Map()
				
				if (mapPoint.Has(step))
					mapPoint := (mapPoint[step])
				else
					return ""
			}
		}
		if (IsSet(configFullPath)) {
			configFullPath := configPath
		}
		return &mapPoint
	}

	/**
	 * Create/update config value at config path
	 * @param {String} path Config path
	 * @param {String|Number|Array} value Value to set config to
	 * @param {true|false} saveToFile If 'false', then modify the config value without updating configuration file
	 */
	SetConfigFromPath(path, value, saveToFile := true) {
		if (path = "")
			return

		steps := StrSplit(path, ".")

		configPath := ""
		configName := ""
		for step in steps {
			if (StrLen(configPath))
				configPath .= "."
			configPath .= configName
			configName := step
		}
		%this.GetConfigFromPath(configPath, true)%.Set(configName, value)
		if (saveToFile) {
			this.Save()
		}
		configActionId := this.GetFullConfigPath(path)
		if (ConfigurationFile._configActions.Has(configActionId)) {
			configAction := ConfigurationFile._configActions[configActionId]
			if (configAction is Func) {
				switch configAction.MinParams {
					case 0:
						thisValue := configAction()
					default:
						thisValue := configAction(value)
				}
			}
		}
	}

	/**
	 * Check if config path exists and if so, then set as config root
	 * @param {String} path Config path to set as root
	 */
	SetConfigRoot(path) {
		confFromPath := this.GetConfigFromPath(path, true)
		if (%confFromPath% is Map)
			this._configStartIn := path
	}

	/**
	 * Checks if config file has been altered by another object and reloads it if so
	 */
	VersionCheck() {
		if (ConfigurationFile._configVersion != this._configVersion) {
			this.Load()
		}
	}

	/**
	 * Observe particular config and trigger a callback function when that config value has changed
	 * @param {String} path Relative path of config to attach action to
	 * @param {Func} callback Callback to call when config has changed
	 */
	AddConfigAction(path, callback) {
		fullConfigPath := this.GetFullConfigPath(path)
		if (callback is Func)
			ConfigurationFile._configActions.Set(fullConfigPath, callback)
		else
			MsgBox("Config action callback must be function")
	}
}
