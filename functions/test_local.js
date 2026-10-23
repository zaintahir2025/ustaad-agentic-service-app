/**
 * Local test runner for extractServiceIntent Cloud Function logic.
 * Can be run standalone with: node functions/test_local.js
 */
const assert = require("assert");
const { extractServiceIntent } = require("./index.js");

async function runLocalTests() {
  console.log("=== Testing extractServiceIntent Cloud Function Locally ===");

  // Helper to simulate Firebase onCall wrapper
  async function invokeFunction(data, auth = null) {
    // In Firebase Functions v2, onCall handlers receive a request object: { data, auth }
    const request = { data, auth };
    return await extractServiceIntent.run(request);
  }

  // Test 1: Roman Urdu with InDrive Budget and Urgency
  console.log("\n[Test 1] Roman Urdu with InDrive Budget and Time Preference");
  const res1 = await invokeFunction({
    problemText: "kal subah kitchen sink leak ho raha hai 800 mein plumber chahiye",
    location: "G-13, Islamabad",
  });
  console.log("Result 1:", JSON.stringify(res1, null, 2));
  assert.strictEqual(res1.role, "Plumber", "Should identify Plumber role");
  assert.strictEqual(res1.timeLabel, "Tomorrow morning", "Should parse 'kal subah' as Tomorrow morning");
  assert.strictEqual(res1.userBudget, 800, "Should extract 800 PKR budget");
  assert.strictEqual(res1.language, "Roman Urdu", "Should recognize Roman Urdu");
  console.log("✓ Test 1 Passed!");

  // Test 2: Urdu Nastaliq Script with High Urgency
  console.log("\n[Test 2] Urdu Script with High Urgency");
  const res2 = await invokeFunction({
    problemText: "بجلی کا بریکر جلدی ٹھیک کرو",
    location: "F-10, Islamabad",
  });
  console.log("Result 2:", JSON.stringify(res2, null, 2));
  assert.strictEqual(res2.role, "Electrician", "Should identify Electrician role");
  assert.strictEqual(res2.urgency, "High", "Should identify High urgency from 'جلدی'");
  assert.strictEqual(res2.language, "Urdu", "Should recognize Urdu script");
  console.log("✓ Test 2 Passed!");

  // Test 3: English AC Repair with Explicit Initial Offer
  console.log("\n[Test 3] English AC Request with Initial Offer");
  const res3 = await invokeFunction({
    problemText: "AC is blowing hot air and needs gas recharge",
    location: "DHA Phase 2, Islamabad",
    initialOffer: 1500,
  });
  console.log("Result 3:", JSON.stringify(res3, null, 2));
  assert.strictEqual(res3.role, "AC Repair", "Should identify AC Repair");
  assert.strictEqual(res3.userBudget, 1500, "Should reflect initial offer");
  assert.strictEqual(res3.language, "English", "Should recognize English");
  console.log("✓ Test 3 Passed!");

  // Test 4: Validation on Empty Input
  console.log("\n[Test 4] Validation Error on Empty Problem Text");
  try {
    await invokeFunction({
      problemText: "   ",
      location: "Islamabad",
    });
    assert.fail("Should have thrown an HttpsError for empty problemText");
  } catch (err) {
    assert.strictEqual(err.code, "invalid-argument", "Should throw invalid-argument code");
    console.log("✓ Test 4 Passed (Correctly rejected empty input with invalid-argument)!");
  }

  console.log("\n=======================================================");
  console.log("  ALL 4 CLOUD FUNCTION LOCAL TESTS PASSED SUCCESSFULLY! ");
  console.log("=======================================================\n");
}

runLocalTests().catch((err) => {
  console.error("Test failed with error:", err);
  process.exit(1);
});
