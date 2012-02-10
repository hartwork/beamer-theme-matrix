#! /usr/bin/false
THEME_DIR=/usr/share/texmf-site/tex/latex/beamer/base/themes

simulate=false
optimize=true

thumbnail_width=181
thumbnail_height=136


# Collect themes with "default" going first
all_theme_files=${THEME_DIR}/theme/beamertheme*.sty
THEME_FILES=${THEME_DIR}/theme/beamerthemedefault.sty
for i in ${all_theme_files} ; do
	[[ "${i}" == *default.sty ]] && continue
	THEME_FILES+=" ${i}"
done

# Collect color themes with "default" going first
all_color_theme_files=${THEME_DIR}/color/beamercolortheme*.sty
COLOR_THEME_FILES=${THEME_DIR}/color/beamercolorthemedefault.sty
for i in ${all_color_theme_files} ; do
	[[ "${i}" == *default.sty ]] && continue
	COLOR_THEME_FILES+=" ${i}"
done
