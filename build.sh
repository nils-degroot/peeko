#! /usr/bin/env zsh

if [ -d "build" ]; then
    rm -rf build
fi

mkdir build

SUBDOMAINS=("tools" "sprites")
INPUT_DIR="$(realpath ./src)"
OUTPUT_DIR="$(realpath ./build)"

# Create page
pandoc "$INPUT_DIR/index.md" \
    -o tmp.html \
    --resource-path "$INPUT_DIR" \
    --self-contained \
    --css="$INPUT_DIR/style.css" \
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
    | cat > "$OUTPUT_DIR/index.html"

# Copy favicon.ico
cp "$INPUT_DIR/favicon.ico" "$OUTPUT_DIR"

# Prepare sub domains
for sub in $SUBDOMAINS; do
    mkdir "$OUTPUT_DIR/$sub"
    cp "$INPUT_DIR/favicon.ico" "$OUTPUT_DIR/$sub"
    STYLE="$INPUT_DIR/style.css" INPUT_DIR="$INPUT_DIR/$sub" OUTPUT_DIR="$OUTPUT_DIR/$sub" "$INPUT_DIR/$sub/build.sh"
done

rm tmp.html
