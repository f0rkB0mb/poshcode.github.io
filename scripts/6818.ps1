function get-roman ([int]$myNum)
{
    if ($myNum -ge 4000 -or $myNum -le 0) 
    {
        "$myNum is not a good one"
    } else {
        $myRomans = [Ordered]@{ M=1000;CM=900;D=500;CD=400;C=100;XC=90;L=50;XL=40;X=10;IX=9;V=5;IV=4;I=1 }
        foreach ($key in $myRomans.Keys)
        {
            while ($myNum -ge  $myRomans.item($key)) 
            {
                 $myOut += $key; # build Roman numeral
                 $myNum -= $myRomans.item($key) # subtract value from given number
            }
        }
        $myOut
    }
}
