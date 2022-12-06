#! /usr/bin/env zsh

if [ ! -d "build" ]; then
    mkdir build
fi

SUBDOMAINS=("sprites" "photos" "cv" "blog")
INPUT_DIR="$(realpath ./src)"
OUTPUT_DIR="$(realpath ./build)"

# Create page
pandoc "$INPUT_DIR/index.md" \
    -o tmp.html \
    --resource-path "$INPUT_DIR" \
    --metadata title="Nils de Groot" \
	--template "$INPUT_DIR/template.html"

# Filter some values 
cat tmp.html | sed \
    -e '/^[[:space:]]*$/d' \
    | cat > "$OUTPUT_DIR/index.html"

rm tmp.html

minify "$INPUT_DIR/style.css" > "$OUTPUT_DIR/style.css"

# Copy favicon.ico
cp "$INPUT_DIR/favicon.ico" "$INPUT_DIR/.htaccess" "$INPUT_DIR/font.ttf" "$OUTPUT_DIR"

# Prepare sub domains
for sub in $SUBDOMAINS; do
	if [ -d "$OUTPUT_DIR/$sub" ]; then
		rm -rf "$OUTPUT_DIR/$sub"
	fi

	mkdir "$OUTPUT_DIR/$sub"

    TEMPLATE="$INPUT_DIR/template.html" \
		STYLE="$INPUT_DIR/style.css" \
		INPUT_DIR="$INPUT_DIR/$sub" \
		OUTPUT_DIR="$OUTPUT_DIR/$sub" "$INPUT_DIR/$sub/build.sh"
done
