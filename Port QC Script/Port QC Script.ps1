<#
    .SYNOPSIS
        This script provides an interactive command-line interface for running port quality control (QC) checks.

    .DESCRIPTION
        The script includes two primary modes of operation: An automated port QC check mode and a verbose QC check mode.
        Please view the code comments for details on each mode

    .NOTES
        Name: Port QC Tool
        Version: 1.0
        Author: James Stevens
        Creation Date: 08.06.23
#>

# Define an array of websites to test
$websites = @("yahoo.com",
               "gmail.com",
               "aol.com",
               "portal.office.com")

# Function to show the interactive Menu
function Show-Menu {
    param ([string] $title = 'Port QC Tool')
    Clear-Host
    Write-Host "|------- $title -------|" -ForegroundColor Green
    Write-Host "`n[1] - Fully Automated Port QC Check (Provides Pass|Fail)`n[2] - Verbose Port QC Check`n[Exit] - Ctrl + C"
}

# Function to allow user input for choices to be made from the main menu options
function Start-MainFunction {
    $validChoice - $false
    Show-Menu
    do {
        $choice = Read-Host "`nPlease make a selection"
        switch ($choice) {
            '1' {
                Start-AutomatedQC
                $validChoice = $true
            }
            '2' {
                Start-VerboseQC
                $validChoice = $true
            }
            default {
                Write-Host "Invalid choice selected!" -ForegroundColor Red
                Invoke-BreakMenu
            }
        }
    } while (-not $validChoice)
}

# Function to close the loop on functions and return to the main menu
function Invoke-BreakMenu {
    Read-Host "Press Enter To Continue"
    Clear-Host
}

# Function for Option 1 - Running the fully automated port QC check procedure
function Start-AutomatedQC {
    if (Invoke-EthernetVerification) {
        Invoke-WebsiteConnectivityCheck
    } else {
        Invoke-BreakMenu
    }
}

# Function for Option 2 - Running the verbose port QC check procedure
function Start-VerboseQC {
    Get-AdapterInfo
    Test-Websites
}

# Function for verifying if an active ethernet adapter is being used and confirming the 3rd octet of the associated IP address
function Invoke-EthernetVerification {
    # Initialize a variable to keep track of whether an ethernet adapter is active
    $activeEthernetValue = $false

    # Verify a specific ethernet adapter is the specified NIC used for the network port connection
    # Adjust the -InterfaceDescription accordingly to match your specified adapter
    if ($adapter = Get-NetAdapter -InterfaceDescription "*AX211*" | Where-Object {$_.Status -eq "Up"}) {
        $activeEthernetValue = $true
        Write-Host "Confirmed Ethernet Adapter Is Currently Active"

        # Obtain the current IP address of the adapter
        $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
        foreach ($address in $ip) {

            # Split the IP address into octets
            $octets = $address.IPAddress.Split('.')

            # Check if the third octet is a specified number of your choice e.g. 0, 1, 26, etc.
            # Note for my specific use-case, the third octet determines which VLAN is being used; adjust code for this function accordingly as needed
            if ($octets[2] -eq 1 -or $octets[2] -eq 27) {
                Write-Host "Confirmed The Ethernet Adapter Is In The Proper VLAN"
            } else {
              
                Write-Host "The Ethernet Adapater Is Not In The Proper VLAN" -ForegroundColor Red
                $activeEthernetValue = $false
                return $activeEthernetValue
            }
        }
    } else {
        Write-Host "The Specified Adapter Is Not Currently Active | An Unspecified Adapter Is Likely Being Used" -ForegroundColor Red
        $activeEthernetValue = $false
        
    }
    return $activeEthernetValue
}

# Function for testing connectivity to defined websites and if succesful state the full QC check passed or failed
function Invoke-WebsiteConnectivityCheck {
    # Defines an array of sites that have failed when performing the connection test below
    $failedWebsites = @()
    foreach ($website in $websites) {
        try {
            $result = Test-Netconnection -ComputerName $website -InformationLevel Quiet
            if (!$result) {
                $failedWebsites += $website
            }
        } catch {
            Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
        }
    }

    if($failedWebsites.Count -eq 0) {
        Write-Host "Connection To All Sites Was Successful"
        Write-Host "`nPort QC Check Passed!`n" -ForegroundColor Green
        Invoke-BreakMenu
    } else {
        Clear-Host
        Write-Host "`nConnection Failed To The Following Sites:"
        foreach ($failedWebsite in $failedWebsites) {
            Write-Host "- $failedWebsite"
            Write-Host "Automated Port QC Failed | Failed To Connect To Sites Listed Above" -ForegroundColor Red
            Invoke-BreakMenu
        }
    }
}

# Function to obtain all active network adapters and list their IP address
function Get-AdapterInfo {
    Write-Host "`nCurrent Active Network Adapters:" -ForegroundColor Yellow

    # Obtain all active network adapters
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

    foreach ($adapter in $adapters) {
        Write-Host "Adapter Name: $($adapter.Name)"
        Write-Host "Adapter Interface Description: $($adapter.InterfaceDescription)"

        # Get current IP address for the adapters
        $ips = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
        foreach ($ip in $ips) {
            Write-Host "IP Address: $($ip.IPAddress)"
        }
    }
}

function Test-Websites {
    Write-Host "`nVerifying Network Connectivity:" -ForegroundColor Yellow

    foreach ($website in $websites) {
        try {
            $result = Test-NetConnection -ComputerName $website -InformationLevel Quiet
            if ($result) {
                Write-Host "- Successfully connected to $website`n"
            } else {
                Write-Host "- Failed to connect to $website`n"
            }
        } catch {
            Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
        }
    }
    Invoke-BreakMenu
}

Start-MainFunction