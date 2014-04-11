`grep FIXME: *` to get what has to be fixed.

mkweb
=====

  * when a filename contains a quote it cannot be copied, since it is used in
    `CMD_COPY` to protect other special characters.
  
  * when a `.keep` or `.ignore` file is modified nothing is remade.
  
  * check should use `DO_CHECK_GNUCMD` for `cp` or else `DO_COPY` may not work
    under MacOS X for instance.
  
  * when files list is too long list-build does not work due to shell line
    length limitation.
  
  * hard-linking files may produce side effect.
  
    When `TEMPLATE` is more recent than an .html file which need to be keeped
    and which is on the same filesystem as the destination file (thus is
    hard-linked only) the source file is reprocessed (`KEEP_COPY`). This may
    be time consuming.
    
    Every time a `TEMPLATE` is modified, such source files should be restamped
    so that they are newer. This is not really a bug, but more a kind of a bad
    behavior, or side effect of the use of hard link.
