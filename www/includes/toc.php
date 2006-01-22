<?php

$elements_per_line=5;

if (!isset($toc_arrays)) return;

$i = 0;
echo '<div style="text-align:center">';
foreach($toc_arrays as $toc_element) {
        if ($i > 0 )
                echo ' | ';

        echo '<a href="#'. $toc_element[0]. '"> ' . $toc_element[0] . ' </a>';

        $i = $i + 1;

        if ($i == $elements_per_line) {
                echo '<br />';
                $i = 0;
        }
}
echo '</div> <br/> <br/>';

?>
