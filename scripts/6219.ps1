Ipmo 'C:\Program Files\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1'

function Get-EC2RunningInstancesConsoleOutput ($AccessKey, $SecretKey)
{
    #create filter to query for running instances only
    $RunningFilter = new-object Amazon.EC2.Model.Filter
    $RunningFilter.Name = 'instance-state-name'
    $RunningFilter.Value = 'running'
    #Get the instances IDs
    $instances = Get-EC2Instance -accesskey $accessKey -secretkey $secretkey -Filter $RunningFilter
    $RunningInstanceID = $instances.Instances.instanceID
    #Get console output
    foreach ($instanceID in $RunningInstanceID)
        {
        $ConsoleOut = Get-EC2ConsoleOutput -AccessKey $accessKey -secretkey $secretKey -InstanceID $instanceID
        #decoding base64 encoded output
        $output = [System.Convert]::FromBase64String($ConsoleOut.Output.ToString())
        $output = [System.Text.Encoding]::UTF8.GetString($output)
        #formatting the output objects
        $line = "" | select instanceID, consoleLine
        $output.split([char]10) | % {$line.instanceID = $instanceID;$line.consoleLine=$_;$line}
        }
}
