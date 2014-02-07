WEBFETCH                := wget
SHA1SUM                 := sha1sum

ALL                     += libvirt-python
libvirt-python-URL1    := http://mirror.onelab.eu/third-party/libvirt-python-1.2.1.tar.gz
libvirt-python-URL2    := http://planet-lab.org/third-party/libvirt-python-1.2.1.tar.gz
libvirt-python-SHA1SUM        := 874014e3b1b199919d40a34f12829fa1d610a2ea
libvirt-python                := $(notdir $(libvirt-python-URL1))

all: $(ALL)
.PHONY: all

##############################
define download_target
$(1): $($(1))
.PHONY: $(1)
$($(1)): 
	@if [ ! -e "$($(1))" ] ; then \
	{ echo Using primary; echo "$(WEBFETCH) $($(1)-URL1)" ; $(WEBFETCH) $($(1)-URL1) ; } || \
	{ echo Using secondary; echo "$(WEBFETCH) $($(1)-URL2)" ; $(WEBFETCH) $($(1)-URL2) ; } ; fi
	@if [ ! -e "$($(1))" ] ; then echo "Could not download source file: $($(1)) does not exist" ; exit 1 ; fi
	@if test "$$$$($(SHA1SUM) $($(1)) | awk '{print $$$$1}')" != "$($(1)-SHA1SUM)" ; then \
	    echo "sha1sum of the downloaded $($(1)) does not match the one from 'Makefile'" ; \
	    echo "Local copy: $$$$($(SHA1SUM) $($(1)))" ; \
	    echo "In Makefile: $($(1)-SHA1SUM)" ; \
	    false ; \
	else \
	    ls -l $($(1)) ; \
	fi
endef

$(eval $(call download_target,libvirt-python))

# install libvirt-devel
$(shell yum localinstall /longbuildroot/RPMS/x86_64/libvirt-devel-1.2.1-0.x86_64.rpm)

sources: $(ALL) 
.PHONY: sources

####################
# default - overridden by the build
SPECFILE = libvirt-python.spec

PWD=$(shell pwd)
PREPARCH ?= noarch
RPMDIRDEFS = --define "_sourcedir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)"
BUILDOPTS = --with python3 --define 'packager PlanetLab'

trees: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps -bp --target $(PREPARCH) $(SPECFILE)

srpm: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps -bs $(SPECFILE)

TARGET ?= $(shell uname -m)
rpm: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps --target $(TARGET) $(BUILDOPTS) -bb $(SPECFILE)

clean:
	rm -f *.rpm *.tgz *.bz2 *.gz

++%: varname=$(subst +,,$@)
++%:
		@echo "$(varname)=$($(varname))"
+%: varname=$(subst +,,$@)
+%:
		@echo "$($(varname))"

