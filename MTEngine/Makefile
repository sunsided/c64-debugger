# C64 Debugger Makefile by Kuba Skrzypnik
# amendments by Marcin "slajerek" Skoczylas

SRCDIR                = .
SUBDIRS               =
DLLS                  =
LIBS                  =
BINS		= c64debugger
CFLAGS		      = -w
CXXFLAGS	      = -w

#LDFLAGS		      = `pkg-config --libs gtk+-3.0 x11 gl libpng portaudio-2.0 xcb-util libjpeg ogg` -pthread
LDFLAGS		      = `pkg-config --libs gtk+-3.0 x11 gl xcb-util alsa` -pthread


CEXTRA                = 
CXXEXTRA              = 
RCEXTRA               =
#DEFINES               = -Og -g
DEFINES               =

### Ugly hack, will be fixed hopefully!
INCLUDE_PATH          = \
	`find Engine -iname "*.h" -printf "-I%h\n" | sort -u` \
	`find Games -iname "*.h" -printf "-I%h\n" | sort -u` \
	`find Linux -iname "*.h" -printf "-I%h\n" | sort -u` \
	`find Engine -iname "*.hpp" -printf "-I%h\n" | sort -u` \
	`find Games -iname "*.hpp" -printf "-I%h\n" | sort -u` \
	`find Linux -iname "*.hpp" -printf "-I%h\n" | sort -u` \
	`pkg-config --cflags gtk+-3.0 x11 gl`

OBJS     = $(MM_SRCS:.mm=.o) $(C_SRCS:.c=.o) $(CXX_SRCS:.cpp=.o) $(CC_SRCS:.cc=.o)

### Even worse!
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

C_SRCS                = $(call rwildcard,Engine,*c) $(call rwildcard,Games,*.c) $(call rwildcard,Linux,*c)
CXX_SRCS                = $(call rwildcard,Engine,*cpp) $(call rwildcard,Games,*.cpp) $(call rwildcard,Linux,*cpp)
CC_SRCS                = $(call rwildcard,Engine,*cc) $(call rwildcard,Games,*.cc) $(call rwildcard,Linux,*cc)
MM_SRCS                = $(call rwildcard,Engine,*mm) $(call rwildcard,Games,*.mm) $(call rwildcard,Linux,*mm)

CC = gcc
CXX = g++

all: $(SUBDIRS) $(LIBS) $(BINS)

.PHONY: all clean dummy
$(SUBDIRS): dummy
	@cd $@ && $(MAKE)

.SUFFIXES: .cpp .cxx .rc .mm .cc
DEFINCL = $(INCLUDE_PATH) $(DEFINES) $(OPTIONS)

.c.o:
	@echo "CC -- $@"
	@$(CC) -c $(CFLAGS) $(CEXTRA) $(DEFINCL) -o $@ $<

.cpp.o:
	@echo "CX -- $@"
	@$(CXX) -c $(CXXFLAGS) $(CXXEXTRA) $(DEFINCL) -o $@ $<

.cc.o:
	@echo "CX -- $@"
	@$(CXX) -c $(CXXFLAGS) $(CXXEXTRA) $(DEFINCL) -o $@ $<

### Seems like someone treats ObjC files like C++ ones, because XCode and things
### Please, don't. Note: this has been fixed in ImGui branch

.mm.o:
	@echo "MM -- $@"
	@$(CXX) -x c++ -c $(CXXFLAGS) $(CXXEXTRA) $(DEFINCL) -o $@ $<

clean: 
	$(RM) $(CLEAN_FILES)  $(C_SRCS:.c=.o) $(MM_SRCS:.mm=.o) $(CXX_SRCS:.cpp=.o) $(CC_SRCS:.cc=.o)
	$(RM) $(BINS)

c64debugger: $(OBJS)
	$(CXX) -o $@ $(OBJS) ${LDFLAGS} $(LIBRARY_PATH)  $(DEFLIB) 
	upx -9 c64debugger	
