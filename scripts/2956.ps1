# Copyright (c) 2011, Chris Cmolik <chris@chriscmolik.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# software, even if advised of the possibility of such damage


# get-old-outlook-events.ps1
# powershell script to retrieve all appointments that haven't been modified in the past three months using the outlook object model
param ( [datetime] $rangestart = [datetime]::now.addmonths(-3)
		, [datetime] $rangeend   = [datetime]::now)

$outlook = new-object -comobject outlook.application
#dictionary to hold users and their events
$dict =@{}
# labeling report
"running report for {0}..." -f [environment]::username

# needed because `n makes too much sense...


# ensure we are logged into a session
	$session = $outlook.session
$session.logon()

# folder for events in outlook = 9
	$apptitems = $session.getdefaultfolder(9).items
	$apptItems.Sort("[Start]")
#$apptItems.IncludeRecurrences = $true
	$restriction = "[End] >= '{0}' AND [Start] <= '{1}' AND [IsRecurring] = TRUE" -f $rangeStart.ToString("g"), $rangeEnd.ToString("g")

foreach($appt in $apptItems.Restrict($restriction))
{ 
	if ($appt.GetRecurrencePattern().PatternEndDate -gt $rangeEnd -and $appt.GetRecurrencePattern().PatternStartDate -lt $rangeStart ) 
	{
		$payload = ""
			$payload += "Event title: {0}`n" -f $appt.Subject

			$payload += "Event's recurring began on: {0:MM/dd/yy}`n" -f [DateTime]$appt.GetRecurrencePattern().PatternStartDate
# Get recurrence pattern
			$recPattern = $appt.GetRecurrencePattern()
			switch($recPattern.RecurrenceType)
			{
				0 { "Recurs Daily." }
				1 {
					if($recPattern.interval -eq 1)
					{
						switch($recPattern.DayOfWeekMask)
						{
							1 {
								$payload += "Occurs every Sunday.`n"
							}
							2 {
								$payload += "Occurs every Monday.`n"
							}
							4 {
								$payload += "Occurs every Tuesday.`n"
							}
							8 { 
								$payload += "Occurs every Wednesday.`n"
							}
							16 {
								$payload += "Occurs every Thursday.`n"
							}
							32 {
								$payload += "Occurs every Friday.`n"
							}
							64 {
								$payload += "Occurs every Saturday.`n"
							}
						}
					}
					else
					{
						switch($recPattern.DayOfWeekMask){
							1 {
								$payload += "Occurs every {0} weeks on Sunday.`n" -f $recPattern.interval
							}
							2 {
								$payload += "Occurs every {0} weeks on Monday.`n" -f $recPattern.interval
							}
							4 {
								$payload += "Occurs every {0} weeks on Tuesday.`n" -f $recPattern.interval
							}
							8 { 
								$payload +="Occurs every {0} weeks on Wednesday.`n" -f $recPattern.interval
							}
							16 {
								$payload +="Occurs every {0} weeks on Thursday.`n" -f $recPattern.interval
							}
							32 {
								$payload +="Occurs every {0} weeks on Friday.`n" -f $recPattern.interval
							}
							64 {
								$payload +="Occurs every {0} weeks on Saturday.`n" -f $recPattern.interval
							}
						}
					}

				}
				2 {
					switch($recPattern.Instance){
						1 { $instance = "first" }
						2 { $instance = "second" }
						3 { $instance = "third" }
						4 { $instance = "fourth" }
						5 { $instance = "fifth" }
						6 { $instance = "sixth" }


					}
					switch($recPattern.DayOfWeekMask) 
					{
						1 { $strDay = "Sunday" }
						2 { $strDay = "Monday" }
						4 { $strDay = "Tuesday" }
						8 { $strDay = "Wednesday" }
						16 { $strDay = "Thursday" }
						32 { $strDay = "Friday" }
						64 { $strDay = "Saturday" }

					}
					$int = $recPattern.Interval
						if ($int -eq 1) 
						{
							$payload += "Occurs on the {0} {1} of each month.`n" -f $instance, $strDay
						}
						else 
						{
							$payload +="Occurs on the {0} {1} every {2} months`n" -f $instance, $strDay, $int
						}	
				}
				3 {	
					if($recPattern.interval -eq 1) {
						$payload +="Recurs each month`n"
					}
					else {
						$payload +="Recurs every {0} month`n" -f $recPattern.interval
					}

					switch($recPattern.Instance){
						1 { $instance = "first" }
						2 { $instance = "second" }
						3 { $instance = "third" }
						4 { $instance = "fourth" }
						5 { $instance = "fifth" }
						6 { $instance = "sixth" }


					}
					switch($recPattern.DayOfWeekMask) 
					{
						1 { $strDay = "Sunday" }
						2 { $strDay = "Monday" }
						4 { $strDay = "Tuesday" }
						8 { $strDay = "Wednesday" }
						16 { $strDay = "Thursday" }
						32 { $strDay = "Friday" }
						64 { $strDay = "Saturday" }

					}
					$payload +="Occurs on the {0} {1} of the month `n" -f $instance, $strDay
				}
				5 { 
					$a = new-object system.globalization.datetimeformatinfo
						$month = $a.MonthNames[$recPattern.MonthOfYear+1]
						$payload += "Occurs each year on {0} {1}`n" -f $month, $recPattern.DayofMonth
				}
				6 {

					switch($recPattern.Instance){
						1 { $instance = "first" }
						2 { $instance = "second" }
						3 { $instance = "third" }
						4 { $instance = "fourth" }
						5 { $instance = "fifth" }
						6 { $instance = "sixth" }


					}
					switch($recPattern.DayOfWeekMask) 
					{
						1 { $strDay = "Sunday" }
						2 { $strDay = "Monday" }
						4 { $strDay = "Tuesday" }
						8 { $strDay = "Wednesday" }
						16 { $strDay = "Thursday" }
						32 { $strDay = "Friday" }
						64 { $strDay = "Saturday" }

					}	
					$a = new-object system.globalization.datetimeformatinfo
						$month = $a.MonthNames[$recPattern.MonthOfYear+1]
						$payload +="Occurs on the {0} {1} of {2} each year`n" -f $recPattern.Instance, $strDay, $month			



				}

			}
		$payload += "From: {0:hh:mm tt} - {1:hh:mm tt}`n" -f [DateTime]$recPattern.StartTime, [DateTime]$recPattern.EndTime
			if ($dict.ContainsValue($appt.Organizer)) {

				$dict.Set_Item($appt.Organizer, ($dict[$appt.Organizer] += $payload))
			}
			else {
				$dict.Set_Item($appt.Organizer, $payload)
			}

	}
}

$outlook = $session = $null;
foreach ($e in $dict.GetEnumerator()) {
	"Person: {0}`n" -f $e.Name 
		"Events:`n{0}" -f $e.Value
		"--------------------------`n`n" 
}
"End report for {0}`n----------------------" -f[Environment]::UserName 
