while($cell.value2.length -ge 0) {
  $name = $cell.value2
  $sam = $cell.offset(0,1).value2
  $givenName = $cell.offset(0,2).value2
  $surName = $cell.offset(0,3).value2
  $displayName = $cell.offset(0,4).value2
  $password = $cell.offset(0, 5).value2
  
  write-host "navn:" $name "`t`t,sam:" $sam "`t,GivenName:" $givenName "`t, surname:" $surName "`t,displayName:" $displayName "`t, password:" $password
  
  #new cell one row down
  $cell = $cell.offset(1, 0)
}

