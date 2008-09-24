
from AppKit import *
from amsn2.gui import base

class Image(object):
    """ This interface will represent an image to be used by the UI"""
    def __init__(self, amsn_core, parent):
		"""Initialize the interface. You should store the reference to the core in here """
		self._img = NSImage.alloc().initWithSize_((1,1))

    def load(self, resource_name, value):
        """ This method is used to load an image using the name of a resource and a value for that resource
            resource_name can be :
                - 'File', value is the filename
                - 'Skin', value is the skin key
                - some more :)
        """
        self._img.release()
        
        if (resource_name == 'File'):
            self._img = NSImage.alloc().initWithContentsOfFile_(str(value))

    def append(self, resource_name, value):
        """ This method is used to overlap an image on the current image
            Have a look at the documentation of the 'load' method for the meanings of 'resource_name' and 'value'
        """
        raise NotImplementedError

    def prepend(self, resource_name, value):
        """ This method is used to underlap an image under the current image
            Have a look at the documentation of the 'load' method for the meanings of 'resource_name' and 'value'
        """
        raise NotImplementedError
