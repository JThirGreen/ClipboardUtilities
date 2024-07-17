#Requires AutoHotkey v2.0

class Cache {
	_filePath := unset
	_name := unset
	_section := unset

	__New(filePath := A_ScriptDir, name := "global") {
		this.FilePath := filePath,
		this.Name := name
	}
	
	/**
	 * Gets or sets the value of a cached variable
	 * @param {String} name Cached variable name
	 * @returns {String}
	 */
	__Item[name, section?] {
		get => this.Get(name, section ?? unset)
		set => this.Set(name, value, section ?? unset)
	}

	/**
	 * The name of this cache
	 * @type {String}
	 */
	Name {
		get => this._name
		set => this._name := value
	}

	/**
	 * The file path where the cache is stored
	 * @type {String}
	 */
	FilePath {
		get {
			return this._filePath
		}
		set {
			this._filePath := value . "\cache"
		}
	}

	/**
	 * The full file path of the cache
	 * @type {String}
	 */
	FileName => this.FilePath . "\" . this.Name . ".ini"

	/**
	 * Default section for cached values to be read from or written to
	 * @type {String}
	 */
	Section {
		get => (this.HasOwnProp("_section")) ? this._section : "global"
		set => this._section := value
	}

	/**
	 * Gets the value of cached variable
	 * @param {String} name Cached variable name
	 * @param {String} section Optional parameter for specifying a specific section
	 * @returns {String}
	 */
	Get(name, section := this.Section) {
		return IniRead(this.FileName, section, name, "")
	}

	/**
	 * Sets the value of cached variable
	 * @param {String} name Cached variable name
	 * @param {String} value Value to be cached
	 * @param {String} section Optional parameter for specifying a specific section
	 */
	Set(name, value, section := this.Section) {
		if (!DirExist(this.FilePath)) {
			DirCreate(this.FilePath)
		}
		IniWrite(value, this.FileName, section, name)
	}

	/**
	 * Deletes a variable from the cache
	 * @param {String} name Cached variable name
	 * @param {String} section Optional parameter for specifying a specific section
	 */
	Delete(name, section := this.Section) {
		IniDelete(this.FileName, section, name)
	}
}