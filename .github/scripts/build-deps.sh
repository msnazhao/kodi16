#!/bin/bash
# Build one stage of tools/depends inside the 16.04 build container.
#   build-deps.sh native | target | smb
#
# Source trees are re-cloned in every job, so make's .installed-* markers are lost while
# the installed prefix is cached. Each prefix therefore carries a manifest
# (<prefix>/.built/<pkg>); finished packages are skipped with `make -o <pkg>`.
# (no `set -u`: bash 4.3 treats empty arrays as unbound)

kind=${1:?usage: build-deps.sh native|target|smb}
D="$SRC/tools/depends"

case "$kind" in
  native) dir="$D/native"; prefix="$NATIVE_PREFIX"; pkgs=();                    extra=() ;;
  # samba is built and cached by its own job
  target) dir="$D/target"; prefix="$TARGET_PREFIX"; pkgs=();                    extra=(-k -o samba-gplv3) ;;
  smb)    dir="$D/target"; prefix="$TARGET_PREFIX"; pkgs=(libiconv samba-gplv3); extra=() ;;
  *) echo "unknown stage: $kind" >&2; exit 2 ;;
esac

mkdir -p "$prefix/.built"

rc=0
if [ ${#pkgs[@]} -eq 0 ]; then
  skip=()
  for f in "$prefix"/.built/*; do
    [ -e "$f" ] && skip+=(-o "$(basename "$f")")
  done
  echo "== $kind: skipping $(( ${#skip[@]} / 2 )) cached packages"
  make -C "$dir" -j"$NPROC" "${extra[@]}" "${skip[@]}" || rc=$?
  for m in "$dir"/*/.installed-*; do
    [ -e "$m" ] && touch "$prefix/.built/$(basename "$(dirname "$m")")"
  done
else
  for p in "${pkgs[@]}"; do
    if [ -e "$prefix/.built/$p" ]; then echo "== $p cached"; continue; fi
    make -C "$dir/$p" -j"$NPROC" || { rc=$?; break; }
    for m in "$dir/$p"/.installed-*; do
      [ -e "$m" ] && touch "$prefix/.built/$p"
    done
  done
fi

echo "== $kind manifest: $(ls "$prefix/.built" | wc -l) packages, rc=$rc"
exit "$rc"
