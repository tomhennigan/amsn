#	User Administration (Address Book data)
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
namespace eval ::abook {
   namespace export setGroup getGroup setContact

   #
   # P R I V A T E
   #
   variable contacts;	# Array for contacts
   			# contacts(email) {		   BPR*
			#       groupId			   LST
			#	phone { home work mobile } BPR.PHH/PHW/PHM
			#	mobile			   BPR.MOB
			# }
   variable groups;	# Array for groups
   			# groups(id) { name }		   LSG
   variable groupCnt 0

   #
   # P R O T E C T E D
   #

   #
   # P U B L I C
   #
   proc setGroup { nr name } {	# LSG <x> <trid> <cnt> <total> <nr> <name> 0
       variable groups
       variable groupCnt

       set groups($nr) $name
       incr groupCnt
#       puts "ABOOK: added group $nr ($name)"
   }
   
   proc getGroup {nr} {
       variable groupCnt
       variable groups

       if { $nr > $groupCnt } { return "" }
       else { return $groups($nr) }
   }

   proc setContact { email field value } {
   	variable contacts

	# Phone numbers are countryCode%20areaCode%20subscriberNumber
        switch $field {
	    FL {	;# From LST.FL command, contains email, groupId
		set contacts($email) [list  $value "" "" "" "" ]
#		puts "ABOOK: creating $email GroupId $value"
#		puts "size [llength $contacts($email)]"
	    }
	    PHH {	;# From BPR.PHH (Home Phone Number)
		set contacts($email) [lreplace $contacts($email) 1 1 $value]
#		puts "ABOOK: $email Home $value"
	    }
	    PHW {	;# From BPR.PHW (Work Phone Number)
		set contacts($email) [lreplace $contacts($email) 2 2 $value]
#		puts "ABOOK: $email Work $value"
	    }
	    PHM {	;# From BPR.PHM (Mobile Phone Number)
		set contacts($email) [lreplace $contacts($email) 3 3 $value]
#		puts "ABOOK: $email Mobile $value"
	    }
	    MOB {	;# From BPR.MOB (Mobile settings) Y|N
		set contacts($email) [lreplace $contacts($email) 4 4 $value]
#		puts "ABOOK: $email MobileSet $value"
	    }
	    default {
	        puts "setContact unknown field $field -> $value"
	    }
	}
   }
}
# $Log$
# Revision 1.2  2002/06/17 00:10:53  lordofscripts
# *** empty log message ***
#
# Revision 1.1  2002/06/17 00:01:57  lordofscripts
# Handles Address Book containing data about users in the forward list
#
