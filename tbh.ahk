#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

; ==========================
; VARIÁVEIS
; ==========================
global stashes := Map()
global selectedStashes := []
global selectedHours := []
global manualHours := []
global ultimaExecucao := ""
global manualGuiItems := []
global manualY := 170

; ==========================
; IMAGENS
; ==========================
stashLinks := [
    "https://github.com/Lovattows/tbh/blob/main/stash1.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash2.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash3.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash4.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash5.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash6.png?raw=true",
    "https://github.com/Lovattows/tbh/blob/main/stash7.png?raw=true"
]

btnImg := A_Temp "\btn.png"
bgImg := A_Temp "\background.png"

Loop 7
{
    path := A_Temp "\stash" A_Index ".png"
    stashes[A_Index] := path
    Download(stashLinks[A_Index], path)
}

Download(
    "https://raw.githubusercontent.com/Lovattows/tbh/main/btn.png",
    btnImg
)

Download(
    "https://raw.githubusercontent.com/Lovattows/tbh/main/background.png",
    bgImg
)

OnExit LimparArquivos

; ==========================
; GUI PRINCIPAL
; ==========================
myGui := Gui("+AlwaysOnTop -Resize", "AUTOLOOT TASKBARHERO")
myGui.SetFont("s10", "Segoe UI")

centerGui(gui, w, h)
{
    x := (A_ScreenWidth - w) // 2
    y := (A_ScreenHeight - h) // 2
    gui.Show("x" x " y" y " w" w " h" h)
}

; ==========================
; BAÚS
; ==========================
leftY := 20
lineH := 26

myGui.Add("Text", "x20 y" leftY " w200", "BAÚS")
leftY += lineH

stashChecks := []
Loop 7
{
    stashChecks.Push(
        myGui.Add("CheckBox", "x20 y" leftY " w200", "Baú " A_Index)
    )
    leftY += lineH
}

; ==========================
; HORÁRIOS FIXOS
; ==========================
hourPairs := [
    ["01:00", "13:00"],
    ["04:00", "16:00"],
    ["07:00", "19:00"],
    ["10:00", "22:00"]
]

myGui.Add("Text", "x260 y20 w200", "HORÁRIOS")

hourChecks := []

y := 50
xLeft := 260
xRight := 340

for pair in hourPairs
{
    hourChecks.Push(myGui.Add("CheckBox", "x" xLeft " y" y " w80", pair[1]))
    hourChecks.Push(myGui.Add("CheckBox", "x" xRight " y" y " w80", pair[2]))
    y += lineH
}

allHours := []
for pair in hourPairs
{
    allHours.Push(pair[1])
    allHours.Push(pair[2])
}

; ==========================
; HORÁRIOS MANUAIS
; ==========================
manualY := y + 20

myGui.Add("Text", "x260 y" manualY " w200", "ADICIONAR HORÁRIO")
manualY += 22

manualInput := myGui.Add("Edit", "x260 y" manualY " w80")

btnAdd := myGui.Add("Button", "x350 y" manualY - 2 " w90", "Adicionar")
btnAdd.OnEvent("Click", AddHour)

manualY += 30

myGui.Add("Text", "x260 y" manualY " w200", "MANUAIS")
manualY += 20

; ==========================
; ADD HOUR (COM ALERTA TOPMOST)
; ==========================
AddHour(*)
{
    global manualInput, manualHours, btnAdd

    if (manualHours.Length >= 3)
    {
        btnAdd.Enabled := false
        return
    }

    h := Trim(manualInput.Value)
    h := RegExReplace(h, "\s+")

    ; ==========================
    ; VALIDAÇÃO 00:00 - 23:59
    ; ==========================
    if !RegExMatch(h, "^(?:[01]\d|2[0-3]):[0-5]\d$")
    {
        ShowError("Horário inválido! Use 00:00 até 23:59")
        return
    }

    for v in manualHours
        if (v = h)
            return

    manualHours.Push(h)
    manualInput.Value := ""

    UpdateManualList()

    if (manualHours.Length >= 3)
        btnAdd.Enabled := false
    else
        btnAdd.Enabled := true
}

; ==========================
; ALERTA TOPMOST (NOVO)
; ==========================
ShowError(msg)
{
    errorGui := Gui("+AlwaysOnTop +ToolWindow -SysMenu")
    errorGui.BackColor := "1E1E1E"
    errorGui.SetFont("s10 cWhite", "Segoe UI")

    errorGui.Add("Text", "w300 Center", msg)

    errorGui.Show("AutoSize Center")

    SetTimer () => errorGui.Destroy(), -1500
}

; ==========================
; UPDATE VISUAL
; ==========================
UpdateManualList()
{
    global manualHours, manualGuiItems, myGui, manualY

    for ctrl in manualGuiItems
        try ctrl.Delete()

    manualGuiItems := []

    x := 260
    y := manualY
    spacing := 60
    maxX := 420

    for h in manualHours
    {
        ctrl := myGui.Add("Text", "x" x " y" y " w60 Center", "• " h)
        manualGuiItems.Push(ctrl)

        x += spacing

        if (x > maxX)
        {
            x := 260
            y += 22
        }
    }
}

; ==========================
; BOTÃO INICIAR
; ==========================
bottomY := Max(leftY, manualY)
btnY := bottomY + 30

myGui.Add("Button", "x20 y" btnY " w420", "INICIAR").OnEvent("Click", StartScript)

guiHeight := btnY + 50
centerGui(myGui, 520, guiHeight)

; ==========================
; START
; ==========================
StartScript(*)
{
    global stashChecks, hourChecks, selectedStashes, selectedHours
    global manualHours, allHours
    global myGui, bgImg

    selectedStashes := []
    selectedHours := []

    Loop 7
        if stashChecks[A_Index].Value
            selectedStashes.Push(A_Index)

    Loop hourChecks.Length
        if hourChecks[A_Index].Value
            selectedHours.Push(allHours[A_Index])

    for h in manualHours
        selectedHours.Push(h)

    if (selectedStashes.Length = 0)
        return ShowError("Selecione pelo menos 1 baú!")

    if (selectedHours.Length = 0)
        return ShowError("Selecione pelo menos 1 horário!")

    myGui.Destroy()

    splash := Gui("-Caption +AlwaysOnTop +ToolWindow")

    splash.Add(
        "Picture",
        "x0 y0 w900 h500",
        bgImg
    )

    x := (A_ScreenWidth - 900) // 2
    y := (A_ScreenHeight - 500) // 2

    splash.Show(
        "x" x
        " y" y
        " w900 h500"
    )

    SetTimer FecharSplash, -5000

    FecharSplash()
    {
        splash.Destroy()
        SetTimer MainLoop, 1000
    }
}

; ==========================
; LOOP
; ==========================
MainLoop()
{
    global selectedHours, ultimaExecucao

    hora := FormatTime(, "HH:mm")
    hoje := FormatTime(, "yyyyMMdd")

    for h in selectedHours
    {
        if (hora = h && ultimaExecucao != hoje hora)
        {
            RotinaCompleta()
            ultimaExecucao := hoje hora
            return
        }
    }
}

; ==========================
; ROTINA
; ==========================
RotinaCompleta()
{
    global selectedStashes, stashes, btnImg

    for stashID in selectedStashes
    {
        img := stashes[stashID]

        if ImageSearch(&x1, &y1, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 " img)
        {
            MouseMove x1 + 28, y1 + 15, 0
            Sleep 100
            Click "Left"

            Sleep 2000

            if ImageSearch(&x2, &y2, 0, 0, A_ScreenWidth, A_ScreenHeight, "*30 " btnImg)
            {
                MouseMove x2 + 60, y2 + 15, 0
                Sleep 100
                Click "Left"
            }
        }

        Sleep 1000
    }
}

; ==========================
; LIMPEZA
; ==========================
LimparArquivos(*)
{
    global stashes, btnImg, bgImg

    for _, path in stashes
        try FileDelete(path)

    try FileDelete(btnImg)
    try FileDelete(bgImg)
}