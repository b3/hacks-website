# Settings may be put in this file (may be fixed on command line)
ifeq ($(origin SETTINGS), undefined)
SETTINGS := .settings
endif

# Processed files wil be copied in this directory
ifeq ($(origin DESTINATION), undefined)
DESTINATION := /tmp/ws
endif

# HTML files created will be based on this template file
ifeq ($(origin TEMPLATE), undefined)
TEMPLATE := $(SOURCE)/Modele.html
endif

# Template content between these marks will be replaced by file content
ifeq ($(origin START_MARK), undefined)
START_MARK := <!-- @DEBUT_CONTENU@ -->
STOP_MARK := <!-- @FIN_CONTENU@ -->
endif

# DATE_FORMAT should not contain exclamation mark
ifeq ($(origin DATE_FORMAT), undefined)
DATE_FORMAT := '+%Y/%m/%d %H:%M:%S'
endif

# Tidy config file
ifeq ($(origin TIDY_CONFIG), undefined)
TIDY_CONFIG := $(HOME)/.tidyrc
endif

# Basename of files containing filename specification to ignore
ifeq ($(origin IGNORE), undefined)
IGNORE := .ignore
endif

# Basename of files containing filename specification to keep as is
ifeq ($(origin KEEP), undefined)
KEEP := .keep
endif

# Show exact executed commands only if VERBOSE is set to 1
ifeq ($(origin VERBOSE), undefined)
VERBOSE := 0
endif

# Temporary directory
ifeq ($(origin TEMP), undefined)
TMP := /tmp
endif

# Temporary sed program
ifeq ($(origin SED_PROG), undefined)
SED_PROG := $(TMP)/s
endif

# Temporary perl program
ifeq ($(origin PERL_PROG), undefined)
PERL_PROG := $(TMP)/p
endif

#### Nothing to change after this line #######################################

##############################################################################
#
# Les fichiers avec extension .html sont utilises pour creer des
# fichiers, aux chemins relatifs identiques, dans le repertoire
# DESTINATION. La creation est faite en remplacant dans un fichier
# modele tout ce qu'il y a entre START_MARK et STOP_MARK par le
# contenu du fichier .html.
#
# Le modele utilise est un fichier, de meme nom de base que TEMPLATE,
# present dans le repertoire du fichier .html traite, ou dans un des
# repertoires parents en remontant jusqu'a la racine des sources (meme
# endroit que ce makefile), ou simplement le fichier TEMPLATE. Le
# choix est fait dans cet ordre (le premier trouve est utilise).
#
# Les fichiers .html generes sont nettoyes avec tidy en utilisant le
# fichier de configuration TIDY_CONFIG.
# 
# Les fichiers sans extension .html sont copies tel quel dans le
# repertoire destination.
#
# Chaque repertoire peut contenir un fichier IGNORE et un fichier
# KEEP.
#
# Le repertoire racine est celui dans lequel se trouve ce makefile.
#
# Certains fichiers sont completement ignores par le processus (on en
# fait rien du tout). C'est le cas de ce fichier makefile, du fichier
# TIDY_CONFIG, du fichier TEMPLATE, du fichier SETTINGS et des
# fichiers dont :
#
# * le nom de base est IGNORE, KEEP, ou le nom de base de TEMPLATE,
#
# * le nom contient un espace, une quote simple, une quote double ou
#   un backslash,
#
# * le nom correspond à un nom de fichier backup d'Emacs (avec comme
#   extension le caractere tilde),
#
# * le nom de base est present dans le fichier IGNORE de leur
#   repertoire,
#
# * le chemin (du fichier ou de son repertoire) relatif a un
#   repertoire est present dans le fichier IGNORE de celui-ci.
#
# Certains fichiers avec extension .html, peuvent etre copie tels
# quels (sans subir la transformation utilisant les marques START_MARK
# et STOP_MARK). C'est le cas des fichiers dont :
#
# * le nom de base est present dans le fichier KEEP de leur
#   repertoire,
#
# * le chemin (du fichier ou de son repertoire) relatif a un
#   repertoire est present dans le fichier KEEP de celui-ci.
#
# La transformation des fichiers a extension .html utilise sed via un
# programme construit dans SED_PROG.
#
##############################################################################

##############################################################################
#
# Developer code conventions
#
##############################################################################

# If settings file exists read it now!
ifeq ($(wildcard $(SETTINGS)),$(SETTINGS))
include $(SETTINGS)
endif

# Sed script to include source into template (not used anymore)
define SED_SCRIPT
#-----------------------------------------------------------------------------
s/$(START_MARK)//
t dedans
b fin
:dedans
N
s/$(STOP_MARK)//
t contenu
b dedans
:contenu
x
r $<
D
:fin
#-----------------------------------------------------------------------------
endef
export SED_SCRIPT

# Perl script to include source into template with some macro substitutions
define PERL_SCRIPT
#-----------------------------------------------------------------------------
# Get template filename from command line
my $$template = shift(@ARGV);

# Get macros from command line
my %macros;
while ($$#ARGV != -1)
{
    my $$k = shift(@ARGV);
    my $$v = shift(@ARGV);
    $$macros{$$k} = $$v;
}

# Substitute macros on given line
sub substitute
{
    my ($$l) = @_;
    foreach (keys(%macros))
    {
        $$l =~ s/$$_/$$macros{$$_}/g;
    }
    print($$l);
}

# Run through template file content
open(T, $$template) || die "cannot open $$template";
my $$inside = 0;
while (<T>)
{
    # Entering content part
    if ($$_ =~ q{$(START_MARK)})
    {
        $$inside = 1;
        # Output content part
        while (<STDIN>)
        {
            &substitute("$$_");
        }
    }
    # Exiting content part
    elsif ($$inside && $$_ =~ q{$(STOP_MARK)})
    {
        $$inside = 0;
    }
    # Output template part
    elsif ($$inside == 0)
    {
        &substitute("$$_");
    }
}
close(T);
#-----------------------------------------------------------------------------
endef
export PERL_SCRIPT

# What shell to use
SHELL = /bin/bash

# By default do not show executed command
ifeq ($(VERBOSE),1)
  Q :=
else
  Q := @
endif

# Absolute path of source files (where this makefile is executed)
SOURCE := $(CURDIR)

# Try to improve performance
MAKEFLAGS += -rR
.PHONY: clean real-clean check debug list-files list-ignored $(SED_PROG) $(PERL_PROG)

# Useful variables for commands (need to be recursively expanded)
file = $(notdir $@)
dir = $(subst $(DESTINATION)/,,$(dir $@))
root = $(shell echo $(subst $(SOURCE),@,$(dir $<)) | sed -e 's![^@/]\+!..!g' -e 'y/@/./' -e 's!/$$!!' -e 's!^\./!!')
date = $(shell date $(DATE_FORMAT))
mtime = $(shell date -r $< $(DATE_FORMAT))
exist = $(subst $(1)/,,$(wildcard $(1)/$(2)))

# Ouput all source files (if opt=-v) or all ignored source files
CMD_FILES := \
  find -H $(SOURCE) -type f -o -type l \
  | grep -e ^$(SOURCE)/makefile$$ \
         -e $(TIDY_CONFIG) \
         -e $(TEMPLATE) \
         -e $(SETTINGS) \
         -e /$(IGNORE)$$ \
         -e /$(KEEP)$$ \
         -e /$(notdir $(TEMPLATE))$$ \
		 -Ee '[ "'\''\]' \
         -e ~$$ \
         $(foreach dir, \
                   $(shell find $(SOURCE) -name $(IGNORE) -printf "%h "), \
                   $(addprefix -e $(dir)/,$(addsuffix $$,$(shell sed 's!/$$!!g' $(dir)/$(IGNORE))) \
                                          $(addsuffix /,$(shell sed 's!/$$!!g' $(dir)/$(IGNORE))) \
           )) \
         $$opt \
  | sort

# Let pass only source files which should be kept as is
#   Last space before the comment should stay present to please grep in the
#   case there is no files to keep
CMD_KEEP := \
  grep -q \
  $(foreach dir, \
            $(shell find $(SOURCE) -name $(KEEP) -printf "%h "), \
            $(addprefix -e ^$(dir)/,$(addsuffix $$,$(shell sed 's!/$$!!g' $(dir)/$(KEEP))) \
                                    $(addsuffix /,$(shell sed 's!/$$!!g' $(dir)/$(KEEP))))) \
 # comment present to embed a space in CMD_KEEP

# Output the right template file path to use
tmp_ini = $(1) := 
tmp_acc = $(if $($(1)),$(1):=$($(1))/$(2),$(1):=$(2))
CMD_TEMPLATE = \
  $(lastword $(TEMPLATE) \
             $(foreach template,\
                       $(notdir $(TEMPLATE)) \
                         $(foreach word, \
                                   $(subst /, ,$(dir)), \
                                   $(eval $(call tmp_acc,path,$(word))) \
                                     $(path)/$(notdir $(TEMPLATE))) \
                         $(eval $(call tmp_ini,path)), \
                       $(call exist,$(SOURCE),$(template))))

# Tidy HTML from standard input to standard output
#   FIXME: tidy does not like & in URL :-(
CMD_TIDY := tidy -q $(if $(TIDY_CONFIG),-config $(TIDY_CONFIG))

# Send dependency content to standard input (and apply some modifications if
# asked)
CMD_BEFORE = \
  cat $< \
  $(if $(value EXT_BEFORE),| $(EXT_BEFORE))

# Send template file with content replaced by standard input to standard
# output
CMD_HTML = \
  perl $(PERL_PROG) $(CMD_TEMPLATE) \
    @DIR@ "$(dir)" \
    @FILE@ "$(file)" \
    @ROOT@ "$(root)" \
    @DATE@ "$(date)" \
    @MTIME@ "$(mtime)"

# Tidy HTML file from standard input (after applying some modifications if
# asked) and save it into destination file
CMD_AFTER = \
  $(if $(value EXT_AFTER),$(EXT_AFTER) |) \
  $(if $(value CMD_TIDY),$(CMD_TIDY) -f $(TMP)/$(subst /,_,$(dir)$(file).tidylog),cat |) \
  >$@ || true

# Hard link a file (or copy it preserving symbolic link) in existing
# destination directory
CMD_COPY = \
  mkdir -p $(dir $@) && \
  cp -l -d -f $< $@ 2>/dev/null 1>&2 || cp -d -f $< $@

##############################################################################

# Check if a command is available
DO_CHECK := \
echo -n "    CHECK " ; \
  which 

# Process source (HTML) file
DO_HTML = \
  if echo $< | $(CMD_KEEP) ; then \
    echo "KEEP_COPY $(dir)$(file)" ; \
    $(CMD_COPY) ; \
  else \
    /bin/echo -e "  DO_HTML $(dir)$(file)\twith template $(CMD_TEMPLATE)" ; \
    mkdir -p $(dir $@) && \
    $(CMD_BEFORE) | $(CMD_HTML) | $(CMD_AFTER) ; \
  fi	

# Copy file
DO_COPY = \
echo "     COPY $(dir)$(file)" ; \
  $(CMD_COPY)

# List of auxiliary programs used
ALL_PROGS := $(SED_PROG) $(PERL_PROG)

# List of all source files to process
ALL_FILES := $(subst $(SOURCE)/,$(DESTINATION)/,$(shell opt=-v ; $(CMD_FILES)))

# Debug stuff
DEBUG_DEPS :=

##############################################################################

all: check $(ALL_PROGS) $(ALL_FILES)

debug:
	@echo "      SOURCE = $(SOURCE)"
	@echo " DESTINATION = $(DESTINATION)"
	@echo "    TEMPLATE = $(TEMPLATE)"
	@echo "  START_MARK = $(START_MARK)"
	@echo "   STOP_MARK = $(STOP_MARK)"
	@echo " DATE_FORMAT = $(DATE_FORMAT)"
	@echo " TIDY_CONFIG = $(TIDY_CONFIG)"
	@echo "    SETTINGS = $(SETTINGS)"
	@echo "      IGNORE = $(IGNORE)"
	@echo "        KEEP = $(KEEP)"
	@echo "     VERBOSE = $(VERBOSE)"
	@echo "         TMP = $(TMP)"
	@echo "    SED_PROG = $(SED_PROG)"
	@echo "   PERL_PROG = $(PERL_PROG)"
	@echo "       SHELL = $(SHELL)"
	@echo "       FILES = see /tmp/files and /tmp/ignored"
	@opt=-v ; $(CMD_FILES) >/tmp/files
	@$(CMD_FILES) > /tmp/ignored

$(SED_PROG):
	$(Q)echo "$$SED_SCRIPT" >$@

$(PERL_PROG):
	$(Q)echo "$$PERL_SCRIPT" >$@

list-files:
	$(Q)opt=-v ; $(CMD_FILES)

list-ignored:
	$(Q)$(CMD_FILES)

# FIXME: les dependances ne sont pas bonne. Si un TEMPLATE nouveau est present le fichier n'est pas recree
$(DESTINATION)/%.html: $(SOURCE)/%.html $(DEBUG_DEPS) $(CMD_TEMPLATE)
	$(Q)$(DO_HTML)

$(DESTINATION)/%:: $(SOURCE)/% $(DEBUG_DEPS)
	$(Q)$(DO_COPY)

clean:
	$(Q)find $(SOURCE) -name '*~' -delete

real-clean:
	$(Q)rm -rf $(ALL_FILES)

check:
	$(Q)$(DO_CHECK) date
	$(Q)$(DO_CHECK) find
	$(Q)$(DO_CHECK) perl
	$(Q)$(DO_CHECK) sed
	$(Q)$(DO_CHECK) tidy

# Local Variables:
# tab-width: 4
# End:
