<#
.SYNOPSIS
    ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER (SMOOTH TUI v2)
    Autor: blayk11 (https://github.com/blayk11)
.DESCRIPTION
    Script modular e seguro para Windows 10 e Windows 11.
    TUI interativa com paginacao dinamica (Zero Flicker / Zero Scroll Overflow),
    navegacao por SETAS/PageUp/PageDown, selecao com ESPACO [X], atalhos 'A', 'N', 'I'.
#>

# Força codificação UTF-8 no console
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Auto-elevação de Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Elevando permissoes para Administrador..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==============================================================================
# HELPERS DE REGISTRO SEGURO (COM FALLBACK PARA REG.EXE)
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
        # Fallback robusto via reg.exe (ignora bloqueios de provider do PS)
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

# ==============================================================================
# MOTOR DE INTERFACE TUI ESTAVEL E SUAVE (SEM FLICKER E COM PAGINACAO)
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

    # Renderiza o cabeçalho fixo
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              " -ForegroundColor Yellow
    Write-Host "             Criado por: blayk11 | https://github.com/blayk11             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " [CATEGORIA]: $Title" -ForegroundColor Green
    if ($Subtitle) {
        Write-Host " $Subtitle" -ForegroundColor DarkGray
    }
    Write-Host " ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [Setas / PgUp / PgDn]: Navegar  |  [Espaco]: Marcar/Desmarcar [X]" -ForegroundColor Cyan
    Write-Host " [A]: Marcar Todos   |   [N]: Desmarcar Todos   |   [I]: Inverter" -ForegroundColor Cyan
    Write-Host " [Enter]: Confirmar e Executar  |  [ESC / Q]: Cancelar / Voltar" -ForegroundColor Yellow
    Write-Host " ========================================================================" -ForegroundColor DarkGray

    # Ponto exato de início da lista na tela
    $listStartTop = [Console]::CursorTop

    while ($true) {
        # Calcula a altura disponível do terminal para a lista
        $winHeight = [Console]::WindowHeight
        if ($winHeight -lt 20) { $winHeight = 25 }
        $winWidth = [Console]::WindowWidth
        if ($winWidth -lt 80) { $winWidth = 80 }

        # Quantidade de itens visíveis por página (deixa margem de segurança para nunca estourar a tela)
        $maxVisible = [Math]::Max(6, $winHeight - $listStartTop - 4)
        if ($maxVisible -gt $totalItems) { $maxVisible = $totalItems }

        # Ajusta janela de rolagem (Scroll Window)
        if ($selectedIndex -lt $scrollOffset) {
            $scrollOffset = $selectedIndex
        } elseif ($selectedIndex -ge ($scrollOffset + $maxVisible)) {
            $scrollOffset = $selectedIndex - $maxVisible + 1
        }

        # Contagem de selecionados
        $selectedCount = ($Items | Where-Object { $_.Selected }).Count

        # Reposiciona o cursor no início da área de listagem (Zero Flicker)
        [Console]::SetCursorPosition(0, $listStartTop)

        # Indicador de itens acima
        $upIndicator = if ($scrollOffset -gt 0) { "   ^ (... mais itens acima ...)" } else { " " }
        $upPadding = $winWidth - $upIndicator.Length - 1
        if ($upPadding -gt 0) { $upIndicator += (" " * $upPadding) }
        Write-Host $upIndicator -ForegroundColor DarkYellow

        # Renderiza a fatia visível de itens
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
                # Linha vazia de preenchimento
                Write-Host (" " * ($winWidth - 1)) -BackgroundColor Black
            }
        }

        # Indicador de itens abaixo
        $downIndicator = if (($scrollOffset + $maxVisible) -lt $totalItems) { "   v (... mais itens abaixo ...)" } else { " " }
        $downPadding = $winWidth - $downIndicator.Length - 1
        if ($downPadding -gt 0) { $downIndicator += (" " * $downPadding) }
        Write-Host $downIndicator -ForegroundColor DarkYellow

        # Barra de status no rodapé
        $statusBar = " [ Item $($selectedIndex + 1) de $totalItems | Marcados: $selectedCount/$totalItems ] "
        $statusPad = $winWidth - $statusBar.Length - 1
        if ($statusPad -gt 0) { $statusBar += ("-" * $statusPad) }
        Write-Host $statusBar -ForegroundColor Green -BackgroundColor Black

        # Captura de tecla
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
    Write-Host "Pressione qualquer tecla para retornar ao menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# 1. PONTO DE RESTAURACAO
# ==============================================================================
function Invoke-RestorePoint {
    Clear-Host
    Write-Host "[*] Criando Ponto de Restauracao de Seguranca..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Pre-Debloat-blayk11" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[+] Ponto de restauracao criado com sucesso!" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Aviso: Nao foi possivel criar ponto de restauracao ($($_.Exception.Message))" -ForegroundColor Red
    }
    Pause-Console
}

# ==============================================================================
# 2. SELECAO E REMOCAO DE APPS UWP (BLOATWARES)
# ==============================================================================
function Menu-BloatwareApps {
    $apps = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Pattern = "*Microsoft.BingWeather*"; Label = "Clima (Bing Weather)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingNews*"; Label = "Noticias (Bing News)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingFinance*"; Label = "Financas (Bing Finance)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.BingSports*"; Label = "Esportes (Bing Sports)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.GetHelp*"; Label = "Obter Ajuda (Get Help)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Getstarted*"; Label = "Dicas / Primeiros Passos (Get Started)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Microsoft3DViewer*"; Label = "Visualizador 3D (3D Viewer)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftOfficeHub*"; Label = "Office Hub (Promocoes Microsoft 365)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MicrosoftSolitaireCollection*"; Label = "Solitaire Collection (Paciencia)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.MixedReality.Portal*"; Label = "Portal de Realidade Mista (Mixed Reality)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.People*"; Label = "Pessoas (Microsoft People)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.SkypeApp*"; Label = "Skype"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Todos*"; Label = "Microsoft To Do"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsAlarms*"; Label = "Alarmes e Relogio"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsFeedbackHub*"; Label = "Hub de Comentarios (Feedback Hub)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsMaps*"; Label = "Mapas do Windows"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.WindowsSoundRecorder*"; Label = "Gravador de Voz"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.YourPhone*"; Label = "Vincular ao Celular (Phone Link)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneMusic*"; Label = "Groove Music / Media Player Antigo"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.ZuneVideo*"; Label = "Filmes e TV (Movies & TV)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Clipchamp.Clipchamp*"; Label = "Clipchamp Video Editor"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.PowerAutomateDesktop*"; Label = "Power Automate Desktop"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.Copilot*"; Label = "Microsoft Copilot App"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.549981C3F5F10*"; Label = "Cortana"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.OutlookForWindows*"; Label = "Novo Outlook (Versao Web)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxSpeechToTextOverlay*"; Label = "Xbox Speech to Text Overlay"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGameOverlay*"; Label = "Xbox Game Overlay"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.XboxGamingOverlay*"; Label = "Xbox Gaming Overlay (Game Bar)"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*Microsoft.GamingApp*"; Label = "Xbox App / Xbox Game Pass"; Selected = $false },
        [PSCustomObject]@{ Pattern = "*SpotifyAB.SpotifyMusic*"; Label = "Spotify (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*DisneyMagicKingdoms*"; Label = "Disney Magic Kingdoms"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*TikTok*"; Label = "TikTok (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Facebook*"; Label = "Facebook (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Instagram*"; Label = "Instagram (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*CandyCrush*"; Label = "Candy Crush / Jogos Patrocinados"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*PrimeVideo*"; Label = "Prime Video (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Netflix*"; Label = "Netflix (Pre-instalado)"; Selected = $true },
        [PSCustomObject]@{ Pattern = "*Microsoft.QuickAssist*"; Label = "Assistencia Rapida (Quick Assist)"; Selected = $false }
    )

    $selected = Show-MultiSelectMenu -Title "REMOVER APLICATIVOS E BLOATWARES (UWP)" -Subtitle "Selecione com [ESPACO] os apps que deseja remover permanentemente." -Items $apps
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Removendo aplicativos selecionados..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            Write-Host " [-] Removendo: $($item.Label)" -ForegroundColor Magenta
            Get-AppxPackage -Name $item.Pattern -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $item.Pattern } | ForEach-Object {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
    Write-Host "[+] Remocao de aplicativos concluida!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 3. SELECAO DE TELEMETRIA, ANUNCIOS E COPILOT
# ==============================================================================
function Menu-TelemetryAndPrivacy {
    $options = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "BingSearch"; Label = "Desativar Busca do Bing e Web no Menu Iniciar"; Selected = $true },
        [PSCustomObject]@{ Id = "Cortana"; Label = "Desativar Cortana e assistentes de voz legados"; Selected = $true },
        [PSCustomObject]@{ Id = "Copilot"; Label = "Desativar Microsoft Copilot AI no sistema"; Selected = $true },
        [PSCustomObject]@{ Id = "Recall"; Label = "Desativar Windows Recall / Snapshot AI"; Selected = $true },
        [PSCustomObject]@{ Id = "Ads"; Label = "Desativar Anuncios, Dicas e Sugestoes do Windows"; Selected = $true },
        [PSCustomObject]@{ Id = "Widgets"; Label = "Desativar Widgets e Feeds de Noticias da Barra de Tarefas"; Selected = $true },
        [PSCustomObject]@{ Id = "ActivityHistory"; Label = "Desativar Historico de Atividades e Linha do Tempo"; Selected = $true },
        [PSCustomObject]@{ Id = "TelemetryDiag"; Label = "Desativar Rastreamento de Diagnostico e Telemetria de Uso"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "TELEMETRIA, ANUNCIOS E COPILOT AI" -Subtitle "Escolha quais recursos de telemetria e rastreamento deseja desligar." -Items $options
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Aplicando ajustes de privacidade selecionados..." -ForegroundColor Yellow

    foreach ($opt in $selected) {
        if (-not $opt.Selected) { continue }
        Write-Host " [+] Aplicando: $($opt.Label)" -ForegroundColor Cyan
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
    Write-Host "[+] Configuracoes de privacidade aplicadas com sucesso!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 4. SELECAO DE SERVICOS EM SEGUNDO PLANO
# ==============================================================================
function Menu-ServicesOptimization {
    $services = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ ServiceName = "SysMain"; Label = "SysMain / Superfetch (Evita leituras desnecessarias em SSD)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "DiagTrack"; Label = "DiagTrack (Experiencias de Usuario e Telemetria)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "dmwappushservice"; Label = "dmwappushservice (WAP Push Telemetria)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "MapsBroker"; Label = "MapsBroker (Gerenciador de Mapas Baixados)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "Fax"; Label = "Fax (Servico de Fax)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "RetailDemo"; Label = "RetailDemo (Demonstracao de Varejo)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WpcMonSvc"; Label = "WpcMonSvc (Controle dos Pais / Parental Controls)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "SharedRealitySvc"; Label = "SharedRealitySvc (Realidade Espacial/Mista)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "WerSvc"; Label = "WerSvc (Relatorio de Erros do Windows)"; Selected = $true },
        [PSCustomObject]@{ ServiceName = "PcaSvc"; Label = "PcaSvc (Assistente de Compatibilidade de Programas)"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "DESATIVAR SERVICOS EM SEGUNDO PLANO" -Subtitle "Escolha quais servicos deseja parar e desativar permanentemente." -Items $services
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Desativando servicos selecionados..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            $svc = Get-Service -Name $item.ServiceName -ErrorAction SilentlyContinue
            if ($svc) {
                Write-Host " [-] Desativando: $($item.Label)" -ForegroundColor Magenta
                Stop-Service -Name $item.ServiceName -Force -ErrorAction SilentlyContinue
                Set-Service -Name $item.ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[+] Servicos otimizados com sucesso!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 5. SELECAO DE LATENCIA E SCHEDULING (CPU / RAM / GPU)
# ==============================================================================
function Menu-LowLatency {
    $tweaks = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Id = "Quantum"; Label = "Win32PrioritySeparation = 38 (Prioridade maxima para apps em foco)"; Selected = $true },
        [PSCustomObject]@{ Id = "GameDVR"; Label = "Desativar GameDVR e Captura de Fundo (Elimina micro-stutters)"; Selected = $true },
        [PSCustomObject]@{ Id = "Multimedia"; Label = "SystemResponsiveness = 0 & NetworkThrottling Off (Latencia minima)"; Selected = $true },
        [PSCustomObject]@{ Id = "GpuPriority"; Label = "Prioridade Alta para Jogos no Multimedia Scheduler (GPU Priority: 8)"; Selected = $true },
        [PSCustomObject]@{ Id = "InstantUI"; Label = "MenuShowDelay = 0 (Resposta visual e de menus instantanea)"; Selected = $true },
        [PSCustomObject]@{ Id = "UltimatePower"; Label = "Desbloquear e Ativar Plano de Energia 'Ultimate Performance'"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "AJUSTES UNIVERSAIS DE LATENCIA E HARDWARE" -Subtitle "Marque os ajustes de kernel, scheduling e GPU que deseja aplicar." -Items $tweaks
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Aplicando ajustes de latencia..." -ForegroundColor Yellow
    foreach ($t in $selected) {
        if (-not $t.Selected) { continue }
        Write-Host " [+] Aplicando: $($t.Label)" -ForegroundColor Cyan
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
    Write-Host "[+] Otimizacoes de latencia aplicadas com sucesso!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 6. DESATIVACAO DE VBS / ISOLAMENTO DE NUCLEO
# ==============================================================================
function Invoke-DisableVBS {
    Clear-Host
    Write-Host "[*] Desativando VBS e Hipervisor de Seguranca..." -ForegroundColor Yellow
    bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
    Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0
    Set-RegDWord "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
    Write-Host "[+] VBS / Hipervisor desligados com sucesso!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# 7. SELECAO DE LIMPEZA DE DISCO E TEMPORARIOS
# ==============================================================================
function Menu-DeepCleaning {
    $cleanOptions = [System.Collections.Generic.List[PSObject]]@(
        [PSCustomObject]@{ Target = "C:\Windows\Temp\*"; Label = "Arquivos Temporarios do Windows (C:\Windows\Temp)"; Selected = $true },
        [PSCustomObject]@{ Target = "$env:LOCALAPPDATA\Temp\*"; Label = "Arquivos Temporarios do Usuario (%TEMP%)"; Selected = $true },
        [PSCustomObject]@{ Target = "C:\Windows\SoftwareDistribution\Download\*"; Label = "Cache de Downloads do Windows Update"; Selected = $true },
        [PSCustomObject]@{ Target = "C:\Windows\Prefetch\*"; Label = "Cache Prefetch do Sistema"; Selected = $true },
        [PSCustomObject]@{ Target = "RecycleBin"; Label = "Esvaziar Lixeira"; Selected = $true }
    )

    $selected = Show-MultiSelectMenu -Title "LIMPEZA PROFUNDA DE ARQUIVOS E CACHES" -Subtitle "Escolha quais pastas de cache e arquivos temporarios deseja purgar." -Items $cleanOptions
    if ($null -eq $selected) { return }

    Clear-Host
    Write-Host "[*] Executando limpeza profunda..." -ForegroundColor Yellow
    foreach ($item in $selected) {
        if ($item.Selected) {
            Write-Host " [-] Limpando: $($item.Label)" -ForegroundColor Cyan
            if ($item.Target -eq "RecycleBin") {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item -Path $item.Target -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[+] Limpeza concluida com sucesso!" -ForegroundColor Green
    Pause-Console
}

# ==============================================================================
# MENU PRINCIPAL INTERATIVO
# ==============================================================================
do {
    try { [Console]::CursorVisible = $true } catch {}
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              " -ForegroundColor Yellow
    Write-Host "             Criado por: blayk11 | https://github.com/blayk11             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " Selecione a categoria que deseja personalizar com [ESPACO] e [SETAS]:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Criar Ponto de Restauracao do Sistema" -ForegroundColor Cyan
    Write-Host "  [2] Remover Bloatwares & Apps UWP (Menu Interativo com [X])" -ForegroundColor Magenta
    Write-Host "  [3] Telemetria, Copilot AI e Anuncios (Menu Interativo com [X])" -ForegroundColor Yellow
    Write-Host "  [4] Servicos em Segundo Plano (Menu Interativo com [X])" -ForegroundColor Yellow
    Write-Host "  [5] Otimizacoes de Baixa Latencia / Hardware (Menu Interativo com [X])" -ForegroundColor Green
    Write-Host "  [6] Desativar VBS / Isolamento de Nucleo (Ganha FPS e Fluidez)" -ForegroundColor Blue
    Write-Host "  [7] Limpeza Profunda de Caches e Temporarios (Menu Interativo com [X])" -ForegroundColor Blue
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [A] APLICAR TUDO COM PADROES RECOMENDADOS (MODO TURBO COMPLETO)" -ForegroundColor Red
    Write-Host "  [R] Reiniciar o Computador Agora" -ForegroundColor DarkYellow
    Write-Host "  [Q] Sair" -ForegroundColor White
    Write-Host ""
    $mainChoice = (Read-Host "Digite a opcao").Trim().ToUpper()

    switch ($mainChoice) {
        "1" { Invoke-RestorePoint }
        "2" { Menu-BloatwareApps }
        "3" { Menu-TelemetryAndPrivacy }
        "4" { Menu-ServicesOptimization }
        "5" { Menu-LowLatency }
        "6" { Invoke-DisableVBS }
        "7" { Menu-DeepCleaning }
        "A" {
            Invoke-RestorePoint
            Clear-Host
            Write-Host "[*] Aplicando MODO TURBO COMPLETO..." -ForegroundColor Yellow
            
            # Apps
            Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { 
                $_.Name -match "(BingWeather|BingNews|BingFinance|BingSports|GetHelp|Getstarted|Microsoft3DViewer|MicrosoftOfficeHub|MicrosoftSolitaireCollection|MixedReality|People|SkypeApp|Todos|FeedbackHub|WindowsMaps|YourPhone|ZuneMusic|ZuneVideo|Clipchamp|PowerAutomate|Copilot|549981C3F5F10|Spotify|Disney|TikTok|Facebook|Instagram|CandyCrush|PrimeVideo|Netflix|OutlookForWindows)"
            } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

            # Telemetria & Privacy
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
            Set-RegDWord "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
            Set-RegDWord "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
            Set-RegDWord "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1

            # Servicos
            @("SysMain", "DiagTrack", "dmwappushservice", "MapsBroker", "Fax", "RetailDemo", "WpcMonSvc", "SharedRealitySvc", "WerSvc", "PcaSvc") | ForEach-Object {
                Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
                Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
            }

            # Latencia
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
            Write-Host " [OK] OTIMIZACAO TURBO CONCLUIDA! REINICIE O PC PARA APLICAR TUDO." -ForegroundColor Green
            Write-Host "========================================================================" -ForegroundColor Green
            Pause-Console
        }
        "R" { Restart-Computer -Force }
        "Q" { break }
        default {
            Write-Host "Opcao invalida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($mainChoice -ne "Q")
