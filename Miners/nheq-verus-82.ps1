<#
MindMiner  Copyright (C) 2017-2020  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::CPU) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$algos = @()
if ([Config]::DefaultCPU) {
	$algos += [AlgoInfoEx]@{ Enabled = $true; Algorithm = "verus"; ExtraArgs = "-t $([Config]::DefaultCPU.Threads)" }
}
else {
	for ([int] $i = $Devices["CPU"].Cores; $i -le $Devices["CPU"].Threads; $i++) {
		$algos += [AlgoInfoEx]@{ Enabled = $true; Algorithm = "verus"; ExtraArgs = "-t $i" }
	}
}

$Cfg = ReadOrCreateMinerConfig "Do you want use to mine the '$Name' miner" ([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename)) @{
	Enabled = $true
	BenchmarkSeconds = 90
	ExtraArgs = $null
	Algorithms = $algos
}

if (!$Cfg.Enabled) { return }

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$threads = [string]::Empty
				if ($extrargs -notmatch "-t ") {
					$threads = "-t $($Devices["CPU"].Cores)"
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::CPU
					API = "nheq_verus"
					URI = "http://mindminer.online/miners/CPU/nheqminer-v0.8.2.zip"
					Path = "$Name\nheqminer.exe"
					ExtraArgs = $extrargs
					Arguments = "-v -l $($Pool.Hosts[0]):$($Pool.PortUnsecure) -u $($Pool.User) -p $($Pool.Password) -a 4046 $threads $extrargs"
					Port = 4046
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
				}
			}
		}
	}
}