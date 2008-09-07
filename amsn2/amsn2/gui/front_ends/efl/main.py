from constants import *
import ecore
import ecore.evas
import ecore.x
import etk
import skins
import window
from amsn2.gui import base
from amsn2.core.views import MenuView, MenuItemView

class aMSNMainWindow(window.aMSNWindow, base.aMSNMainWindow):
    def __init__(self, amsn_core):     
        window.aMSNWindow.__init__(self, amsn_core)
        self.on_destroyed(self.__on_delete_request)
        self.on_shown(self.__on_show)
        self.on_key_down(self.__on_key_down)

    """ Private methods
        thoses methods shouldn't be called by outside or by an inherited class
        since that class shouldn't be herited
    """
    def __on_show(self, evas_obj):
        self._amsn_core.mainWindowShown()

    def __on_delete_request(self, evas_obj):
        self._amsn_core.quit()

    def __on_key_down(self, obj, event):
        if event.keyname == "Escape":
            self._amsn_core.quit()
        else:
            window.aMSNWindow._on_key_down(self,obj, event)
