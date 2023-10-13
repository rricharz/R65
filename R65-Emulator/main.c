/*
 * R65
 *
 * main.c
 * 
 * Copyright 2016  rricharz
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *  
 */
 
#define GDK_DISABLE_DEPRECATION_WARNINGS

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <cairo.h>
#include <gtk/gtk.h>
#include <math.h>

#include "main.h"
#include "R65.h"
#include "crt.h"
#include "fdc.h"
#include "fake6502.h"

GtkWidget *global_window;
cairo_surface_t *global_surface;
cairo_t *global_surface_cr;
int global_surface_has_been_updated;
int global_firstcall;
guint global_timeout_ref;
int cursorDisabled;
int exDisplay;
int fullscreen;
int pixelated;

struct tColor {
	double r, g, b;
} strokeColor, fillColor;

struct tClick {
	int button, x, y, down;
} global_click;

int global_char;

int windowWidth, windowHeight;
int crtWidth, crtHeight, crtOffset;
int panelSize, panelOffset;
double panelScale;

/////////////////////////////////////////////
void Background(double r, double g, double b)
/////////////////////////////////////////////
{
    cairo_set_source_rgb(global_surface_cr, r, g, b);
    cairo_rectangle (global_surface_cr, 0, 0, windowWidth, windowHeight);
    cairo_fill(global_surface_cr);
    global_surface_has_been_updated = TRUE;
}

/////////////////////////////////////////////////
void Crt_Background(double r, double g, double b)
/////////////////////////////////////////////////
{
    // cairo_set_source_rgb(global_surface_cr, r, g, b);
    Stroke(210, 210, 210); Fill(0, 0, 0, 0);
    Rect(crtOffset/2,  windowHeight - crtOffset/2,
        crtWidth + crtOffset, crtHeight + crtOffset);
    cairo_fill(global_surface_cr);
    global_surface_has_been_updated = TRUE;
}


////////////////////////////////
void Stroke(int r, int g, int b)
////////////////////////////////
{
	strokeColor.r = (double)r / 256.0;
	strokeColor.g = (double)g / 256.0;
	strokeColor.b = (double)b / 256.0;
}

/////////////////////////////////////////
void Fill(int r, int g, int b, int alpha)
/////////////////////////////////////////
{
	fillColor.r = (double)r / 256.0;
	fillColor.g = (double)g / 256.0;
	fillColor.b = (double)b / 256.0;
}

///////////////////////
void StrokeWidth(int w)
///////////////////////
{
	cairo_set_line_width (global_surface_cr, w);
}

/////////////////////////////////////
void Rect(int x, int y, int w, int h)
/////////////////////////////////////
{
	cairo_set_source_rgb(global_surface_cr, strokeColor.r, strokeColor.g, strokeColor.b);
	cairo_rectangle(global_surface_cr, x, y - h, w, h);
	cairo_stroke_preserve(global_surface_cr);
	cairo_set_source_rgb(global_surface_cr, fillColor.r, fillColor.g, fillColor.b);
	cairo_fill(global_surface_cr);
	global_surface_has_been_updated = TRUE;
}

/////////////////////////////////////////
void Line(int x1, int y1, int x2, int y2)
/////////////////////////////////////////
{
	cairo_set_source_rgb(global_surface_cr, strokeColor.r, strokeColor.g, strokeColor.b);
	cairo_move_to(global_surface_cr, x1, y1);
        cairo_line_to(global_surface_cr, x2, y2);
        cairo_stroke(global_surface_cr);
        global_surface_has_been_updated = TRUE;
}

////////////////////////////////
void Circle(int x, int y, int r)
////////////////////////////////
{
	cairo_set_source_rgb(global_surface_cr, strokeColor.r, strokeColor.g, strokeColor.b);
	cairo_arc(global_surface_cr, x, y, r / 2, 0, 2*M_PI);
	cairo_stroke_preserve(global_surface_cr);
        cairo_set_source_rgb(global_surface_cr, fillColor.r, fillColor.g, fillColor.b);
	cairo_fill(global_surface_cr);
	global_surface_has_been_updated = TRUE;
}

///////////////////////////////////////////////////////////////////////////////
void Text(int x, int y, char *s, char *fn, int fontSize, int erase, int bold)
///////////////////////////////////////////////////////////////////////////////
{
	cairo_text_extents_t extents;
	cairo_font_weight_t weight;
	if (bold)
	    weight = CAIRO_FONT_WEIGHT_BOLD;
	else
	    weight = CAIRO_FONT_WEIGHT_NORMAL;
	cairo_select_font_face(global_surface_cr, fn, CAIRO_FONT_SLANT_NORMAL, weight);
	cairo_set_font_size(global_surface_cr, fontSize);
	if (erase) {
		cairo_text_extents(global_surface_cr, s, &extents);
		cairo_set_source_rgb(global_surface_cr, fillColor.r, fillColor.g, fillColor.b);
		cairo_rectangle(global_surface_cr, x, 
		  y - extents.height - 1, 
		  extents.width + ((3 * fontSize) / 4), (7 * extents.height) / 5);
		cairo_fill(global_surface_cr);
	}
	cairo_set_source_rgb(global_surface_cr, strokeColor.r, strokeColor.g, strokeColor.b);
	cairo_move_to(global_surface_cr, x, y);
	cairo_show_text(global_surface_cr, s);	
	cairo_stroke(global_surface_cr);
	global_surface_has_been_updated = TRUE;
}

////////////////////////////////////////////////////////////
void TextMid(int x, int y, char *s, int fontSize, int erase)
////////////////////////////////////////////////////////////
{
	cairo_text_extents_t extents;
	cairo_select_font_face(global_surface_cr, "Monospace", CAIRO_FONT_SLANT_NORMAL,
	    CAIRO_FONT_WEIGHT_NORMAL);
	cairo_set_font_size(global_surface_cr, fontSize);
	cairo_text_extents(global_surface_cr, s, &extents);
	if (erase) {
		cairo_set_source_rgb(global_surface_cr, fillColor.r, fillColor.g, fillColor.b);
		cairo_rectangle(global_surface_cr, x, 
		  y - extents.height - 1, 
		  extents.width + ((3 * fontSize) / 4), (7 * extents.height) / 5);
		cairo_fill(global_surface_cr);
	}
	cairo_set_source_rgb(global_surface_cr, strokeColor.r, strokeColor.g, strokeColor.b);
	cairo_move_to(global_surface_cr, x - extents.width / 2, y);
	cairo_show_text(global_surface_cr, s);	
	cairo_stroke (global_surface_cr);
	global_surface_has_been_updated = TRUE;
}

////////////////////////////////////////
void Image(int x, int y, char *filename)
////////////////////////////////////////
{
	cairo_surface_t *image = cairo_image_surface_create_from_png(filename);
	if (image != NULL) {
		int h = cairo_image_surface_get_height(image);
		cairo_set_source_surface(global_surface_cr, image, x, y - h);
		cairo_paint(global_surface_cr);
	}
	cairo_surface_destroy(image);
	global_surface_has_been_updated = TRUE;
}

////////////////
void Paint(void)
////////////////
// force immediate redraw, if global surface has been updated
{
	if (global_surface_has_been_updated) {
		gtk_widget_queue_draw(global_window);
		while (gtk_events_pending())
			gtk_main_iteration();
		global_surface_has_been_updated = FALSE;
	}
}

/////////////////////////////
void Alert(char *s, int halt)
/////////////////////////////
{
	GtkWidget *dialog;
	if (!cursorDisabled) {   // do not show if cursor is disabled
		dialog = gtk_message_dialog_new(GTK_WINDOW(global_window), GTK_DIALOG_DESTROY_WITH_PARENT,
			GTK_MESSAGE_ERROR, GTK_BUTTONS_CLOSE, s, NULL, NULL);
		gtk_dialog_run(GTK_DIALOG (dialog));
		gtk_widget_destroy (dialog);
	}
	else
		printf("******** Alert! %s\n", s);
	if (halt)
		exit(1);
}

///////////////
void Quit(void)
///////////////
{
	gtk_main_quit();
}

////////////////////////
void disableCursor(void)
////////////////////////
{
	GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(global_window));
	gdk_window_set_cursor(gdk_window, gdk_cursor_new(GDK_BLANK_CURSOR));
	cursorDisabled = TRUE;
}

//////////////////////
void clearClicks(void)
//////////////////////
{
	while (gtk_events_pending())           // check for clicks
		gtk_main_iteration();
	global_click.button = 0;
	global_click.x      = 0;
	global_click.y      = 0;
	global_click.down   = 0;
}

///////////////////////////////
void checkClick(int *x, int *y)
///////////////////////////////
{
        while (gtk_events_pending())           // check for clicks
                gtk_main_iteration();
	*x = global_click.x;
        *y = global_click.y;		
	global_click.button = 0;
	global_click.x = 0;
	global_click.y = 0;
}

////////////////////////
void checkPendingEvents()
////////////////////////
{
    while (gtk_events_pending())            // check for gtk events
        gtk_main_iteration();
}

////////////////////////
int clickStillDown(void)
////////////////////////
{
	Paint();                               // update painting bevore waiting for input
	while (gtk_events_pending())           // check for clicks
		gtk_main_iteration();
	return global_click.down;
}

//////////////////////////////////////////////////////
static gboolean on_next_timer_event(GtkWidget *widget)
//////////////////////////////////////////////////////
// Updates the screen (and blinks the cursor, if uncommented)
{
        global_surface_has_been_updated = FALSE;
        g_source_remove(global_timeout_ref);    // stop timer, in case crtUpdate takes too long
        // global_pendingCrtUpdate = TRUE;
        // crtUpdate();
	if (global_surface_has_been_updated)
		gtk_widget_queue_draw(widget);
	global_timeout_ref = g_timeout_add(TIME_INTERVAL,
			(GSourceFunc) on_next_timer_event, (gpointer) global_window);  // restart timer
	return TRUE;
}

///////////////////////////////////////////////////////
static gboolean on_first_timer_event(GtkWidget *widget)
///////////////////////////////////////////////////////
// starts the interpreter
{
        global_surface_has_been_updated = FALSE;
        global_timeout_ref = g_timeout_add(TIME_INTERVAL,
			(GSourceFunc) on_next_timer_event, (gpointer) global_window);  // timer
        r65Loop();                      // start interpreting and stay there
	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////////
static gboolean on_draw_event(GtkWidget *widget, cairo_t *cr, gpointer user_data)
/////////////////////////////////////////////////////////////////////////////////
{  	
	if (global_firstcall) {
		global_surface = cairo_surface_create_similar(cairo_get_target(cr),
			CAIRO_CONTENT_COLOR_ALPHA, windowWidth, windowHeight);
		global_surface_cr = cairo_create(global_surface);
		global_surface_has_been_updated = FALSE;
		global_firstcall = FALSE;
                // add a first timer event to start interpreting
		global_timeout_ref = g_timeout_add(0,
			(GSourceFunc) on_first_timer_event, (gpointer) global_window);
	}
	
	cairo_set_source_surface(cr, global_surface, 0, 0);
	cairo_paint(cr);
	
	return FALSE;
}

/////////////////////////////////////////////////////////////////////////////////////
static gboolean clicked(GtkWidget *widget, GdkEventButton *event, gpointer user_data)
/////////////////////////////////////////////////////////////////////////////////////
{
        global_click.button = event->button;
        global_click.x      = event->x;
        global_click.y      = event->y;
        global_click.down   = 1;
        // printf("Clicked %d, %d\n", global_click.x, global_click.y);
        
        return TRUE;
}

//////////////////////////////////////////////////////////////////////////////////////
static void released(GtkWidget *widget, GdkEventButton *event, gpointer user_data)
//////////////////////////////////////////////////////////////////////////////////////
{
	global_click.down   = 0;
}

///////////////////////////
static void on_quit_event()
///////////////////////////
{
	r65Quit();
        gtk_main_quit();
        exit(0);
}

//////////////////////////////////
void QuitProgram(int shutDownFlag)
//////////////////////////////////
{
        r65Quit();
        gtk_main_quit();
        if (shutDownFlag)
          system("sudo shutdown -h now");
        exit(0);
}

///////////////////////////////////////////////////////////////////////////////////
static void on_key_press(GtkWidget *widget, GdkEventKey *event, gpointer user_data)
///////////////////////////////////////////////////////////////////////////////////
{
    // printf("key pressed, state =%04X, keyval=%04X\n", event->state, event->keyval);
        
    // control keys
    if (event->state & GDK_CONTROL_MASK) {
        if (event->keyval == 0xFF53)      // control cursor right -> insert
            global_char = 0x15;
        else if (event->keyval == 0xFF52) // control cursor up -> roll up
            global_char = 0x08;
        else if (event->keyval == 0xFF54) // control cursor down -> roll down
            global_char = 0x02;
        else if (event->keyval == 0xFF08) // control rubout -> delete
            global_char = 0x19;
        else if (event->keyval == 0xFF0D) // control return -> clear to end of screen
            global_char = 0x11;
        else if (event->keyval == 0xFF51) // control cursor left-> delete
            global_char = 0x19;
            
        else global_char = event->keyval & 0x1F;
    }
                
    // shift special keys
    else if ((event->state & GDK_SHIFT_MASK) && ((event->keyval &  0xFF00) == 0xFF00)) {
        global_char = event->keyval & 0xFEFF;
        // printf("Shift key %04x\n",global_char);
        if (global_char == 0xFE1B)  {    // <shift> ESC: execute NMI
            pendingNMI = 1;      
            global_char = 0;
            return;
        }
        else if (global_char == 0xFEEB)  {    // <shift> menu: execute QUIT
            QuitProgram(0);      
            return;
        }
        else if (global_char == 0xFEE7)  {    // <shift> ALT: execute QUIT and SHUTDOWN
            QuitProgram(1);      
            return;
        }
        else global_char = event->keyval & 0x1F;
    }
                
    // normal keys
    else {
        if ((event->keyval == 0xFFE1) || (event->keyval == 0xFFE3)) return;
        global_char = event->keyval;
        }
                
    setKeyboardInterrupt();
}

/////////////////////////////////
int main (int argc, char *argv[])
/////////////////////////////////
{
    GtkWidget *darea;
	
    int firstArg = 1;
        
    exDisplay  = FALSE;
    fullscreen = FALSE;
    pixelated      = FALSE;
	
    while (firstArg < argc) {
	if (strcmp(argv[firstArg],"-full") == 0)
	    fullscreen = TRUE;
	else if (strcmp(argv[firstArg],"-extern") == 0)
	    exDisplay = TRUE;  
	else if (strcmp(argv[firstArg],"-pixelated") == 0)
	    pixelated = TRUE; 
        else {
            printf("R65: unknown argument %s\n", argv[firstArg]);
        }
        firstArg++;
    }
      
    gtk_init(&argc, &argv);
	
    global_firstcall = TRUE;
    cursorDisabled = FALSE;
	
    clearClicks();

    global_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    darea = gtk_drawing_area_new();
    gtk_container_add(GTK_CONTAINER(global_window), darea);
    gtk_widget_add_events(global_window, GDK_BUTTON_PRESS_MASK);
    gtk_widget_add_events(global_window, GDK_BUTTON_RELEASE_MASK);
    gtk_widget_add_events(global_window, GDK_KEY_PRESS_MASK);
        	
    GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(global_window));
    int screenWidth = gdk_screen_get_width(screen);
    int screenHeight = gdk_screen_get_height(screen);
    printf("Screen dimensions: %d x %d\n", screenWidth, screenHeight);
        
    if (fullscreen) {	    
	// DISPLAY UNDECORATED MAXIMIZED WINDOW
	gtk_window_set_decorated(GTK_WINDOW(global_window), FALSE);
	gtk_window_fullscreen(GTK_WINDOW(global_window));
	windowWidth  = screenWidth;
	windowHeight = screenHeight;
	panelScale = (double)(windowWidth) / (double)(MIN_WINDOW_WIDTH);
    }	
    else {
	// DISPLAY DECORATED WINDOW
	gtk_window_set_decorated(GTK_WINDOW(global_window), TRUE);
	gtk_window_set_default_size(GTK_WINDOW(global_window),
		MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT);
	windowWidth  = MIN_WINDOW_WIDTH;
	windowHeight = MIN_WINDOW_HEIGHT;
	panelScale = 1.0;
    }
    printf("Window dimensions: %d x %d\n", windowWidth, windowHeight);
    
    crtOffset = windowHeight / 15;
    crtHeight = windowHeight - (2 * crtOffset);
    // Aspect ratio of original display
    crtWidth  = 4 * crtHeight / 3;
    
    panelOffset = crtWidth +  (2 * crtOffset); 
    panelSize   = windowWidth -panelOffset - ( crtOffset / 2);
    printf("PanelOffset: %d\n", panelOffset, windowHeight);
	
    gtk_window_set_title(GTK_WINDOW(global_window), WINDOW_NAME);
	
    g_signal_connect(G_OBJECT(darea), "draw",  G_CALLBACK(on_draw_event), NULL);
    g_signal_connect(G_OBJECT(global_window), "destroy", G_CALLBACK(on_quit_event), NULL);
    g_signal_connect(G_OBJECT(global_window), "button-press-event", G_CALLBACK(clicked), NULL);
    g_signal_connect(G_OBJECT(global_window), "button-release-event", G_CALLBACK(released), NULL);
    g_signal_connect(G_OBJECT(global_window), "key_press_event", G_CALLBACK(on_key_press), NULL);

	
    if (strlen(ICON_NAME) > 0) {
	gtk_window_set_icon_from_file(GTK_WINDOW(global_window), ICON_NAME, NULL);	
    }

    gtk_widget_show_all(global_window);
	
    r65Setup();

    gtk_main();

	return 0;
}
