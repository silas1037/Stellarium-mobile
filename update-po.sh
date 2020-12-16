#!/bin/sh

echo update stellarium.pot

INPUT_FILES=$(find data/qml/ -name '*.qml')

xgettext -o po/stellarium/stellarium.pot \
         -j -C --qt \
         --keyword=QT_TR_NOOP \
         --keyword=qsTr \
         --add-comments=TRANSLATORS: \
         --copyright-holder="Stellarium's team" \
         --from-code=utf-8 \
         $INPUT_FILES

echo update all the po

LANGS="en fr de es it zh_CN zh_TW"
for lang in $LANGS; do
    msgmerge --quiet --update -m -N --backup=none -s \
             po/stellarium/$lang.po po/stellarium/stellarium.pot
done
