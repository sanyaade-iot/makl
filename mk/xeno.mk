#
# $Id: xeno.mk,v 1.17 2007/02/25 10:58:15 tat Exp $
# 
# User Variables:
#
#   - XENO_NAME             Package name
#
#   - XENO_FETCH            Tool to use to retrieve the package srcs or other
#   - XENO_FETCH_FLAGS      Arguments to $XENO_FETCH
#   - XENO_FETCH_URI        Remote resource name
#   - XENO_FETCH_LOCAL      Local resource name
#   - XENO_FETCH_TREE       True if package is fetched as src tree (e.g. cvs)
#   - XENO_NO_FETCH         If set the fetch: target is skipped
#
#   - XENO_UNZIP            Tarball decompression command
#   - XENO_UNZIP_FLAGS      Arguments to be passed to $XENO_UNZIP
#   - XENO_UNZIP_FLAGS_POST Arguments to be passed to $XENO_UNZIP after the 
#                           tarball argument (e.g '-C' argument to tar)
#   - XENO_NO_UNZIP         If set the unzip: target is skipped
#
#   - XENO_PATCH            Patch command
#   - XENO_PATCH_FLAGS      Arguments to be passed to $XENO_PATCH
#   - XENO_PATCH_URI		Remote patch URI (if you need to download it)
#   - XENO_PATCH_FILE       Local patch file
#   - XENO_NO_PATCH         If set the patch: target is skipped
#
#   - XENO_CONF             Configure script to be used
#   - XENO_CONF_FLAGS       Arguments to be passed to $XENO_CONF
#   - XENO_NO_CONF          If set the conf: target is skipped
#
#   - XENO_BUILD            Build command
#   - XENO_BUILD_FLAGS      Arguments to be passed to $XENO_BUILD
#   - XENO_UNBUILD          Unbuild command
#   - XENO_UNBUILD_FLAGS    Arguments to be passed to $XENO_UNBUILD
#   - XENO_BUILD_DIR        Where the package top-level build driver resides
#   - XENO_NO_BUILD         If set the build: target is skipped
#
#   - XENO_INSTALL          Install command
#   - XENO_INSTALL_FLAGS    Arguments to be passed to $XENO_INSTALL
#   - XENO_UNINSTALL        Uninstall command
#   - XENO_UNINSTALL_FLAGS  Arguments to be passed to $XENO_UNINSTALL
#   - XENO_NO_INSTALL       If set the install: target is skipped
#
# Applicable Targets:
# - all, clean, purge, fetch{,-clean,-purge}, unzip{,-clean,-purge}, 
#   patch{,-clean,-purge}, conf{,-clean,-purge}, build{,-clean,-purge}, 
#   install{,-clean,-purge}

#
# Set sensible defaults
#
XENO_TARBALL ?= $(notdir $(XENO_FETCH_URI))
XENO_NAME ?= $(firstword                        \
        $(sort                                  \
            $(foreach ext, $(XENO_UNZIP_EXTS),  \
                $(patsubst %$(ext), %, $(XENO_TARBALL)))))

XENO_FETCH ?= wget
XENO_FETCH_FLAGS ?= --passive-ftp
XENO_FETCH_LOCAL ?= $(XENO_TARBALL)

XENO_UNZIP ?= tar
XENO_UNZIP_FLAGS ?= zxvf
XENO_UNZIP_EXTS ?= .tar.bz2 .tbz .tar.gz .tgz .tbz2

XENO_CONF ?= ./configure

XENO_PATCH ?= patch
XENO_PATCH_FLAGS ?= -p1 <

XENO_BUILD ?= $(MAKE)
XENO_UNBUILD ?= $(XENO_BUILD)
XENO_INSTALL ?= $(XENO_BUILD)
XENO_UNBUILD_FLAGS ?= clean
XENO_INSTALL_FLAGS ?= install
XENO_BUILD_DIR ?= $(XENO_NAME)

XENO_DIST_DIR ?= dist

#
# Test preconditions
#
ifndef XENO_FETCH_URI
    ifndef XENO_TARBALL
        $(error XENO_FETCH_URI or XENO_TARBALL must be set when including the \
                xeno.mk template !)
    endif   # !XENO_TARBALL
endif   # !XENO_FETCH_URI

##
## all target (with hooks)
##
all: all-hook-pre fetch unzip patch conf build install all-hook-post
all-hook-pre all-hook-post:

##
## clean target (actions are called in the reverse order)
##
clean: clean-hook-pre install-clean build-clean conf-clean patch-clean \
       unzip-clean fetch-clean clean-hook-post
clean-hook-pre clean-hook-post:

##
## purge target (actions are called in the reverse order)
##
purge: purge-hook-pre install-purge build-purge conf-purge patch-purge \
       unzip-purge fetch-purge purge-hook-post
purge-hook-pre purge-hook-post:

##
## preconditions (in the forward and backward directions)
##
fetch-pre:
unzip-pre: .realfetch
patch-pre: unzip-pre .realunzip
conf-pre: patch-pre .realpatch
build-pre: conf-pre .realconf
install-pre:  build-pre .realbuild

fetch-clean-pre: unzip-clean unzip-clean-pre
unzip-clean-pre: patch-clean patch-clean-pre
patch-clean-pre: conf-clean conf-clean-pre
conf-clean-pre: build-clean build-clean-pre
build-clean-pre: install-clean install-clean-pre
install-clean-pre:

##
## fetch{,-clean,-purge} targets
##
ifndef XENO_NO_FETCH
fetch: .realfetch

.realfetch: 
	@$(MAKE) fetch-pre fetch-hook-pre fetch-make fetch-hook-post
	@touch $@

fetch-make: 
	@echo "==> fetching $(XENO_NAME) from $(XENO_FETCH_URI)"
ifndef XENO_FETCH_TREE
	@if [ ! -d $(XENO_DIST_DIR) ]; then \
	    mkdir $(XENO_DIST_DIR); \
	fi ; \
	if [ ! -f $(XENO_DIST_DIR)/$(XENO_FETCH_LOCAL) ]; then \
	    (cd $(XENO_DIST_DIR) && \
            set $(XENO_FETCH_URI) ; \
            while [ $$# -gt 0 ] ; \
            do \
                $(XENO_FETCH) $(XENO_FETCH_FLAGS) $$1 ; \
                ret=$$? ; \
                [ $$ret = 0 ] && break ; \
                shift ; \
            done ; \
            [ $$ret = 0 ] || exit $$ret) ; \
	fi;
else    # XENO_FETCH_TREE
	@set $(XENO_FETCH_URI) ; \
	while [ $$# -gt 0 ] ; \
	do \
	    $(XENO_FETCH) $(XENO_FETCH_FLAGS) $$1 ; \
	    ret=$$? ; \
	    [ $$ret = 0 ] && break ; \
	    shift ; \
	done ; \
    [ $$ret = 0 ] || exit $$ret ;
endif   # !XENO_FETCH_TREE

fetch-hook-pre fetch-hook-post:

fetch-clean: fetch-clean-pre
	@rm -f .realfetch

fetch-purge: fetch-realpurge fetch-clean

fetch-realpurge:
ifndef XENO_FETCH_TREE
	@rm -f $(XENO_DIST_DIR)/$(XENO_FETCH_LOCAL)
	@rmdir $(XENO_DIST_DIR) 2>/dev/null || true
else    # XENO_FETCH_TREE
	@rm -rf $(XENO_BUILD_DIR)
endif   # !XENO_FETCH_TREE

else    # XENO_NO_FETCH
fetch .realfetch: fetch-pre
	@touch .realfetch

fetch-clean fetch-purge: fetch-clean-pre
	@rm -f .realfetch

endif   # !XENO_NO_FETCH

##
## unzip{,-clean,-purge} targets
##
ifndef XENO_NO_UNZIP
unzip: .realunzip

.realunzip: 
	@$(MAKE) unzip-pre unzip-hook-pre unzip-make unzip-hook-post
	@touch $@

unzip-make:
	@echo "==> unzipping $(XENO_TARBALL)"
	@$(XENO_UNZIP) $(XENO_UNZIP_FLAGS) $(XENO_DIST_DIR)/$(XENO_TARBALL) \
        $(XENO_UNZIP_FLAGS_POST)

unzip-hook-pre unzip-hook-post:

unzip-clean: unzip-clean-pre
	@rm -f .realunzip

unzip-purge: unzip-realpurge unzip-clean

unzip-realpurge:
	@rm -rf $(XENO_NAME)

else    # XENO_NO_UNZIP
unzip .realunzip: unzip-pre
	@touch .realunzip

unzip-clean unzip-purge: unzip-clean-pre
	@rm -f .realunzip

endif   # !XENO_NO_UNZIP

##
## patch{,-clean,-purge} targets
##
ifdef XENO_PATCH_URI

ifndef XENO_PATCH_FILE
XENO_PATCH_FILE ?= $(notdir $(XENO_PATCH_URI))

$(XENO_PATCH_FILE):
	@if [ ! -f $(XENO_DIST_DIR)/$(XENO_PATCH_FILE) ]; then \
		(cd $(XENO_DIST_DIR) && \
		 $(XENO_FETCH) $(XENO_FETCH_FLAGS) $(XENO_PATCH_URI)) ; \
	 fi
endif

patch-fetch: $(XENO_PATCH_FILE) 
else
patch-fetch: 
endif

ifdef XENO_PATCH_FILE

patch: .realpatch

.realpatch: 
	@$(MAKE) patch-fetch patch-pre patch-hook-pre patch-make patch-hook-post
	@touch $@

patch-make:
	@echo "==> patching $(XENO_NAME) with $(XENO_PATCH_FILE)"
	@(cd $(XENO_NAME) && \
            $(XENO_PATCH) $(XENO_PATCH_FLAGS) $(XENO_DIST_DIR)/$(XENO_PATCH_FILE))

patch-hook-pre patch-hook-post:

patch-clean: patch-clean-pre
	@rm -f .realpatch

patch-purge: patch-realpurge patch-clean

patch-realpurge:
ifdef XENO_PATCH_URI
	@rm -f $(XENO_PATCH_FILE)
endif

else    # XENO_PATCH_FILE
patch .realpatch: patch-pre
	@touch .realpatch

patch-clean patch-purge: patch-clean-pre
	@rm -f .realpatch

endif   # !XENO_PATCH_FILE

##
## conf{,-clean,-purge} targets
##
ifndef XENO_NO_CONF
conf: .realconf

.realconf: 
	@$(MAKE) conf-pre conf-hook-pre conf-make conf-hook-post
	@touch $@

conf-make:
	@echo "==> configuring in $(XENO_BUILD_DIR)/"
	@(cd $(XENO_BUILD_DIR) && $(XENO_CONF) $(XENO_CONF_FLAGS))

conf-hook-pre conf-hook-post:

conf-clean: conf-clean-pre
	@rm -f .realconf

conf-purge: conf-clean

else    # XENO_NO_CONF

conf .realconf: conf-pre
	@touch .realconf

conf-clean conf-purge: conf-clean-pre
	@rm -f .realconf

endif   # !XENO_NO_CONF

##
## build{,-clean,-purge} targets
##
ifndef XENO_NO_BUILD
build: .realbuild

.realbuild: 
	@$(MAKE) build-pre build-hook-pre build-make build-hook-post
	@touch $@

build-make:
	@echo "==> building in $(XENO_BUILD_DIR)/"
	@(cd $(XENO_BUILD_DIR) && $(XENO_BUILD) $(XENO_BUILD_FLAGS))

build-hook-pre build-hook-post:

build-clean: build-clean-pre
	@echo "==> cleaning up in $(XENO_BUILD_DIR)/"
	@if [ -d $(XENO_BUILD_DIR) ]; then \
	    (cd $(XENO_BUILD_DIR) && $(XENO_UNBUILD) $(XENO_UNBUILD_FLAGS)) \
	fi;
	@rm -f .realbuild

build-purge: build-clean

else    # XENO_NO_BUILD

build .realbuild: build-pre
	@touch .realbuild

build-clean build-purge: build-clean-pre
	@rm -f .realbuild

endif   # !XENO_NO_BUILD

##
## install{,-clean,-purge} targets
##
ifndef XENO_NO_INSTALL
install: .realinstall

.realinstall: 
	@$(MAKE) install-pre install-hook-pre install-make install-hook-post
	@touch $@

install-make:
	@echo "==> installing $(XENO_NAME)"
	@(cd $(XENO_BUILD_DIR) && $(XENO_INSTALL) $(XENO_INSTALL_FLAGS))

install-hook-pre install-hook-post:

install-clean: install-clean-pre
ifdef XENO_UNINSTALL
	@(cd $(XENO_BUILD_DIR) && $(XENO_UNINSTALL) $(XENO_UNINSTALL_FLAGS))
endif
	@rm -f .realinstall

install-purge: install-clean

else    # XENO_NO_INSTALL
install .realinstall: install-pre
	@touch .realinstall

install-clean install-purge: install-clean-pre
	@rm -f .realinstall

endif   # !XENO_NO_INSTALL
