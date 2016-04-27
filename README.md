# PowerBash
<img src="http://i.imgur.com/Wzkn5Fr.gif" width="75%" height="75%"/>

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

## What Commands Are Available?
PowerBash looks in locations in the Linux Subsystem's filesystem for programs, equivalent to the following `$PATH`:
```
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/gcc/x86_64-linux-gnu/4.8:/usr/games
```
This is currently hardcoded, although I plan on making it configurable in future.

Any existing commands available to the current PowerShell session, including EXEs in the PowerShell `$env:PATH`, cmdlets, functions, and aliases, will not be overridden by Linux programs.  If you would like to use a Linux program of the same name instead, remove all functions, cmdlets, and aliases from your session prior to importing the module.  For EXEs, you can pass the names of the programs you want overriden to the module via `-ArgumentList` when importing (comma separated).

For example, `sort` is an alias for `Sort-Object` in PowerShell, and the Win32 utility, `sort.exe`, is normally on your `$env:PATH`.  To use the Linux `sort` utility instead, first remove the PowerShell alias:
```
Remove-Item alias:sort -Force
```
And then import PowerBash, passing `"sort"` to `-ArgumentList`:
```
Import-Module PowerBash\PowerBash.psm1 3>$null -ArgumentList "sort"
```

### apt-get
`apt-get` is treated specially.  Whenever `[sudo] apt-get install ...` is run, PowerBash is reloaded, causing the newly installed program to be instantly available.

## Converting Paths from Windows to Linux Versions
The function `ConvertTo-LinuxPath` (alias `lxp`) is provided, to allow easier conversion between Windows versions of paths and the Linux equivalents.

For convenience, I've added a PSReadLine key handler for **Alt-L**, which will change Windows paths to Linux paths in place in the console:

<img src="http://i.imgur.com/qlqBhJB.gif" width="75%" height="75%" />

(Note: `ConvertTo-LinuxPath` is a quick and dirty implementation.  It probably doesn't handle all escaping properly.)

## Caveats/Implementation Details
When imported, PowerBash locates available Linux programs, and adds a wrapper for each one.  Each wrapper handles pipe input and other arguments, and launches something like `bash.exe -c "$Program $Args < $PipeArgs"`.  Note that this incurs the performance overhead of launching a new `bash.exe` process for every command.

[This bug](https://github.com/Microsoft/BashOnWindows/issues/2) ([UserVoice page](https://wpdev.uservoice.com/forums/266908-command-prompt-console-bash-on-ubuntu-on-windo/suggestions/13425768-allow-windows-programs-to-spawn-bash)) currently makes it impossible to connect the `bash.exe` process` stdin/stdout/stderr to anything other than the console, which means piping directly to and from it cannot be done.  As a consequence, PowerBash is designed around avoiding any scenario where PowerShell will try to redirect the input or output streams.  

Unfortunately, this requires the use of temporary files for communication between PowerShell and the Linux Subsystem, which hurts performance.  In playing with it myself, I haven't found it noticeable, but YMMV.

It was also necessary to add some hacky command introspection, involving examining ASTs to determine whether or not PowerShell will redirect the output of `bash.exe` somewhere other than the console, which allows interactive apps to function alongside those used in pipelines.  While I think I've covered most common scenarios with this, I have no doubt that there are some ways in which this breaks.  If you see `Error: 0x80070057` after running a command, please open a bug.
