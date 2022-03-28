#! /usr/bin/env zsh

if [ ! -d "build" ]; then
    mkdir build
fi

SUBDOMAINS=("tools" "sprites" "photos")
INPUT_DIR="$(realpath ./src)"
OUTPUT_DIR="$(realpath ./build)"

# Create page
pandoc "$INPUT_DIR/index.md" \
    -o tmp.html \
    --resource-path "$INPUT_DIR" \
    --self-contained \
    --css="$INPUT_DIR/style.css" \
    --metadata title="Nils de Groot" \
	--template "$INPUT_DIR/template.html"

# Filter some values 
cat tmp.html | sed \
    -e '0,/<p>/s//<p class\=\"text-center\">/' \
    -e '/^[[:space:]]*$/d' \
    | cat > "$OUTPUT_DIR/index.html"

# Copy favicon.ico
cp "$INPUT_DIR/favicon.ico" "$OUTPUT_DIR"
cp "$INPUT_DIR/style.css" "$OUTPUT_DIR"

# Prepare sub domains
for sub in $SUBDOMAINS; do
	if [ -d "$OUTPUT_DIR/$sub" ]; then
		rm -rf "$OUTPUT_DIR/$sub"
	fi

	mkdir "$OUTPUT_DIR/$sub"

    cp "$INPUT_DIR/favicon.ico" "$OUTPUT_DIR/$sub"
    TEMPLATE="$INPUT_DIR/template.html" STYLE="$INPUT_DIR/style.css" INPUT_DIR="$INPUT_DIR/$sub" OUTPUT_DIR="$OUTPUT_DIR/$sub" "$INPUT_DIR/$sub/build.sh"
done

rm tmp.html
