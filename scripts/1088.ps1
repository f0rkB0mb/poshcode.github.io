#The PowerShell Talk
#Demo 2 - VM Easy Bake Oven
#VMware

#Connect to vCenter
Get-Credential | connect-viserver -Server "Your vCenter Here"

#Create the new VM
get-vmhost -Name "ESX Server" | New-VM -Name Dave -DiskMB "10240" -GuestId "otherGuest" -MemoryMB 512 -NumCpu 1 -resourcepool "Demo" 

#Get some info on said VM
get-resourcepool "Demo" | Get-VM | fl *

#Change the Memory
Get-VM -Name "Dave" | Set-VM -MemoryMB 1024 -confirm:$false
#And the Network
Get-VM -Name "Dave" | New-NetworkAdapter -NetworkName "Demo" -StartConnected:$true -confirm:$false

#Delete the VM
Get-VM -Name "Dave" | Remove-Vm -Confirm:$false
