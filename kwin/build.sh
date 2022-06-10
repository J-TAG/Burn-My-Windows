#!/bin/bash

# -------------------------------------------------------------------------------------- #
#           )                                                   (                        #
#        ( /(   (  (               )    (       (  (  (         )\ )    (  (             #
#        )\()) ))\ )(   (         (     )\ )    )\))( )\  (    (()/( (  )\))(  (         #
#       ((_)\ /((_|()\  )\ )      )\  '(()/(   ((_)()((_) )\ )  ((_)))\((_)()\ )\        #
#       | |(_|_))( ((_)_(_/(    _((_))  )(_))  _(()((_|_)_(_/(  _| |((_)(()((_|(_)       #
#       | '_ \ || | '_| ' \))  | '  \()| || |  \ V  V / | ' \)) _` / _ \ V  V (_-<       #
#       |_.__/\_,_|_| |_||_|   |_|_|_|  \_, |   \_/\_/|_|_||_|\__,_\___/\_/\_//__/       #
#                                  |__/                                                  #
#                        Copyright (c) 2021 Simon Schneegans                             #
#           Released under the GPLv3 or later. See LICENSE file for details.             #
# -------------------------------------------------------------------------------------- #

# Exit the script when one command fails.
set -e

# Go to the script's directory.
cd "$( cd "$( dirname "$0" )" && pwd )" || \
  { echo "ERROR: Could not find kwin directory."; exit 1; }

BUILD_DIR="_build"

mkdir -p "$BUILD_DIR"

# $1: The nick of the effect (e.g. "energize-a")
# $2: The name of the effect (e.g. "Energize A")
# $3: A short description of the effect (e.g. "Beam your windows away")
generate() {

  # Use the nick for the effect's directory name by replacing dashes by underscoares.
  DIR_NAME="kwin4_effect_$(echo $1 | tr '-' '_')"

  # Use the name of the effect for the JavaScript class name by removing all spaces.
  EFFECT_CLASS="BurnMyWindows$(echo $2 | tr -d ' ')"

  # Create resource directories.
  mkdir -p "$BUILD_DIR/$DIR_NAME/contents/shaders"
  mkdir -p "$BUILD_DIR/$DIR_NAME/contents/code"
  mkdir -p "$BUILD_DIR/$DIR_NAME/contents/config"
  mkdir -p "$BUILD_DIR/$DIR_NAME/contents/ui"

  # Copy the config and ui files.
  cp "$DIR_NAME/main.xml" "$BUILD_DIR/$DIR_NAME/contents/config"
  cp "$DIR_NAME/config.ui" "$BUILD_DIR/$DIR_NAME/contents/ui"

  perl -pe "s/%LOAD_CONFIG%/$(tr '/' '\f' < "$DIR_NAME/loadConfig.js")/g;" \
       main.js.in | tr '\f' '/' > "$BUILD_DIR/$DIR_NAME/contents/code/main.js"

  perl -pi -e "s/%EFFECT_CLASS%/$EFFECT_CLASS/g;" "$BUILD_DIR/$DIR_NAME/contents/code/main.js"
  perl -pi -e "s/%SHADER_NAME%/$1/g;"             "$BUILD_DIR/$DIR_NAME/contents/code/main.js"

  cp metadata.desktop.in "$BUILD_DIR/$DIR_NAME/metadata.desktop"
  perl -pi -e "s/%ICON%/$1/g;"            "$BUILD_DIR/$DIR_NAME/metadata.desktop"
  perl -pi -e "s/%NAME%/$2/g;"            "$BUILD_DIR/$DIR_NAME/metadata.desktop"
  perl -pi -e "s/%DESCRIPTION%/$3/g;"     "$BUILD_DIR/$DIR_NAME/metadata.desktop"
  perl -pi -e "s/%DIR_NAME%/$DIR_NAME/g;" "$BUILD_DIR/$DIR_NAME/metadata.desktop"

  {
    echo "#version 140"
    echo "#define KWIN"
    echo ""
    echo "// This file is automatically generated during the build process."
    echo ""
    cat "../resources/shaders/common.glsl"
    cat "../resources/shaders/$1.frag"
  } > "$BUILD_DIR/$DIR_NAME/contents/shaders/$1_core.frag"

  {
    echo "#define KWIN_LEGACY"
    echo ""
    echo "// This file is automatically generated during the build process."
    echo ""
    cat "../resources/shaders/common.glsl"
    cat "../resources/shaders/$1.frag"
  } > "$BUILD_DIR/$DIR_NAME/contents/shaders/$1.frag"
}

generate "tv" "TV Effect" "Make windows close like turning off a TV"
generate "energize-a" "Energize A" "Beam your windows away"
# generate "fire" "Fire" "Make windows burn"