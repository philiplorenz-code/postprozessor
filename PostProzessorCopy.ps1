
#############################################################################################################################################################################################################
# Beginn GUI Zeug
#############################################################################################################################################################################################################

Add-Type -AssemblyName PresentationCore,PresentationFramework

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="800" Height="550" Topmost="True">
  <Grid>
    <TabControl Margin="2,0,-2,0" SelectedIndex="{Binding tabIndex}" Name="name">
      <TabItem Visibility="Collapsed" Header="Auswahl">
        <Grid Margin="0,-2,0,2" Name="selection" Background="#9b9b9b">
          <Button Content="5-Achs M200" HorizontalAlignment="Left" VerticalAlignment="Top" Width="210" Margin="33,259,0,0" Height="64" BorderBrush="#9b9b9b" Foreground="#000000" OpacityMask="#4a90e2" BorderThickness="5,5,5,5" FontFamily="Yu Gothic UI Bold *" FontSize="22" FontWeight="DemiBold" Background="#ffffff" Name="m200button"/>
          <Button Content="Nesting X200" HorizontalAlignment="Left" VerticalAlignment="Top" Width="210" Margin="33,80,0,0" Name="x200button" Height="64" Background="#ffffff" BorderBrush="#9b9b9b" Foreground="#000000" OpacityMask="#4a90e2" BorderThickness="5,5,5,5" FontFamily="Yu Gothic UI Bold *" FontSize="22" FontWeight="DemiBold"/>
          <Image HorizontalAlignment="Left" Height="171" VerticalAlignment="Top" Width="313" Margin="395,20,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\x200.png" Name="x200"/>
          <Image HorizontalAlignment="Left" Height="171" VerticalAlignment="Top" Width="313" Margin="395,210,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\m200.png" Name="m200"/>
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon1" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText1" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
          <CheckBox HorizontalAlignment="Left" Name="m200cb" VerticalAlignment="Top" Content="Run M200 for _2" Margin="38,143,0,0" IsChecked="{Binding m200cb}"/>
          <CheckBox HorizontalAlignment="Left" Name="x200cb" VerticalAlignment="Top" Content="Run X200 for _2" Margin="40,325,0,0" IsChecked="{Binding x200cb}"/>
        </Grid>
      </TabItem>
      <TabItem Visibility="Collapsed" Header="Fortschritt">
        <Grid Background="#9b9b9b" Margin="1,1,-1,-1" Name="wait">
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon2" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText2" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
          <Image HorizontalAlignment="Left" Height="255" VerticalAlignment="Top" Width="571" Margin="185,97,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\warten.png"/>
          <Image HorizontalAlignment="Left" Height="245" VerticalAlignment="Top" Width="123" Margin="41,102,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\sanduhr.png"/>
        </Grid>
      </TabItem>
      <TabItem Visibility="Collapsed" Header="Ende">
        <Grid Background="#FFE5E5E5">
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon3" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText3" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
          <Image HorizontalAlignment="Left" Height="102" VerticalAlignment="Top" Width="102" Margin="12,5,0,0" Name="errorimage" Source="C:\DevStuff\Projekt\Theo\error.png"/>
          
          <TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="102" Width="356" TextWrapping="Wrap" Margin="94,224,0,0" Text="In der Konfiguration liegt ein Fehler vor! Bitte oeffne den Exportbericht!"/>
          <TextBlock HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Fehler:" Margin="664,29,0,0" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
        </Grid>
      </TabItem>
    </TabControl>
  </Grid>
</Window>

"@
# <TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="306" Width="471" Text="In der Konfiguration liegt ein Fehler vor!" TextWrapping="Wrap" Margin="292,82,0,0" Name="errorbox"/>
#-------------------------------------------------------------#
#----Control Event Handlers-----------------------------------#
#-------------------------------------------------------------#



#endregion

#-------------------------------------------------------------#
#----Script Execution-----------------------------------------#
#-------------------------------------------------------------#

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }


$m200button.Add_Click({ Run-M200 $this $_ })
$x200button.Add_Click({ Run-X200 $this $_ })




$State = [pscustomobject]@{}


function Set-Binding {
  param($Target,$Property,$Index,$Name)

  $Binding = New-Object System.Windows.Data.Binding
  $Binding.Path = "[" + $Index + "]"
  $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay



  [void]$Target.SetBinding($Property,$Binding)
}

function FillDataContext ($props) {

  for ($i = 0; $i -lt $props.Length; $i++) {

    $prop = $props[$i]
    $DataContext.Add($DataObject. "$prop")

    $getter = [scriptblock]::Create("return `$DataContext['$i']")
    $setter = [scriptblock]::Create("param(`$val) return `$DataContext['$i']=`$val")
    $State | Add-Member -Name $prop -MemberType ScriptProperty -Value $getter -SecondValue $setter

  }
}



$DataObject = ConvertFrom-Json @"

{
    "tabIndex" : 0,
    "GlobalError" : null,
    "Systempath" : null,
    "SystemCommand" : null,
    "SystemProfile" : null,
    "Program" : null,
    "XConverter" : null,
    "Infiles" : null,
    "M200Infiles" : null,
    "X200Infiles" : null,
    "tmpFiles" : null,
    "M200tmpFiles" : null,
    "X200tmpFiles" : null,
    "tmpFiles2" : null,
    "M200tmpFiles2" : null,
    "X200tmpFiles2" : null,
    "outFiles" : null,
    "M200outFiles" : null,
    "X200outFiles" : null,
    "Tooling" : null,
    "WorkingDir" : null,
    "WorkingDirTemp" : null,
    "input" : null,
    "x200cb" : "false",
    "m200cb" : "false"
}

"@

$DataContext = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
FillDataContext @("tabIndex","GlobalError","Systempath","SystemCommand","SystemProfile","Program","XConverter","Infiles","tmpFiles","tmpFiles2","outFiles","Tooling","WorkingDir","WorkingDirTemp","input","M200Infiles","X200Infiles","M200tmpFiles","X200tmpFiles","M200tmpFiles2","X200tmpFiles2","M200outFiles","X200outFiles","x200cb","m200cb")

# TODO - das hier gerade ziehen!! Binding setzen zsm mit poshgui!
$Window.DataContext = $DataContext
Set-Binding -Target $name -Property $([System.Windows.Controls.TabControl]::SelectedIndexProperty) -Index 0 -Name "tabIndex"
Set-Binding -Target $m200cb -Property $([System.Windows.Controls.CheckBox]::IsCheckedProperty) -Index 1 -Name "m200cb" 
Set-Binding -Target $x200cb -Property $([System.Windows.Controls.CheckBox]::IsCheckedProperty) -Index 2 -Name "x200cb" 



$Global:SyncHash = [hashtable]::Synchronized(@{})
$SyncHash.Window = $Window
$Jobs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
$initialSessionState = [initialsessionstate]::CreateDefault()

function Start-RunspaceTask
{
  [CmdletBinding()]
  param([Parameter(Mandatory = $True,Position = 0)] [scriptblock]$ScriptBlock,
    [Parameter(Mandatory = $True,Position = 1)] [PSObject[]]$ProxyVars)

  $Runspace = [runspacefactory]::CreateRunspace($InitialSessionState)
  $Runspace.ApartmentState = 'STA'
  $Runspace.ThreadOptions = 'ReuseThread'
  $Runspace.Open()
  foreach ($Var in $ProxyVars) { $Runspace.SessionStateProxy.SetVariable($Var.Name,$Var.Variable) }
  $Thread = [powershell]::Create('NewRunspace')
  $Thread.AddScript($ScriptBlock) | Out-Null
  $Thread.Runspace = $Runspace
  [void]$Jobs.Add([psobject]@{ PowerShell = $Thread; Runspace = $Thread.BeginInvoke() })
}

$JobCleanupScript = {
  do
  {
    foreach ($Job in $Jobs)
    {
      if ($Job.Runspace.IsCompleted)
      {
        [void]$Job.PowerShell.EndInvoke($Job.Runspace)
        $Job.PowerShell.Runspace.Close()
        $Job.PowerShell.Runspace.Dispose()
        $Job.PowerShell.Dispose()

        $Jobs.Remove($Job)
      }
    }

    Start-Sleep -Seconds 1
  }
  while ($SyncHash.CleanupJobs)
}

Get-ChildItem Function: | Where-Object { $_.Name -notlike "*:*" } | Select-Object name -ExpandProperty name |
ForEach-Object {
  $Definition = Get-Content "function:$_" -ErrorAction Stop
  $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList "$_",$Definition
  $InitialSessionState.Commands.Add($SessionStateFunction)
}


$Window.Add_Closed({
    Write-Verbose 'Halt runspace cleanup job processing'
    $SyncHash.CleanupJobs = $False
  })

$SyncHash.CleanupJobs = $True
function Async ($scriptBlock) { Start-RunspaceTask $scriptBlock @([psobject]@{ Name = 'DataContext'; Variable = $DataContext },[psobject]@{ Name = "State"; Variable = $State },[psobject]@{ Name = "SyncHash"; Variable = $SyncHash }) }

Start-RunspaceTask $JobCleanupScript @([psobject]@{ Name = 'Jobs'; Variable = $Jobs })


#############################################################################################################################################################################################################
# Ende GUI Zeug
#############################################################################################################################################################################################################



# Verhindert, dass eine PowerShell-Konsole angezeigt wird (lediglich GUI wird an Frontend ausgegeben)
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(),0)

# State-Variables: Programm ist multithreaded - diese Variablen sind aus jedem Thread heraus lesend/schreibend zugreifbar
$State.Systempath = $Systempath
$State.SystemCommand = $SystemCommand
$State.SystemProfile = $SystemProfile
$State.Program = $Program

$State.input = $input

$State.Infiles = @()
$State.tmpFiles = @()
$State.tmpFiles2 = @()
$State.outFiles = @()

$State.M200Infiles = @()
$State.M200tmpFiles = @()
$State.M200tmpFiles2 = @()
$State.M200outFiles = @()

$State.X200Infiles = @()
$State.X200tmpFiles = @()
$State.X200tmpFiles2 = @()
$State.X200outFiles = @()

$State.WorkingDir
$State.WorkingDirTemp


# M200-spezifische Änderungen
function Run-M200 () {
  $State.x200cb | Set-Content "C:\Users\philip\Code\output.txt"
}


# X200-spezifische Änderungen
function Run-X200 () {

}


$Window.ShowDialog()
