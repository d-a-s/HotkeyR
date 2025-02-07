#v::
run, %gvim%,,, pid
WinWait ahk_pid %pid%
WinActivate ahk_pid %pid%
return


#IfWinActive ahk_class CabinetWClass

!c::
file := expWinGetSel()
;controlList()
;ToolTip, %file%
Clipboard:=file
return

!t::
cwd := expWinGetSel(2)
exe := "c:\WINDOWS\system32\cmd.exe"
run, %exe%, %cwd%
return

!p::
cwd := expWinGetSel(2)
exe := "c:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe"
run, %exe%, %cwd%
return

!r::
cwd := expWinGetSel(2)
file := expWinGetSel(1)
run, %gvim% "%file%", %dir%
return

#IfWinActive

; types: 0=any, 1=file, 2=dir
expWinGetSel(type:=0) {
    (!hWnd) && hWnd := WinExist("A")
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
    activeTab := 0
    ControlGet, activeTab, Hwnd, , ShellTabWindowClass1, ahk_id %hwnd%

    for oWin in ComObjCreate("Shell.Application").Windows {
        if (oWin.HWND != hWnd) {
            continue
        }
        if activeTab {
            shellBrowser := ComObjQuery(oWin, IID_IShellBrowser, IID_IShellBrowser)
            ;tab := shellBrowser.GetWindow()
            fnum := NumGet(NumGet(shellBrowser + 0), 3 * A_PtrSize)
            DllCall(fnum, "ptr", shellBrowser, "uint*", thisTab)
            thisHex := Trim(Format("{:#x}", thisTab))
            match := thisHex = activeTab ? 1 : 0
            Log("checking for active tab: " hWnd "|" oWin.LocationURL "|" activeTab "|" thisHex "|" match)
            ;ComCall(3, shellBrowser, "uint*", &thisTab := 0)
            if (match)
                break
        }
        else {
            Log("no tabs?: " hWnd "|" oWin.LocationURL "|" activeTab "|")
            break
        }
    }

    sel := oWin.Document.SelectedItems
    Log("selected # " sel.Count)
    for o in sel {
        p := o.path
        if(type = 2 and o.isFolder) {
          Log("selecting folder: " p)
          return p
        }
        if(type = 1 and !o.isFolder) {
          Log("selecting file: " p)
          return p
        }
        if(type = 0){
          Log("selecting any: " p)
          return p
        }
    }
    if(type = 1) {
      Log("no file selected")
      return
    }

    windowPath := oWin.LocationURL
    windowPath := RegExReplace(windowPath, "^file:///", "")
    windowPath := StrReplace(windowPath, "/", "\")
    windowPath := RegExReplace(windowPath, "%20", " ")
    Log("active dir: " windowPath)
    return windowPath
}
