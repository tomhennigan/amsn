<?php
   define('source', 'translations');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

        <p>
        <br/>
          <b>Join our mailing list!!</b><br/><br/>
We have an <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">amsn-
lang mailing list</a> available for people who wish to help us.<br/>
<br/>

You can join it by visiting <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">this page</a>.<br/>
<br/>
Translation requests for new sentences will be sent to this list, so anyone can
instantly answer and send us the translation.<br/><br/><br/>

<b>How to translate missing keys, please READ THIS before translating!</b><br/><br/>
RULES THAT MUST BE FOLLOWED:<br/></p>
<ul><li>Please read the <a href='http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/LANG-HOWTO?rev=HEAD&amp;content-type=text/plain'><b>LANG-HOWTO</b></a> file.</li>

<li>Read LANG-HOWTO again!</li>
<li>Just click the link of the language you want to update (at the back of the page)
<br/><br/>Then, at the page that opens :<br/><br/></li>
<li>Download the old language file ( you will find the link at that page )</li>
<li>Add the keywords from the list at the bottom of the page
to the language file.</li>
<li>Translate the english explanations</li>
<li>Send the updated file to <a href="mailto:amsn-translations@lists.sourceforge.net
">amsn-translations@lists.sourceforge.net</a></li>
<li>We will ONLY accept langfiles. We will NOT accept, in ANY way,
individual keys received in the body of the email. You MUST send
the COMPLETE langfile (for instance, langit if you are italian)
ATTACHED to de email message.</li>
<li>As stated above, keys sent in the body of the email will be IGNORED and DISCARDED.</li>
<li>Langfiles sent to other email addresses than
amsn-translations@lists.sourceforge.net will also be IGNORED
and DISCARDED.</li></ul>
<br/>You can help us by translating some sentences to your language, or modifying
wrongly translated sentences.<br/>
<br/>
Be careful with $1, $2... parameters that appear in some sentences.
You can change their position, but they <b>must</b> appear on the sentence, they
'll be
substituted during execution with some values.<br/><br/><br/>

<b>How to add a new language</b><br/><br/>
<ul><li>Choose a short identifier for your language (for example english - en).</li>
<li>Download the english language file <a href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/langen?rev=HEAD&amp;content-type=text/plain">here</a>.</li>
<li>Rename the file to langXX with XX the identifier you've chosen</li>
<li>Translate the file, except for the first word of each line (that is the key).</li>
<li>Send the new file to <a href="mailto:amsn-translations@lists.sourceforge.net">amsn-translations@lists.sourceforge.net</a></li>
</ul>

<?php
include inc . 'langlist.php';
include inc . 'footer.php';
?>
