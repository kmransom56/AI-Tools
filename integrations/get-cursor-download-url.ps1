# get-cursor-download-url.ps1
$shortUri = 'https://cursor.sh/install/windows'
Write-Host "Checking redirect for $shortUri"
try {
    $resp = Invoke-WebRequest -Uri $shortUri -Method Head -MaximumRedirection 0 -ErrorAction Stop
    if ($resp.Headers['Location']) {
        Write-Host "Redirect Location: $($resp.Headers['Location'])"
    } else {
        Write-Host "No Location header on HEAD. Trying GET to follow redirects..."
        $r = Invoke-WebRequest -Uri $shortUri -MaximumRedirection 20 -UseBasicParsing -ErrorAction Stop
        Write-Host "Final URI: $($r.BaseResponse.ResponseUri)"
    }
} catch [System.Net.WebException] {
    $we = $_.Exception.Response
    if ($we -and $we.Headers['Location']) {
        Write-Host "Redirect Location (from WebException): $($we.Headers['Location'])"
    } else {
        Write-Host "Failed to resolve redirect: $($_.Exception.Message)"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}