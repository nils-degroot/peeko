#! /usr/bin/env zsh

cd "$INPUT_DIR"

# Build file
pandoc "$INPUT_DIR/index.md" \
    -o "$INPUT_DIR/tmp.html" \
	--template $TEMPLATE

# Remove unwanted tags
cat "$INPUT_DIR/tmp.html" | sed \
    -e '/^[[:space:]]*$/d' \
	-e '0,/<p>/s//<p class\=\"text-center\">/' \
    -e 's/<body/<body style=\"margin-top: 0\"/g' \
    | cat > "$OUTPUT_DIR/index.html"

rm "$INPUT_DIR/tmp.html"
cp "$INPUT_DIR/nils-small.jpg" "$OUTPUT_DIR"
