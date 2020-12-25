<#
MindMiner  Copyright (C) 2018-2020  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::nVidia) { exit }
if (![Config]::Is64Bit) { exit }
if ([Config]::CudaVersion -lt [version]::new(9, 1)) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = ReadOrCreateMinerConfig "Do you want use to mine the '$Name' miner" ([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename)) @{
	Enabled = $true
	BenchmarkSeconds = 90
	ExtraArgs = $null
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "aergo" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "bcd" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "bitcore" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "c11" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "hex" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "hsr" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "kawpow"; BenchmarkSeconds = 120 }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "phi" } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "phi2" } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "phi2-lux" } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "poly"; BenchmarkSeconds = 120 } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "skunk" } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "sonoa" } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "timetravel" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "tribus"; BenchmarkSeconds = 120 }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "vit" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "x16r"; BenchmarkSeconds = 120 } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "x16r"; BenchmarkSeconds = 120; ExtraArgs="-i 22" }  # t-rex faster
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x16rv2"; BenchmarkSeconds = 120 } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x16rv2"; BenchmarkSeconds = 120; ExtraArgs="-i 22" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "x16s"; BenchmarkSeconds = 120 } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "x17"; BenchmarkSeconds = 120 } # t-rex faster
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; BenchmarkSeconds = 120 }
)}

if (!$Cfg.Enabled) { return }

$url =  "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.1.zip"
if ([Config]::CudaVersion -ge [version]::new(10, 1)) { $url = "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.1.zip" }
elseif ([Config]::CudaVersion -ge [version]::new(10, 0)) { $url = "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.0.zip" }
elseif ([Config]::CudaVersion -ge [version]::new(9, 2)) { $url = "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.2.zip" }

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				if ($_.Algorithm -match "phi2-lux") { $_.Algorithm = "phi2" }
				$N = Get-CCMinerStatsAvg $Algo $_
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$hosts = [string]::Empty
				$Pool.Hosts | ForEach-Object {
					$hosts = Get-Join " " @($hosts, "-o stratum+tcp://$_`:$($Pool.PortUnsecure) -u $($Pool.User) -p $($Pool.Password)")
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::nVidia
					API = "ccminer"
					URI = $url
					Path = "$Name\z-enemy.exe"
					ExtraArgs = $extrargs
					Arguments = "-a $($_.Algorithm) $hosts -R $($Config.CheckTimeout) -q $N --api-bind=4068 --api-bind-http=0 $extrargs"
					Port = 4068
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = 1
				}
			}
		}
	}
}