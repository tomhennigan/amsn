<?php
   define('source', 'download');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="download.css" />';
   
   include inc . 'header.php';
?>

<br />
<img style="display: block;margin-left: auto;margin-right: auto;" src="images/download-linux.png" alt="Linux Download" /><br />
	<a name="AP"></a>
	<h3>Generic Installers</h3>
	<dl><dt>
            <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl84.x86.package"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage" /></a><br />
	    <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl84.x86.package"><span class="toc_title">aMSN Installer for Tcl/Tk&nbsp;8.4</span></a>
	</dt><dd>
		Distribution independent installer for those who <strong>already</strong> have Tcl/Tk&nbsp;8.4
    </dd></dl>
	<dl><dt>
            <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl85.x86.package"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage" /></a><br />
	    <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2-1.tcl85.x86.package"><span class="toc_title">aMSN Installer for Tcl/Tk&nbsp;8.5</span></a>
	</dt><dd>
		Distribution independent installer for those who <strong>already</strong> have Tcl/Tk&nbsp;8.5 <strong>final version</strong>
    </dd></dl>
    <br />
    <p>
      These generic installers were created with <a href="http://www.autopackage.org/">Autopackage</a>.
      This is a new Linux technology to create distribution independent packages,
      with an installer <a href="http://www.autopackage.org/gallery.html">with a user-friendly look. Check by yourself !</a>.<br />
      <a href="http://www.autopackage.org/docs/howto-install/"><b>Please follow the instructions to install the package.</b></a>
    </p>
<br />
<hr style="width:200px;" />
<br />
    <h3>Distributions including aMSN</h3><br />
    <p>
      The following distributions already include aMSN in their package collections.
      You can install aMSN directly with your package manager, without having to download it here.
    </p>
    <p>
      However, some distributions may not supply the last version yet.
      In that case it's recommended to use <a href="#AP">the aMSN Installer.</a>
	</p>
	<p>
	An other way to install aMSN if everything else fails, is to install the <a href="#tarball">source tarball</a>.
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
    <h3>Source downloads</h3>
        <dl class="toc"><dt>
        <a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2.tar.bz2"><img class="toc_icon" src="images/download-tarball-big.png" alt="Tarball" /></a><br />
	<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2.tar.bz2"><span class="toc_title">aMSN Source</span></a>
        </dt><dd>
          Source package to build a binary for your own distribution.
        </dd></dl>
    <p>
      You can use the source package to build a binary for your Linux distribution.
      It is also possible to create RPM or DEB packages from the source package,
      using the <span class="command">make rpm</span> or <span class="command">make deb</span> command appropriate to your distribution.<br />
      Please follow the <a href="http://amsn-project.net/wiki/Installing_Tarball">instructions to install</a> the package.
	</p>

<br />
<hr style="width:200px;" />
<br />
	
	<a name="SVN"></a>
	<h3>Latest development version (SVN Snapshot)</h3>
	<dl class="toc"><dt>
	<a href="http://www.amsn-project.net/amsn_dev.tar.gz"><img class="toc_icon" src="images/download-svn-big.png" alt="SVN Snapshot" /></a><br />
	<a href="http://www.amsn-project.net/amsn_dev.tar.gz"><span class="toc_title">SVN Snapshot</span></a>
        </dt><dd>
Latest development version (SVN Snapshot <?php if (file_exists('amsn_dev.tar.gz')) { echo 'of '.date("F d Y H:i:s.", filectime('amsn_dev.tar.gz')); } ?> )
	</dd></dl>
	<p>
		You may want to test our development version. But, as it's a development version, it may contains more bugs than the official versions, and may also be completely broken sometimes. You will find more information on how to install that development version <a href="http://www.amsn-project.net/wiki/Installing_SVN">on our wiki</a>
	</p>

<?php include inc . 'footer.php'; ?>
