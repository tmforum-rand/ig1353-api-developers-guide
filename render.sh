#!/bin/bash

# Simple script to build AsciiDoc files to PDF and HTML
# Usage: ./render.sh

set -e  # Exit on error

# Configuration
OUTPUT_DIR="./output"
PDF_THEME="tmf-pdf-theme.yml"
FONTS_DIR="fonts"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Copy CSS file to output directory for HTML
if [ -f "tmf-html-style.css" ]; then
    cp tmf-html-style.css "${OUTPUT_DIR}/"
fi

# Copy images directory to output for HTML
if [ -d "images" ]; then
    cp -r images "${OUTPUT_DIR}/"
    echo "Copied images directory to ${OUTPUT_DIR}/"
fi

# Check if theme file exists
THEME_ARG=""
if [ -f "${PDF_THEME}" ]; then
    THEME_ARG="-a pdf-theme=${PDF_THEME}"
    echo "Using PDF theme: ${PDF_THEME}"
else
    echo "Warning: ${PDF_THEME} not found, using default theme"
fi

# Check if fonts directory exists
FONTS_ARG=""
if [ -d "${FONTS_DIR}" ]; then
    FONTS_ARG="-a pdf-fontsdir=${FONTS_DIR};GEM_FONTS_DIR"
    echo "Using fonts directory: ${FONTS_DIR}"
fi

# Build diagrams from source files
DIAGRAMS_DIR="diagrams"
IMAGES_DIR="images"

if [ -d "${DIAGRAMS_DIR}" ] && command -v plantuml &> /dev/null; then
    echo "Building diagrams..."
    diagram_count=0

    for puml_file in "${DIAGRAMS_DIR}"/*.puml; do
        if [ -f "$puml_file" ]; then
            base_name=$(basename "$puml_file" .puml)
            output_svg="${IMAGES_DIR}/${base_name}.svg"

            # Check if diagram needs to be rebuilt (source newer than output, or output doesn't exist)
            if [ ! -f "$output_svg" ] || [ "$puml_file" -nt "$output_svg" ]; then
                echo "  → Generating ${base_name}.svg..."
                plantuml -tsvg -o "../${IMAGES_DIR}" "$puml_file"
                ((diagram_count++))
            fi
        fi
    done

    if [ $diagram_count -eq 0 ]; then
        echo "  ✓ All diagrams up to date"
    else
        echo "  ✓ Generated $diagram_count diagram(s)"
    fi
elif [ -d "${DIAGRAMS_DIR}" ]; then
    echo "Warning: plantuml command not found - diagram generation skipped"
    echo "  Generated diagrams in ${IMAGES_DIR}/ will be used"
    echo "  Install with: brew install plantuml (macOS) or see https://plantuml.com/download"
fi

# Build each part*.adoc file
for adoc_file in part*.adoc; do
    if [ -f "$adoc_file" ]; then
        echo "Building $adoc_file..."

        # Build PDF
        echo "  → PDF..."
        asciidoctor-pdf \
            -r asciidoctor-diagram \
            ${THEME_ARG} \
            ${FONTS_ARG} \
            -D "${OUTPUT_DIR}" \
            --trace \
            "$adoc_file"

        # Build HTML
        echo "  → HTML..."
        asciidoctor \
            -r asciidoctor-diagram \
            -a stylesheet=tmf-html-style.css \
            -a stylesdir=. \
            -a linkcss \
            -D "${OUTPUT_DIR}" \
            "$adoc_file"

        echo "✓ Built $(basename "$adoc_file" .adoc).pdf and .html"
    fi
done

echo ""
echo "Done! Output files are in ${OUTPUT_DIR}/"
