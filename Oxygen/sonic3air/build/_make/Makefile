# This Makefile is primarily used for building the Switch version.

.DEFAULT_GOAL := all

NAME		=  sonic3air
BUILD_STRING	= `grep BUILD_STRING ../../source/sonic3air/version.inc | cut -d'"' -f2`
BUILD_VARIANT	= `grep BUILD_VARIANT ../../source/sonic3air/version.inc | cut -d'"' -f2`
SUFFIX		=  
PKGCONFIG	=  pkg-config
DEBUG		?= 0
STATIC		?= 1
VERBOSE		?= 0
PROFILE		?= 0
STRIP		?= strip
BASEDIR		?= ../../../..

CFLAGS		?= -std=c++17 -Wno-psabi

ENDUSER		?= 1

ifeq ($(ENDUSER),1)
	DEFINES += -DENDUSER
endif

# =============================================================================
# Detect default platform if not explicitly specified
# (Mostly unused, most platforms use CMake)
# =============================================================================

ifdef EMSCRIPTEN
	PLATFORM = Emscripten
endif

ifndef PLATFORM
	ifeq ($(OS),Windows_NT)
		PLATFORM = Windows
		ARCH ?= $(shell gcc -dumpmachine)
	else
		UNAME_S := $(shell uname -s)

		ifeq ($(UNAME_S),Linux)
			PLATFORM = Linux
			ARCH ?= $(shell gcc -dumpmachine)
		endif

		ifeq ($(UNAME_S),Darwin)
			PLATFORM = macOS
			ARCH ?= $(shell gcc -dumpmachine)
		endif
	endif
endif

PLATFORM ?= Unknown

# =============================================================================

OUTDIR = bin/$(PLATFORM)
OBJDIR = obj/$(PLATFORM)

ifdef ARCH
	OUTDIR := $(OUTDIR)/$(ARCH)
	OBJDIR := $(OBJDIR)/$(ARCH)
endif

include Makefile_cfgs/Platforms/$(PLATFORM).cfg

# =============================================================================

ifeq ($(STATIC),1)
	PKGCONFIG +=  --static
endif

ifeq ($(DEBUG),1)
	CFLAGS += -g2
	STRIP = :
	DEFINES += -DDEBUG
else
	CFLAGS += -g0 -O3
endif

ifeq ($(PROFILE),1)
	CFLAGS += -pg -g -fno-inline-functions -fno-inline-functions-called-once -fno-optimize-sibling-calls -fno-default-inline
endif

ifeq ($(VERBOSE),0)
	CC := @$(CC)
	CXX := @$(CXX)
endif

ifeq ($(VERBOSE),2)
	CFLAGS += -v
endif

# =============================================================================

CFLAGS += `$(PKGCONFIG) --cflags sdl2 ogg vorbis theora vorbisfile theoradec zlib minizip`
LIBS   += `$(PKGCONFIG) --libs-only-l --libs-only-L sdl2 ogg vorbis theora vorbisfile theoradec zlib minizip`

ifeq ($(STATIC),1)
	CFLAGS += -static
endif

INCLUDES  += \
				-I$(BASEDIR)/Oxygen/lemonscript/source \
				-I$(BASEDIR)/Oxygen/oxygenengine/source \
				-I$(BASEDIR)/Oxygen/sonic3air/source \
				-I$(BASEDIR)/librmx/source \
				-I$(BASEDIR)/Oxygen/sonic3air/source/external

INCLUDES += $(LIBS)

# Main Sources: globbed like the CMake build (the old hand-written list was stale)
SRCDIRS := \
	Oxygen/lemonscript/source/lemon \
	Oxygen/oxygenengine/source/oxygen \
	Oxygen/oxygenengine/source/oxygen_netcore \
	Oxygen/sonic3air/source/sonic3air
SOURCES += $(patsubst $(BASEDIR)/%.cpp,%,$(shell find $(addprefix $(BASEDIR)/,$(SRCDIRS)) -name '*.cpp'))
SOURCES += $(patsubst $(BASEDIR)/%.cpp,%,$(wildcard \
	$(BASEDIR)/librmx/source/rmxbase/*.cpp \
	$(BASEDIR)/librmx/source/rmxbase/_jsoncpp/*.cpp \
	$(BASEDIR)/librmx/source/rmxmedia/*.cpp \
	$(BASEDIR)/librmx/source/rmxext_oggvorbis/*.cpp))

# =============================================================================

PKGSUFFIX ?= $(SUFFIX)

BINPATH = $(OUTDIR)/$(NAME)$(SUFFIX)
PKGPATH = $(OUTDIR)/$(NAME)$(PKGSUFFIX)

OBJECTS += $(addprefix $(OBJDIR)/, $(addsuffix .o, $(SOURCES)))

$(shell mkdir -p $(OUTDIR))
$(shell mkdir -p $(OBJDIR))

$(OBJDIR)/%.o: $(BASEDIR)/%.c
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CC) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(OBJDIR)/%.o: $(BASEDIR)/%.cpp
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CXX) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(BINPATH): $(OBJDIR) $(OBJECTS)
	@echo -n Linking...
	$(CXX) $(CFLAGS) $(LDFLAGS) $(OBJECTS) $(LIBPATHS) $(LIBS) -o $@ 
	@echo " Done!"
	$(STRIP) $@

ifeq ($(BINPATH),$(PKGPATH))
all: $(BINPATH)
else
all: $(PKGPATH)
endif

clean:
	rm -rf $(OBJDIR)