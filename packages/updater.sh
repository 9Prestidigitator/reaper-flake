#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused jq nix perl

set -euo pipefail

readonly derivation="$(dirname "$0")/reaper.nix"
readonly download_page="https://www.reaper.fm/download.php"

reaper_version="$({
  curl --fail --location --silent --show-error "$download_page" \
    | sed -nE 's/.*Version ([0-9]+\.[0-9]+).*/\1/p' \
    | sed -n '1p'
})"

if [[ -z "$reaper_version" ]]; then
  echo "Could not determine the latest REAPER version from $download_page" >&2
  exit 1
fi

readonly major_version="${reaper_version%%.*}"
readonly compact_version="${reaper_version//./}"
readonly base_url="https://www.reaper.fm/files/${major_version}.x/reaper${compact_version}"

hash_for_url() {
  local url="$1"

  # nix store prefetch-file returns the flat-file SHA-256 in the SRI format
  # expected by fetchurl, so no conversion from nix-prefetch-url is needed.
  nix store prefetch-file --json --hash-type sha256 "$url" | jq --raw-output '.hash'
}

readonly x86_64_linux_url="${base_url}_linux_x86_64.tar.xz"
readonly aarch64_linux_url="${base_url}_linux_aarch64.tar.xz"
readonly darwin_url="${base_url}_universal.dmg"

echo "Updating REAPER to $reaper_version"
echo "Prefetching $x86_64_linux_url"
x86_64_linux_hash="$(hash_for_url "$x86_64_linux_url")"
echo "Prefetching $aarch64_linux_url"
aarch64_linux_hash="$(hash_for_url "$aarch64_linux_url")"
echo "Prefetching $darwin_url"
darwin_hash="$(hash_for_url "$darwin_url")"

REAPER_VERSION="$reaper_version" \
X86_64_LINUX_HASH="$x86_64_linux_hash" \
AARCH64_LINUX_HASH="$aarch64_linux_hash" \
DARWIN_HASH="$darwin_hash" \
perl -0pi -e '
  sub replace_once {
    my ($pattern, $replacement, $label) = @_;
    my $matches = () = $_ =~ /$pattern/g;
    die "Expected exactly one $label in $ARGV, found $matches\n" unless $matches == 1;
    s/$pattern/$replacement/;
  }

  replace_once(qr/^    version = "[^"]+";$/m, qq{    version = "$ENV{REAPER_VERSION}";}, "version");
  replace_once(qr/^        then "sha256-[^"]+"$/m, qq{        then "$ENV{DARWIN_HASH}"}, "Darwin hash");
  replace_once(qr/^            x86_64-linux = "sha256-[^"]+";$/m, qq{            x86_64-linux = "$ENV{X86_64_LINUX_HASH}";}, "x86_64-linux hash");
  replace_once(qr/^            aarch64-linux = "sha256-[^"]+";$/m, qq{            aarch64-linux = "$ENV{AARCH64_LINUX_HASH}";}, "aarch64-linux hash");
' "$derivation"

echo "Updated $derivation"
