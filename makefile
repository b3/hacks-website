.PHONY:build-doc
build-doc:
	sed -n \
-e '/define QUICKDOC/,/export QUICKDOC/ p' \
-e '/define DOC/,/export DOC/ p' \
-e '/define HELP/,/export HELP/ p' \
mkweb \
| \
sed -r \
-e '/^\#\#+/ d' \
-e 's/^\# //g' \
-e 's/^\#$$//g' \
-e 's/^define (.*)$$/# \1\n/' \
-e '/endef/ d' \
-e 's/^export.*$$//' \
> mkweb.md

.PHONY: fixme
fixme:
	grep -r FIXME: * | sed -re 's/^([^:]*:).*(FIXME:)/\1 \2/'

.PHONY: clean
clean:
	rm mkweb.md
	find . -name '*~' -delete
