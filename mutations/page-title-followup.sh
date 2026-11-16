# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the #14 review follow-up (error-page title, print title without suffix).
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/routes/+layout.svelte src/lib/pageTitles.ts"
MUT_TESTS="src/routes/layoutTitle.test.ts src/routes/layoutTitle.svelte.test.ts"
MUT_PREP=""
# The layout stops passing page.error: an errored route shows its route title again.
mutate error-not-passed "sed -i 's#pageTitle(page.route.id, page.data, data.instanceName, page.error)#pageTitle(page.route.id, page.data, data.instanceName)#' src/routes/+layout.svelte && grep -q 'pageTitle(page.route.id, page.data, data.instanceName)}' src/routes/+layout.svelte"
# pageTitle ignores the error it is given.
mutate error-ignored "sed -i 's#const name = routeId \&\& !error ? #const name = routeId ? #' src/lib/pageTitles.ts && grep -q 'const name = routeId ? ' src/lib/pageTitles.ts"
# The print page gets the instance suffix again.
mutate print-suffixed "sed -i 's#return STANDALONE_TITLES.has(routeId!) ? name : m.page_title#return m.page_title#' src/lib/pageTitles.ts && ! grep -q 'STANDALONE_TITLES.has' src/lib/pageTitles.ts"
