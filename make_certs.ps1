# From https://docs.microsoft.com/en-us/aspnet/core/security/authentication/certauth?view=aspnetcore-3.1

######
# CA #
######

$root = $PSScriptRoot

Function Convert-PfxToCrt([byte[]]$bytes, [string]$out, [switch]$cert = $true)
{    
    if($cert -eq $true)
    {
        $content = @(
        '-----BEGIN CERTIFICATE-----',        
        [System.Convert]::ToBase64String($bytes, 'InsertLineBreaks'),        
        '-----END CERTIFICATE-----')
        $content | Out-File -FilePath $out -Encoding ascii
    }else {
        $content = [System.Convert]::ToBase64String($bytes)
        $content | Out-File -NoNewline -FilePath $out -Encoding ascii
    }
}

Function Write-ExportBase64Instructions()
{
    Write-Host "nginx require Base64 encoded. Folow steps: "
    Write-Host " 1. Install pfx into CurrentUser\Root (Trusted Root Certification Authorities)"
    Write-Host " 2. Open certmgr.msc and navigate to Trusted Root Certification Authorities"
    Write-Host " 3. Right click certificate, select All Tasks > Export..."
    Write-Host " 4. Click next until presented with export format options. Select Base-64 encoded X.509 (.CER)"
    Write-Host " 5. Export to $PSScriptRoot or any other location"
}

Function Create-RootCA()
{
    # Friendly name
    $fn = "cca_root_ca"
    $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(20) `
        -FriendlyName $fn -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature

    $t = $cert.Thumbprint

    $password = Read-Host "Enter password for $fn" -AsSecureString
    #$password = ConvertTo-SecureString -String "1234" -Force -AsPlainText

    $pfx = Join-Path $root "$fn.pfx"
    Get-ChildItem -Path cert:\localMachine\my\$t | Export-PfxCertificate -FilePath $pfx  -Password $password

    # CRT is Base64 in contrast to CER that is binary
    Write-ExportBase64Instructions
    #$crt = Join-Path $root "$fn.crt"
    #Convert-PfxToCrt $cert.RawData $crt
    return $t
}

Function Create-IntermediateCA([string]$signThumbprintRootCA)
{
    $fn = "cca_intermediate"

    $parentcert = Get-ChildItem -Path cert:\LocalMachine\My\$signThumbprintRootCA

    $cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -DnsName "localhost" -Signer $parentcert -NotAfter (Get-Date).AddYears(20) `
        -FriendlyName $fn -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -TextExtension @("2.5.29.19={text}CA=1&pathlength=1")
    
    $t = $cert.Thumbprint    

    $pfx = Join-Path $root "$fn.pfx"
    $password = Read-Host "Enter password for $fn" -AsSecureString
    Get-ChildItem -Path cert:\localMachine\my\$t | Export-PfxCertificate -FilePath $pfx -Password $password

    #$crt = Join-Path $root "$fn.crt"
    #Convert-PfxToCrt $cert.RawData $crt
    return $t
}

Function Create-ClientCertificate([string]$subject, [string]$signThumbprintRootCA)
{
    $rootcert = Get-ChildItem -Path cert:\LocalMachine\My\$signThumbprintRootCA
    
    $fn = "cca_client"
    # "2.5.29.17={text}upn=localhost"
    # https://github.com/dotnet/aspnetcore/issues/7246#issuecomment-537752663
    $cert = New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\my -DnsName "localhost" -Signer $rootcert `
        -NotAfter (Get-Date).AddYears(20) -FriendlyName $fn -Type Custom -Subject $subject `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") -KeyUsage CertSign, DigitalSignature, KeyEncipherment

    $t = $cert.Thumbprint

    $pfx = Join-Path $root "$fn.pfx"
    $password = Read-Host "Enter password for $fn" -AsSecureString
    Get-ChildItem -Path cert:\CurrentUser\my\$t | Export-PfxCertificate -FilePath $pfx -Password $password

    #$crt = Join-Path $root "$fn.crt"
    #Convert-PfxToCrt $cert.RawData $crt    
    return $t
}

$t = Create-RootCA
Write-Host "Root CA has thumbprint: $t"
$thumbprint = Read-Host "Enter thumbprint to sign: "
Create-IntermediateCA $thumbprint
# TODO: Sign with intermediate? Then root and intermediate must be available for Docker image
Create-ClientCertificate "CN=cca_client,O=Development,OU=local,C=SE" $thumbprint
