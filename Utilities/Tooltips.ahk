#Requires AutoHotkey v2.0
#Include General.ahk
#Include Time.ahk

CoordMode("Mouse")
CoordMode("ToolTip")

/** @type {ToolTipList} */
global MainToolTipList := ToolTipList()

class ToolTipList {
	/**
	 * Initialize with blank value as placeholder for default tool tip (1)
	 * @type {Array<ToolTipBox>}
	 **/
	ToolTips := [""]

	Left := 0
	Top := 0
	Right := 0
	Bottom := 0
	Width => this.Right - this.Left
	Height => this.Bottom - this.Top

	/**
	 * @param {String|Array<String>} content Content displayed in tooltip
	 * @param {ToolTipDirection} direction Direction to append content to if multiple are provided
	 */
	__New(content?, direction?) {
		if (IsSet(content)) {
			this.Add(content, direction?)
		}
	}
	
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
	 * @param {ToolTipDirection} direction Direction from previously added tool tip to display new one at
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
	 * @param {ToolTipDirection} direction1 Direction from last added tool tip to display the next one in
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
		local originX, originY,
			realLeft, realTop, realRight, realBottom,
			virtualLeft, virtualTop, virtualRight, virtualBottom,
			mouseX, mouseY,
			boundLeft, boundTop, boundRight, boundBottom
		GetScreenPosMouse(&mouseX, &mouseY)
		GetDisplayFromCoords(mouseX, mouseY, &boundLeft, &boundTop, &boundRight, &boundBottom, true)

		displayTTs()

		this.Left := virtualLeft - originX, this.Top := virtualTop - originY, this.Right := virtualRight - originX, this.Bottom := virtualBottom - originY,
		realWidth := realRight - realLeft, realHeight := realBottom - realTop
		if (this.Width != realWidth || this.Height != realHeight) {
			displayTTs()
		}

		if (delay) {
			delay := 0 - Abs(delay) ; Force negative to only run timer once
			if (!this.HasOwnProp("_boundHideMethod")) {
				this._boundHideMethod := ObjBindMethod(this, "Hide", true)
			}
			SetTimer(this._boundHideMethod, delay)
		}

		displayTTs() {
			minOriginX := boundLeft - this.Left,
			minOriginY := boundTop - this.Top,
			maxOriginX := boundRight - this.Right - 1,
			maxOriginY := boundBottom - this.Bottom - 1,
			originX := Max(minOriginX, Min(maxOriginX, mouseX)),
			originY := Max(minOriginY, Min(maxOriginY, mouseY)),
			isFirstShown := false
			for tt in this.ToolTips {
				if (IsSet(tt) && tt is ToolTipBox) {
					if (!isFirstShown) {
						isFirstShown := true,
						tt.SetCoords(originX, originY)
						tt.Show(0)
						realLeft := tt.Left, realTop := tt.Top, realRight := tt.Right, realBottom := tt.Bottom,
						virtualLeft := tt.VirtualLeft, virtualTop := tt.VirtualTop, virtualRight := tt.VirtualRight, virtualBottom := tt.VirtualBottom
					}
					else {
						tt.Show(0, "relativeTo")
						realLeft := Min(realLeft, tt.Left), realTop := Min(realTop, tt.Top), realRight := Max(realRight, tt.Right), realBottom := Max(realBottom, tt.Bottom),
						virtualLeft := Min(virtualLeft, tt.virtualLeft), virtualTop := Min(virtualTop, tt.virtualTop), virtualRight := Max(virtualRight, tt.virtualRight), virtualBottom := Max(virtualBottom, tt.virtualBottom)
					}
				}
			}
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
	X => this.HasOwnProp("_x") ? this._x : 0
	/**
	 * Y coord of top-left corner
	 * @type {Integer}
	 */
	Y => this.HasOwnProp("_y") ? this._y : 0
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
	 * Left bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	Left => this.X
	/**
	 * Top bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	Top => this.Y
	/**
	 * Right bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	Right => this.X + this.Width
	/**
	 * Bottom bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	Bottom => this.Y + this.Height
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
				if (this.IsShown) {
					this.ShowNew()
				}
			}
		}
	}
	/**
	 * Status of if tool tip is displayed or not
	 * @type {true|false}
	 */
	IsShown => !!WinExist("ahk_id " . this.Id)
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
	 * Virtual X coordinate of top-left corner from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualX := 0
	/**
	 * Virtual Y coordinate of top-left corner from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualY := 0
	/**
	 * Virtual left bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualLeft => this.VirtualX
	/**
	 * Virtual top bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualTop => this.VirtualY
	/**
	 * Virtual right bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualRight => this.VirtualX + this.Width
	/**
	 * Virtual bottom bounding coordinate from multi-tooltip origin
	 * @type {Integer}
	 */
	VirtualBottom => this.VirtualY + this.Height

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
		changed := false
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
			newX := Number(x),
			changed |= this._x != newX,
			this._x := newX
		}
		if (IsInteger(y)) {
			newY := Number(y),
			changed |= this._y != newY,
			this._y := newY
		}
		if (changed) {
			if (!(this.RelativeTo is ToolTipBox)) {
				this.VirtualX := this._x,
				this.VirtualY := this._y
			}
			if (this.IsShown) {
				winDelay := A_WinDelay
				SetWinDelay(0)
				WinMove(this.X, this.Y, , , "ahk_id " . this.Id)
				SetWinDelay(winDelay)
			}
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
						this.SetCoords(this.RelativeTo.Left, this.RelativeTo.Top - this.Height)
						this.VirtualX := this.RelativeTo.VirtualLeft, this.VirtualY := this.RelativeTo.VirtualTop - this.Height
					}
				case "left":
					success := this.Width > 0
					if (success) {
						this.SetCoords(this.RelativeTo.Left - this.Width, this.RelativeTo.Top)
						this.VirtualX := this.RelativeTo.VirtualLeft - this.Width, this.VirtualY := this.RelativeTo.VirtualTop
					}
				case "right":
					success := true
					this.SetCoords(this.RelativeTo.Right, this.RelativeTo.Top)
					this.VirtualX := this.RelativeTo.VirtualRight, this.VirtualY := this.RelativeTo.VirtualTop
				default: ; Defaults to "bottom"
					success := true
					this.SetCoords(this.RelativeTo.Left, this.RelativeTo.Bottom)
					this.VirtualX := this.RelativeTo.VirtualLeft, this.VirtualY := this.RelativeTo.VirtualBottom
			}
		}
		;MsgBox(direction . ": " . (success ? "Success" : "Fail"))
		return success
	}

	/**
	 * Display this tool tip
	 * @param {Integer} delay Delay (in ms) to auto hide tool tip
	 * @param {""|"mouse"|"relativeTo"} relativePos Mode for what to update coordinates relative to
	 * @param {Array<Integer>} offset Optional offset to apply in format: [xOffset, yOffset]
	 */
	Show(delay := 2000, relativePos := "", offset := [0,0]) {
		/** @type {true|false} */
		recalcDimensions := false
		switch relativePos {
			case "":
			case "mouse":
				this.SetCoords("mouse","mouse")
			case "relativeTo":
				recalcDimensions := !this.SetCoordsRelativeTo()
			default:
				return
		}
		if (IsSet(offset)) {
			this._x += offset[1],
			this._y += offset[2]
		}
		if (!this.IsShown) {
			this.ShowNew()
		}
		try {
			WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . this.Id)
			recalcDimensions |= ((this.RelativeDirection = "left" && this._width != winW) || (this.RelativeDirection = "top" && this._height != winH)),
			this._x := winX, this._y := winY, this._width := winW, this._height := winH
			if (recalcDimensions) {
				this.SetCoordsRelativeTo()
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

	ShowNew() {
		this.Id := ToolTip(this.Content, this.X, this.Y, this.Idx)
	}

	Hide(force := false) {
		if (this.IsShown && (!this.DelayOnly || force)) {
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

/**
 * @typedef {"top"|"left"|"right"|"bottom"} ToolTipDirection
 */