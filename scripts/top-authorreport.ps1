#create top author report excluding major vendors
#this script needs offline psgallery data
Param(
    [string]$Path = "$env:temp\psgallery.xml",
    [string]$Title = "Top 25 PSGallery Contributors",
    [string]$Filename = "psgallery-authors.md"
)

Write-Host "[$(Get-Date)] Starting $($myinvocation.mycommand)" -ForegroundColor darkcyan

#initialize defaults
$intro = Get-Content C:\scripts\PSGalleryReports\scripts\author-intro.txt
$all = Import-Clixml $Path

#exlude major vendors. This is subjective and completely arbitrary.
$filter = { $_.author -notmatch '\b(Microsoft|Amazon|Dell|DSC|Oracle|VMware|OneScript|HP|PowerShell Team|CData|BitTitan|Hewlett-Packard)\b'}
$query = $all | Where-Object $filter -OutVariable f
$top = $query| Group-Object author | Sort-Object count -Descending | Select-Object -first 25

$md = [System.Collections.Generic.list[string]]::new()
$md.Add("# $title`n")
$intro | ForEach-Object {$md.add($_)}
$md.Add("`n")

#insert navigation 4/21/2022 JDH
$top.foreach({
    #modify the name for the bookmark
    $link = $_.name.replace(' ','-')
    $link = $link -replace "[\.@]",""
    Write-Host "[$(Get-Date)] Creating link $link" -ForegroundColor DarkMagenta
    $nav = "+ [$($_.name)](#$link) ($($_. count))"
    $md.Add($nav)
})

foreach ($item in $top) {
    Write-Host "[$(Get-Date)] Processing author $($item.name)" -ForegroundColor darkcyan
    $md.Add("`n## $($item.name)`n")

    $item.group | Sort-Object PublishedDate -Descending | ForEach-Object {
        if ($_.projectURI) {
            $uri = ($_.projectURI).absoluteUri
            $modName = "[$($_.name) $($_.version)]($uri)"
        }
        else {
            $modName = "$($_.name) $($_.version)"
        }

        $md.Add("+ **$modName**  - $($_.description) [*$($_.PublishedDate)*]")
    }
}

$md.add("`n*Updated: $(Get-Date -Format U) UTC*")

Write-Host "[$(Get-Date)] Saving report to $filename" -ForegroundColor darkcyan
$md | Out-File "c:\scripts\psgalleryreports\$filename" -Encoding utf8
Write-Host "[$(Get-Date)] Ending $($myinvocation.mycommand)" -ForegroundColor darkcyan

<#
Change log

4/22/2022
  - updated code to define internal link
4/21/2022
  - Added navigation to top 25 authors
4/20/2022
 - Initial release

#>