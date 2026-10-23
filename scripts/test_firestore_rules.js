/**
 * Verification test suite for strict Firestore Security Rules.
 *
 * Verifies that:
 * 1. Users can only read/write their own profile and bookings.
 * 2. Providers can only update their own availability/status, NOT their rating.
 * 3. Reviews can only be created by the customer associated with a completed booking.
 * 4. Unauthorized writes/reads are blocked (HTTP 403 PERMISSION_DENIED).
 *
 * Usage:
 *   node scripts/test_firestore_rules.js
 */

const http = require("http");
const assert = require("assert");

const projectId = process.env.FIREBASE_PROJECT_ID || "ustaad-service-app-17d0a";
const port = parseInt(process.env.FIRESTORE_EMULATOR_PORT || "8080", 10);
const host = "127.0.0.1";

// Creates an unsigned JWT for the Firebase Emulator
function createToken(uid) {
  const header = Buffer.from(JSON.stringify({ alg: "none", typ: "JWT" })).toString("base64url");
  const payload = Buffer.from(JSON.stringify({
    user_id: uid,
    sub: uid,
    aud: projectId,
    iss: `https://securetoken.google.com/${projectId}`,
    auth_time: Math.floor(Date.now() / 1000),
  })).toString("base64url");
  return `${header}.${payload}.`;
}

// Low-level HTTP requester to the Firestore Emulator REST API
function requestFirestore({ path, method = "GET", token = null, body = null }) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const headers = {
      "Content-Type": "application/json",
    };
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }
    if (payload) {
      headers["Content-Length"] = Buffer.byteLength(payload);
    }

    const fullPath = `/v1/projects/${projectId}/databases/(default)/documents/${path}`;
    const options = {
      hostname: host,
      port: port,
      path: fullPath,
      method: method,
      headers: headers,
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        let json = null;
        try {
          json = data ? JSON.parse(data) : {};
        } catch (_) {
          json = { raw: data };
        }
        resolve({ status: res.statusCode, data: json });
      });
    });

    req.on("error", (err) => reject(err));
    if (payload) req.write(payload);
    req.end();
  });
}

// Convert flat JS object to Firestore REST document fields
function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === null) {
      fields[k] = { nullValue: null };
    } else if (typeof v === "boolean") {
      fields[k] = { booleanValue: v };
    } else if (typeof v === "number") {
      if (Number.isInteger(v)) {
        fields[k] = { integerValue: v.toString() };
      } else {
        fields[k] = { doubleValue: v };
      }
    } else if (typeof v === "string") {
      fields[k] = { stringValue: v };
    } else if (Array.isArray(v)) {
      fields[k] = {
        arrayValue: {
          values: v.map((item) => ({ stringValue: String(item) })),
        },
      };
    } else if (typeof v === "object") {
      fields[k] = { mapValue: { fields: toFirestoreFields(v) } };
    }
  }
  return fields;
}

async function runSecurityRulesVerification() {
  console.log("===============================================================");
  console.log("  VERIFYING FIRESTORE SECURITY RULES ON FIREBASE EMULATOR      ");
  console.log("===============================================================\n");

  const aliceToken = createToken("cust_alice");
  const bobToken = createToken("cust_bob");
  const providerToken = createToken("prov_ahmed");

  // =================================================================
  // SECTION 1: PROFILES SECURITY
  // =================================================================
  console.log("[Test 1] Profiles Isolation:");
  
  // 1a. Alice creates her own profile -> MUST SUCCEED (200)
  const p1 = await requestFirestore({
    path: "profiles/cust_alice",
    method: "PATCH",
    token: aliceToken,
    body: {
      fields: toFirestoreFields({
        id: "cust_alice",
        full_name: "Alice Khan",
        phone: "+923001111111",
        address: "House 12, G-13, Islamabad",
      }),
    },
  });
  assert.strictEqual(p1.status, 200, "Alice should be allowed to write her own profile");
  console.log("  ✓ Alice created her own profile: ALLOWED (200)");

  // 1b. Bob attempts to write to Alice's profile -> MUST BE BLOCKED (403)
  const p2 = await requestFirestore({
    path: "profiles/cust_alice",
    method: "PATCH",
    token: bobToken,
    body: {
      fields: toFirestoreFields({
        id: "cust_alice",
        full_name: "Bob Tampering",
      }),
    },
  });
  assert.strictEqual(p2.status, 403, "Bob must be BLOCKED from modifying Alice's profile");
  console.log("  ✓ Bob blocked from modifying Alice's profile: BLOCKED (403)");

  // 1c. Bob attempts to read Alice's profile -> MUST BE BLOCKED (403)
  const p3 = await requestFirestore({
    path: "profiles/cust_alice",
    method: "GET",
    token: bobToken,
  });
  assert.strictEqual(p3.status, 403, "Bob must be BLOCKED from reading Alice's profile");
  console.log("  ✓ Bob blocked from reading Alice's private profile: BLOCKED (403)");

  // 1d. Alice reads her own profile -> MUST SUCCEED (200)
  const p4 = await requestFirestore({
    path: "profiles/cust_alice",
    method: "GET",
    token: aliceToken,
  });
  assert.strictEqual(p4.status, 200, "Alice must be allowed to read her own profile");
  console.log("  ✓ Alice reading her own profile: ALLOWED (200)");

  // =================================================================
  // SECTION 2: PROVIDERS RATING INTEGRITY
  // =================================================================
  console.log("\n[Test 2] Provider Rating Tampering Protection:");

  // Set up provider document directly (administrative seed)
  await requestFirestore({
    path: "service_providers/prov_ahmed",
    method: "PATCH",
    token: "owner",
    body: {
      fields: toFirestoreFields({
        id: "prov_ahmed",
        name: "Ahmed Electrician",
        rating: 4.5,
        reliability: 0.95,
        verified: true,
        availability_slots: ["Today 4:00 PM"],
        next_slot: "Today 4:00 PM",
        is_online: true,
      }),
    },
  });

  // 2a. Provider Ahmed updates availability/status -> MUST SUCCEED (200)
  const prv1 = await requestFirestore({
    path: "service_providers/prov_ahmed?updateMask.fieldPaths=availability_slots&updateMask.fieldPaths=next_slot",
    method: "PATCH",
    token: providerToken,
    body: {
      fields: toFirestoreFields({
        id: "prov_ahmed",
        rating: 4.5,
        reliability: 0.95,
        verified: true,
        availability_slots: ["Tomorrow 10:00 AM", "Tomorrow 2:00 PM"],
        next_slot: "Tomorrow 10:00 AM",
      }),
    },
  });
  assert.strictEqual(prv1.status, 200, "Provider should be allowed to update own availability");
  console.log("  ✓ Provider updating availability slots: ALLOWED (200)");

  // 2b. Provider Ahmed attempts to change rating to 5.0 -> MUST BE BLOCKED (403)
  const prv2 = await requestFirestore({
    path: "service_providers/prov_ahmed?updateMask.fieldPaths=rating",
    method: "PATCH",
    token: providerToken,
    body: {
      fields: toFirestoreFields({
        id: "prov_ahmed",
        rating: 5.0,
      }),
    },
  });
  assert.strictEqual(prv2.status, 403, "Provider must be BLOCKED from altering rating");
  console.log("  ✓ Provider blocked from self-inflating rating: BLOCKED (403)");

  // 2c. Customer Bob attempts to modify provider Ahmed -> MUST BE BLOCKED (403)
  const prv3 = await requestFirestore({
    path: "service_providers/prov_ahmed",
    method: "PATCH",
    token: bobToken,
    body: {
      fields: toFirestoreFields({
        availability_slots: ["Tampered"],
      }),
    },
  });
  assert.strictEqual(prv3.status, 403, "Customer must be BLOCKED from updating provider");
  console.log("  ✓ Non-owner blocked from modifying provider catalog: BLOCKED (403)");

  // =================================================================
  // SECTION 3: BOOKINGS ISOLATION & ACCESS
  // =================================================================
  console.log("\n[Test 3] Bookings Isolation & Access Controls:");

  // 3a. Alice creates her booking -> MUST SUCCEED (200)
  const b1 = await requestFirestore({
    path: "bookings/book_alice_1",
    method: "PATCH",
    token: aliceToken,
    body: {
      fields: toFirestoreFields({
        user_id: "cust_alice",
        provider_id: "prov_ahmed",
        quote_base: 500,
        quote_total: 650,
        status: "scheduled",
        created_at: new Date().toISOString(),
      }),
    },
  });
  assert.strictEqual(b1.status, 200, "Alice should be allowed to create her booking");
  console.log("  ✓ Alice creating booking for herself: ALLOWED (200)");

  // 3b. Bob attempts to read Alice's booking -> MUST BE BLOCKED (403)
  const b2 = await requestFirestore({
    path: "bookings/book_alice_1",
    method: "GET",
    token: bobToken,
  });
  assert.strictEqual(b2.status, 403, "Bob must be BLOCKED from reading Alice's booking");
  console.log("  ✓ Bob blocked from reading Alice's booking: BLOCKED (403)");

  // 3c. Bob attempts to tamper with Alice's booking price -> MUST BE BLOCKED (403)
  const b3 = await requestFirestore({
    path: "bookings/book_alice_1?updateMask.fieldPaths=quote_total",
    method: "PATCH",
    token: bobToken,
    body: {
      fields: toFirestoreFields({
        quote_total: 100,
      }),
    },
  });
  assert.strictEqual(b3.status, 403, "Bob must be BLOCKED from modifying Alice's booking");
  console.log("  ✓ Bob blocked from modifying Alice's booking: BLOCKED (403)");

  // 3d. Provider Ahmed can read the booking assigned to him -> MUST SUCCEED (200)
  const b4 = await requestFirestore({
    path: "bookings/book_alice_1",
    method: "GET",
    token: providerToken,
  });
  assert.strictEqual(b4.status, 200, "Assigned provider should be allowed to read booking");
  console.log("  ✓ Assigned provider reading booking: ALLOWED (200)");

  // =================================================================
  // SECTION 4: REVIEWS GATED BY COMPLETED BOOKING
  // =================================================================
  console.log("\n[Test 4] Reviews Gated by Completed Booking:");

  // 4a. Alice attempts to review without a completed booking (booking status is 'scheduled') -> MUST BE BLOCKED (403)
  const r1 = await requestFirestore({
    path: "reviews/rev_fail_1",
    method: "PATCH",
    token: aliceToken,
    body: {
      fields: toFirestoreFields({
        user_id: "cust_alice",
        provider_id: "prov_ahmed",
        booking_id: "book_alice_1", // Scheduled, not completed!
        rating: 5,
        comment: "Great service so far!",
        created_at: new Date().toISOString(),
      }),
    },
  });
  assert.strictEqual(r1.status, 403, "Review for non-completed booking must be BLOCKED");
  console.log("  ✓ Review on 'scheduled' non-completed booking: BLOCKED (403)");

  // 4b. Bob attempts to review using Alice's booking -> MUST BE BLOCKED (403)
  const r2 = await requestFirestore({
    path: "reviews/rev_fail_2",
    method: "PATCH",
    token: bobToken,
    body: {
      fields: toFirestoreFields({
        user_id: "cust_bob",
        provider_id: "prov_ahmed",
        booking_id: "book_alice_1",
        rating: 4,
        comment: "Bob using Alice's booking",
        created_at: new Date().toISOString(),
      }),
    },
  });
  assert.strictEqual(r2.status, 403, "Review with another user's booking must be BLOCKED");
  console.log("  ✓ Review with another user's booking: BLOCKED (403)");

  // 4c. Provider Ahmed completes Alice's booking
  const bComplete = await requestFirestore({
    path: "bookings/book_alice_1?updateMask.fieldPaths=status",
    method: "PATCH",
    token: providerToken,
    body: {
      fields: toFirestoreFields({
        user_id: "cust_alice",
        provider_id: "prov_ahmed",
        quote_base: 500,
        quote_total: 650,
        status: "completed",
      }),
    },
  });
  assert.strictEqual(bComplete.status, 200, "Provider marks booking completed");
  console.log("  ✓ Provider Ahmed marks booking as 'completed': ALLOWED (200)");

  // 4d. Alice now submits review with completed booking -> MUST SUCCEED (200)
  const r3 = await requestFirestore({
    path: "reviews/rev_success_1",
    method: "PATCH",
    token: aliceToken,
    body: {
      fields: toFirestoreFields({
        user_id: "cust_alice",
        provider_id: "prov_ahmed",
        booking_id: "book_alice_1",
        rating: 5,
        comment: "Excellent repair! Arrived on time and solved breaker issue.",
        created_at: new Date().toISOString(),
      }),
    },
  });
  assert.strictEqual(r3.status, 200, "Review for completed booking must be ALLOWED");
  console.log("  ✓ Review on 'completed' booking submitted by customer: ALLOWED (200)");

  // 4e. Alice attempts to update / delete the submitted review -> MUST BE BLOCKED (403)
  const r4 = await requestFirestore({
    path: "reviews/rev_success_1",
    method: "DELETE",
    token: aliceToken,
  });
  assert.strictEqual(r4.status, 403, "Deleting submitted review must be BLOCKED");
  console.log("  ✓ Deleting review blocked (Audit immutability): BLOCKED (403)");

  console.log("\n===============================================================");
  console.log("  ALL FIRESTORE SECURITY RULES ASSERTIONS PASSED (10/10)!       ");
  console.log("===============================================================\n");
}

runSecurityRulesVerification().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
