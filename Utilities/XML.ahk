#Requires AutoHotkey v2.0

class XML {
    _xDocument := ""
    __New(data) {
        this._xDocument := XML.loadXML(data)
    }

    static loadXML(data)
    {
        o := ComObject("MSXML2.DOMDocument.6.0")
        o.async := false
        o.loadXML(data is VarRef ? %data% : data)
        return o
    }
}