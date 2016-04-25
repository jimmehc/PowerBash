# PowerBash
![](http://i.imgur.com/Wzkn5Fr.gif)

Module which allows you to run bash commands and other Linux programs from the Windows Subsystem for Linux directly from PowerShell, with support for piping to and from PowerShell commands.

## Quick Start
Ensure you are running a recent Windows 10 Insiders build (>14316), and [set up the Subsystem for Linux](https://blogs.windows.com/windowsexperience/2016/04/06/announcing-windows-10-insider-preview-build-14316/).

Grab the necessary files by cloning this repo:
```
git clone https://github.com/jimmehc/PowerBash.git
```

And import the PowerBash module (PowerShell doesn't like function names like "apt-get", so redirect the warning stream to $null to avoid that warning message):
```
Import-Module PowerBash\PowerBash.psm1 3>$null
```

## Converting Paths from Windows to Linux Versions
The function `ConvertTo-LinuxPath` (alias `lxp`) is provided, to allow easier conversion between Windows versions of paths and the Linux equivalents.

For convenience, I've added a PSReadLine key handler for **Alt-L**, which will change Windows paths to Linux paths in place in the console:
![](http://i.imgur.com/qlqBhJB.gif)
