#!/usr/bin/perl -w

###
###
### This program is free software; you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation; version 2 of the License
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program; if not, write to the Free Software
### Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###
###
### amsnctl.pl
### amsn remote control
###
### just another way to control amsn 
### you can use this program in your scripts in an easier way 
### than using amsn-remote-CLI
###
### written by David Muñoz ( voise at tiscali.es )
###
###

### ./amsnctl.pl [stuff] 
###
### [stuff] are:
###
###   --cmd    [cmd]  : amsn remote command   (mandatory)
###   --login  [user] : session login         (mandatory)
###   --passwd [pass] : amsn server password  (mandatory)
###   --host   [IP]   : ip, default 127.0.0.1 
###   --port   [port] : port, default 63251   
###
###
### Example (notice the use of " and \" in command)
###
### ./amsnctl.pl --login me@hotmail.com --passwd mypasswd --cmd "setnick \"me - programming in perl\""
###

###
### IMPORTANT:
###
###   you MUST install Perl-HMAC package
### 

use Digest::HMAC_MD5;  
use IO::Socket;        
use Getopt::Long;      

### do you think i like commenting code? 

GetOptions("host=s" => \$host,
	   "port=s" => \$port,
	   "login=s" => \$acc,
	   "passwd=s" => \$pass,
	   "cmd=s" => \$cmd);

if (!defined($host)) {
    $host = '127.0.0.1';
}

if (!defined($port)) {
    $port = '63251';
}

if (!defined($acc)) {
    die "You must scpecify a login name\n";
}

if (!defined($pass)) {
    die "You must specify a password\n";
}

if (!defined($cmd)) {
    die "You must specify a command\n";
}

my $sock = new IO::Socket::INET (
                                 PeerAddr => $host,
                                 PeerPort => $port,
                                 Proto => 'tcp',
                                );

die "Amsn server closed?\n" unless $sock;

$sock->autoflush(1);
print $sock "$acc\n";

$_ = <$sock>;
chomp($_);
s/\r//;
$port2 = $_;
close($sock);

my $sock2 = new IO::Socket::INET (
                                 PeerAddr => $host,
                                 PeerPort => $port2,
                                 Proto => 'tcp',
                                );
die "Amsn server closed?\n" unless $sock;

$sock2->autoflush(1);
print $sock2 "auth\n";

$_ = <$sock2>;
s/(\d+\.\d+)//;
$reto = $1;
$hmac = Digest::HMAC_MD5->new($reto);
$hmac->add($pass);
$digest = $hmac->hexdigest;

print $sock2 "auth2 $digest\n";
$_= <$sock2>;

print $sock2 $cmd."\n";
print $sock2 "quit\n";
$_=<$sock2>;
print;
close $sock2;

