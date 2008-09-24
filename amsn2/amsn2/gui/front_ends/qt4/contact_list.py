from amsn2.gui import base

from PyQt4.QtCore import *
from PyQt4.QtGui import *
from contact_model import ContactModel
from contact_item import ContactItem
from ui_contactlist import Ui_ContactList
from styledwidget import StyledWidget
from amsn2.core.views import StringView
from amsn2.gui import base

class aMSNContactListWindow(base.aMSNContactListWindow):
    def __init__(self, amsn_core, parent):
        self._amsn_core = amsn_core
        self._parent = parent
        self._clwidget = aMSNContactListWidget(amsn_core, self)
        self._clwidget.show()

    def show(self):
        self._clwidget.show()
    
    def hide(self):
        self._clwidget.hide()

    def setTitle(self, text):
        self._parent.setTitle(text)

    def setMenu(self, menu):
        self._parent.setMenu(menu)

    def topCLUpdated(self, contactView):
        pass #TODO

    
            
class aMSNContactListWidget(StyledWidget, base.aMSNContactListWidget):
    def __init__(self, amsn_core, parent):
        StyledWidget.__init__(self, parent._parent)
        self._amsn_core = amsn_core
        self.ui = Ui_ContactList()
        self.ui.setupUi(self)
        self._parent = parent
        self._mainWindow = parent._parent
        self._model = QStandardItemModel(self)
        self.ui.cList.setModel(self._model)

    def show(self):
        self._mainWindow.fadeIn(self)

    def hide(self):
        pass
    
    def contactUpdated(self, contact):
        l = self._model.findItems("", Qt.MatchWildcard)
        
        for itm in l:
            if itm.data(40) == contact.uid:
                itm.setContactName(QString.fromUtf8(contact.name.toString()))
                break

    def groupUpdated(self, group):
        l = self._model.findItems("", Qt.MatchWildcard)
        
        for itm in l:
            
            if itm.data(40) == group.uid:
                
                itm.setText(QString.fromUtf8(group.name.toString()))
            
                for contact in group.contacts:
                    
                    for ent in l:
                        
                        if ent.data(40) == contact.uid:
                            itm.setContactName(QString.fromUtf8(contact.name.toString()))
                            continue
                        
                    print "  * " + contact.name.toString()
            
                    contactItem = ContactItem()
                    contactItem.setContactName(QString.fromUtf8(contact.name.toString()))
                    contactItem.setData(contact.uid, 40)
            
                    itm.appendRow(contactItem)
                    
                break

    def groupRemoved(self, group):
        l = self._model.findItems("", Qt.MatchWildcard)
        
        for itm in l:
            if itm.data(40) == group.uid:
                row = self._model.indexFromItem(itm)
                self._model.takeRow(row)
                break

    def configure(self, option, value):
        pass

    def cget(self, option, value):
        pass

    def size_request_set(self, w,h):
        pass

    def setContactCallback(self, cb):
        #cb is func(contactview)
        pass

    def setContactContextMenu(self, cb):
        #TODO:
        pass

    def groupAdded(self, group):
        print group.name.toString()
        
        pi = self._model.invisibleRootItem();
        
        # Adding Group Item
        
        groupItem = QStandardItem()
        groupItem.setText(QString.fromUtf8(group.name.toString()))
        groupItem.setData(QVariant(group.uid), 40)
        pi.appendRow(groupItem)
        
        for contact in group.contacts:
            print "  * " + contact.name.toString()
            
            contactItem = ContactItem()
            contactItem.setContactName(QString.fromUtf8(contact.name.toString()))
            contactItem.setData(QVariant(contact.uid), 40)
            
            groupItem.appendRow(contactItem)
