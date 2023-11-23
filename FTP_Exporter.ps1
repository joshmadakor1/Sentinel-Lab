# Get API key from here: https://ipgeolocation.io/
$API_KEY = "<API_KEY_HERE>"
$LOGFILE_FTP = "C:\ProgramData\FTPSVC2\u_extend0.log"
$LOGFILE_FTP_OUTPUT = "C:\ProgramData\failed_ftp.log"

function write-Sample-Log() {
    "latitude:39.90499,longitude:116.40529,sourcehost:sample,state:Beijing,country:China,timestamp:2023-11-22 06:57:21,ISP:UCloud/China Telecom/China Unicom, label:China - 106.75.90.129" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
    "latitude:37.42240,longitude:-122.08421,sourcehost:sample,state:California,country:United States,timestamp:2023-11-22 08:19:04,ISP:Google LLC, label:United States - 34.78.6.216" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
    "latitude:37.69527,longitude:-121.90062,sourcehost:sample,state:California,country:United States,timestamp:2023-11-22 12:17:05,ISP:Hurricane Electric LLC, label:United States - 184.105.247.196" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
    "latitude:37.42240,longitude:-122.08421,sourcehost:sample,state:California,country:United States,timestamp:2023-11-22 13:42:32,ISP:Google LLC, label:United States - 35.205.96.143" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
    "latitude:37.73345,longitude:-122.38998,sourcehost:sample,state:California,country:United States,timestamp:2023-11-22 15:26:23,ISP:DigitalOcean, LLC, label:United States - 198.199.107.82" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
    "latitude:37.38293,longitude:-121.98216,sourcehost:sample,state:California,country:United States,timestamp:2023-11-22 17:40:43,ISP:Palo Alto Networks, Inc, label:United States - 205.210.31.198" | Out-File $LOGFILE_FTP_OUTPUT -Append -Encoding utf8
}

if ((Test-Path $LOGFILE_FTP_OUTPUT) -eq $false) {
    New-Item -ItemType File -Path $LOGFILE_FTP_OUTPUT
    write-Sample-Log
}


# Preforms Geo Location
function Get-GeoLocationAndLog {
    param (
        [string]$sourceIp,
        [string]$timestamp,
        [string]$LOGFILE_PATH
    )

    $log_contents = Get-Content $LOGFILE_PATH -ErrorAction SilentlyContinue

    do {
        $currentSecond = (Get-Date).Second
    } until ($currentSecond % 2 -ne 0)

    if (-Not ($log_contents -match "$($timestamp)") -or ($log_contents.Length -eq 0)) {
        # Announce the gathering of geolocation data and pause for a second as to not rate-limit the API
        #Write-Host "Getting Latitude and Longitude from IP Address and writing to log" -ForegroundColor Yellow -BackgroundColor Black
        Start-Sleep -Seconds 1

        # Make web request to the geolocation API
        # For more info: https://ipgeolocation.io/documentation/ip-geolocation-api.html
        $API_ENDPOINT = "https://api.ipgeolocation.io/ipgeo?apiKey=$($API_KEY)&ip=$($sourceIp)"
        $response = Invoke-WebRequest -UseBasicParsing -Uri $API_ENDPOINT

        # Pull Data from the API response, and store them in variables
        $responseData = $response.Content | ConvertFrom-Json
        $latitude = $responseData.latitude
        $longitude = $responseData.longitude
        $state_prov = $responseData.state_prov
        $isp = $responseData.isp
        if ($state_prov -eq "") { $state_prov = "null" }
        $country = $responseData.country_name
        if ($country -eq "") {$country -eq "null"}

        # Write all gathered data to the custom log file.
        $logData = "latitude:$($latitude),longitude:$($longitude),sourcehost:$($sourceIp),state:$($state_prov),country:$($country),timestamp:$($timestamp),ISP:$($isp), label:$($country) - $($sourceIp)"
        $logData | Out-File $LOGFILE_PATH -Append -Encoding utf8

        Write-Host -BackgroundColor Black -ForegroundColor Red $logData
    }
}

# Continuously monitor the log file for new lines
Get-Content $LOGFILE_FTP -Wait | ForEach-Object {
    # Check if the line contains "ControlChannelOpened"
    if ($_ -like "*ControlChannelOpened*") {
        # Split the line by spaces to extract timestamp and IP
        $lineParts = $_ -split ' '
        
        # Extract timestamp and IP
        $time = $lineParts[0] + " " + $lineParts[1]
        $ip = $lineParts[2]
        
        Get-GeoLocationAndLog -sourceIp $ip -timestamp $time -LOGFILE_PATH $LOGFILE_FTP_OUTPUT    
    }
}
