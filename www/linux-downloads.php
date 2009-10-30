<?php
   define('source', 'download');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="download.css" />';
   
   include inc . 'header.php';
?>
<?php echo '
<br />
<img style="display: block;margin-left: auto;margin-right: auto;" src="images/download-linux.png" alt="Linux Download" /><br />
	<a name="AP"></a>
	<h3>'.GENERIC_INSTALLER.'</h3>
	<dl><dt>
            <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl84.x86.package"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage" /></a><br />
	    <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl84.x86.package"><span class="toc_title">'.AMSN_INSTALLER_TCL84.'</span></a>
	</dt><dd>
		'.INDEPENT_INSTALLER84.'
    </dd></dl>
	<dl><dt>
            <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl85.x86.package"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage" /></a><br />
	    <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl85.x86.package"><span class="toc_title">'.AMSN_INSTALLER_TCL85.'</span></a>
	</dt><dd>
		'.INDEPENT_INSTALLER85.'
    </dd></dl>
    <br />
    <p>
      '.CREATED_WITH_AUTO.'<br />
      <a href="http://www.autopackage.org/docs/howto-install/"><b>'.PLEASE_FOLLOW.'</b></a>
    </p>
<br />
<hr style="width:200px;" />
<br />
    <h3>'.DISTRO_INC_AMSN.'</h3><br />
    <p>
      '.DISTRO_DESC_1.'
    </p>
    <p>
      '.DISTRO_DESC_2.'
	</p>
	<p>
	'.OTHERWAY_TARBALL.'
	</p>
	<div style="float:left;margin:1em;text-align:center;">
		<a href="http://packages.debian.org/search?keywords=amsn&searchon=names&suite=all&section=all">
		<img src="images/download-debian-big.png" class="distr" alt="Debian"/><br />Debian</a>
	</div>
	<div style="float:left;margin:1em;text-align:center;">
		<a href="http://amsn-project.net/wiki/InstallOnFedora">
		<img src="images/download-fedora-big.png" class="distr" alt="Fedora"/><br />Fedora</a>
	</div>
	<div style="float:left;margin:1em;text-align:center;">
		<a href="http://packages.gentoo.org/package/net-im/amsn">
		<img src="images/download-gentoo-big.png" class="distr" alt="Gentoo"/><br />Gentoo</a>
	</div>
	<div style="float:left;margin:1em;text-align:center;">
		<a href="http://packages.ubuntu.com/cgi-bin/search_packages.pl?keywords=amsn&amp;searchon=names&amp;version=all&amp;release=all&amp;exact=1">
		<img src="images/download-ubuntu-big.png" class="distr" alt="Ubuntu"/><br />Ubuntu</a>
	</div>
	<div style="clear:left"></div>
<br />
	<div style="float:left;margin:1em;text-align:center;">
		<a href="http://paketler.pardus.org.tr/info/devel/source/amsn.html">
		<img src="images/download-pardus-big.png" class="distr" alt="Pardus (page in turkish)"/><br />Pardus</a>
	</div>
	<div style="clear:left"></div>
<br />
<hr style="width:200px;" />
<br />

    <a name="tarball"></a>
    <h3>'.SOURCE_DOWNLOADS.'</h3>
        <dl class="toc"><dt>
        <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2.tar.bz2"><img class="toc_icon" src="images/download-tarball-big.png" alt="Tarball" /></a><br />
	<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2.tar.bz2"><span class="toc_title">'.AMSN_SOURCE.'</span></a>
        </dt><dd>
          
        </dd></dl>
    <p>
      '.SOURCE_DESC_1.'<br />
      '.SOURCE_DESC_2.'
	</p>

<br />
<hr style="width:200px;" />
<br />
	
	<a name="SVN"></a>
	<h3>'.LATEST_DEV_TITLE.'</h3>
	<dl class="toc"><dt>
	<a href="http://www.amsn-project.net/amsn_dev.tar.gz"><img class="toc_icon" src="images/download-svn-big.png" alt="SVN Snapshot" /></a><br />
	<a href="http://www.amsn-project.net/amsn_dev.tar.gz"><span class="toc_title">'.SVN_SNAPSHOT.'</span></a>
        </dt><dd>
'.LATEST_DEV_SVN.' ';?> <?php if (file_exists('amsn_dev.tar.gz')) { echo 'of '.date("F d Y H:i:s.", filectime('amsn_dev.tar.gz')); } ?><?php echo ')
	</dd></dl>
	<p>
		'.LATEST_DEV_DESC.'
	</p>';
?>
<?php include inc . 'footer.php'; ?>
