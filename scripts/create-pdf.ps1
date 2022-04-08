#requires -version 5.1

Write-Host "[$(Get-Date)] Starting Markdown to PDF conversion" -foreground green
#this script uses a private set of commands for converting markdown to adoc to pdf.
. C:\scripts\rubydocs.ps1

Get-Childitem $PSScriptRoot\..\psgallery-*.md | foreach-Object {
    Write-Host "[$(Get-Date)] Converting $($_.fullname) to adoc format" -foreground green
    Convertto-Adoc -fullname $_.fullname -images .\images -Passthru | Convert-Links
    $adoc = $($_.fullname).replace(".md",".adoc")
    Write-Host "[$(Get-Date)] Converting $adoc to pdf" -foreground Green
    asciidoctor -a allow-uri-read -a linkattrs -b pdf -d manpage -r asciidoctor-pdf -a pdfwidth=pt -a pdf-fontsdir=C:\gemfonts -a pdf-theme=.\pdf-theme.yml $adoc
    Write-Host "[$(Get-Date)] Optimizing PDF" -foreground green
    Optimize-pdf $adoc.replace(".adoc",".pdf")
} -end {
    Write-Host "[$(Get-Date)] Removing adoc files" -foreground green
    Remove-Item *.adoc
}

Write-Host "[$(Get-Date)] Ending Markdown to PDF conversion" -foreground green