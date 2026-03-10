#!/usr/bin/env bash
# Test: Search endpoint
# Docs: GET /search.json?q=keyword (min 2 chars, returns up to 20 items + 10 lists)

section "Search"

# 1. Search with a keyword (>= 2 chars)
api_get "$(search_path)?q=Unicorn"
assert_status "200" "$RESPONSE_STATUS" "GET /search.json?q=Unicorn"
assert_success_envelope "$RESPONSE_BODY" "object" "search with keyword"

# 2. Search with a short query (< 2 chars)
api_get "$(search_path)?q=U"
assert_status "200" "$RESPONSE_STATUS" "GET /search.json?q=U"
assert_success_envelope "$RESPONSE_BODY" "object" "search short query"

# 3. Search with no query param
api_get "$(search_path)"
assert_status "200" "$RESPONSE_STATUS" "GET /search.json (no query)"
assert_success_envelope "$RESPONSE_BODY" "object" "search no query"
