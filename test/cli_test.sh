#!/bin/sh
set -eu

exe=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/bin"
cat > "$work/bin/fzf" <<'EOF'
#!/bin/sh
sed -n '1p'
EOF
chmod +x "$work/bin/fzf"

export PATH="$work/bin:$PATH"
export XDG_DATA_HOME="$work/data"

if "$exe" > "$work/missing.out" 2>&1; then
  echo "browsing without a saved library should fail" >&2
  exit 1
fi
grep -F "load FILE first" "$work/missing.out"

cat > "$work/first.txt" <<'EOF'
Book A
- Your Highlight on page 1

Quote One
==========
EOF

"$exe" load "$work/first.txt" > "$work/first.out"
grep -F "Loaded 1 highlights" "$work/first.out"
grep -F "Quote One" "$work/first.out"
test -f "$XDG_DATA_HOME/kindle-highlights/library.sexp"

rm "$work/first.txt"
"$exe" > "$work/browse.out"
grep -F "Quote One" "$work/browse.out"
if "$exe" load "$work/first.txt" > "$work/failed_load.out" 2>&1; then
  echo "loading a missing file should fail" >&2
  exit 1
fi
"$exe" > "$work/after_failed_load.out"
grep -F "Quote One" "$work/after_failed_load.out"

cat > "$work/second.txt" <<'EOF'
Book B
- Your Highlight on page 2

Quote Two
==========
EOF

"$exe" load "$work/second.txt" > "$work/second.out"
"$exe" > "$work/replaced.out"
grep -F "Quote Two" "$work/replaced.out"
if grep -F "Quote One" "$work/replaced.out"; then
  echo "replacement kept an old quote" >&2
  exit 1
fi

: > "$work/empty.txt"
"$exe" load "$work/empty.txt" > "$work/empty.out"
"$exe" > "$work/empty_browse.out"
grep -F "No highlights found in the saved library" "$work/empty_browse.out"
