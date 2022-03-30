#! /usr/bin/env zsh

# Build file
pandoc "$INPUT_DIR/index.md" \
    -o "$INPUT_DIR/tmp.html" \
	--template $TEMPLATE

# Remove unwanted tags
cat "$INPUT_DIR/tmp.html" | sed \
    -e '/^[[:space:]]*$/d' \
    -e 's/<body/<body style=\"margin-top: 0\"/g' \
    | cat > "$OUTPUT_DIR/index.html"

find "$INPUT_DIR/sprites" -type f -exec cp {} $OUTPUT_DIR \;

rm "$INPUT_DIR/tmp.html"
