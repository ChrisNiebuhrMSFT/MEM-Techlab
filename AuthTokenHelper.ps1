class AuthToken
{

    #Properties
    hidden [string]
    $_token
    hidden [System.Collections.Generic.List[PSObject]]
    $_result
    [PSObject]
    $Result

    # Constructor
    AuthToken([string]$tokenString)
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
    # Methods
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
}

#ERASE ALL THIS AND PUT XAML BELOW between the @" "@ 
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
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Margin="5" Grid.Column="0" Grid.Row="0" Text="Copy token here" FontWeight="Bold"/>
        <TextBox  x:Name="TxtTokenInput" Margin="5" Grid.Column="0" Grid.Row="1" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" />
        <TextBlock Margin="5" Grid.Column="1" Grid.Row="0" Text="Token Result" FontWeight="Bold"/>
        <Border BorderBrush="LightGray" BorderThickness="1" Grid.Column="1" Grid.Row="1" Margin="5">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBlock x:Name="TxtResult" Grid.Column="1" Grid.Row="1" Margin="5" TextWrapping="Wrap"/>
        </ScrollViewer>
        </Border>
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
        $token = [Authtoken]::new($WPFTxtTokenInput.Text)
        if($token.Result -ne 'Invalid token')
        {
            $props=$token.Result.psobject.Properties

            foreach($prop in $props)
            {
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

