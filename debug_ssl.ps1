$webRequest = [System.Net.HttpWebRequest]::Create("https://ca.netintegrate.net/api/ca")
$webRequest.ServerCertificateValidationCallback = {
    param($sender, $certificate, $chain, $sslPolicyErrors)
    Write-Output "SSL Errors: $sslPolicyErrors"
    if ($certificate) {
        Write-Output "Subject: $($certificate.Subject)"
        Write-Output "Issuer: $($certificate.Issuer)"
    } else {
        Write-Output "Certificate not available."
    }
    foreach ($element in $chain.ChainElements) {
        if ($element.Certificate) {
            Write-Output "Chain Element: $($element.Certificate.Subject)"
            Write-Output "   Issuer: $($element.Certificate.Issuer)"
            foreach ($status in $element.ChainElementStatus) {
                Write-Output "   Status: $($status.Status) - $($status.StatusInformation)"
            }
        } else {
            Write-Output "Chain Element Certificate not available."
        }
    }
    return $true
}
try { $webRequest.GetResponse().Dispose() } catch {}
