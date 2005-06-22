#include <X11/Xlib.h>
#include <Imlib.h>

int main(int argc, char* argv[]){
	Display *disp = NULL;
	Screen *scr = NULL;
	Visual *vis = NULL;
	Colormap cm;
	int depth;
	Window root = 0;
	char *filename;
	ImlibData *id;
	ImlibImage *im;
	int ret;
	
	if (argc != 2){
		printf("Bad usage : snapshot file\nWith file the output of the snapshot\n");
		return -1;
	}
	filename = argv[1];

	disp = XOpenDisplay(NULL);
	if (!disp)
		printf("Can't open X display.");
	
	id=Imlib_init(disp);
	
	scr = ScreenOfDisplay(disp, DefaultScreen(disp));
	vis = DefaultVisual(disp, DefaultScreen(disp));
	depth = DefaultDepth(disp, DefaultScreen(disp));
	cm = DefaultColormap(disp, DefaultScreen(disp));
	root = RootWindow(disp, DefaultScreen(disp));
	
	/*imlib_context_set_display(disp);
	imlib_context_set_visual(vis);
	imlib_context_set_colormap(cm);
	imlib_context_set_color_modifier(NULL);
	imlib_context_set_operation(IMLIB_OP_COPY);*/
	
	im = Imlib_create_image_from_drawable(id,root, 0, 0, 0, scr->width, scr->height);
	
	//Imlib_context_set_image(im);
	
	ret=Imlib_save_image(id, im, filename, 0);
	Imlib_destroy_image(id, im);
	return (ret == 0);
}
