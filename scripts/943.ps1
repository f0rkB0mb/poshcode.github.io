function Get-VCTime() {
   return (Get-View "ServiceInstance-ServiceInstance").CurrentTime()
}


$lastCheckTime = Get-VCTime

while ($true)
{
   $modifiedVMs = @()
   $freshEventsStartTime = $lastCheckTime
   $lastCheckTime = Get-VCTime
   
   # Get all the VM network edit events
   foreach ($event in Get-VIEvent -Start $freshEventsStartTime -Types Info)
   {
      if ($event.GetType().FullName -eq "VimApi.VmReconfiguredEvent" -and
         $event.configSpec -ne $null)
      {
         foreach ($change in $event.configSpec.deviceChange)
         {
            if ($change.operation -eq "edit" -and
               $change.device -ne $null -and
               $change.device.GetType().FullName -eq "VimApi.VirtualPCNet32")
            {
               # VM's networking was reconfigured.
               $vmId = $event.vm.vm.Type + '-' + $event.vm.vm.Value
               $modifiedVMs += Get-VM -Id $vmId
            }
         }
      }
   }

   # Did one of these edits violate isolation?
   foreach ($vm in $modifiedVMs | select -Unique)
   {
      $intranetNics = $vm.NetworkAdapters | where { $_.NetworkName -eq 'Intranet' }
      $dmzNics      = $vm.NetworkAdapters | where { $_.NetworkName -eq 'DMZ' }

      if ($intranetNics -ne $null -and $dmzNics -ne $null)
      {
         # Send an email notification
         $message = "VM '" + $vm.Name + "' violates network isolation rules!"
         Write-Host $message -ForegroundColor Yellow
         
         # Use .Net’s SmtpClient to send mail. Just tell it which SMTP server to use
         (New-Object 'System.Net.Mail.SmtpClient' 'smtp.example1234.com').Send(
            'NetworkMonitor@example1234.com',   # Sender
            'john.doe@example1234.com',         # Recipient
            'Network isolation violation',      # Subject
            $message)
      }
   }

   Start-Sleep 60
} # while ($true)
