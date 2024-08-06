#Requires AutoHotkey v2.0

CoordMode("Mouse")
CoordMode("ToolTip")

/** @type {ToolTipList} */
global mainToolTipList := ToolTipList()

class ToolTipList {
	/**
	 * Initialize with blank value as placeholder for default tool tip (1)
	 * @type {Array<ToolTipBox>}
	 **/
	ToolTips := [""]
	
	__Item[i] {
		; {i} is incremented in order to skip the default tool tip (1) while also allowing it to still be accessed with intent by using non-standard index (0)
		get {
			if (i > 0) {
				i++
				if (!this.ToolTips.Has(i)) {
					this[i] := ToolTipBox("", i)
				}
				return this.ToolTips.Get(i, "")
			}
			return ""
		}
		set {
			if (i > 0) {
				i++
				if (this.Length < i) {
					this.Length := i
				}
				if (value is ToolTipBox) {
					this.ToolTips[i] := value
				}
				else if (!(value is String) && value = false)  {
					this.ToolTips[i] := ""
				}
				else {
					if (this.ToolTips.Get(i, "") is ToolTipBox) {
						this.ToolTips[i].Content := value
					}
					else {
						this.ToolTips[i] := ToolTipBox(value, i)
					}
				}
			}
		}
	}

	__Enum(NumberOfVars) {
		i := 1
		EnumItems(&item) {
			if (i > this.Length) {
				return false
			}
			item := this[i++]
			return true
		}
		EnumIndexAndItems(&index, &item) {
			index := i
			return EnumItems(&item)
		}
		return (NumberOfVars = 1) ? EnumItems : EnumIndexAndItems
	}

	Length {
		get => this.ToolTips.Length - (this.ToolTips[1] = "" ? 1 : 0)
		set => this.ToolTips.Length := (value + (this.ToolTips[1] = "" ? 1 : 0))
	}

	/**
	 * Add new {@link ToolTipBox} to the list
	 * @param {ToolTipBox|Array<ToolTipBox>|String|Array<String>} ttList New tool tip(s) to add
	 * @param {"top"|"left"|"right"|"bottom"} direction Direction from previously added tool tip to display new one at
	 * @param {ToolTipBox} relativeTo Override to select tool tip to use as relative reference instead of previously added one
	 */
	Add(ttList, direction?, relativeTo?) {
		if (IsSet(relativeTo)) {
			this._lastAddedTT := relativeTo
		}

		if (!(ttList is Array)) {
			ttList := [ttList]
		}
		for ttBox in ttList {
			if (ttBox is String) {
				ttBox := ToolTipBox(ttBox)
			}
			if (this.HasOwnProp("_lastAddedTT")) {
				ttBox.RelativeTo := this._lastAddedTT
			}
			this.ToolTips.Push(ttBox)
			ttBox.Idx := this.Length
			if (IsSet(direction)) {
				ttBox.RelativeDirection := direction
			}
			this._lastAddedTT := ttBox
		}
	}

	/**
	 * Create and add tool tips from strings
	 * @param {String} direction1 Direction from last added tool tip to display the next one in
	 * @param {String} tooltip1 String to create next tool tip from
	 * @param {[String, String]} values Additional direction and text pairs to create tool tips from
	 */
	Push(direction1, tooltip1, values*) {
		i := 0
		loop {
			if (i > values.Length) {
				break
			}
			direction := (i = 0) ? direction1 : values[i - 1],
			tipText := (i = 0) ? tooltip1 : values[i]
			this.Add(tipText, direction)
			i += 2
		}
	}

	/**
	 * Hide and delete all tool tips
	 */
	Reset() {
		this.Hide(true)
		this.ToolTips := [""]
	}

	/**
	 * Update text of tool tips
	 * @param {String|true|false} tooltips*
	 * 
	 * String: Update tool tip at matching index
	 * 
	 * true: Skip tool tip at matching index
	 * 
	 * false: Delete tool tip at matching index
	 */
	Update(tooltips*) {
		temp := ""
		for idx, tt in tooltips {
			if (tt is String) {
				this[idx] := tt
			}
			else if (tt = true) {
				continue
			}
			else if (tt = false) {
				this[idx] := false
			}
		}
	}

	Show(delay := 2000) {
		isFirstShown := false
		for tt in this.ToolTips {
			if (IsSet(tt) && tt is ToolTipBox) {
				if (!isFirstShown) {
					isFirstShown := true
					tt.Show(0, "mouse")
				}
				else {
					tt.Show(0, "relativeTo")
				}
			}
		}

		if (delay) {
			delay := 0 - Abs(delay) ; Force negative to only run timer once
			if (!this.HasOwnProp("_boundHideMethod")) {
				this._boundHideMethod := ObjBindMethod(this, "Hide", true)
			}
			SetTimer(this._boundHideMethod, delay)
		}
	}

	Hide(force := false) {
		for idx, tt in this.ToolTips {
			if (IsSet(tt) && tt is ToolTipBox) {
				tt.Hide(force)
			}
		}
	}
}

class ToolTipBox {
	/**
	 * ID of tool tip window
	 * @type {Integer}
	 */
	Id := 0
	
	/**
	 * X coord of top-left corner
	 * @type {Integer}
	 */
	X {
		get {
			this.SetCoords()
			return this.HasOwnProp("_x") ? this._x : 0
		}
	}
	/**
	 * Y coord of top-left corner
	 * @type {Integer}
	 */
	Y {
		get {
			this.SetCoords()
			return this.HasOwnProp("_y") ? this._y : 0
		}
	}
	/**
	 * Width of tool tip window
	 * @type {Integer}
	 */
	Width => this.HasOwnProp("_width") ? this._width : 0
	/**
	 * Height of tool tip window
	 * @type {Integer}
	 */
	Height => this.HasOwnProp("_height") ? this._height : 0
	/**
	 * Index of which tool tip to display as
	 * @type {Integer}
	 */
	Idx := 0
	/**
	 * Text content of tool tip
	 * @type {String}
	 */
	Content {
		get {
			return this.HasOwnProp("_content") ? this._content : ""
		}
		set {
			if (!this.HasOwnProp("_content") || this._content !== value) {
				this._width := 0
				this._height := 0
				this._content := value
			}
		}
	}
	/**
	 * Status of if tool tip is displayed or not
	 * @type {true|false}
	 */
	IsShown := false
	/**
	 * Flag to disable manual use of this.hide() for this tooltip
	 * @type {true|false}
	 */
	DelayOnly := false
	/**
	 * Optional other tool tip to display this one relative to
	 * @type {ToolTipBox}
	 */
	RelativeTo := ""
	/**
	 * Direction from {this.RelativeTo} to display this tool tip at
	 * @type {"top"|"left"|"right"|"bottom"}
	 */
	RelativeDirection := "bottom"

	/**
	 * @param {String} content Content displayed in tooltip
	 * @param {Integer} idx Tooltip index to use when displaying
	 * @param {true|false} delayOnly Flag to disable use of {@link RemoveToolTip()} for this tooltip
	 */
	__New(content, idx := 1, delayOnly := false) {
		this._x := 0,
		this._y := 0,
		this.Content := content,
		this.Idx := idx,
		this.DelayOnly := delayOnly
		this.SetCoords("mouse","mouse")
	}

	/**
	 * Set the x and y coordinates to specific values. If either coordinate is "mouse", then the current location of the mouse is used for that coordinate
	 * @param {Integer|"mouse"} x New X-coordinate
	 * @param {Integer|"mouse"} y New Y-coordinate
	 */
	SetCoords(x := "", y := "") {
		if (x = "mouse" || y = "mouse") {
			MouseGetPos(&mouseX, &mouseY)
			if (x = "mouse") {
				x := mouseX
			}
			if (y = "mouse" || y = "") {
				y := mouseY
			}
		}
		if (IsInteger(x)) {
			this._x := Number(x)
		}
		if (IsInteger(y)) {
			this._y := Number(y)
		}
	}

	/**
	 * Sets coordinates of this tool tip to display next to existing tool tip based on {direction}
	 * @param {String} direction Direction from {RelativeTo} to display this tool tip at
	 * @returns {true|false} Returns "true" if coords set successfully, otherwise "false"
	 */
	SetCoordsRelativeTo(direction := this.RelativeDirection) {
		this.RelativeDirection := direction,
		success := false
		if (this.RelativeTo is ToolTipBox && this.RelativeTo.IsShown) {
			switch direction {
				case "top":
					success := this.Height > 0
					if (success) {
						this.SetCoords(this.RelativeTo.X, this.RelativeTo.Y - this.Height)
					}
				case "left":
					success := this.Width > 0
					if (success) {
						this.SetCoords(this.RelativeTo.X - this.Width, this.RelativeTo.Y)
					}
				case "right":
					success := true
					this.SetCoords(this.RelativeTo.X + this.RelativeTo.Width, this.RelativeTo.Y)
				default: ; Defaults to "bottom"
					success := true
					this.SetCoords(this.RelativeTo.X, this.RelativeTo.Y + this.RelativeTo.Height)
			}
		}
		;MsgBox(direction . ": " . (success ? "Success" : "Fail"))
		return success
	}

	/**
	 * Display this tool tip
	 * @param {Integer} delay Delay (in ms) to auto hide tool tip
	 * @param {""|"mouse"|"relativeTo"} relativePos Mode for what to update coordinates relative to 
	 */
	Show(delay := 2000, relativePos := "") {
		/** @type {true|false} */
		recalcCoords := false
		switch relativePos {
			case "":
			case "mouse":
				this.SetCoords("mouse","mouse")
			case "relativeTo":
				recalcCoords := !this.SetCoordsRelativeTo()
			default:
				return
		}
		this.Id := ToolTip(this.Content, this.X, this.Y, this.Idx)
		this.IsShown := true
		try {
			if (recalcCoords || this._width = 0 || this._height = 0) {
				WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . this.Id)
				this._x := winX
				this._y := winY
				this._width := winW
				this._height := winH
				if (recalcCoords) {
					this.SetCoordsRelativeTo()
					this.Id := ToolTip(this.Content, this.X, this.Y, this.Idx)
				}
			}
		}
		if (delay) {
			delay := 0 - Abs(delay) ; Force negative to only run timer once
			if (!this.HasOwnProp("_boundHideMethod")) {
				this._boundHideMethod := ObjBindMethod(this, "Hide", true)
			}
			SetTimer(this._boundHideMethod, delay)
		}
	}

	Hide(force := false) {
		if (!this.DelayOnly || force) {
			this.IsShown := false
			ToolTip(, , , this.Idx)
		}
	}
}

/** @type {Map<Integer,ToolTipBox>} */
global addedToolTips := Map()
/**
 * Displays string {txt} as tooltip for {delay} period of time in milliseconds
 * @param {String} txt String to display as tooltip
 * @param {Integer} delay Number of milliseconds to display tooltip for
 */
AddToolTip(txt, delay := 2000, arrayMode := "down") {
	delay := 0 - Abs(delay) ; Force negative to only run timer once
	
	ToolTip(txt)
	if (delay) {
		SetTimer(RemoveToolTip, delay)
	}

	return
}

/**
 * Remove tooltip if currently displayed
 */
RemoveToolTip() {
	ToolTip(, , , )
}