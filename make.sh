#! /usr/bin/env bash
# Copyright (C) 2009 Sebastian Pipping <sebastian@pipping.org>
# Licensed under GPLv3 or later
source config.sh

PROGRAMS=
${simulate} || PROGRAMS="${PROGRAMS} wiki2beamer pdflatex convert"
${optimize} && PROGRAMS="${PROGRAMS} optipng"
for program in ${PROGRAMS} ; do
	if [[ -z "$(type -p ${program})" ]]; then
		echo "ERROR: Command ${program} not available"
		exit 1
	fi
done

ABS_INPUT_DIR="${PWD}"/input
ABS_TEMP_DIR="${PWD}"/temp
ABS_OUTPUT_DIR="${PWD}"/output

HTML_FILE="${ABS_OUTPUT_DIR}/index.html"

mkdir -p "${ABS_INPUT_DIR}"
mkdir -p "${ABS_TEMP_DIR}"
mkdir -p "${ABS_OUTPUT_DIR}"

cp style.css "${ABS_OUTPUT_DIR}"/

theme_count=0
for theme_file in ${THEME_FILES} ; do
	theme_count=$((theme_count + 1))
done

color_theme_count=0
for theme_file in ${COLOR_THEME_FILES} ; do
	color_theme_count=$((color_theme_count + 1))
done

echo wiki2beamer content.txt \> content.tex
wiki2beamer content.txt > content.tex || exit 1

header_written=false

total_count=$((theme_count * color_theme_count))
total_number=0
even_row=false
for theme_file in ${THEME_FILES} ; do
	${even_row} && even_row=false || even_row=true
	theme=$(sed -e 's|^beamertheme||'  -e 's|\.sty$||' <<< "$(basename "${theme_file}")")

	case ${theme} in
	boxes) continue ;;
	*) ;;
	esac

	if ! ${header_written} ; then
		cat <<EOF 1>"${HTML_FILE}"
<html><head>
<link href='style.css' rel='stylesheet' type='text/css'>
<title>Beamer Theme Matrix</title>
</head><body>
<table class='shots'>
<tr>
	<th class='shots_odd'>
		<script type="text/javascript">
			var flattr_url = 'http://www.hartwork.org/beamer-theme-matrix/';
			var flattr_btn='compact';
		</script>
		<script src="http://api.flattr.com/button/load.js" type="text/javascript"></script>
		<noscript>
			&amp;lt;a href="http://flattr.com/thing/12664/Beamer-Theme-Matrix" target="_blank"&amp;gt;
			&amp;lt;img src="http://api.flattr.com/button/button-compact-static-100x17.png" title="Flattr this" border="0" /&amp;gt;&amp;lt;/a&amp;gt;
		</noscript>
	</th>
EOF
		even_col=false
		for color_theme_file in ${COLOR_THEME_FILES} ; do
			${even_col} && even_col=false || even_col=true
			color_theme=$(sed -e 's|^beamercolortheme||' -e 's|\.sty$||' <<< "$(basename "${color_theme_file}")")

			case ${color_theme} in
			structure|sidebartab) continue ;;
			*) ;;
			esac

			cell_class=shots_odd
			${even_col} && cell_class=shots_even
			printf "<th class='${cell_class}'>${color_theme}</th>" 1>>"${HTML_FILE}"
		done
		echo "</tr>" 1>>"${HTML_FILE}"
	fi

	cell_class=shots_odd
	${even_row} && cell_class=shots_even

	printf "<tr><th class='${cell_class}'>${theme}</th>" 1>>"${HTML_FILE}"

	even_col=false
	for color_theme_file in ${COLOR_THEME_FILES} ; do
		${even_col} && even_col=false || even_col=true
		color_theme=$(sed -e 's|^beamercolortheme||' -e 's|\.sty$||' <<< "$(basename "${color_theme_file}")")

		percent=$((total_number * 100 / total_count))
		total_number=$((total_number + 1))

		case ${color_theme} in
		structure|sidebartab)
			total_count=$((total_count - 1))
			total_number=$((total_number - 1))
			continue
			;;
		*) ;;
		esac

		printf '\033[01;32m[%3d%%] %s %s\033[00m\n' ${percent} "${theme}" "${color_theme}"

		input_base=beamer-${color_theme}-${theme}
		input_file="${input_base}".tex
		pdf_output_file="${input_base}".pdf
		png_output_base="${input_base}".png
		abs_input_file="${ABS_INPUT_DIR}/${input_file}"
		sed -e 's|\\usetheme{default}|\\usetheme{'${theme}'}|' \
		-e 's|\\usecolortheme{default}|\\usecolortheme{'${color_theme}'}|' template.tex > "${abs_input_file}"


		(
			cd "${ABS_TEMP_DIR}" || exit 1



			if ! ${simulate} ; then
				echo pdflatex "\"${abs_input_file}\"" 1\>/dev/null
				for i in {1..2}; do
					pdflatex "${abs_input_file}" 1>/dev/null || exit 1
				done
	
				echo convert -density 203.17x203.17 "\"${pdf_output_file}\"" "\"${png_output_base}\"" 1\>/dev/null
				convert -density 203.17x203.17 "${pdf_output_file}" "${png_output_base}" 1>/dev/null || exit 1
	
				for page_number in 0 1 ; do
					png_output_page_file="${input_base}-${page_number}.png"
					jpeg_output_page_file_thumbnail="${input_base}-${page_number}-thumbnail.jpg"

					if ${optimize} ; then
						echo optipng "${png_output_page_file}" \| grep --color=always -o '"[0-9]\+\.[0-9]\+% decrease"'
						optipng "${png_output_page_file}" | grep --color=always -o "[0-9]\+\.[0-9]\+% decrease" || exit 1
					fi

					echo convert -resize ${thumbnail_width}x${thumbnail_height} -quality 100 "\"${png_output_page_file}\"" "\"${jpeg_output_page_file_thumbnail}\"" 1\>/dev/null
					convert -resize ${thumbnail_width}x${thumbnail_height} -quality 100 "${png_output_page_file}" "${jpeg_output_page_file_thumbnail}" 1>/dev/null || exit 1
				done
	
				by_theme_dir="${ABS_OUTPUT_DIR}"/by-theme/"${theme}"/"${color_theme}"
				by_color_theme_dir="${ABS_OUTPUT_DIR}"/by-colortheme/"${color_theme}"/"${theme}"
				by_page_dir="${ABS_OUTPUT_DIR}"/by-page
	
				mkdir -p "${ABS_OUTPUT_DIR}/all/"
				mkdir -p "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/all/"
				mkdir -p "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/by-theme/${theme}/"
				mkdir -p "${ABS_OUTPUT_DIR}/by-theme/${theme}/all/"
				mkdir -p "${ABS_OUTPUT_DIR}/by-theme/${theme}/by-colortheme/${color_theme}/"
			fi

			cell_class=shots_odd
			${even_row} && ${even_col} && cell_class=shots_even
	
			printf "<td class='${cell_class}'>" 1>>"${HTML_FILE}"

			page_number=0
			for page in title content ; do
				png_output_page_file="${input_base}-${page_number}.png"
				jpeg_output_page_file_thumbnail="${input_base}-${page_number}-thumbnail.jpg"
				
				by_theme_link="${by_theme_dir}/${png_output_page_file}"
				by_color_theme_link="${by_color_theme_dir}/${png_output_page_file}"
				
				abs_png_output_page_file="${ABS_OUTPUT_DIR}"/all/"${png_output_page_file}"
				abs_jpeg_output_page_file_thumbnail="${ABS_OUTPUT_DIR}"/all/"${jpeg_output_page_file_thumbnail}"
				
				printf "<a href='all/${png_output_page_file}'><img src='all/${jpeg_output_page_file_thumbnail}' width='${thumbnail_width}' height='${thumbnail_height}' class='slideshot'>" 1>>"${HTML_FILE}"
				
				if ! ${simulate} ; then
					mv "${png_output_page_file}" "${abs_png_output_page_file}"
					mv "${jpeg_output_page_file_thumbnail}" "${abs_jpeg_output_page_file_thumbnail}"
				
					mkdir -p "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/by-page/${page}/"
					mkdir -p "${ABS_OUTPUT_DIR}/by-page/${page}/all/"
					mkdir -p "${ABS_OUTPUT_DIR}/by-page/${page}/by-colortheme/${color_theme}/"
					mkdir -p "${ABS_OUTPUT_DIR}/by-page/${page}/by-theme/${theme}/"
					mkdir -p "${ABS_OUTPUT_DIR}/by-theme/${theme}/by-page/${page}/"
				
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/all/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/by-page/${page}/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-colortheme/${color_theme}/by-theme/${theme}/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-page/${page}/all/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-page/${page}/by-colortheme/${color_theme}/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-page/${page}/by-theme/${theme}/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-theme/${theme}/all/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-theme/${theme}/by-colortheme/${color_theme}/${png_output_page_file}" 2>/dev/null
					ln "${abs_png_output_page_file}" "${ABS_OUTPUT_DIR}/by-theme/${theme}/by-page/${page}/${png_output_page_file}" 2>/dev/null
				fi

				page_number=$((page_number + 1))
			done

			printf "</td>" 1>>"${HTML_FILE}"
			exit 0
		) || exit 1
	done
	echo "</tr>" 1>>"${HTML_FILE}"
	header_written=true
done
echo "</table>" 1>>"${HTML_FILE}"
echo "</body></html>" 1>>"${HTML_FILE}"

printf '\033[01;32m[100%%]\033[00m\n'
exit 0
