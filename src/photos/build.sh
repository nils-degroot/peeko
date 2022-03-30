#! /usr/bin/env zsh

IMAGE_PREFIX="/"
PHOTO_OUT="$OUTPUT_DIR/photos"

basepage=$(cat "$INPUT_DIR/index.md")

# Remove unwanted tags
cat "$INPUT_DIR/tmp.html" | sed \
    -e '/^[[:space:]]*$/d' \
    -e 's/<body/<body style=\"margin-top: 0\"/g' \
    | cat > "$OUTPUT_DIR/index.html"

rm "$INPUT_DIR/tmp.html"

# Setup photos
if [ -d "$PHOTO_OUT" ]; then
	rm -rf $PHOTO_OUT
fi

cp "$STYLE" "$OUTPUT_DIR"

mkdir "$PHOTO_OUT"
photos=($(ls $PHOTO_DIR))

parent_i=0
while true; do
	pagenumber=$((parent_i+1))
	page="## Photos - $pagenumber"

	for i in {1..10}; do
		photo_index=$((10*parent_i+i))
		if [ $photo_index -gt ${#photos[@]} ]; then
			break
		fi

		page+="\n\n![${photos[$photo_index]}](/photos/$photo_index.jpg)"
		cp "$PHOTO_DIR/${photos[$photo_index]}" "$PHOTO_OUT/$photo_index.jpg"
	done

	echo "$page" | pandoc \
	    -o "$OUTPUT_DIR/$pagenumber.html" \
	    --css="/style.css" \
		--template "$TEMPLATE" \
		--metadata title="Peeko - Photos - $pagenumber"

	basepage+="\n\n[Page $pagenumber](/$pagenumber.html)"

	let "parent_i+=1"
	if [ $((10*parent_i)) -gt ${#photos[@]} ]; then
		break
	fi
done

# Build file
echo "$basepage" | pandoc \
    -o "$INPUT_DIR/tmp.html" \
    --self-contained \
    --css="$STYLE" \
	--template "$TEMPLATE"

