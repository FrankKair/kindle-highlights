#!/bin/sh
set -eu

exe=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/bin"
mkdir "$work/tmp"
export TMPDIR="$work/tmp"
cat > "$work/bin/fzf" <<'EOF'
#!/bin/sh
set -eu
if [ -n "${FZF_TEST_EXIT_CODE:-}" ]; then
  cat > /dev/null
  exit "$FZF_TEST_EXIT_CODE"
fi
count=0
if [ -f "$FZF_TEST_STATE" ]; then
  count=$(cat "$FZF_TEST_STATE")
fi
if [ "$count" -ge "${FZF_TEST_SELECTIONS:-1}" ]; then
  cat > /dev/null
  exit 130
fi
echo "$((count + 1))" > "$FZF_TEST_STATE"
tee "$FZF_TEST_OPTIONS" | sed -n "${FZF_TEST_ROW:-1}p"
EOF
cat > "$work/bin/less" <<'EOF'
#!/bin/sh
set -eu
test "$1" = '-P'
test "$2" = 'q to return | / to search'
test "$3" = '--'
printf '%s\n' "$4" >> "$PAGER_TEST_PATHS"
if [ -n "${PAGER_TEST_EXIT_CODE:-}" ]; then
  exit "$PAGER_TEST_EXIT_CODE"
fi
cat "$4"
EOF
chmod +x "$work/bin/fzf" "$work/bin/less"

export PATH="$work/bin:$PATH"
export XDG_DATA_HOME="$work/data"
export FZF_TEST_STATE="$work/selector-state"
export FZF_TEST_OPTIONS="$work/selector-options"
export PAGER_TEST_PATHS="$work/pager-paths"

run_cli () {
  rm -f "$FZF_TEST_STATE" "$PAGER_TEST_PATHS"
  "$exe" "$@"
}

check_selector_cleanup () {
  for path in "$TMPDIR"/kindle-books-*; do
    test ! -e "$path"
  done
}

if run_cli > "$work/missing.out" 2>&1; then
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

run_cli load "$work/first.txt" > "$work/first.out"
grep -F "Loaded 1 highlights" "$work/first.out"
grep -F -- "--- Book A ---" "$work/first.out"
grep -F "Quote One" "$work/first.out"
test -f "$XDG_DATA_HOME/kindle-highlights/library.sexp"
check_selector_cleanup
while IFS= read -r path; do
  test ! -e "$path"
done < "$PAGER_TEST_PATHS"

rm "$work/first.txt"
run_cli > "$work/browse.out"
grep -F "Quote One" "$work/browse.out"

# Select twice in one process, then cancel the selector.
export FZF_TEST_SELECTIONS=2
run_cli > "$work/repeated.out"
test "$(grep -c 'Quote One' "$work/repeated.out")" -eq 2
unset FZF_TEST_SELECTIONS

# Cancelling immediately should exit successfully without displaying quotes.
export FZF_TEST_SELECTIONS=0
run_cli > "$work/cancelled.out"
test ! -s "$work/cancelled.out"
test ! -e "$PAGER_TEST_PATHS"
check_selector_cleanup
unset FZF_TEST_SELECTIONS

if run_cli load "$work/first.txt" > "$work/failed_load.out" 2>&1; then
  echo "loading a missing file should fail" >&2
  exit 1
fi
run_cli > "$work/after_failed_load.out"
grep -F "Quote One" "$work/after_failed_load.out"

cat > "$work/second.txt" <<'EOF'
Book B
- Your Highlight on page 2

Quote Two
==========
EOF

run_cli load "$work/second.txt" > "$work/second.out"
run_cli > "$work/replaced.out"
grep -F "Quote Two" "$work/replaced.out"
if grep -F "Quote One" "$work/replaced.out"; then
  echo "replacement kept an old quote" >&2
  exit 1
fi

# Selector failures should report an error and fail the command.
export FZF_TEST_EXIT_CODE=2
if run_cli > "$work/selector_failed.out" 2>&1; then
  echo "a selector error should fail the command" >&2
  exit 1
fi
unset FZF_TEST_EXIT_CODE

grep -F "Book selection failed:" "$work/selector_failed.out"
check_selector_cleanup

# Pager failures should fail the command and still clean up the temporary file.
export PAGER_TEST_EXIT_CODE=1
if run_cli > "$work/pager_failed.out" 2>&1; then
  echo "a pager error should fail the command" >&2
  exit 1
fi
unset PAGER_TEST_EXIT_CODE

grep -F "Could not display highlights: less exited with code 1" "$work/pager_failed.out"
test -s "$PAGER_TEST_PATHS"
while IFS= read -r path; do
  test ! -e "$path"
done < "$PAGER_TEST_PATHS"

# A large book list should reach fzf without hitting shell argument limits.
awk 'BEGIN {
  for (i = 1; i <= 4000; i++) {
    printf "Book %04d %0100d\n- Your Highlight on page 1\n\nQuote %d\n==========\n", i, 0, i
  }
}' > "$work/large.txt"
run_cli load "$work/large.txt" > "$work/large.out"
grep -F "Loaded 4000 highlights" "$work/large.out"
grep -F -- "--- Book 0001 " "$work/large.out"
grep -F "> Quote 1" "$work/large.out"
check_selector_cleanup

# Counts use unique highlights, align across digit widths, and retain book identity.
# Write Book B first so the expected options also check title sorting.
awk 'BEGIN {
  for (i = 1; i <= 10; i++) {
    printf "Book B\n- Your Highlight on page 1\n\nQuote B %d\n==========\n", i
  }
  printf "Book B\n- Your Highlight on page 1\n\nQuote B 1\n==========\n"
  for (i = 1; i <= 2; i++) {
    printf "Book A\n- Your Highlight on page 1\n\nQuote A %d\n==========\n", i
  }
}' > "$work/multiple.txt"

export FZF_TEST_ROW=2
run_cli load "$work/multiple.txt" > "$work/select_second.out"
cat > "$work/expected-options" <<'EOF'
[ 2] Book A
[10] Book B
EOF
cmp "$work/expected-options" "$FZF_TEST_OPTIONS"
grep -Fx -- "--- Book B ---" "$work/select_second.out"
test "$(grep -c '^> Quote B ' "$work/select_second.out")" -eq 10
test "$(grep -Fxc '> Quote B 1' "$work/select_second.out")" -eq 1
if grep -F 'Quote A ' "$work/select_second.out"; then
  echo "selecting Book B should not display Book A highlights" >&2
  exit 1
fi

export FZF_TEST_ROW=1
run_cli > "$work/select_first.out"
unset FZF_TEST_ROW
cmp "$work/expected-options" "$FZF_TEST_OPTIONS"
grep -Fx -- "--- Book A ---" "$work/select_first.out"
test "$(grep -c '^> Quote A ' "$work/select_first.out")" -eq 2
if grep -F 'Quote B ' "$work/select_first.out"; then
  echo "selecting Book A should not display Book B highlights" >&2
  exit 1
fi
check_selector_cleanup

: > "$work/empty.txt"
run_cli load "$work/empty.txt" > "$work/empty.out"
run_cli > "$work/empty_browse.out"
grep -F "No highlights found in the saved library" "$work/empty_browse.out"
