#!/usr/bin/perl
# Perlscript to complete AMSN language files 
# by Patrick Kuijvenhoven <spantie_pet@users.sourceforge.net>

my $backupdir 	= "/tmp";
my $diff 		= "diff";

# These are standard on most distributions.
use File::Copy;
use File::Basename;

sub usage {
	print STDERR "Usage: $0 <english langfile location> <your langfile location>\n";
	exit 1;
	}

sub langfiletohash {
	$filename = shift;
	undef $hash;
	open(FILEHANDLE, $filename) or die("Could not open languagefile \"$filename\": $!");
	while(<FILEHANDLE>) {
	 if (/^(.*?){1} (.*?)$/) {
	   $hash->{$1} = $2;
	   }
	 }
	close(FILEHANDLE);
	return $hash;
	}

if($#ARGV < 1) {
 usage();
 }

$f_english = $ARGV[0];
$f_other   = $ARGV[1];
if($ARGV[2] && -d $ARGV[2]) { 
	$backupdir = $ARGV[2];
	}

$f_other_new = $backupdir."/".basename($f_other);
$f_other_old = $backupdir."/".basename($f_other).".old";
$f_other_diff= $backupdir."/".basename($f_other).".diff";

copy($f_other,$f_other_old) or die("[!] Failed to create backupfile $f_other_old: $!\n");

$english = langfiletohash($f_english);
$other   = langfiletohash($f_other);

foreach $key (sort keys %$english) {
	if(! $other->{$key} || $other->{$key} eq "") {
		print "[E] ".$key.": ".$english->{$key}."\n";
		print "[?] ".$key.": ";
		undef $answer; do { $char = getc(STDIN); $answer .= $char } while ($char ne "\n"); chomp($answer);
		if($answer ne "") { 
			$other->{$key} = $answer; 
			} 
		print "\n";
		$i++;
	}
}

if($i == 0) { 
	print "[i] No missing keys :)\n";
	exit;
	}

open(NEWLANGFILE, "> $f_other_new");
print NEWLANGFILE "amsn_lang_version ".$other->{"amsn_lang_version"}."\n";
foreach $key (sort keys %$other) {
	if($key ne "amsn_lang_version") {
		print NEWLANGFILE $key." ".$other->{$key}."\n";
		}
	}
close(NEWLANGFILE);

$cmd = "$diff -u $f_other_old $f_other_new > $f_other_diff";
system($cmd);

print qq {
If you like $f_other_diff, just move $f_other_new to
$f_other.

To help the amsn project, please send your $f_other_diff 
to alberto\@udlaspalmas.net

Or, if you are subscribed to the amsn-lang list: 
amsn-lang\@lists.sourceforge.net

};

exit 0;
