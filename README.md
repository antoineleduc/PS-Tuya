# PS-Tuya
PowerShell Script to communicate with Tuya devices

I decided to include my PowerShell code for Woods Wion (Eco-Plugs) smart outlet into my tools, why not share it with other people?
<br>
## What you will need:
Get the access token valid for 2 hours using 
<br>`Get-TuyaToken -clientid "[clientid_from_tuya_dev_portal]" -secret "[secret_from_tuya_dev_portal]"`

You can verify the status of the device using 
<br>`Get-TuyaStatus -deviceid "[deviceid_from_app_settings]"`

Get the supported commands for your device using 
<br>`Get-TuyaCommands -deviceid "[deviceid_from_app_settings]"`

Exemple of a command to send: 
<br>`Send-TuyaCommand -deviceid "[deviceid_from_app_settings]" -code "bright_value_1" -value "1000"`
<br><b>ENJOY!</b>
<br>

```powershell
function Get-TuyaToken{

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
```
