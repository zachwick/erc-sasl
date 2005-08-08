VERSION=5.1
SNAPDIR=erc-$(VERSION)

SPECIAL = erc-auto.el
UNCOMPILED = erc-chess.el erc-bbdb.el erc-ibuffer.el erc-speak.el \
		erc-speedbar.el erc-compat.el
TESTING = erc-members.el erc-macs.el
ALLSOURCE = $(wildcard *.el)
SOURCE	= $(filter-out $(SPECIAL) $(UNCOMPILED) $(TESTING),$(ALLSOURCE))
TARGET	= $(patsubst %.el,%.elc,$(SPECIAL) $(SOURCE))
MISC	= AUTHORS CREDITS HISTORY NEWS README Makefile ChangeLog \
		ChangeLog.2004 ChangeLog.2003 ChangeLog.2002 \
		ChangeLog.2001 servers.pl erc-auto.in
EMACS   = emacs

all: $(TARGET)

autoloads: erc-auto.el

erc-auto.el: erc-auto.in $(SOURCE)
	cp erc-auto.in erc-auto.el
	rm -f erc-auto.elc
	$(EMACS) --no-init-file --no-site-file -batch \
		-l $(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-auto \
		-f generate-autoloads \
		$(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-auto.el .

%.elc: %.el
	$(EMACS) --no-init-file --no-site-file -batch \
		-l $(shell pwd | sed -e 's|^/cygdrive/\([a-z]\)|\1:|')/erc-maint \
		-f batch-byte-compile $<

clean:
	-rm -f *~ *.elc

realclean: clean
	-rm -f $(TARGET) $(SPECIAL)

distclean:
	-rm -f $(TARGET)
	-rm -Rf ../$(SNAPDIR)

debrelease: $(ALLSOURCE) $(SPECIAL) distclean
	mkdir ../$(SNAPDIR) && chmod 0755 ../$(SNAPDIR)
	cp $(ALLSOURCE) $(SPECIAL) $(MISC) ../$(SNAPDIR)
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
	(cd ../$(SNAPDIR) && debuild -rfakeroot)

debrelease-mwolson:
	-rm -f ../../dist/erc_*
	-rm -f ../erc_$(VERSION)*
	$(MAKE) debrelease
	cp ../erc_$(VERSION)* ../../dist

release: autoloads distclean
	mkdir ../$(SNAPDIR) && chmod 0755 ../$(SNAPDIR)
	cp $(SPECIAL) $(UNCOMPILED) $(SOURCE) $(MISC) ../erc-$(VERSION)
	(cd .. && tar czf erc-$(VERSION).tar.gz erc-$(VERSION)/*; \
	  zip -r erc-$(VERSION).zip erc-$(VERSION))

todo:	erc.elc

upload:
	(cd .. && echo open ftp://upload.sourceforge.net > upload.lftp ; \
	  echo cd /incoming >> upload.lftp ; \
	  echo mput erc-$(VERSION).zip >> upload.lftp ; \
	  echo mput erc-$(VERSION).tar.gz >> upload.lftp ; \
	  echo close >> upload.lftp ; \
	  lftp -f upload.lftp ; \
	  rm -f upload.lftp)
