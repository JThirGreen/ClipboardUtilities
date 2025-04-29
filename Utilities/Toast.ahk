#Requires AutoHotkey v2.0
#Include General.ahk
#Include Time.ahk

class Toast {
    /** @type {Integer} */
    static _padding := 12
    /** @type {Integer} */
    static _duration := 2000
    /** @type {Integer} */
    static _defaultFrequency := 60
    /** @type {Gui} */
    _gui := ""
    /** @type {Gui.Text} */
    _guiTitle := ""
    /** @type {Gui.Text} */
    _guiText := ""
    /** @type {{x:Number, y:Number} */
    _guiOrigin := {x:0, y:0}
    /** @type {{x:Number, y:Number} */
    _guiSlideOffset := {x:0, y:0}
    
    /** @type {String} */
    _title := ""
    /** @type {String} */
    _content := ""

    /** @type {Integer} */
    _fadeTime := 200
    /** @type {true|false} */
    _isRendering := false
    /** @type {Func} */
    _hideFunc := ""

    /** @type {Integer} */
    Hwnd {
        get => this._gui.Hwnd
    }

    /** @type {Integer} */
    _stepFrequency := Toast._defaultFrequency
    /** @type {Integer} */
    StepFrequency {
        get => this._stepFrequency > 0 ? this._stepFrequency : 255
        set => this._stepFrequency
    }

    /** @type {Integer} */
    _opacity := -1
    /** @type {Integer} */
    Opacity {
        get => this._gui is Gui ? this._opacity : -1
        set {
            if (this._gui is Gui) {
                this._opacity := Value
                winDelay := A_WinDelay
                SetWinDelay(0)
                WinSetTransparent(Max(Min(Round(this._opacity), 255), 0), this.Hwnd)
                SetWinDelay(winDelay)
            }
        }
    }

    __New(title := "", content := "", duration := Toast._duration) {
        this._content := content,
        this._title := title
        this.FadeIn(duration)
    }

    ApplyStepRatio(stepRatio) {
        this.Opacity := 255 * stepRatio
        newX := this._guiOrigin.x - (this._guiSlideOffset.x * stepRatio)
        newY := this._guiOrigin.y - (this._guiSlideOffset.y * stepRatio)
        this.Move(newX, newY)
    }

    /**
     * Initialize and display toast GUI
     * @param {Integer} delay Time to display toast for (in ms)
     */
    Display(delay := Toast._duration) {
        this.Render(delay?)
        this.Opacity := 255
    }

    /**
     * Initialize toast GUI
     * @param {Integer} delay Time to display toast for (in ms)
     */
    Render(delay := Toast._duration) {
        if (this._gui is Gui) {
            this.Hide()
        }
        padding := Toast._padding,
        halfPadding := Toast._padding // 2,
        minWidth := 200,
        maxWidth := 600,
        contentWidth := 0,
        contentHeight := 0,
        this._gui := Gui("+ToolWindow -Caption +AlwaysOnTop +Disabled -DPIScale")
        this._gui.BackColor := 000000
        if (StrLen(this._title) > 0) {
            this._gui.SetFont("cFFFFFF S12 bold", "Verdana")
            this._guiTitle := this._gui.AddText("center x" . padding . " y" . padding . " r1", this._title)
        }
        if (StrLen(this._content) > 0) {
            this._gui.SetFont("cFFFFFF S8", "Verdana")
            this._guiText := this._gui.AddText("center x" . padding . " y+" . padding . " r1", this._content)
        }
        else {
            this._guiText := this._guiTitle ; If no content is found, then resize title as if it's the content
        }
        this._guiText.GetPos(&ctrlX, &ctrlY, &ctrlW, &ctrlH)
        contentHeight := ctrlY + ctrlH - padding
        ; Match title and text widths to keep them centered 
        if (ctrlW < minWidth) {
            contentWidth := minWidth
        }
        else if (ctrlW < maxWidth) {
            contentWidth := ctrlW
        }
        else {
            contentWidth := maxWidth
        }
        this._guiTitle.Move(, , contentWidth)
        this._guiText.Move(, , contentWidth)

        toastWidth := padding + contentWidth + padding,
        toastHeight := padding + contentHeight + padding
        ; Get toast origin
        GetScreenPosMouse(&mouseX, &mouseY)
        currentDisplay := GetDisplayFromCoords(mouseX, mouseY, &dispLeft, &dispTop, &dispRight, &dispBottom)

        this._guiOrigin.x := (dispRight + dispLeft) // 2,
        this._guiOrigin.y := dispTop

        this._guiSlideOffset.x := 0,
        this._guiSlideOffset.y := -20

        ; Display toast
        this._gui.Show("NoActivate X" . this._guiOrigin.x . " Y" . this._guiOrigin.y . " AutoSize")
        this.Opacity := 0
        WinGetPos(&winX, &winY, &winW, &winH, this.Hwnd)
        newW := toastWidth,
        newH := toastHeight
        this._guiOrigin.x := winX - (newW // 2),
        this._guiOrigin.y := dispTop
        this._gui.Move(this._guiOrigin.x, this._guiOrigin.y, newW, newH)
        ;MsgBox("display #" . currentDisplay . "(" . dispTop . "," . dispBottom . "," . dispLeft . "," . dispRight . ")" . "`n" . this._guiOrigin.x . "," . this._guiOrigin.y . "@" . newW . "x" . newH)
        WinSetRegion("0-0 W" . newW . " H" . newH . " R30-30", this.Hwnd)
        WinSetExStyle("+0.20", this.Hwnd)

        delay := 0 - Abs(delay) ; Force negative to only run timer once
        if (!(this._hideFunc is Func)) {
            this._hideFunc := ObjBindMethod(this, "Hide")
        }
        SetTimer(this._hideFunc, delay)
    }

    /**
     * Display toast with fade in effect
     * @param {Integer} stepFrequency Number of steps per second
     * @param {Integer} delay Time to display toast for (in ms)
     */
    FadeIn(delay := Toast._duration, stepFrequency := this.StepFrequency) {
        if ((!IsSet(delay) || delay > this._fadeTime) && stepFrequency > 0) {
            this._hideFunc := ObjBindMethod(this, "FadeOut", stepFrequency)
            this.Render(delay > this._fadeTime ? delay - this._fadeTime : delay)
            this.Opacity := 0,
            lastStep := 0,
            steps := Round((stepFrequency * this._fadeTime) / 1000),
            startTime := TickCount(),
            elapsed := 0
            while (lastStep < steps && elapsed < this._fadeTime) {
                elapsed := TickCount() - startTime
                step := Round((elapsed * steps) / this._fadeTime)
                if (step > lastStep) {
                    if (step < steps) {
                        this.ApplyStepRatio(step / steps)
                    }
                    else {
                        break
                    }
                    if (this.Opacity < 0 || !(this.Opacity < 255)) {
                        break
                    }
                    lastStep := step
                }
                PreciseSleep(1)
            }
            this.ApplyStepRatio(1)
        }
        else {
            this.Display(delay)
        }
    }

    /**
     * Hide toast with fade out effect
     * @param {Integer} stepFrequency Number of steps per second for fading out
     */
    FadeOut(stepFrequency := this.StepFrequency) {
        if (stepFrequency > 0) {
            steps := Round((stepFrequency * this._fadeTime) / 1000),
            lastStep := 0,
            startTime := TickCount(),
            elapsed := 0
            while (lastStep < steps && elapsed < this._fadeTime) {
                elapsed := TickCount() - startTime
                step := Round((elapsed * steps) / this._fadeTime)
                if (step > lastStep) {
                    if (step < steps) {
                        this.ApplyStepRatio((steps - step) / steps)
                    }
                    else {
                        break
                    }
                    if (this.Opacity < 0 || !(this.Opacity < 255)) {
                        break
                    }
                    lastStep := step
                }
                PreciseSleep(1)
            }
        }
        this.Hide()
    }

    /**
     * Hide and destroy toast GUI
     */
    Hide() {
        if (this._gui is Gui) {
            this._gui.Hide()
            this._guiText := ""
            this._guiTitle := ""
            this._gui.Destroy()
            this._gui := ""
        }
        if (this._hideFunc is Func) {
            SetTimer(this._hideFunc, 0)
            this._hideFunc := ""
        }
    }

    Move(x?, y?, w?, h?) {
        if (this._gui is Gui) {
            winDelay := A_WinDelay
            SetWinDelay(0)
            WinMove(x?, y?, w?, h?, this.Hwnd)
            SetWinDelay(winDelay)
        }
    }
}