. .lib\slack.ps1

cls

$server 		= "localhost"
$user 			= "root"
$password 		= ""
$backupFolder	= "C:\xampp\htdocs\seele.com\site\_backups"
$dbName 		= "seele_new"
$MySQLDumpPath 	= "C:\xampp\mysql\bin\mysqldump.exe"
$limit 			= (Get-Date).AddDays(-7) # file rentention period.

#---	Format timestamp for the filename
$timestamp	= Get-Date -format yyyyMMdd-HHmmss
#Write-Host $timestamp

write-host "Backing up database: " $dbName

#---	Set backup filename
$filename 	= $timestamp + "_" + $dbName + ".sql"
$fullPath 	= $backupFolder + "" + $filename


#---	Invoke backup Command.
 cmd /c " `"$MySQLDumpPath`" -h $server -u $user $dbname > $fullPath "
 If (test-path($fullPath))
 {
 write-host "Backup created."
 }


#---	Check if 7z is present. Alias for 7-zip.  May need to change path below.
if (-not (test-path "C:\Program Files\7-Zip\7z.exe")) {throw "C:\Program Files\7-Zip\7z.exe required"}
set-alias sz "C:\Program Files\7-Zip\7z.exe"

$zipfile 	= $backupFolder + $timestamp + "_" + $dbName + '.zip'
$from 		= $fullPath
# write-host "from:" $from
# write-host "to  :" $zipfile
# $cmd		="sz a -tzip $zipfile $from"
# write-host $cmd

sz a -tzip $zipfile $from

remove-item "$from"

#-- send to FTP
write-host "My file" + $zipfile

#---	Delete Files
Get-ChildItem -Path $backupFolder -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force



#we specify the directory where all files that we want to upload
$Dir=$zipfile

#ftp server
$ftp = "ftp://seele.mikolajewski.ch/"
$user = "seele_backuper"
$pass = "w1jk8139"

$webclient = New-Object System.Net.WebClient

$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)

#list every sql server trace file
foreach($item in (dir $Dir "*.trc")){
    "Uploading $item..."
    $uri = New-Object System.Uri($ftp+$item.Name)
    $webclient.UploadFile($uri, $item.FullName)
 }

 # Important Message!
$test = 'Important Message 12345'

# Post the message to Slack
$channel = '#powershell-backups'
$message = "New DB backup!`r`n$Dir"
$botname = 'Database Backuper'
$result = Post-ToSlack -Channel $channel -Message $message -BotName $botname

# Validate the results
if ($result.ok)
{
 Write-Host -Object 'Success! The important message was sent!'
}
else
{
 Write-Host -Object 'It failed! Abort the mission!'
}