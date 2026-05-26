# FluxMacro self-signing script
# Creates a self-signed code-signing certificate (stored in your Windows cert store)
# and signs FluxMacro.exe.  Re-run after every release build.
#
# The cert is NOT trusted by Windows SmartScreen -- that requires a paid CA cert.
# What you DO get: if anyone tampers with the .exe after signing, signtool verify
# will report the signature is invalid, so you can detect tampering.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File sign_app.ps1
#   powershell -ExecutionPolicy Bypass -File sign_app.ps1 -ExePath "path\to\FluxMacro.exe"

param(
    [string]$ExePath = "out\build\x64-release\CMakeProject1\FluxMacro.exe"
)

$ErrorActionPreference = "Stop"
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"

# 1. Resolve exe path
if (-not [System.IO.Path]::IsPathRooted($ExePath)) {
    $ExePath = Join-Path $PSScriptRoot $ExePath
}
if (-not (Test-Path $ExePath)) {
    Write-Error "Exe not found: $ExePath`nBuild the release first, then run this script."
    exit 1
}

# 2. Get or create certificate
$certSubject = "CN=FluxMacro, O=strangeststar"
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigning |
    Where-Object { $_.Subject -eq $certSubject -and $_.NotAfter -gt (Get-Date) } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if ($cert) {
    Write-Host "Using existing certificate [$($cert.Thumbprint)] valid until $($cert.NotAfter.ToString('yyyy-MM-dd'))"
} else {
    Write-Host "Creating new self-signed code-signing certificate..."
    $cert = New-SelfSignedCertificate `
        -Subject           $certSubject `
        -Type              CodeSigning `
        -CertStoreLocation Cert:\CurrentUser\My `
        -NotAfter          (Get-Date).AddYears(10) `
        -HashAlgorithm     SHA256 `
        -KeyAlgorithm      RSA `
        -KeyLength         2048
    Write-Host "Certificate created [$($cert.Thumbprint)] valid for 10 years"

    # Export a .cer (public key only, no private key -- safe to share)
    $cerPath = Join-Path $PSScriptRoot "FluxMacro_codesign.cer"
    Export-Certificate -Cert $cert -FilePath $cerPath -Type CERT | Out-Null
    Write-Host "Public cert exported to: $cerPath"
}

# 3. Sign
Write-Host ""
Write-Host "Signing: $ExePath"

$timestampUrl = "http://timestamp.digicert.com"
$signed = $false

try {
    $out = & $signtool sign /fd SHA256 /sha1 $cert.Thumbprint /td SHA256 /tr $timestampUrl $ExePath 2>&1
    Write-Host $out
    if ($LASTEXITCODE -eq 0) {
        $signed = $true
    }
} catch {
    $signed = $false
}

if (-not $signed) {
    Write-Warning "Timestamp server unreachable -- signing without timestamp."
    & $signtool sign /fd SHA256 /sha1 $cert.Thumbprint $ExePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Signing failed."
        exit 1
    }
}

# 4. Verify (use PowerShell's authenticode check -- works correctly with self-signed certs)
Write-Host ""
Write-Host "Verifying signature..."
$sig = Get-AuthenticodeSignature $ExePath
Write-Host "  Status   : $($sig.Status)"
Write-Host "  Signer   : $($sig.SignerCertificate.Subject)"
Write-Host "  Thumbprint: $($sig.SignerCertificate.Thumbprint)"

if ($sig.Status -eq "HashMismatch") {
    Write-Error "TAMPERED: signature hash does not match file contents."
    exit 1
} elseif ($sig.Status -eq "NotSigned") {
    Write-Error "File is not signed."
    exit 1
} else {
    # NotTrusted / UnknownError = self-signed cert not in trusted root store -- expected.
    # HashMismatch would have exited above.  Anything else means the sig is intact.
    Write-Host ""
    Write-Host "Signature is intact."
    if ($sig.Status -eq "NotTrusted" -or $sig.Status -eq "UnknownError") {
        Write-Host "(Status '$($sig.Status)' is normal for self-signed certs -- tamper detection still works)"
    }
}

Write-Host ""
Write-Host "Done."
Write-Host "To check tamper status later:"
Write-Host "  (Get-AuthenticodeSignature `"$ExePath`").Status"
Write-Host "  -- 'NotTrusted' or 'UnknownError' = signed and untampered (self-signed is expected here)"
Write-Host "  -- 'HashMismatch' = file was modified after signing"
Write-Host "  -- 'NotSigned' = signature was stripped"
