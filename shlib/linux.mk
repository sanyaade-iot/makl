# $Id: linux.mk,v 1.8 2007/06/22 08:15:33 tho Exp $
#
# Linux

ifdef SHLIB

SHLIB_OBJS = $(OBJS:.o=.so)
SHLIB_MAJOR ?= 0
SHLIB_MINOR ?= 0

#
# automatic rules for shared objects
#
.SUFFIXES: .so .c .cc .C .cpp .cxx

.c.so:
	$(CC) $(CPICFLAGS) -DPIC $(CFLAGS) -c $< -o $*.so

.cc.so .C.so .cpp.so .cxx.so:
	$(CXX) $(CPICFLAGS) -DPIC $(CXXFLAGS) -c $< -o $*.so

#
# set library naming vars
#
SHLIB_LINK ?= lib$(__LIB).so
SONAME ?= $(SHLIB_LINK).$(SHLIB_MAJOR)
SHLIB_NAME ?= $(SONAME).$(SHLIB_MINOR)

#
# build rules
#
all-shared: $(SHLIB_NAME)

$(SHLIB_NAME): $(SHLIB_OBJS)
	@echo "===> building shared $(__LIB) library"
	rm -f $(SHLIB_NAME) $(SHLIB_LINK)
	ln -sf $(SHLIB_NAME) $(SHLIB_LINK)
	$(CC) -shared -Wl,-soname,$(SONAME) \
	    -o $(SHLIB_NAME) \
	    `$(LORDER) $(SHLIB_OBJS) | $(TSORT)` $(LDADD) ${LDFLAGS} 

install-shared:
	$(INSTALL) $(__INSTALL_ARGS) -m $(LIBMODE) $(SHLIB_NAME) $(RELOC)$(LIBDIR)
	ln -sf $(SONAME) $(RELOC)$(LIBDIR)/$(SHLIB_LINK)
	ln -sf $(SHLIB_NAME) $(RELOC)$(LIBDIR)/$(SONAME)

uninstall-shared:
	rm -f $(RELOC)$(LIBDIR)/$(SHLIB_NAME)
	rm -f $(RELOC)$(LIBDIR)/$(SHLIB_LINK)
	rm -f $(RELOC)$(LIBDIR)/$(SONAME)

clean-shared:
	rm -f $(SHLIB_OBJS)
	rm -f $(SHLIB_NAME) $(SHLIB_LINK)

endif
