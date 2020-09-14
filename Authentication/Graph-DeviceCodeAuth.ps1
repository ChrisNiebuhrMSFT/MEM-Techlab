<#
Disclaimer

This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance 
of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for 
any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the 
use of or inability to use the sample scripts or documentation, even if Microsoft has been advised 
of the possibility of such damages

Author: Microsoft  (Chris Niebuhr)
Mail:   Chris.Niebuhr@Microsoft.com
Date:   09.09.2020
#>

$tenantID = 'Enter TenantID here'
$clientID = 'Enter ClientID here'
$resource = "https://graph.microsoft.com/";
$authUrl = "https://login.microsoftonline.com/$tenant";

$postParams = @{ resource = "$resource"; client_id = "$clientId" }
$response = Invoke-RestMethod -Method POST -Uri "$authurl/oauth2/devicecode" -Body $postParams
Write-Host $response.message
$tokenParams = @{ grant_type = "device_code"; resource = "$resource"; client_id = "$clientId"; code = "$($response.device_code)" }

$tokenResponse = Invoke-RestMethod -Method POST -Uri "$authurl/oauth2/token" -Body $tokenParams
$header = @{'Authorization' = "Bearer $($tokenResponse.access_token)"}
Invoke-RestMethod -Method Get -Uri 'https://graph.microsoft.com/beta/me/presence' -Headers $header


$tokenResponse