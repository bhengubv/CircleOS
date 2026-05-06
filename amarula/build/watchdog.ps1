# Amarula build watchdog
# Polls every 60s. Beeps + toast notification when build dies.
# Run with: powershell -ExecutionPolicy Bypass -File watchdog.ps1

Add-Type -AssemblyName System.Windows.Forms

function Show-Toast($title, $body) {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $textNodes = $template.GetElementsByTagName("text")
    $textNodes.Item(0).AppendChild($template.CreateTextNode($title)) | Out-Null
    $textNodes.Item(1).AppendChild($template.CreateTextNode($body)) | Out-Null
    $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("CircleOS-Build").Show($toast)
}

function Beep-Alert {
    1..5 | ForEach-Object {
        [console]::beep(1200, 300)
        Start-Sleep -Milliseconds 100
    }
}

$lastStep = ""
$deadCount = 0
$lastAlert = [DateTime]::MinValue

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Watchdog started. Polling every 60s." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop."
Write-Host ""

while ($true) {
    $ts = Get-Date -Format 'HH:mm:ss'

    # Probe WSL: get ninja/hb count + last step + error count
    $probe = wsl -d Ubuntu-22.04 -u root -- bash -c "echo PROCS=`$(pgrep -c -f 'ninja|hb/main' 2>/dev/null); echo STEP=`$(grep -oP '\[\d+/\d+\]' /root/ohos/build_take13.log 2>/dev/null | tail -1); echo ERR=`$(grep -c '\[OHOS ERROR\]' /root/ohos/build_take13.log 2>/dev/null)" 2>$null

    $procs = ($probe | Select-String 'PROCS=(\d+)').Matches.Groups[1].Value
    $step  = ($probe | Select-String 'STEP=(.+)').Matches.Groups[1].Value
    $errs  = ($probe | Select-String 'ERR=(\d+)').Matches.Groups[1].Value

    if (-not $procs) {
        Write-Host "[$ts] WSL not responding" -ForegroundColor Yellow
    }
    elseif ([int]$procs -lt 2) {
        $deadCount++
        Write-Host "[$ts] Build DEAD (procs=$procs, lastStep=$step, errs=$errs) — $deadCount consecutive" -ForegroundColor Red

        # Alert once per 5 min to avoid spamming
        if (([DateTime]::Now - $lastAlert).TotalMinutes -ge 5) {
            Beep-Alert
            try { Show-Toast "CircleOS Build DIED" "Last step: $step. Errors: $errs. Check Claude Code." } catch { Write-Host "(toast failed: $_)" }
            $lastAlert = [DateTime]::Now
        }
    }
    else {
        $deadCount = 0
        $changed = if ($step -ne $lastStep) { '✓' } else { '...' }
        Write-Host "[$ts] alive procs=$procs step=$step errs=$errs $changed" -ForegroundColor DarkGray
        $lastStep = $step
    }

    Start-Sleep -Seconds 60
}
