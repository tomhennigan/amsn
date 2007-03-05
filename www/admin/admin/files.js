function switchVisibility(name,show)
{

    if (document.getElementById(name+"_div").style.display == 'block' || show == 0) {
        document.getElementById(name+"_div").style.display = 'none';
    } else if (document.getElementById(name+"_div").style.display == 'none' || show == 1) {
        document.getElementById(name+"_div").style.display = 'block';
        document.getElementById(name+"_frame").src = 'admin/pick.file.php?field='+name+'#f'+document.getElementById(name).value;
    }
}