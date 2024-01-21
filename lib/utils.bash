#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/nim-works/nimskull"
TOOL_NAME="nimskull"
TOOL_TEST="nim --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4 -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	list_github_tags
}

detect_target_triple() {
	# Get the OS name (Darwin or Linux)
	local os_name
	os_name=$(uname -s)

	# Get the machine hardware name (x86_64)
	local machine_hw_name
	machine_hw_name=$(uname -m)

	# Normalize and construct the target triple
	case "$os_name" in
	Linux)
		local os_type="linux-gnu"
		;;
	Darwin)
		local os_type="apple-darwin"
		;;
	*)
		fail "Unsupported operating system '$os_name'"
		;;
	esac

	# Construct the target triple
	echo "${machine_hw_name}-${os_type}"
}

check_sha256() {
	local src="$1"
	local dst="$2"
	local target
	target=$(detect_target_triple) || fail "Unable to detect target triple"

	case "$target" in
	x86_64-linux-gnu)
		# compare sha256 of src and dst on linux; fail if mismatch
		sha256sum --check --status <(echo "$src  $dst") || fail "Checksum mismatch for $dst"
		;;
	x86_64-apple-darwin)
		# compare sha256 of src and dst on macos; fail if mismatch
		shasum -a 256 --check --status <(echo "$src  $dst") || fail "Checksum mismatch for $dst"
		;;
	*)
		fail "Unsupported target triple '$target'"
		;;
	esac
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	target=$(detect_target_triple) || fail "Unable to detect target triple"

	# Map the target triple to the platform
	local platform
	case "$target" in
	x86_64-linux-gnu)
		platform="linux_amd64"
		;;
	x86_64-apple-darwin)
		platform="macosx_amd64"
		;;
	*)
		fail "Unsupported target triple '$target'"
		;;
	esac

	echo "* Downloading $TOOL_NAME release $version manifest..."
	url="$GH_REPO/releases/download/${version}/manifest.json"
	local manifest
	manifest=$(curl --fail --silent --location "$url")

	# sample input manifest:
	# {"manifestVersion":0,"version":"0.1.0-dev.21167","source":
	# {"name":"nim-0.1.0-dev.21167.tar.zst","sha256":"619b160b64822ccbe23e8069620cbf3720d6a0c355bb7c11e9e9ef764ab3a10d"},
	# "binaries":[
	# {"target":"x86_64-linux-gnu","name":"nim-0.1.0-dev.21167-linux_amd64.tar.zst","sha256":"f2d141c362c294c28036a44af4394afca9a74f5e88f5c913426a58592da02f45"},
	# {"target":"x86_64-apple-darwin","name":"nim-0.1.0-dev.21167-macosx_amd64.tar.zst","sha256":"2618608b4d5fc9b9f9da8b5cbba1547688761d1e84d6c64ffb1af6e5050c3e89"}]}
	#
	# we want to retrieve the tarball name for the target triple, so we'll
	# use jq to select it from the binaries array in the object:
	#
	local tarball
	tarball=$(echo "$manifest" | jq -r ".binaries[] | select(.target == \"$target\") | .name")
	checksum=$(echo "$manifest" | jq -r ".binaries[] | select(.target == \"$target\") | .sha256")
	echo "* Downloading $TOOL_NAME release $version for $target..."
	url="$GH_REPO/releases/download/${version}/${tarball}"
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"

	check_sha256 "$checksum" "$filename" || fail "Checksum mismatch for $filename"
	echo "* SHA256 checksum verified for ${version}-${platform} artifact."
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		# Assert nimskull executable exists.
		local executable
		executable="${install_path}/bin/$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$executable" || fail "Expected $executable to be executable."

		echo "* Installation successful; compiler --version output:"
		# Assert nimskull executable can be run by the operating system.
		"$executable" --version || fail "Could not run $executable --version"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
