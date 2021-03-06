#requires -version 2.0
function Get-PopupInfo {
  param(
    [Parameter(Position=0)]
    [ValidateRange(3, 15)]
    [Int32]$TimeOut = 3
  )
  
  begin {
    $raw = $host.UI.RawUI
    $old = $raw.WindowPosition
    $con = $raw.WindowSize
    $rec = New-Object Management.Automation.Host.Rectangle $old.X, $old.Y, `
                                        $raw.BufferSize.Width, ($old.Y + 25)
    $buf = $raw.GetBufferContents($rec)
    
    function strip([Int32]$x, [Int32]$y, [Int32]$z, [ConsoleColor]$bc) {
      $pos = $old;$pos.X += $x;$pos.Y += $y
      $row = $raw.NewBufferCellArray(@(' ' * $z), $bc, $bc)
      $raw.SetBufferContents($pos, $row)
    }
    
    function msg([Int32]$x, [Int32]$y, [String]$text, [ConsoleColor]$fc, [ConsoleColor]$bc) {
      $pos = $old;$pos.X += $x;$pos.Y += $y
      $row = $raw.NewBufferCellArray(@($text), $fc, $bc)
      $raw.SetBufferContents($pos, $row)
    }
  }
  process {
    0..2 | % {strip 0 $_ ($con.Width) 'Yellow'}
    msg 3 0 $('Today: {0}' -f (date -u %d/%m/%Y)) 'Blue' 'Yellow'
    msg 3 1 $('Host running: {0}' -f ((date) - (ps -id $pid).StartTime)) 'DarkGreen' 'Yellow'
    msg 3 2 $('Commands: {0}' -f ((history | select id -Last 1).Id)) 'Magenta' 'Yellow'
    sleep -sec $TimeOut
  }
  end {
    $raw.SetBufferContents($old, $buf)
  }
}
