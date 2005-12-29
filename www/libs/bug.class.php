<?php
if(!defined('_BUG_CLASS_')) {
  define('_BUG_CLASS_',1);
  
  class Bug {
#information about the bug
    var $_id;
    var $_version;
    var $ip;
    var $flag=NONE;

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
      $this->date=$xml->get_content('/bug[1]/error[1]/date[1]');
      $this->text=$xml->get_content('/bug[1]/error[1]/text[1]');
      $this->stack=$xml->get_content('/bug[1]/error[1]/stack[1]');
      $this->code=$xml->get_content('/bug[1]/error[1]/code[1]');
      //set system stuff
      $this->amsn=$xml->get_content('/bug[1]/system[1]/amsn[1]');
      $this->cvs_date=$xml->get_content('/bug[1]/system[1]/date[1]');
      $this->tcl=$xml->get_content('/bug[1]/system[1]/tcl[1]');
      $this->tk=$xml->get_content('/bug[1]/system[1]/tk[1]');
      $this->osversion=$xml->get_content('/bug[1]/system[1]/osversion[1]');
      $this->byteorder=$xml->get_content('/bug[1]/system[1]/byteorder[1]');
      $this->threaded=$xml->get_content('/bug[1]/system[1]/threaded[1]');
      $this->machine=$xml->get_content('/bug[1]/system[1]/machine[1]');
      $this->platform=$xml->get_content('/bug[1]/system[1]/platform[1]');
      $this->os=$xml->get_content('/bug[1]/system[1]/os[1]');
      $this->user=$xml->get_content('/bug[1]/system[1]/user[1]');
      $this->wordsize=$xml->get_content('/bug[1]/system[1]/wordsize[1]');
      //set extra stuff
      $this->status_log=$xml->get_content('/bug[1]/extra[1]/status_log[1]');
      $this->protocol_log=$xml->get_content('/bug[1]/extra[1]/protocol_log[1]');
      //set user info
      $this->email=$xml->get_content('/bug[1]/user[1]/email[1]');
      $this->comment=trim($xml->get_content('/bug[1]/user[1]/comment[1]'));
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
      $query="SELECT COUNT(*) AS c FROM ".TABLE." WHERE bug_ip='".$ip."' AND bug_text='".$this->text."'";
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
		    'bug_flag'=>$this->flag,
		    'bug_email'=>$this->email,
		    'bug_comment'=>$this->comment);
      return $fields;
    }
  
    function save2db() {
      $fieldsq="`bug_ip`";
      $valuesq="'".$_SERVER['REMOTE_ADDR']."'";

      $array=$this->getArray();
      foreach($array as $key => $value) {
	$fieldsq.=",`".$key."`";
	$valuesq.=",'".$value."'";
      }
      
      $query="INSERT INTO ".TABLE." (".$fieldsq.") VALUES (".$valuesq.")";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $this->_id=mysql_insert_id();
      
      return $this->_id;
    }

    function update2db() {
      $array=$this->getArray();
      $query="UPDATE ".TABLE." SET ";
      foreach($array as $key => $value) {
	$query.=$key."='".$value."',";
      }
      #get rid of the trailing ,
      $query=substr($query,0,strlen($query)-1);
      #and finally the clause
      $query.=" WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }

    function deletedb() {
      $query="DELETE FROM ".TABLE." WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $query="DELETE FROM ".TDUPES." WHERE dupe_bug1='".$this->_id."' OR dupe_bug2='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }

    function loaddb($id) {
      $query="SELECT * FROM ".TABLE." WHERE bug_id='$id'";
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
      #set extra stuff
      $this->status_log=$row['bug_status'];
      $this->protocol_log=$row['bug_protocol'];
      #user crap
      $this->email=$row['bug_email'];
      $this->comment=$row['bug_comment'];

    }
    
    function email($title,$msg) {
      $title="[".$this->_id."] ".$title;
      mail($this->email,$title,$msg,"From: ".EMAIL);
    }

    function msg($msg,$redir=false) {
      echo '<div class="center">'.$msg.'</div>';
      if($redir!==false) {
	echo '<div class="center">Click <a href="index.php">here</a> to go back to the buglist. You will be redirected there in 5 seconds.</div>';
	URL::js_redirect('index.php',5);
      }
    }
    
    function actions() {
      switch($_GET["do"]) {
      case 'removeip':
	$query="DELETE FROM ".TABLE." WHERE bug_ip='".$this->ip."'";
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
      global $FLAGS,$FLAGS_DESC;

      $blocked=blocked($this->ip);
      dupes($this->_id,$dupes);
      
      if(isset($_POST['submit'])) {
	switch($_POST['submit']) {
	case 'Save':
	  $flag=intval(trim($_POST['flag']));
	  if($flag!=$this->flag) {
	    $name=array_search($flag,$FLAGS);
	    $this->email("New flag!",'This bug is now marked as '.$name.' which means: "'.$FLAGS_DESC[$name].'".');
	  }
	  $this->flag=$flag;
	  
	  if($_POST['dupe']!="") {
	    $dupe=$_POST['dupe'];
	    if(!bug_exists($dupe)) {
	      $this->msg('A non existant bug can\'t be a duplicate!');
	      break;
	    }
	    if($dupe==$this->_id) {
	      $this->msg('A bug can\'t be a duplicate of itself!');
	      break;
	    }
	    if(array_search($dupe,$dupes)!==false) {
	      $this->msg('It already is a duplicate!');
	      break;
	    }
	    
	    $query="INSERT INTO ".TDUPES." (dupe_bug1,dupe_bug2) VALUES ('".$this->_id."','".$dupe."')";
	    query($query);
	    $this->msg('Duplicate added.');
	    $this->email('Duplicate','This bug has been marked as a duplicate of '.$dupe.'.');
	    $dupes[]=$dupe;
	  }
	  $this->update2db();
	  break;
	case 'Delete':
	  $this->deletedb();
	  $this->email('Deleted','This bug has been deleted.');
	  $this->msg('Bug deleted!',true);
	  break;
	}
      }
	
      echo '<form action="index.php?bug='.$this->_id.'" method="POST">';

      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Administration</caption>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Flag: </b>';
      echo '<select name="flag">';
      foreach($FLAGS as $flag => $value) {
	echo '<option value="'.$value.'"';
	echo ($this->flag==$value)?' selected="selected"':'';
	echo '>'.$flag.'</option>';
      }
      echo '</select>';
      echo '</td><td class="bug_info" rowspan="3">';
      echo '<b>Reporter:</b> ';
      echo hideemail($this->email);
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>IP Address: </b>';
      echo private_ip($this->ip);
      echo ' <small>';
      echo '<a href="?bug='.$this->_id.'&amp;do=block">';
      if($blocked!==false)
	echo 'Unblock';
      else 
	echo 'Block';
      echo '</a>';
      echo ' ';
      echo '<a href="?bug='.$this->_id.'&amp;do=removeip">Remove</a>';
      echo '</small></td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Duplicates: </b>';
      foreach($dupes as $dupe) {
	if($dupe!=$this->_id)
	  echo '<a href="?bug='.$dupe.'">'.$dupe.'</a> ';
      }
      echo '<input type="text" name="dupe" class="short" />';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" align="right" colspan="2">';
      echo '<input type="submit" name="submit" value="Save"/>';
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
      echo '<b>aMSN Version: </b>'.$this->amsn;
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