/**
 * Script to test the extractServiceIntent Cloud Function running inside the Firebase Emulator.
 *
 * Usage:
 *   1. Start emulator in terminal 1:
 *      firebase emulators:start --only functions
 *   2. Run this test script in terminal 2:
 *      node scripts/test_emulator_function.js
 */

const http = require("http");

const projectId = process.env.FIREBASE_PROJECT_ID || "ustaad-service-app-17d0a";
const region = process.env.FIREBASE_REGION || "us-central1";
const port = process.env.FUNCTIONS_EMULATOR_PORT || 5001;
const host = "127.0.0.1";

const testPayload = JSON.stringify({
  data: {
    problemText: "pani ka nalka leak kar raha hai 600 rupay mein plumber chahiye",
    location: "G-13, Islamabad",
    initialOffer: 600,
  },
});

const options = {
  hostname: host,
  port: port,
  path: `/${projectId}/${region}/extractServiceIntent`,
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(testPayload),
  },
};

console.log(`Sending Callable request to: http://${host}:${port}${options.path}`);

const req = http.request(options, (res) => {
  let responseData = "";

  res.on("data", (chunk) => {
    responseData += chunk;
  });

  res.on("end", () => {
    console.log(`Status Code: ${res.statusCode}`);
    try {
      const parsed = JSON.parse(responseData);
      console.log("Parsed Response:\n", JSON.stringify(parsed, null, 2));
      if (parsed.result && parsed.result.role) {
        console.log(`\nSUCCESS: Extracted role "${parsed.result.role}" with budget PKR ${parsed.result.userBudget}!`);
      } else {
        console.log("\nNote: Response received but check structure:", responseData);
      }
    } catch (e) {
      console.error("Failed to parse JSON response:", responseData);
    }
  });
});

req.on("error", (error) => {
  console.error(`\nError connecting to Firebase Emulator at http://${host}:${port}`);
  console.error("Make sure the emulator is running: firebase emulators:start --only functions");
  console.error("Details:", error.message);
});

req.write(testPayload);
req.end();
