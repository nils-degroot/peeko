#!/usr/bin/env zsh

BACK="\n\n[Back](/blog)"

basepage=$(cat "$INPUT_DIR/index.md")

find "$INPUT_DIR" -type f -name '*.md' -not -name 'index.md' -print0 | while read -d $'\0' entry; do
	base=$(basename "$entry")
	name="${base%.*}"

	content="$(cat "$entry")$BACK"
	echo "$content" | pandoc \
		-o "$OUTPUT_DIR/$name.html" \
		--template "$TEMPLATE" \
		--highlight-style "$INPUT_DIR/syntax.theme"

	basepage+="\n- [${name}](/blog/${name}.html)"
done

basepage+="$BACK"

echo -e "$basepage" | pandoc \
    -o "$OUTPUT_DIR/index.html" \
	--template "$TEMPLATE"
