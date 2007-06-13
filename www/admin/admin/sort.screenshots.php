<?php
require_once '../../common.php';
session_start();

header("Cache-control: private");

require_once 'lib.user.php';
require_once 'lib.misc.php';

if (!isset($_SESSION['user'], $_SESSION['level']) || !user_level(3)) {
    noperms();
    exit;
}
?>
<html>
<head>
</head>
<?php
if (isset($_POST['sort_id']) && ereg('^[0-9][0-9]*$', $_POST['sort_id']) && isset($_POST['sort'])) {
    if (mysql_num_rows(($all = @mysql_query("SELECT * FROM `amsn_screenshots` ORDER BY `order` DESC, `name` ASC")))) {

        $sorting = array();
        while ($row = mysql_fetch_assoc($all)) {
            array_push($sorting, $row['id']);
        }
        if ($_POST['sort'] == 'up') {
            $new_id = $_POST['sort_id'] - 1;
        }
        else {
            $new_id = $_POST['sort_id'] + 1;
        }
        if ($new_id >= 0 && $new_id < sizeof($sorting) && $_POST['sort_id'] >= 0 && $_POST['sort_id'] < sizeof($sorting)) {
            $element = $sorting[$_POST['sort_id']];
            $sorting[$_POST['sort_id']] = $sorting[$new_id];
            $sorting[$new_id] = $element;
            $success = true;
            $i = sizeof($sorting)-1;
            foreach ($sorting as $v) {
                $success = mysql_query("UPDATE `amsn_screenshots` SET `order` = '{$i}' WHERE `id` = '{$v}' LIMIT 1") ? $success : false;
                $i = $i - 1;
            }
            if ($success) {
?>
<script language="javascript"><!--
    function applymod()
    {
        var field = window.parent.document.getElementById("list_ids");
        var curid = <?php echo $_POST['sort_id'] ?>;
        var newid = <?php echo $new_id ?>;
        var curtxt = field.options[curid].text;
        field.options[curid].text = field.options[newid].text;
        field.options[newid].text = curtxt;
        field.selectedIndex = newid;
    }
    //-->
</script>
<body onload="applymod()">
</body>
<?php
            }
        }
    }
}
?>
</html>
