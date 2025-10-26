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

DEFAULT_USER_INSTALL_DIR="${XDG_DATA_HOME:-"${HOME}"/.local/share}/JetBrains/apps"
DEFAULT_USER_DESKTOP_DIR="${XDG_DATA_HOME:-"${HOME}"/.local/share}/applications"
DEFAULT_USER_BIN_DIR="${HOME}/.local/bin"

DEFAULT_SYSTEM_INSTALL_DIR="/opt/JetBrains/apps"
DEFAULT_SYSTEM_DESKTOP_DIR="/usr/local/share/applications"
DEFAULT_SYSTEM_BIN_DIR="/usr/local/bin"

DEFAULT_KEYWORDS="JetBrains;IDE;code;"

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
      --system             default to system-wide install directories
      --user               default to user install directories
      --no-install         skip tool installation
      --only-install       only install the tool, skip desktop and bin setup
      --no-desktop         skip desktop (launcher) installation
      --no-bin             skip adding symlink to bin dir
  -h, --help               print usage information and exit

For fine-grained control, the exact directory for each component can be
specified.

install dirs:
  -d, --install-dir DIR    directory to install to (default: "$DEFAULT_USER_INSTALL_DIR")
      --desktop-dir DIR    directory to install desktop file to (default: "$DEFAULT_USER_DESKTOP_DIR")
      --bin-dir     DIR    directory from which to symlink the editor (default: "$DEFAULT_USER_BIN_DIR")

examples:

User install with no bin added to "${DEFAULT_USER_BIN_DIR}":
  $PROG --user --no-bin pycharm goland

System install to with custom data dir:
  $PROG --system --install-dir=/var/opt/Jetbrains/apps idea
EOF
}

main() {
	# Requires gnu enhanced getopt
	ARGS=$(getopt --name "$PROG" --long 'help,user,system,install-dir:,desktop-dir:,bin-dir:,no-install,only-install,no-desktop,no-bin' --options 'hd:' -- "$@")
	eval set -- "$ARGS"

	install_dir=""
	desktop_dir=""
	bin_dir=""
	default_to_user=true
	do_install=true
	do_add_desktop_entry=true
	do_link_bin=true
	while [ $# -gt 0 ]; do
		case "$1" in
			-h | --help)
				print_help
				exit 0
				;;
			--user)
				default_to_user=true
				;;
			--system)
				default_to_user=false
				;;
			-d | --install-dir)
				shift
				install_dir="$1"
				;;
			--desktop-dir)
				shift
				desktop_dir="$1"
				;;
			--bin-dir)
				shift
				bin_dir="$1"
				;;
			--no-install)
				do_install=false
				;;
			--only-install)
				do_install=true
				do_add_desktop_entry=false
				do_link_bin=false
				;;
			--no-desktop)
				do_add_desktop_entry=false
				;;
			--no-bin)
				do_link_bin=false
				;;
			--)
				shift
				break
				;;
		esac
		shift
	done

	if [ -z "$install_dir" ]; then
		if $default_to_user; then install_dir="$DEFAULT_USER_INSTALL_DIR"; else install_dir="$DEFAULT_SYSTEM_INSTALL_DIR"; fi
	fi
	if [ -z "$desktop_dir" ]; then
		if $default_to_user; then desktop_dir="$DEFAULT_USER_DESKTOP_DIR"; else desktop_dir="$DEFAULT_SYSTEM_DESKTOP_DIR"; fi
	fi
	if [ -z "$bin_dir" ]; then
		if $default_to_user; then bin_dir="$DEFAULT_USER_BIN_DIR"; else bin_dir="$DEFAULT_SYSTEM_BIN_DIR"; fi
	fi

	if [ $# -lt 1 ]; then
		echo "No tool name specified" >&2
		exit 1
	fi

	if ! $do_install && ! $do_add_desktop_entry && ! $do_link_bin; then
		echo "Install, desktop entry, and bin disabled; nothing to do" >&2
		exit 1
	fi

	arch=linux  # Just linux x86_64 for now
	while [ $# -gt 0 ]; do
		unset tool_name
		unset tool_code
		unset binary_name
		unset keywords
		case "$1" in
			intellij | idea | java)
				tool_name="IntelliJ IDEA"
				tool_code=IU
				binary_name=idea
				keywords="${DEFAULT_KEYWORDS}${tool_code};java;groovy;kotlin;"
				;;
			pycharm | python)
				tool_name="PyCharm"
				tool_code=PY
				binary_name=pycharm
				keywords="${DEFAULT_KEYWORDS}${tool_code};python;javascript;typescript;"
				;;
			goland | go | golang)
				tool_name="GoLand"
				tool_code=GO
				binary_name=goland
				keywords="${DEFAULT_KEYWORDS}${tool_code};go;golang;"
				;;
			clion | c | "c++" | cpp)
				tool_name="CLion"
				tool_code=CL
				binary_name=clion
				keywords="${DEFAULT_KEYWORDS}${tool_code};c;c++;cpp;"
				;;
			rider | "c#" | "C#")
				tool_name="Rider"
				tool_code=RD
				binary_name=rider
				keywords="${DEFAULT_KEYWORDS}${tool_code};C#;F#;.NET;"
				;;
			rustrover | rust | rover)
				tool_name="RustRover"
				tool_code=RR
				binary_name=rustrover
				keywords="${DEFAULT_KEYWORDS}${tool_code};rust;"
				;;
			rubyminer | ruby)
				tool_name="RubyMiner"
				tool_code=RM
				binary_name=rubyminer
				keywords="${DEFAULT_KEYWORDS}${tool_code};ruby;"
				;;
			datagrip)
				tool_name="DataGrip"
				tool_code=DG
				binary_name=datagrip
				keywords="${DEFAULT_KEYWORDS}${tool_code};"
				;;
			*)
				echo "Unrecognized tool '$1'" >&2
				exit 1
		esac
		if $do_install; then
			install_jetbrains_ide "$install_dir" "$tool_name" "$binary_name" "$tool_code" "$arch"
		fi
		if $do_add_desktop_entry; then
			add_desktop_entry "$desktop_dir" "$install_dir" "$tool_name" "$binary_name" "$keywords"
		fi
		if $do_link_bin; then
			ln --symbolic --force --no-target-directory "$install_dir"/"$binary_name"/bin/"$binary_name" "$bin_dir"/"$binary_name"
		fi
		shift
	done
}

add_desktop_entry() {
	desktop_dir="$1"; shift
	install_dir="$1"; shift
	tool_name="$1"; shift
	binary_name="$1"; shift
	keywords="$1"; shift

	# create desktop launcher
	cat <<EOF | tee "$desktop_dir"/"$binary_name".desktop >/dev/null
[Desktop Entry]
Name=${tool_name}
Exec="${install_dir}/${binary_name}/bin/${binary_name}" %u
Version=1.0
Type=Application
Categories=Development;IDE;
Keywords=$keywords
Terminal=false
Icon=${install_dir}/${binary_name}/bin/${binary_name}.svg
# Icon=${binary_name}
Comment=JetBrains ${tool_name} IDE
StartupWMClass=jetbrains-${binary_name}
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
