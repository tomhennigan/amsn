# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'chatWindow.ui'
#
# Created: Wed Sep 24 13:45:23 2008
#      by: PyQt4 UI code generator 4.4.3
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

class Ui_ChatWindow(object):
    def setupUi(self, ChatWindow):
        ChatWindow.setObjectName("ChatWindow")
        ChatWindow.resize(559, 445)
        self.verticalLayout_3 = QtGui.QVBoxLayout(ChatWindow)
        self.verticalLayout_3.setObjectName("verticalLayout_3")
        self.splitter_2 = QtGui.QSplitter(ChatWindow)
        self.splitter_2.setOrientation(QtCore.Qt.Vertical)
        self.splitter_2.setObjectName("splitter_2")
        self.splitter = QtGui.QSplitter(self.splitter_2)
        self.splitter.setOrientation(QtCore.Qt.Horizontal)
        self.splitter.setObjectName("splitter")
        self.textEdit = QtGui.QTextEdit(self.splitter)
        self.textEdit.setObjectName("textEdit")
        self.layoutWidget = QtGui.QWidget(self.splitter)
        self.layoutWidget.setObjectName("layoutWidget")
        self.verticalLayout = QtGui.QVBoxLayout(self.layoutWidget)
        self.verticalLayout.setObjectName("verticalLayout")
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setObjectName("label")
        self.verticalLayout.addWidget(self.label)
        spacerItem = QtGui.QSpacerItem(20, 40, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.verticalLayout.addItem(spacerItem)
        self.layoutWidget1 = QtGui.QWidget(self.splitter_2)
        self.layoutWidget1.setObjectName("layoutWidget1")
        self.verticalLayout_2 = QtGui.QVBoxLayout(self.layoutWidget1)
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.toolBar = QtGui.QToolBar(self.layoutWidget1)
        self.toolBar.setMinimumSize(QtCore.QSize(0, 32))
        self.toolBar.setMaximumSize(QtCore.QSize(16777215, 32))
        self.toolBar.setSizeIncrement(QtCore.QSize(0, 32))
        self.toolBar.setBaseSize(QtCore.QSize(0, 32))
        self.toolBar.setAcceptDrops(True)
        self.toolBar.setMovable(False)
        self.toolBar.setObjectName("toolBar")
        self.verticalLayout_2.addWidget(self.toolBar)
        self.horizontalLayout = QtGui.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.inputWidget = QtGui.QTextEdit(self.layoutWidget1)
        self.inputWidget.setEnabled(True)
        self.inputWidget.setMinimumSize(QtCore.QSize(0, 0))
        self.inputWidget.setBaseSize(QtCore.QSize(0, 40))
        self.inputWidget.setObjectName("inputWidget")
        self.horizontalLayout.addWidget(self.inputWidget)
        self.label_2 = QtGui.QLabel(self.layoutWidget1)
        self.label_2.setObjectName("label_2")
        self.horizontalLayout.addWidget(self.label_2)
        self.verticalLayout_2.addLayout(self.horizontalLayout)
        self.verticalLayout_3.addWidget(self.splitter_2)
        self.horizontalLayout_2 = QtGui.QHBoxLayout()
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        self.statusIcon = QtGui.QLabel(ChatWindow)
        self.statusIcon.setMinimumSize(QtCore.QSize(24, 24))
        self.statusIcon.setMaximumSize(QtCore.QSize(24, 24))
        self.statusIcon.setObjectName("statusIcon")
        self.horizontalLayout_2.addWidget(self.statusIcon)
        self.statusText = QtGui.QLabel(ChatWindow)
        self.statusText.setObjectName("statusText")
        self.horizontalLayout_2.addWidget(self.statusText)
        self.verticalLayout_3.addLayout(self.horizontalLayout_2)
        self.actionInsert_Emoticon = QtGui.QAction(ChatWindow)
        self.actionInsert_Emoticon.setObjectName("actionInsert_Emoticon")
        self.actionNudge = QtGui.QAction(ChatWindow)
        self.actionNudge.setObjectName("actionNudge")
        self.toolBar.addAction(self.actionInsert_Emoticon)
        self.toolBar.addAction(self.actionNudge)

        self.retranslateUi(ChatWindow)
        QtCore.QMetaObject.connectSlotsByName(ChatWindow)

    def retranslateUi(self, ChatWindow):
        ChatWindow.setWindowTitle(QtGui.QApplication.translate("ChatWindow", "Form", None, QtGui.QApplication.UnicodeUTF8))
        self.label.setText(QtGui.QApplication.translate("ChatWindow", "Something here...", None, QtGui.QApplication.UnicodeUTF8))
        self.toolBar.setWindowTitle(QtGui.QApplication.translate("ChatWindow", "Quick Actions", None, QtGui.QApplication.UnicodeUTF8))
        self.label_2.setText(QtGui.QApplication.translate("ChatWindow", "Contact image", None, QtGui.QApplication.UnicodeUTF8))
        self.actionInsert_Emoticon.setText(QtGui.QApplication.translate("ChatWindow", "Insert Emoticon", None, QtGui.QApplication.UnicodeUTF8))
        self.actionNudge.setText(QtGui.QApplication.translate("ChatWindow", "Nudge", None, QtGui.QApplication.UnicodeUTF8))

