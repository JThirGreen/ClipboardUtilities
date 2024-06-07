#Requires AutoHotkey v2.0
#Include ..\Utilities\Text.ahk
#Include ..\Utilities\JSON.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ..\Utilities\TextTrimmer.ahk
#Include ..\MenuManager\main.ahk

class CustomClip {
	/**
	 * Type of content in this clip
	 * @type {String}
	 */
	_type := ""

	/**
	 * Clip content
	 * @type {String|ClipboardAll}
	 */
	value := ""

	/**
	 * Raw clip content
	 * @type {ClipboardAll}
	 */
	_clip := ""

	/**
	 * Name generated based on content
	 * @type {String}
	 */
	name := ""

	/**
	 * Record of when object was created
	 * @type {String}
	 */
	createdOn := A_Now

	/**
	 * File name of clip if it has been saved to a file 
	 * @type {String}
	 */
	SavedAs := ""

	/**
	 * File path of clip if it has been saved to a file 
	 * @type {String}
	 */
	SavedAt := ""

	/**
	 * Type of transformation to apply in certain scenarios
	 * @type {String}
	 */
	TfMode := ""

	/**
	 * @param {Any} content Clip content
	 * @param {String} datatype Type of content in clip
	 * @param {ClipboardAll} clip Optional raw clip content
	 * @param {String} tfMode Optional transformation mode to use
	 */
	__New(content, datatype := "text", clip := "", tfMode := "") {
		this._clip := clip
		this.TfMode := tfMode
		if (datatype = "json") {
			jsonObj := (Type(content) = "String") ? JSON.parse(content) : content
			this._type := jsonObj["_type"]
			newValue := jsonObj["value"]
			if (Type(newValue) = "String") {
				this.value := newValue
			}
			else {
				this.value := newValue is Buffer ? ClipboardAll(newValue) : JSON.stringify(newValue)
			}
			this.createdOn := jsonObj["createdOn"]
		}
		else {
			this._type := datatype
			this.value := content
		}
		/** @type {TextTrimmer} */
		clipMenuText := TextTrimmer((this._type = "text") ? CleanNewLines(this.text) : (this._type . " data"))
		this.name := clipMenuText.Value
	}

	/**
	 * @type {String}
	 */
	filePath => ((StrLen(this.SavedAt) > 0) ? (this.SavedAt . "\") : "") . this.SavedAs

	/**
	 * @type {ClipboardAll}
	 */
	clip {
		get {
			if (this._clip = "" && StrLen(this.SavedAs) > 0 && FileExist(this.filePath)) {
				this._clip := ClipboardAll(FileRead(this.filePath, "RAW"))
			}
			return this._clip
		}
	}

	/**
	 * @type {String|ClipboardAll}
	 */
	content {
		get {
			if (this.clip != "") {
				return this.clip
			}
			else if (this._type = "binary") {
				return this.value
			}
			else {
				return CleanNewLines(this.ToString())
			}
		}
	}

	/**
	 * @type {String}
	 */
	type {
		get {
			if (!StrLen(this._type) && this.clip = "") {
				return "text"
			}
			else {
				return this._type
			}
		}
	}

	/**
	 * Text content of clip
	 * 
	 * Certain transformations may be applied based on TfMode
	 * @type {String}
	 */
	text {
		get {
			if (this.type = "text") {
				if (this.TfMode = "Trim") {
					return Trim(this.value)
				}
				return this.value
			}
			return ""
		}
	}
	
	/**
	 * Return value if it is text, otherwise return generated name
	 * @param {true|false} applyTfMode
	 * @returns {String}
	 */
	ToString(applyTfMode := true) {
		if (this.type = "text") {
			return applyTfMode ? this.text : this.value
		}
		else {
			return this.name
		}
	}
	
	/**
	 * Temporarily use clipboard to paste content of clip
	 */
	Paste() {
		PasteValue(this.content, this.type, true)
	}
	
	/**
	 * Replace clipboard content with content of this clip
	 */
	Apply() {
		SetClipboardValue(this.content, this.type)
	}

	toJSON() {
		return {_type:this._type, value:this.value, createdOn:this.createdOn}
	}
}