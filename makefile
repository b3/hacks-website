DESTINATION := /tmp/ws
TEMPLATE = $(SOURCE)/Modele.html

START_MARK := <!-- @DEBUT_CONTENU@ -->
STOP_MARK := <!-- @FIN_CONTENU@ -->

TIDY_CONFIG := tidy.cfg

IGNORE := .ignore
KEEP := .keep

SED_PROG := /tmp/s

#### Rien a modifier apres cette ligne  ######################################

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
# TIDY_CONFIG, du fichier TEMPLATE et des fichiers dont :
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

ifeq ($(VERBOSE),1)
  Q =
else
  Q = @
endif

.PHONY: clean real-clean check debug list

MAKEFLAGS += -rR

DEBUG_DEPS :=

SOURCE := $(shell pwd)

# Find all source files (if opt=-v) or all ignored source files
CMD_FILES := \
  find -H $(SOURCE) -type f -o -type l \
  | grep -e ^$(SOURCE)/makefile$$ \
         -e $(TIDY_CONFIG) \
         -e $(TEMPLATE) \
         -e /$(IGNORE)$$ \
         -e /$(KEEP)$$ \
         -e /$(notdir $(TEMPLATE))$$ \
		 -Ee '[ "'\''\]' \
         -e ~$$ \
         $(foreach dir, \
                   $(shell find $(SOURCE) -name $(IGNORE) -printf "%h "), \
                   $(addprefix -e $(dir)/,$(addsuffix $$,$(shell cat $(dir)/$(IGNORE))) \
                                          $(addsuffix /,$(shell cat $(dir)/$(IGNORE))) \
           )) \
         $$opt \
  | sort

# Let pass only source files which should be kept as is
CMD_KEEP := \
  grep -q \
  $(foreach dir, \
            $(shell find $(SOURCE) -name $(KEEP) -printf "%h "), \
            $(addprefix -e ^$(dir)/,$(addsuffix $$,$(shell cat $(dir)/$(KEEP))) \
                                    $(addsuffix /,$(shell cat $(dir)/$(KEEP)))))

CMD_TIDY := $(shell which tidy)

CMD_COPY = \
echo "    COPY $(dir)$(file)" ; \
  mkdir -p $(dir $@) ; \
  cp -d -f $< $@

# FIXME: super lent faudrait faire faire le travail par make plutot que sh
# FIXME: les dependances ne sont pas bonne : si un TEMPLATE nouveau est present le fichier n'est pas recree
TEMPLATE_TO_USE = \
  `( \
    n=\`echo $(dir) | tr / '\n' | wc -l\` ; \
    m=\`basename $(TEMPLATE)\` ; \
    while test $$n -gt 0 && ! ls -1 \`echo $(dir) | cut -d / -f 1-$$n\`/$$m 2>/dev/null ; \
    do \
      n=\`expr $$n - 1\`; \
    done ; \
    echo $(TEMPLATE) \
  ) | head -1`

CMD_HTML = \
echo " DO_HTML ($(TEMPLATE_TO_USE)) $(dir)$(file)" ; \
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
  sed -f $(SED_PROG) $(TEMPLATE_TO_USE) > $@ ; \
  \
  sed -i -e 's/^/\#PASS_1\# /g' $(SED_PROG) ; \
  echo s!@ROOT@!$(shell echo $(dir $<) | sed -e 's!$(SOURCE)!@!' -e 's![^@/]\+!..!g' -e 'y/@/./' -e 's!/$$!!')!g >>$(SED_PROG) ; \
  echo s!@DATE@!$(shell date '+%Y/%m/%d %H:%M:%S')!g >>$(SED_PROG) ; \
  echo s!@MTIME@!$(shell date -r $< '+%Y/%m/%d %H:%M:%S')!g >>$(SED_PROG) ; \
  sed -i -f $(SED_PROG) $@ 

# FIXME: tidy empeche les & dans les URL :-(
#  \
#  $(CMD_TIDY) -q -config $(TIDY_CONFIG) -f /tmp/$$(echo $(dir)$(file).tidylog | tr / _) $@

file = $(notdir $@)
dir = $(subst $(DESTINATION)/,,$(dir $@))

DO_CHECK := \
echo -n "   CHECK " ; \
  which 

DO_HTML = \
  if echo $< | $(CMD_KEEP) ; then \
    $(CMD_COPY) ; \
  else \
    $(CMD_HTML) ; \
  fi	

DO_COPY = \
  $(CMD_COPY)

ALL_FILES := $(subst $(SOURCE)/,$(DESTINATION)/,$(shell opt=-v ; $(CMD_FILES)))

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

listfiles:
	$(Q)opt=-v ; $(CMD_FILES)

listignored:
	$(Q)$(CMD_FILES)

$(DESTINATION)/%.html: $(SOURCE)/%.html $(DEBUG_DEPS) $(TEMPLATE)
	$(Q)$(DO_HTML)

$(DESTINATION)/%:: $(SOURCE)/% $(DEBUG_DEPS)
	$(Q)$(DO_COPY)

clean:
	$(Q)find $(SOURCE) -name '*~' -delete

real-clean:
	$(Q)rm -rf $(ALL_FILES)

check:
	$(Q)$(DO_CHECK) tidy

##############################################################################

# Work garbage
#tmp_ini = $(1) := 
#tmp_acc = $(if $($(1)),$(1):=$($(1))/$(2),$(1):=$(2))
#$(foreach exist, \
#                      $(foreach x, \
#                                $(subst /, ,$(dir)), \
#                                $(eval $(call tmp_acc,path,$(x))) \
#                                  $(path)), \
#  $(eval $(call tmp_ini,path))
#
#TEST_KEEP := \
#   grep -xsq "^$(file)$$" $(dir)$(KEEP) \
#|| grep -xsq "^$(dir)$(file)$$" $(SOURCE)/$(KEEP) \
#|| grep -xsq "^$(dir)$$" $(SOURCE)/$(KEEP) \
#|| ( echo $(SOURCE)/$(dir) | grep -sq $(patsubst %, -e '^$(SOURCE)/%', $(shell cat $(SOURCE)/$(KEEP) 2>/dev/null)))
#
#CMD_KEEP = \
#	echo $(dir)$(file) ; \
#	echo \
#    $(foreach keep, \
#              $(foreach x, \
#                        $(subst /, ,$(dir)), \
#                        $(eval $(call tmp_acc,path,$(x))) \
#                          $(path)/$(KEEP)), \
#              $(shell test -e $(SOURCE)/$(keep) && echo $(SOURCE)/$(keep)))
#
# End
