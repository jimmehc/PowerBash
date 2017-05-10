$script:thisModulePath = $MyInvocation.MyCommand.ScriptBlock.Module.Path

function ConvertTo-LinuxPath
{
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Path
    )

    if($Path.StartsWith("\\"))
    {
        Write-Error "UNC paths not currently supported"
        return
    }

    if($Path -match "^(\`"?)([A-Za-z])\:\\")
    {
        $quote = $Matches[1]
        $driveLetter = $Matches[2]

        if($driveLetter)
        {
            $Path = $Path -replace "^$quote$driveLetter\:\\","$quote/mnt/$($driveLetter.ToLower())/"
        }
    }

    $Path = $Path -replace "\\","/"
    $Path = $Path -replace " ","\ "
    $Path = $Path -replace "\(","\("
    $Path = $Path -replace "\)","\)"

    $Path
}
Set-Alias lxp ConvertTo-LinuxPath

function Get-AllBashApps
{
    $bashFSRoot = "$env:LOCALAPPDATA\lxss\rootfs"
    $bashPATH = "/usr/local/sbin","/usr/local/bin","/usr/sbin","/usr/bin","/sbin","/bin","/usr/lib/gcc/x86_64-linux-gnu/4.8","/usr/games"
    $allBashApps = @()
    foreach($path in $bashPATH)
    {
        $allBashApps += Get-ChildItem "$bashFSRoot$path" | ?{ $_.Extension -eq "" -and ("[") -notcontains $_.Name } |
                            Foreach-Object { [pscustomobject]@{ Name = $_.Name; Path = "$path/$($_.Name)" } }
    }

    $allBashApps
}

function Add-BashWrappers
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        $BashApps,
        [Parameter(Position=1, Mandatory=$false)]
        [string[]]$Overwrite=@()
    )

    $allPSCommandsHash = @{}
    foreach($c in ((Get-Command *).Name -replace "\.exe$",""))
    {
         if($Overwrite -notcontains $_ )
         { 
             $allPSCommandsHash[$c] = $true;
         }
    }

    foreach($app in $BashApps)
    {
        if(!$allPSCommandsHash[$app.Name])
        {
            New-Item -Path function: -Name $app.Name -Value {
                begin
                {
                    $filteredArgs = New-Object System.Collections.ArrayList
                    foreach($a in $args)
                    {
                        if($a -ne "--%")
                        {
                            $filteredArgs += $a
                        }
                    }

                    $bashCommandStr = "$($app.Path) $filteredArgs"
                    $bashArgs = "-c",$bashCommandStr
                }

                end 
                {
                    if(@($input).Count -gt 0)
                    {
                        $input.Reset()
                        $input | & "bash.exe" $bashArgs
                    }
                    else
                    {
                        & "bash.exe" $bashArgs
                    }

                    if(($filteredArgs.Length -ge 3 -and $app.Name -eq "sudo" -and ("apt-get","apt") -contains $filteredArgs[0] -and $filteredArgs[1] -eq "install") -or
                            ($filteredArgs.Length -ge 2 -and ("apt-get","apt") -contains $app.Name -and $filteredArgs[0] -eq "install"))
                    {
                        Import-Module $script:thisModulePath -Force -Global -DisableNameChecking
                    }
                }
            }.GetNewClosure()

            Export-ModuleMember -Function $app.Name
            $allPSCommandsHash[$app.Name] = $true
        }
    }
}

$script:allBashApps = Get-AllBashApps
. Add-BashWrappers $script:allBashApps $args

Set-PSReadlineKeyHandler -Key "Alt+l" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $tokenToChange = $null
    foreach ($token in $tokens)
    {
        $extent = $token.Extent
        if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor)
        {
            $tokenToChange = $token

            if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext())
            {
                $nextToken = $foreach.Current
                if ($nextToken.Extent.StartOffset -eq $cursor)
                {
                    $tokenToChange = $nextToken
                }
            }
            break
        }
    }

    if ($tokenToChange -ne $null)
    {
        $extent = $tokenToChange.Extent
        $tokenText = $extent.Text
        $replacement = ConvertTo-LinuxPath $tokenText

        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $extent.StartOffset,
            $tokenText.Length,
            $replacement)
    }
}

Export-ModuleMember -Function ConvertTo-LinuxPath
Export-ModuleMember -Alias lxp
