#Requires AutoHotkey v2.0
#Include JSON.ahk
/**
 * Given a hotkey, return true if all related key states are also true
 * @param {String} hk
 * @param {String} Mode
 * @returns {true|false}
 */
GetHotKeyState(hk, Mode?) {
    if (RegExMatch(hk, "^(?:(?:[<>*~$]|(?<ctrl>\^)|(?<alt>!)|(?<shift>\+)|(?<win>#))*)(?<key1>(?:[A-Za-z0-9_]+)|.)(?:\s+&\s+(?<key2>(?&key1)))?$", &matchInfo)) {
        keys := []
        if (matchInfo.ctrl) {
            keys.Push("Ctrl")
        }
        if (matchInfo.alt) {
            keys.Push("Alt")
        }
        if (matchInfo.shift) {
            keys.Push("Shift")
        }
        if (matchInfo.win) {
            keys.Push("Win")
        }
        if (matchInfo.key1) {
            keys.Push(matchInfo.key1)
        }
        if (matchInfo.key2) {
            keys.Push(matchInfo.key2)
        }
        for (key in keys) {
            keyState := false
            if (key = "Win") {
                keyState := GetKeyState("LWin", Mode ?? unset) || GetKeyState("RWin", Mode ?? unset)
            }
            else {
                keyState := GetKeyState(key, Mode ?? unset)
            }

            if (!keyState) {
                return false
            }
        }
        return true
    }
    return false
}