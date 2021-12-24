<?php
/*******************************************************************************
*  Title: PHP hit counter (PHPcount)  *  Author: Klemen Stirn phpjunkyard.com  *
*******************************************************************************/
// Count unique visitors? 1 = YES, 0 = NO
$count_unique = 1;
// Number of hours a visitor is considered as "unique"
$unique_hours = 6;
// Minimum number of digits shown (zero-padding). Set to 0 to disable.
$min_digits = 0;
// Thousands separator; 1,999,999 or 1.999.999 or 1 999 999 or just 1999999
$thousands_separator = ',';
////////////////////////////////////////////////////////////////////////////////
// DO NOT EDIT BELOW
////////////////////////////////////////////////////////////////////////////////

// Turn error notices off
error_reporting(E_ALL ^ E_NOTICE);

// Set the correct MIME type
header("Content-type: text/javascript");

// Tell browsers not to cache the file output so we can count all hits
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Is page ID set?
if ( ! isset($_GET['page']) )
{
	die('ERROR: Call with <b>?page=PAGEID</b> eg: <b>counter.php?page=test</b>');
}

// Remove any illegal chars from the page ID
$page = preg_replace('/[^a-zA-Z0-9\-_\.]/', '', $_GET['page']);

// Stop if $page is not valid
if ( strlen($page) == 0 )
{
	die('ERROR: Page ID is missing or invalid');
}

// Set values for cookie and log file names
$cname   = 'tcount_unique_'.$page;
$logfile = $page;

// Does the log file exist?
if ( ! file_exists($logfile) )
{
	die('ERROR: Log file not found.  File names might be CaSe SeNSiTiVe!');
}

// Open log file for reading and writing
if ($fp = @fopen($logfile, 'r+'))
{
	// Lock log file from other scripts
	$locked = flock($fp, LOCK_EX);

	// Lock successful?
	if ($locked)
	{
		// Let's read current count
		$count = intval( trim( fread($fp, filesize($logfile) ) ) );

		// If counting unique hits is enabled make sure it's a unique hit
		if ( $count_unique == 0 || ! isset($_COOKIE[$cname]) )
		{
			// Update count by 1 and write the new value to the log file
			$count = $count + 1;
			rewind($fp);
			fwrite($fp, $count);

			// Print the Cookie and P3P compact privacy policy
			header('P3P: CP="NOI NID"');
			setcookie($cname, 1, time()+60*60*$unique_hours);
		}
	}
	else
	{
		// Lock not successful. Better to ignore than to damage the log file
		$count = 1;
	}

	// Release file lock and close file handle
	flock($fp, LOCK_UN);
	fclose($fp);
}
else
{
	die("ERROR: <b>Not writable.</b> PHP needs permission to write to file $logfile");
}

// Is zero-padding enabled? If yes, add zeros if required
if ($min_digits)
{
	$count = sprintf('%0'.$min_digits.'s', $count);
}

// Format thousands?
if ( strlen($thousands_separator) )
{
	$count = number_format($count, 0, '', $thousands_separator);
}

// Print out Javascript code and exit
echo("document.write('{$count}');");
exit();
