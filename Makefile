VERSION=5.2
SNAPDIR=erc-$(VERSION)
LASTUPLOAD = 5.1.4-4
BUILDOPTS  =

SPECIAL = erc-auto.el
UNCOMPILED = erc-bbdb.el erc-chess.el erc-ibuffer.el erc-speak.el \
		erc-speedbar.el erc-compat.el

# Files to include in the extras pack for Emacs 22
EXTRAS  = erc-bbdb.el erc-chess.el erc-list.el erc-speak.el \
		 README.extras COPYING

ALLSOURCE = $(wildcard *.el)
SOURCE	= $(filter-out $(SPECIAL) $(UNCOMPILED), $(ALLSOURCE))
TARGET	= $(patsubst %.el,%.elc,$(SPECIAL) $(SOURCE))
MANUAL  = erc
MISC	= AUTHORS COPYING CREDITS HISTORY NEWS README Makefile ChangeLog \
		ChangeLog.06 ChangeLog.05 ChangeLog.04 ChangeLog.03 \
		ChangeLog.02 ChangeLog.01 \
		servers.pl erc-auto.in erc.texi

EMACS       = emacs
SITEFLAG    = --no-site-file

PREFIX   = /usr/local
ELISPDIR = $(PREFIX)/share/emacs/site-lisp/erc
INFODIR  = $(PREFIX)/info

# XEmacs users will probably want the following settings.
#EMACS    = xemacs
#SITEFLAG = -no-site-file

INSTALLINFO = install-info --info-dir=$(INFODIR)

# If you're using Debian, uncomment the following line and comment out
#the above line.
#INSTALLINFO = install-info --section "Emacs" "emacs" --info-dir=$(INFODIR)

all: lisp $(MANUAL).info

lisp: $(TARGET) 

autoloads: erc-auto.el

erc-auto.el: erc-auto.in $(SOURCE)
	cp erc-auto.in erc-auto.el
	rm -f erc-auto.elc
	@$(EMACS) -q $(SITEFLAG) -batch \
		-l $(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-auto \
		-f erc-generate-autoloads \
		$(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-auto.el .

%.elc: %.el
	@$(EMACS) -q $(SITEFLAG) -batch \
		-l $(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-maint \
		-f batch-byte-compile $<

%.info: %.texi
	makeinfo $<

%.html: %.texi
	makeinfo --html --no-split $<

doc: $(MANUAL).info $(MANUAL).html

clean:
	-rm -f *~ *.elc

realclean: clean
	-rm -f $(MANUAL).info $(MANUAL).html $(TARGET) $(SPECIAL)

install-info: $(MANUAL).info
	[ -d $(INFODIR) ] || install -d $(INFODIR)
	install -m 0644 $(MANUAL).info $(INFODIR)/$(MANUAL)
	$(INSTALLINFO) $(INFODIR)/$(MANUAL)

install-bin: lisp
	install -d $(ELISPDIR)
	install -m 0644 $(ALLSOURCE) $(TARGET) $(ELISPDIR)

install: install-bin install-info

distclean:
	-rm -f $(MANUAL).info $(MANUAL).html $(TARGET)
	-rm -Rf ../$(SNAPDIR)

debprepare: $(ALLSOURCE) $(SPECIAL) distclean
	mkdir ../$(SNAPDIR) && chmod 0755 ../$(SNAPDIR)
	cp $(ALLSOURCE) $(SPECIAL) $(MISC) ../$(SNAPDIR)
	cp -r images ../$(SNAPDIR)
	test -d ../$(SNAPDIR)/images/.arch-ids && rm -R \
	  ../$(SNAPDIR)/images/.arch-ids || :
	test -d ../$(SNAPDIR)/images/CVS && rm -R \
	  ../$(SNAPDIR)/images/.arch-ids || :

debbuild:
	(cd ../$(SNAPDIR) && \
	  dpkg-buildpackage -v$(LASTUPLOAD) $(BUILDOPTS) \
	    -us -uc -rfakeroot && \
	  echo "Running lintian ..." && \
	  lintian -i ../erc_$(VERSION)*.deb || : && \
	  echo "Done running lintian." && \
	  debsign)

debrelease: debprepare
	-rm -f ../../dist/erc_*
	-rm -f ../erc_$(VERSION)*
	(cd .. && tar -czf erc_$(VERSION).orig.tar.gz $(SNAPDIR))
	cp -R debian ../$(SNAPDIR)
	test -d ../$(SNAPDIR)/debian/CVS && rm -R \
	  ../$(SNAPDIR)/debian/CVS \
	  ../$(SNAPDIR)/debian/maint/CVS \
	  ../$(SNAPDIR)/debian/scripts/CVS || :
	test -d ../$(SNAPDIR)/debian/.arch-ids && rm -R \
	  ../$(SNAPDIR)/debian/.arch-ids \
	  ../$(SNAPDIR)/debian/maint/.arch-ids \
	  ../$(SNAPDIR)/debian/scripts/.arch-ids || :
	$(MAKE) debbuild
	cp ../erc_$(VERSION)* ../../dist

debrevision:
	-rm -f ../../dist/erc_*
	-rm -f ../erc_$(VERSION)-*
	-rm -fr ../erc-$(VERSION)
	$(MAKE) debprepare
	cp -R debian ../$(SNAPDIR)
	test -d ../$(SNAPDIR)/debian/CVS && rm -R \
	  ../$(SNAPDIR)/debian/CVS \
	  ../$(SNAPDIR)/debian/maint/CVS \
	  ../$(SNAPDIR)/debian/scripts/CVS || :
	test -d ../$(SNAPDIR)/debian/.arch-ids && rm -R \
	  ../$(SNAPDIR)/debian/.arch-ids \
	  ../$(SNAPDIR)/debian/maint/.arch-ids \
	  ../$(SNAPDIR)/debian/scripts/.arch-ids || :
	$(MAKE) debbuild
	cp ../erc_$(VERSION)* ../../dist

release: autoloads distclean
	mkdir ../$(SNAPDIR) && chmod 0755 ../$(SNAPDIR)
	cp $(SPECIAL) $(UNCOMPILED) $(SOURCE) $(MISC) ../$(SNAPDIR)
	cp -r images ../$(SNAPDIR)
	test -d ../$(SNAPDIR)/images/CVS && \
	  rm -R ../$(SNAPDIR)/images/CVS || :
	test -d ../$(SNAPDIR)/images/.arch-ids && \
	  rm -R ../$(SNAPDIR)/images/.arch-ids || :
	(cd .. && tar czf erc-$(VERSION).tar.gz $(SNAPDIR)/*; \
	  zip -r erc-$(VERSION).zip $(SNAPDIR))

extras:
	-rm -Rf ../$(SNAPDIR)-extras
	mkdir ../$(SNAPDIR)-extras && chmod 0755 ../$(SNAPDIR)-extras
	cp $(EXTRAS) ../$(SNAPDIR)-extras
	(cd .. && tar czf erc-$(VERSION)-extras.tar.gz $(SNAPDIR)-extras/*; \
	  zip -r erc-$(VERSION)-extras.zip $(SNAPDIR)-extras)

upload:
	(cd .. && gpg --detach erc-$(VERSION).tar.gz && \
	  gpg --detach erc-$(VERSION).zip && \
	  echo "Directory: erc" | gpg --clearsign > \
	    erc-$(VERSION).tar.gz.directive.asc && \
	  cp erc-$(VERSION).tar.gz.directive.asc \
	    erc-$(VERSION).zip.directive.asc && \
	  echo open ftp://ftp-upload.gnu.org > upload.lftp ; \
	  echo cd /incoming/ftp >> upload.lftp ; \
	  echo mput erc-$(VERSION).zip* >> upload.lftp ; \
	  echo mput erc-$(VERSION).tar.gz* >> upload.lftp ; \
	  echo close >> upload.lftp ; \
	  lftp -f upload.lftp ; \
	  rm -f upload.lftp)

upload-extras:
	(cd .. && gpg --detach erc-$(VERSION)-extras.tar.gz && \
	  gpg --detach erc-$(VERSION)-extras.zip && \
	  echo "Directory: erc" | gpg --clearsign > \
	    erc-$(VERSION)-extras.tar.gz.directive.asc && \
	  cp erc-$(VERSION)-extras.tar.gz.directive.asc \
	    erc-$(VERSION)-extras.zip.directive.asc && \
	  echo open ftp://ftp-upload.gnu.org > upload.lftp ; \
	  echo cd /incoming/ftp >> upload.lftp ; \
	  echo mput erc-$(VERSION)-extras.zip* >> upload.lftp ; \
	  echo mput erc-$(VERSION)-extras.tar.gz* >> upload.lftp ; \
	  echo close >> upload.lftp ; \
	  lftp -f upload.lftp ; \
	  rm -f upload.lftp)
