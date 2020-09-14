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

#Helper-Class to deal with Azure Authentication Tokens
class AuthTokenHelper
{
    #region Properties
    hidden [string]
    $_token
    hidden [System.Collections.Generic.List[PSObject]]
    $_result
    [PSObject]
    $Result
    #endregion

    #region Constructor
    AuthTokenHelper([string]$tokenString)
    {
        if($this.IsTokenValid($tokenString))
        {
            $this._token = $tokenString
            $this.ProcessToken()
        }
        else
        {
            $this._token = $null  
            $this.Result = 'Invalid token'
        }
    }
    #endregion

    #region Methods
    #Check if the provided Token is valid 
    hidden [bool]IsTokenValid([string]$tokenString)
    {
        [bool] $isValid = $false
        if($tokenString.StartsWith('eyJ') -and $tokenString -notmatch '[^a-z0-9_\-\.]+')
        {
            $isValid = $true
        }
        return $isValid
    }

    # Process the JWT and convert the Data to a human readable format
    hidden [void]ProcessToken()
    {
        $this._result = New-Object System.Collections.Generic.List[PSObject]
        $splits = ($this._token -split '\.')[0..1]

        if($splits.count -gt 1)
        {
            foreach($split in $splits)
            {
                $data = $split
                switch($data.Length % 4)
                {
                    0 {break}
                    2 {$data+= '=='; break}
                    3 {$data+= '=' ; break}
                }
                $dataNorm = $data -replace '-', '+' -replace '_', '/'
                $this._result.Add(([System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($dataNorm)) | ConvertFrom-Json))
                $this.Result = $this._result[1]
            }
        }
        else
        {
            $data = $splits[0]
            switch($data.Length % 4)
            {
                0 {break}
                2 {$data+= '=='; break}
                3 {$data+= '=' ; break}
            }
            $dataNorm = $data -replace '-', '+' -replace '_', '/'
            $this._result.Add(([System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($dataNorm)) | ConvertFrom-Json))
            $this.Result = $this._result[0]
        }   
    }
    #endregion
}

#region PowerShell GUI
$inputXML = @"
<Window x:Class="PSTokenViewer.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:PSTokenViewer"
        mc:Ignorable="d"
        Title="Azure Token Viewer" Height="450" Width="800" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Margin="5" Grid.Column="0" Grid.Row="0" Text="Copy token here" FontWeight="Bold"/>
        <ScrollViewer Grid.Row="1" Grid.Column="0" VerticalScrollBarVisibility="Auto">
            <TextBox  x:Name="TxtTokenInput" Margin="5" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" TextWrapping="Wrap"/>
        </ScrollViewer>
        <TextBlock Margin="5" Grid.Column="2" Grid.Row="0" Text="Token Result" FontWeight="Bold"/>
        <Border Grid.Column="2" Grid.Row="1" BorderBrush="LightGray" BorderThickness="1" Margin="5" />
        <TextBlock  x:Name="TxtResult" Grid.Column="2" Grid.Row="1" Margin="5" TextWrapping="Wrap"/>
        <GridSplitter Grid.Column="1" Grid.Row="1" Width="8" Height="15" VerticalAlignment="Stretch" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@ 


$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try
{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch [System.Management.Automation.MethodInvocationException]
{
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    Write-Host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*")
    {
        Write-Warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch
{
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{Set-Variable -Name ('WPF{0}' -f ($_.Name)) -Value $Form.FindName($_.Name)}
#region Eventhandler
$OnTextChanged=
{
    if($WPFTxtTokenInput.Text.Length -gt 0)
    {
        $token = [AuthtokenHelper]::new($WPFTxtTokenInput.Text)
        if($token.Result -ne 'Invalid token')
        {
            #Iterate through every Property of Token.Result 
            #This is for formatting purposes
            $props=$token.Result.psobject.Properties
            foreach($prop in $props)
            {
                #A Run is used to do inline formatting inside a Textblock
                $run = New-Object -TypeName System.Windows.Documents.Run
                $run.FontWeight = [System.Windows.FontWeights]::Bold
                $run.Text = '{0}: ' -f $prop.Name
                $run.Foreground = [System.Windows.Media.Brushes]::Green
                $WPFTxtResult.Inlines.Add($run)
                if($prop.Value -is [Array])
                {
                    $tmpValues = $prop.Value -join ","
                }
                else 
                {
                    $tmpValues = $prop.Value
                }
                $run = New-Object -TypeName System.Windows.Documents.Run
                $run.Text = "{0}`n" -f$tmpValues
                $run.Foreground = [System.Windows.Media.Brushes]::Blue
                $WPFTxtResult.Inlines.Add($run)
            }
        } 
        else
        {
            $WPFTxtResult.Text = 'Invalid token'
        }
    }
    else
    {
        $WPFTxtResult.Text = [string]::Empty
    }
}
#endregion

$WPFTxtTokenInput.Add_TextChanged($OnTextChanged)
$Form.ShowDialog() | Out-Null
#endregion

$data =  'JhQqGjTRT-X8IgTmNDfVgp5CaZQQZnb2wGD7cz9wrSHSfFF6rEN_Jqm3_9NKH5AZK3ypKxB88SqkMqeT6XF4MfhQ7ERjDgRLwwYGS9y8UhrEL6Dh5lYnRb9t1T4PLQToXhQV1XtRKqAUsKerPjBGgcw3T6ilJ4fl_4pbztijlG0n7A5AUeScQw9sxund3UPEV1EpUjN990Ae6YInffrjzc34XDBhXs9pgl7Y5zwsIq-Q8NWGA3nTFgRHpNCta3cNhHFpq0tQlXSMRUYO-dQUHkqpkIYm87X1jP0P2tZu3A0oRD_PT41IMYQOQiMupy8g7Eoyq58r5MC6yM__oOdIkA==' -replace '-', '+' -replace '_', '/'
[System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($data))