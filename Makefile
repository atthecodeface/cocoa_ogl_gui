all: plot

.PHONY:plot
plot:
	jbuilder build src/plot_obj/plot_obj.exe
	DYLD_LIBRARY_PATH=~/Git/cocoa_ogl_gui/_build/default/src/cocoa_ogl_gui/cocoa _build/default/src/plot_obj/plot_obj.exe

.PHONY:clean
clean:
	jbuilder clean

install:
	jbuilder build @install
	jbuilder install
