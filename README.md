Description
===========

This is a collection of small **dirty** hacks I have written along the time
and that are all about creation of website (collection of HTML pages and
classical files).

They are not guaranteed to work nor be completed nor even to be useful.

They are all written to be used as command line tool and with the least
dependency possible. They are mainly written in perl.

- `get-element` -- print specified HTML elements data (or attribute value)

- `htmltoc` -- generate table of contents from headings in (x)HTML

- `htmltree` -- print HTML tree

- `mkweb` -- create a static website using source and template files

- `set-element` -- replace specified HTML elements data with some given content

The one I used more is `mkweb` which is self documented: look at the code or
at the file [`mkweb.md`](mkweb.md) which is an automatic extraction of
it. This one is not written in perl but in GNU makefile.


Others tools of same interest
=============================

* Genpage: http://www.xemacs.org/genpage/www/


Things to be done
=================

other tools to write
--------------------

* generate_menu (parameters may be max-depth)

* generate_breadcrumbs

mkweb
-----

  * Fix BUGS (`grep FIXME: *`)

  * Add tests

  * Add support of comments (lines starting by # sign) in `.keep` and `.ignore`
    files

  * Enhance content position determination in template file.

    Since we deal with HTML files, content should be determined by a specific id
    attribute of some tag and not through some free text stored in
    `START_CONTENT` and `STOP_CONTENT` variables.

    If that is how to be changed the *old* behavior should be preserved and the
    new one offered only through some flag variables.
   
  * Complete behavior should be simplified.

  * `CMD_KEEP` should be avoided to be more efficient.

    File action determination (determining if a file need to processed or
    copied) is ugly because it use a call to a process $(shell) make functions
    for each file in the `DO_HTML` variables.

    A more efficient way should be investigated. The most efficient way should
    determined that information only once.

* `CMD_TEMPLATE` should bed verified.

    See the `FIXME:` before `$(DESTINATION)/%.html` target in mkweb source.
