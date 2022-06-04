function Write-ToLog {
    param(
      [string]$logmessage
    )

    If (!(Test-Path (Join-path $PSScriptRoot "logs"))){
        New-Item -ItemType Directory -Path (Join-path $PSScriptRoot "logs")
    }

    $logmessage = ((Get-Date).ToString()) + $logmessage
    $logmessage | Out-File -Append -FilePath (Join-path $PSScriptRoot "logs" "log.log")
  }

Get-ADComputer

Write-ToLog -logmessage ($error[0].ToString() + $error[0].InvocationInfo.PositionMessage)