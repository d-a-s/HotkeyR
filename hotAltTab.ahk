#SingleInstance, Force
;#NoTrayIcon
#Persistent  ; Keep the script running
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability

#include <Optimize>
#include <SerDes>
#include <RunAsAdmin>

#include <_HtmlWindow>
#include <_ShellRunEx>
#include <_GetWindowList>
#include <_GetWindowIcon>

RunAsAdmin()

; Thread, interrupt, 0  ; IMPORTANT: Make all threads always-interruptible

SetWorkingDir %A_ScriptDir%
SetCapsLockState, AlwaysOff

BEEP_FILE = %A_ScriptDir%\Resources\Beep.wav
APP_NAME = HotkeyR
TEMP_FOLDER = %A_Temp%\HotkeyR

FileCreateDir % TEMP_FOLDER
FileDelete %TEMP_FOLDER%\*.ico

; msgbox % TEMP_FOLDER

g_lastActivatedHwnd := {}
g_hotkeyProgramMap := {}
g_iconCache := {}
g_altPressed := false
g_winShown := false
g_index := 0

log(txt) {
  global TEMP_FOLDER
  logfile := TEMP_FOLDER "\log.txt"
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

^!r::
  Suspend Permit
  Reload
return

^!x::exitApp

~Alt::
  g_index := 0
return

~Alt Up::
  if(g_winShown) {
    g_winShown := false
    hw_hide()
    if(g_index>1){
      activateIndex(g_index)
    }
  }
return

!Tab::paint_list(1)
!+Tab::paint_list(-1)

paint_list(offset)
{
  global g_index
  global g_winList
  global g_webBrowser
  global g_iconCache
  global TEMP_FOLDER
  global g_winShown

  if (!g_winShown) {

    while ( not hw_isReady() ) {
      sleep 50
    }

    Critical
    g_winList := getWindowList()
    Critical off

    updateTbody()

    sleep 10
    hw_show()

    for i, v in g_winList
    {
      ;if (not g_winShown) break

      if g_iconCache.HasKey(v.hwnd)
        continue

      iconFile := "icon_" . v.hwnd . ".ico"
      iconPath := TEMP_FOLDER . "\" . iconFile
      ;log(iconFile . " | " . i . " | " . v.hwnd)
      SaveWindowIcon( v.hwnd, iconPath)
      g_webBrowser.document.getElementById("icon_" v.hwnd).src := iconPath
      g_iconCache[v.hwnd] := iconPath
    }

    ; if (!g_webBrowser.CoreWebView2){
    ;   g_webBrowser.EnsureCoreWebView2Async()
    ; }

    ; while ( not g_webBrowser.CoreWebView2 ) {
    ;   log("waiting for g_webBrowser.CoreWebView2")
    ;   sleep 100
    ; }
    ; webView.CoreWebView2.OpenDevToolsWindow()
  }
  g_winShown := true

  winCnt := g_winList.Count()
  ;log("index old: " g_index " | " offset " | " winCnt)
  if (!g_index)
    g_index := 0
  g_index := g_index+offset
  if(g_index < 0)
    g_index:= winCnt-1
  if(g_index > winCnt)
    g_index := 1
  log("index: " g_index " | " offset " | " winCnt)

  updateUI(false)
}
return

; XXX
; https://gist.github.com/be5invis/6571037
scrollPage(delta)
{
  global GuiHwnd

  ControlGet, hwndTopControl, Hwnd,,, ahk_id %GuiHwnd%

  WHEEL_DELTA := (120 << 16) * delta
  WinGetPos, x, y, width, height, ahk_id %GuiHwnd%
  mX := x + width / 2
  mY := y + height / 2

  PostMessage, 0x20A, WHEEL_DELTA, (mY << 16) | mX,,% "ahk_id " hwndTopControl
}

exitApp()
{
  ExitApp
}

aboutApp()
{
  SetTimer, onTimer, Off

  text =
  ( LTrim
    HotkeyR
    version 1.0
    rossning92@gmail.com

    The MIT License

    Copyright (c) 2017 Ross Ning

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  )
  MsgBox, 4096, About, % text
}

updateTbody() {
  global GuiHwnd
  global g_winList
  global g_iconCache
  global g_webBrowser
  global TEMP_FOLDER

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
      iconSrc = %TEMP_FOLDER%\icon_%hwnd%.ico
    else
      iconSrc = images/loading-spinner-grey.gif
    activeWindow := v.isActive ? "activeWindow" : ""
    ows = onclick="AHK('activateWnd', '%hwnd%')"
    row =
    (
      <tr id="tr_%hwnd%" %ows% class="%activeWindow%">
        <td><img class="icon" id="icon_%hwnd%" src="%iconSrc%"></td>
        <td><span class="key">%key%</span></td>
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

onTimer() {
  global GuiHwnd

  ; Reset AlwaysOnTop to keep HotkeyR front most
  WinSet, AlwaysOnTop, On, ahk_id %GuiHwnd%
}
