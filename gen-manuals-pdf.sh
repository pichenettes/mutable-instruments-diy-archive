#!/usr/bin/env bash
#
# Generate PDF user manuals for Mutable Instruments products
#
# Copyright (C) 2026 Robert Ham <rah@settrans.net>
#
# This script needs to be run in an environment with the following
# Python packages installed:
#
#   mkdocs mkdocs-material mkdocs-to-pdf
#
# To build the manuals, run this script from within the
# mutable-instruments-diy-archive directory like so:
#
# $ cd /somewhere/mutable-instruments-diy-archive
# $ ./gen-manuals-pdf.sh ../mutable-instruments-manuals
#
# When the script completes, the manuals will be deposited in the
# supplied directory, ../mutable-instruments-manuals above.
#

OUTPUT_DIR="$( realpath "$1" )"

TEMP_DIR="$( mktemp -d )"
function rm_temp() {
    rm -rf "${TEMP_DIR}"
}
trap rm_temp EXIT

mkdir -p "${OUTPUT_DIR}"

find . -type f -name "manual.md" | while read manual; do
    dir=$( dirname ${manual} )
    name=$( basename ${dir} )

    manual_out="$( realpath "${TEMP_DIR}/${name}" )"
    mkdocs new "${manual_out}"
    ln -s "$( realpath ${dir}/../static )" "${manual_out}/docs/static"
    sed -e 's_../static_static_' ${manual} > "${manual_out}/docs/index.md"

    cat > "${manual_out}"/mkdocs.yml <<EOF
site_name: Mutable Instruments ${name@u} Manual
site_author: Émilie Gillet
theme:
    name: material
plugins:
  - to-pdf
EOF

    stylesheet_dir="${manual_out}/templates"
    mkdir -p "${stylesheet_dir}"
    cat > "${stylesheet_dir}/styles.scss" <<EOF
  html {
    font-size: 125%;
  }

  body {
    font-size: 100%;
  }

  article {
    font-size: 100%;
  }

  pre,
  code,
  var,
  samp,
  kbd,
  tt {
    font-size: 1em;
  }
EOF

    (
        cd "${manual_out}"
        mkdocs build
        cp "${manual_out}/site/pdf/document.pdf" "${OUTPUT_DIR}/${name}.pdf"
    )
done
