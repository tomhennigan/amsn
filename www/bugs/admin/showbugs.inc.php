<?php
$table=new Tabler(TBUGS,array('ID'=>'bug_id','Name'=>'bug_name','Developer'=>'bug_developer','Priority'=>'bug_priority','Flag'=>'bug_flag','Last Update'=>'bug_last_update'),array(),'bug_priority DESC');
$table->col_option('bug_id','css','width:50px;text-align:center');
$table->col_option('bug_name','filter','search');
$table->col_option('bug_developer','css','width:200px;');
$table->col_option('bug_priority','css','width:50px;text-align:center');
$table->col_option('bug_flag','css','width:100px;text-align:center');
$table->col_option('bug_flag','rename',$FLAGS);
$table->col_option('bug_last_update','rename','strftime("%c",$arg)');
$table->col_option('bug_last_update','css','width:230px;');
$table->link('bug');
$table->show();
?>