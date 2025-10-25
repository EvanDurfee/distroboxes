#!/usr/bin/env bash

set -euo pipefail

PROG="$(basename "$BASH_SOURCE")"

download_dir="$(mktemp -d)"

_exit () {
	exit_code="${1:-99}"
	# Untrap exit signal to avoid looping
	trap - EXIT
	# Kill any direct descendents before exiting
	pkill -P $$ || :
	if [ -e "$download_dir" ]; then
		rm -r "$download_dir"
	fi
	exit "$exit_code"
}

trap '_exit 7' SIGINT SIGTERM SIGHUP
trap '_exit $?' EXIT

print_help () {
	cat <<EOF
Usage: $PROG [OPTION...] TOOL...

Install JetBrains IDEs

Download and install jetbrains IDEs and add desktop files.

tools:
  idea (Intellij Idea Ultimate) for Java
  pycharm (PyCharm Professional) for python and typescript
  goland (GoLand) for golang
  clion (CLion) for C/C++
  rider (Rider) for C\# and .NET
  rustrover (RustRover) for rust
  rubyminer (RubyMiner) for ruby
  datagrip (DataGrip) for databases

options:
  -d, --install-dir DIR    directory to install to (default: ~/.local/share/JetBrains/apps)
      --desktop-dir DIR    directory to install desktop file to (default: ~/.local/share/applications)
      --no-install         skip tool installation
      --no-desktop         skip desktop (launcher) installation
  -h, --help               print usage information and exit

examples:

$PROG --install-dir=/opt/Jetbrains/apps --desktop-dir=/usr/local/share/applications pycharm goland
EOF
}

main() {
	# Requires gnu enhanced getopt
	ARGS=$(getopt --name "$PROG" --long 'help,install-dir:,desktop-dir:,no-desktop,no-install' --options 'hd:' -- "$@")
	eval set -- "$ARGS"

	echo "Done evaluating args"

	install_dir="${HOME}/.local/share/JetBrains/apps"
	desktop_dir="${HOME}/.local/share/applications"
	do_add_desktop_entry=true
	do_install=true
	while [ $# -gt 0 ]; do
		case "$1" in
			-h | --help)
				print_help
				exit 0
				;;
			-d | --install-dir)
				shift
				install_dir="$1"
				;;
			--desktop-dir)
				shift
				desktop_dir="$1"
				;;
			--no-desktop)
				do_add_desktop_entry=false
				;;
			--no-install)
				do_install=false
				;;
			--)
				shift
				break
				;;
		esac
		shift
	done

	if [ $# -lt 1 ]; then
		echo "No tool name specified" >&2
		exit 1
	fi

	if ! $do_install && ! $do_add_desktop_entry; then
		echo "Install and desktop entry disabled, nothing to do" >&2
		exit 1
	fi

	arch=linux  # Just linux x86_64 for now
	while [ $# -gt 0 ]; do
		unset tool_name
		unset tool_code
		unset binary_name
		case "$1" in
			intellij | idea | java)
				tool_name="IntelliJ IDEA"
				tool_code=IU
				binary_name=idea
				;;
			pycharm | python)
				tool_name="PyCharm"
				tool_code=PY
				binary_name=pycharm
				;;
			goland | go | golang)
				tool_name="GoLand"
				tool_code=GO
				binary_name=goland
				;;
			clion | c | "c++" | cpp)
				tool_name="CLion"
				tool_code=CL
				binary_name=clion
				;;
			rider | "c#" | "C#")
				tool_name="Rider"
				tool_code=RD
				binary_name=rider
				;;
			rustrover | rust | rover)
				tool_name="RustRover"
				tool_code=RR
				binary_name=rustrover
				;;
			rubyminer | ruby)
				tool_name="RubyMiner"
				tool_code=RM
				binary_name=rubyminer
				;;
			datagrip)
				tool_name="DataGrip"
				tool_code=DG
				binary_name=datagrip
				;;
			*)
				echo "Unrecognized tool '$1'" >&2
				exit 1
		esac
		if $do_install; then
			install_jetbrains_ide "$install_dir" "$tool_name" "$binary_name" "$tool_code" "$arch"
		fi
		if $do_add_desktop_entry; then
			add_desktop_entry "$desktop_dir"  "$install_dir" "$tool_name" "$binary_name"
		fi
		shift
	done
}

add_desktop_entry() {
	desktop_dir="$1"; shift
	install_dir="$1"; shift
	tool_name="$1"; shift
	binary_name="$1"; shift

	cat <<EOF | tee "$desktop_dir"/"$binary_name".desktop >/dev/null
[Desktop Entry]
Name="${tool_name}"
Exec="${install_dir}/${binary_name}/bin/${binary_name}" %u
Version=1.0
Type=Application
Categories=Development;IDE;
Terminal=false
Icon="${install_dir}/${binary_name}/bin/${binary_name}.svg"
Comment="JetBrains ${tool_name} IDE"
StartupWMClass="jetbrains-${binary_name}"
StartupNotify=true
EOF
}

install_jetbrains_ide() {
	install_dir="$1"; shift
	tool_name="$1"; shift
	binary_name="$1"; shift
	tool_code="$1"; shift
	arch="$1"; shift

	if [ -e "${install_dir}/${binary_name}/bin/${binary_name}" ]; then
		# Already installed
		return 0
	fi

	# https://plugins.jetbrains.com/docs/marketplace/product-codes.html
	mkdir -p "${download_dir}/${binary_name}"
	curl --fail-with-body -L "https://download.jetbrains.com/product?code=${tool_code}&platform=${arch}" \
		| tar xvz -C "${download_dir}/${binary_name}" --strip 1

	mkdir -p "${install_dir}"
	mv --no-target-directory "${download_dir}"/"${binary_name}" "${install_dir}"/"${binary_name}"
}

main "$@"
