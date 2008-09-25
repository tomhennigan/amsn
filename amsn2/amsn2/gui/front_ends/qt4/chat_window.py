from amsn2.gui import base

from PyQt4.QtCore import *
from PyQt4.QtGui import *
from ui_chatWindow import Ui_ChatWindow
    
class aMSNChatWindow(QTabWidget, base.aMSNChatWindow):
    def __init__(self, amsn_core, Parent=None):
        QTabWidget.__init__(self, Parent)
        
        self._core(amsn_core)
        
    def addChatWidget(self, chat_widget):
        self.addTab(chat_widget, "test")
        
    
class aMSNChatWidget(QWidget, base.aMSNChatWidget):
    def __init__(self, Parent=None):
        QWidget.__init__(self, Parent)
        # TODO: Init chat window code from amsn core here
        
        self.ui = Ui_ChatWindow()
        self.ui.setupUi(self)
        
        self.loadEmoticonList()
        
        QObject.connect(self.ui.inputWidget, SIGNAL("textChanged()"), self.processInput)
        QObject.connect(self.ui.actionInsert_Emoticon, SIGNAL("triggered()"), self.showEmoticonList)
        """ These connections needs to be revisited, since they should probably point
        to an interface method """
        self.enterShortcut = QShortcut("Enter", self.ui.inputWidget)
        QObject.connect(self.enterShortcut, SIGNAL("activated()"), self.sendMessage)
        
        QObject.connect(self.ui.actionNudge, SIGNAL("triggered()"), self.nudge)
        

    def processInput(self):
        """ Here we process what is inside the widget... so showing emoticon
        and similar stuff"""
        
        QObject.disconnect(self.ui.inputWidget, SIGNAL("textChanged()"), self.processInput)
        
        self.text = QString(self.ui.inputWidget.toHtml())
                
        for emoticon in self.emoticonList:
            if self.text.contains(emoticon) == True:
                print emoticon
                self.text.replace(emoticon, "<img src=\"throbber.gif\" />")
                
        self.ui.inputWidget.setHtml(self.text)
        self.ui.inputWidget.moveCursor(QTextCursor.End)
        
        QObject.connect(self.ui.inputWidget, SIGNAL("textChanged()"), self.processInput)
        
    def sendMessage(self):
        print "To Implement"
        
    def loadEmoticonList(self):
        self.emoticonList = QStringList()
        
        """ TODO: Request emoticon list from amsn core, maybe use a QMap to get the image URL? """
        
        """ TODO: Discuss how to handle custom emoticons. We have to provide an option
        to change the default icon theme, this includes standard emoticons too.
        Maybe qrc? """
        
        self.emoticonList << ";)" << ":)" << "EmOtIcOn"
        
    def showEmoticonList(self):
        """ Let's popup emoticon selection here """
        print "Guess what? No emoticons. But I'll put in a random one for you"
        self.appendImageAtCursor("throbber.gif")
        
    def nudge(self):
        print "Driiiiin!!!"
        
    def appendTextAtCursor(self, text):
        self.ui.inputWidget.textCursor().insertHtml(str(text))
        
    def appendImageAtCursor(self, image):
        self.ui.inputWidget.textCursor().insertHtml(QString("<img src=\"" + str(image) + "\" />"))
        
    def onUserJoined(self, contact):
        textEdit.append("<b>"+sender.name+" "+this.tr("has joined the conversation")+("</b><br>"))
        pass

    def onUserLeft(self, contact):
        textEdit.append("<b>"+contact.name+" "+this.tr("has left the conversation")+("</b><br>"))
        pass

    def onUserTyping(self, contact):
        self.ui.statusText.setText(QString(contact.name + " is typing"))

    def onMessageReceived(self, sender, message):
        print "Ding!"
        textEdit.append("<b>"+sender.name+" "+this.tr("writes:")+("</b><br>"))
        textEdit.append(message.toString())
        pass

    def onNudgeReceived(self, sender):
        textEdit.append("<b>"+sender.name+" "+this.tr("sent you a nudge!")+("</b><br>"))
        pass
        
