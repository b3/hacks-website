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
TEMPLATE = $(SOURCE)/Modele.html
endif

# Template content between these marks will be replaced by file content
ifeq ($(origin START_MARK), undefined)
START_MARK := <!-- @DEBUT_CONTENU@ -->
STOP_MARK := <!-- @FIN_CONTENU@ -->
endif

# DATE_FORMAT should not contain exclamation mark
ifeq ($(origin DATE_FORMAT), undefined)
DATE_FORMAT ?= '+%Y/%m/%d %H:%M:%S'
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
ifeq ($(shell ls $(SETTINGS) 2>/dev/null),$(SETTINGS))
include $(SETTINGS)
endif

# By default do not show executed command
ifeq ($(VERBOSE),1)
  Q :=
else
  Q := @
endif

# Absolute path of source files (where this makefile is executed)
SOURCE := $(shell pwd)

# Try to improve performance
MAKEFLAGS += -rR
.PHONY: clean real-clean check debug list-files list-ignored

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
                   $(addprefix -e $(dir)/,$(addsuffix $$,$(shell sed 's/\/$$//g' $(dir)/$(IGNORE))) \
                                          $(addsuffix /,$(shell sed 's/\/$$//g' $(dir)/$(IGNORE))) \
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
            $(addprefix -e ^$(dir)/,$(addsuffix $$,$(shell sed 's/\/$$//g' $(dir)/$(KEEP))) \
                                    $(addsuffix /,$(shell sed 's/\/$$//g' $(dir)/$(KEEP))))) \
 # embed a space in CMD_KEEP

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
                       $(shell test -e $(SOURCE)/$(template) && echo $(template))))

# FIXME: doit être découpé en filtre et création de destination
# Replace content in template file by dependency content
#   FIXME: tidy empeche les & dans les URL :-(
CMD_HTML = \
  mkdir -p $(dir $@) ; \
  \
  echo 's/$(START_MARK)//' >$(SED_PROG) ; \
  echo 't dedans' >>$(SED_PROG) ; \
  echo 'b fin' >>$(SED_PROG) ; \
  echo ':dedans' >>$(SED_PROG) ; \
  echo 'N' >>$(SED_PROG) ; \
  echo 's/$(STOP_MARK)//' >>$(SED_PROG) ; \
  echo 't contenu' >>$(SED_PROG) ; \
  echo 'b dedans' >>$(SED_PROG) ; \
  echo ':contenu' >>$(SED_PROG) ; \
  echo 'x' >>$(SED_PROG) ; \
  echo r $< >>$(SED_PROG) ; \
  echo 'D' >>$(SED_PROG) ; \
  echo ':fin' >>$(SED_PROG) ; \
  sed -f $(SED_PROG) $(CMD_TEMPLATE) > $@ ; \
  sed -i -e 's/^/\#PASS_1\# /g' $(SED_PROG) ; \
  \
  echo s!@ROOT@!$(root)!g >>$(SED_PROG) ; \
  echo s!@DATE@!$(date)!g >>$(SED_PROG) ; \
  echo s!@MTIME@!$(mtime)!g >>$(SED_PROG) ; \
  sed -i -f $(SED_PROG) $@ ; \
  \
  $(CMD_TIDY) $@ || true

# FIXME: doit être un filtre
# Tidy HTML file 
#   FIXME: avec := c'est plus rapide mais c'est une seule fois
CMD_TIDY = $(shell which tidy) -m -q $(if $(TIDY_CONFIG),-config $(TIDY_CONFIG)) -f $(TMP)/$(subst /,_,$(dir)$(file).tidylog)

# Copy file in existing destination directory and preserve symbolic link
CMD_COPY = \
  mkdir -p $(dir $@) && \
  cp -l -d -f $< $@ 2>/dev/null 1>&2 || cp -d -f $< $@

# Useful variables for commands (need to be classical recursively expanded)
file = $(notdir $@)
dir = $(subst $(DESTINATION)/,,$(dir $@))
root = $(shell echo $(subst $(SOURCE),@,$(dir $<)) | sed -e 's![^@/]\+!..!g' -e 'y/@/./' -e 's!/$$!!')
date = $(shell date $(DATE_FORMAT))
mtime = $(shell date -r $< $(DATE_FORMAT))

# Check if a command is available
DO_CHECK := \
echo -n "    CHECK " ; \
  which 

# Process HTML file
DO_HTML = \
  if echo $< | $(CMD_KEEP) ; then \
    echo "KEEP_COPY $(dir)$(file)" ; \
    $(CMD_COPY) ; \
  else \
    /bin/echo -e "  DO_HTML $(dir)$(file)\n          (with template $(CMD_TEMPLATE))" ; \
    $(CMD_HTML) ; \
  fi	

# Copy file
DO_COPY = \
echo "     COPY $(dir)$(file)" ; \
  $(CMD_COPY)

# List of all source files to process
ALL_FILES := $(subst $(SOURCE)/,$(DESTINATION)/,$(shell opt=-v ; $(CMD_FILES)))

# Debug stuff
DEBUG_DEPS :=

##############################################################################

all: $(ALL_FILES)

debug:
	@echo "      SOURCE = $(SOURCE)"
	@echo " DESTINATION = $(DESTINATION)"
	@echo "    TEMPLATE = $(TEMPLATE)"
	@echo "  START_MARK = $(START_MARK)"
	@echo "   STOP_MARK = $(STOP_MARK)"
	@echo "       FILES = see /tmp/files and /tmp/ignored"
	@opt=-v ; $(CMD_FILES) >/tmp/files
	@$(CMD_FILES) > /tmp/ignored

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
	$(Q)$(DO_CHECK) tidy

# Local Variables:
# tab-width: 4
# End:
