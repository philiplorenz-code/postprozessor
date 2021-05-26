[CmdletBinding()]
Param(
    $SystemPath, # the value can be set in PYTHA Interface Setup
    $SystemCommand, # the value can be set in PYTHA Interface Setup
    $SystemProfile, # the value can be set in PYTHA Interface Setup
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Program
)
############################################################################

#Hier müssen die Pfade von XConverter und Werkzeugdatei angegeben werden bei 32Bit
#$XConverter = 'C:\Program Files (x86)\SCM Group_1\Maestro\XConverter.exe'
#$Tooling = 'C:\Program Files (x86)\SCM Group_1\Maestro\Tlgx\def.tlgx'


#Alternative Pfade für Maestro 64 Bit
$XConverter = 'C:\Program Files\SCM Group\Maestro\XConverter.exe'
$Tooling = 'C:\Users\Public\Documents\SCM Group\Maestro\Tlgx\def.tlgx'

# Global Vars
$count = 0
$global:inFiles = @()
$global:tmpFiles = @()
$global:tmpFiles2 = @()
$global:outFiles = @()
$global:exclamtionmarks = @()
$global:workingdir = (get-item ($input.CamPath[0])).Directory

# Functions
function Add-StringBefore {
    param (
        [array]$insert,
        [string]$keyword,
        # in $textfile muss eigentlich immer $Prog.CamPath übergeben werden
        [string]$textfile,
        [boolean]$bc
    )
    Write-Host "Das ist der insert: $insert"
    Write-Host "Das ist das keyword: $keyword"
    Write-Host "Das ist der PFad: $textfile"

    $content = Get-Content $textfile

    Write-Host "Das ist der aktuelle inhalt: $content"
    $counter = 0
    $keywordcomplete = ""
    foreach ($string in $content) {

        if ($string -like "*$keyword*") {
            if ($bc){
                $exclamtionmarks += $textfile
            }

            $keywordcomplete = $string

            $content[$counter] = ""
            for ($i = 0; $i -lt $insert.Count; $i++) {
                $content[$counter] = $content[$counter] + $insert[$i] + "`n" 
            }
            if ($bc){
                $keywordcomplete = $keywordcomplete.Substring(0, $keywordcomplete.Length - 1)
                $keywordcomplete = $keywordcomplete.Substring(0, $keywordcomplete.Length - 1)
                $keywordcomplete = $keywordcomplete + ", -1, -1, -1, 0, true, true, 0, 5);"
                $content[$counter] = $content[$counter] + $keywordcomplete
            }
            else {
                $content[$counter] = $content[$counter] + $keywordcomplete + "`n" 
            }
            
        }
        $counter++
    }


    $content | Out-File $textfile



}
function Set-Exlamationmarks {
    param (
        [array]$files
    )
    $files = $files | Select-Object -Unique
    foreach ($textfile in $files) {
        $textfile = $textfile.Replace("xcs","pgmx")
        $dir = (Get-Item $textfile).Directory.FullName 
        $filename = "!!!" + ((Get-Item $textfile).Name)
        $newsave = $dir + "\" + $filename
        $content | Out-File $newsave
        Remove-Item $textfile  
    }
}
function Correct-M200 {
    $file2 = (Get-ChildItem $workingdir | Where-Object {$_.FullName -like "*_2.xcs"} | Select-Object FullName).FullName
    Write-Host "diese Datei wird nun von Correct-Function gecheckt: $file2" -ForegroundColor Green
    $count = 0
    $content = Get-Content $file2
    foreach ($line in $content) {
        if ($line -like "*CreateRawWorkpiece*"){
            $stringarray = $line.split(",")
            $newarray = @()
            $newarray += $stringarray[0]
            $newarray += ","
            for ($i = 1; $i -lt $stringarray.Count; $i++) {
                if ($i -eq 1){
                }
                else {
                    $newarray += ","
                }
                $newarray[$i] += "0.0000"
            } 

            [string]$output = $newarray
            $output = $output -replace '\s',''
            $output = $output + ");"
            $dbg = $content[$count]
            Write-Host "Diese ContentLine wird geändert: $dbg" -ForegroundColor Green
            Write-Host "In: $output" -ForegroundColor Green

            $lastarray = $output.Split("(")
            $output = $lastarray[0] + "(" + ($lastarray[1] -replace '^.','0')

            $content[$count] = $output

        }
        if ($line -like "*SetWorkpieceSetupPosition*"){
            $stringarray = $line.split(",")
            $newarray = @()
            $newarray += $stringarray[0]
            $newarray += ","
            for ($i = 1; $i -lt $stringarray.Count; $i++) {
                if ($i -eq 1){
                }
                else {
                    $newarray += ","
                }
                $newarray[$i] += "0.0000"
            } 

            [string]$output = $newarray
            $output = $output -replace '\s',''
            $output = $output + ");"
            $dbg = $content[$count]
            Write-Host "Diese ContentLine wird geändert: $dbg" -ForegroundColor Green
            Write-Host "In: $output" -ForegroundColor Green

            $lastarray = $output.Split("(")
            $output = $lastarray[0] + "(" + ($lastarray[1] -replace '^.','0')

            $content[$count] = $output

        }
        $count++
    }

    $content | Out-File $file2

}
function Correct-M200Updated {
    $file2 = (Get-ChildItem $workingdir | Where-Object {$_.FullName -like "*_2.xcs"} | Select-Object FullName).FullName
    Write-Host "diese Datei wird nun von Correct-Function gecheckt: $file2" -ForegroundColor Green
    $count = 0
    $content = Get-Content $file2
    foreach ($line in $content) {
        if ($line -like "*CreateRawWorkpiece*"){
            $newstring = ($content[$count]) -replace ".{43}$"
            $newstring = $newstring + "0.0000,0.0000,0.0000,0.0000,0.0000,0.0000);"
            $content[$count] = $newstring
        }
        if ($line -like "*SetWorkpieceSetupPosition*"){
            $newstring = ($content[$count]) -replace ".{26}$"
            $newstring = $newstring + "0.0000,0.0000,0.0000,0.0000);"
            $content[$count] = $newstring
        }
        $count++
    }

    $content | Out-File $file2

}
function First-Replace {
    (Get-Content $Prog.CamPath) | Foreach-Object {

        # Hier können Textersetzungen angegeben werden, welche dann in der xcs- bzw. pgmx-Datei wirksam werden
        $_.Replace("SlantedBladeCut", "Saegeschnitt_").
        Replace("Routing_", "Fraesen_").
        Replace("VerticalDrilling", "Vertikale Bohrung").
        Replace("HorizontalDrilling", "Horizontale Bohrung").
        Replace("PYTHA_INIT_", "Blindes Makro_").
        Replace("PYTHA_PARK_", "Wegfahrschritt_")

    } | Set-Content $Prog.CamPath

    # Approach- und RetractStrategie ersetzen
    (Get-Content $Prog.CamPath) | Foreach-Object {

        # Hier können Textersetzungen angegeben werden, welche dann in der xcs- bzw. pgmx-Datei wirksam werden
        $_.Replace("SetApproachStrategy(true, false, -1)", "SetApproachStrategy(false, true, 2)").
        Replace("SetRetractStrategy(true, false, -1, 0)", "SetRetractStrategy(false, true, 2, 5)")

    } | Set-Content $Prog.CamPath



    # An- und Abfahrbewegung fliegend bohrend für Nut
    $insertnut = @()
    $insertnut += 'SetApproachStrategy(true, false, 1.5);'
    $insertnut += 'SetRetractStrategy(true, false, 1.5, 0);'
    $keywordnut = "CreateSlot"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $insertnut -keyword $keywordnut -textfile $textfile -bc $false

    # Anfahrbewegung fliegend bohrend und Strategie für Tasche (funktioniert bisher nur für eine Tasche!!!)
    $inserttasche = @()
    $inserttasche += 'SetApproachStrategy(true, false, 1.5);'
    $inserttasche += 'CreateContourParallelStrategy(true, 0, true, 5, 0, 0);'
    $keywordtasche = "CreateContourPocket"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $inserttasche -keyword $keywordtasche -textfile $textfile -bc $false
    
        
    # Vorritzen, an- und abfahren mit dem Sägeblatt
    $insertblatt = @()
    $insertblatt += 'SetApproachStrategy(true, true, 0.25);'
    $insertblatt += 'SetRetractStrategy(true, true, 0.25, 0);'
    $insertblatt += 'CreateSectioningMillingStrategy(5, 80, 0);'
    $keywordblatt = "CreateBladeCut"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $insertblatt -keyword $keywordblatt -textfile $textfile -bc $true
 
}
function convert-xcs-to-pgmx {
    Write-Output 'GS Ravensburg CAM-Export' $inFiles 'Umwandlung von .xcs- in .pgmx-Dateien inklusive Saugerpositionierung und Optimierung' $outFiles
    # Konvertieren in tmp pgmx

    Write-Host "Konvertieren in tmp pgmx" -ForegroundColor Red
    Write-Host "inFiles:" -ForegroundColor Red
    $inFiles
    Write-Host "tmfiles:" -ForegroundColor Red
    $tmpFiles
    & $XConverter -ow -s -report -m 0 -i $inFiles -t $Tooling -o $tmpFiles | Out-Default

    # Bearbeitungen optimieren
    Write-Host "Bearbeitungen optimieren" -ForegroundColor Red
    Write-Host "tmfiles:" -ForegroundColor Red
    $tmpFiles
    Write-Host "tmfiles2:" -ForegroundColor Red
    $tmpFiles2
    & $XConverter -ow -s -m 2 -i $tmpFiles -t $Tooling -o $tmpFiles2 | Out-Default
	
    # Sauger positionieren
    Write-Host "Sauger positionieren" -ForegroundColor Red
    Write-Host "tmfiles2:" -ForegroundColor Red
    $tmpFiles2
    Write-Host "outfiles:" -ForegroundColor Red
    $outFiles
    & $XConverter -ow -s -m 13 -i $tmpFiles2 -t $Tooling -o $outFiles | Out-Default

    # Loesche die temporaeren Dateien
    Write-Host "Remove tmpFiles : $tmpFiles" -ForegroundColor Green
    $gci = (gci $workingdir).Name
    Write-Host " Dateien vor Löschversuch: $gci" -ForegroundColor Green
    Remove-Item $tmpFiles  
	
    # Loesche die temporaeren Dateien
    Remove-Item $tmpFiles2
}
function Prepare-Files {

    if ($count -ge 200) { 
        # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		

        convert-xcs-to-pgmx

        $count = 0
        $inFiles = ""
        $tmpFiles = ""
        $tmpFiles2 = ""
        $outFiles = ""
    }

    Write-Host "################" -ForegroundColor Red
    $Prog
    Write-Host "###" -ForegroundColor Red
    $Prog.CamPath


    $xcsPath = $Prog.CamPath
    Write-Host "$xcsPath" -ForegroundColor Green
    $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
    Write-Host "$pgmxPath" -ForegroundColor Green
    $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
    Write-Host "$tmpPath" -ForegroundColor Green
    $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
    Write-Host "$tmpPath2" -ForegroundColor Green

        
    $count += 1
    $inFiles += $xcsPath
    $outFiles += $pgmxPath
    $tmpFiles += $tmpPath
    $tmpFiles2 += $tmpPath2

    
}
function Open-Dir {
    Invoke-Item $workingdir 
}


# Main
foreach ($Prog in $input) {
    First-Replace

Correct-M200Updated

}


<#

foreach ($Prog in $input) {
    if ($count -ge 200) { 
        # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		

        #convert-xcs-to-pgmx

        $count = 0
        $inFiles = ""
        $tmpFiles = ""
        $tmpFiles2 = ""
        $outFiles = ""
    }

    Write-Host "################" -ForegroundColor Red
    $Prog
    Write-Host "###" -ForegroundColor Red
    $Prog.CamPath


    $xcsPath = $Prog.CamPath
    Write-Host "$xcsPath" -ForegroundColor Green
    $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
    Write-Host "$pgmxPath" -ForegroundColor Green
    $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
    Write-Host "$tmpPath" -ForegroundColor Green
    $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
    Write-Host "$tmpPath2" -ForegroundColor Green

        
    $count += 1
    $inFiles += $xcsPath
    $outFiles += $pgmxPath
    $tmpFiles += $tmpPath
    $tmpFiles2 += $tmpPath2
}




Write-Output 'GS Ravensburg CAM-Export' $inFiles 'Umwandlung von .xcs- in .pgmx-Dateien inklusive Saugerpositionierung und Optimierung' $outFiles
# Konvertieren in tmp pgmx

Write-Host "Konvertieren in tmp pgmx" -ForegroundColor Red
Write-Host "inFiles:" -ForegroundColor Red
$inFiles
Write-Host "tmfiles:" -ForegroundColor Red
$tmpFiles
& $XConverter -ow -s -report -m 0 -i $inFiles -t $Tooling -o $tmpFiles | Out-Default

# Bearbeitungen optimieren
Write-Host "Bearbeitungen optimieren" -ForegroundColor Red
Write-Host "tmfiles:" -ForegroundColor Red
$tmpFiles
Write-Host "tmfiles2:" -ForegroundColor Red
$tmpFiles2
& $XConverter -ow -s -m 2 -i $tmpFiles -t $Tooling -o $tmpFiles2 | Out-Default

# Sauger positionieren
Write-Host "Sauger positionieren" -ForegroundColor Red
Write-Host "tmfiles2:" -ForegroundColor Red
$tmpFiles2
Write-Host "outfiles:" -ForegroundColor Red
$outFiles
& $XConverter -ow -s -m 13 -i $tmpFiles2 -t $Tooling -o $outFiles | Out-Default


#>

########

function convert-xcs-to-pgmx {
    Write-Output 'GS Ravensburg CAM-Export' $inFiles 'Umwandlung von .xcs- in .pgmx-Dateien inklusive Saugerpositionierung und Optimierung' $outFiles
    # Konvertieren in tmp pgmx
    & $XConverter -ow -s -report -m 0 -i $inFiles -t $Tooling -o $tmpFiles | Out-Default

    # Bearbeitungen optimieren
    & $XConverter -ow -s -m 2 -i $tmpFiles -t $Tooling -o $tmpFiles2 | Out-Default
	
    # Sauger positionieren
    & $XConverter -ow -s -m 13 -i $tmpFiles2 -t $Tooling -o $outFiles | Out-Default

    # Loesche die temporaeren Dateien
    Remove-Item $tmpFiles  
	
    # Loesche die temporaeren Dateien
    Remove-Item $tmpFiles2
}

foreach ($Prog in $input) {
    if ($count -ge 200) { 
        # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		

        convert-xcs-to-pgmx

        $count = 0
        $inFiles = ""
        $tmpFiles = ""
        $tmpFiles2 = ""
        $outFiles = ""
    }

    $xcsPath = $Prog.CamPath
    $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
    $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
    $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
	
		
    $count += 1
    $inFiles += $xcsPath
    $outFiles += $pgmxPath
    $tmpFiles += $tmpPath
    $tmpFiles2 += $tmpPath2
}

convert-xcs-to-pgmx

########


Set-Exlamationmarks -file $exclamtionmarks
Open-Dir
Start-Sleep 1
