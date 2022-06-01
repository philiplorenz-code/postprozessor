$path = "1_SeiteL_Lichtgr_6.542_T01_1"
$path = "_SeiteL____1"



$filename = Split-Path $path -leaf
$split = $filename.split("_")

$PosNr = $split[0]
$Bauteilname = $split[1]
$Material = $split[2]
$Fraestiefe = $split[3]
$Technologie = $split[4]
$ProgrammNr = $split[5]

if ([string]::IsNullOrEmpty($Fraestiefe)){
    $MM = 0
}
else {
    $MM = $Fraestiefe
}

# SetMacroParam
$content = Get-Content $path
$output = @()
foreach ($string in $content) {
  $output += $string
  if ($string -like "*SetMacroParam*Angle*") {
    $output += 'SetMacroParam("Depth", ' + $MM + ');'
  }

}
Set-Content -Path $FilePath -Value $output



$string = "_SeiteL____1"
$split = $string.split("_")


Split-Path $outputPath -leaf
