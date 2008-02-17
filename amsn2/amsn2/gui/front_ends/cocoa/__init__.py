
from amsn2 import gui
import sys

# Here we load the actual front end.
# We need to import the front end module and return it
# so the guimanager can access its classes
def load():
    import cocoa
    return cocoa

# Initialize the front end by checking for any
# dependency then register it to the guimanager
try:
    import imp

    # try to find any necessary module
    # imp.find_module()
    gui.GUIManager.registerFrontEnd("cocoa", sys.modules[__name__])
    
except ImportError:
    pass
        
