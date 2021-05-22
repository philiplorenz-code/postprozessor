
foreach ($item in (get-childitem "C:\Users\saigon\Desktop\dateien\Vorher-Nachher\!Testing\Vorher")) {
    (Get-Content $item.Fullname) | Foreach-Object {

        # Hier können Textersetzungen angegeben werden, welche dann in der xcs- bzw. pgmx-Datei wirksam werden
        $_.Replace("SlantedBladeCut", "Saegeschnitt_").
        Replace("Routing_", "Fraesen_").
        Replace("VerticalDrilling", "Vertikale Bohrung").
        Replace("HorizontalDrilling", "Horizontale Bohrung").
        Replace("PYTHA_INIT_", "Blindes Makro_").
        Replace("PYTHA_PARK_", "Wegfahrschritt_")

    } | Set-Content $item.Fullname

    # An- und Abfahrbewegung im bogen bohrend für Umfräsung

    # Diese Funktion ermöglicht das Einfügen von Zeilen vor einem definierten Keyword!
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
        $indexarray = @()
        $counter = 0
        $keywordcomplete = ""
        foreach ($string in $content) {

            if ($string -like "*$keyword*") {
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
        if ($bc){
            $dir = (Get-Item $textfile).Directory.FullName 
            $filename = "!!!" + ((Get-Item $textfile).Name)
            $newsave = $dir + "\" + $filename
            $content | Out-File $newsave
            Remove-Item $textfile
        }
        else {
            $content | Out-File $textfile
        }

    
    }

    # Approach- und RetractStrategie ersetzen
    foreach ($command in (Get-Content $item.Fullname)) {
        $command.Replace("SetApproachStrategy(true, false, -1)", "SetApproachStrategy(false, true, 2)")
        $command.Replace("SetRetractStrategy(true, false, -1, 0)", "SetRetractStrategy(false, true, 2, 5)")
    }



    # An- und Abfahrbewegung fliegend bohrend für Nut
    $insertnut = @()
    $insertnut += 'SetApproachStrategy(true, false, 1.5);'
    $insertnut += 'SetRetractStrategy(true, false, 1.5, 0);'
    $keywordnut = "CreateSlot"
    $textfile = $item.Fullname
    Add-StringBefore -insert $insertnut -keyword $keywordnut -textfile $textfile -bc $false

    # Anfahrbewegung fliegend bohrend und Strategie für Tasche (funktioniert bisher nur für eine Tasche!!!)
    $inserttasche = @()
    $inserttasche += 'SetApproachStrategy(true, false, 1.5);'
    $inserttasche += 'CreateContourParallelStrategy(true, 0, true, 5, 0, 0);'
    $keywordtasche = "CreateContourPocket"
    $textfile = $item.Fullname
    Add-StringBefore -insert $inserttasche -keyword $keywordtasche -textfile $textfile -bc $false
    
	
    # Vorritzen, an- und abfahren mit dem Sägeblatt
    $insertblatt = @()
    $insertblatt += 'SetApproachStrategy(true, true, 0.25);'
    $insertblatt += 'SetRetractStrategy(true, true, 0.25, 0);'
    $insertblatt += 'CreateSectioningMillingStrategy(5, 80, 0);'
    $keywordblatt = "CreateBladeCut"
    $textfile = $item.Fullname
    Add-StringBefore -insert $insertblatt -keyword $keywordblatt -textfile $textfile -bc $true
    
 
}
