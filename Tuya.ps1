﻿function Get-TuyaToken{

    Param(
        [parameter(Mandatory)]
        [string]$clientid,
        [parameter(Mandatory)]
        [string]$secret,
        [parameter(Mandatory=$false)]
        [string]$sign_method = "HMAC-SHA256"
    )

    $global:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $global:headers.Add("client_id", $clientid)
    $global:headers.Add("secret", $secret)
    
    $timestamp = [Math]::Floor(1000 * (Get-Date ([datetime]::UtcNow) -UFormat %s))
    $global:headers.Add("t", $timestamp)

    $str = $headers.client_id+$timestamp
    $secret = $headers.secret
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($str))
    $global:sigHex = [BitConverter]::ToString($signature).Replace('-','').ToUpper()

    $global:headers.Add("sign", $sigHex)
    $global:headers.Add("sign_method", $sign_method)
    
    $response = Invoke-RestMethod 'https://openapi.tuyaus.com/v1.0/token?grant_type=1' -Method 'GET' -Headers $headers
    $response | ConvertTo-Json

    $global:accesstoken = $response.result.access_token

    $global:headers.Add("access_token", $accesstoken)
    $global:headers.Add("Content-Type", "application/json")
    
    $timestamp = [Math]::Floor(1000 * (Get-Date ([datetime]::UtcNow) -UFormat %s))
    $global:headers.t = $timestamp

    $str = $headers.client_id+$response.result.access_token+$timestamp
    $secret = $headers.secret
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($str))
    $sigHex = [BitConverter]::ToString($signature).Replace('-','').ToUpper()

    $global:headers.sign = $sigHex

    clear
    Write-Host $accesstoken`n
    }

function Get-TuyaStatus{
     Param(
        [parameter(Mandatory=$false)]
        [string]$clientid = $clientid,
        [parameter(Mandatory=$false)]
        [string]$secret = $secret,
        [parameter(Mandatory=$false)]
        [string]$sign_method = "HMAC-SHA256",
        [parameter(Mandatory)]
        [string]$deviceid
    )

    $TuyaURL = 'https://openapi.tuyaus.com/v1.0/devices/'+$deviceid+'/status'
    $response = Invoke-RestMethod $TuyaURL -Method 'GET' -Headers $headers
    $response | ConvertTo-Json

    $global:ONResult = $response.result.value[0]

    if($ONResult -eq "True"){$ONStatus = "ON"}
    else{$ONStatus = "OFF"}

    $global:BrightStatus = ($response.result.value[1])/10
    
    clear
    Write-Host "Curent Status: $ONStatus $BrightStatus%`n"
    }

function Send-TuyaCommand{
    
    Param(
        [parameter(Mandatory=$false)]
        [string]$clientid = $clientid,
        [parameter(Mandatory=$false)]
        [string]$secret = $secret,
        [parameter(Mandatory=$false)]
        [string]$sign_method = "HMAC-SHA256",
        [parameter(Mandatory)]
        [string]$deviceid,
        [parameter(Mandatory)]
        [string]$code,
        [parameter(Mandatory)]
        [string]$value
    )

    $TuyaURL = 'https://openapi.tuyaus.com/v1.0/devices/'+$deviceid+'/commands'
    $body = "{`n	`"commands`":[`n		{`n			`"code`": `"$code`",`n			`"value`":$value`n		}`n	]`n}"
    $response = Invoke-RestMethod $TuyaURL -Method 'POST' -Headers $headers -Body $body
}

function Get-TuyaCommands{
    
    Param(
        [parameter(Mandatory=$false)]
        [string]$clientid = $clientid,
        [parameter(Mandatory=$false)]
        [string]$secret = $secret,
        [parameter(Mandatory=$false)]
        [string]$sign_method = "HMAC-SHA256",
        [parameter(Mandatory)]
        [string]$deviceid
    )

    $TuyaURL = 'https://openapi.tuyaus.com/v1.0/devices/'+$deviceid+'/functions'
    $response = Invoke-RestMethod $TuyaURL -Method 'GET' -Headers $headers
    $response | ConvertTo-Json
    clear
    $response.result.functions | format-table code,type,values

}


Get-TuyaToken -clientid "9ncx5yg8a8wfoknaccig" -secret "a6f6d87a741745769b02a13e91fe5f6d"
Get-TuyaStatus -deviceid "036282088caab5ff088f"
Send-TuyaCommand -deviceid "036282088caab5ff088f" -code "bright_value_1" -value "1000"
Get-TuyaCommands -deviceid "036282088caab5ff088f"