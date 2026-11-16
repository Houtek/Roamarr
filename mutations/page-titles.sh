# shellcheck shell=bash disable=SC2034  # sourced by pr-gates.sh, which reads the MUT_* variables
# G5 mutations for the per-page titles branch (issue #12 part 2): sourced by pr-gates.sh.
# Each mutation asserts it actually changed the file (grep), so a no-op sed can't fake a pass.
MUT_FILES="src/routes/+layout.svelte src/lib/pageTitles.ts src/routes/trips/[id]/print/+page.svelte"
MUT_TESTS="src/routes/layoutTitle.test.ts src/routes/layoutTitle.svelte.test.ts src/lib/pageTitles.test.ts"
MUT_PREP=""
# Back to the part-1 default title: no page names at all.
mutate no-page-name "sed -i 's#<title>{pageTitle(page.route.id, page.data, data.instanceName)}</title>#<title>{data.instanceName || \"Roamarr\"}</title>#' src/routes/+layout.svelte && grep -q '<title>{data.instanceName || \"Roamarr\"}</title>' src/routes/+layout.svelte"
# Title computed once, not reactive: SSR stays right, client navigation must catch it.
mutate not-reactive "sed -i 's#<title>{pageTitle(page.route.id, page.data, data.instanceName)}</title>#<title>{untrack(() => pageTitle(page.route.id, page.data, data.instanceName))}</title>#' src/routes/+layout.svelte && grep -q '<title>{untrack(' src/routes/+layout.svelte"
# Record names ignored: trip pages fall back to the generic name.
mutate trip-name-ignored "sed -i 's#return typeof trip?.name === .string. \&\& trip.name.trim() ? trip.name : undefined;#return undefined;#' src/lib/pageTitles.ts && grep -q '^	return undefined;' src/lib/pageTitles.ts"
# A page route without an entry: the coverage test must name it.
mutate entry-missing "sed -i \"/^	'\\/trips\\/\\[id\\]\\/edit': /d\" src/lib/pageTitles.ts && ! grep -q \"'/trips/\\[id\\]/edit'\" src/lib/pageTitles.ts"
# A page brings back its own <title>.
mutate page-own-title "printf '\\n<svelte:head><title>x</title></svelte:head>\\n' >> 'src/routes/trips/[id]/print/+page.svelte' && grep -q '<title>x</title>' 'src/routes/trips/[id]/print/+page.svelte'"
