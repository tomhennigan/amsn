TkCXimage: A Tk binding to the CXimage library


CxImage is a C++ class that can load, save, display, transform images in a very simple and fast way.

CxImage is open source and licensed under the zlib license. In a nutshell, this means that you can use the code however you wish, as long as you don't claim it as your own.

With more than 200 functions, and with comprehensive working demos, CxImage offers all the tools to build simple image processing applications on a fast learning curve. Supported file formats are: BMP, GIF, ICO, CUR, JBG, JPG, JPC, JP2, PCX, PGX, PNG, PNM, RAS, SKA, TGA, TIF, WBMP, WMF, RAW, CRW, NEF, CR2, DNG, ORF, ARW, ERF, 3FR, DCR, X3F, MEF, RAF, MRW, PEF, SR2.

Cximage is highly portable and has been tested with Visual C++ 6 / 2008, C++ Builder 3 / 6, MinGW on Windows, and with gcc 3.3.2 on Linux. The library can be linked statically, or through a DLL or an activex component.

TkCximage was developed for the aMSN chat client by the aMSN team. It provides a significant subset of CXimage's capabilities, including loading, converting, resizing, cropping, colorizing, blending, thumbnailing, and more, and can be called from Tcl/Tk. While TkCXimage was developed specifically for aMSN, its robust image processing capabilities make it a good replacement for the TkImg package. For documentation of what TkCXimage can do, please see "demo.tcl" in the demos directory. Currently the source code is the only documentation, but it is clearly structured and named.

While CXimage itself is available under the zlib license, TkCximage is available under the LGPL version 2.1. Please see "licence.txt" for the license details. 

Currently the only way to build TkCXimage is to run "configure; make" in the toplevel aMSN directory, available from aMSN's SVN repository at http://www.amsn-project.net. This will build all binary modules for aMSN on Linux/MacOSX systems, and possibly Windows. 

TkCXimage author: The aMSN Team.
TkCXimage documentation: Kevin Walzer, kw@codebykevin.com
