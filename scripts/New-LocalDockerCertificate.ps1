$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$certificateDirectory = Join-Path $repositoryRoot "certificates"
$certificatePath = Join-Path $certificateDirectory "local-cert.pem"
$certificateDerPath = Join-Path $certificateDirectory "local-cert.cer"
$privateKeyPath = Join-Path $certificateDirectory "local-key.pem"
$pfxPath = Join-Path $certificateDirectory "local-cert.pfx"

New-Item -ItemType Directory -Path $certificateDirectory -Force | Out-Null

$certificateIsReusable = $false
if ((Test-Path $certificatePath) -and (Test-Path $privateKeyPath) -and (Test-Path $pfxPath)) {
    $existingCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificatePath)
    $sanExtension = $existingCertificate.Extensions |
        Where-Object { $_.Oid.Value -eq "2.5.29.17" } |
        Select-Object -First 1
    $sanNames = if ($sanExtension) { $sanExtension.Format($false) } else { "" }
    $certificateIsReusable =
        $existingCertificate.NotAfter -gt [DateTime]::UtcNow.AddDays(1) -and
        $sanNames.Contains("localhost") -and
        $sanNames.Contains("identityserver.localhost")
}

if (-not $certificateIsReusable) {
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
        "CN=localhost",
        $rsa,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    )

    $request.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $true)
    )
    $request.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
            [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature -bor
                [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment,
            $true
        )
    )

    $enhancedKeyUsages = [System.Security.Cryptography.OidCollection]::new()
    [void]$enhancedKeyUsages.Add([System.Security.Cryptography.Oid]::new("1.3.6.1.5.5.7.3.1"))
    $request.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($enhancedKeyUsages, $true)
    )

    $subjectAlternativeNames = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
    $subjectAlternativeNames.AddDnsName("localhost")
    $subjectAlternativeNames.AddDnsName("identityserver.localhost")
    $subjectAlternativeNames.AddIpAddress([System.Net.IPAddress]::Loopback)
    $subjectAlternativeNames.AddIpAddress([System.Net.IPAddress]::IPv6Loopback)
    $request.CertificateExtensions.Add($subjectAlternativeNames.Build())

    $now = [DateTimeOffset]::UtcNow
    $certificate = $request.CreateSelfSigned($now.AddMinutes(-5), $now.AddYears(2))
    $certificateDer = $certificate.Export(
        [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
    )
    try {
        [System.IO.File]::WriteAllText(
            $certificatePath,
            "-----BEGIN CERTIFICATE-----`n$([Convert]::ToBase64String($certificateDer, [Base64FormattingOptions]::InsertLineBreaks))`n-----END CERTIFICATE-----`n",
            [System.Text.Encoding]::ASCII
        )
        [System.IO.File]::WriteAllText(
            $privateKeyPath,
            "-----BEGIN PRIVATE KEY-----`n$([Convert]::ToBase64String($rsa.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob), [Base64FormattingOptions]::InsertLineBreaks))`n-----END PRIVATE KEY-----`n",
            [System.Text.Encoding]::ASCII
        )
        [System.IO.File]::WriteAllBytes(
            $certificateDerPath,
            $certificateDer
        )
        [System.IO.File]::WriteAllBytes(
            $pfxPath,
            $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx)
        )
    }
    finally {
        $certificate.Dispose()
        $rsa.Dispose()
    }
}
else {
    $existingCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificatePath)
    try {
        $certificateDer = $existingCertificate.Export(
            [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
        )
        [System.IO.File]::WriteAllBytes($certificateDerPath, $certificateDer)
    }
    finally {
        $existingCertificate.Dispose()
    }
}

$certificateForTrust = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificateDerPath)
$trustedCertificate = Get-ChildItem Cert:\CurrentUser\Root |
    Where-Object { $_.Thumbprint -eq $certificateForTrust.Thumbprint } |
    Select-Object -First 1

if (-not $trustedCertificate) {
    Import-Certificate -FilePath $certificateDerPath -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
}

Write-Output "Local Docker TLS certificate is ready:"
Write-Output "  HTTPS names: localhost, identityserver.localhost"
Write-Output "  Public certificate: $certificatePath"
Write-Output "  Private key and IdentityServer PFX are in the ignored certificates directory."
