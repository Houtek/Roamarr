# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the actions-menu fix (menu inside the map hero keeps the hero's white text).
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/app.css"
MUT_TESTS="src/lib/themeScheme.test.ts"
MUT_PREP=""
# The rule is gone: the original bug.
mutate rule-removed "sed -i 's#\.trip-hero--map \.app-user-menu-panel {#.trip-hero--map .app-user-menu-panel-gone {#' src/app.css && grep -q 'app-user-menu-panel-gone {' src/app.css"
# The colour is reset but the hero's text shadow stays.
mutate shadow-kept "sed -i '/\.trip-hero--map \.app-user-menu-panel {/,/}/{/text-shadow: none;/d}' src/app.css && ! sed -n '/\.trip-hero--map \.app-user-menu-panel {/,/}/p' src/app.css | grep -q 'text-shadow'"
# Reset to a fixed white instead of the theme colour (unreadable on light).
mutate fixed-white "sed -i '/\.trip-hero--map \.app-user-menu-panel {/,/}/s#--trip-readable: var(--theme-trip-readable, \#ffffff);#--trip-readable: \#ffffff;#' src/app.css && sed -n '/\.trip-hero--map \.app-user-menu-panel {/,/}/p' src/app.css | grep -q -- '--trip-readable: #ffffff;'"
