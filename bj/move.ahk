workheight() {
    SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
    return %MonitorWorkAreaBottom%
}
workwidth() {
    SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
    return %MonitorWorkAreaRight%
}

#k::
#UP::
WinGetActiveStats, AT, AW, AH, AX, AY
WinMove, %AT%, , %AX%, 0
return

#h::
#LEFT::
WinGetActiveStats, ATitle, AWidth, AHeight, AX, AY
WinMove, %ATitle%, , 0, %AY%
return

#j::
#DOWN::
WinGetActiveStats, ATitle, AWidth, AHeight, AX, AY
NewAY := workheight() - AHeight
WinMove, %ATitle%, , %AX%, %NewAY%
return

#l::
#RIGHT::
WinGetActiveStats, ATitle, AWidth, AHeight, AX, AY
NewAX := a_screenwidth - AWidth
WinMove, %ATitle%, , %NewAX%, %AY%
return

#1::
;random xr,0,80
;WinMove,A,,80+xr,0,900,872
AY = 0
NewAHeight := workheight() - AY
AX = 80
NewAWidth := a_screenwidth - AX
NewAWidth := 1280
WinMove, a, , %AX%, %AY%, %NewAWidth%, %NewAHeight%
return

#2::
random xr, -50, 50
WinMove, A, , 200 + xr, 150 + xr, 1100, 600
return

#3:: WinMove, A, , a_screenwidth - 900, workheight() - 550, 900, 550
#4:: WinMove, A, , , , , workheight() / 2 - 14
#5:: WinMove, A, , , , a_screenwidth / 2,