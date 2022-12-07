Function Get-PSUDownloadLinks {
    Microsoft.PowerShell.Utility\Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility
    $TLS12Protocol = [System.Net.SecurityProtocolType] 'Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol
    [string]$home_url_psu = 'https://ironmansoftware.com/powershell-universal/downloads'
    [string]$regex_psu_link = 'https://[-\w./]{1,}((msi)|(zip)|(exe))'
    [string]$regex_psu_downloads = '(?!(\)}>))[\w ]+(?=(<\/a>))'
    [hashtable]$parameters = @{}
    $parameters.Add('Uri', $home_url_psu)
    $parameters.Add('UseBasicParsing', $true)
    $Error.Clear()
    Try {
        [Microsoft.PowerShell.Commands.WebResponseObject]$results = Microsoft.PowerShell.Utility\Invoke-WebRequest @parameters
    }
    Catch {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } |  Microsoft.PowerShell.Utility\Select-Object -First 1 | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty Exception
        [string]$parameters_string = $parameters |  Microsoft.PowerShell.Commands.Utility\ConvertTo-Json -Compress
        Microsoft.PowerShell.Utility\Write-Host "Invoke-WebRequest failed (while using $parameters_string) due to [$error_message]"
        Return
    }
    [int32]$results_status_code = $results.StatusCode
    If ($results_status_code -ne 200) {
        Microsoft.PowerShell.Utility\Write-Host "Somehow a status code of [$results_status_code] was returned from Invoke-WebRequest when accessing $home_url_psu"
        Return
    }
    [int32]$content_length = $results.RawContentLength
    If ( $content_length -eq 0) {
        Microsoft.PowerShell.Utility\Write-Host "Somehow the retrieved content was empty when accessing $home_url_psu"
        Return
    }
    [array]$download_links = $results.Links -match $regex_psu_link | Select-Object $matches
    [int32]$download_links_count = $download_links.Count
    If ( $download_links_count -eq 0) {
        Microsoft.PowerShell.Utility\Write-Host "Somehow the retrieved content had no matching links when accessing $home_url_psu"
        Return
    }
    [array]$download_links_formatted = ForEach ( $link in $download_links) {
        If ( $null -ne $Matches ) {
            $Matches.Clear()
        }
        $link.outerHTML -match $regex_psu_downloads | Out-Null
        [string]$download_type = $Matches.Values | Select-Object -Last 1
        [string]$download_link = $link.href
        If ($download_type.Length -eq 0) {
            Microsoft.PowerShell.Utility\Write-Host "Somehow the download type was empty for $link"
            Return
        }
        If ($download_link -notmatch $regex_psu_link) {
            Microsoft.PowerShell.Utility\Write-Host "Somehow the download link was not a valid url for $link"
            Return
        }
        [string]$file_version = $download_link -split '/' | Microsoft.PowerShell.Utility\Select-Object -Skip 1 -Last 1
        [string]$file_name = $download_link -split '/' | Microsoft.PowerShell.Utility\Select-Object -Skip 0 -Last 1
        [PSCustomObject]@{ download_type = $download_type; file_version = $file_version; file_name = $file_name; download_link = $download_link; }
    }
    Return $download_links_formatted
}
