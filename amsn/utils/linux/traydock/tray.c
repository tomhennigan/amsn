#include <stdio.h>
#include <stdlib.h>
#include <X11/X.h>
#include <Imlib.h>
#include <string.h>
#include <tk.h>
#include <tcl.h>
#include <time.h>

#define XEMBED_MAPPED                   (1 << 0)
#define SYSTEM_TRAY_REQUEST_DOCK    0
#define SYSTEM_TRAY_BEGIN_MESSAGE   1
#define SYSTEM_TRAY_CANCEL_MESSAGE  2

#define IL_LAST(il)				\
{						\
	if (il != NULL){			\
		while (il->next != NULL) 	\
			il=(TrayIcon *)il->next; 	\
	}					\
}

#define IL_FIRST(il) 				\
{						\
	if (il != NULL){			\
		while (il->prev != NULL)	\
			il=(TrayIcon *)il->prev; 	\
	}					\
}

#define IL_APPEND(il,item)  			\
{						\
	if (il != NULL)			\
	{					\
		IL_LAST(il)			\
		il->next=(TrayIcon_ *)item; 	\
		item->prev=(TrayIcon_ *)il; 	\
		il=(TrayIcon *)il->next;   	\
	}else{					\
		il=item;			\
	}					\
}
	
#define IL_PREPEND(il,item)  			\
{						\
	if (il != NULL)				\
	{					\
		IL_FIRST(il)			\
		il->prev=(TrayIcon_ *)item; 	\
		item->next=(TrayIcon_ *)il; 	\
		il=(TrayIcon *)il->prev;   	\
	}else{					\
		il=item;			\
	}					\
}


typedef struct TrayIcon *TrayIcon_;
typedef struct {
	Tk_Window win;
	Pixmap pixmap;
	Pixmap mask;
	int w,h;
	char tooltip[256];
	TrayIcon_ *prev;
	TrayIcon_ *next;
	Window parent;
}TrayIcon;

static ImlibData *id;
static TrayIcon *iconlist=NULL;
static Tk_3DBorder border=NULL;
/* System tray window ID */
static Window systemtray;
static Display *display;
static int msgid=0;
Tcl_TimerToken timer=NULL;
static int tooltip=0;
Tcl_Interp * globalinterp;

/* Set embed information */
static void
xembed_set_info (Tk_Window window, unsigned long  flags)
{
   	unsigned long buffer[2];
 
	/* Get flags */
   	Atom xembed_info_atom = XInternAtom (display,"_XEMBED_INFO",0);
 
   	buffer[0] = 0;                /* Protocol version */
   	buffer[1] = flags;
 
	/* Change the property */
   	XChangeProperty (display,
                    Tk_WindowId(window),
                    xembed_info_atom, xembed_info_atom, 32,
                    PropModeReplace,
                    (unsigned char *)buffer, 2);
}

void send_message( Display* dpy,Window w,
		Atom type,long message, 
		long data1, long data2, long data3)
{
    	XEvent ev;
  
    	memset(&ev, 0, sizeof(ev));
    	ev.xclient.type = ClientMessage;
    	ev.xclient.window = w;
    	ev.xclient.message_type = type;
    	ev.xclient.format = 32;
    	ev.xclient.data.l[0] = time(NULL);
    	ev.xclient.data.l[1] = message;
    	ev.xclient.data.l[2] = data1;
    	ev.xclient.data.l[3] = data2;
    	ev.xclient.data.l[4] = data3;

		//trap_errors();
    	XSendEvent(dpy, w, False, NoEventMask, &ev);
    	XSync(dpy, False);
    //if (untrap_errors()) {
	/* Handle failure */
		//printf("Handle failure\n");
    //}
}

static unsigned char *get_wm_name() {
        int screen = DefaultScreen(display);
        Atom type;
        int format;
        long n_returned;
        long bytes_returned;
        unsigned char *buffer;

        Window root = RootWindow(display, screen);
        Window *child;
        Atom supwmcheck = XInternAtom(display, "_NET_SUPPORTING_WM_CHECK", False);
        Atom wmname = XInternAtom(display, "_NET_WM_NAME", False);

        XGetWindowProperty(display, root, supwmcheck, 0, 8, False, AnyPropertyType, &type, &format, &n_returned,
                        &bytes_returned, (unsigned char **)&child);

        if (n_returned != 1) return NULL;

        XGetWindowProperty(display, *child, wmname, 0, 128, False, AnyPropertyType, &type, &format, &n_returned,
                        &bytes_returned, &buffer);

        if (n_returned == 0) return NULL;

        XFree(child);
        return buffer;
}

/* Procedure that Docks the icon */
static void
DockIcon(ClientData clientData)
{

	Window root, parent, *children;
	int n, ret, atom;
	TrayIcon *icon= clientData;
	unsigned char* wm_name = get_wm_name();

	xembed_set_info(icon->win,XEMBED_MAPPED);

	Tk_MapWindow(icon->win);
	XQueryTree(display, Tk_WindowId(icon->win), &root, &parent, &children, &n);
	XFree(children);
	Tk_UnmapWindow(icon->win);

	if (wm_name != NULL && !strcmp(wm_name, "KWin")) {
		atom = XInternAtom(display, "_KDE_NET_WM_SYSTEM_TRAY_WINDOW_FOR", False);
		ret = XChangeProperty(display, parent, atom,
				XA_WINDOW, 32, PropModeReplace, (unsigned char *)&parent, 1);
		Tk_MapWindow(icon->win);
	} else {
		send_message(display,systemtray,XInternAtom (display, "_NET_SYSTEM_TRAY_OPCODE", False ),
				SYSTEM_TRAY_REQUEST_DOCK,Tk_WindowId(icon->win),0,0);
	}

	XFree(wm_name);
	
	icon->parent = parent;
}

/* Draw the icon */
static void
DrawIcon (ClientData clientData)
{
	TrayIcon *icon=clientData;
	int x,y,w,h,b,d;
	Window r;
	Pixmap mask;
	GC gc=NULL;
	XGCValues gcv;

	XGetGeometry(display, Tk_WindowId(icon->win), &r, &x, &y, &w, &h, &b, &d);
	Tk_Fill3DRectangle(icon->win, Tk_WindowId(icon->win),
		border, 0, 0,
		w,h,
		0,TK_RELIEF_FLAT);
	
	XCopyArea(display,icon->pixmap,Tk_WindowId(icon->win),
			DefaultGC(display,DefaultScreen(display)) 
			,0,0,icon->w,icon->h,(w-icon->w)/2, (h-icon->h)/2);
	
	
		
	mask =  XCreatePixmap(display, Tk_WindowId(icon->win), w, h, 1);
		
	gcv.foreground=0;
	gc =  XCreateGC(display, mask, GCForeground, &gcv);
	XFillRectangle(display, mask, gc , 0, 0, w, h);

	gcv.foreground=1;
	gcv.background=0;
	XChangeGC(display, gc, GCForeground, &gcv); 
	XFillRectangle(display, mask, gc , (w-icon->w)/2, (h-icon->h)/2, icon->w, icon->h);
	XCopyArea(display,icon->mask,mask,gc,0,0,icon->w,icon->h,(w-icon->w)/2, (h-icon->h)/2);
	
	XShapeCombineMask (display ,Tk_WindowId(icon->win), ShapeBounding, 0,0,mask,ShapeSet);
	XShapeCombineMask (display ,icon->parent, ShapeBounding, 0,0,mask,ShapeSet);

	XFreeGC(display,gc);	
}


static void show_tooltip (ClientData clientdata)
{
	TrayIcon *icon = (TrayIcon *)clientdata;
	if (icon->tooltip != NULL)
	{	
		tooltip=1;
//		printf ("%s\n",icon->tooltip);
	}
	timer=NULL;
}

static void remove_tooltip ()
{
	if (tooltip == 1)
	{
		tooltip=0;
	}
}


/* Callback function when a message arrives */
static int MessageEvent(
        Tk_Window tkwin,
        XEvent *eventPtr) {
//		  printf("Message\n");
}


/* Callback function when an event happens */
static void IconEvent(ClientData clientData, register XEvent *eventPtr) {
	int atom;
	int mask;
	TrayIcon *icon = (TrayIcon *)clientData;

	if ((eventPtr->type == Expose) && (eventPtr->xexpose.count == 0)) {
		if (icon->win != NULL)
			/*horrible hack to redraw the icon when dragging the dock aroun the panels*/
			Tcl_CreateTimerHandler(500, DrawIcon, icon);
		goto redraw;

	} else if (eventPtr->type == ConfigureNotify) {
		goto redraw;
	} else if (eventPtr->type == EnterNotify) {
		if (timer == NULL) {
			timer = Tcl_CreateTimerHandler(500, show_tooltip, icon);
		}
	} else if (eventPtr->type == LeaveNotify) {
		if (tooltip==1)
			remove_tooltip();
		if (timer != NULL) {
			Tcl_DeleteTimerHandler(timer);
			timer=NULL;
		}

	}

	return;

redraw:
    	if ((icon->win != NULL)) {
		Tcl_DoWhenIdle(DrawIcon, (ClientData) icon);
    	}
}

/* New tray icon procedure (newti command) */
static int Tk_TrayIconNew  (ClientData clientData,
		Tcl_Interp *interp,
		int objc,
		Tcl_Obj *CONST objv[]) {

	int n,test,found;
	char *arg,*pixmap=NULL;
	size_t length;
	Tk_Window mainw;
	unsigned int mask;
	TrayIcon *icon;
	ImlibImage *im;
	XSizeHints *hint;

	/* Get memory for trayicon data and zero it*/
	icon = (TrayIcon *) malloc(sizeof(TrayIcon));
	memset((void *) icon, 0, (sizeof(TrayIcon)));
	icon->next = icon->prev=NULL;
	
	mainw=Tk_MainWindow(interp);

	/* Get a Tk3DBorder object for later drawing */
	if (!border)
		border = Tk_Get3DBorder(interp, mainw, "white");

	/* systemtray was not available in Init */
	if (systemtray==0) {
		Tcl_AppendResult (interp, "cannot create a tray icon without a system tray", (char *) NULL);
		return TCL_ERROR;
	}

	/* Get the first argument string (object name) and check it */
	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	//printf("Arg: %s\n",arg);
	if (strncmp(arg,".",1)) {
		Tcl_AppendResult (interp, "bad path name: ",
			Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Search in the list if that trayicon window name already exists */
	//printf ("Searching for %s!!\n",arg);
	found=0;
	if (iconlist != NULL)
	{
		IL_FIRST(iconlist)
		
		while (1)
		{
			//printf ("Comparing with %s!!\n",Tk_PathName(iconlist->win));
			if (!strcmp(Tk_PathName(iconlist->win),arg))
			{
				found=1;
				break;
			}
			if (iconlist->next==NULL)
				break;
			iconlist=(TrayIcon *)iconlist->next;
		}

		if (found == 1)
		{
			Tcl_AppendResult (interp, "tray icon ",arg , " already exist", (char *) NULL);
			//printf ("Already exists error!!\n");
			return TCL_ERROR;
		}
	}

	/* Parse options */
	for (n=2;n<objc;n++) {
		arg=Tcl_GetStringFromObj(objv[n],(int *) &length);
		if (arg[0] == '-') {
			if (!strncmp(arg,"-pixmap",length)) {
				n++;
				/*Get pixmap name*/
				pixmap=Tcl_GetStringFromObj(objv[n],(int *) &length);
			} else if (!strncmp(arg,"-tooltip",length)) {
				/* Copy tooltip string */
				n++;
				strcpy (icon->tooltip,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else {
				Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
				return TCL_ERROR;
			}
		} else {
			Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
			return TCL_ERROR;
		}
	}

	/* If there's a pixmap file, load it */
	if (pixmap != NULL) {
		if ((test=open(pixmap,O_RDONLY))==-1) {
			Tcl_AppendResult (interp, "cannot open pixmap file ",pixmap , (char *) NULL);
			return TCL_ERROR;
		}
		close (test);

		/* Create the window */
		icon->win=Tk_CreateWindowFromPath(interp,mainw,
				Tcl_GetStringFromObj(objv[1],(int *) &length),"");

		DockIcon((ClientData)icon);
		
		/* Load image */
		im=Imlib_load_image(id,pixmap);
		Imlib_render(id,im,im->rgb_width,im->rgb_height);
		if ( im->rgb_width >24 || im->rgb_height > 24 ) 
		{
			im=Imlib_clone_scaled_image(id, im, 24,24);
			Imlib_render(id,im,24,24);
			icon->w=im->rgb_width;
			icon->h=im->rgb_height;
		} else {
			icon->w=im->rgb_width;
			icon->h=im->rgb_height;
		}
		
		/* Save it on the struct */
		icon->pixmap=Imlib_move_image(id,im);
   		icon->mask=Imlib_move_mask(id,im);
		
		/* Create callback function for event handling */
		mask = StructureNotifyMask | SubstructureNotifyMask | ExposureMask | PropertyChangeMask | EnterWindowMask | LeaveWindowMask
		  | PropertyNotify | ReparentNotify;
		Tk_CreateEventHandler(icon->win, mask, IconEvent, (ClientData) icon);
		Tk_CreateClientMessageHandler(MessageEvent);
		
		/* Set default icon size hint */
		hint = XAllocSizeHints();
		hint->flags |=PMinSize;
		hint->min_width=24;
		hint->min_height=24;
	
		XSetWMNormalHints(display,Tk_WindowId(icon->win),hint);
		XFree(hint);
	}else{
		Tcl_AppendResult (interp, "you must provide a pixmap file", (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Append icon to the icon list */
	IL_APPEND(iconlist,icon)
	
	/* Set result string and return OK */
	Tcl_SetResult(interp, Tk_PathName(icon->win), TCL_STATIC);
	return TCL_OK;
}

/* configureti command */
static int 
Tk_ConfigureIcon  (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	int n,test,found;
	char *arg,*pixmap=NULL;
	size_t length;
	ImlibImage *im;

	/* Check path name */
	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
	if (objc < 2)
	{
		Tcl_AppendResult (interp, "what do you want to configure?" , (char *) NULL);
		return TCL_ERROR;
	}
	
	/* Find icon in the list */
	found=0;
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(Tk_PathName(iconlist->win),arg))
		{
			found=1;
			break;
		}
		if (iconlist->next==NULL)
			break;
		iconlist=(TrayIcon *)iconlist->next;
	}

	if (found == 0)
	{
		Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
		return TCL_ERROR;
	}

		
	/* Parse arguments */
	for (n=2;n<objc;n++)
	{
		arg=Tcl_GetStringFromObj(objv[n],(int *) &length);
		if (arg[0] == '-')
		{
			if (!strncmp(arg,"-pixmap",length))
			{
				n++;
				pixmap=Tcl_GetStringFromObj(objv[n],(int *) &length);
			} else if (!strncmp(arg,"-tooltip",length))
			{
				n++;
				strcpy(iconlist->tooltip,Tcl_GetStringFromObj(objv[n],(int *) &length));
			} else {
				Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
				return TCL_ERROR;
			}
		}else{
			Tcl_AppendResult (interp, "unknown", arg,"option", (char *) NULL);
			return TCL_ERROR;
		}
	}

	if (pixmap != NULL)
	{
		if ((test=open(pixmap,O_RDONLY))==-1)
		{
			Tcl_AppendResult (interp, "cannot open pixmap file ",pixmap , (char *) NULL);
			return TCL_ERROR;
		}
		close (test);
						
		im=Imlib_load_image(id,pixmap);
		Imlib_render(id,im,im->rgb_width,im->rgb_height);
		if ( im->rgb_width >24 || im->rgb_height > 24 ) 
		{
			im=Imlib_clone_scaled_image(id, im, 24,24);
			Imlib_render(id,im,24,24);
			iconlist->w=im->rgb_width;
			iconlist->h=im->rgb_height;
		} else {
			iconlist->w=im->rgb_width;
			iconlist->h=im->rgb_height;
		}
		iconlist->pixmap=Imlib_move_image(id,im);
   		iconlist->mask=Imlib_move_mask(id,im);
		
		
    		Tcl_DoWhenIdle(DrawIcon, (ClientData) iconlist);
			
	}
	return TCL_OK;
}
/*static int 
Tk_TrayIconBalloon  (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	int found;
	char *arg=NULL;
	size_t length;
  

	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
	if (objc < 2)
	{
		Tcl_AppendResult (interp, "please give me a balloon message" , (char *) NULL);
		return TCL_ERROR;
	}
	
	found=0;
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(Tk_PathName(iconlist->win),arg))
		{
			found=1;
			break;
		}
		if (iconlist->next==NULL)
			break;
		iconlist=(TrayIcon *)iconlist->next;
	}

	if (found == 0)
	{
		Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
		return TCL_ERROR;
	}

	msgid++;
	
	arg = Tcl_GetStringFromObj(objv[2],(int *) &length);
	length--;

	send_message(display,systemtray,XInternAtom (display, "_NET_SYSTEM_TRAY_OPCODE", False ),
			SYSTEM_TRAY_BEGIN_MESSAGE,0,length,msgid);
	while (length > 0)
    	{
      		XClientMessageEvent ev;

      		ev.type = ClientMessage;
      		ev.window = Tk_WindowId(iconlist->win);
      		ev.format = 8;
      		ev.message_type = XInternAtom (display,
				     "_NET_SYSTEM_TRAY_MESSAGE_DATA", False);
      		if (length > 20)
		{
	  		memcpy (&ev.data, arg, 20);
	  		length -= 20;
	  		arg += 20;
		}
      		else
		{
	  		memcpy (&ev.data, arg, length);
	  		length = 0;
		}

      		XSendEvent (display,
		  	systemtray, False, NoEventMask, (XEvent *)&ev);
      		XSync (display, False);
    	}	
	return TCL_OK;
}*/

/* Removes the icon from the dock area */
static int 
Tk_RemoveIcon  (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	int found;
	char *arg=NULL;
	size_t length;
	TrayIcon *tmp=NULL;
	
	/* Check path */
	arg=Tcl_GetStringFromObj(objv[1],(int *) &length);
	if (strncmp(arg,".",1))
	{
		Tcl_AppendResult (interp, "bad path name: ",Tcl_GetStringFromObj(objv[1],(int *) &length) , (char *) NULL);
		return TCL_ERROR;
	}
		
	/* Find icon in the list */
	found=0;
	if (iconlist == NULL)
	{
		Tcl_AppendResult (interp, "create a tray icon first" , (char *) NULL);
		return TCL_ERROR;
	}

		
	IL_FIRST(iconlist)
		
	while (1)
	{
		if (!strcmp(Tk_PathName(iconlist->win),arg))
		{
			found=1;
			break;
		}
		if (iconlist->next==NULL)
			break;
		iconlist=(TrayIcon *)iconlist->next;
	}

	if (found == 0)
	{
		Tcl_AppendResult (interp, "tray icon not found: ",arg , (char *) NULL);
		return TCL_OK;
	}
	
	//XReparentWindow (display,Tk_WindowId(iconlist->win),DefaultRootWindow(display),0,0);
	printf("Destroying %s\n",Tk_PathName(iconlist->win));
	Tk_DestroyWindow(iconlist->win);
	
	/* Remove it from the list */
	if (iconlist->next == NULL && iconlist->prev == NULL)
	{
		free(iconlist);
		iconlist=NULL;
	} else if (iconlist->next==NULL)
	{
		tmp = (TrayIcon *)iconlist->prev;
		tmp->next=NULL;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	} else if (iconlist->prev==NULL)
	{
		tmp = (TrayIcon *)iconlist->next;
		tmp->prev=NULL;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	} else	{
		tmp = (TrayIcon *) iconlist->prev;
		tmp->next = iconlist->next;
		((TrayIcon *)tmp->next)->prev=(TrayIcon_ *)tmp;
		iconlist->prev=iconlist->next=NULL;
		free(iconlist);
		iconlist=tmp;
	}
		
	return TCL_OK;
}


static int 
Tk_SystemTrayAvailable  (ClientData clientData,
		Tcl_Interp *interp,
    		int objc,
    		Tcl_Obj *CONST objv[])
{
	Tcl_Obj *result;
	if (systemtray >0)
		result=Tcl_NewIntObj(1);
	else
		result=Tcl_NewIntObj(-1);
	
	Tcl_SetObjResult(interp, result);
	return TCL_OK;
}

/* Initialization procedure, called when loading the shared library */
int Tray_Init(Tcl_Interp *interp)
{
	char buffer[256];
	Atom a;
	Tk_Window mainwin;
	systemtray=0;

	globalinterp = interp;

	//Check TK version is 8.0 or higher
	if (Tk_InitStubs(interp, "8.0", 0) == NULL) {
		return TCL_ERROR;
	}

	//Get main window, and display
	mainwin=Tk_MainWindow(interp);
	display = Tk_Display(mainwin);

	/* Initialize imlib */
	id=Imlib_init(display);

	snprintf (buffer, sizeof (buffer), "_NET_SYSTEM_TRAY_S%d",
					XScreenNumberOfScreen(Tk_Screen(mainwin)));
     	/* Get the X11 Atom */
	a=XInternAtom (display,buffer, False);
	/* And get the window ID associated to that atom */
	systemtray=XGetSelectionOwner(display,a);

	/* Create the new trayicon commands */
	Tcl_CreateObjCommand(interp, "newti", Tk_TrayIconNew,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "configureti", Tk_ConfigureIcon,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "removeti", Tk_RemoveIcon,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "systemtray_exist", Tk_SystemTrayAvailable,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
    	/*Tcl_CreateObjCommand(interp, "tiballoon", Tk_TrayIconBalloon,
	    	(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);*/

    return TCL_OK;
}
