<?php
if(!defined('_BUG_CLASS_')) {
  define('_BUG_CLASS_',1);
  
  class Bug {
#information about the bug
    var $_id;
    var $name;
    var $developer;
    var $priority;
    var $flag;
    var $error_regexp;
    var $stack_regexp;
    var $desc;
    var $bugs=array();
    var $lastupdate;
    
    function Bug() {
      $this->lastupdate=mktime();
    }

    #array getArray (void)
    #returns all the information in a colum2value array to me used when generating queries
    function getArray() {
      $fields=array('bug_name'=>$this->name,
		    'bug_developer'=>$this->developer,
		    'bug_priority'=>$this->priority,
		    'bug_last_update'=>$this->lastupdate,
		    'bug_flag'=>$this->flag,
		    'bug_error_regexp'=>$this->error_regexp,
		    'bug_stack_regexp'=>$this->stack_regexp,
		    'bug_desc'=>$this->desc);
      return $fields;
    }
  
    function save2db() {
      $fieldsq="";
      $valuesq="";

      $array=$this->getArray();
      foreach($array as $key => $value) {
	$fieldsq.=",`".$key."`";
	$valuesq.=",'".$value."'";
      }

      $fieldsq=substr($fieldsq,1);
      $valuesq=substr($valuesq,1);
      
      $query="INSERT INTO ".TBUGS." (".$fieldsq.") VALUES (".$valuesq.")";
      //echo $query;
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $this->_id=mysql_insert_id();
      
      return $this->_id;
    }

    function update2db() {
      $array=$this->getArray();
      $query="UPDATE ".TBUGS." SET ";
      foreach($array as $key => $value) {
	$query.=$key."='".mysql_real_escape_string($value)."',";
      }
      #get rid of the trailing ,
      $query=substr($query,0,strlen($query)-1);
      #and finally the clause
      $query.=" WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }
    
    function deletedb() {
      $query="DELETE FROM ".TBUGS." WHERE bug_id='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $query="DELETE FROM ".TBUGREPORTS." WHERE bug_parent='".$this->_id."'";
      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
    }

    function loaddb($id) {
      $query="SELECT * FROM ".TBUGS." WHERE bug_id='$id'";
      $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());
      $rows=mysql_num_rows($result);
      if($rows!=1) {
	return false;
      }
      $row=mysql_fetch_array($result);
      $this->_id=$id;

      $this->name=$row['bug_name'];
      $this->developer=$row['bug_developer'];
      $this->priority=$row['bug_priority'];
      $this->lastupdate=$row['bug_last_update'];
      $this->flag=$row['bug_flag'];
      $this->error_regexp=$row['bug_error_regexp'];
      $this->stack_regexp=$row['bug_stack_regexp'];
      $this->desc=$row['bug_desc'];
      
      $this->loadbugs();
    }

    function loadbugs() {
      $this->bugs=array();
      $query="SELECT bug_id FROM ".TBUGREPORTS." WHERE bug_parent='".$this->_id."'";
      $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());

      while($row=mysql_fetch_array($result)) {
	$this->bugs[]=$row['bug_id'];
      }
    }

    function checkReport($rep) {
      global $FLAGS;
      if($this->lastupdate<$rep->cvs_date && $FLAGS[$this->flag]=='FIXED') {
	$this->flag=$FLAGS['REOPENED'];
	$this->lastupdate=mktime();
	$this->update2db();
	if($this->developer!="Nobody") 
	  email($this->developer,"[".$this->_id.'] Bad Fix',"Seems like bug #".$this->_id." has not been fixed properly as we have just recieved an bug report that matches it from an amsn client newer than the fix date.\n\nhttp://amsn.sf.net/bugs/index.php?show=bug&id=".$this->_id);
	return true;
      } else if($this->lastupdate>$rep->cvs_date && $FLAGS[$this->flag]=='FIXED') {
	return false;
      }
      return true;
    }
    
    function msg($msg,$redir=false) {
      echo '<div class="center">'.$msg.'</div>';
      if($redir!==false) {
	echo '<div class="center">Click <a href="index.php?show=bugs">here</a> to go back to the buglist. You will be redirected there in 5 seconds.</div>';
	URL::js_redirect('index.php?show=bugs',5);
      }
    }
    
    function actions() {
      if(isset($_POST['submit'])) {
	switch($_POST['submit']) {
	case 'Save':
	  foreach($_POST as $key => $value) {
	    $_POST[$key]=stripslashes($value);
	  }
	  $this->name=(isset($_POST['name']))?$_POST['name']:$this->name;
	  if(isset($_POST['flag']) && $_POST['flag']!=$this->flag) {
	    $this->flag=$_POST['flag'];
	    $this->lastupdate=mktime();
	    foreach($this->bugs as $id) {
	      $report=new BugReport();
	      $report->loaddb($id);
	      $report->updated($this->flag);
	    }
	  }
	  $this->developer=(isset($_POST['developer']))?$_POST['developer']:$this->developer;
	  $this->desc=(isset($_POST['desc']))?$_POST['desc']:$this->desc;
	  $this->error_regexp=(isset($_POST['error_regexp']))?$_POST['error_regexp']:$this->error_regexp;
	  $this->stack_regexp=(isset($_POST['stack_regexp']))?$_POST['stack_regexp']:$this->stack_regexp;
	  $this->update2db();
	  break;
	case 'Delete':
	  $this->deletedb();
	  $this->msg('Bug deleted!',true);
	  break;
	case 'Search':
	  $query="UPDATE ".TBUGREPORTS." SET bug_parent='0' WHERE bug_parent='".$this->_id."'";
	  mysql_query($query) or die('MySQL Query Error! '.mysql_error());
	  $query="SELECT bug_id,bug_text,bug_stack FROM ".TBUGREPORTS." WHERE bug_parent='0'";
	  $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());
	  $found=0;
	  while($row=mysql_fetch_array($result)) {
	    if(ereg($this->error_regexp,$row['bug_text']) && ereg_mline($this->stack_regexp,$row['bug_stack'])) {
	      $query="UPDATE ".TBUGREPORTS. " SET bug_parent='".$this->_id."' WHERE bug_id='".$row['bug_id']."'";
	      mysql_query($query) or die('MySQL Query Error! '.mysql_error());
	      $this->bugs[]=$row['bug_id'];
	      $found++;
	    }
	  }
	  $this->msg("Found ".$found." bug reports!",false);
	  break;
	case 'Preview':
	  $this->stack_regexp=stripslashes($_POST['stack_regexp']);
	  $this->error_regexp=stripslashes($_POST['error_regexp']);
	  $query="SELECT bug_id,bug_text,bug_stack FROM ".TBUGREPORTS." WHERE bug_parent='0' OR bug_parent='".$this->_id."'";
	  $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());
	  $found=0;
	  $bugs=array();
	  while($row=mysql_fetch_array($result)) {
	    if(ereg($this->error_regexp,$row['bug_text']) && ereg_mline($this->stack_regexp,$row['bug_stack'])) {
	      if(count($bugs)<10)
		$bugs[]=$row['bug_id'];
	      $found++;
	    }
	  }
	  $this->msg("Found ".$found." bug reports!",false);
	  $str='';
	  foreach($bugs as $id) {
	    $str.='<a href="?show=bugreport&amp;id='.$id.'">'.$id.'</a> ';
	  }
	  $this->msg("Preview: ".$str,false);
	  break;
	}
      }
    }
    
    function show() {
      if($this->_id==NULL) {
	$this->msg("No such bug!",true);
      } else {
	$this->actions();
	$this->show_admin();
	$this->show_bugs();
      }
    }

    function show_admin() {
      global $FLAGS;

      echo '<form action="index.php?show=bug&amp;id='.$this->_id.'" method="POST">';

      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Administration</caption>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Name: </b>';
      echo '<input type="text" name="name" value="'.$this->name.'"/>';
      echo '</td><td class="bug_info">';
      echo '<b>Flag:</b> ';
      echo '<select name="flag">';
      foreach($FLAGS as $id => $flag) {
	echo '<option value="'.$id.'"';
	if($id==$this->flag) echo ' selected="selected"';
	echo '>'.$flag.'</option>';
      }
      echo '</select>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Developer: </b>';
      echo '<input type="text" name="developer" value="'.$this->developer.'"/>';
      echo '</td><td class="bug_info">';
      echo '<b>Priority: </b>';
      echo $this->priority;
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info">';
      echo '<b>Description:</b>';
      echo '</td><td class="bug_info">';
      echo '<b>Last Update: </b>';
      echo strftime('%c',$this->lastupdate);
      echo '</td></tr>';
      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<textarea name="desc">';
      echo $this->desc;
      echo '</textarea>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" align="right" colspan="2">';
      echo '<input type="submit" name="submit" value="Delete"/>';
      echo '<input type="submit" name="submit" value="Save"/>';
      echo '</td></tr>';
      echo '</table>';
    }

    function show_bugs() {
      echo '<table class="bug" cellspacing="0" align="center">';
      echo '<caption class="bug_title">Bug Reports</caption>';
      $total_bugs = count($this->bugs);

      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Reports '.$total_bugs.' : </b>';

      $shown_bugs = 0;
      foreach($this->bugs as $report) {
	echo '<a href="?show=bugreport&amp;id='.$report.'">'.$report.'</a> ';

	$shown_bugs = $shown_bugs + 1;
	if ($shown_bugs >= 100) {
	   $remaining_bugs = $total_bugs - 100;
	   echo ' ... ('.$remaining_bugs.' more)';
	   break;
	}

      }
      echo '</td></tr>';
      
      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<a href="?show=navigatebug&amp;id='.$this->_id.'">Navigate through this bug\'s reports</a>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Error Text RegExp:</b><br/>';
      echo '<textarea name="error_regexp">';
      echo $this->error_regexp;
      echo '</textarea>';
      echo '</td></tr>';
      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Stack RegExp:</b><br/>';
      echo '<textarea name="stack_regexp">';
      echo $this->stack_regexp;
      echo '</textarea>';
      echo '</td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" align="right" colspan="2">';
      echo '<input type="submit" name="submit" value="Preview"/>';
      echo '<input type="submit" name="submit" value="Search"/>';
      echo '<input type="submit" name="submit" value="Save"/>';
      echo '</td></tr>';

      echo '</table>';
      echo '</form>';
    }
  }
}
?>
