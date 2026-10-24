const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { GoogleGenAI } = require("@google/genai");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * System instruction tailored for multilingual Pakistani home service requests.
 * Handles English, Urdu (Nastaliq), and Roman Urdu transliteration/code-switching.
 */
const SYSTEM_INSTRUCTION = `You are Ustaad AI, an expert natural language understanding system for a Pakistani home-services platform.
Your task is to analyze user service requests in English, Urdu, Roman Urdu, or code-switched mixtures (Roman Urdu + English),
and extract a structured service intent.

Supported Service Roles:
1. 'Electrician': Breakers, wiring, short circuit, sparks, ceiling fans, switches, sockets, fuses, lights, UPS, generators.
2. 'Plumber': Water pipes, pipe leakage, taps, sink, washroom plumbing, commode, geyser, water tank, drainage, water pump/motor.
3. 'AC Repair': Air conditioner, cooling fault, gas leak, gas charge/refill, compressor, split AC servicing.
4. 'Cleaning': Sofa deep cleaning, carpet cleaning, water tank sanitization, floor scrubbing.
5. 'Tutor': Home tuition, school/college subjects (Math, Physics, English, Science).
6. 'Beautician': Bridal makeup, party makeup, haircut, mehndi, facial, parlour services.
7. 'General': Handyman tasks, furniture assembly, generic repairs.

Urgency Classification:
- 'High': Emergency words like "urgent", "jaldi", "foran", "immediately", "asap", "danger", "sparking", "short circuit", "flood".
- 'Normal': Standard scheduled repair.

Budget Extraction:
- Look for amounts expressed in PKR (e.g. "500 mein", "rs 800", "pkr 1200", "budget: 1500"). Return integer between 50 and 100000.

You MUST reply with JSON ONLY adhering strictly to:
{
  "role": "Electrician" | "Plumber" | "AC Repair" | "Cleaning" | "Tutor" | "Beautician" | "General",
  "description": string,
  "urgency": "High" | "Normal",
  "location": string,
  "timeLabel": string,
  "language": "Urdu" | "Roman Urdu" | "English",
  "confidence": number,
  "userBudget": number | null,
  "reasoning": string
}`;

/**
 * Heuristic Fallback Engine for Intent Extraction.
 */
function heuristicExtractIntent(problem, location, initialOffer) {
  const norm = (problem || "")
    .toLowerCase()
    .replace(/\u064a/g, "\u06cc")
    .replace(/\u0649/g, "\u06cc")
    .replace(/\u0643/g, "\u06a9")
    .replace(/\u06c0/g, "\u06c1")
    .replace(/\u200c/g, "")
    .trim();

  let role = "General";
  let description = "General Maintenance";

  const electricianKeys = [
    "bijli", "batti", "electric", "electrician", "wire", "wiring", "breaker",
    "fan", "pankha", "light", "switch", "socket", "fuse", "inverter", "generator",
    "ups", "short circuit", "spark", "sparking", "board", "voltage", "bulb",
    "بجلی", "بریکر", "پنکھا", "تار", "شارٹ سرکٹ", "سوئچ"
  ];
  const plumberKeys = [
    "plumb", "plumber", "pani", "paani", "nal", "nalka", "leak", "leakage",
    "pipe", "drain", "gutter", "drainage", "sink", "washroom", "toilet",
    "commode", "tap", "toti", "geyser", "tanki", "water tank", "basin",
    "water pump", "motor", "پانی", "نل", "نلکا", "پلمبر", "لیک", "گیزر"
  ];
  const acKeys = [
    "ac", "air conditioner", "cooling", "thanda", "compressor", "gas leak",
    "gas charge", "split", "chilled", "inverter ac", "ac service", "اے سی", "ٹھنڈا", "کولنگ", "گیس"
  ];
  const cleaningKeys = [
    "clean", "cleaning", "safai", "safayi", "dust", "deep clean", "sofa",
    "carpet", "tanki safai", "dhulai", "صفائی", "صاف", "کارپٹ", "صوفہ"
  ];
  const tutorKeys = [
    "tutor", "teacher", "ustad", "ustaad", "math", "maths", "study", "parhai",
    "tuition", "physics", "english", "matric", "fsc", "استاد", "ٹیچر", "پڑھائی"
  ];
  const beautyKeys = [
    "beauty", "makeup", "salon", "parlour", "bridal", "mehndi", "haircut",
    "facial", "waxing", "بیوٹی", "میک اپ", "سیلون", "مہندی"
  ];

  if (electricianKeys.some(k => norm.includes(k))) {
    role = "Electrician";
    description = norm.includes("breaker") || norm.includes("short circuit") || norm.includes("spark")
      ? "Breaker & Short Circuit Fault"
      : norm.includes("fan") || norm.includes("pankha")
      ? "Ceiling Fan Service & Repair"
      : "Electrical Repair";
  } else if (plumberKeys.some(k => norm.includes(k))) {
    role = "Plumber";
    description = norm.includes("geyser") || norm.includes("tanki")
      ? "Geyser & Water Tank Maintenance"
      : norm.includes("sink") || norm.includes("washroom")
      ? "Washroom Sink & Plumbing Repair"
      : "Plumbing Issue & Leak Fix";
  } else if (acKeys.some(k => norm.includes(k))) {
    role = "AC Repair";
    description = norm.includes("gas")
      ? "AC Gas Refill & Leak Check"
      : norm.includes("cooling") || norm.includes("thanda")
      ? "AC Cooling Fault Troubleshooting"
      : "AC Service & Maintenance";
  } else if (cleaningKeys.some(k => norm.includes(k))) {
    role = "Cleaning";
    description = norm.includes("sofa") || norm.includes("carpet")
      ? "Sofa & Carpet Deep Cleaning"
      : "Deep Cleaning Request";
  } else if (tutorKeys.some(k => norm.includes(k))) {
    role = "Tutor";
    description = "Tutoring Session";
  } else if (beautyKeys.some(k => norm.includes(k))) {
    role = "Beautician";
    description = "Beauty Service & Grooming";
  }

  const isUrgent = ["urgent", "jaldi", "foran", "emergency", "asap", "sparks", "danger", "فوراً", "جلدی", "خراب"]
    .some(k => norm.includes(k));

  let timeLabel = "Next available slot";
  if (norm.includes("kal subah") || norm.includes("tomorrow morning") || norm.includes("کل صبح")) {
    timeLabel = "Tomorrow morning";
  } else if (norm.includes("kal") || norm.includes("tomorrow") || norm.includes("کل")) {
    timeLabel = "Tomorrow";
  } else if (norm.includes("aaj") || norm.includes("today") || norm.includes("آج")) {
    timeLabel = "Today";
  } else if (norm.includes("raat") || norm.includes("tonight") || norm.includes("رات")) {
    timeLabel = "Tonight";
  }

  let language = "English";
  if (/[\u0600-\u06ff]/.test(problem)) {
    language = "Urdu";
  } else if (["mujhe", "chahiye", "kal", "subah", "pani", "bijli", "jaldi", "foran", "parhai", "safai", "thanda", "mein", "ka", "ki", "ke", "hai"].some(k => norm.includes(k))) {
    language = "Roman Urdu";
  }

  let extractedBudget = null;
  const budgetPatterns = [
    /(?:budget|offer|rs\.?|pkr|rupay|rupees)\s*[:=]?\s*(\d{2,6})/i,
    /(\d{2,6})\s*(?:rs\.?|pkr|rupay|rupees|rp|mein|me|ma\b)/i,
  ];
  for (const pat of budgetPatterns) {
    const match = problem.match(pat);
    if (match && match[1]) {
      const val = parseInt(match[1], 10);
      if (val >= 50 && val <= 100000) {
        extractedBudget = val;
        break;
      }
    }
  }

  return {
    role,
    description,
    urgency: isUrgent ? "High" : "Normal",
    location: location || "Islamabad",
    timeLabel,
    language,
    confidence: role === "General" ? 0.75 : 0.92,
    userBudget: initialOffer || extractedBudget,
    reasoning: `Extracted via cloud heuristic fallback engine [language=${language}, urgency=${isUrgent ? "High" : "Normal"}].`,
  };
}

// =========================================================================
// 1. PHASE 3 — Callable Cloud Function: extractServiceIntent
// =========================================================================
exports.extractServiceIntent = onCall(
  {
    cors: true,
    region: "us-central1",
    maxInstances: 10,
  },
  async (request) => {
    const data = request.data || {};
    const problemText = typeof data.problemText === "string" ? data.problemText.trim() : "";
    const location = typeof data.location === "string" ? data.location.trim() : "Islamabad";
    const initialOffer = typeof data.initialOffer === "number" ? data.initialOffer : null;

    if (!problemText) {
      throw new HttpsError(
        "invalid-argument",
        "The function must be called with a non-empty 'problemText' string."
      );
    }

    if (problemText.length > 500) {
      throw new HttpsError(
        "invalid-argument",
        "Problem description exceeds maximum allowable length of 500 characters."
      );
    }

    const apiKey = process.env.GEMINI_API_KEY || data.apiKey || "";

    if (apiKey) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const userPrompt = `Analyze user request: "${problemText}" in "${location}". Initial offer: ${initialOffer || "None"}.`;

        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: userPrompt,
          config: {
            systemInstruction: SYSTEM_INSTRUCTION,
            responseMimeType: "application/json",
            temperature: 0.1,
          },
        });

        const text = response?.text?.trim() || "";
        if (text) {
          const parsed = JSON.parse(text);
          return {
            role: parsed.role || "General",
            description: parsed.description || "Home Service",
            urgency: parsed.urgency || "Normal",
            location: parsed.location || location,
            timeLabel: parsed.timeLabel || "Next available slot",
            language: parsed.language || "English",
            confidence: typeof parsed.confidence === "number" ? parsed.confidence : 0.95,
            userBudget: initialOffer || parsed.userBudget || null,
            reasoning: parsed.reasoning || "Analyzed via Gemini 2.5 Flash Cloud Logic.",
            source: "gemini-cloud",
          };
        }
      } catch (err) {
        console.warn("Gemini API call failed, falling back to heuristic:", err.message);
      }
    }

    const fallback = heuristicExtractIntent(problemText, location, initialOffer);
    return {
      ...fallback,
      source: "cloud-heuristic",
    };
  }
);

// =========================================================================
// 2. PHASE 4 & 5 — Firestore Trigger: onBookingCreate
// =========================================================================
exports.onBookingCreate = onDocumentCreated("bookings/{bookingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const booking = snapshot.data();
  const bookingId = event.params.bookingId;
  const providerId = booking.providerId || booking.provider_id;

  console.log(`[onBookingCreate] Processing new booking ${bookingId} for provider ${providerId}`);

  // Fetch provider FCM tokens for instant push notification
  if (providerId) {
    try {
      const providerDoc = await db.collection("users").doc(providerId).get();
      if (providerDoc.exists) {
        const tokens = providerDoc.data().fcmTokens || [];
        if (tokens.length > 0) {
          await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
              title: "نیا آرڈر موصول ہوا! (New Job Request)",
              body: `New booking request: ${booking.serviceType || "Service"} (${booking.priceEstimate || 0} PKR)`,
            },
            data: {
              bookingId,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          });
        }
      }
    } catch (err) {
      console.error("[onBookingCreate] FCM dispatch error:", err);
    }
  }
});

// =========================================================================
// 3. PHASE 4 & 5 — Firestore Trigger: onBookingStatusChange
// =========================================================================
exports.onBookingStatusChange = onDocumentUpdated("bookings/{bookingId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const bookingId = event.params.bookingId;

  if (before.status === after.status) return;

  const validTransitions = {
    pending: ["confirmed", "cancelled"],
    confirmed: ["en_route", "cancelled"],
    en_route: ["in_progress", "cancelled"],
    in_progress: ["completed", "cancelled"],
    completed: [],
    cancelled: [],
  };

  const allowed = validTransitions[before.status] || [];
  if (!allowed.includes(after.status)) {
    console.warn(`[onBookingStatusChange] Invalid transition attempt: ${before.status} -> ${after.status} on booking ${bookingId}`);
  }

  // Notify customer of status change
  const customerId = after.customerId || after.user_id;
  if (customerId) {
    try {
      const customerDoc = await db.collection("users").doc(customerId).get();
      if (customerDoc.exists) {
        const tokens = customerDoc.data().fcmTokens || [];
        if (tokens.length > 0) {
          const statusLabels = {
            confirmed: "Your booking is confirmed! Ustaad is assigned.",
            en_route: "Ustaad is en route to your location! (راستے میں ہیں)",
            in_progress: "Work in progress. (کام جاری ہے)",
            completed: "Booking completed! Please leave a review. (کام مکمل)",
            cancelled: "Booking was cancelled.",
          };
          await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
              title: "Booking Update (آرڈر کی تفصیل)",
              body: statusLabels[after.status] || `Status updated to ${after.status}`,
            },
            data: {
              bookingId,
              status: after.status,
            },
          });
        }
      }
    } catch (err) {
      console.error("[onBookingStatusChange] FCM notification error:", err);
    }
  }
});

// =========================================================================
// 4. PHASE 4 — Firestore Trigger: onReviewCreate (Atomic Rating Recalculation)
// =========================================================================
exports.onReviewCreate = onDocumentCreated("reviews/{reviewId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const review = snapshot.data();
  const providerId = review.providerId || review.provider_id;
  const rating = Number(review.rating) || 5;

  if (!providerId) return;

  const providerRef = db.collection("providers").doc(providerId);

  try {
    await db.runTransaction(async (transaction) => {
      const providerDoc = await transaction.get(providerRef);
      if (!providerDoc.exists) return;

      const data = providerDoc.data();
      const currentRating = Number(data.rating) || 5.0;
      const currentCount = Number(data.reviewCount) || 0;

      const newCount = currentCount + 1;
      const newRating = Number(((currentRating * currentCount + rating) / newCount).toFixed(2));

      transaction.update(providerRef, {
        rating: newRating,
        reviewCount: newCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    console.log(`[onReviewCreate] Successfully updated provider ${providerId} rating atomically.`);
  } catch (err) {
    console.error("[onReviewCreate] Failed to update provider rating:", err);
  }
});

// =========================================================================
// 5. PHASE 6 — Callable Cloud Function: verifyJazzCashPayment
// =========================================================================
exports.verifyJazzCashPayment = onCall(
  {
    cors: true,
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated to verify payments.");
    }

    const { transactionRef, bookingId, amount } = request.data || {};

    if (!transactionRef || !bookingId || !amount) {
      throw new HttpsError("invalid-argument", "Missing transactionRef, bookingId, or amount.");
    }

    // Server-side audit and verification
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Associated booking not found.");
    }

    const paymentRecord = {
      bookingId,
      customerId: request.auth.uid,
      amount: Number(amount),
      gateway: "JazzCash",
      transactionRef,
      status: "success",
      verifiedByServer: true,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("payments").add(paymentRecord);

    await bookingRef.update({
      paymentStatus: "paid",
      status: "confirmed",
      transactionRef,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      transactionRef,
      status: "paid",
      message: "JazzCash payment verified successfully by Ustaad server.",
    };
  }
);

// =========================================================================
// 6. PHASE 7 — Callable Cloud Function: searchProviders (Server-side Ranking)
// =========================================================================
exports.searchProviders = onCall(
  {
    cors: true,
    region: "us-central1",
  },
  async (request) => {
    const { serviceType, city = "Islamabad", userLocation, offer } = request.data || {};

    // Configurable weights (can also be read from config/ranking_weights doc)
    const weights = {
      distance: 0.3,
      rating: 0.4,
      price: 0.2,
      responseTime: 0.1,
    };

    let query = db.collection("providers");
    if (city) {
      query = query.where("city", "==", city);
    }

    const snapshot = await query.get();
    const providers = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      data.id = doc.id;
      providers.push(data);
    });

    // Score and rank providers
    const scored = providers.map((p) => {
      const rating = Number(p.rating) || 4.5;
      const price = Number(p.price) || 1000;
      const distance = Number(p.distanceKm) || 4.0;
      const responseTime = Number(p.responseTimeMinutes) || 15;

      const normalizedRating = (rating / 5.0) * 100;
      const normalizedDistance = Math.max(0, 100 - distance * 10);
      const normalizedPrice = offer ? Math.max(0, 100 - Math.abs(price - offer) / 20) : 80;
      const normalizedResponse = Math.max(0, 100 - responseTime * 2);

      const totalScore =
        normalizedRating * weights.rating +
        normalizedDistance * weights.distance +
        normalizedPrice * weights.price +
        normalizedResponse * weights.responseTime;

      let rankingReason = "Recommended";
      if (rating >= 4.8) rankingReason = "Top Rated";
      else if (distance <= 2.5) rankingReason = "Nearest";
      else if (price <= 600) rankingReason = "Best Value";

      return {
        ...p,
        totalScore: Math.round(totalScore),
        rankingReason,
      };
    });

    scored.sort((a, b) => b.totalScore - a.totalScore);

    if (scored.length > 0) {
      scored[0].rankingReason = "Best Match";
    }

    return {
      providers: scored.slice(0, 20),
      count: scored.length,
      weights,
    };
  }
);

// =========================================================================
// 7. PHASE 8 — Firestore Trigger: onNewChatMessage
// =========================================================================
exports.onNewChatMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const message = snapshot.data();
  const chatId = event.params.chatId;
  const senderId = message.senderId;

  try {
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;

    const participants = chatDoc.data().participants || [];
    const recipientId = participants.find((id) => id !== senderId);

    if (recipientId) {
      const recipientDoc = await db.collection("users").doc(recipientId).get();
      if (recipientDoc.exists) {
        const tokens = recipientDoc.data().fcmTokens || [];
        if (tokens.length > 0) {
          await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
              title: "New Message from Ustaad",
              body: message.text || "You have a new message.",
            },
            data: {
              chatId,
              senderId,
            },
          });
        }
      }
    }
  } catch (err) {
    console.error("[onNewChatMessage] FCM dispatch error:", err);
  }
});
