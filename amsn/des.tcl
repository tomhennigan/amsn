# des.tcl
# Port of Javascript implementation to Tcl 8.4 by Mac A. Cody,
# October 2002 - February 2003
#
# Paul Tero, July 2001
# http://www.shopable.co.uk/des.html
#
# Optimized for performance with large blocks by Michael Hayworth, November 2001
# http://www.netdealing.com
#
# This software is copyrighted (c) 2003 by Mac A. Cody.  All rights
# reserved.  The following terms apply to all files associated with
# the software unless explicitly disclaimed in individual files or
# directories.

# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software for any purpose, provided that existing
# copyright notices are retained in all copies and that this notice is
# included verbatim in any distributions. No written agreement, license,
# or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors and
# need not follow the licensing terms described here, provided that the
# new terms are clearly indicated on the first page of each file where
# they apply.

# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
# FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
# DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
# IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
# NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.

# GOVERNMENT USE: If you are acquiring this software on behalf of the
# U.S. government, the Government shall have only "Restricted Rights"
# in the software and related documentation as defined in the Federal 
# Acquisition Regulations (FARs) in Clause 52.227.19 (c) (2).  If you
# are acquiring the software on behalf of the Department of Defense, the
# software shall be classified as "Commercial Computer Software" and the
# Government shall have only "Restricted Rights" as defined in Clause
# 252.227-7013 (c) (1) of DFARs.  Notwithstanding the foregoing, the
# authors grant the U.S. Government and others acting in its behalf
# permission to use and distribute the software in accordance with the
# terms specified in this license. 
namespace eval des {
    # Procedure: encrypt - Encryption front-end for the des procedure
    # Inputs:
    #   key     : The 64-bit DES key or the 192-bit 3DES key
    #             (Note: The lsb of each byte is ignored; odd parity
    #             is not required).
    #   message : String to be encrypted (Note: The string is
    #             extended with null characters to an integral
    #             multiple of eight bytes.
    #   mode    : DES mode 1=CBC, 0=ECB (default).
    #   iv      : The input vector used in CBC mode.
    # Output:
    #   The encrypted data string.
    proc encrypt {key message {mode 0} {iv {}}} {
	return [des $key $message 1 $mode $iv]
    }

    # Procedure: decrypt - Decryption front-end for the des procedure
    # Inputs:
    #   key     : The 64-bit DES key or the 192-bit 3DES key
    #             (Note: The lsb of each byte is ignored; odd parity
    #             is not required).
    #   message : String to be decrypted (Note: The string length
    #             must be an integral multiple of eight bytes.
    #   mode    : DES mode 1=CBC, 0=ECB (default).
    #   iv      : The input vector used in CBC mode.
    # Output:
    #   The encrypted or decrypted data string.
    proc decrypt {key message {mode 0} {iv {}}} {
	return [des $key $message 0 $mode $iv]
    }

    if { $initialize_amsn == 1 } {

	variable spfunction1 [list 0x1010400 0 0x10000 0x1010404 0x1010004 0x10404 0x4 0x10000 0x400 0x1010400 0x1010404 0x400 0x1000404 0x1010004 0x1000000 0x4 0x404 0x1000400 0x1000400 0x10400 0x10400 0x1010000 0x1010000 0x1000404 0x10004 0x1000004 0x1000004 0x10004 0 0x404 0x10404 0x1000000 0x10000 0x1010404 0x4 0x1010000 0x1010400 0x1000000 0x1000000 0x400 0x1010004 0x10000 0x10400 0x1000004 0x400 0x4 0x1000404 0x10404 0x1010404 0x10004 0x1010000 0x1000404 0x1000004 0x404 0x10404 0x1010400 0x404 0x1000400 0x1000400 0 0x10004 0x10400 0 0x1010004];
	variable spfunction2 [list 0x80108020 0x80008000 0x8000 0x108020 0x100000 0x20 0x80100020 0x80008020 0x80000020 0x80108020 0x80108000 0x80000000 0x80008000 0x100000 0x20 0x80100020 0x108000 0x100020 0x80008020 0 0x80000000 0x8000 0x108020 0x80100000 0x100020 0x80000020 0 0x108000 0x8020 0x80108000 0x80100000 0x8020 0 0x108020 0x80100020 0x100000 0x80008020 0x80100000 0x80108000 0x8000 0x80100000 0x80008000 0x20 0x80108020 0x108020 0x20 0x8000 0x80000000 0x8020 0x80108000 0x100000 0x80000020 0x100020 0x80008020 0x80000020 0x100020 0x108000 0 0x80008000 0x8020 0x80000000 0x80100020 0x80108020 0x108000];
	variable spfunction3 [list 0x208 0x8020200 0 0x8020008 0x8000200 0 0x20208 0x8000200 0x20008 0x8000008 0x8000008 0x20000 0x8020208 0x20008 0x8020000 0x208 0x8000000 0x8 0x8020200 0x200 0x20200 0x8020000 0x8020008 0x20208 0x8000208 0x20200 0x20000 0x8000208 0x8 0x8020208 0x200 0x8000000 0x8020200 0x8000000 0x20008 0x208 0x20000 0x8020200 0x8000200 0 0x200 0x20008 0x8020208 0x8000200 0x8000008 0x200 0 0x8020008 0x8000208 0x20000 0x8000000 0x8020208 0x8 0x20208 0x20200 0x8000008 0x8020000 0x8000208 0x208 0x8020000 0x20208 0x8 0x8020008 0x20200];
	variable spfunction4 [list 0x802001 0x2081 0x2081 0x80 0x802080 0x800081 0x800001 0x2001 0 0x802000 0x802000 0x802081 0x81 0 0x800080 0x800001 0x1 0x2000 0x800000 0x802001 0x80 0x800000 0x2001 0x2080 0x800081 0x1 0x2080 0x800080 0x2000 0x802080 0x802081 0x81 0x800080 0x800001 0x802000 0x802081 0x81 0 0 0x802000 0x2080 0x800080 0x800081 0x1 0x802001 0x2081 0x2081 0x80 0x802081 0x81 0x1 0x2000 0x800001 0x2001 0x802080 0x800081 0x2001 0x2080 0x800000 0x802001 0x80 0x800000 0x2000 0x802080];
	variable spfunction5 [list 0x100 0x2080100 0x2080000 0x42000100 0x80000 0x100 0x40000000 0x2080000 0x40080100 0x80000 0x2000100 0x40080100 0x42000100 0x42080000 0x80100 0x40000000 0x2000000 0x40080000 0x40080000 0 0x40000100 0x42080100 0x42080100 0x2000100 0x42080000 0x40000100 0 0x42000000 0x2080100 0x2000000 0x42000000 0x80100 0x80000 0x42000100 0x100 0x2000000 0x40000000 0x2080000 0x42000100 0x40080100 0x2000100 0x40000000 0x42080000 0x2080100 0x40080100 0x100 0x2000000 0x42080000 0x42080100 0x80100 0x42000000 0x42080100 0x2080000 0 0x40080000 0x42000000 0x80100 0x2000100 0x40000100 0x80000 0 0x40080000 0x2080100 0x40000100];
	variable spfunction6 [list 0x20000010 0x20400000 0x4000 0x20404010 0x20400000 0x10 0x20404010 0x400000 0x20004000 0x404010 0x400000 0x20000010 0x400010 0x20004000 0x20000000 0x4010 0 0x400010 0x20004010 0x4000 0x404000 0x20004010 0x10 0x20400010 0x20400010 0 0x404010 0x20404000 0x4010 0x404000 0x20404000 0x20000000 0x20004000 0x10 0x20400010 0x404000 0x20404010 0x400000 0x4010 0x20000010 0x400000 0x20004000 0x20000000 0x4010 0x20000010 0x20404010 0x404000 0x20400000 0x404010 0x20404000 0 0x20400010 0x10 0x4000 0x20400000 0x404010 0x4000 0x400010 0x20004010 0 0x20404000 0x20000000 0x400010 0x20004010];
	variable spfunction7 [list 0x200000 0x4200002 0x4000802 0 0x800 0x4000802 0x200802 0x4200800 0x4200802 0x200000 0 0x4000002 0x2 0x4000000 0x4200002 0x802 0x4000800 0x200802 0x200002 0x4000800 0x4000002 0x4200000 0x4200800 0x200002 0x4200000 0x800 0x802 0x4200802 0x200800 0x2 0x4000000 0x200800 0x4000000 0x200800 0x200000 0x4000802 0x4000802 0x4200002 0x4200002 0x2 0x200002 0x4000000 0x4000800 0x200000 0x4200800 0x802 0x200802 0x4200800 0x802 0x4000002 0x4200802 0x4200000 0x200800 0 0x2 0x4200802 0 0x200802 0x4200000 0x800 0x4000002 0x4000800 0x800 0x200002];
	variable spfunction8 [list 0x10001040 0x1000 0x40000 0x10041040 0x10000000 0x10001040 0x40 0x10000000 0x40040 0x10040000 0x10041040 0x41000 0x10041000 0x41040 0x1000 0x40 0x10040000 0x10000040 0x10001000 0x1040 0x41000 0x40040 0x10040040 0x10041000 0x1040 0 0 0x10040040 0x10000040 0x10001000 0x41040 0x40000 0x41040 0x40000 0x10041000 0x1000 0x40 0x10040040 0x1000 0x41040 0x10001000 0x40 0x10000040 0x10040000 0x10040040 0x10000000 0x40000 0x10001040 0 0x10041040 0x40040 0x10000040 0x10040000 0x10001000 0x10001040 0 0x10041040 0x41000 0x41000 0x1040 0x1040 0x40040 0x10000000 0x10041000];

	variable desEncrypt {0 32 2}
	variable desDecrypt {30 -2 -2}
	variable des3Encrypt {0 32 2 62 30 -2 64 96 2}
	variable des3Decrypt {94 62 -2 32 64 2 30 -2 -2}
    }

    # Procedure: des
    # Inputs:
    #   key     : The 64-bit DES key or the 192-bit 3DES key
    #             (Note: The lsb of each byte is ignored; odd parity
    #             is not required).
    #   message : String to be encrypted or decrypted (Note: For
    #             encryption, the string is extended with null
    #             characters to an integral multiple of eight bytes.
    #             For decryption, the string length must be an integral
    #             multiple of eight bytes.
    #   encrypt : Perform encryption (1) or decryption (0)
    #   mode    : DES mode 1=CBC, 0=ECB (default).
    #   iv      : The input vector used in CBC mode.
    # Output:
    #   The encrypted or decrypted data string.
    proc des {key message encrypt {mode 0} {iv {}}} {
	variable spfunction1
	variable spfunction2
	variable spfunction3
	variable spfunction4
	variable spfunction5
	variable spfunction6
	variable spfunction7
	variable spfunction8
	variable desEncrypt
	variable desDecrypt
	variable des3Encrypt
	variable des3Decrypt

	# Create the 16 or 48 subkeys we will need
	set keys [createKeys $key];
	set m 0
	set cbcleft 0x00; set cbcleft2 0x00
	set cbcright 0x00; set cbcright2 0x00
	set len [string length $message];
	set chunk 0;
	# Set up the loops for single and triple des
	set iterations [expr {[llength $keys] == 32 ? 3 : 9}]; # Single or triple des
	if {$iterations == 3} {
	    expr {$encrypt ? [set looping $desEncrypt] : [set looping $desDecrypt]}
	} else {
	    expr {$encrypt ? [set looping $des3Encrypt] : [set looping $des3Decrypt]}
	}

	append message "\0\0\0\0\0\0\0\0"; # Pad the message out with null bytes
	# Store the result here
	set result {};
	set tempresult {};

	# CBC mode
	if {$mode == 1} {
	    binary scan $iv H8H8 cbcleftTemp cbcrightTemp
	    set cbcleft "0x$cbcleftTemp"
	    set cbcright "0x$cbcrightTemp"
	}

	# Loop through each 64 bit chunk of the message
	while {$m < $len} {
	    binary scan $message x${m}H8H8 lefttemp righttemp
	    set left {}
	    append left "0x" $lefttemp
	    set right {}
	    append right "0x" $righttemp
	    incr m 8

	    #puts "Left start: $left";
	    #puts "Right start: $right";
	    # For Cipher Block Chaining mode, xor the message with the previous result
	    if {$mode == 1} {
		if {$encrypt} {
		    set left [expr {$left ^ $cbcleft}]
		    set right [expr {$right ^ $cbcright}]
		} else {
		    set cbcleft2 $cbcleft;
		    set cbcright2 $cbcright;
		    set cbcleft $left;
		    set cbcright $right;
		}
	    }

	    #puts "Left mode: $left";
	    #puts "Right mode: $right";
	    #puts "cbcleft: $cbcleft";
	    #puts "cbcleft2: $cbcleft2";
	    #puts "cbcright: $cbcright";
	    #puts "cbcright2: $cbcright2";

	    # First each 64 but chunk of the message must be permuted according to IP
	    set temp [expr {(($left >> 4) ^ $right) & 0x0f0f0f0f}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 4)}];
	    set temp [expr {(($left >> 16) ^ $right) & 0x0000ffff}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 16)}];
	    set temp [expr {(($right >> 2) ^ $left) & 0x33333333}];
	    set left [expr {$left ^ $temp}]; set right [expr {$right ^ ($temp << 2)}];
	    set temp [expr {(($right >> 8) ^ $left) & 0x00ff00ff}];
	    set left [expr {$left ^ $temp}];
	    set right [expr {$right ^ ($temp << 8)}];
	    set temp [expr {(($left >> 1) ^ $right) & 0x55555555}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 1)}];

	    set left [expr {((($left << 1) & 0xffffffff) | (($left >> 31) & 0x00000001))}]; 
	    set right [expr {((($right << 1) & 0xffffffff) | (($right >> 31) & 0x00000001))}]; 

	    #puts "Left IP: [format %x $left]";
	    #puts "Right IP: [format %x $right]";

	    # Do this either 1 or 3 times for each chunk of the message
	    for {set j 0} {$j < $iterations} {incr j 3} {
		set endloop [lindex $looping [expr {$j + 1}]];
		set loopinc [lindex $looping [expr {$j + 2}]];

		#puts "endloop: $endloop";
		#puts "loopinc: $loopinc";

		# Now go through and perform the encryption or decryption  
		for {set i [lindex $looping $j]} {$i != $endloop} {incr i $loopinc} {
		    # For efficiency
		    set right1 [expr {$right ^ [lindex $keys $i]}]; 
		    set right2 [expr {((($right >> 4) & 0x0fffffff) | \
					   (($right << 28) & 0xffffffff)) ^ [lindex $keys [expr $i + 1]]}];
 
		    # puts "right1: [format %x $right1]";
		    # puts "right2: [format %x $right2]";

		    # The result is attained by passing these bytes through the S selection functions
		    set temp $left;
		    set left $right;
		    set right [expr {$temp ^ ([lindex $spfunction2 [expr ($right1 >> 24) & 0x3f]] | \
						 [lindex $spfunction4 [expr ($right1 >> 16) & 0x3f]] | \
						 [lindex $spfunction6 [expr ($right1 >>  8) & 0x3f]] | \
						 [lindex $spfunction8 [expr $right1 & 0x3f]] | \
						 [lindex $spfunction1 [expr ($right2 >> 24) & 0x3f]] | \
						 [lindex $spfunction3 [expr ($right2 >> 16) & 0x3f]] | \
						 [lindex $spfunction5 [expr ($right2 >>  8) & 0x3f]] | \
						  [lindex $spfunction7 [expr $right2 & 0x3f]])}];
 
		    # puts "Left iter: [format %x $left]";
		    # puts "Right iter: [format %x $right]";

		}
		set temp $left;
		set left $right;
		set right $temp; # Unreverse left and right
	    }; # For either 1 or 3 iterations

	    #puts "Left Iterated: [format %x $left]";
	    #puts "Right Iterated: [format %x $right]";

	    # Move then each one bit to the right
	    set left [expr {((($left >> 1) & 0x7fffffff) | (($left << 31) & 0xffffffff))}]; 
	    set right [expr {((($right >> 1) & 0x7fffffff) | (($right << 31) & 0xffffffff))}]; 

	    #puts "Left shifted: [format %x $left]";
	    #puts "Right shifted: [format %x $right]";

	    # Now perform IP-1, which is IP in the opposite direction
	    set temp [expr {((($left >> 1) & 0x7fffffff) ^ $right) & 0x55555555}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 1)}];
	    set temp [expr {((($right >> 8) & 0x00ffffff) ^ $left) & 0x00ff00ff}];
	    set left [expr {$left ^ $temp}];
	    set right [expr {$right ^ ($temp << 8)}];
	    set temp [expr {((($right >> 2) & 0x3fffffff) ^ $left) & 0x33333333}]; 
	    set left [expr {$left ^ $temp}];
	    set right [expr {$right ^ ($temp << 2)}];
	    set temp [expr {((($left >> 16) & 0x0000ffff) ^ $right) & 0x0000ffff}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 16)}];
	    set temp [expr {((($left >> 4) & 0x0fffffff) ^ $right) & 0x0f0f0f0f}];
	    set right [expr {$right ^ $temp}];
	    set left [expr {$left ^ ($temp << 4)}];

	    #puts "Left IP-1: [format %x $left]";
	    #puts "Right IP-1: [format %x $right]";

	    # For Cipher Block Chaining mode, xor the message with the previous result
	    if {$mode == 1} {
		if {$encrypt} {
		    set cbcleft $left;
		    set cbcright $right;
		} else {
		    set left [expr {$left ^ $cbcleft2}];
		    set right [expr {$right ^ $cbcright2}];
		}
	    }

	    append tempresult [binary format H16 [format %08x%08x $left $right]]

	    #puts "Left final: [format %x $left]";
	    #puts "Right final: [format %x $right]";

	    incr chunk 8;
	    if {$chunk == 512} {
		append result $tempresult
		set tempresult {};
		set chunk 0;
	    }
	}; # For every 8 characters, or 64 bits in the message

	# Return the result as an array
	return ${result}$tempresult
    }; # End of des

    if { $initialize_amsn == 1 } {
 
	variable pc2bytes0 [list 0 0x4 0x20000000 0x20000004 0x10000 0x10004 0x20010000 0x20010004 0x200 0x204 0x20000200 0x20000204 0x10200 0x10204 0x20010200 0x20010204]
	variable pc2bytes1 [list 0 0x1 0x100000 0x100001 0x4000000 0x4000001 0x4100000 0x4100001 0x100 0x101 0x100100 0x100101 0x4000100 0x4000101 0x4100100 0x4100101]
	variable pc2bytes2 [list 0 0x8 0x800 0x808 0x1000000 0x1000008 0x1000800 0x1000808 0 0x8 0x800 0x808 0x1000000 0x1000008 0x1000800 0x1000808]
	variable pc2bytes3 [list 0 0x200000 0x8000000 0x8200000 0x2000 0x202000 0x8002000 0x8202000 0x20000 0x220000 0x8020000 0x8220000 0x22000 0x222000 0x8022000 0x8222000]
	variable pc2bytes4 [list 0 0x40000 0x10 0x40010 0 0x40000 0x10 0x40010 0x1000 0x41000 0x1010 0x41010 0x1000 0x41000 0x1010 0x41010]
	variable pc2bytes5 [list 0 0x400 0x20 0x420 0 0x400 0x20 0x420 0x2000000 0x2000400 0x2000020 0x2000420 0x2000000 0x2000400 0x2000020 0x2000420]
	variable pc2bytes6 [list 0 0x10000000 0x80000 0x10080000 0x2 0x10000002 0x80002 0x10080002 0 0x10000000 0x80000 0x10080000 0x2 0x10000002 0x80002 0x10080002]
	variable pc2bytes7 [list 0 0x10000 0x800 0x10800 0x20000000 0x20010000 0x20000800 0x20010800 0x20000 0x30000 0x20800 0x30800 0x20020000 0x20030000 0x20020800 0x20030800]
	variable pc2bytes8 [list 0 0x40000 0 0x40000 0x2 0x40002 0x2 0x40002 0x2000000 0x2040000 0x2000000 0x2040000 0x2000002 0x2040002 0x2000002 0x2040002]
	variable pc2bytes9 [list 0 0x10000000 0x8 0x10000008 0 0x10000000 0x8 0x10000008 0x400 0x10000400 0x408 0x10000408 0x400 0x10000400 0x408 0x10000408]
	variable pc2bytes10 [list 0 0x20 0 0x20 0x100000 0x100020 0x100000 0x100020 0x2000 0x2020 0x2000 0x2020 0x102000 0x102020 0x102000 0x102020]
	variable pc2bytes11 [list 0 0x1000000 0x200 0x1000200 0x200000 0x1200000 0x200200 0x1200200 0x4000000 0x5000000 0x4000200 0x5000200 0x4200000 0x5200000 0x4200200 0x5200200]
	variable pc2bytes12 [list 0 0x1000 0x8000000 0x8001000 0x80000 0x81000 0x8080000 0x8081000 0x10 0x1010 0x8000010 0x8001010 0x80010 0x81010 0x8080010 0x8081010]
	variable pc2bytes13 [list 0 0x4 0x100 0x104 0 0x4 0x100 0x104 0x1 0x5 0x101 0x105 0x1 0x5 0x101 0x105]

	# Now define the left shifts which need to be done
	variable shifts {0  0  1  1  1  1  1  1  0  1  1  1  1  1  1  0};
    }

    # Procedure: createKeys
    # Input:
    #   key     : The 64-bit DES key or the 192-bit 3DES key
    #             (Note: The lsb of each byte is ignored; odd parity
    #             is not required).
    # Output:
    # The 16 (DES) or 48 (3DES) subkeys.
    proc createKeys {key} {
	variable pc2bytes0
	variable pc2bytes1
	variable pc2bytes2
	variable pc2bytes3
	variable pc2bytes4
	variable pc2bytes5
	variable pc2bytes6
	variable pc2bytes7
	variable pc2bytes8
	variable pc2bytes9
	variable pc2bytes10
	variable pc2bytes11
	variable pc2bytes12
	variable pc2bytes13
	variable shifts

	# How many iterations (1 for des, 3 for triple des)
	set iterations [expr {([string length $key] >= 24) ? 3 : 1}];
	# Stores the return keys
	set keys {}
	# Other variables
	set lefttemp {}; set righttemp {}
	set m 0
	# Either 1 or 3 iterations
	for {set j 0} {$j < $iterations} {incr j} {
	    binary scan $key x${m}H8H8 lefttemp righttemp
	    set left {}
	    append left "0x" $lefttemp
	    set right {}
	    append right "0x" $righttemp
	    incr m 8

	    #puts "Left key: $left"
	    #puts "Right key: $right"

	    set temp [expr {(($left >> 4) ^ $right) & 0x0f0f0f0f}]
	    set right [expr {$right ^ $temp}]
	    set left [expr {$left ^ ($temp << 4)}]
	    set temp [expr {(($right >> 16) ^ $left) & 0x0000ffff}]
	    set left [expr {$left ^ $temp}]
	    set right [expr {$right ^ ($temp << 16)}]
	    set temp [expr {(($left >> 2) ^ $right) & 0x33333333}]
	    set right [expr {$right ^ $temp}]
	    set left [expr {$left ^ ($temp << 2)}]
	    set temp [expr {(($right >> 16) ^ $left) & 0x0000ffff}]
	    set left [expr {$left ^ $temp}]
	    set right [expr {$right ^ ($temp << 16)}]
	    set temp [expr {(($left >> 1) ^ $right) & 0x55555555}]
	    set right [expr {$right ^ $temp}]
	    set left [expr {$left ^ ($temp << 1)}]
	    set temp [expr {(($right >> 8) ^ $left) & 0x00ff00ff}]
	    set left [expr {$left ^ $temp}]
	    set right [expr {$right ^ ($temp << 8)}]
	    set temp [expr (($left >> 1) ^ $right) & 0x55555555]
	    set right [expr $right ^ $temp]
	    set left [expr $left ^ ($temp << 1)]
	    
	    #puts "Left key PC1: [format %x $left]"
	    #puts "Right key PC1: [format %x $right]"

	    # The right side needs to be shifted and to get the last four bits of the left side
	    set temp [expr {($left << 8) | (($right >> 20) & 0x000000f0)}];
	    # Left needs to be put upside down
	    set left [expr {($right << 24) | (($right << 8) & 0x00ff0000) | \
				(($right >> 8) & 0x0000ff00) | (($right >> 24) & 0x000000f0)}];
	    set right $temp;

	    #puts "Left key juggle: [format %x $left]"
	    #puts "Right key juggle: [format %x $right]"

	    # Now go through and perform these shifts on the left and right keys
	    foreach i $shifts  {
		# Shift the keys either one or two bits to the left
		if {$i} {
		    set left [expr {($left << 2) | (($left >> 26) & 0x0000003f)}];
		    set right [expr {($right << 2) | (($right >> 26) & 0x0000003f)}];
		} else {
		    set left [expr {($left << 1) | (($left >> 27) & 0x0000001f)}];
		    set right [expr {($right << 1) | (($right >> 27) & 0x0000001f)}];
		}
		set left [expr {$left & 0xfffffff0}];
		set right [expr {$right & 0xfffffff0}];

		# Now apply PC-2, in such a way that E is easier when encrypting or decrypting
		# this conversion will look like PC-2 except only the last 6 bits of each byte are used
		# rather than 48 consecutive bits and the order of lines will be according to 
		# how the S selection functions will be applied: S2, S4, S6, S8, S1, S3, S5, S7
		set lefttemp [expr {[lindex $pc2bytes0 [expr {($left >> 28) & 0x0000000f}]] | \
					[lindex $pc2bytes1 [expr {($left >> 24) & 0x0000000f}]] | \
					[lindex $pc2bytes2 [expr {($left >> 20) & 0x0000000f}]] | \
					[lindex $pc2bytes3 [expr {($left >> 16) & 0x0000000f}]] | \
					[lindex $pc2bytes4 [expr {($left >> 12) & 0x0000000f}]] | \
					[lindex $pc2bytes5 [expr {($left >> 8) & 0x0000000f}]] | \
					[lindex $pc2bytes6 [expr {($left >> 4) & 0x0000000f}]]}];
		set righttemp [expr {[lindex $pc2bytes7 [expr {($right >> 28) & 0x0000000f}]] | \
					 [lindex $pc2bytes8 [expr {($right >> 24) & 0x0000000f}]] | \
					 [lindex $pc2bytes9 [expr {($right >> 20) & 0x0000000f}]] | \
					 [lindex $pc2bytes10 [expr {($right >> 16) & 0x0000000f}]] | \
					 [lindex $pc2bytes11 [expr {($right >> 12) & 0x0000000f}]] | \
					 [lindex $pc2bytes12 [expr {($right >> 8) & 0x0000000f}]] | \
					 [lindex $pc2bytes13 [expr {($right >> 4) & 0x0000000f}]]}];
		set temp [expr {(($righttemp >> 16) ^ $lefttemp) & 0x0000ffff}];
		lappend keys [expr {$lefttemp ^ $temp}];
		lappend keys [expr {$righttemp ^ ($temp << 16)}];
	    }
	}; # For each iterations
	# Return the keys we've created
	return $keys;
    }; # End of createKeys
}; # End of des namespace eval

package provide tclDES 0.5
