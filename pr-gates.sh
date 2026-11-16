#!/usr/bin/env bash
# pr-gates.sh: offline gates G3-G6 of pr-preflight.sh, for a CI container started with
# `--network none`. Same checks, no sudo/netns needed (the container has no network).
#   pr-gates.sh <branch-dir> <master-dir> <out-dir> <mutations-file>
# Both dirs already have node_modules (npm ci ran in a networked container before).
set -uo pipefail
B=$1; M=$2; O=$3
mkdir -p "$O"; T=$(mktemp -d); fails=()
pass() { printf '  PASS %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; fails+=("$1"); }

if curl -sS -m5 https://registry.npmjs.org >/dev/null 2>&1; then echo "network reachable: refusing (must run with --network none)"; exit 3; fi
echo "glibc: $(ldd --version | head -1) / node $(node -v) / network: none (verified)"

warnings() { grep -i -E 'warn|error|IMPORT_IS_UNDEFINED|fetch failed' "$1" | sed -E 's/[0-9]+(\.[0-9]+)?m?s\b//g' | sort -u; }

# G3 offline build vs master
(cd "$B" && npm run build >"$O/branch.build.log" 2>&1); rb=$?
(cd "$M" && npm run build >"$O/master.build.log" 2>&1); rm_=$?
if [ $rb -ne 0 ]; then
	fail "G3 offline build failed (exit $rb)"; tail -20 "$O/branch.build.log"
else
	new=$(comm -23 <(warnings "$O/branch.build.log") <([ $rm_ -eq 0 ] && warnings "$O/master.build.log"))
	broken=$(grep -rl 'void 0)()' "$B/build" 2>/dev/null | head -3)
	if [ -n "$new" ] || [ -n "$broken" ]; then fail "G3 new warnings vs master or broken output"; printf '    %s\n' "$new" $broken
	else pass "G3 offline build, no warnings beyond master's"; fi
fi

# G4 check + full suite
(cd "$B" && npm run check >"$O/check.log" 2>&1) && pass "G4 npm run check" || { fail "G4 npm run check"; tail -20 "$O/check.log"; }
(cd "$B" && TMPDIR="$T" npx vitest run >"$O/test.log" 2>&1) \
	&& pass "G4 full suite: $(sed 's/\x1b\[[0-9;]*m//g' "$O/test.log" | grep -E '^ +Tests ' | xargs)" \
	|| { fail "G4 test suite"; sed 's/\x1b\[[0-9;]*m//g' "$O/test.log" | grep -E ' FAIL |×' | head -20; }

# G5 mutations: the branch's new tests must FAIL on each mutation. The mutations are per
# branch, in mutations/<name>.sh (4th argument); each file sets MUT_FILES (files a mutation
# may touch, restored after each), MUT_TESTS (test files to run), optional MUT_PREP (command
# run after mutating, e.g. a code generator), and calls `mutate <label> <shell command>`.
mutate() {
	(cd "$B" && git checkout -q -- $MUT_FILES && sh -c "$2" \
		&& { [ -z "${MUT_PREP:-}" ] || sh -c "$MUT_PREP" >/dev/null 2>&1; }; \
		TMPDIR="$T" npx vitest run $MUT_TESTS >"$O/mustfail-$1.log" 2>&1)
	local rc=$?
	(cd "$B" && git checkout -q -- $MUT_FILES)
	if [ $rc -ne 0 ] && grep -q 'FAIL' "$O/mustfail-$1.log"; then pass "G5 new tests fail on mutation: $1"
	else fail "G5 new tests still PASS on mutation: $1"; fi
}
# shellcheck source=/dev/null  # per-branch file, path given at run time
if [ -n "${4:-}" ]; then . "$4"; else fail "G5 no mutations file given"; fi

# G6 docs drift (generated files excluded)
drift=0
while IFS= read -r tok; do
	[ -z "$tok" ] && continue
	if git -C "$B" grep -q -F "$tok" HEAD -- '*.md'; then echo "    still in docs: $tok"; drift=1; fi
done < <(git -C "$B" diff "origin/master...HEAD" -- . ':!*.generated.*' ':!package-lock.json' \
	| grep -E '^-[^-]' | grep -o -E 'https?://[^" )]+|cdn\.[a-z.]+' | sort -u)
[ $drift = 0 ] && pass "G6 no removed URL/host left in *.md" || fail "G6 docs drift"

rm -r "$T"
echo
if [ ${#fails[@]} -eq 0 ]; then echo "pr-gates: ALL GREEN"; exit 0; fi
echo "pr-gates: ${#fails[@]} FAILED: ${fails[*]}"; exit 1
