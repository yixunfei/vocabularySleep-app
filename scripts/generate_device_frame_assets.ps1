Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$outputDir = Join-Path $PSScriptRoot '..\assets\toolbox\device_frames'
$outputDir = [System.IO.Path]::GetFullPath($outputDir)
[System.IO.Directory]::CreateDirectory($outputDir) | Out-Null

function New-ArgbColor {
  param(
    [int]$A,
    [int]$R,
    [int]$G,
    [int]$B
  )

  return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-RoundedPath {
  param(
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [float]$Radius
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = $Radius * 2
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    $X + $Width - $diameter,
    $Y + $Height - $diameter,
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-BitmapAndGraphics {
  param(
    [int]$Width,
    [int]$Height
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)
  return @{
    Bitmap = $bitmap
    Graphics = $graphics
  }
}

function Clear-PathTransparent {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Drawing2D.GraphicsPath]$Path
  )

  $previous = $Graphics.CompositingMode
  $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Transparent)
  $Graphics.FillPath($brush, $Path)
  $brush.Dispose()
  $Graphics.CompositingMode = $previous
}

function Add-SideButton {
  param(
    [System.Drawing.Graphics]$Graphics,
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [System.Drawing.Color]$BaseColor,
    [System.Drawing.Color]$HighlightColor
  )

  $buttonRadius = [Math]::Min($Width, $Height) / 2
  $path = New-RoundedPath -X $X -Y $Y -Width $Width -Height $Height -Radius $buttonRadius
  $brush = New-Object System.Drawing.SolidBrush $BaseColor
  $Graphics.FillPath($brush, $path)
  $brush.Dispose()

  $pen = New-Object System.Drawing.Pen $HighlightColor, 2
  $Graphics.DrawPath($pen, $path)
  $pen.Dispose()
  $path.Dispose()
}

function New-ShadowBitmap {
  param(
    [int]$Width,
    [int]$Height,
    [float]$BodyX,
    [float]$BodyY,
    [float]$BodyWidth,
    [float]$BodyHeight,
    [float]$Radius
  )

  $bundle = New-BitmapAndGraphics -Width $Width -Height $Height
  $g = $bundle.Graphics
  for ($i = 20; $i -ge 1; $i--) {
    $inflate = $i * 3
    $alpha = [Math]::Max(4, 7 + $i * 3)
    $path = New-RoundedPath `
      -X ($BodyX - $inflate) `
      -Y ($BodyY + 18 + $inflate * 0.35) `
      -Width ($BodyWidth + $inflate * 2) `
      -Height ($BodyHeight + 46 + $inflate * 1.2) `
      -Radius ($Radius + $inflate * 0.85)
    $brush = New-Object System.Drawing.SolidBrush (New-ArgbColor -A $alpha -R 0 -G 0 -B 0)
    $g.FillPath($brush, $path)
    $brush.Dispose()
    $path.Dispose()
  }

  for ($i = 12; $i -ge 1; $i--) {
    $alpha = [Math]::Max(3, 6 + $i * 2)
    $brush = New-Object System.Drawing.SolidBrush (New-ArgbColor -A $alpha -R 0 -G 0 -B 0)
    $g.FillEllipse(
      $brush,
      $BodyX + 130 - $i * 12,
      $BodyY + $BodyHeight - 18 + $i * 6,
      $BodyWidth - 260 + $i * 24,
      170 + $i * 18
    )
    $brush.Dispose()
  }

  return $bundle
}

function Save-Bitmap {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$FileName
  )

  $path = Join-Path $outputDir $FileName
  $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  return $path
}

function New-IPhoneAssets {
  $width = 1400
  $height = 2880
  $bundle = New-BitmapAndGraphics -Width $width -Height $height
  $bmp = $bundle.Bitmap
  $g = $bundle.Graphics

  $bodyX = 78
  $bodyY = 84
  $bodyW = 1244
  $bodyH = 2712
  $bodyR = 176
  $screenX = 144
  $screenY = 154
  $screenW = 1112
  $screenH = 2572
  $screenR = 132

  $bodyPath = New-RoundedPath -X $bodyX -Y $bodyY -Width $bodyW -Height $bodyH -Radius $bodyR
  $metal = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.RectangleF]::new($bodyX, $bodyY, $bodyW, $bodyH),
    (New-ArgbColor 255 250 238 224),
    (New-ArgbColor 255 192 161 128),
    90
  )
  $blend = New-Object System.Drawing.Drawing2D.Blend
  $blend.Positions = [float[]](0.0, 0.18, 0.5, 0.82, 1.0)
  $blend.Factors = [float[]](0.0, 0.45, 1.0, 0.42, 0.0)
  $metal.Blend = $blend
  $g.FillPath($metal, $bodyPath)
  $metal.Dispose()

  $leftEdge = New-Object System.Drawing.SolidBrush (New-ArgbColor 52 104 72 47)
  $g.FillRectangle($leftEdge, $bodyX, $bodyY + 120, 34, $bodyH - 240)
  $g.FillRectangle($leftEdge, $bodyX + $bodyW - 34, $bodyY + 120, 34, $bodyH - 240)
  $leftEdge.Dispose()

  $outerPen = New-Object System.Drawing.Pen (New-ArgbColor 255 118 88 62), 20
  $g.DrawPath($outerPen, $bodyPath)
  $outerPen.Dispose()
  $innerPen = New-Object System.Drawing.Pen (New-ArgbColor 132 255 248 240), 4
  $innerPath = New-RoundedPath -X ($bodyX + 22) -Y ($bodyY + 20) -Width ($bodyW - 44) -Height ($bodyH - 40) -Radius ($bodyR - 20)
  $g.DrawPath($innerPen, $innerPath)
  $innerPen.Dispose()
  $innerPath.Dispose()

  $bezelPath = New-RoundedPath -X ($screenX - 14) -Y ($screenY - 14) -Width ($screenW + 28) -Height ($screenH + 28) -Radius ($screenR + 18)
  $bezelBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 12 12 13)
  $g.FillPath($bezelBrush, $bezelPath)
  $bezelBrush.Dispose()
  $bezelPath.Dispose()

  $screenPath = New-RoundedPath -X $screenX -Y $screenY -Width $screenW -Height $screenH -Radius $screenR
  Clear-PathTransparent -Graphics $g -Path $screenPath

  $islandBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 10 10 10)
  $islandPath = New-RoundedPath -X 546 -Y 178 -Width 308 -Height 74 -Radius 37
  $g.FillPath($islandBrush, $islandPath)
  $islandBrush.Dispose()
  $islandPath.Dispose()

  $cameraBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 200 39 46 55)
  $g.FillEllipse($cameraBrush, 826, 196, 28, 28)
  $g.FillEllipse($cameraBrush, 1188, 196, 24, 24)
  $cameraBrush.Dispose()

  Add-SideButton -Graphics $g -X 57 -Y 664 -Width 21 -Height 342 -BaseColor (New-ArgbColor 255 222 198 173) -HighlightColor (New-ArgbColor 70 255 245 232)
  Add-SideButton -Graphics $g -X 1322 -Y 892 -Width 22 -Height 344 -BaseColor (New-ArgbColor 255 220 192 166) -HighlightColor (New-ArgbColor 60 255 245 232)
  Add-SideButton -Graphics $g -X 1322 -Y 1298 -Width 22 -Height 336 -BaseColor (New-ArgbColor 255 220 192 166) -HighlightColor (New-ArgbColor 60 255 245 232)

  $accentBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 88 157 122 90)
  $g.FillRectangle($accentBrush, 240, 372, 68, 16)
  $g.FillRectangle($accentBrush, 1092, 372, 68, 16)
  $g.FillRectangle($accentBrush, 268, 2400, 68, 16)
  $g.FillRectangle($accentBrush, 1084, 2400, 68, 16)
  $accentBrush.Dispose()

  Save-Bitmap -Bitmap $bmp -FileName 'iphone_titanium_frame.png' | Out-Null
  $screenPath.Dispose()
  $bodyPath.Dispose()
  $g.Dispose()
  $bmp.Dispose()

  $shadowBundle = New-ShadowBitmap `
    -Width $width -Height $height `
    -BodyX $bodyX -BodyY $bodyY -BodyWidth $bodyW -BodyHeight $bodyH -Radius $bodyR
  Save-Bitmap -Bitmap $shadowBundle.Bitmap -FileName 'iphone_titanium_shadow.png' | Out-Null
  $shadowBundle.Graphics.Dispose()
  $shadowBundle.Bitmap.Dispose()

  $glareBundle = New-BitmapAndGraphics -Width $width -Height $height
  $gg = $glareBundle.Graphics
  $glareBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 48 255 255 255)
  $glarePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(118, 126),
    [System.Drawing.PointF]::new(642, 96),
    [System.Drawing.PointF]::new(1102, 516),
    [System.Drawing.PointF]::new(892, 724),
    [System.Drawing.PointF]::new(314, 422)
  )
  $gg.FillPolygon($glareBrush, $glarePoints)
  $glareBrush.Dispose()
  $arcPen = New-Object System.Drawing.Pen (New-ArgbColor 34 255 255 255), 14
  $gg.DrawArc($arcPen, 152, 166, 1092, 1640, 205, 116)
  $arcPen.Dispose()
  $framePen = New-Object System.Drawing.Pen (New-ArgbColor 26 255 255 255), 8
  $gg.DrawPath($framePen, (New-RoundedPath -X 164 -Y 174 -Width 1064 -Height 446 -Radius 160))
  $framePen.Dispose()
  Save-Bitmap -Bitmap $glareBundle.Bitmap -FileName 'iphone_titanium_glare.png' | Out-Null
  $glareBundle.Graphics.Dispose()
  $glareBundle.Bitmap.Dispose()
}

function New-IPhoneObsidianAssets {
  $width = 1400
  $height = 2880
  $bundle = New-BitmapAndGraphics -Width $width -Height $height
  $bmp = $bundle.Bitmap
  $g = $bundle.Graphics

  $bodyX = 78
  $bodyY = 84
  $bodyW = 1244
  $bodyH = 2712
  $bodyR = 176
  $screenX = 144
  $screenY = 154
  $screenW = 1112
  $screenH = 2572
  $screenR = 132

  $bodyPath = New-RoundedPath -X $bodyX -Y $bodyY -Width $bodyW -Height $bodyH -Radius $bodyR
  $metal = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.RectangleF]::new($bodyX, $bodyY, $bodyW, $bodyH),
    (New-ArgbColor 255 104 109 116),
    (New-ArgbColor 255 30 32 36),
    90
  )
  $blend = New-Object System.Drawing.Drawing2D.Blend
  $blend.Positions = [float[]](0.0, 0.18, 0.5, 0.82, 1.0)
  $blend.Factors = [float[]](0.0, 0.36, 1.0, 0.34, 0.0)
  $metal.Blend = $blend
  $g.FillPath($metal, $bodyPath)
  $metal.Dispose()

  $edgeBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 42 228 232 240)
  $g.FillRectangle($edgeBrush, $bodyX + 2, $bodyY + 120, 26, $bodyH - 240)
  $g.FillRectangle(
    $edgeBrush,
    $bodyX + $bodyW - 28,
    $bodyY + 120,
    26,
    $bodyH - 240
  )
  $edgeBrush.Dispose()

  $outerPen = New-Object System.Drawing.Pen (New-ArgbColor 255 19 20 24), 20
  $g.DrawPath($outerPen, $bodyPath)
  $outerPen.Dispose()
  $innerPen = New-Object System.Drawing.Pen (New-ArgbColor 86 245 247 250), 3
  $innerPath = New-RoundedPath -X ($bodyX + 22) -Y ($bodyY + 20) -Width ($bodyW - 44) -Height ($bodyH - 40) -Radius ($bodyR - 20)
  $g.DrawPath($innerPen, $innerPath)
  $innerPen.Dispose()
  $innerPath.Dispose()

  $bezelPath = New-RoundedPath -X ($screenX - 14) -Y ($screenY - 14) -Width ($screenW + 28) -Height ($screenH + 28) -Radius ($screenR + 18)
  $bezelBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 9 9 10)
  $g.FillPath($bezelBrush, $bezelPath)
  $bezelBrush.Dispose()
  $bezelPath.Dispose()

  $screenPath = New-RoundedPath -X $screenX -Y $screenY -Width $screenW -Height $screenH -Radius $screenR
  Clear-PathTransparent -Graphics $g -Path $screenPath

  $islandBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 5 5 6)
  $islandPath = New-RoundedPath -X 546 -Y 178 -Width 308 -Height 74 -Radius 37
  $g.FillPath($islandBrush, $islandPath)
  $islandBrush.Dispose()
  $islandPath.Dispose()

  $cameraBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 168 91 109 142)
  $g.FillEllipse($cameraBrush, 826, 196, 28, 28)
  $g.FillEllipse($cameraBrush, 1188, 196, 24, 24)
  $cameraBrush.Dispose()

  Add-SideButton -Graphics $g -X 57 -Y 664 -Width 21 -Height 342 -BaseColor (New-ArgbColor 255 67 72 78) -HighlightColor (New-ArgbColor 56 245 247 250)
  Add-SideButton -Graphics $g -X 1322 -Y 892 -Width 22 -Height 344 -BaseColor (New-ArgbColor 255 60 64 70) -HighlightColor (New-ArgbColor 56 245 247 250)
  Add-SideButton -Graphics $g -X 1322 -Y 1298 -Width 22 -Height 336 -BaseColor (New-ArgbColor 255 60 64 70) -HighlightColor (New-ArgbColor 56 245 247 250)

  $accentBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 70 108 114 122)
  $g.FillRectangle($accentBrush, 240, 372, 68, 14)
  $g.FillRectangle($accentBrush, 1092, 372, 68, 14)
  $g.FillRectangle($accentBrush, 268, 2400, 68, 14)
  $g.FillRectangle($accentBrush, 1084, 2400, 68, 14)
  $accentBrush.Dispose()

  Save-Bitmap -Bitmap $bmp -FileName 'iphone_obsidian_frame.png' | Out-Null
  $screenPath.Dispose()
  $bodyPath.Dispose()
  $g.Dispose()
  $bmp.Dispose()

  $shadowBundle = New-ShadowBitmap `
    -Width $width -Height $height `
    -BodyX $bodyX -BodyY $bodyY -BodyWidth $bodyW -BodyHeight $bodyH -Radius $bodyR
  Save-Bitmap -Bitmap $shadowBundle.Bitmap -FileName 'iphone_obsidian_shadow.png' | Out-Null
  $shadowBundle.Graphics.Dispose()
  $shadowBundle.Bitmap.Dispose()

  $glareBundle = New-BitmapAndGraphics -Width $width -Height $height
  $gg = $glareBundle.Graphics
  $glareBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 42 255 255 255)
  $glarePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(146, 140),
    [System.Drawing.PointF]::new(622, 118),
    [System.Drawing.PointF]::new(1026, 470),
    [System.Drawing.PointF]::new(862, 672),
    [System.Drawing.PointF]::new(356, 448)
  )
  $gg.FillPolygon($glareBrush, $glarePoints)
  $glareBrush.Dispose()
  $arcPen = New-Object System.Drawing.Pen (New-ArgbColor 26 255 255 255), 12
  $gg.DrawArc($arcPen, 176, 194, 1020, 1520, 210, 108)
  $arcPen.Dispose()
  Save-Bitmap -Bitmap $glareBundle.Bitmap -FileName 'iphone_obsidian_glare.png' | Out-Null
  $glareBundle.Graphics.Dispose()
  $glareBundle.Bitmap.Dispose()
}

function New-AndroidAssets {
  $width = 1400
  $height = 2880
  $bundle = New-BitmapAndGraphics -Width $width -Height $height
  $bmp = $bundle.Bitmap
  $g = $bundle.Graphics

  $bodyX = 118
  $bodyY = 96
  $bodyW = 1166
  $bodyH = 2692
  $bodyR = 146
  $screenX = 158
  $screenY = 136
  $screenW = 1086
  $screenH = 2612
  $screenR = 116

  $bodyPath = New-RoundedPath -X $bodyX -Y $bodyY -Width $bodyW -Height $bodyH -Radius $bodyR
  $shell = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.RectangleF]::new($bodyX, $bodyY, $bodyW, $bodyH),
    (New-ArgbColor 255 96 100 106),
    (New-ArgbColor 255 24 25 28),
    90
  )
  $blend = New-Object System.Drawing.Drawing2D.Blend
  $blend.Positions = [float[]](0.0, 0.15, 0.52, 0.84, 1.0)
  $blend.Factors = [float[]](0.0, 0.28, 1.0, 0.32, 0.0)
  $shell.Blend = $blend
  $g.FillPath($shell, $bodyPath)
  $shell.Dispose()

  $edgeBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 44 178 183 190)
  $g.FillRectangle($edgeBrush, $bodyX, $bodyY + 136, 28, $bodyH - 272)
  $g.FillRectangle($edgeBrush, $bodyX + $bodyW - 28, $bodyY + 136, 28, $bodyH - 272)
  $edgeBrush.Dispose()

  $outerPen = New-Object System.Drawing.Pen (New-ArgbColor 230 148 152 158), 8
  $g.DrawPath($outerPen, $bodyPath)
  $outerPen.Dispose()
  $innerPen = New-Object System.Drawing.Pen (New-ArgbColor 74 245 247 252), 2
  $innerPath = New-RoundedPath -X ($bodyX + 14) -Y ($bodyY + 14) -Width ($bodyW - 28) -Height ($bodyH - 28) -Radius ($bodyR - 18)
  $g.DrawPath($innerPen, $innerPath)
  $innerPen.Dispose()
  $innerPath.Dispose()

  $bezelPath = New-RoundedPath -X ($screenX - 8) -Y ($screenY - 8) -Width ($screenW + 16) -Height ($screenH + 16) -Radius ($screenR + 12)
  $bezelBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 8 9 10)
  $g.FillPath($bezelBrush, $bezelPath)
  $bezelBrush.Dispose()
  $bezelPath.Dispose()

  $screenPath = New-RoundedPath -X $screenX -Y $screenY -Width $screenW -Height $screenH -Radius $screenR
  Clear-PathTransparent -Graphics $g -Path $screenPath

  $holeBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 15 16 18)
  $g.FillEllipse($holeBrush, 687, 164, 70, 70)
  $holeBrush.Dispose()
  $lensBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 128 125 145 168)
  $g.FillEllipse($lensBrush, 714, 191, 16, 16)
  $lensBrush.Dispose()

  $earPen = New-Object System.Drawing.Pen (New-ArgbColor 18 255 255 255), 8
  $g.DrawLine($earPen, 566, 154, 878, 154)
  $earPen.Dispose()

  Add-SideButton -Graphics $g -X 94 -Y 742 -Width 24 -Height 318 -BaseColor (New-ArgbColor 255 92 95 99) -HighlightColor (New-ArgbColor 36 255 255 255)
  Add-SideButton -Graphics $g -X 1284 -Y 1042 -Width 24 -Height 326 -BaseColor (New-ArgbColor 255 102 105 110) -HighlightColor (New-ArgbColor 34 255 255 255)
  Add-SideButton -Graphics $g -X 1284 -Y 1412 -Width 24 -Height 352 -BaseColor (New-ArgbColor 255 102 105 110) -HighlightColor (New-ArgbColor 34 255 255 255)

  Save-Bitmap -Bitmap $bmp -FileName 'android_graphite_frame.png' | Out-Null
  $screenPath.Dispose()
  $bodyPath.Dispose()
  $g.Dispose()
  $bmp.Dispose()

  $shadowBundle = New-ShadowBitmap `
    -Width $width -Height $height `
    -BodyX $bodyX -BodyY $bodyY -BodyWidth $bodyW -BodyHeight $bodyH -Radius $bodyR
  Save-Bitmap -Bitmap $shadowBundle.Bitmap -FileName 'android_graphite_shadow.png' | Out-Null
  $shadowBundle.Graphics.Dispose()
  $shadowBundle.Bitmap.Dispose()

  $glareBundle = New-BitmapAndGraphics -Width $width -Height $height
  $gg = $glareBundle.Graphics
  $glareBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 42 255 255 255)
  $glarePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(176, 126),
    [System.Drawing.PointF]::new(734, 96),
    [System.Drawing.PointF]::new(1110, 440),
    [System.Drawing.PointF]::new(996, 618),
    [System.Drawing.PointF]::new(346, 378)
  )
  $gg.FillPolygon($glareBrush, $glarePoints)
  $glareBrush.Dispose()
  $arcPen = New-Object System.Drawing.Pen (New-ArgbColor 28 255 255 255), 12
  $gg.DrawArc($arcPen, 148, 124, 1120, 1700, 216, 102)
  $arcPen.Dispose()
  Save-Bitmap -Bitmap $glareBundle.Bitmap -FileName 'android_graphite_glare.png' | Out-Null
  $glareBundle.Graphics.Dispose()
  $glareBundle.Bitmap.Dispose()
}

function New-AndroidFrostAssets {
  $width = 1400
  $height = 2880
  $bundle = New-BitmapAndGraphics -Width $width -Height $height
  $bmp = $bundle.Bitmap
  $g = $bundle.Graphics

  $bodyX = 118
  $bodyY = 96
  $bodyW = 1166
  $bodyH = 2692
  $bodyR = 146
  $screenX = 158
  $screenY = 136
  $screenW = 1086
  $screenH = 2612
  $screenR = 116

  $bodyPath = New-RoundedPath -X $bodyX -Y $bodyY -Width $bodyW -Height $bodyH -Radius $bodyR
  $shell = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.RectangleF]::new($bodyX, $bodyY, $bodyW, $bodyH),
    (New-ArgbColor 255 243 247 252),
    (New-ArgbColor 255 184 193 206),
    90
  )
  $blend = New-Object System.Drawing.Drawing2D.Blend
  $blend.Positions = [float[]](0.0, 0.15, 0.52, 0.84, 1.0)
  $blend.Factors = [float[]](0.0, 0.24, 1.0, 0.26, 0.0)
  $shell.Blend = $blend
  $g.FillPath($shell, $bodyPath)
  $shell.Dispose()

  $edgeBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 56 255 255 255)
  $g.FillRectangle($edgeBrush, $bodyX, $bodyY + 136, 28, $bodyH - 272)
  $g.FillRectangle($edgeBrush, $bodyX + $bodyW - 28, $bodyY + 136, 28, $bodyH - 272)
  $edgeBrush.Dispose()

  $outerPen = New-Object System.Drawing.Pen (New-ArgbColor 220 166 175 186), 8
  $g.DrawPath($outerPen, $bodyPath)
  $outerPen.Dispose()
  $innerPen = New-Object System.Drawing.Pen (New-ArgbColor 84 255 255 255), 2
  $innerPath = New-RoundedPath -X ($bodyX + 14) -Y ($bodyY + 14) -Width ($bodyW - 28) -Height ($bodyH - 28) -Radius ($bodyR - 18)
  $g.DrawPath($innerPen, $innerPath)
  $innerPen.Dispose()
  $innerPath.Dispose()

  $bezelPath = New-RoundedPath -X ($screenX - 8) -Y ($screenY - 8) -Width ($screenW + 16) -Height ($screenH + 16) -Radius ($screenR + 12)
  $bezelBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 9 11 15)
  $g.FillPath($bezelBrush, $bezelPath)
  $bezelBrush.Dispose()
  $bezelPath.Dispose()

  $screenPath = New-RoundedPath -X $screenX -Y $screenY -Width $screenW -Height $screenH -Radius $screenR
  Clear-PathTransparent -Graphics $g -Path $screenPath

  $holeBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 255 15 16 18)
  $g.FillEllipse($holeBrush, 687, 164, 70, 70)
  $holeBrush.Dispose()
  $lensBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 132 150 173 205)
  $g.FillEllipse($lensBrush, 713, 190, 18, 18)
  $lensBrush.Dispose()

  $earPen = New-Object System.Drawing.Pen (New-ArgbColor 14 255 255 255), 8
  $g.DrawLine($earPen, 566, 154, 878, 154)
  $earPen.Dispose()

  Add-SideButton -Graphics $g -X 94 -Y 742 -Width 24 -Height 318 -BaseColor (New-ArgbColor 255 184 193 206) -HighlightColor (New-ArgbColor 60 255 255 255)
  Add-SideButton -Graphics $g -X 1284 -Y 1042 -Width 24 -Height 326 -BaseColor (New-ArgbColor 255 176 186 200) -HighlightColor (New-ArgbColor 60 255 255 255)
  Add-SideButton -Graphics $g -X 1284 -Y 1412 -Width 24 -Height 352 -BaseColor (New-ArgbColor 255 176 186 200) -HighlightColor (New-ArgbColor 60 255 255 255)

  Save-Bitmap -Bitmap $bmp -FileName 'android_frost_frame.png' | Out-Null
  $screenPath.Dispose()
  $bodyPath.Dispose()
  $g.Dispose()
  $bmp.Dispose()

  $shadowBundle = New-ShadowBitmap `
    -Width $width -Height $height `
    -BodyX $bodyX -BodyY $bodyY -BodyWidth $bodyW -BodyHeight $bodyH -Radius $bodyR
  Save-Bitmap -Bitmap $shadowBundle.Bitmap -FileName 'android_frost_shadow.png' | Out-Null
  $shadowBundle.Graphics.Dispose()
  $shadowBundle.Bitmap.Dispose()

  $glareBundle = New-BitmapAndGraphics -Width $width -Height $height
  $gg = $glareBundle.Graphics
  $glareBrush = New-Object System.Drawing.SolidBrush (New-ArgbColor 48 255 255 255)
  $glarePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(146, 124),
    [System.Drawing.PointF]::new(756, 96),
    [System.Drawing.PointF]::new(1088, 386),
    [System.Drawing.PointF]::new(938, 624),
    [System.Drawing.PointF]::new(342, 382)
  )
  $gg.FillPolygon($glareBrush, $glarePoints)
  $glareBrush.Dispose()
  $arcPen = New-Object System.Drawing.Pen (New-ArgbColor 30 255 255 255), 12
  $gg.DrawArc($arcPen, 162, 132, 1092, 1614, 214, 104)
  $arcPen.Dispose()
  Save-Bitmap -Bitmap $glareBundle.Bitmap -FileName 'android_frost_glare.png' | Out-Null
  $glareBundle.Graphics.Dispose()
  $glareBundle.Bitmap.Dispose()
}

New-IPhoneAssets
New-IPhoneObsidianAssets
New-AndroidAssets
New-AndroidFrostAssets

Write-Output "Device frame assets generated to $outputDir"
