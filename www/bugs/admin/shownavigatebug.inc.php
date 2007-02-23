<?php
  $id=$_GET['id'];

$table=new Tabler(TBUGREPORTS,array('ID'=>'bug_id','Text'=>'bug_text','Submitted'=>'bug_date','Revision'=>'bug_revision','CVS Date'=>'bug_cvsdate','Version'=>'bug_amsn','Tcl/TK'=>'bug_tcl','OS'=>'bug_os','MSN Protocol'=>'bug_msnprotocol'),array('bug_parent='.$id));
$table->col_option('bug_id','css','width:50px;text-align:center');
$table->col_option('bug_text','filter','search');
$table->col_option('bug_text','rename','translucate(html_entity_decode(\'$arg\'),45)');
$table->col_option('bug_date','css','width:210px;text-align:center');
$table->col_option('bug_date','rename','strftime("%c",$arg)');
$table->col_option('bug_date','filter','search');
$table->col_option('bug_cvsdate','rename','strftime("%c",$arg)');
$table->col_option('bug_cvsdate','css','width:210px;text-align:center');
$table->col_option('bug_cvsdate','filter','search');
$table->col_option('bug_amsn','css','width:50px;text-align:center');
$table->col_option('bug_tcl','css','width:70px;text-align:center');
$table->col_option('bug_os','css','width:70px;');
$table->col_option('bug_msnprotocol','css','text-align:center');
$table->link('bugreport');
$table->show();
?>
