<#
MindMiner  Copyright (C) 2018  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

class DeviceInfo {
	[string] $Name
}

class CPUInfo : DeviceInfo {
	[int] $Cores
	[int] $Threads
	[int] $Clock
	[string] $Features
	# [decimal] $Load
}

class GPUInfo : DeviceInfo {
	[decimal] $Load
	[decimal] $LoadMem
	[decimal] $Temperature
	[decimal] $Fan
	[decimal] $Power
	[decimal] $PowerLimit
	[decimal] $Clock
	[decimal] $ClockMem
}