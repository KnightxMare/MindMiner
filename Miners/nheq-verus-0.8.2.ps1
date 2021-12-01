<#
MindMiner  Copyright (C) 2017-2021  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::CPU) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$from = $Devices[[eMinerType]::CPU].Cores
$to = $Devices[[eMinerType]::CPU].Threads
if ([Config]::DefaultCPU) {
	$from = [Config]::DefaultCPU.Cores
	$to = [Config]::DefaultCPU.Threads
}
$Algorithms = @()
for ($t = $from; $t -le $to; $t++) {
	$Algorithms += [AlgoInfoEx]@{ Enabled = $true; Algorithm = "verushash"; ExtraArgs = "-t $t" }
}

$Cfg = [BaseConfig]::ReadOrCreate([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename), @{
	Enabled = $true
	BenchmarkSeconds = 60
	ExtraArgs = $null
	Algorithms = $Algorithms
})

if (!$Cfg.Enabled) { return }

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				# CPU
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				if ($extrargs -notmatch "-t ") {
					$extrargs = Get-Join " " @($extrargs, "-t $($Devices["CPU"].Threads)")
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::CPU
					API = "nheq_verus"
					URI = "https://mindminer.online/miners/CPU/nheqminer-v0.8.2.zip"
					Path = "$Name\nheqminer.exe"
					ExtraArgs = $extrargs
					Arguments = "-v -l $($Pool.Hosts[0]):$($Pool.PortUnsecure) -u $($Pool.User) -p $($Pool.Password) -a 4100 $extrargs"
					Port = 4100
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
				}
			}
		}
	}
}