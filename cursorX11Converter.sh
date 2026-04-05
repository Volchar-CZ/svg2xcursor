#!/usr/bin/env bash

set -e

#   How to run so I don't have to always type it out
# ./cursorX11Converter.sh defaultVz4.svg -x 4.5 -y 0.5 -i flatpak run org.inkscape.Inkscape -o vz2

# -------------------------
# DEFAULT CONFIG
# -------------------------
INKSCAPE_CMD=(inkscape)
# SIZES=(16 24 32 48 64 80 96 112 128 256 512) # If you are me, then a good idea
SIZES=(16 32 64 96 128) # REALISTIC

# -------------------------
# ARGUMENT PARSING
# -------------------------
SVG=""                          # Path to SVG file
HOTSPOT_X=0                     # the hotspot localition in px from the left
HOTSPOT_Y=0                     # the hotspot localition in px from the top
BASENAME=""                     # Name; either inputed or taken from the svg name.

# Parsing arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--inkscape)
            shift
            INKSCAPE_CMD=()
            while [[ $# -gt 0 && "$1" != -* ]]; do  # Check if bin was provided
                INKSCAPE_CMD+=("$1")
                shift
            done
            ;;
        -x)
            HOTSPOT_X="$2" # MANDATORY
            shift 2
            ;;
        -y)
            HOTSPOT_Y="$2" # MANDATORY
            shift 2
            ;;
        -o|--output)
            shift
            BASENAME="$1" # Leave out if you want to do a batch run
            shift
            ;;
        *)
            if [[ -z "$SVG" ]]; then
                SVG="$1"
                shift
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            ;;
    esac
done

# If there's no name inputed, assume the file's name is the desired output name.
# Good for batch runs
if [[ -z "$BASENAME" ]]; then
    BASENAME=$(basename "$SVG" .svg)
fi

# -------------------------
# VALIDATION
# -------------------------
if [[ -z "$SVG" || -z "$HOTSPOT_X" || -z "$HOTSPOT_Y" || -z "$BASENAME" ]]; then
    echo "Usage:"
    echo "./script.sh cursor.svg -x 3.5 -y 0.5 [-i inkscape_path] -o arrow"
    exit 1
fi

if [[ ! -f "$SVG" ]]; then
    echo "SVG file not found!"
    exit 1
fi

# -------------------------
# PREP
# -------------------------
WORKDIR="./cursor_build"
mkdir -p "$WORKDIR"

CONF_FILE="$WORKDIR/${BASENAME}.in"
> "$CONF_FILE"

echo "[*] SVG: $SVG"
echo "[*] Hotspot: $HOTSPOT_X, $HOTSPOT_Y"
echo "[*] Output basename: $BASENAME"
echo "[*] Inkscape command: ${INKSCAPE_CMD[@]}"

# -------------------------
# MAIN LOOP
# -------------------------
for SIZE in "${SIZES[@]}"; do
    SCALE=$(echo "$SIZE / 32" | bc -l)

    HX=$(echo "$HOTSPOT_X * $SCALE" | bc -l)
    HY=$(echo "$HOTSPOT_Y * $SCALE" | bc -l)

    # round to nearest integer
    HX_INT=$(LC_NUMERIC=C printf "%.0f" "$HX")
    HY_INT=$(LC_NUMERIC=C printf "%.0f" "$HY")

    OUT_PNG="$WORKDIR/${BASENAME}_${SIZE}.png"

    echo "[*] Exporting ${SIZE}px (hotspot: $HX_INT,$HY_INT)"

"${INKSCAPE_CMD[@]}" "$SVG" -w "$SIZE" -h "$SIZE" -o "$OUT_PNG" 2>/dev/null

    echo "$SIZE $HX_INT $HY_INT $OUT_PNG" >> "$CONF_FILE"
done

# -------------------------
# GENERATE CURSOR
# -------------------------
OUTPUT_CURSOR="./${BASENAME}"

echo "[*] Running xcursorgen..."
xcursorgen "$CONF_FILE" "$OUTPUT_CURSOR"

echo "[✓] Done!"
echo "Cursor file: $OUTPUT_CURSOR"

mv $OUTPUT_CURSOR $HOME/.icons/Volch-cursors-TestBed/cursors/$OUTPUT_CURSOR