#!/bin/bash

echo update stellarium.pot

INPUT_FILES="$(find data/qml/ -name '*.qml') $(find src -name '*.h' -o -name '*.cpp')"

xgettext -o po/stellarium/stellarium.pot \
         -C --qt \
         --keyword=QT_TR_NOOP \
         --keyword=qsTr \
         --keyword=_ \
         --keyword=N_ \
         --keyword=q_ \
         --keyword=qc_:1,2c \
         --keyword=translate:2 \
         --keyword=translate:2,3c \
         --add-comments=TRANSLATORS: \
         --copyright-holder="Stellarium's team" \
         --from-code=utf-8 \
         $INPUT_FILES

echo update all the po

LANGS="en fr de es it zh_CN zh_TW ru"
for lang in $LANGS; do
    msgmerge --quiet --update -m -N --backup=none -s \
             po/stellarium/$lang.po po/stellarium/stellarium.pot
done
