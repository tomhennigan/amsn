
           ==========================
             Winks plugin v20070310
           ==========================



1) How do I enable winks support?

   First of all, you should be running aMSN 0.97b updated (at least svn 7719) ;)
   Then go to the plugin selection dialog and enable Winks.
   RESTART AMSN.


2) What do I need so that Winks plugin works correctly?

   * A .cab files' decompressing tool.
      -> For Windows XP SP2 or newer: Check the field "Use Extrac32 instead CabExtract".
      -> For other OS (or if it doesn't works with Extrac32) you can get CabExtract. You'll have to set the path where you installed CabExtract in the plugin configuration dialog. You can get it from: http://www.kyz.uklinux.net/cabextract.php


   * An external flash player.
      There are many players and it depends on which operative system you use. Once you chose and downloaded one, you should go to the plugin configuration dialog and set the player path and the player arguments.
      Here's some players with their arguments:

      -> Linux: Adobe Flash Player
         http://www.adobe.com/support/flashplayer/downloads.html
         Player arguments: ""

      -> Windows/Macintosh: Flash Player Projector
         http://www.adobe.com/support/flashplayer/downloads.html
         Player arguments "".

      -> Windows: Swiff Player
         http://www.globfx.com/downloads/swfplayer/
         Player arguments: "".

      -> Linux/Windows: gnash
         http://www.gnu.org/software/gnash/#downloading
         Player arguments: "-1"


3) How do I use Winks Plugin?

   If you have winks plugin enabled (cf 1) ), you'll see a new Winks button in the chat window ("CW"). The Winks Menu will show you the winks you can send. It will be empty the first time.

            /!\ THE PLUGIN DOES NOT INCLUDE ANY WINKS /!\

    You have to get them from other contacts (simply receiving them) or add from an .MCO file doing right click on the Winks button or clicking "Add new wink..." on the Winks menu.

   In the Winks menu:
    -> Left click a wink : send to your contact
    -> Middle click a wink : see a preview
    -> Right click a wink : edit/delete


4) What can I configure in Winks plugin?

   -> "Show "Add new wink" in winks menu.": Once enabled, this option will display in the bottom of the Wink Menu a button allowing you to add a new wink from a .mco file.
      It's always possible to add a wink by right-clincking the Winks button in the CW.
   -> "Close winks menu on mouse leave": Once enabled, this option will automatically close the Wink Menu as soon as your mouse cursor left it. If it's disabled, a "Close" button will appear in the bottom of the Wink Menu, that you'll have to click.
   -> "CabExtract command:": This allows you to set the path/command of CabExtract
   -> "Use extrac32 (set for WinXP) instead of cabextract.": This option allows people using Windows XP SP2 or newer to use Extrac32, which is included in their OS.
   -> "Swf player command:": This allows you to set the path/command of your Flash player
   -> "Swf player arguments:": This allows you to set arguments of the Flash player you chose
   -> "Play wink immediatly when received.": Once enabled, the winks received will automatically be played.
   -> "Play the wink inside the chat window (only for gnash). ": This option, that requires gnash, will play the wink embedded in the CW, not in an external window.
   -> "Notify received winks in one line.": The received winks will be displayed on one single line.

5) How do I add new Winks?

   -> Receiving a wink via aMSN: When one of your contacts sends you a wink, that wink will be added to your Winks menu.
   -> Adding a wink from an .MCO file:  When you right click the Winks button or the "Add new wink..." button in the Winks menu, it will ask you for a file (the MCO=messenger content object) and then a wink name. If the file is correct, the wink that it contains will be added to your Winks menu. If you leave empty the wink name field, the plugin will look for a suitable name in the wink files. If after accepting you don't see the new wink in your wink menu, the file may not be a wink file or there's some trouble. In that case, go to the contact list window and press Ctrl+S. Then the Satus window will show up, in the last lines you can see what the problem is. If you report a bug, please include those lines.


6) Why is it so slow?

   When someone sends you a wink only sends you a message with the wink ID. If you have the wink, it will be played immediatly, but if you don't the plugin should ask the other person for it and then you have to wait until the wink file transfer is complete.
   The same when you send a wink to the other client.


7) Why are the winks played in a another window? Can't I see them inside the chat window?

   What the plugin does to show you the wink is calling an external flash player (see question 2). "External" means that its another program, not amsn, who plays it; so it has his own window. But there's may be a way to see them inside chat window: If your player is "gnash", we can use its functionallity to achieve it. This feature is still being tested and developed, so I may work or not, depending on what os and gnash version you use. Anyway, if you want to try, enable the "Play the wink inside the chat window" option in the plugin configuration dialog.


8) I found a bug! / I need more help!

   You always can ask for help or reports the problems you find in amsn's forums:

      Plugins forum:

         http://www.amsn-project.net/forums/viewforum.php?f=14

      Wink plugin development topic:

         http://www.amsn-project.net/forums/viewtopic.php?t=2366



   Written by Pablo Novara, zaskar_84@yahoo.com.ar

   Thanks to the aMSN development team for their help; Kakaroto for the voice-messages example code and many tips about amsn internals; Jérôme Gagnon-Voyer, Karel Demeyer and Alberto Diaz, Doki for the Nudge plugin (great plugin example); snipe2004 for the french translation and readme corrections; Trappski for the swedish translation; WM-666 for the dutch translation; [S]haDoW for the italian translation; Trip for the german translation; Simple Me for the button pixmaps; NoWhereMan, neothematrix and many others for testing, reporting bugs, suggesting modifications and all those things...

