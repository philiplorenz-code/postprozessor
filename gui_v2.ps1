[CmdletBinding()]
Param(
    $SystemPath, # the value can be set in PYTHA Interface Setup
    $SystemCommand, # the value can be set in PYTHA Interface Setup
    $SystemProfile, # the valuå can be set in PYTHA Interface Setup
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Program
)
############################################################################

#Hier müssen die Pfade von XConverter und Werkzeugdatei angegeben werden bei 32Bit
#$XConverter = 'C:\Program Files (x86)\SCM Group_1\Maestro\XConverter.exe'
#$Tooling = 'C:\Program Files (x86)\SCM Group_1\Maestro\Tlgx\def.tlgx'

write-host $SystemPath
write-host $SystemCommand
write-host $SystemProfile
write-host $Program
write-host "Input:"
write-host $Input
$Global:input_new = $input
$str = $Global:input_new | Out-String
Write-Host $str -ForegroundColor Green

#Alternative Pfade für Maestro 64 Bit
$XConverter = 'C:\Program Files\SCM Group\Maestro\XConverter.exe'
$Tooling = 'C:\Users\Public\Documents\SCM Group\Maestro\Tlgx\def.tlgx'

# Global Vars
$count = 0
$Global:inFiles = @()
$Global:tmpFiles = @()
$Global:tmpFiles2 = @()
$Global:outFiles = @()
$Global:exclamtionmarks = @()
$Global:workingdir = (get-item ($input.CamPath[0])).Directory
$Global:input_new = $input

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
                $Global:exclamtionmarks += $textfile
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
function Correct-{
    $file2 = (Get-ChildItem $Global:workingdir | Where-Object {$_.FullName -like "*_2.xcs"} | Select-Object FullName).FullName
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
    $file2 = (Get-ChildItem $Global:workingdir | Where-Object {$_.FullName -like "*_2.xcs"} | Select-Object FullName).FullName
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
            $newstring = $newstring + "0.0000, 0.0000, 0.0, 0.0);"
            $content[$count] = $newstring
        }
        $count++
    }

    $content | Out-File $file2

}
function First-Replace {
    foreach ($Prog in $Global:input_new) {

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
}
function Convert-Prep {

}
function convert-xcs-to-pgmx {
    Write-Host "!!!!! TMPFiles2: $Global:tmpFiles2" -ForegroundColor Green
    Write-Output 'GS Ravensburg CAM-Export' $Global:inFiles 'Umwandlung von .xcs- in .pgmx-Dateien inklusive Saugerpositionierung und Optimierung' $Global:outFiles
    # Konvertieren in tmp pgmx
    Write-Host "JETZT WERDEN INFILES IN TEMP KONVERTIERT!!!!" -ForegroundColor Green
    Write-Host $Global:inFiles -ForegroundColor RED
    Write-Host "INFILES: $Global:inFiles" -ForegroundColor Green
    & $XConverter -ow -s -report -m 0 -i $Global:inFiles -t $Tooling -o $Global:tmpFiles | Out-Default
    $g = (gci -Path $Global:workingdir).Name
    Write-Host "Das ist der Ordnerinhalt nach der Konvertierung: $g"
    # Bearbeitungen optimieren
    Write-Host "JETZT WERDEN FILES OPTIMIERT!!!!" -ForegroundColor Green
    & $XConverter -ow -s -m 2 -i $Global:tmpFiles -t $Tooling -o $Global:tmpFiles2 | Out-Default
    $g = (gci -Path $Global:workingdir).Name
    Write-Host "Das ist der Ordnerinhalt nach der Optimierung: $g"

    # Sauger positionieren
    & $XConverter -ow -s -m 13 -i $Global:tmpFiles2 -t $Tooling -o $Global:outFiles | Out-Default

    # Loesche die temporaeren Dateien
    Remove-Item $Global:tmpFiles  
	
    # Loesche die temporaeren Dateien
    Remove-Item $Global:tmpFiles2
}

function Open-Dir {
    Invoke-Item $Global:workingdir 
}


######################################################
######################################################


#-------------------------------------------------------------#
#----Initial Declarations-------------------------------------#
#-------------------------------------------------------------#

Add-Type -AssemblyName PresentationCore, PresentationFramework

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="800" Height="550" Topmost="True">
<Grid>
<TabControl Margin="1,0,-1,0" SelectedIndex="{Binding tabIndex}" Name="name">
     <TabItem Visibility="Collapsed" Header="Auswahl"><Grid Margin="0,-2,0,2" Name="selection" Background="#9b9b9b">


<Button Content="5-Achs M200" HorizontalAlignment="Left" VerticalAlignment="Top" Width="210" Margin="33,260,0,0" Height="64" BorderBrush="#9b9b9b" Foreground="#000000" OpacityMask="#4a90e2" BorderThickness="5,5,5,5" FontFamily="Yu Gothic UI Bold *" FontSize="22" FontWeight="DemiBold" Background="#ffffff" Name="m200button"/>
<Button Content="Nesting X200" HorizontalAlignment="Left" VerticalAlignment="Top" Width="210" Margin="33,80,0,0" Name="x200button" Height="64" Background="#ffffff" BorderBrush="#9b9b9b" Foreground="#000000" OpacityMask="#4a90e2" BorderThickness="5,5,5,5" FontFamily="Yu Gothic UI Bold *" FontSize="22" FontWeight="DemiBold"/>
<Image HorizontalAlignment="Left" Height="171" VerticalAlignment="Top" Width="313" Margin="395,20,0,0" Source="C:\DevStuff\Projekt\Theo\x200.png" Name="x200"/>
<Image HorizontalAlignment="Left" Height="171" VerticalAlignment="Top" Width="313" Margin="395,210,0,0" Source="C:\DevStuff\Projekt\Theo\m200.png" Name="m200"/>
<Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon1" Source="C:\DevStuff\Projekt\Theo\icon.png"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText1" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
</Grid>
</TabItem>
     <TabItem Visibility="Collapsed" Header="Fortschritt"><Grid Background="#9b9b9b" Margin="1,1,-1,-1" Name="wait">
<Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon2" Source="C:\DevStuff\Projekt\Theo\icon.png"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText2" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>





<Image HorizontalAlignment="Left" Height="255" VerticalAlignment="Top" Width="571" Margin="185,97,0,0" Source="C:\DevStuff\Projekt\Theo\warten.png"/>
<Image HorizontalAlignment="Left" Height="245" VerticalAlignment="Top" Width="123" Margin="41,102,0,0" Source="C:\DevStuff\Projekt\Theo\sanduhr.png"/>
</Grid>
</TabItem>
     <TabItem Visibility="Collapsed" Header="Ende"><Grid Background="#FFE5E5E5">
<Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon3" Source="C:\DevStuff\Projekt\Theo\icon.png"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText3" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>


<Image HorizontalAlignment="Left" Height="102" VerticalAlignment="Top" Width="102" Margin="12,5,0,0" Name="errorimage" Source="C:\DevStuff\Projekt\Theo\error.png"/>

<TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="306" Width="471" Text="" TextWrapping="Wrap" Margin="292,82,0,0" Name="errorbox"/>
<TextBlock HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Fehler:" Margin="664,29,0,0" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
</Grid></TabItem>
</TabControl>
</Grid></Window>
"@

#-------------------------------------------------------------#
#----Control Event Handlers-----------------------------------#
#-------------------------------------------------------------#


#Write your code here
function Run-M200(){
    $State.tabIndex = 1
    First-Replace
    Correct-M200Updated
    foreach ($Prog in $Global:input_new) {
        if ($count -ge 200) { 
            # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		
    
            convert-xcs-to-pgmx
    
            $count = 0
            $Global:inFiles = ""
            $Global:tmpFiles = ""
            $Global:tmpFiles2 = ""
            $Global:outFiles = ""
        }
        
    
        $xcsPath = $Prog.CamPath
        $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
        $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
        $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
        
            
        $count += 1
        $Global:inFiles += $xcsPath
        $Global:outFiles += $pgmxPath
        $Global:tmpFiles += $tmpPath
        $Global:tmpFiles2 += $tmpPath2
    }
    convert-xcs-to-pgmx
    Open-Dir
    Start-Sleep 1
    if ($error.count -gt 0){
        $State.tabIndex = 2
    }
    else {
        exit
    }

}

function Run-X200(){
    $State.tabIndex = 1

    First-Replace

    foreach ($Prog in $Global:input_new) {
        if ($count -ge 200) { 
            # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		
    
            convert-xcs-to-pgmx
    
            $count = 0
            $Global:inFiles = ""
            $Global:tmpFiles = ""
            $Global:tmpFiles2 = ""
            $Global:outFiles = ""
        }
        
    
        $xcsPath = $Prog.CamPath
        $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
        $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
        $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
        
            
        $count += 1
        $Global:inFiles += $xcsPath
        $Global:outFiles += $pgmxPath
        $Global:tmpFiles += $tmpPath
        $Global:tmpFiles2 += $tmpPath2
    }
    
    convert-xcs-to-pgmx

    Set-Exlamationmarks -files $Global:exclamtionmarks
    Open-Dir
    Start-Sleep 1
    if ($error.count -gt 0){
        $State.tabIndex = 2
    }
    else {
        exit
    }
}

function Set-Endscreen(){
    $State.tabIndex = 2
}
#endregion

#-------------------------------------------------------------#
#----Script Execution-----------------------------------------#
#-------------------------------------------------------------#

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

$m200button.Add_Click({Run-M200 $this $_})
$x200button.Add_Click({Run-X200 $this $_})
$errorbox.text = $error

$State = [PSCustomObject]@{}


Function Set-Binding {
    Param($Target,$Property,$Index,$Name)
 
    $Binding = New-Object System.Windows.Data.Binding
    $Binding.Path = "["+$Index+"]"
    $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
    


    [void]$Target.SetBinding($Property,$Binding)
}

function FillDataContext($props){

    For ($i=0; $i -lt $props.Length; $i++) {
   
   $prop = $props[$i]
   $DataContext.Add($DataObject."$prop")
   
    $getter = [scriptblock]::Create("return `$DataContext['$i']")
    $setter = [scriptblock]::Create("param(`$val) return `$DataContext['$i']=`$val")
    $State | Add-Member -Name $prop -MemberType ScriptProperty -Value  $getter -SecondValue $setter
               
       }
   }



$DataObject =  ConvertFrom-Json @"

{
    "tabIndex" : 0
}

"@

$DataContext = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
FillDataContext @("tabIndex") 

$Window.DataContext = $DataContext
Set-Binding -Target $name -Property $([System.Windows.Controls.TabControl]::SelectedIndexProperty) -Index 0 -Name "tabIndex"




$Global:SyncHash = [HashTable]::Synchronized(@{})
$SyncHash.Window = $Window
$Jobs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
$initialSessionState = [initialsessionstate]::CreateDefault()

Function Start-RunspaceTask
{
    [CmdletBinding()]
    Param([Parameter(Mandatory=$True,Position=0)][ScriptBlock]$ScriptBlock,
          [Parameter(Mandatory=$True,Position=1)][PSObject[]]$ProxyVars)
            
    $Runspace = [RunspaceFactory]::CreateRunspace($InitialSessionState)
    $Runspace.ApartmentState = 'STA'
    $Runspace.ThreadOptions  = 'ReuseThread'
    $Runspace.Open()
    ForEach($Var in $ProxyVars){$Runspace.SessionStateProxy.SetVariable($Var.Name, $Var.Variable)}
    $Thread = [PowerShell]::Create('NewRunspace')
    $Thread.AddScript($ScriptBlock) | Out-Null
    $Thread.Runspace = $Runspace
    [Void]$Jobs.Add([PSObject]@{ PowerShell = $Thread ; Runspace = $Thread.BeginInvoke() })
}

$JobCleanupScript = {
    Do
    {    
        ForEach($Job in $Jobs)
        {            
            If($Job.Runspace.IsCompleted)
            {
                [Void]$Job.Powershell.EndInvoke($Job.Runspace)
                $Job.PowerShell.Runspace.Close()
                $Job.PowerShell.Runspace.Dispose()
                $Job.Powershell.Dispose()
                
                $Jobs.Remove($Job)
            }
        }

        Start-Sleep -Seconds 1
    }
    While ($SyncHash.CleanupJobs)
}

Get-ChildItem Function: | Where-Object {$_.name -notlike "*:*"} |  select name -ExpandProperty name |
ForEach-Object {       
    $Definition = Get-Content "function:$_" -ErrorAction Stop
    $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList "$_", $Definition
    $InitialSessionState.Commands.Add($SessionStateFunction)
}


$Window.Add_Closed({
    Write-Verbose 'Halt runspace cleanup job processing'
    $SyncHash.CleanupJobs = $False
})

$SyncHash.CleanupJobs = $True
function Async($scriptBlock){ Start-RunspaceTask $scriptBlock @([PSObject]@{ Name='DataContext' ; Variable=$DataContext},[PSObject]@{Name="State"; Variable=$State},[PSObject]@{Name = "SyncHash";Variable = $SyncHash})}

Start-RunspaceTask $JobCleanupScript @([PSObject]@{ Name='Jobs' ; Variable=$Jobs })



$Window.ShowDialog()
$Window.activate()

######################################################
######################################################

 
