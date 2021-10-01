#! /usr/bin/env zsh

# Create page
pandoc index.md \
    -o tmp.html \
    --self-contained \
    --css=style.css \
    --metadata title="Nils de Groot"

# Remove unwanted tags
cat tmp.html | sed \
    -e 's/<title>.*/<title>Nils de Groot<\/title>/g' \
    -e 's/<meta name\=\"generator.*//g' \
    -e 's/<h1.*//g' \
    -e 's/<header.*//g' \
    -e 's/<\/header.*//g' \
    -e 's/<p>©/<p class=\"text-center\">©/g' \
    -e '0,/<p>/s//<p class\=\"text-center\">/' \
    -e '/^[[:space:]]*$/d' \
    | cat > index.html

rm tmp.html
