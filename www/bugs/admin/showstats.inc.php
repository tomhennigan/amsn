<?php
    function print_unique_count($result, $field) {
      mysql_data_seek($result, 0);

      $versions = array();

      while($row=mysql_fetch_array($result)) {
        if (!isset($os[$row[$field]])) {
           $os[$row[$field]] = 1;
        } else {
           $os[$row[$field]]++;
        }
      }

      $first = 1;
      foreach ($os as $version => $count) {
         if ( $first != 1) {
              echo " - ";
         }
	 if ($version == "") {
	      $version = "Unknown";
	 }
         echo $version."(".$count.") ";
         $first = 0;
      }
    }

    function show_bug_stats($wild) {
      if ($wild == 1) {
           $query="SELECT bug_amsn, bug_tcl, bug_os FROM ".TBUGREPORTS." WHERE bug_parent='0'";
      } elseif ($wild == 0) {
           $query="SELECT bug_amsn, bug_tcl, bug_os FROM ".TBUGREPORTS." WHERE bug_parent<>'0'";
      } else {
           $query="SELECT bug_amsn, bug_tcl, bug_os FROM ".TBUGREPORTS;
      }
      $result=mysql_query($query) or die('MySQL Query Error! '.mysql_error());

      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Appears in aMSN versions : </b>';
      print_unique_count($result, 'bug_amsn');
      echo '<br/></td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Appears in Tcl/Tk versions : </b>';
      print_unique_count($result, 'bug_tcl');
      echo '<br/></td></tr>';

      echo '<tr class="bug_row"><td class="bug_info" colspan="2">';
      echo '<b>Appears in the Operating Systems : </b>';
      print_unique_count($result, 'bug_os');
      echo '<br/></td></tr>';
      flush();

      mysql_free_result($result);
    }

echo "All bug reports : <br/>";
show_bug_stats(2);
echo "<br/><br/><br/>Wild bug reports : <br/>";
show_bug_stats(1);
echo "<br/><br/><br/>Parented bug reports : <br/>";
show_bug_stats(0);
echo "<br/><br/><br/>";

?>
