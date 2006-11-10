#
# $Id: Makefile,v 1.11 2006/11/10 18:08:55 tho Exp $
#

MAKL_ROOT_DIR = $(shell pwd)
MAKL_VERSION = $(shell cat $(MAKL_ROOT_DIR)/VERSION)
MAKLRC ?= $(MAKL_ROOT_DIR)/makl.env
LOGIN_SHELL ?= bash

all help:
	@echo
	@echo "# MaKL version $(MAKL_VERSION) - (c) 2005-2006 - KoanLogic srl"
	@echo "Available targets:"
	@echo
	@echo "   * help        print this menu"
	@echo "   * hints       output environment variables"
	@echo "   * toolchain   install platform toolchain files"
	@echo "   * env         generate a file containing runtime MaKL variables"
	@echo "   * clean       remove autogenerated toolchain files"
	@echo
ifndef MAKL_DIR
	@echo "In order for MaKL to run properly, you must set the MAKL_DIR"
	@echo "environment variable.  Type 'make hints' to get an help."
	@echo
endif    

toolchain:
	@setup/shlib_setup.sh $(MAKL_PLATFORM)
	@setup/toolchain_setup.sh $(MAKL_PLATFORM)

env:
	@setup/env_setup.sh $(MAKL_DIR) $(MAKL_VERSION) $(LOGIN_SHELL) $(MAKLRC)
 
hints:
	@setup/shell_setup.sh $(MAKL_ROOT_DIR)

clean:
	rm -f $(MAKL_ROOT_DIR)/etc/toolchain.mk
	rm -f $(MAKL_ROOT_DIR)/etc/toolchain.cf
	rm -f $(MAKL_ROOT_DIR)/mk/shlib.mk
