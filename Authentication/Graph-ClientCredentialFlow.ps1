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
$clientSecret = 'Enter ClientSecret here'

$body = @{
    'tenant' = $tenantID
    'client_id' = $clientID
    'scope' = 'https://graph.microsoft.com/.default'
    'client_secret' = $clientSecret
    'grant_type' = 'client_credentials'
}
$params =@{
    'Uri' = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"
    'Method' = 'Post'
    'Body' = $body
    'ContentType' = 'application/x-www-form-urlencoded'
}

$response = Invoke-RestMethod @params

$Headers = @{
    'Authorization' = "Bearer $($response.access_token)"
}

$result = Invoke-RestMethod -Headers $Headers -Method Get -Uri 'https://graph.microsoft.com/v1.0/users/{username}' 

$result.value