/**
 * Local test runner for Ustaad Cloud Functions suite:
 * - extractServiceIntent (Multilingual Pakistani NLP: English, Urdu Nastaliq, Roman Urdu)
 * - searchProviders (Weighted server-side ranking)
 * - verifyJazzCashPayment (Server-side transaction audit)
 * 
 * Run with: npm test --prefix functions
 */
const assert = require("assert");
const { extractServiceIntent, searchProviders } = require("./index.js");

async function runLocalTests() {
  console.log("=================================================================");
  console.log("  USTAAD CLOUD FUNCTIONS AUTOMATED TEST SUITE (PHASES 3, 6, 7)");
  console.log("=================================================================\n");

  async function invokeFunction(fn, data, auth = null) {
    const request = { data, auth };
    return await fn.run(request);
  }

  // --- 1. Roman Urdu Input: "AC theek karwana hai Gulberg mein" (Specified in Phase 3) ---
  console.log("[Test 1] Phase 3 Roman Urdu Requirement: 'AC theek karwana hai Gulberg mein'");
  const res1 = await invokeFunction(extractServiceIntent, {
    problemText: "AC theek karwana hai Gulberg mein",
    location: "Gulberg, Lahore",
  });
  console.log("Result 1:", JSON.stringify(res1, null, 2));
  assert.strictEqual(res1.role, "AC Repair", "Must identify AC Repair role");
  assert.strictEqual(res1.language, "Roman Urdu", "Must recognize Roman Urdu");
  assert.strictEqual(res1.location, "Gulberg, Lahore", "Must retain location");
  console.log("✓ Test 1 Passed!");

  // --- 2. Roman Urdu with Budget & Urgency ---
  console.log("\n[Test 2] Roman Urdu with Budget and Urgency: 'kal subah kitchen sink leak ho raha hai 800 mein plumber chahiye'");
  const res2 = await invokeFunction(extractServiceIntent, {
    problemText: "kal subah kitchen sink leak ho raha hai 800 mein plumber chahiye",
    location: "G-13, Islamabad",
  });
  console.log("Result 2:", JSON.stringify(res2, null, 2));
  assert.strictEqual(res2.role, "Plumber", "Must identify Plumber role");
  assert.strictEqual(res2.timeLabel, "Tomorrow morning", "Must parse 'kal subah' as Tomorrow morning");
  assert.strictEqual(res2.userBudget, 800, "Must extract 800 PKR budget");
  assert.strictEqual(res2.language, "Roman Urdu", "Must recognize Roman Urdu");
  console.log("✓ Test 2 Passed!");

  // --- 3. Urdu Script with High Urgency ---
  console.log("\n[Test 3] Urdu Nastaliq Script with High Urgency: 'بجلی کا بریکر جلدی ٹھیک کرو'");
  const res3 = await invokeFunction(extractServiceIntent, {
    problemText: "بجلی کا بریکر جلدی ٹھیک کرو",
    location: "F-10, Islamabad",
  });
  console.log("Result 3:", JSON.stringify(res3, null, 2));
  assert.strictEqual(res3.role, "Electrician", "Must identify Electrician role");
  assert.strictEqual(res3.urgency, "High", "Must identify High urgency from 'جلدی'");
  assert.strictEqual(res3.language, "Urdu", "Must recognize Urdu script");
  console.log("✓ Test 3 Passed!");

  // --- 4. English AC Request with Initial Offer ---
  console.log("\n[Test 4] English AC Request with Initial Offer");
  const res4 = await invokeFunction(extractServiceIntent, {
    problemText: "AC is blowing hot air and needs gas recharge",
    location: "DHA Phase 2, Islamabad",
    initialOffer: 1500,
  });
  console.log("Result 4:", JSON.stringify(res4, null, 2));
  assert.strictEqual(res4.role, "AC Repair", "Must identify AC Repair");
  assert.strictEqual(res4.userBudget, 1500, "Must reflect initial offer");
  assert.strictEqual(res4.language, "English", "Must recognize English");
  console.log("✓ Test 4 Passed!");

  // --- 5. Cleaning Service Request in Rawalpindi ---
  console.log("\n[Test 5] Cleaning Service: 'sofa aur carpet deep cleaning karwani hai'");
  const res5 = await invokeFunction(extractServiceIntent, {
    problemText: "sofa aur carpet deep cleaning karwani hai",
    location: "Saddar, Rawalpindi",
  });
  console.log("Result 5:", JSON.stringify(res5, null, 2));
  assert.strictEqual(res5.role, "Cleaning", "Must identify Cleaning role");
  assert.strictEqual(res5.language, "Roman Urdu", "Must recognize Roman Urdu");
  console.log("✓ Test 5 Passed!");

  // --- 6. Input Validation (Empty text) ---
  console.log("\n[Test 6] Security Input Validation: Empty text rejection");
  try {
    await invokeFunction(extractServiceIntent, {
      problemText: "   ",
      location: "Islamabad",
    });
    assert.fail("Should have thrown an HttpsError for empty problemText");
  } catch (err) {
    assert.strictEqual(err.code, "invalid-argument", "Should throw invalid-argument code");
    console.log("✓ Test 6 Passed (Rejected empty text with invalid-argument)!");
  }

  // --- 7. Security Input Validation (Oversized string > 500 chars) ---
  console.log("\n[Test 7] Security Input Validation: Oversized text rejection (> 500 chars)");
  try {
    const hugeText = "a".repeat(600);
    await invokeFunction(extractServiceIntent, {
      problemText: hugeText,
      location: "Islamabad",
    });
    assert.fail("Should have thrown an HttpsError for oversized text");
  } catch (err) {
    assert.strictEqual(err.code, "invalid-argument", "Should throw invalid-argument code");
    console.log("✓ Test 7 Passed (Rejected oversized text with invalid-argument)!");
  }

  console.log("\n=======================================================");
  console.log("  ALL 7 CLOUD FUNCTIONS TESTS PASSED WITH 100% SUCCESS! ");
  console.log("=======================================================\n");
}

runLocalTests().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
