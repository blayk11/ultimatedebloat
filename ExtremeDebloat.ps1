<#
.SYNOPSIS
    ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER (SMOOTH TUI v2)
    Author: blayk11 (https://github.com/blayk11)
.DESCRIPTION
    Universal, modular, and safe debloat and latency optimization script for Windows 10 & 11.
    Interactive TUI with dynamic pagination (Zero Flicker / Zero Scroll Overflow),
    keyboard navigation via ARROW keys / PageUp / PageDown, checkbox selection [X], and hotkeys 'A', 'N', 'I'.
#>

# Force UTF-8 console encoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Administrator auto-elevation (compatible with local and remote irm/iex execution)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Elevating permissions to Administrator..."
    if ($PSCommandPath) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/blayk11/ultimatedebloat/main/ExtremeDebloat.ps1 | iex`"" -Verb RunAs
    }
    exit
}

# ==============================================================================
# SAFE REGISTRY HELPERS (WITH AUTOMATIC FALLBACK TO REG.EXE)
# ==============================================================================
function Set-RegDWord {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type DWord -Value $Value -Force -ErrorAction Stop | Out-Null
    } catch {
        $regPath = $Path.Replace("HKLM:\", "HKLM\").Replace("HKCU:\", "HKCU\")
        cmd.exe /c "reg add `"$regPath`" /v `"$Name`" /t REG_DWORD /d $Value /f" 2>$null | Out-Null
    }
}

function Set-RegString {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type String -Value $Value -Force -ErrorAction Stop | Out-Null
    } catch {
        $regPath = $Path.Replace("HKLM:\", "HKLM\").Replace("HKCU:\", "HKCU\")
        cmd.exe /c "reg add `"$regPath`" /v `"$Name`" /t REG_SZ /d `"$Value`" /f" 2>$null | Out-Null
    }
}

function Remove-RegValue {
    param (
        [string]$Path,
        [string]$Name
    )
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {
        $regPath = $Path.Replace("HKLM:\", "HKLM\").Replace("HKCU:\", "HKCU\")
        cmd.exe /c "reg delete `"$regPath`" /v `"$Name`" /f" 2>$null | Out-Null
    }
}

function Install-SpecificUwpApp {
    param (
        [string]$Pattern,
        [string]$Label,
        [string]$WingetId
    )
    Write-Host " [*] Restoring App: $Label..." -ForegroundColor Yellow

    # Method 1: Try registering from provisioned image cache
    $registered = $false
    try {
        $pkg = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $Pattern }
        if ($pkg) {
            $manifestPath = (Get-ChildItem -Path "C:\Program Files\WindowsApps" -Recurse -Filter "AppxManifest.xml" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*$($pkg.DisplayName)*" } | Select-Object -First 1).FullName
            if ($manifestPath) {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifestPath -ErrorAction SilentlyContinue
                $registered = $true
            }
        }
    } catch {}

    # Method 2: Fallback to winget if ID is provided and not restored yet
    if (-not $registered -and $WingetId) {
        Write-Host "   [-] Downloading & reinstalling via winget ($WingetId)..." -ForegroundColor DarkGray
        winget install --id $WingetId --exact --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
    }
}

# ==============================================================================
# SMOOTH & STABLE TUI ENGINE (ZERO-FLICKER & DYNAMIC PAGINATION)
# ==============================================================================
function Show-MultiSelectMenu {
    param (
        [string]$Title,
        [string]$Subtitle,
        [System.Collections.Generic.List[PSObject]]$Items
    )

    $selectedIndex = 0
    $scrollOffset = 0
    $totalItems = $Items.Count

    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host

    # Fixed header rendering
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              " -ForegroundColor Yellow
    Write-Host "             Created by: blayk11 | https://github.com/blayk11             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " [CATEGORY]: $Title" -ForegroundColor Green
    if ($Subtitle) {
        Write-Host " $Subtitle" -ForegroundColor DarkGray
    }
    Write-Host " ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [Arrows / PgUp / PgDn]: Navigate  |  [Space]: Toggle Checkbox [X]" -ForegroundColor Cyan
    Write-Host " [A]: Select All    |    [N]: Deselect All    |    [I]: Invert" -ForegroundColor Cyan
    Write-Host " [Enter]: Confirm & Execute    |    [ESC / Q]: Cancel / Return" -ForegroundColor Yellow
    Write-Host " ========================================================================" -ForegroundColor DarkGray

    # Precise top position for the list
    $listStartTop = [Console]::CursorTop

    while ($true) {
        $winHeight = [Console]::WindowHeight
        if ($winHeight -lt 20) { $winHeight = 25 }
        $winWidth = [Console]::WindowWidth
        if ($winWidth -lt 80) { $winWidth = 80 }

        # Calculate max visible items with safe margin to prevent console buffer scrolling
        $maxVisible = [Math]::Max(6, $winHeight - $listStartTop - 4)
        if ($maxVisible -gt $totalItems) { $maxVisible = $totalItems }

        # Adjust scrolling window
        if ($selectedIndex -lt $scrollOffset) {
            $scrollOffset = $selectedIndex
        } elseif ($selectedIndex -ge ($scrollOffset + $maxVisible)) {
            $scrollOffset = $selectedIndex - $maxVisible + 1
        }

        # Count selected items
        $selectedCount = ($Items | Where-Object { $_.Selected }).Count

        # Reposition cursor to top of the list (Zero-Flicker)
        [Console]::SetCursorPosition(0, $listStartTop)

        # Scroll up indicator
        $upIndicator = if ($scrollOffset -gt 0) { "   ^ (... more items above ...)" } else { " " }
        $upPadding = $winWidth - $upIndicator.Length - 1
        if ($upPadding -gt 0) { $upIndicator += (" " * $upPadding) }
        Write-Host $upIndicator -ForegroundColor DarkYellow

        # Render visible item slice
        for ($i = 0; $i -lt $maxVisible; $i++) {
            $itemIndex = $scrollOffset + $i
            if ($itemIndex -lt $totalItems) {
                $item = $Items[$itemIndex]
                $check = if ($item.Selected) { "[X]" } else { "[ ]" }
                $prefix = if ($itemIndex -eq $selectedIndex) { " > " } else { "   " }
                
                $lineText = "$prefix$check $($item.Label)"
                $padding = $winWidth - $lineText.Length - 1
                if ($padding -gt 0) { $lineText += (" " * $padding) }
                if ($lineText.Length -ge $winWidth) { $lineText = $lineText.Substring(0, $winWidth - 1) }

                if ($itemIndex -eq $selectedIndex) {
                    Write-Host $lineText -ForegroundColor Black -BackgroundColor Cyan
                } else {
                    if ($item.Selected) {
                        Write-Host $lineText -ForegroundColor White -BackgroundColor Black
                    } else {
                        Write-Host $lineText -ForegroundColor DarkGray -BackgroundColor Black
                    }
                }
            } else {
                Write-Host (" " * ($winWidth - 1)) -BackgroundColor Black
            }
        }

        # Scroll down indicator
        $downIndicator = if (($scrollOffset + $maxVisible) -lt $totalItems) { "   v (... more items below ...)" } else { " " }
        $downPadding = $winWidth - $downIndicator.Length - 1
        if ($downPadding -gt 0) { $downIndicator += (" " * $downPadding) }
        Write-Host $downIndicator -ForegroundColor DarkYellow

        # Status footer bar
        $statusBar = " [ Item $($selectedIndex + 1) of $totalItems | Selected: $selectedCount/$totalItems ] "
        $statusPad = $winWidth - $statusBar.Length - 1
        if ($statusPad -gt 0) { $statusBar += ("-" * $statusPad) }
        Write-Host $statusBar -ForegroundColor Green -BackgroundColor Black

        # Key capture
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            ([ConsoleKey]::UpArrow) {
                if ($selectedIndex -gt 0) { $selectedIndex-- } else { $selectedIndex = $totalItems - 1 }
            }
            ([ConsoleKey]::DownArrow) {
                if ($selectedIndex -lt ($totalItems - 1)) { $selectedIndex++ } else { $selectedIndex = 0 }
            }
            ([ConsoleKey]::PageUp) {
                $selectedIndex = [Math]::Max(0, $selectedIndex - $maxVisible)
            }
            ([ConsoleKey]::PageDown) {
                $selectedIndex = [Math]::Min($totalItems - 1, $selectedIndex + $maxVisible)
            }
            ([ConsoleKey]::Home) {
                $selectedIndex = 0
            }
            ([ConsoleKey]::End) {
                $selectedIndex = $totalItems - 1
            }
            ([ConsoleKey]::Spacebar) {
                $Items[$selectedIndex].Selected = -not $Items[$selectedIndex].Selected
            }
            ([ConsoleKey]::A) {
                foreach ($item in $Items) { $item.Selected = $true }
            }
            ([ConsoleKey]::N) {
                foreach ($item in $Items) { $item.Selected = $false }
            }
            ([ConsoleKey]::I) {
                foreach ($item in $Items) { $item.Selected = -not $item.Selected }
            }
            ([ConsoleKey]::Enter) {
                try { [Console]::CursorVisible = $true } catch {}
                return $Items
            }
            ([ConsoleKey]::Escape) {
                try { [Console]::CursorVisible = $true } catch {}
                return $null
            }
            ([ConsoleKey]::Q) {
                try { [Console]::CursorVisible = $true } catch {}
                return $null
            }
        }
    }
}

function Pause-Console {
    Write-Host ""
    Write-Host "Press any key to return to the menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# 1. SYSTEM RESTORE POINT
# ==============================================================================
function Invoke-RestorePoint {
    Clear-Host
    Write-Host "[*] Creating Safety System Restore Point..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Pre-Debloat-blayk11" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[+] System restore point created successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Warning: Unable to create restore point ($($_.Exception.Message))" -ForegroundColor Red
    }
    Pause-Console
}

# ==============================================================================
# 2. UWP BLOATWARE & APP PURGE
# ==============================================================================
function Menu-BloatwareApps {
    $apps = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Pattern = "*Microsoft.BingWeather*"; Label = "Weather (Bing Weather)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingNews*"; Label = "News (Bing News)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingFinance*"; Label = "Finance (Bing Finance)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingSports*"; Label = "Sports (Bing Sports)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.GetHelp*"; Label = "Get Help"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Getstarted*"; Label = "Tips / Get Started"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Microsoft3DViewer*"; Label = "3D Viewer"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftOfficeHub*"; Label = "Office Hub (Microsoft 365 Promotions)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftSolitaireCollection*"; Label = "Solitaire Collection"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MixedReality.Portal*"; Label = "Mixed Reality Portal"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.People*"; Label = "People (Microsoft People)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.SkypeApp*"; Label = "Skype"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Todos*"; Label = "Microsoft To Do"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsAlarms*"; Label = "Alarms & Clock"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsFeedbackHub*"; Label = "Feedback Hub"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsMaps*"; Label = "Windows Maps"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsSoundRecorder*"; Label = "Voice Recorder"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.YourPhone*"; Label = "Phone Link"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneMusic*"; Label = "Groove Music / Legacy Media Player"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneVideo*"; Label = "Movies & TV"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Clipchamp.Clipchamp*"; Label = "Clipchamp Video Editor"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.PowerAutomateDesktop*"; Label = "Power Automate Desktop"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Copilot*"; Label = "Microsoft Copilot App"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.549981C3F5F10*"; Label = "Cortana"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.OutlookForWindows*"; Label = "New Outlook (Web Version)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxSpeechToTextOverlay*"; Label = "Xbox Speech to Text Overlay"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGameOverlay*"; Label = "Xbox Game Overlay"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGamingOverlay*"; Label = "Xbox Gaming Overlay (Game Bar)"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GamingApp*"; Label = "Xbox App / PC Game Pass"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*SpotifyAB.SpotifyMusic*"; Label = "Spotify (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*DisneyMagicKingdoms*"; Label = "Disney Magic Kingdoms"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*TikTok*"; Label = "TikTok (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Facebook*"; Label = "Facebook (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Instagram*"; Label = "Instagram (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*CandyCrush*"; Label = "Candy Crush / Sponsored Games"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*PrimeVideo*"; Label = "Prime Video (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Netflix*"; Label = "Netflix (Pre-installed)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.QuickAssist*"; Label = "Quick Assist"; Selected = $false }
    )

    $selected = Show-MultiSelectMenu -Title "REMOVE BLOATWARE & APPS (UWP)" -Subtitle "Use [SPACE] to select the apps you want to permanently remove." -Items $apps
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Removing selected applications..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            Write-Host " [-] Removing: $($item.Label)" -ForegroundColor Magenta
            Get-AppxPackage -Name $item.Pattern -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $item.Pattern } | ForEach-Object {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
    Write-Host "[+] Application removal completed!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 3. TELEMETRY, ADS & COPILOT AI
# ==============================================================================
function Menu-TelemetryAndPrivacy {
    $options = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "BingSearch"; Label = "Disable Bing Web Search in Start Menu"; Selected = $true },
        [PSCustomObject]@{ Id = "Cortana"; Label = "Disable Cortana & Legacy Voice Assistants"; Selected = $true },
        [PSCustomObject]@{ Id = "Copilot"; Label = "Disable Microsoft Copilot AI System-wide"; Selected = $true },
        [PSCustomObject]@{ Id = "Recall"; Label = "Disable Windows Recall / Snapshot AI"; Selected = $true },
        [PSCustomObject]@{ Id = "Ads"; Label = "Disable Windows Ads, Tips & Suggestions"; Selected = $true },
        [PSCustomObject]@{ Id = "Widgets"; Label = "Disable Taskbar Widgets & News Feeds"; Selected = $true },
        [PSCustomObject]@{ Id = "ActivityHistory"; Label = "Disable Activity History & Timeline"; Selected = $true },
        [PSCustomObject]@{ Id = "TelemetryDiag"; Label = "Disable Diagnostic Data Collection & Usage Telemetry"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "TELEMETRY, ADS & COPILOT AI" -Subtitle "Select the telemetry, advertising and tracking features you wish to disable." -Items $options
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Applying selected privacy settings..." -ForegroundColor Yellow

    foreach ($opt in $selected) {
        if (-not $opt.Selected) { continue }
        Write-Host " [+] Applying: $($opt.Label)" -ForegroundColor Cyan
        switch ($opt.Id) {
            "BingSearch" {
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
                Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
            }
            "Cortana" {
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
            }
            "Copilot" {
                Set-RegDWord "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
            }
            "Recall" {
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
            }
            "Ads" {
                $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                Set-RegDWord $cdm "ContentDeliveryAllowed" 0
                Set-RegDWord $cdm "OemPreInstalledAppsEnabled" 0
                Set-RegDWord $cdm "PreInstalledAppsEnabled" 0
                Set-RegDWord $cdm "PreInstalledAppsEverEnabled" 0
                Set-RegDWord $cdm "SilentInstalledAppsEnabled" 0
                Set-RegDWord $cdm "SubscribedContent-338387Enabled" 0
                Set-RegDWord $cdm "SubscribedContent-338388Enabled" 0
                Set-RegDWord $cdm "SubscribedContent-338389Enabled" 0
                Set-RegDWord $cdm "SubscribedContent-353698Enabled" 0
                Set-RegDWord $cdm "SystemPaneSuggestionsEnabled" 0
            }
            "Widgets" {
                Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
            }
            "ActivityHistory" {
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0
            }
            "TelemetryDiag" {
                Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
                Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
            }
        }
    }
    Write-Host "[+] Privacy settings applied successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 4. BACKGROUND SERVICES OPTIMIZATION
# ==============================================================================
function Menu-ServicesOptimization {
    $services = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ ServiceName = "SysMain"; Label = "SysMain / Superfetch (Eliminates redundant disk I/O on SSD/NVMe)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "DiagTrack"; Label = "DiagTrack (Connected User Experiences & Telemetry)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "dmwappushservice"; Label = "dmwappushservice (WAP Push Telemetry)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "MapsBroker"; Label = "MapsBroker (Downloaded Maps Manager)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "Fax"; Label = "Fax (Fax Service)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "RetailDemo"; Label = "RetailDemo (Retail Demo Service)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WpcMonSvc"; Label = "WpcMonSvc (Parental Controls)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "SharedRealitySvc"; Label = "SharedRealitySvc (Spatial / Mixed Reality)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WerSvc"; Label = "WerSvc (Windows Error Reporting)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "PcaSvc"; Label = "PcaSvc (Program Compatibility Assistant)"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "DISABLE BACKGROUND SERVICES" -Subtitle "Select the background services you want to permanently stop and disable." -Items $services
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Disabling selected services..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            $svc = Get-Service -Name $item.ServiceName -ErrorAction SilentlyContinue
            if ($svc) {
                Write-Host " [-] Disabling: $($item.Label)" -ForegroundColor Magenta
                Stop-Service -Name $item.ServiceName -Force -ErrorAction SilentlyContinue
                Set-Service -Name $item.ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[+] Background services optimized successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 5. UNIVERSAL LOW LATENCY & HARDWARE SCHEDULING (CPU / RAM / GPU)
# ==============================================================================
function Menu-LowLatency {
    $tweaks = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "Quantum"; Label = "Win32PrioritySeparation = 38 (Maximum CPU priority for focused apps)"; Selected = $true },
        [PSCustomObject]@{ Id = "GameDVR"; Label = "Disable GameDVR & Background Capture (Eliminates micro-stutters)"; Selected = $true },
        [PSCustomObject]@{ Id = "Multimedia"; Label = "SystemResponsiveness = 0 & NetworkThrottling Off (Minimum latency)"; Selected = $true },
        [PSCustomObject]@{ Id = "GpuPriority"; Label = "High GPU Priority in Multimedia Scheduler (GPU Priority: 8)"; Selected = $true },
        [PSCustomObject]@{ Id = "InstantUI"; Label = "MenuShowDelay = 0 (Instant visual & menu responsiveness)"; Selected = $true },
        [PSCustomObject]@{ Id = "UltimatePower"; Label = "Unlock and Enable 'Ultimate Performance' Power Plan"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "UNIVERSAL LOW LATENCY & HARDWARE TWEAKS" -Subtitle "Select the kernel, scheduling and GPU tweaks you want to apply." -Items $tweaks
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Applying latency tweaks..." -ForegroundColor Yellow
    foreach ($t in $selected) {
        if (-not $t.Selected) { continue }
        Write-Host " [+] Applying: $($t.Label)" -ForegroundColor Cyan
        switch ($t.Id) {
            "Quantum" {
                Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
            }
            "GameDVR" {
                Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
            }
            "Multimedia" {
                Set-RegDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
                Set-RegDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
            }
            "GpuPriority" {
                $gameProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
                Set-RegDWord $gameProfile "Affinity" 0
                Set-RegString $gameProfile "Background Only" "False"
                Set-RegDWord $gameProfile "Clock Rate" 10000
                Set-RegDWord $gameProfile "GPU Priority" 8
                Set-RegDWord $gameProfile "Priority" 6
                Set-RegString $gameProfile "Scheduling Category" "High"
                Set-RegString $gameProfile "SFIO Priority" "High"
            }
            "InstantUI" {
                Set-RegString "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0"
                Set-RegString "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "2000"
                Set-RegString "HKCU:\Control Panel\Desktop" "HungAppTimeout" "1000"
            }
            "UltimatePower" {
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
                $scheme = (powercfg -list | Select-String "Desempenho M.ximo|Ultimate Performance" | ForEach-Object { $_.Line.Split()[3] })
                if ($scheme) { powercfg -setactive $scheme }
            }
        }
    }
    Write-Host "[+] Latency optimizations applied successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 6. DISABLE VBS / CORE ISOLATION
# ==============================================================================
function Invoke-DisableVBS {
    Clear-Host
    Write-Host "[*] Disabling VBS & Security Hypervisor..." -ForegroundColor Yellow
    bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
    Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0
    Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
    Write-Host "[+] VBS / Hypervisor disabled successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 7. DEEP DISK & CACHE CLEANER
# ==============================================================================
function Menu-DeepCleaning {
    $cleanOptions = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Target = "C:\Windows\Temp\*"; Label = "Windows Temporary Files (C:\Windows\Temp)"; Selected = $true },
        [PSCustomObject]@{ Target = "$env:LOCALAPPDATA\Temp\*"; Label = "User Temporary Files (%TEMP%)"; Selected = $true },
        [PSCustomObject]@{ Target = "C:\Windows\SoftwareDistribution\Download\*"; Label = "Windows Update Download Cache"; Selected = $true },
        [PSCustomObject]@{ Target = "C:\Windows\Prefetch\*"; Label = "System Prefetch Cache"; Selected = $true },
        [PSCustomObject]@{ Target = "RecycleBin"; Label = "Empty Recycle Bin"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "DEEP DISK & CACHE CLEANUP" -Subtitle "Select the cache folders and temporary files you wish to purge." -Items $cleanOptions
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Executing deep cleanup..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            Write-Host " [-] Cleaning: $($item.Label)" -ForegroundColor Cyan
            if ($item.Target -eq "RecycleBin") {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item -Path $item.Target -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[+] Cleanup completed successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# RESTORE SUBMENUS (GRANULAR RESTORATION PER CATEGORY)
# ==============================================================================
function Menu-RestoreIndividualApps {
    $restoreApps = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsStore*"; Label = "Microsoft Store (Store Core Installer)"; WingetId = "9WZDNCRFJBMP"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingWeather*"; Label = "Weather (Bing Weather)"; WingetId = "9WZDNCRFJ3Q2"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingNews*"; Label = "News (Microsoft News)"; WingetId = "9WZDNCRFHVFW"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingFinance*"; Label = "Money / Finance (MSN Money)"; WingetId = "9WZDNCRFHV4V"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingSports*"; Label = "Sports (MSN Sports)"; WingetId = "9WZDNCRFHVH4"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GetHelp*"; Label = "Get Help"; WingetId = "9PKDZBMV1R3T"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Getstarted*"; Label = "Tips / Get Started"; WingetId = "9WZDNCRFJBD8"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Microsoft3DViewer*"; Label = "3D Viewer"; WingetId = "9NBLGGH42THS"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftOfficeHub*"; Label = "Office Hub (Microsoft 365)"; WingetId = "9WZDNCRD29V9"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftSolitaireCollection*"; Label = "Solitaire Collection"; WingetId = "9WZDNCRFJ347"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MixedReality.Portal*"; Label = "Mixed Reality Portal"; WingetId = "9NG1H8B3ZC7M"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.People*"; Label = "People (Microsoft People)"; WingetId = "9NBLGGH10PG8"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.SkypeApp*"; Label = "Skype"; WingetId = "9WZDNCRFJ364"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Todos*"; Label = "Microsoft To Do"; WingetId = "9NBLGGH5R558"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsAlarms*"; Label = "Windows Clock & Alarms"; WingetId = "9WZDNCRFJ3PR"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsCalculator*"; Label = "Windows Calculator"; WingetId = "9WZDNCRFJ367"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsFeedbackHub*"; Label = "Feedback Hub"; WingetId = "9NBLGGH4R32N"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsMaps*"; Label = "Windows Maps"; WingetId = "9WZDNCRBXB69"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsSoundRecorder*"; Label = "Voice Recorder / Sound Recorder"; WingetId = "9WZDNCRFHWKN"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.YourPhone*"; Label = "Phone Link"; WingetId = "9NMPJ99VJBWV"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneMusic*"; Label = "Windows Media Player / Groove"; WingetId = "9WZDNCRSUB40"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneVideo*"; Label = "Movies & TV (Films & TV)"; WingetId = "9WZDNCRFJ3P2"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Clipchamp.Clipchamp*"; Label = "Clipchamp Video Editor"; WingetId = "9P1J8S7CCWWT"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.PowerAutomateDesktop*"; Label = "Power Automate"; WingetId = "9NX1NDD33ZGS"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Copilot*"; Label = "Microsoft Copilot App"; WingetId = "9NHT9RB2F4HD"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.OutlookForWindows*"; Label = "Outlook for Windows"; WingetId = "9NRXDXMKZQP7"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGamingOverlay*"; Label = "Xbox Game Bar"; WingetId = "9NZKPSTSNW4P"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GamingApp*"; Label = "Xbox App / PC Gaming"; WingetId = "9MV0B5HZVK9Z"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsTerminal*"; Label = "Windows Terminal"; WingetId = "9N0DX20HK701"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Paint*"; Label = "Paint"; WingetId = "9PCFS5B6T72H"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsNotepad*"; Label = "Notepad"; WingetId = "9MSMLRH6LZF3"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ScreenSketch*"; Label = "Snipping Tool"; WingetId = "9MZ95KL8MR0L"; Selected = $false }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE INDIVIDUAL APPS (REINSTALL / RE-REGISTER)" -Subtitle "Select the specific app(s) you want to reinstall or repair on your PC." -Items $restoreApps
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Restoring selected application packages..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            Install-SpecificUwpApp -Pattern $item.Pattern -Label $item.Label -WingetId $item.WingetId
        }
    }
    Write-Host "[+] App restoration process completed!" -ForegroundColor Green
    Pause-Console
}

function Menu-RestoreIndividualApps {
    $restoreApps = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsStore*"; Label = "Microsoft Store (Store Core Installer)"; WingetId = "9WZDNCRFJBMP"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingWeather*"; Label = "Weather (Bing Weather)"; WingetId = "9WZDNCRFJ3Q2"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingNews*"; Label = "News (Microsoft News)"; WingetId = "9WZDNCRFHVFW"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingFinance*"; Label = "Money / Finance (MSN Money)"; WingetId = "9WZDNCRFHV4V"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingSports*"; Label = "Sports (MSN Sports)"; WingetId = "9WZDNCRFHVH4"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GetHelp*"; Label = "Get Help"; WingetId = "9PKDZBMV1R3T"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Getstarted*"; Label = "Tips / Get Started"; WingetId = "9WZDNCRFJBD8"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Microsoft3DViewer*"; Label = "3D Viewer"; WingetId = "9NBLGGH42THS"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftOfficeHub*"; Label = "Office Hub (Microsoft 365)"; WingetId = "9WZDNCRD29V9"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftSolitaireCollection*"; Label = "Solitaire Collection"; WingetId = "9WZDNCRFJ347"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.MixedReality.Portal*"; Label = "Mixed Reality Portal"; WingetId = "9NG1H8B3ZC7M"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.People*"; Label = "People (Microsoft People)"; WingetId = "9NBLGGH10PG8"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.SkypeApp*"; Label = "Skype"; WingetId = "9WZDNCRFJ364"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Todos*"; Label = "Microsoft To Do"; WingetId = "9NBLGGH5R558"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsAlarms*"; Label = "Windows Clock & Alarms"; WingetId = "9WZDNCRFJ3PR"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsCalculator*"; Label = "Windows Calculator"; WingetId = "9WZDNCRFJ367"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsFeedbackHub*"; Label = "Feedback Hub"; WingetId = "9NBLGGH4R32N"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsMaps*"; Label = "Windows Maps"; WingetId = "9WZDNCRBXB69"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsSoundRecorder*"; Label = "Voice Recorder / Sound Recorder"; WingetId = "9WZDNCRFHWKN"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.YourPhone*"; Label = "Phone Link"; WingetId = "9NMPJ99VJBWV"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneMusic*"; Label = "Windows Media Player / Groove"; WingetId = "9WZDNCRSUB40"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneVideo*"; Label = "Movies & TV (Films & TV)"; WingetId = "9WZDNCRFJ3P2"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Clipchamp.Clipchamp*"; Label = "Clipchamp Video Editor"; WingetId = "9P1J8S7CCWWT"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.PowerAutomateDesktop*"; Label = "Power Automate"; WingetId = "9NX1NDD33ZGS"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Copilot*"; Label = "Microsoft Copilot App"; WingetId = "9NHT9RB2F4HD"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.OutlookForWindows*"; Label = "Outlook for Windows"; WingetId = "9NRXDXMKZQP7"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGamingOverlay*"; Label = "Xbox Game Bar"; WingetId = "9NZKPSTSNW4P"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GamingApp*"; Label = "Xbox App / PC Gaming"; WingetId = "9MV0B5HZVK9Z"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsTerminal*"; Label = "Windows Terminal"; WingetId = "9N0DX20HK701"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.Paint*"; Label = "Paint"; WingetId = "9PCFS5B6T72H"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsNotepad*"; Label = "Notepad"; WingetId = "9MSMLRH6LZF3"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.ScreenSketch*"; Label = "Snipping Tool"; WingetId = "9MZ95KL8MR0L"; Selected = $false }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE INDIVIDUAL APPS (REINSTALL / RE-REGISTER)" -Subtitle "Select the specific app(s) you want to reinstall or repair on your PC." -Items $restoreApps
    if ($null -eq $selected) { return }

    $chosen = @($selected | Where-Object { $_.Selected })
    if ($chosen.Count -eq 0) {
        Clear-Host
        Write-Host "[!] No apps were selected for restoration." -ForegroundColor Yellow
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " RESTORE CONFIRMATION - INDIVIDUAL APPS" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "You have selected $($chosen.Count) application(s) to restore:" -ForegroundColor White
    foreach ($item in $chosen) {
        Write-Host " [X] $($item.Label)" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $confirm = (Read-Host "Do you want to proceed with restoring these apps? (Y/N / S/N)").Trim().ToUpper()
    if ($confirm -ne "Y" -and $confirm -ne "S" -and $confirm -ne "SIM" -and $confirm -ne "YES") {
        Write-Host "[-] Action cancelled by user." -ForegroundColor Red
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "[*] Restoring selected application packages..." -ForegroundColor Yellow
    foreach ($item in $chosen) {
        Install-SpecificUwpApp -Pattern $item.Pattern -Label $item.Label -WingetId $item.WingetId
    }
    Write-Host "[+] App restoration process completed!" -ForegroundColor Green
    Pause-Console
}

function Menu-RestoreIndividualServices {
    $serviceDefaults = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ ServiceName = "SysMain"; Label = "SysMain / Superfetch (Restore to Automatic)"; Startup = "Automatic"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "DiagTrack"; Label = "DiagTrack / Telemetry (Restore to Automatic)"; Startup = "Automatic"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "dmwappushservice"; Label = "dmwappushservice (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "MapsBroker"; Label = "MapsBroker / Downloaded Maps (Restore to Automatic)"; Startup = "Automatic"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "Fax"; Label = "Fax Service (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "RetailDemo"; Label = "Retail Demo Service (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WpcMonSvc"; Label = "Parental Controls (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "SharedRealitySvc"; Label = "Spatial / Mixed Reality Service (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WerSvc"; Label = "Windows Error Reporting (Restore to Manual)"; Startup = "Manual"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "PcaSvc"; Label = "Program Compatibility Assistant (Restore to Manual)"; Startup = "Manual"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE BACKGROUND SERVICES" -Subtitle "Select which specific service(s) you want to re-enable and restore to defaults." -Items $serviceDefaults
    if ($null -eq $selected) { return }

    $chosen = @($selected | Where-Object { $_.Selected })
    if ($chosen.Count -eq 0) {
        Clear-Host
        Write-Host "[!] No services were selected for restoration." -ForegroundColor Yellow
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " RESTORE CONFIRMATION - BACKGROUND SERVICES" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "You have selected $($chosen.Count) service(s) to restore:" -ForegroundColor White
    foreach ($item in $chosen) {
        Write-Host " [X] $($item.Label)" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $confirm = (Read-Host "Do you want to proceed with restoring these services? (Y/N / S/N)").Trim().ToUpper()
    if ($confirm -ne "Y" -and $confirm -ne "S" -and $confirm -ne "SIM" -and $confirm -ne "YES") {
        Write-Host "[-] Action cancelled by user." -ForegroundColor Red
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "[*] Restoring selected background services..." -ForegroundColor Yellow
    foreach ($item in $chosen) {
        $svc = Get-Service -Name $item.ServiceName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host " [+] Restoring: $($item.Label)" -ForegroundColor Cyan
            Set-Service -Name $item.ServiceName -StartupType $item.Startup -ErrorAction SilentlyContinue
            if ($item.Startup -eq "Automatic") {
                Start-Service -Name $item.ServiceName -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[+] Background services restored successfully!" -ForegroundColor Green
    Pause-Console
}

function Menu-RestoreIndividualPrivacy {
    $privacyItems = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "BingSearch"; Label = "Re-enable Bing Search in Start Menu"; Selected = $true },
        [PSCustomObject]@{ Id = "Cortana"; Label = "Re-enable Cortana & Legacy Voice Assistant Policies"; Selected = $true },
        [PSCustomObject]@{ Id = "Copilot"; Label = "Re-enable Microsoft Copilot AI System-wide"; Selected = $true },
        [PSCustomObject]@{ Id = "Recall"; Label = "Re-enable Windows Recall / AI Data Analysis"; Selected = $true },
        [PSCustomObject]@{ Id = "Ads"; Label = "Re-enable Windows Suggestions, Tips & Content Delivery"; Selected = $true },
        [PSCustomObject]@{ Id = "Widgets"; Label = "Re-enable Taskbar Widgets & News Feeds"; Selected = $true },
        [PSCustomObject]@{ Id = "ActivityHistory"; Label = "Re-enable Activity History & Timeline Uploads"; Selected = $true },
        [PSCustomObject]@{ Id = "TelemetryDiag"; Label = "Re-enable Diagnostic Data Collection & App Tracking"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE PRIVACY & TELEMETRY SETTINGS" -Subtitle "Select which specific telemetry, AI, or search feature(s) to re-enable." -Items $privacyItems
    if ($null -eq $selected) { return }

    $chosen = @($selected | Where-Object { $_.Selected })
    if ($chosen.Count -eq 0) {
        Clear-Host
        Write-Host "[!] No privacy/telemetry settings were selected for restoration." -ForegroundColor Yellow
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " RESTORE CONFIRMATION - PRIVACY & TELEMETRY" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "You have selected $($chosen.Count) privacy setting(s) to restore:" -ForegroundColor White
    foreach ($opt in $chosen) {
        Write-Host " [X] $($opt.Label)" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $confirm = (Read-Host "Do you want to proceed with restoring these settings? (Y/N / S/N)").Trim().ToUpper()
    if ($confirm -ne "Y" -and $confirm -ne "S" -and $confirm -ne "SIM" -and $confirm -ne "YES") {
        Write-Host "[-] Action cancelled by user." -ForegroundColor Red
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "[*] Restoring selected privacy settings..." -ForegroundColor Yellow
    foreach ($opt in $chosen) {
        Write-Host " [+] Restoring: $($opt.Label)" -ForegroundColor Cyan
        switch ($opt.Id) {
            "BingSearch" {
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch"
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb"
                Remove-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled"
            }
            "Cortana" {
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"
            }
            "Copilot" {
                Remove-RegValue "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
            }
            "Recall" {
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis"
            }
            "Ads" {
                $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                Remove-RegValue $cdm "ContentDeliveryAllowed"
                Remove-RegValue $cdm "OemPreInstalledAppsEnabled"
                Remove-RegValue $cdm "PreInstalledAppsEnabled"
                Remove-RegValue $cdm "PreInstalledAppsEverEnabled"
                Remove-RegValue $cdm "SilentInstalledAppsEnabled"
                Remove-RegValue $cdm "SubscribedContent-338387Enabled"
                Remove-RegValue $cdm "SubscribedContent-338388Enabled"
                Remove-RegValue $cdm "SubscribedContent-338389Enabled"
                Remove-RegValue $cdm "SubscribedContent-353698Enabled"
                Remove-RegValue $cdm "SystemPaneSuggestionsEnabled"
            }
            "Widgets" {
                Remove-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa"
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests"
            }
            "ActivityHistory" {
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities"
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"
            }
            "TelemetryDiag" {
                Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
                Remove-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs"
            }
        }
    }
    Write-Host "[+] Privacy and Telemetry settings restored successfully!" -ForegroundColor Green
    Pause-Console
}

function Menu-RestoreIndividualLatency {
    $latencyItems = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "Quantum"; Label = "Restore CPU Quantum (Win32PrioritySeparation = 2 [Stock])"; Selected = $true },
        [PSCustomObject]@{ Id = "GameDVR"; Label = "Re-enable GameDVR & Background Screen Recording"; Selected = $true },
        [PSCustomObject]@{ Id = "Multimedia"; Label = "Restore SystemResponsiveness (20) & NetworkThrottling (10)"; Selected = $true },
        [PSCustomObject]@{ Id = "GpuPriority"; Label = "Restore Game Task Profile Priorities to Stock"; Selected = $true },
        [PSCustomObject]@{ Id = "InstantUI"; Label = "Restore MenuShowDelay (400ms) & HungAppTimeouts (5000ms)"; Selected = $true },
        [PSCustomObject]@{ Id = "BalancedPower"; Label = "Restore Balanced Power Scheme (Default)"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE LATENCY & HARDWARE TWEAKS" -Subtitle "Select which specific kernel, power or latency tweak(s) to restore." -Items $latencyItems
    if ($null -eq $selected) { return }

    $chosen = @($selected | Where-Object { $_.Selected })
    if ($chosen.Count -eq 0) {
        Clear-Host
        Write-Host "[!] No latency/hardware settings were selected for restoration." -ForegroundColor Yellow
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " RESTORE CONFIRMATION - HARDWARE & LATENCY" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "You have selected $($chosen.Count) tweak(s) to restore:" -ForegroundColor White
    foreach ($item in $chosen) {
        Write-Host " [X] $($item.Label)" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $confirm = (Read-Host "Do you want to proceed with restoring these settings? (Y/N / S/N)").Trim().ToUpper()
    if ($confirm -ne "Y" -and $confirm -ne "S" -and $confirm -ne "SIM" -and $confirm -ne "YES") {
        Write-Host "[-] Action cancelled by user." -ForegroundColor Red
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "[*] Restoring selected hardware and latency settings..." -ForegroundColor Yellow
    foreach ($item in $chosen) {
        Write-Host " [+] Restoring: $($item.Label)" -ForegroundColor Cyan
        switch ($item.Id) {
            "Quantum" {
                Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 2
            }
            "GameDVR" {
                Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 1
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 0
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 0
                Set-RegDWord "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 0
            }
            "Multimedia" {
                Set-RegDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10
                Set-RegDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20
            }
            "GpuPriority" {
                $gameProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
                Set-RegDWord $gameProfile "Affinity" 0
                Set-RegString $gameProfile "Background Only" "False"
                Set-RegDWord $gameProfile "Clock Rate" 10000
                Set-RegDWord $gameProfile "GPU Priority" 8
                Set-RegDWord $gameProfile "Priority" 2
                Set-RegString $gameProfile "Scheduling Category" "Medium"
                Set-RegString $gameProfile "SFIO Priority" "Normal"
            }
            "InstantUI" {
                Set-RegString "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400"
                Set-RegString "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "5000"
                Set-RegString "HKCU:\Control Panel\Desktop" "HungAppTimeout" "5000"
            }
            "BalancedPower" {
                powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null | Out-Null
            }
        }
    }
    Write-Host "[+] Hardware and latency tweaks restored successfully!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 8. RESTORE & ROLLBACK CENTER (UNDO HUB)
# ==============================================================================
function Menu-RollbackCenter {
    $hubCategories = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "Apps"; Label = "Reinstall / Restore Specific Apps (Item-by-item selection)"; Selected = $false },
        [PSCustomObject]@{ Id = "Services"; Label = "Restore Specific Background Services (Item-by-item selection)"; Selected = $false },
        [PSCustomObject]@{ Id = "Privacy"; Label = "Restore Privacy, AI & Telemetry Settings (Item-by-item selection)"; Selected = $false },
        [PSCustomObject]@{ Id = "Latency"; Label = "Restore Latency & Hardware Tweaks (Item-by-item selection)"; Selected = $false },
        [PSCustomObject]@{ Id = "VBS"; Label = "Re-enable VBS / Core Isolation & Security Hypervisor"; Selected = $false },
        [PSCustomObject]@{ Id = "AllStoreApps"; Label = "Batch Re-register ALL Factory Windows Store Apps"; Selected = $false },
        [PSCustomObject]@{ Id = "SystemRestore"; Label = "Launch Windows System Restore Wizard (rstrui.exe)"; Selected = $false }
    )

    $selected = Show-MultiSelectMenu -Title "RESTORE & ROLLBACK COMMAND CENTER" -Subtitle "Use [SPACE] to select the restoration categories or actions you want to run." -Items $hubCategories
    if ($null -eq $selected) { return }

    $chosenHub = @($selected | Where-Object { $_.Selected })
    if ($chosenHub.Count -eq 0) {
        Clear-Host
        Write-Host "[!] No restore options were selected." -ForegroundColor Yellow
        Pause-Console
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " CONFIRM RESTORATION CATEGORIES" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "You selected $($chosenHub.Count) action(s)/category(ies):" -ForegroundColor White
    foreach ($item in $chosenHub) {
        Write-Host " [X] $($item.Label)" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $confirm = (Read-Host "Do you want to proceed with the selected categories? (Y/N / S/N)").Trim().ToUpper()
    if ($confirm -ne "Y" -and $confirm -ne "S" -and $confirm -ne "SIM" -and $confirm -ne "YES") {
        Write-Host "[-] Action cancelled by user." -ForegroundColor Red
        Pause-Console
        return
    }

    foreach ($item in $selected) {
        if (-not $item.Selected) { continue }
        switch ($item.Id) {
            "Apps" { Menu-RestoreIndividualApps }
            "Services" { Menu-RestoreIndividualServices }
            "Privacy" { Menu-RestoreIndividualPrivacy }
            "Latency" { Menu-RestoreIndividualLatency }
            "VBS" {
                Clear-Host
                Write-Host "[*] Re-enabling VBS & Security Hypervisor..." -ForegroundColor Yellow
                bcdedit /set hypervisorlaunchtype auto 2>$null | Out-Null
                Remove-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity"
                Remove-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled"
                Write-Host "[+] VBS / Hypervisor set to AUTO (default). Reboot required!" -ForegroundColor Green
                Pause-Console
            }
            "AllStoreApps" {
                Clear-Host
                Write-Host "[*] Re-registering all built-in Windows Store packages..." -ForegroundColor Yellow
                Get-AppxPackage -AllUsers | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
                }
                Write-Host "[+] Store app registration finished!" -ForegroundColor Green
                Pause-Console
            }
            "SystemRestore" {
                Start-Process "rstrui.exe"
            }
        }
    }
}

# ==============================================================================
# INTERACTIVE MAIN MENU
# ==============================================================================
do {
    try { [Console]::CursorVisible = $true } catch {}
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              " -ForegroundColor Yellow
    Write-Host "             Created by: blayk11 | https://github.com/blayk11             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " Select a category to customize with [SPACE] and [ARROWS]:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Create System Restore Point" -ForegroundColor Cyan
    Write-Host "  [2] Remove Bloatware & UWP Apps (Interactive Menu with [X])" -ForegroundColor Magenta
    Write-Host "  [3] Telemetry, Copilot AI & Ads (Interactive Menu with [X])" -ForegroundColor Yellow
    Write-Host "  [4] Background Services (Interactive Menu with [X])" -ForegroundColor Yellow
    Write-Host "  [5] Low Latency & Hardware Tweaks (Interactive Menu with [X])" -ForegroundColor Green
    Write-Host "  [6] Disable VBS / Core Isolation (Boosts FPS & Frametime)" -ForegroundColor Blue
    Write-Host "  [7] Deep Disk & Cache Cleaner (Interactive Menu with [X])" -ForegroundColor Blue
    Write-Host "  [8] RESTORE / ROLLBACK HUB (Revert Tweaks to Windows Defaults)" -ForegroundColor Green
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [A] APPLY ALL RECOMMENDED DEFAULTS (FULL TURBO MODE)" -ForegroundColor Red
    Write-Host "  [R] Reboot Computer Now" -ForegroundColor DarkYellow
    Write-Host "  [Q] Exit" -ForegroundColor White
    Write-Host ""
    $mainChoice = (Read-Host "Enter your choice").Trim().ToUpper()

    switch ($mainChoice) {
        "1" { Invoke-RestorePoint }
        "2" { Menu-BloatwareApps }
        "3" { Menu-TelemetryAndPrivacy }
        "4" { Menu-ServicesOptimization }
        "5" { Menu-LowLatency }
        "6" { Invoke-DisableVBS }
        "7" { Menu-DeepCleaning }
        "8" { Menu-RollbackCenter }
        "A" {
            Invoke-RestorePoint
            Clear-Host
            Write-Host "[*] Applying FULL TURBO MODE..." -ForegroundColor Yellow
            
            # Apps
            Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { 
                $_.Name -match "(BingWeather|BingNews|BingFinance|BingSports|GetHelp|Getstarted|Microsoft3DViewer|MicrosoftOfficeHub|MicrosoftSolitaireCollection|MixedReality|People|SkypeApp|Todos|FeedbackHub|WindowsMaps|YourPhone|ZuneMusic|ZuneVideo|Clipchamp|PowerAutomate|Copilot|549981C3F5F10|Spotify|Disney|TikTok|Facebook|Instagram|CandyCrush|PrimeVideo|Netflix|OutlookForWindows)"
            } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

            # Telemetry & Privacy
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
            Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
            Set-RegDWord "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1

            # Services
            @("SysMain", "DiagTrack", "dmwappushservice", "MapsBroker", "Fax", "RetailDemo", "WpcMonSvc", "SharedRealitySvc", "WerSvc", "PcaSvc") | ForEach-Object {
                Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
                Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
            }

            # Latency
            Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
            Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
            Set-RegString "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0"
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
            $scheme = (powercfg -list | Select-String "Desempenho M.ximo|Ultimate Performance" | ForEach-Object { $_.Line.Split()[3] })
            if ($scheme) { powercfg -setactive $scheme }

            # VBS
            bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
            Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0

            Write-Host ""
            Write-Host "========================================================================" -ForegroundColor Green
            Write-Host " [OK] TURBO OPTIMIZATION COMPLETED! REBOOT YOUR PC TO APPLY ALL CHANGES." -ForegroundColor Green
            Write-Host "========================================================================" -ForegroundColor Green
            Pause-Console
        }
        "R" { Restart-Computer -Force }
        "Q" { break }
        default {
            Write-Host "Invalid choice!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($mainChoice -ne "Q")
