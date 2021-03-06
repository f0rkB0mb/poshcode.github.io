#requires -version 2.0
## ISE-Snippets module v 1.0
## DEVELOPED FOR CTP3 
## See comments for each function for changes ...
##############################################################################################################
## As a shortcut for every snippet would be to much, I created Add-Snippet which presents a menu.
## Feel free to add your own snippets to function Add-Snippet but please contribute your changes here
##############################################################################################################
## Provides Code Snippets for working with ISE
## Add-Snippet - Presents menu for snippet selection
## Add-SnippetToEditor - Adds a snippet at caret position
##############################################################################################################


## Add-Snippet
##############################################################################################################
## Presents menu for snippet selection
##############################################################################################################
function Add-Snippet
{
    $snippets = @{
        "region" = @( "#region", "#endregion" )
        "function" = @( "function FUNCTION_NAME", "{", "}" )
        "param" = @( "param ``", "(", ")" )
        "if" = @( "if ( CONDITION )", "{", "}" )
        "else" = @( "else", "{", "}" )
        "elseif" = @( "elseif ( CONDITION )", "{", "}" )
        "foreach" = @( "foreach ( ITEM in COLLECTION )", "{", "}" )
        "for" = @( "foreach ( INIT; CONDITION; REPEAT )", "{", "}" )
        "while" = @( "while ( CONDITION )", "{", "}" )
        "dowhile" = @( "do" , "{", "}", "while ( CONDITION )" )
        "dountil" = @( "do" , "{", "}", "until ( CONDITION )" )
        "try" = @( "try", "{", "}" )
        "catch" = @( "catch", "{", "}" )
        "catch [<error type>] " = @( "catch [ERROR_TYPE]", "{", "}" )
        "finaly" = @( "finaly", "{", "}" )
    }
    

    $editor = $psISE.CurrentOpenedFile.Editor
    if ( $editor.SelectedText.length -eq 0) {
        $caretLine = $editor.CaretLine
        $caretColumn = $editor.CaretColumn
        $text = $editor.Text.Split("`n")
        $line = $text[$caretLine -1]
        $LeftOfCarret = $line.substring(0, $caretColumn - 1)
        $parts = $LeftOfCarret.split("")
        $len = $parts[-1].length
        $start = $caretColumn - $len
        $editor.select($caretLine, $start, $caretLine, $caretColumn )
    }    

      $snippetName = $editor.SelectedText
      $editor.insertText('')
      Add-SnippetToEditor $snippets[$snippetName]
}

## Add-SnippetToEditor
##############################################################################################################
## Adds a snippet at caret position
##############################################################################################################
function Add-SnippetToEditor
{
    param `
    (
        [string[]] $snippet
    )

    $editor = $psISE.CurrentOpenedFile.Editor
    $caretLine = $editor.CaretLine
    $caretColumn = $editor.CaretColumn
    $text = $editor.Text.Split("`n")
    $newText = @()
    if ( $caretLine -gt 1 )
    {
        $newText += $text[0..($caretLine -2)]
    }
    $curLine = $text[$caretLine -1]
    $indent = $curline -replace "[^\t ]", ""
    foreach ( $snipLine in $snippet )
    {
        $newText += $indent + $snipLine
    }
    if ( $caretLine -ne $text.Count )
    {
        $newText += $text[$caretLine..($text.Count -1)]
    }
    $editor.Text = [String]::Join("`n", $newText)
    $editor.SetCaretPosition($caretLine, $caretColumn)
}

#Export-ModuleMember Add-Snippet


##############################################################################################################
## Inserts command Add Snippet to custom menu
##############################################################################################################
if (-not( $psISE.CustomMenu.Submenus | where { $_.DisplayName -eq "_Snippet" } ) )
{
    $null = $psISE.CustomMenu.Submenus.Add("_Snippet", {Add-Snippet}, "Ctrl+Alt+S")
}
