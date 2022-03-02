#! /usr/bin/env sh

# Build file
pandoc "$INPUT_DIR/index.md" \
    -o "$INPUT_DIR/tmp.html" \
    --self-contained \
    --css="$STYLE" \
	--template "$TEMPLATE"

# Remove unwanted tags
cat "$INPUT_DIR/tmp.html" | sed \
    -e '/^[[:space:]]*$/d' \
    -e 's/<body/<body style=\"margin-top: 0\"/g' \
    | cat > "$OUTPUT_DIR/index.html"

rm "$INPUT_DIR/tmp.html"
