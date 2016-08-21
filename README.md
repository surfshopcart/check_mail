# check_mail
AppleScript to individually check email accounts in Mail.app

This is a self-contained script.  All you have to do is rename your Mail accounts by appending a "/XX" (without the quotes) to every account name (The "XX" in this example is the number, in minutes, that you want to check an account).  If you do not want a particular account checked by this script, simply append "/0" to it's name, or append nothing at all.  If the script doesn't find a slash in the name, it will skip it.  You can still check the account manually from within Mail.

The first time this script is run, it will create an accounts.data file with the names of all your Mail accounts that end in "/XX".  If you happen to change an account name after the first run, it will sense the change and update the data file on-the-fly.  There's no need to restart Mail or this script after a change.  Nice!

This script produces a log file with everything lined up nice and neat.  It also logs any errors.  The log is reset at every run to keep it from growing over time.

To use this script, simply save it as an Application with Script Editor and select "Stay open after run handler".  Leave "Show startup screen" unchecked.  You can name it anything you like.  Both the data and log files will be saved inside the application bundle so you don't have to keep track of where everything is located.  To view them, simply click on the app's icon in the Finder, select "Show Package Contents", then navigate to Contents > Resources > Scripts.

This was done as a personal project, but I felt others might get some use out of it as well.  Any ideas on how to make this better would be greatly appreciated.
