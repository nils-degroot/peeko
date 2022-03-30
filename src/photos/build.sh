#! /usr/bin/env zsh

IMAGE_PREFIX="/"
PHOTO_OUT="$OUTPUT_DIR/photos"

basepage=$(cat "$INPUT_DIR/index.md")

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

		page+="\n\n![${photos[$photo_index]}](/photos/photos/$photo_index.jpg)"
		cp "$PHOTO_DIR/${photos[$photo_index]}" "$PHOTO_OUT/$photo_index.jpg"
	done

	page+="\n\n[Back](/photos)"

	echo "$page" | pandoc \
	    -o "$OUTPUT_DIR/$pagenumber.html" \
		--template "$TEMPLATE" \
		--metadata title="Peeko - Photos - $pagenumber"

	basepage+="\n\n[Page $pagenumber](/photos/$pagenumber.html)"

	let "parent_i+=1"
	if [ $((10*parent_i)) -gt ${#photos[@]} ]; then
		break
	fi
done

basepage+="\n\n[Back](/)"

# Build file
echo "$basepage" | pandoc \
    -o "$OUTPUT_DIR/index.html" \
	--template "$TEMPLATE"
