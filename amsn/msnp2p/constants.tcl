namespace eval ::p2p {

	variable MAX_INT32 2147483647
	variable MAX_INT16 32767

	proc generate_uuid { } {

		#  package require uuid
		#
		#  set uuid [::uuid::generate]
		#  binary scan $uuid  H2H2H2H2H2H2H2H2H4H* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
		#  set uuid [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]
		#  return $uuid
		set uuid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		return $uuid

	}

	proc myRand { min max } {

		return [expr {int($min + rand() * (1+$max-$min))}]

	}

	proc generate_id { {max 2147483647} } {

		set min 1000
		return [myRand $min $max]

	}

}

namespace eval ::p2p::Codec {
	set ML20 ML20
}

namespace eval ::p2p::EufGuid {

	set MSN_OBJECT {A4268EEC-FEC5-49E5-95C3-F126696BDBF6}
	set FILE_TRANSFER {5D3E02AB-6190-11D3-BBBB-00C04F795683}
	set MEDIA_RECEIVE_ONLY {1C9AA97E-9C05-4583-A3BD-908A196F1E92}
	set MEDIA_SESSION {4BD96FC0-AB17-4425-A14A-439185962DC8}
	set SHARE_PHOTO {41D3E74E-04A2-4B37-96F8-08ACDB610874}
	set ACTIVITY {6A13AF9C-5308-4F35-923A-67E8DDA40C2F}


}

namespace eval ::p2p::PeerInfo {
	set PROTOCOL_VERSION 512
	set IMPLEMENTATION_ID 0
	set VERSION 3584
	set CAPABILITIES 271
}

namespace eval ::p2p::SLPContentType {
	set SESSION_REQUEST application/x-msnmsgr-sessionreqbody
	set SESSION_FAILURE application/x-msnmsgr-session-failure-respbody
	set SESSION_CLOSE application/x-msnmsgr-sessionclosebody
	set TRANSFER_REQUEST application/x-msnmsgr-transreqbody
	set TRANSFER_RESPONSE application/x-msnmsgr-transrespbody
	set TRANS_UDP_SWITCH application/x-msnmsgr-transudpswitch
	set NULL null
}

namespace eval ::p2p::SLPRequestMethod {
	set INVITE INVITE
	set BYE BYE
	set ACK ACK
}

namespace eval ::p2p::SLPStatus {
	set ACCEPTED 200
	set ERROR 500
	set DECLINED 603
}

namespace eval ::p2p::MSNObjectType {
	set CUSTOM_EMOTICON 2
	set DISPLAY_PICTURE 3
	set BACKGROUND_PICTURE 5
	set DYNAMIC_DISPLAY_PICTURE 7
	set WINK 8
	set VOICE_CLIP 11
	set SAVED_STATE_PROPERTY 12
	set LOCATION 14

}

namespace eval ::p2p::ApplicationID {
	set WINK_TRANSFER 1
	set VOICE_CLIP_TRANSFER 1
	set FILE_TRANSFER 2
	set CUSTOM_EMOTICON_TRANSFER 11
	set DISPLAY_PICTURE_TRANSFER 12
	set WEBCAM 4

}
