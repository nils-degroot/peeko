#! /usr/bin/env zsh

# Minify css
cat style.css \
    | sed -r ':a; s%(.*)/\*.*\*/%\1%; ta; /\/\*/ !b; N; ba' \
    | tr -d '\t' | tr -d ' ' | tr -d '\n' | tr -s ' ' ' ' > style.min.css

# Create page
pandoc index.md \
    -o tmp.html \
    --self-contained \
    --css=style.min.css \
    --metadata title="Nils de Groot"

# Remove unwanted tags
cat tmp.html | sed \
    -e 's/<title>.*/<title>Nils de Groot<\/title>/g' \
    -e 's/<meta name\=\"generator.*//g' \
    -e 's/<h1.*//g' \
    -e 's/<header.*//g' \
    -e 's/<\/header.*//g' \
    -e '0,/<p>/s//<p style\=\"text-align: center\">/' \
    -e '/^[[:space:]]*$/d' \
    | cat > index.html

rm tmp.html
