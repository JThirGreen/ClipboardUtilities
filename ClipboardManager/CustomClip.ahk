#Requires AutoHotkey v2.0
#Include ..\ContextMenu.ahk

class CustomClip {
	/**
	 * Type of content in this clip
	 * @type {String}
	 */
	type := ""

	/**
	 * Clip content
	 * @type {Any}
	 */
	value := ""

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
	 */
	__New(content, datatype := "text") {
		this.type := datatype
		this.value := content
		/** @type {MenuText} */
		clipMenuText := {}
		if (datatype = "text")
			clipMenuText := MenuText(content)
		else
			clipMenuText := MenuText(datatype . " data")
		this.name := clipMenuText.Value
		this.title := clipMenuText.Text
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
		if (this.type = "binary") {
			cbTemp := ClipboardAll()
			A_Clipboard := ClipboardAll(this.value)
			PasteClipboard(, true)
			A_Clipboard := cbTemp
		}
		else {
			PasteValue(this.ToString())
		}
	}
	
	/**
	 * Replace clipboard content with content of this clip
	 */
	Select() {
		if (this.type = "binary") {
			A_Clipboard := ClipboardAll(this.value)
		}
		else {
			A_Clipboard := this.value
		}
	}
}