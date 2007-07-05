# $Id: subdir.mk,v 1.20 2007/07/05 08:12:04 tat Exp $
#
# Variables:
# - SUBDIR      A list of subdirectories that should be built as well.
#               Each of the targets will execute the same target in the
#               subdirectories.
#
# Applicable Targets:
# - any target (optionally with -pre and -post suffix)

# make filename used (Makefile, makefile, Makefile.subdir, mymakefile, etc.)
MAKEFILENAME = $(firstword $(MAKEFILE_LIST))

# additional flags
ifneq ($(strip $(MAKEFILENAME)),)
MAKE_ADD_FLAGS = -f $(MAKEFILENAME)
endif

ifdef HOOK_T

$(HOOK_T)-pre:
$(HOOK_T)-post:

else    # !HOOK_T

.PHONY: subdirs $(SUBDIR)

subdirs: $(SUBDIR)

# no explicit target, run make into subdirs
$(SUBDIR):
	@$(MAKE) SUBDIR_GOAL= -C $@ $(SUBDIR_GOAL)

ifndef SUBDIR_GOAL
# one or more explicit target has been provided. run $target-pre, make
# subdirs and $target-post
$(MAKECMDGOALS):
	@$(MAKE) $(MAKE_ADD_FLAGS) HOOK_T=$@ $@-pre
	@$(MAKE) $(MAKE_ADD_FLAGS) SUBDIR_GOAL=$@ subdirs
	@$(MAKE) $(MAKE_ADD_FLAGS) HOOK_T=$@ $@-post
endif

all: subdirs

endif   # HOOK_T
