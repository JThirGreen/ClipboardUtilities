#Requires AutoHotkey v2.0
#Include ..\Utilities\Clipboard.ahk
#Include ..\ContextMenu.ahk

Class CustomClip {
	/**
	 * Type of content in this clip
	 * @type {String}
	 */
	_type := ""

	/**
	 * Clip content
	 * @type {Any}
	 */
	value := ""

	/**
	 * Raw clip content
	 * @type {ClipboardAll()}
	 */
	clip := ""

	/**
	 * Name generated based on content
	 * @type {String}
	 */
	name := ""

	/**
	 * Name generated based on content for use in context menus
	 * @type {String}
	 */
	title := ""

	/**
	 * @param {Any} content Clip content
	 * @param {String} datatype Type of content in clip
	 * @param {ClipboardAll()} clip Optional raw clip content
	 */
	__New(content, datatype := "text", clip := "") {
		this._type := datatype
		this.value := content
		this.clip := clip
		/** @type {MenuText} */
		clipMenuText := MenuText((datatype = "text") ? (content) : (datatype . " data"))
		this.name := clipMenuText.Value
		this.title := clipMenuText.Text
	}

	content {
		get {
			if (this.clip != "") {
				return this.clip
			}
			else if (this._type = "binary") {
				return this.value
			}
			else {
				return this.ToString()
			}
		}
	}

	type {
		get {
			if (this.clip != "") {
				return "binary"
			}
			else {
				return this._type
			}
		}
	}
	
	/**
	 * Return value if it is text, otherwise return generated name
	 * @returns {String} 
	 */
	ToString() {
		if (this.type = "text")
			return this.value
		else
			return this.name
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
}