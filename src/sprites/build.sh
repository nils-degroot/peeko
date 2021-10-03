#! /usr/bin/env zsh

# Build file
pandoc "$INPUT_DIR/index.md" \
    -o "$INPUT_DIR/tmp.html" \
    --self-contained \
    --css="$STYLE" \
    --metadata title="Peeko - Sprites"

# Remove unwanted tags
cat "$INPUT_DIR/tmp.html" | sed \
    -e 's/<h1/<h3/g' \
    -e 's/<\/h1>/<\/h3>/g' \
    -e 's/<header.*//g' \
    -e 's/<\/header.*//g' \
    -e 's/<meta name\=\"generator.*//g' \
    -e 's/<p>©/<p class=\"text-center\">©/g' \
    -e '/^[[:space:]]*$/d' \
    -e 's/<body/<body style=\"margin-top: 0\"/g' \
    -e 's/title\">.*/title\">Sprites<\/h3>/g' \
    | cat > "$OUTPUT_DIR/index.html"

cp -r "$INPUT_DIR/sprites" "$OUTPUT_DIR/sprites"

rm "$INPUT_DIR/tmp.html"
