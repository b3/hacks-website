DESTINATION=/tmp/ws
TEMPLATE=$(SOURCE)/Modele.html

START_MARK=<!-- @DEBUT_CONTENU@ -->
STOP_MARK=<!-- @FIN_CONTENU@ -->

TIDY_CONFIG=tidy.cfg

IGNORE=.ignore
KEEP=.keep

SED_PROG=/tmp/s

#### Rien a modifier apres cette ligne  ######################################

##############################################################################
#
# Les fichiers avec extension .html sont utilises pour creer des fichiers, aux
# chemins relatifs identiques, dans le repertoire DESTINATION. La creation est
# faite en remplacant dans un fichier modele tout ce qu'il y a entre
# START_MARK et STOP_MARK par le contenu du fichier .html.
#
# Le modele utilise est un fichier, de meme nom de base que TEMPLATE, present
# dans le repertoire du fichier .html traite, ou dans un des repertoires
# parents en remontant jusqu'a la racine des sources (meme endroit que ce
# makefile), ou simplement le fichier TEMPLATE. Le choix est fait dans cet
# ordre (le premier trouve est utilise).
#
# Les fichiers .html generes sont nettoyes avec tidy en utilisant le fichier
# de configuration TIDY_CONFIG.
# 
# Les fichiers sans extension .html sont copies tel quel dans le repertoire
# destination.
#
# Certains fichiers peuvent etre ignores completement par le processus (on en
# fait rien du tout). C'est le cas si :
#
# * son nom de base est present dans le fichier IGNORE de son repertoire,
#
# * son chemin relatif a la racine est present dans le fichier IGNORE de la
#   racine,
#
# * le chemin de son repertoire (avec le dernier slash) est present dans le
#   fichier IGNORE de la racine (meme repertoire que ce makefile),
#
# Certains fichiers avec extension .html, peuvent etre copie tels quels (sans
# subir la transformation utilisant les marques START_MARK et
# STOP_MARK). C'est le cas si :
#
# * son nom de base est present dans le fichier KEEP de son repertoire,
#
# * son chemin relatif a la racine est present dans le fichier KEEP de la
#   racine,
#
# * le chemin de son repertoire (avec le dernier slash) est present dans le
#   fichier KEEP de la racine,
#
# Les fichiers TEMPLATE (ou de meme nom de base), makefile et TIDY_CONFIG ne
# sont pas pris en compte.
#
# Les fichiers IGNORE, KEEP et les fichiers de backup d'Emacs (avec extension
# ~) sont ignores par defaut.
#
# La transformation des fichiers a extension .html utilise sed via un
# programme construit dans SED_PROG.
#
##############################################################################

.PHONY: clean real-clean check debug list

DEBUG_DEPS=

SOURCE=$(shell pwd)

FILES=$(subst \
  $(SOURCE)/, \
  $(DESTINATION)/, \
  $(shell find -H $(SOURCE) -type f -o -type l \
          | grep -v -e '/$(notdir $(TEMPLATE))$$' \
                    -e '^$(SOURCE)/makefile$$' \
                    -e '/$(IGNORE)$$' \
                    -e '/$(KEEP)$$' \
					$(patsubst %, -e '^$(SOURCE)/%', $(shell cat $(SOURCE)/$(IGNORE) 2>/dev/null)) \
                    -e '~$$' \
                    -e $(TIDY_CONFIG)))

CMD_NAMES = \
  file=$(notdir $<) ; \
  dir=$(subst $(SOURCE)/,,$(dir $<))

CMD_IGNORE = \
if    grep -xsq "^$$file$$" $$dir$(IGNORE) \
   || grep -xsq "^$$dir$$file$$" $(SOURCE)/$(IGNORE) \
   || grep -xsq "^$$dir$$" $(SOURCE)/$(IGNORE) ; then \
  echo "  IGNORE $$dir$$file" ; \
  exit ; \
fi

TEST_KEEP = \
   grep -xsq "^$$file$$" $$dir$(KEEP) \
|| grep -xsq "^$$dir$$file$$" $(SOURCE)/$(KEEP) \
|| grep -xsq "^$$dir$$" $(SOURCE)/$(KEEP) \
|| ( echo $(SOURCE)/$$dir | grep -sq $(patsubst %, -e '^$(SOURCE)/%', $(shell cat $(SOURCE)/$(KEEP) 2>/dev/null)) )

CMD_TIDY = $(shell which tidy)

CMD_COPY = \
echo "    COPY $$dir$$file" ; \
  mkdir -p $(dir $@) ; \
  cp -d -f $< $@

# FIXME: super lent faudrait faire faire le travail par make plutot que sh
# FIXME: les dependances ne sont pas bonne : si un TEMPLATE nouveau est present le fichier n'est pas recree
TEMPLATE_TO_USE = \
  `( \
    n=\`echo $$dir | tr / '\n' | wc -l\` ; \
    m=\`basename $(TEMPLATE)\` ; \
    while test $$n -gt 0 && ! ls -1 \`echo $$dir | cut -d / -f 1-$$n\`/$$m 2>/dev/null ; \
    do \
      n=\`expr $$n - 1\`; \
    done ; \
    echo $(TEMPLATE) \
  ) | head -1`

CMD_HTML = \
echo " DO_HTML $$dir$$file" ; \
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
  sed -i -f $(SED_PROG) $@ 

# FIXME: tidy empeche les & dans les URL :-(
#  \
#  $(CMD_TIDY) -q -config $(TIDY_CONFIG) -f /tmp/$$(echo $$dir$$file.tidylog | tr / _) $@

DO_CHECK = \
echo -n "   CHECK " ; \
  which 

DO_HTML = \
  $(CMD_NAMES) ; \
  $(CMD_IGNORE) ; \
  if $(TEST_KEEP) ; then \
    $(CMD_COPY) ; \
  else \
    $(CMD_HTML) ; \
  fi	

DO_COPY = \
  $(CMD_NAMES) ; \
  $(CMD_IGNORE) ; \
  $(CMD_COPY)

##############################################################################

all: $(FILES)

debug:
	@echo "      SOURCE = $(SOURCE)"
	@echo " DESTINATION = $(DESTINATION)"
	@echo "    TEMPLATE = $(TEMPLATE)"
	@echo "  START_MARK = $(START_MARK)"
	@echo "   STOP_MARK = $(STOP_MARK)"
	@echo "         TMP = $(patsubst %, -e '^$(SOURCE)/%', $(shell cat $(SOURCE)/$(IGNORE) 2>/dev/null)) "

list:
	@for i in $(FILES) ; do echo $$i; done

$(DESTINATION)/%.html: $(SOURCE)/%.html $(DEBUG_DEPS) $(TEMPLATE)
	@$(DO_HTML)

$(DESTINATION)/%:: $(SOURCE)/% $(DEBUG_DEPS)
	@$(DO_COPY)

clean:
	@find $(SOURCE) -name '*~' -delete

real-clean:
	@rm -rf $(FILES)

check:
	@$(DO_CHECK) tidy

##############################################################################

# End
