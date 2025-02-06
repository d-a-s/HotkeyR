#SingleInstance, Force
if not A_IsAdmin
{
  Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
  ExitApp
}

;#NoTrayIcon
#Persistent  ; Keep the script running
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability

#include <SerDes>

#include <_HtmlWindow>
#include <_ShellRunEx>
#include <_GetWindowList>
#include <_GetWindowIcon>

SetWorkingDir %A_ScriptDir%

g_appName := "HotkeyR"
g_tempFolder := A_Temp "\" g_appName

FileCreateDir, % g_tempFolder
FileDelete, %g_tempFolder%\*.ico

g_lastActivatedHwnd := {}
g_hotkeyProgramMap := {}
g_iconCache := {}
g_altPressed := false
g_index := 0

log(txt) {
  ; global g_tempFolder
  ; logfile := g_tempFolder "\log.txt"
  logfile := "log.txt"
  FormatTime, currentTime,, yyyy-MM-dd HH:mm:ss
  logTxt := currentTime ": " txt
  FileAppend, %logTxt% `n, %logfile%
}

toggleTop(hwnd)
{
  log("toggle top: " hwnd " | " e.target)
  global g_webBrowser

  w := g_webBrowser.document.parentWindow

  WinGet, ExStyle, ExStyle, ahk_id %hwnd%
  if (ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST
    WinSet, AlwaysOnTop, Off, ahk_id %hwnd%

    w.jQuery("#tr_" hwnd " .topmost-btn").removeClass("red lighten-2").addClass("grey lighten-3")
  } else {
    WinSet, AlwaysOnTop, On, ahk_id %hwnd%

    w.jQuery("#tr_" hwnd " .topmost-btn").removeClass("grey lighten-3").addClass("red lighten-2")
  }
}

activateWnd(hwnd)
{
  log("activating: " hwnd)
  WinActivate, ahk_id %hwnd%
  updateUI(hwnd)
}

activateIndex(idx)
{
  global g_winList
  log("activating: " idx)
  w := g_winList[idx+1].hwnd

  ; keys := g_winList.GetKeys()
  ; log("keys: " keys)
  ; w := keys[idx]
  log("getting hwnd via index: " w)
  activateWnd(w)
}

updateUI(hwnd) {

  global g_webBrowser
  global g_winList
  global g_index

  ; Remove active window class name from previous active window
  trList := g_webBrowser.document.parentWindow.jQuery("#tbody tr")
  ;for i, tr in trList {
  Loop, % trList.length {
    i := A_Index - 1
    tr := trList[i]
    if(!tr)
      continue
    ;log("loop tr: " i " |id " tr.id " |cls " tr.className " |gi " g_index)
    if(not hwnd and tr.className = "activeWindow") {
      ;log("setting hwnd " tr.id)
      hwnd := SubStr(tr.id, 4)
      continue
    }
    if(tr.id = "tr_" . hwnd) {
      tr.className := "activeWindow"
      continue
    }
    if(i = g_index ) {
      tr.className := "highlight-orange"
      continue
    }
    tr.className := ""
  }
  ;log("hwnd " hwnd)
  ;g_webBrowser.document.getElementById("tr_" hwnd).className := "activeWindow"
}

isTargetWindowActive() {
  global GuiHwnd
  id := "ahk_id " GuiHwnd
  WinGet, isVisible, MinMax, %id%
  if (isVisible = 0){
    log(id " - exists, visible " isVisible)
    return true
  }
  log(id " - not exist " isVisible)
  return false
}

^!r::
  Suspend Permit
  Reload
return

^!x::exitApp

~Alt::
  g_index := 0
return

~Alt Up::
  if(1 or isTargetWindowActive()) {
    hw_hide()
    if(g_index>=1){
      activateIndex(g_index)
    }
  }
return

!Tab::paint_list(1)
!+Tab::paint_list(-1)

#If isTargetWindowActive()
  !1::changeIndex(0,0)
  !2::changeIndex(0,1)
  !3::changeIndex(0,2)
  !4::changeIndex(0,3)
  !5::changeIndex(0,4)
  !6::changeIndex(0,5)
  !7::changeIndex(0,6)
  !8::changeIndex(0,7)
  !9::changeIndex(0,8)
#If

paint_list(offset)
{
  global g_index
  global g_winList
  global g_webBrowser
  global g_iconCache
  global g_tempFolder
  global hw_height
  if (!isTargetWindowActive()) {

    while ( not hw_isReady() ) {
      sleep 50
    }

    Critical
    g_winList := getWindowList()
    Critical off

    updateTbody()

    sleep 10
    log("heights: |hw: " hw_height " |web: " g_webBrowser.document.body.offsetHeight)
    hw_height := g_webBrowser.document.body.offsetHeight

    changeIndex(offset)
    hw_show()

    for i, v in g_winList
    {
      if g_iconCache.HasKey(v.hwnd)
        continue

      iconFile := "icon_" . v.hwnd . ".ico"
      iconPath := g_tempFolder . "\" . iconFile
      ; log(iconPath . " | " . i . " | " . v.hwnd)
      SaveWindowIcon( v.hwnd, iconPath)
      g_webBrowser.document.getElementById("icon_" v.hwnd).src := iconPath
      g_iconCache[v.hwnd] := iconPath
    }
    log("paint list win-create end")
  }
  else {
    changeIndex(offset)
  }
}

changeIndex(offset, abs:=false) {
  global g_index
  global g_winList
  winCnt := g_winList.Count()
  ;log("index old: " g_index " | " offset " | " winCnt)
  if (!g_index)
    g_index := 0
  if(abs ~= "^\d+$" and abs > 0){
    g_index := abs + offset
  } else {
    g_index := g_index+offset
  }
  if(g_index < 0)
    g_index:= winCnt-1
  if(g_index > winCnt)
    g_index := 1
  log("index: " g_index " | " offset " | " winCnt)

  updateUI(false)
}
return

updateTbody() {
  global GuiHwnd
  global g_winList
  global g_iconCache
  global g_webBrowser
  global g_tempFolder

  ; Update web page
  tbody =
  for i, v in g_winList {
    if (v.hwnd = GuiHwnd) {
      continue
    }

    key := SubStr(v.processName, 1, 1)
    StringUpper, key, key

    hwnd := v.hwnd
    ; msgbox % hwnd
    processName := v.processName
    title := v.title
    toggleTopColor := v.onTop ? "red lighten-2" : "grey lighten-3"
    if g_iconCache.HasKey(hwnd)
      iconSrc = %g_tempFolder%\icon_%hwnd%.ico
    else
      iconSrc = images/loading-spinner-grey.gif
    activeWindow := v.isActive ? "activeWindow" : ""
    ows = onclick="AHK('activateWnd', '%hwnd%')"
    row =
    (
      <tr id="tr_%hwnd%" %ows% class="%activeWindow%">
        <td><img class="icon" id="icon_%hwnd%" src="%iconSrc%"></td>
        <td><span class="key">%i%</span></td>
        <td>%processName%</td>
        <td class="winTitle">%title%</td>
        <td><a class="topmost-btn btn-flat %toggleTopColor%"
          onclick="AHK('toggleTop', '%hwnd%')">
          <i class="material-icons">vertical_align_top</i>
        </a></td>
      </tr>
    )
    ; log("creating row: " row)
    tbody .= row
  }

  g_webBrowser.document.getElementById("tbody").innerHTML := tbody
}

#include %A_ScriptDir%\bj\move.ahk
