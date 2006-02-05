<?php
if(!defined('_BUGREPORT_CLASS_')) {
  define('_BUGREPORT_CLASS_',1);
  
  class Bugreport {
#information about the bug
    var $_id;
    var $_version;
    var $ip;
    var $bug;
    
#user information
    var $email;
    var $comment;
    
#error variables
    var $date;
    var $text;
    var $stack;
    var $code;
    
#system info
    var $amsn;
    var $cvs_date;
    var $tcl;
    var $tk;
    var $osversion;
    var $byteorder;
    var $threaded;
    var $machine;
    var $platform;
    var $os;
    var $user;
    var $wordsize;
    var $msnprotocol;
    
#extra debug info
    var $status_log;
    var $protocol_log;
    
    function Bug() {
      
    }

    function load_report($report,$isfile=false) {
      $xml=new XML();
      if($isfile) {
	$xml->load_file($report);
      } else {
	$xml->load_text($report);
      }

      $this->_version=$xml->get_content('/bug[1]/attribute::version');
      //set error stuff
      $this->date=html_entity_decode($xml->get_content('/bug[1]/error[1]/date[1]'));
      $this->text=html_entity_decode($xml->get_content('/bug[1]/error[1]/text[1]'));
      $this->stack=html_entity_decode($xml->get_content('/bug[1]/error[1]/stack[1]'));
      $this->code=html_entity_decode($xml->get_content('/bug[1]/error[1]/code[1]'));
      //set system stuff
      $this->amsn=html_entity_decode($xml->get_content('/bug[1]/system[1]/amsn[1]'));
      $this->cvs_date=html_entity_decode($xml->get_content('/bug[1]/system[1]/date[1]'));
      $this->tcl=html_entity_decode($xml->get_content('/bug[1]/system[1]/tcl[1]'));
      $this->tk=html_entity_decode($xml->get_content('/bug[1]/system[1]/tk[1]'));
      $this->osversion=html_entity_decode($xml->get_content('/bug[1]/system[1]/osversion[1]'));
      $this->byteorder=html_entity_decode($xml->get_content('/bug[1]/system[1]/byteorder[1]'));
      $this->threaded=html_entity_decode($xml->get_content('/bug[1]/system[1]/threaded[1]'));
      $this->machine=html_entity_decode($xml->get_content('/bug[1]/system[1]/machine[1]'));
      $this->platform=html_entity_decode($xml->get_content('/bug[1]/system[1]/platform[1]'));
      $this->os=html_entity_decode($xml->get_content('/bug[1]/system[1]/os[1]'));
      $this->user=html_entity_decode($xml->get_content('/bug[1]/system[1]/user[1]'));
      $this->wordsize=html_entity_decode($xml->get_content('/bug[1]/system[1]/wordsize[1]'));
      $this->msnprotocol=html_entity_decode($xml->get_content('/bug[1]/system[1]/msnprotocol[1]'));
      //set extra stuff
      $this->status_log=html_entity_decode($xml->get_content('/bug[1]/extra[1]/status_log[1]'));
      $this->protocol_log=html_entity_decode($xml->get_content('/bug[1]/extra[1]/protocol_log[1]'));
      //set user info
      $this->email=html_entity_decode($xml->get_content('/bug[1]/user[1]/email[1]'));
      $this->comment=trim(html_entity_decode($xml->get_content('/bug[1]/user[1]/comment[1]')));
    }
    
#checks if this is a valid report
#a valid report needs to have
#-stack
#-cvs date
#-tcl/tk version
#-the version has to be bigger than BUG_VERSION
    function check() {
      if($this->stack=="" || $this->cvs_date=="" || $this->tcl=="" || $this->tk=="" || $this->_version<BUG_VERSION) {
	return false;
      }
      return true;
    }
    
    #checks if this bug is potential spam
    # -same bug from the same ip
    function spam($ip='0.0.0.0') {
      $query="SELECT COUNT(*) AS c FROM ".TBUGREPORTS." WHERE bug_ip='".$ip."' AND bug_text='".$this->text."'";
      $r=query($query);
      $row=mysql_fetch_array($r);
      if($row['c']>0) {
	return true;
      }
      return false;
    }
    
#do we support this bug?
# -tcl/tk 8.4 up
    function supported() {
      if($this->tcl<8.4 || $this->tk < 8.4) {
	return false;
      }
      return true;
    }

    function searchForParents() {
      $query="SELECT bug_id,bug_error_regexp,bug_stack_regexp FROM ".TBUGS;
      $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      while($row=mysql_fetch_array($result)) {
	if(ereg($row['bug_error_regexp'],$this->text) && ereg_multi($row['bug_stack_regexp'],$this->stack)) {
	  $this->bug=$row['bug_id'];
	  return $row['bug_id'];
	}
      }
      return 0;
    }
    
    #array getArray (void)
    #returns all the information in a colum2value array to me used when generating queries
    function getArray() {
      $fields=array('bug_date'=>$this->date,
		    'bug_text'=>$this->text,
		    'bug_stack'=>$this->stack,
		    'bug_code'=>$this->code,
		    'bug_amsn'=>$this->amsn,
		    'bug_cvsdate'=>$this->cvs_date,
		    'bug_tcl'=>$this->tcl,
		    'bug_tk'=>$this->tk,
		    'bug_os'=>$this->os, 
		    'bug_osversion'=>$this->osversion,
		    'bug_byteorder'=>$this->byteorder,
		    'bug_threaded'=>$this->threaded,
		    'bug_machine'=>$this->machine, 
		    'bug_platform'=>$this->platform, 
		    'bug_user'=>$this->user, 
		    'bug_wordsize'=>$this->wordsize,
		    'bug_status'=>$this->status_log,
		    'bug_protocol'=>$this->protocol_log,
		    'bug_email'=>$this->email,
		    'bug_comment'=>$this->comment,
		    'bug_parent'=>$this->bug,
		    'bug_msnprotocol'=>$this->msnprotocol);
      return $fields;
    }
  
    function save2db() {
      $fieldsq="`bug_ip`";
      $valuesq="'".$_SERVER['REMOTE_ADDR']."'";

      $array=$this->getArray();
      foreach($array as $key => $value) {
	$fieldsq.=",`".$key."`";
	$valuesq.=",'".mysql_real_escape_string($value)."'";
      }
      
      $query="INSERT INTO ".TBUGREPORTS." (".$fieldsq.") VALUES (".$valuesq.")";
      //echo $query;
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $this->_id=mysql_insert_id();
      
      return $this->_id;
    }

    function update2db() {
      $array=$this->getArray();
      $query="UPDATE ".TBUGREPORTS." SET ";
      foreach($array as $key => $value) {
	$query.=$key."='".addslashes($value)."',";
      }
      #get rid of the trailing ,
      $query=substr($query,0,strlen($query)-1);
      #and finally the clause
      $query.=" WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }
    
    function deletedb() {
      $query="DELETE FROM ".TBUGREPORTS." WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }

    function loaddb($id) {
      $query="SELECT * FROM ".TBUGREPORTS." WHERE bug_id='$id'";
      $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $rows=mysql_num_rows($result);
      if($rows!=1) {
	return false;
      }
      $row=mysql_fetch_array($result);
      $this->_id=$id;
      $this->ip=$row['bug_ip'];

      #set error stuff
      $this->date=$row['bug_date'];
      $this->text=$row['bug_text'];
      $this->stack=$row['bug_stack'];
      $this->code=$row['bug_code'];
      #set system stuff
      $this->amsn=$row['bug_amsn'];
      $this->cvs_date=$row['bug_cvsdate'];
      $this->tcl=$row['bug_tcl'];
      $this->tk=$row['bug_tk'];
      $this->osversion=$row['bug_osversion'];
      $this->byteorder=$row['bug_byteorder'];
      $this->threaded=$row['bug_threaded'];
      $this->machine=$row['bug_machine'];
      $this->platform=$row['bug_platform'];
      $this->os=$row['bug_os'];
      $this->user=$row['bug_user'];
      $this->wordsize=$row['bug_wordsize'];
      $this->msnprotocol=$row['bug_msnprotocol'];
      #set extra stuff
      $this->status_log=$row['bug_status'];
      $this->protocol_log=$row['bug_protocol'];
      #user crap
      $this->email=$row['bug_email'];
      $this->comment=$row['bug_comment'];
      $this->bug=$row['bug_parent'];
    }
    
    function email($title,$msg) {
      $title="[".$this->_id."] ".$title;
      mail($this->email,$title,$msg,"From: ".EMAIL);
    }

    function msg($msg,$redir=false) {
      echo '<div class="center">'.$msg.'</div>';
      if($redir!==false) {
	echo '<div class="center">Click <a href="index.php?show=wild">here</a> to go back to the buglist. You will be redirected there in 5 seconds.</div>';
	URL::js_redirect('index.php?show=wild',5);
      }
    }

    function updated($flag) {
      global $FLAGS,$FLAGS_DESC;
      if($this->email!="") {
	email($this->email,"aMSN Bug Report #".$this->_id." Follow-Up","A bug report that you have sent in the past has been updated. It has been marked as ".$FLAGS[$flag].". This means the following:\n\n".$FLAGS_DESC[$flag]."\n\nThank You for your cooperation,\naMSN Development Team");
      }
    }
    
    function actions() {
      switch($_GET["do"]) {
      case 'removeip':
	$query="DELETE FROM ".TBUGREPORTS." WHERE bug_ip='".$this->ip."'";
	query($query);
	$this->msg("All the bugs reported from ".private_ip($this->ip)." have been removed!",true);
	break;
      case 'block':
	$blocked=blocked($this->ip);
	if($blocked===false) {
	  //blocking expires in 1 day
	  $day=60*60*24;
	  $query="INSERT INTO ".TBLOCK." (block_ip,block_until) VALUES ('".$this->ip."',UNIX_TIMESTAMP()+".$day.")";
	  query($query);
	} else {
	  $query="DELETE FROM ".TBLOCK." WHERE block_ip='".$this->ip."'";
	  query($query);
	}
	break;
      }
    }
    
    function show() {
      if($this->_id==NULL) {
	$this->msg("No such bug!",true);
      } else {
	$this->actions();
	$this->show_admin();
	$this->show_error();
	$this->show_system();
	$this->show_extra();
      }
    }

    function show_admin() {
      $blocked=blocked($this->ip);
      
      if(isset($_POST['submit'])) {
	switch($_POST['submit']) {
	case 'Save':
	  $this->update2db();
	  break;
	case 'Delete':
	  $this->deletedb();
	  $this->email('Deleted','This bug has been deleted.');
	  $this->msg('Bug deleted!',true);
	  break;
	}
      }
	
      echo '<form action="index.php?show=bugreport&amp;id='.$this->_id.'" method="POST">';

      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Administration</caption>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Parent Bug: </b>';
      if($this->bug>0) {
	echo '<a href="?show=bug&amp;id='.$this->bug.'">'.$this->bug.'</a> ';
      }
      echo ' <small><a href="javascript:pickBug('.$this->_id.')">Change</a></small';
      echo '</td><td class="bug_info" rowspan="2">';
      echo '<b>Reporter:</b> ';
      echo hideemail($this->email);
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>IP Address: </b>';
      echo private_ip($this->ip);
      echo ' <small>';
      echo '<a href="?show=bugreport&amp;id='.$this->_id.'&amp;do=block">';
      if($blocked!==false)
	echo 'Unblock';
      else 
	echo 'Block';
      echo '</a>';
      echo ' ';
      echo '<a href="?show=bugreport&amp;id='.$this->_id.'&amp;do=removeip">Remove</a>';
      echo '</small></td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" align="right" colspan="2">';
      echo '<input type="submit" name="submit" value="Delete"/>';
      echo '</td></tr>';
      echo '</table>';

      echo '</form>';
    }

    function show_error() {
      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Error</caption>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Error: </b>'.$this->text;
      echo '</td><td class="bug_info">';
      echo '<b>Error Code: </b>'.$this->code;
      echo '</td></tr>';

      echo '<tr class="bug_row"><td colspan="2" class="bug_info">';
      echo '<b>Submitted:</b>'.strftime("%c",$this->date);
      echo '</td></tr>';
      
      echo '<tr class="bug_row"><td colspan="2" class="bug_info">';
      echo '<b>Stack: </b>';
      echo '<pre>';
      echo $this->stack;
      echo '</pre>';
      echo '</td></tr>';
      echo '</table>';
    }
    
    function show_system() {
      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">System</caption>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>aMSN Version: </b>'.$this->amsn.' (MSNP'.$this->msnprotocol.')';
      echo '</td><td class="bug_info">';
      echo '<b>CVS Date: </b>'.strftime('%c',$this->cvs_date);
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Tcl Version: </b>'.$this->tcl;
      echo '</td><td class="bug_info">';
      echo '<b>Tk Version: </b>'.$this->tk;
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Operating System: </b>'.$this->os;
      echo '</td><td class="bug_info">';
      echo '<b>OS Version: </b>'.$this->osversion;
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Platform: </b>'.$this->platform;
      echo '</td><td class="bug_info">';
      echo '<b>Machine: </b>'.$this->machine;
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Byte Order: </b>'.$this->byteorder;
      echo '</td><td class="bug_info">';
      echo '<b>Threads: </b>';
      echo ($this->threaded=='true')?'Yes':'No';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Word Size: </b>'.$this->wordsize;
      echo '</td><td class="bug_info">';
      echo '<b>User: </b>'.$this->user;
      echo '</td></tr>';
      
      echo '</table>';
    }
    
    function show_extra() {
      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Extra</caption>';

      echo '<tr class="bug_row"><td colspan="2" class="bug_info">';
      echo '<b>User Comment:</b>';
      echo '<pre class="bug" width="100">';
      echo $this->comment;
      echo '</pre>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td colspan="2" class="bug_info">';
      echo '<b>Status Log:</b>';
      echo '<pre class="bug" width="100">';
      echo $this->status_log;
      echo '</pre>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td colspan="2" class="bug_info">';
      echo '<b>Protocol Log:</b>';
      echo '<pre class="bug" width="100">';
      echo $this->protocol_log;
      echo '</pre>';
      echo '</td></tr>';
      
      echo '</table>';
    }
  }
}
?>
