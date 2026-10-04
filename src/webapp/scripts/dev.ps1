$ErrorActionPreference = "Stop"

$webAppRoot = Split-Path -Parent $PSScriptRoot
Set-Location $webAppRoot

$tcpClient = [System.Net.Sockets.TcpClient]::new("localhost", 5001)
try {
    $validationCallback = [System.Net.Security.RemoteCertificateValidationCallback]{
        param($sender, $certificate, $chain, $errors)
        return $true
    }
    $sslStream = [System.Net.Security.SslStream]::new(
        $tcpClient.GetStream(),
        $false,
        $validationCallback
    )
    try {
        $sslStream.AuthenticateAsClient("localhost")
        $serverCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $sslStream.RemoteCertificate
        )
    }
    finally {
        $sslStream.Dispose()
    }
}
finally {
    $tcpClient.Dispose()
}

$thumbprint = $serverCertificate.Thumbprint
$personalCertificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Thumbprint -eq $thumbprint -and $_.HasPrivateKey } |
    Select-Object -First 1
$trustedCertificate = Get-ChildItem Cert:\CurrentUser\Root |
    Where-Object { $_.Thumbprint -eq $thumbprint } |
    Select-Object -First 1

if (-not $personalCertificate -or -not $trustedCertificate) {
    throw "The IdentityServer HTTPS certificate is not the trusted .NET development certificate. Run 'dotnet dev-certs https --trust' and start IdentityServer on https://localhost:5001."
}

$certificateDirectory = Join-Path $webAppRoot "certificates"
New-Item -ItemType Directory -Path $certificateDirectory -Force | Out-Null
$certificatePath = Join-Path $certificateDirectory "identityserver-dev-cert.pem"
$certificateBytes = $personalCertificate.Export(
    [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
)
$base64Certificate = [Convert]::ToBase64String($certificateBytes)
$pemLines = [System.Text.RegularExpressions.Regex]::Matches($base64Certificate, ".{1,64}") |
    ForEach-Object { $_.Value }
$pem = "-----BEGIN CERTIFICATE-----`n$($pemLines -join "`n")`n-----END CERTIFICATE-----`n"
[System.IO.File]::WriteAllText($certificatePath, $pem, [System.Text.Encoding]::ASCII)

$env:IDENTITY_SERVER_CA_CERT = $certificatePath
& node --use-system-ca node_modules/next/dist/bin/next dev --experimental-https
exit $LASTEXITCODE
