
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
function test-test {
    Start-Sleep -Seconds 5
    Write-Host "Test" -ForegroundColor Green
    
}
function Run-M200(){
    $State.tabIndex = 1

    if ($error.count -gt 0){
        $State.tabIndex = 2
        test-test

    }

}

function Run-X200(){
    $State.tabIndex = 1
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



