(* 
https://www.surfshopcart.com/info/scripts/applescript-mail-el-capitan.php

PURPOSE:
   Checks individual Apple Mail accounts at different intervals that you determine.
	
INSTRUCTIONS:
   Set Mail's preferences to "Check for new mail: Manually".
   Append the time interval, in seconds, to your Mail accounts names, e.g. personal/15
   Save this script as an Application and select the Stay Open option.
*)

global the_minute_count, the_minimum_interval, the_accounts_list, first_run, new_accounts_list, script_name
global accounts_file, log_file, the_time, big_number

set the_minimum_interval to 1
set the_minute_count to 0
set first_run to "Yes"

----------------------------------------------------------------
-- Get the name of the script to dim the icon in the dock.
----------------------------------------------------------------
set script_path to path to me

-- Get full name of this script.
tell application "Finder"
	set script_name_full to name of script_path
	set the_ext to name extension of script_path
	
	-- Get the name of this script, minus the extension.
	if the_ext is not "" then
		set script_name to text items 1 thru ((offset of "." in script_name_full) - 1) of script_name_full as string
	else
		set script_name to script_name_full
	end if
	
	-- Dim this script's icon in the Dock
	delay 1
	set visible of process script_name to false
end tell

set log_file to "/Applications/" & script_name_full & "/Contents/Resources/Scripts/log.txt" as POSIX file

my Write_To_Log("script_name_full is \"" & script_name_full & "\"", log_file, true)
my Write_To_Log("the_ext is \"" & the_ext & "\"", log_file, true)
my Write_To_Log("script_name is \"" & script_name & "\"\n", log_file, true)

----------------------------------------------------------------
-- Create "the_accounts_list" from the accounts.data file.
----------------------------------------------------------------
set accounts_file to "/Applications/" & script_name_full & "/Contents/Resources/Scripts/accounts.data" as POSIX file
my Read_Accounts_List(accounts_file)
if the_accounts_list = "" then
	-- The_accounts_list will be empty the very first time this script is run.
	Update_eAccounts()
end if
---------------------------------------------

on idle
	if App_Is_Running("Mail") then
		if first_run = "Yes" then
			my Write_To_Log("-- First Run :: " & (current date), log_file, true)
			tell application "Mail"
				activate
				check for new mail
				my Get_Accounts(the_accounts_list)
			end tell
			set first_run to "No"
		end if
		set the_minute_count to the_minute_count + the_minimum_interval
		
		tell application "Mail"
			repeat with each_account in the_accounts_list
				set the_interval to rich text ((offset of "/" in each_account) + 1) thru -1 of each_account
				if the_interval ≠ 0 then
					set theMod to the_minute_count mod the_interval
					if (theMod = 0) then
						set the_dots to (big_number) - (length of each_account) + 2
						try
							check for new mail for account each_account
							my Write_To_Log(each_account & " " & my n_reps(".", the_dots) & " checked at " & my Get_Time(), log_file, true)
						on error
							my Write_To_Log("*** error on account " & each_account & " at " & my Get_Time(), log_file, true)
							my Update_eAccounts()
							delay 0.5
							my Read_Accounts_List(accounts_file)
						end try
					end if
				end if
			end repeat
		end tell
		return (the_minimum_interval * 60)
	else
		return 60
	end if
end idle

on Read_Accounts_List(accounts_file)
	-- File contains Mail account names - 1 per line.
	tell application "Finder"
		if exists accounts_file then
			set the_accounts_list to read alias accounts_file using delimiter linefeed as «class utf8»
		else
			do shell script "touch \"" & accounts_file & "\""
		end if
	end tell
end Read_Accounts_List


on Get_Accounts(the_accounts_list)
	set the_minimum_interval to 0
	set the_count to 0
	set big_number to {}
	
	tell application "Mail"
		repeat with each_account in the_accounts_list
			set name_length to length of each_account
			set big_number to big_number & name_length
			-- Grab the number after the slash.
			set the_interval to rich text ((offset of "/" in each_account) + 1) thru -1 of each_account
			if the_interval > 0 then
				set the_count to the_count + 1
				if (the_count > 1) then
					set the_minimum_interval to my GCD(the_interval, the_minimum_interval)
				else
					set the_minimum_interval to (the_interval as integer)
				end if
			end if
		end repeat
	end tell
	set big_number to my Highest_Number(big_number)
	my Write_To_Log("\"Get_Accounts\" was run.", log_file, true)
	
	if the_minimum_interval = 0 then
		--display dialog "No accounts have been set to check (values must be greater than 0)."
		--return
		-- Create the accounts list if it doesn't already exist.
		(* Is there a better way to check this than by "the_minimum_interval"? *)
		Update_eAccounts()
	end if
end Get_Accounts

on Update_eAccounts()
	-- Get account names from Mail and create a list.
	-- The time frequency is grabbed from the digits after the "/" in the account name.
	-- This function is called only when an email account name is changed in Mail.
	set new_accounts_list to ""
	set the_cnt to 0
	tell application "Mail"
		set the_account_count to count of accounts
		repeat with each_account in accounts
			set the_cnt to the_cnt + 1
			set the_account_name to name of each_account as string
			if the_account_name contains "/" then
				set the_interval to rich text ((offset of "/" in the_account_name) + 1) thru -1 of the_account_name
				if the_interval > 0 then
					if the_cnt = the_account_count then
						-- Don't add a newline to the last line.
						set new_accounts_list to new_accounts_list & the_account_name
					else
						set new_accounts_list to new_accounts_list & the_account_name & "\n"
					end if
				end if
			end if
		end repeat
	end tell
	
	set the data_file to open for access file accounts_file with write permission
	write new_accounts_list to data_file
	close access data_file
	my Write_To_Log("\"Update_eAccounts\" was run.", log_file, true)
end Update_eAccounts

on Get_Time()
	set the_time to time string of (current date)
end Get_Time

on Write_To_Log(this_data, target_file, append_data)
	tell application "Finder"
		if not (exists target_file) then
			do shell script "touch \"" & target_file & "\""
		end if
	end tell
	try
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data & "\n" to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end Write_To_Log

on GCD(a, b) --  Greatest Common Divisor**
	repeat until b = 0
		set x to b
		set b to a mod b
		set a to x
	end repeat
	return a
end GCD

on Highest_Number(values_list)
	set the high_amount to ""
	repeat with i from 1 to the count of the values_list
		set this_item to item i of the values_list
		set the item_class to the class of this_item
		if the item_class is in {integer, real} then
			if the high_amount is "" then
				set the high_amount to this_item
			else if this_item is greater than the high_amount then
				set the high_amount to item i of the values_list
			end if
		else if the item_class is list then
			set the high_value to Highest_Number(this_item)
			if the the high_value is greater than the high_amount then ¬
				set the high_amount to the high_value
		end if
	end repeat
	return the high_amount
end Highest_Number

-- Repeat a character "x" times.
on n_reps(s, n)
	set o to ""
	if n < 1 then return o
	
	repeat while (n > 1)
		if (n mod 2) > 0 then set o to o & s
		set n to (n div 2)
		set s to (s & s)
	end repeat
	return o & s
end n_reps


on quit
	-- Empty the log file when quitting so it doesn't continue to grow.
	set your_filename to open for access file log_file with write permission
	set eof your_filename to 0
	continue quit
end quit


on App_Is_Running(app_name)
	tell application "System Events" to (name of processes) contains app_name
end App_Is_Running

