# Generates the Avalon launcher icons from assets/branding/new_app_icon.png.
#
# The source is a 1254 px mockup: the artwork sits inside a rounded square on a
# white plate. Rather than guessing the plate's corner radius (it is a squircle,
# so a circular clip always leaves either white or a bitten corner), the white
# plate is flood-filled away from the outside and the artwork keeps its own
# outline. Every icon is then drawn edge to edge inside its own mask:
#
#   legacy    the artwork, exactly as supplied, filling a rounded square
#   round     the same artwork cropped to a circle (the platform crops corners)
#   adaptive  the artwork at 72/108, the area Android guarantees is visible, so
#             no launcher shape can crop the picture; the navy background layer
#             fills the corner wedges the artwork's own rounding leaves open
#   splash    the artwork on the navy plate for the native launch screen
param(
    # Defaults write straight into the project, so the command is simply
    #   powershell -File tool/make_icons.ps1
    [string]$Source = (Join-Path $PSScriptRoot '..\assets\branding\new_app_icon.png'),
    [string]$OutDir = (Join-Path $PSScriptRoot '..\android\app\src\main\res')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$navy = [System.Drawing.Color]::FromArgb(255, 4, 16, 29)   # #04101D, avalon_launcher_background

$src = [System.Drawing.Bitmap]::FromFile($Source)
$w = $src.Width
$h = $src.Height

# Read the whole source once: GetPixel over 1.5M pixels takes minutes.
$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$data = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$px = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)
$src.UnlockBits($data)

function PixelIndex([int]$x, [int]$y) { $y * $stride + $x * 4 }
function Is-Light([int]$i) { ($px[$i] -ge 170) -and ($px[$i + 1] -ge 170) -and ($px[$i + 2] -ge 170) }

# Flood fill the plate from the border. Only cells that are light *and* reachable
# from outside belong to the white plate, so a bright highlight inside the art is
# never erased.
$outside = New-Object 'bool[]' ($w * $h)
$stack = New-Object 'System.Collections.Generic.Stack[int]'
for ($x = 0; $x -lt $w; $x++) {
    foreach ($y in @(0, ($h - 1))) {
        if ((Is-Light (PixelIndex $x $y)) -and -not $outside[$y * $w + $x]) { $stack.Push(($y * $w + $x)) }
    }
}
for ($y = 0; $y -lt $h; $y++) {
    foreach ($x in @(0, ($w - 1))) {
        if ((Is-Light (PixelIndex $x $y)) -and -not $outside[$y * $w + $x]) { $stack.Push(($y * $w + $x)) }
    }
}
while ($stack.Count -gt 0) {
    $p = $stack.Pop()
    if ($outside[$p]) { continue }
    $x = $p % $w
    $y = [math]::Floor($p / $w)
    if (-not (Is-Light (PixelIndex $x $y))) { continue }
    $outside[$p] = $true
    if ($x -gt 0) { $stack.Push($p - 1) }
    if ($x -lt $w - 1) { $stack.Push($p + 1) }
    if ($y -gt 0) { $stack.Push($p - $w) }
    if ($y -lt $h - 1) { $stack.Push($p + $w) }
}

# The plate's edge is antialiased: two pixels of the artwork are given up so the
# icon edge is art, not a pale rim.
for ($pass = 0; $pass -lt 2; $pass++) {
    $grown = $outside.Clone()
    for ($y = 1; $y -lt $h - 1; $y++) {
        for ($x = 1; $x -lt $w - 1; $x++) {
            $i = $y * $w + $x
            if ($outside[$i]) { continue }
            if ($outside[$i - 1] -or $outside[$i + 1] -or $outside[$i - $w] -or $outside[$i + $w]) { $grown[$i] = $true }
        }
    }
    $outside = $grown
}

# The square the artwork occupies.
$minX = $w; $minY = $h; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        if (-not $outside[$y * $w + $x]) {
            if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$artSide = [math]::Max(($maxX - $minX + 1), ($maxY - $minY + 1))
$artX = [int](($minX + $maxX + 1 - $artSide) / 2)
$artY = [int](($minY + $maxY + 1 - $artSide) / 2)
"artwork square: ${artSide}px at ($artX,$artY) in the ${w}px source"

# One clean tile: the artwork with the plate gone and its own outline kept.
$tile = New-Object System.Drawing.Bitmap($artSide, $artSide, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$tdata = $tile.LockBits((New-Object System.Drawing.Rectangle(0, 0, $artSide, $artSide)), [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$tstride = $tdata.Stride
$tp = New-Object byte[] ($tstride * $artSide)
for ($y = 0; $y -lt $artSide; $y++) {
    $sy = $artY + $y
    for ($x = 0; $x -lt $artSide; $x++) {
        $sx = $artX + $x
        if ($sx -lt 0 -or $sy -lt 0 -or $sx -ge $w -or $sy -ge $h) { continue }
        if ($outside[$sy * $w + $sx]) { continue }
        $si = PixelIndex $sx $sy
        $ti = $y * $tstride + $x * 4
        $tp[$ti] = $px[$si]
        $tp[$ti + 1] = $px[$si + 1]
        $tp[$ti + 2] = $px[$si + 2]
        $tp[$ti + 3] = 255
    }
}
[System.Runtime.InteropServices.Marshal]::Copy($tp, 0, $tdata.Scan0, $tp.Length)
$tile.UnlockBits($tdata)

function New-Icon {
    param(
        [int]$Pixels,
        [double]$ArtScale,   # fraction of the canvas the artwork covers
        [string]$Shape,      # 'rounded' | 'circle' | 'plate'
        [string]$Path
    )

    $bmp = New-Object System.Drawing.Bitmap($Pixels, $Pixels, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $side = $Pixels * $ArtScale
    $off = ($Pixels - $side) / 2
    $dest = New-Object System.Drawing.RectangleF($off, $off, $side, $side)
    $source = New-Object System.Drawing.RectangleF(0, 0, $artSide, $artSide)

    if ($Shape -eq 'plate') {
        # The launch screen: the art on a full navy tile. The window background is
        # the same navy, so the bitmap has no edge of its own.
        $g.Clear($navy)
        $g.DrawImage($tile, $dest, $source, [System.Drawing.GraphicsUnit]::Pixel)
    }
    elseif ($Shape -eq 'circle') {
        $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
        $clip.AddEllipse(0, 0, $Pixels, $Pixels)
        $g.SetClip($clip, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        $g.DrawImage($tile, (New-Object System.Drawing.RectangleF(0, 0, $Pixels, $Pixels)), $source, [System.Drawing.GraphicsUnit]::Pixel)
        $g.ResetClip()
        $clip.Dispose()
    }
    else {
        # The artwork is its own mask: it already carries the supplied outline.
        $g.DrawImage($tile, $dest, $source, [System.Drawing.GraphicsUnit]::Pixel)
    }

    $g.Dispose()
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "{0,-56} {1}x{1}" -f ((Split-Path -Leaf $dir) + '\' + (Split-Path -Leaf $Path)), $Pixels
}

$densities = @(
    @{ Name = 'mdpi';    Legacy = 48;  Fore = 108 },
    @{ Name = 'hdpi';    Legacy = 72;  Fore = 162 },
    @{ Name = 'xhdpi';   Legacy = 96;  Fore = 216 },
    @{ Name = 'xxhdpi';  Legacy = 144; Fore = 324 },
    @{ Name = 'xxxhdpi'; Legacy = 192; Fore = 432 }
)

foreach ($d in $densities) {
    New-Icon -Pixels $d.Legacy -ArtScale 1.00 -Shape 'rounded' -Path "$OutDir\mipmap-$($d.Name)\avalon_launcher.png"
    New-Icon -Pixels $d.Legacy -ArtScale 1.00 -Shape 'circle'  -Path "$OutDir\mipmap-$($d.Name)\avalon_launcher_round.png"
    # 72 of the 108 dp the launcher reserves is guaranteed to be visible. Fitting
    # the whole picture into that square means no mask can crop it.
    New-Icon -Pixels $d.Fore   -ArtScale (72 / 108) -Shape 'rounded' -Path "$OutDir\mipmap-$($d.Name)\avalon_launcher_foreground.png"
}

# The native launch screen: the artwork centred on the navy plate. One file for
# every density; `drawable-nodpi` is drawn at its intrinsic 512 px and the
# bitmap is centred by the layer list.
New-Icon -Pixels 512 -ArtScale 0.86 -Shape 'plate' -Path "$OutDir\drawable-nodpi\avalon_splash.png"

$tile.Dispose()
$src.Dispose()
