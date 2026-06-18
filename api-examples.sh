#!/bin/bash
# ============================================================
#  tests/api-examples.sh
#  Quick curl examples to test the Nutrition Engine API
#
#  Usage:
#    chmod +x tests/api-examples.sh
#    ./tests/api-examples.sh
#
#  Or run individual commands manually
# ============================================================

BASE_URL="http://localhost:3000"

echo "🧪  Nutrition Engine API Testing Guide"
echo "======================================="
echo ""
echo "Base URL: $BASE_URL"
echo "Make sure the server is running: npm run dev"
echo ""

# ── Test 1: Health Check ──────────────────────────────────────────
echo "📌 TEST 1: Health Check"
echo "Command:"
echo "curl $BASE_URL/health"
echo ""
echo "Expected:"
echo '{"status":"ok","engine":"Autonomous AI Nutrition Engine"}'
echo ""
read -p "Press Enter to run..."
curl "$BASE_URL/health" | jq .
echo -e "\n"

# ── Test 2: Single Item (Cache Miss → Gemini API) ───────────────
echo "📌 TEST 2: Single Item Calculation (Cache Miss)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/calculate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"restaurantName\":\"Buffalo Burger\",\"itemName\":\"Old School 200g\"}'"
echo ""
echo "Expected:"
echo '{"success":true,"source":"ai_generated","restaurant":{...},"item":{...}}'
echo ""
read -p "Press Enter to run..."
curl -X POST "$BASE_URL/api/nutrition/calculate" \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Buffalo Burger","itemName":"Old School 200g"}' | jq .
echo -e "\n"

# ── Test 3: Same Item Again (Cache Hit) ───────────────────────────
echo "📌 TEST 3: Same Item Again (Cache Hit - Zero Cost)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/calculate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"restaurantName\":\"Buffalo Burger\",\"itemName\":\"Old School 200g\"}'"
echo ""
echo "Expected:"
echo '{"success":true,"source":"cache","restaurant":{...},"item":{...}}'
echo "(Notice source changed from ai_generated to cache)"
echo ""
read -p "Press Enter to run..."
curl -X POST "$BASE_URL/api/nutrition/calculate" \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Buffalo Burger","itemName":"Old School 200g"}' | jq .
echo -e "\n"

# ── Test 4: Batch Processing ─────────────────────────────────────
echo "📌 TEST 4: Batch Processing (3 items)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/batch \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"items\":[...]}'"
echo ""
read -p "Press Enter to run..."
curl -X POST "$BASE_URL/api/nutrition/batch" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"restaurantName": "Buffalo Burger", "itemName": "Cheese Burger"},
      {"restaurantName": "McDonald'\''s", "itemName": "Big Mac"},
      {"restaurantName": "KFC", "itemName": "Original Chicken"}
    ]
  }' | jq .
echo -e "\n"

# ── Test 5: Cache Statistics ─────────────────────────────────────
echo "📌 TEST 5: View Cache Statistics"
echo "Command:"
echo "curl $BASE_URL/api/nutrition/cache/stats"
echo ""
echo "Expected:"
echo '{"success":true,"totalRestaurants":N,"totalCachedItems":M,"restaurants":[...]}'
echo ""
read -p "Press Enter to run..."
curl "$BASE_URL/api/nutrition/cache/stats" | jq .
echo -e "\n"

# ── Test 6: Purge Specific Item ───────────────────────────────────
echo "📌 TEST 6: Purge a Single Cached Item"
echo "Command:"
echo "curl -X DELETE $BASE_URL/api/nutrition/cache/Buffalo%20Burger/Old%20School%20200g"
echo ""
echo "Expected:"
echo '{"success":true,"message":"Item purged..."}'
echo ""
read -p "Press Enter to run..."
curl -X DELETE "$BASE_URL/api/nutrition/cache/Buffalo%20Burger/Old%20School%20200g" | jq .
echo -e "\n"

# ── Test 7: Re-request Purged Item (Cache Miss Again) ────────────
echo "📌 TEST 7: Request Purged Item (Cache Miss - Gemini Called Again)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/calculate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"restaurantName\":\"Buffalo Burger\",\"itemName\":\"Old School 200g\"}'"
echo ""
echo "Expected:"
echo '{"success":true,"source":"ai_generated",...} (source is ai_generated again)'
echo ""
read -p "Press Enter to run..."
curl -X POST "$BASE_URL/api/nutrition/calculate" \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Buffalo Burger","itemName":"Old School 200g"}' | jq .
echo -e "\n"

# ── Test 8: Purge Entire Restaurant ───────────────────────────────
echo "📌 TEST 8: Purge All Items from a Restaurant"
echo "Command:"
echo "curl -X DELETE $BASE_URL/api/nutrition/cache/Buffalo%20Burger"
echo ""
echo "Expected:"
echo '{"success":true,"restaurantName":"Buffalo Burger","itemsPurged":N}'
echo ""
read -p "Press Enter to run..."
curl -X DELETE "$BASE_URL/api/nutrition/cache/Buffalo%20Burger" | jq .
echo -e "\n"

# ── Test 9: Error Handling ───────────────────────────────────────
echo "📌 TEST 9: Error Handling (Missing Field)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/calculate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"restaurantName\":\"Buffalo Burger\"}'"
echo ""
echo "Expected:"
echo '{"success":false,"error":"...","code":"VALIDATION_ERROR","timestamp":"..."}'
echo ""
read -p "Press Enter to run..."
curl -X POST "$BASE_URL/api/nutrition/calculate" \
  -H "Content-Type: application/json" \
  -d '{"restaurantName":"Buffalo Burger"}' | jq .
echo -e "\n"

# ── Test 10: Reset Cache (DESTRUCTIVE) ────────────────────────────
echo "📌 TEST 10: Reset Entire Cache (DESTRUCTIVE - Requires Header)"
echo "Command:"
echo "curl -X POST $BASE_URL/api/nutrition/cache/reset \\"
echo "  -H 'X-Confirm-Reset: true'"
echo ""
echo "Expected:"
echo '{"success":true,"message":"Cache reset...","data":{"itemsDeleted":N,"restaurantsDeleted":M}}'
echo ""
read -p "Press Enter to run? (⚠️  WARNING: This will delete all cached data) [y/N]"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl -X POST "$BASE_URL/api/nutrition/cache/reset" \
    -H "X-Confirm-Reset: true" | jq .
else
  echo "Skipped."
fi
echo -e "\n"

echo "✅  All tests completed!"
echo ""
echo "📊  To verify your database:"
echo "    npm run db:studio"
echo ""
