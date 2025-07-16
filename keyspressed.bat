@findstr/v "^@f.*&" "%~f0"|powershell -WindowStyle hidden -&goto:eof

# above line is magic to interpret the rest of the code as powershell

# basic logic from here
# https://powershell.one/tricks/input-devices/detect-key-press

$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
'@
Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi

# use a buffer of 5 characters, initialized with numbers

$global:buffer = "                                                              "
Write-Host "KeyPressed is running!" -ForegroundColor Green

# Create a Windows Form to display the buffer
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.TopMost = $true
$form.StartPosition = "Manual"
$form.Width = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width 
$form.Height = 100

$form.Location = New-Object System.Drawing.Point(0, ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height - $form.Height))
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Text = $global:buffer
$textbox.AutoSize = $false
$textbox.Dock = [System.Windows.Forms.DockStyle]::Fill
$textbox.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
$textbox.SelectionStart = $textbox.Text.Length
$form.Controls.Add($textbox)

$form.Add_Shown({$form.Activate()})
$form.Show()


# Function to update the Windows Form textbox
function Update-FormBuffer {
    param (
        [string]$buffer
    )
    $textbox.Text = $buffer
    $textbox.SelectionStart = $textbox.Text.Length
    $form.Refresh()
}

function Get-UTF8 {
    param (
        [int]$codePoint
    )

    # Convert the code point to a character
    $char = [char]$codePoint

    # Get the string representation of the character using UTF-8 encoding
    $letter = [System.Text.Encoding]::GetEncoding('UTF-8').GetString([System.Text.Encoding]::UTF8.GetBytes($char))

    return $letter
}

$bkspc  = Get-UTF8(0x232B) # ⌫
$enter = Get-UTF8(0x23ce) # ⏎
$left = Get-UTF8(0x2190) # ←
$up = Get-UTF8(0x2191) # ↑
$right = Get-UTF8(0x2192) # →
$down = Get-UTF8(0x2193) # ↓
$win = Get-UTF8(0x229E) # ⊞
$tab = Get-UTF8(0x2B7E) # ⭾
$agrave = Get-UTF8(0xe0) # à
$eacute = Get-UTF8(0xE9) # é
$para = Get-UTF8(0xa7) # §
$egrave = Get-UTF8(0xe8) # è
$frenchc = Get-UTF8(0xe7) # ç
$ugrave = Get-UTF8(0xf9) # ù
$mu = Get-UTF8(0xb5) # µ
$squared = Get-UTF8(0xb2) # ²
$shifttabb = (Get-UTF8(0x21e7))+(Get-UTF8(0x2b7e)) # ⇧⭾
$degree = Get-UTF8(0xb0) # °
$pound = Get-UTF8(0xa3) # £
$umlaut = Get-UTF8(0xa8) # ¨
$cubed = Get-UTF8(0xb3) # ³
$euro = Get-UTF8(0x20ac) # €
$tick = Get-UTF8(0xb4) # ´

# List of ASCII codes that will be listened to
$list = @(8, 9, 13, 27)+@(32..128)+@(186..192)+@(219..226)
# $list = 32..512
$hit = @(-32767,-32768)
# endless loop monitoring keypresses
do {
    foreach ($_ in $list) {
        $pressed = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($_) -eq -32767)
        if ($pressed) {
            
            # Write-Host $_
            
            $shiftPressed = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(16) -in $hit) -or
                [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(160) -in $hit) -or
                [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(161) -in $hit) -or
                [console]::CapsLock

            $ctrlPressed = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(162) -in $hit)  -or
                [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(163) -in $hit)

            $altPressed = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(164) -in $hit) -or
                [bool]([PsOneApi.Keyboard]::GetAsyncKeyState(165) -in $hit)

            # convert ascii to character
            $letter = [char]$_

            # Check if Shift key is pressed
            if (-not $shiftPressed) {
                $letter = $letter.ToString().ToLower()
            }

            Switch ($_){
                8 {$letter = $bkspc} # ⌫
                13 {$letter = $enter} # ⏎
                27 {$letter = "Esc"}
                33 {$letter = "PgUp"}
                34 {$letter = "PgDn"}
                35 {$letter = "End"}
                36 {$letter = "Home"}
                37 {$letter = $left} # ←
                38 {$letter = $up} # ↑
                39 {$letter = $right} # →
                40 {$letter = $down} # ↓
                46 {$letter = "Del"}
                91 {$letter = $win} # ⊞
            }
            
            if ($ctrlPressed) { $letter = "Ctrl+$letter" }
            if ($altPressed) { $letter = "Alt+$letter" }
            
            if ($_ -in @(48..59)+@(186..192)+@(9, 219, 220, 221, 222, 226)) {
                if  (-not $shiftPressed) {
                    Switch ($_) {
                        9 {$letter = $tab} # ⭾
                        48 {$letter = $agrave} # à
                        49 {$letter = "&"}
                        50 {$letter = $eacute} # é
                        51 {$letter = '"'}
                        52 {$letter = "'"}
                        53 {$letter = "("}
                        54 {$letter = $para} # §
                        55 {$letter = $egrave} # è
                        56 {$letter = "!"}
                        57 {$letter = $frenchc} # ç
                        186 {$letter = "$"}
                        187 {$letter = "="}
                        188 {$letter = ","}
                        189 {$letter = "-"}
                        190 {$letter = ";"}
                        191 {$letter = ":"}
                        192 {$letter = $ugrave} # ù
                        219 {$letter = ")"}
                        220 {$letter = $mu} # µ
                        221 {$letter = "^"}
                        222 {$letter = $squared} # ²
                        226 {$letter = "<"}
                    }
                } else {
                    Switch ($_){
                        9 {$letter = $shifttab} # ⇧⭾
                        186 {$letter = "*"}
                        187 {$letter = "+"}
                        188 {$letter = "?"}
                        189 {$letter = "_"}
                        190 {$letter = "."}
                        191 {$letter = "/"}
                        192 {$letter = "%"}
                        219 {$letter = $degree} # °
                        220 {$letter = $pound} # £
                        221 {$letter = $umlaut} # ¨
                        222 {$letter = $cubed} # ³
                        226 {$letter = ">"}
                    }
                }
            }
       
            if ($altPressed -and $ctrlPressed){
                Switch ($_){
                    48 {$letter="}"}
                    49 {$letter="|"}
                    50 {$letter="@"}
                    51 {$letter="#"}
                    54 {$letter="^"}
                    57 {$letter="{"}
                    69 {$letter=$euro} # €
                    186 {$letter="]"}
                    187 {$letter="~"}
                    192 {$letter=$tick} # ´
                    220 {$letter='`'}
                    221 {$letter="["}
                    226 {$letter="\"}
                }
            }

            if ($letter.Length -gt 2){
                if ($global:buffer[-1] -eq " ") {
                    $letter += " "
                } else {
                    $letter = " $letter "
                }
            } 

            $global:buffer = $global:buffer.Substring($letter.Length) + $letter
           
            
            # special letter sequence to stop the script
            $last5 = $global:buffer[-5..-1] -join ""
            $mu5 = "$mu$mu$mu$mu$mu"
            if ($last5 -eq $mu5){ #  "µµµµµ"
                Exit
            } 
            
            # Update the Windows Form textbox
            Update-FormBuffer $global:buffer 
        }
    }

    Start-Sleep -Milliseconds 50

} while ($true)

Write-Host "Done" # This line is essential, otherwise the batch script will quit early
