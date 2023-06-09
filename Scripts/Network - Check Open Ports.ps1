# Example command
#Specify the -PORTS to test against.
#.\Check-Open-Ports.ps1 -COMPUTER CWYEQ01-cluscas -PORTS 80, 135, 445, 1556, 2910, 2941, 3343, 3389, 5120
#.\Check-Open-Ports.ps1 -COMPUTER 10.23.75.33 -PORTS 80, 9100, 515, 631, 52000, 5100

<#
.SYNOPSIS
This checks a remote computer for open ports by attempting a TCP socket connection
to the specified port(s).

.DESCRIPTION
Use the parameter -computer to specify the target computer, and the parameter
-ports to specify ports to check.

It will try to determine if you pass an IP or a DNS name. Use -ignoreDNS to try
to check for open ports even if it's determined not to be an IP and DNS lookup
fails.

Use -ping to also try to ICMP ping the target computer.

Example: .\Check-Open-Ports.ps1 -computer server01 -ports 3389, 445, 80 -ping

Author: Joakim Svendsen, Svendsen Tech
http://www.powershelladmin.com

.PARAMETER Computer
Target computer name or IP address.
.PARAMETER Ports
Ports to check whether are open. Array of integers. Separate ports with commas.
.PARAMETER Ping
Switch. Try to ping the target computer as well if this is specified.
.PARAMETER IgnoreDNS
Switch. Specify this to check for open ports even if DNS lookup fails.
#>

param([Parameter(Mandatory=$true)][string] $Computer,
      [Parameter(Mandatory=$true)][int[]] $Ports,
      [switch] $Ping,
      [switch] $IgnoreDNS
     )


# I know there are ways to match 0-255 only, but I'm keeping it simple
[bool] $IsIp = $false

if ($Computer -match '\A(?:\d{1,3}\.){3}\d{1,3}\z') {
    
    $IsIp = $true
    Write-Output "'$Computer' looks like an IPv4 address. Skipping DNS lookup."
    
}

if ($IsIp -ne $true) {
    
    Write-Output 'Trying a DNS lookup.'
    
    # Do a DNS lookup with a .NET class method. Suppress error messages.
    $ErrorActionPreference = 'SilentlyContinue'
    
    $Ips = [System.Net.Dns]::GetHostAddresses($Computer) | Foreach { $_.IPAddressToString }
    
    if ($?) {
        
        Write-Output 'IP address(es) from DNS:' ($Ips -join ', ')
        
    }
    
    else {
        
        if ($IgnoreDNS) {
            
            Write-Output "WARNING: Could not resolve DNS name, but -IgnoreDNS was specified. Proceeding."
            
        }
        
        else {
            
            Write-Output "Could not resolve DNS name and -IgnoreDNS not specified. Exiting with code 1."
            exit 1
            
        }
        
    }
    # Make errors visible again
    $ErrorActionPreference = 'Continue'
    
}

if ($ping) {
    
    if (Test-Connection -Count 1 -ErrorAction SilentlyContinue $Computer) {
        
        Write-Output "$Computer responded to ICMP ping"
        
    }
    
    else {
        
        Write-Output "$Computer did not respond to ICMP ping"
        
    }
    
}

foreach ($Port in $Ports) {
    
    $private:socket = New-Object Net.Sockets.TcpClient
    
    # Suppress error messages
    $ErrorActionPreference = 'SilentlyContinue'
    
    # Try to connect
    $private:socket.Connect($Computer, $Port)
    
    # Make error messages visible again
    $ErrorActionPreference = 'Continue'
    
    if ($private:socket.Connected) {
        
        Write-Output "${Computer}: Port $port is open"
        $private:socket.Close()
        
    }
     
    else {
        
        Write-Output "${Computer}: Port $port is closed or filtered"
        
    }
    
    $private:socket = $null
    
}
