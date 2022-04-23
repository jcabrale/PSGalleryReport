#requires -version 5.1
#requires -module PowerShellGet

#this script is run from a PowerShell scheduled job so use explicit paths to avoid errors.

Param(
    [Parameter(HelpMessage = "Run the reports using offline data")]
    [switch]$Offline,
    [Parameter(HelpMessage = "Create the reports but skip git commands.")]
    [switch]$Testing
)
Write-Host "[$(Get-Date)] Starting c:\scripts\psgalleryreport\run.ps1" -ForegroundColor cyan
$tmpData = "$env:temp\psgallery.xml"

if (-Not $Offline) {
    Try {
        #verify PwoerShellGallery is online
        Write-Host "[$(Get-Date)] Testing PowerShellGallery.com"
        $test = Invoke-WebRequest -Uri https://powershellgallery.com -DisableKeepAlive -UseBasicParsing -ErrorAction Stop
        if ($test.statuscode -eq 200) {
            #save an offline file of all modules and use that for the reports
            Write-Host "[$(Get-Date)] Saving offline data to $tmpData" -ForegroundColor cyan
            Find-Module -Repository PSGallery -ErrorAction Stop | Export-Clixml -Path $tmpData
        }
        else {
            Throw "PowerShellGallery.com is not available. Status code $($test.statuscode),"
        }
    }
    Catch {
        Throw $_
    }
}

if (Test-Path $tmpData) {
    #newest is the default
    Write-Host "[$(Get-Date)] Running report list" -ForegroundColor cyan
    C:\scripts\psgalleryreports\scripts\make-reports.ps1 -Offline
    C:\scripts\psgalleryreports\scripts\make-reports.ps1 -Offline -NoAzureAWS
    C:\scripts\psgalleryreports\scripts\make-reports.ps1 -Offline -ReportType Azure
    C:\scripts\psgalleryreports\scripts\make-reports.ps1 -Offline -ReportType Downloads
    C:\scripts\psgalleryreports\scripts\make-reports.ps1 -Offline -ReportType CommunityDownloads

    #top author report
    C:\scripts\psgalleryreports\scripts\top-authorreport.ps1
    #make tag list
    C:\scripts\PSGalleryReports\scripts\make-taglist.ps1
    #Create PDFs
    c:\scripts\psgalleryreports\scripts\create-pdf.ps1

    if (-Not $Testing) {
        #git updates
        Write-Host "[$(Get-Date)] Running git updates" -ForegroundColor cyan
        Set-Location C:\scripts\PSGalleryReports
        git add .
        $msg = "reporting run $(Get-Date -Format u)"
        git commit -m $msg
        Write-Host "[$(Get-Date)] Pushing commit to Github" -ForegroundColor cyan
        git push
    }
}
else {
    Write-Warning "Can't find $tmpData"
}

Write-Host "[$(Get-Date)] Ending c:\scripts\psgalleryreport\run.ps1" -ForegroundColor cyan

<#
Change Log

4/23/2022
  Added test for PowerShellGallery.com

4/20/2022
  Added top author report

4/13/2022
  Replaced $myinvocation.mycommand with hard-coded references since $myinvocation doesn't resolve
  when run from a PowerShell scheduled job.

4/11/2022
  added make-taglist.ps1
  added community download report

#>