# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the theme-test-hero follow-up (hero exception matched by rule, not by '#fff').
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/app.css"
MUT_TESTS="src/lib/themeScheme.test.ts"
MUT_PREP=""
# A fixed '#fff' outside the hero rule: master's value filter let this through.
mutate stray-fff "sed -i '/\.trip-hero--map \.app-user-menu-panel {/a\\		--trip-readable-danger: #fff;' src/app.css && grep -q -- '--trip-readable-danger: #fff;' src/app.css"
# The hero rule stops pinning white.
mutate hero-not-white "sed -i '/\.trip-hero--map \.trip-hero-content {/,/}/s#--trip-readable: \#fff;#--trip-readable: \#111;#' src/app.css && sed -n '/\.trip-hero--map \.trip-hero-content {/,/}/p' src/app.css | grep -q -- '--trip-readable: #111;'"
