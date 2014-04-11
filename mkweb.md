# QUICKDOC

1. Create a template html file such as :

        +-- template.html -----------------------------+
        | <html>                                       |
        |   <head></head>                              |
        |   <body>                                     |
        |     <h1>My website</h1>                      |
        |     <!-- @START_CONTENT@ -->                 |
        |     <p>Content will come here</p>            |
        |     <p>Use this file to set up your CSS.</p> |
        |     <!-- @END_CONTENT@ -->                   |
        |   </body>                                    |
        | </html>                                      |
        +----------------------------------------------+

2. Create source files containing content such as :

        +-- welcome.html -------------------------------------------+
        | <p>Welcome guys</p>                                       |
        | <p>                                                       |
        |    In this website you will not find anything interesting |
        |    about <a href="about/me.html">me</a>                   |
        | </p>                                                      |
        +-----------------------------------------------------------+
   
        +-- about/me.html -----------------------------------------------------+
        | <p>You have been warned !</p>                                        |
        | <p>Nothing here, go back <a href="@ROOT@/welcome.html">home</a></p>  |
        +----------------------------------------------------------------------+
   
3. Call the command and specify the destination website directory path :

        mkweb DESTINATION=/path/to/your/website/destination

4. That's it your website is created at the right place, with all page
   having the same layout taken from your template file, content being
   inserted at the right place.

For more details call `./mkweb doc`


# DOC

In this documentation :

* uppercased words refer to variables defined in mkweb command file ;

* root of source files is where the command is executed.

mkweb is a command build as a *simple* makefile which can be processed by
GNU make (which should thus be installed in order to run it).

The goal of this command is to use files with `.html` extension (source
files) in order to create new files, with same basename and same relative
path, under the directory DESTINATION. Existing hierarchy of files is
preserved and reproduced.

Source files are transformed after being selected. They also may be prepared
before being transformed.

Files transformation process
----------------------------

Created file are based on a template in which every text between
START_CONTENT and STOP_CONTENT is replaced by the content of the processed
`.html` file.

The used template is a file with same basename as TEMPLATE. This file is
looked up from the directory containing the processed `.html` file up to the
root of source files (which is the directory where the command is executed,
also stored in SOURCE). This lookup process is done upward and use the first
matching template file found, or TEMPLATE if none are found in the path.

Creation of new `.html` files from sources one is done by a perl script
build and stored in PERL_PROG.

This processing replaces some strings found in the source file:

* @DIR@ by the dirname of source file (from the root of source files)

* @FILE@ by the basename of source file

* @ROOT@ by a relative path to the root of source files

* @DATE@ by the current date using format DATE_FORMAT

* @MTIME@ by the last modification date of source file

Other strings replacement may be done :

* via HOOK_MACROS. In that case HOOK_MACROS must be an even numbered list of
  strings. First string is replaced by second, third by fourth, etc.

* via string replacement definitions in source file. In that case
  definitions must be at the very beginning of the file. A definition is a
  single line with a string (the one to be replaced), a colon, one or more
  spaces, another string (the replacement). Definitions ends when an empty
  line is found. Definitions are removed from the source file before
  transformation process.

Generated `.html` files are cleaned up by tidy unless USE_TIDY is set to
0. tidy uses TIDY_CONFIG config file, which is set by default to
SOURCE/.tidyrc.

Content may be filtered before processing, via HOOK_BEFORE, or after (but
before tidy), via HOOK_AFTER.

Files selection process
-----------------------

Files without `.html` suffix are copied without modification in their
destination directory.

Every source directory may contain an IGNORE file or a KEEP file.

Some files are completely ignored by the whole process (nothing is done on
them). It is the case for TIDY_CONFIG, TEMPLATE, SETTINGS and files:

* which basename is IGNORE, KEEP, PREPARE or same basename as TEMPLATE,

* which name use a space, a single quote, a double quote or a backslash,

* which name is an emacs backup name (ends with a tilda character),

* which basename is mentioned in the IGNORE file located in their directory,

* which basename match a pattern mentioned in an IGNORE file located in one
  of the directories above their own directory,

* which relative path (or directory path) from another directory is
  mentioned in the IGNORE file located in this (root) directory,

* which relative path (or directory path) from another directory match a
  pattern mentioned in an IGNORE file located in one of the directories
  above this (root) directory.

Some files with `.html` suffix may be copied as is (without being touched by
the whole modification process). It is the case for files:

* which basename is mentioned in the KEEP file located in their directory,

* which basename match a pattern mentioned in a KEEP file located in one of
  the directories above their own directory,

* which relative path (or directory path) from another directory is
  mentioned in the KEEP file located in this (root) directory,

* which relative path (or directory path) from another directory match a
  pattern mentioned in an KEEP file located in one of the directories above
  this (root) directory.

Patterns for file to ignore or to keep may use 2 differents joker: `*` match
any string of characters (including the empty one) and `?` match any single
character.

Files selection is done by a perl script build and stored in PERL_FIND.

File preparation process
------------------------

In order to prepare source files special makefiles may be used. Before
transformation start and using a deep-first algorithm, **every** PREPARE
files found in a directory under the root of source files are passed to the
make command. This call to `make` is done after having moved to the
directory holding the PREPARE file. This phase is not subject to file
selection process.

If `.html` file are created by this preparation phase they are considered as
source files in the transformation phase.

Customisation
-------------

Customisation of almost everything in the command may be done by modifying
variables. This can be done :

* through command line using `VARIABLE=value` form parameters

* through the SETTINGS file which may simply respect makefile syntax. The
  simplest case is to fix variables through `VARIABLE = value` form line.

Copy operations may be replace by hard link ones. This is the case if
HARD_LINK is set to 1 and if it the underlying operating system allows it
(destination is on the same filesystem as source). That may save some space
for big websites. In case hard link is used, one should however remember
that every `.html` destination files depends on TEMPLATE. For `.html` files
which need to be kept as is, that means, for instance, that if TEMPLATE is
more recent than any such `.html` kept file, each time the command is called
every such file will be processed : destination *is* source when hard
linked.


# HELP

    usage: $(MAKEFILE) [VAR=VALUE ...] [ACTION]
    
    where ACTION includes
    
        help             show this help message
        quick            display a very short howto about $(MAKEFILE)
        doc              display documentation
        version          display version number
    
        prepare          prepare source files
        create           prepare source files and then create web site pages
    
        check            check if needed commands and files are available
    
        list-vars        list available variables with current values
        list-files       list source files to be processed
        list-build       list destination files to be created
        list-ignored     list ignored files in source directory
        list-prepare     list directory in which preparation takes place
    
        clean            remove unnecessary files (backup files, etc.)
        real-clean       remove generated files and unnecessary files
    
    If no ACTION specified the `create` one is issued unless DEFAULT_ACTION
    variable is set. 

