function Get-SimpsonQuote{
    <#
    .SYNOPSIS
    Does a little html scraping to get a random quote from the Simpsons.

    .DESCRIPTION
    Use with caution. 

    .EXAMPLE
    Get-SimpsonQuote

    Homer: About last night. You might have noticed Daddy acting a little strange and you probably don't understand why.
    Bart: I understand why. You were wasted.
    Homer: I admit it. I didn't know when to say "when." I'm sorry it happened and I just hope you didn't lose a lot of respect for me.
    Bart: Dad, I have as much respect for you as I ever did or ever will.

    #>

    [cmdletbinding()]
    param()

    $site = 'http://en.wikiquote.org'
    
    $main = Invoke-WebRequest -Uri "$site/wiki/The_Simpsons"
    
    filter Get-Episodes {if($_.href -like '/wiki/The_Simpsons/Season_*#*'){$_}}
    
    $episodes = $main.Links | Get-Episodes

    $random_episode = Get-Random -Minimum 0 -Maximum $episodes.count

    $uri = "$site$($episodes[$random_episode].href)"
    Write-Verbose "Getting quote from `"$site$($episodes[$random_episode].href).`""    

    $episode_page = Invoke-WebRequest -Uri $uri

    $quote_index = @()
    0..($episode_page.AllElements.count-1) | 
        ForEach-Object {if($episode_page.AllElements.item($_).tagname -eq 'DL'){$quote_index+=$_}}

    $random_quote = Get-Random -Minimum 0 -Maximum ($quote_index.count -1)

    Write-Output ($episode_page.AllElements.item($quote_index[$random_quote]).innerText)
}

Get-SimpsonQuote
