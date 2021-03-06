# $Id: solaris.mk,v 1.4 2008/11/07 05:52:54 tho Exp $
#
# Solaris

ifdef SHLIB

SHLIB_OBJS = $(OBJS:.o=.so)
SHLIB_MAJOR ?= 0
SHLIB_MINOR ?= 0

##
## automatic rules for shared objects
##
.SUFFIXES: .so $(ALL_EXTS)

$(foreach e,$(C_EXTS),$(addsuffix .so,$(e))):
	$(CC) -fPIC $(CFLAGS) -c $< -o $*.so

##
## Set library naming vars
##
SHLIB_LINK ?= lib$(__LIB).so
SONAME ?= $(SHLIB_LINK).$(SHLIB_MAJOR)
SHLIB_NAME ?= $(SONAME).$(SHLIB_MINOR)

##
## build rules
##
all-shared: $(SHLIB_NAME)

$(SHLIB_NAME): $(SHLIB_OBJS)
	@echo "===> building shared $(__LIB) library"
	$(RM) -f $(SHLIB_NAME) $(SHLIB_LINK) $(SONAME)
	ln -sf $(SHLIB_NAME) $(SHLIB_LINK)
	ln -sf $(SHLIB_NAME) $(SONAME)
	$(__CC) -shared -o $(SHLIB_NAME) -Wl,-h,$(SONAME) \
	    `$(LORDER) $(SHLIB_OBJS) | $(TSORT)`

$(SHLIBDIR):
	$(MKINSTALLDIRS) "$(SHLIBDIR)"
ifneq ($(strip $(__CHOWN_ARGS)),)
	chown $(__CHOWN_ARGS) "$(SHLIBDIR)"
endif

install-shared: $(SHLIBDIR)
	$(INSTALL) $(__INSTALL_ARGS) -m $(LIBMODE) $(SHLIB_NAME) "$(SHLIBDIR)"
	ln -sf $(SHLIB_NAME) "$(SHLIBDIR)/$(SHLIB_LINK)"
	ln -sf $(SHLIB_NAME) "$(SHLIBDIR)/$(SONAME)"

uninstall-shared:
	$(RM) -f "$(SHLIBDIR)/$(SHLIB_NAME)"
	$(RM) -f "$(SHLIBDIR)/$(SHLIB_LINK)"
	$(RM) -f "$(SHLIBDIR)/$(SONAME)"
	-rmdir "$(SHLIBDIR)" 2>/dev/null

clean-shared:
	$(RM) -f $(SHLIB_OBJS)
	$(RM) -f $(SHLIB_NAME) $(SHLIB_LINK) $(SONAME)

endif
