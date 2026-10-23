const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * System instruction tailored for multilingual Pakistani home service requests.
 * Explicitly instructs the model on Roman Urdu transliteration, code-switching,
 * Urdu in Nastaliq script, localized terminology, and Pakistani Rupee (PKR) offers.
 */
const SYSTEM_INSTRUCTION = `You are Ustaad AI, an expert natural language understanding system for a Pakistani home-services platform.
Your task is to analyze user service requests in English, Urdu, Roman Urdu, or code-switched mixtures (Roman Urdu + English),
and extract a structured service intent.

Linguistic Context & Dialects:
- Pakistani users frequently mix English and Roman Urdu (e.g. "kitchen sink pipe leak ho raha hai budget 600", "fan spark kar raha hai jaldi plumber ya electrician bhejo").
- Urdu script inputs may be in Nastaliq/Arabic unicode characters (e.g. "بجلی کا بریکر جلدی ٹھیک کرو").
- Roman Urdu keywords: bijli, batti, tar, wire, pankha, switch, breaker, pani, nalka, toti, geyzer, tanki, motor, safai, thanda, parhai, ustad, jaldi, foran, kharab, toot, etc.

Supported Service Roles:
1. 'Electrician': Breakers, wiring, short circuit, sparks, ceiling fans, switches, sockets, fuses, lights, UPS, generators, voltage fluctuation.
2. 'Plumber': Water pipes, pipe leakage, taps, sink, washroom plumbing, commode, geyser, water tank, drainage, sewerage, water pump/motor.
3. 'AC Repair': Air conditioner, cooling fault, gas leak, gas charge/refill, compressor, split AC servicing, heating mode.
4. 'Cleaning': Sofa deep cleaning, carpet cleaning, water tank sanitization, floor scrubbing, post-construction cleaning.
5. 'Tutor': Home tuition, school/college subjects (Math, Physics, English, Science), Matric, FSc, O/A Levels.
6. 'Beautician': Bridal makeup, party makeup, haircut, mehndi, facial, waxing, parlour services.
7. 'General': Handyman tasks, furniture assembly, or generic repairs not fitting above categories.

Urgency Classification:
- 'High': Emergency words like "urgent", "jaldi", "foran", "immediately", "asap", "danger", "sparking", "short circuit", "flood", "overflowing", "toot gaya".
- 'Normal': Standard scheduled repair.

Budget & Offer Extraction:
- Look for amounts expressed in PKR/rupees (e.g. "500 mein", "rs 800", "pkr 1200", "budget: 1500", "offer 700 rupay").
- Must be a realistic integer between 50 and 100000. If none found, return null.

Time Label:
- E.g. "Immediate", "Tomorrow morning" (kal subah / کل صبح), "Tomorrow" (kal / کل), "Today" (aaj / آج), "Tonight" (raat / رات), or default to "Next available slot".

Language:
- 'Urdu' if containing Arabic/Urdu script.
- 'Roman Urdu' if containing transliterated Roman Urdu tokens.
- 'English' if standard English.

You MUST reply with JSON ONLY adhering strictly to:
{
  "role": "Electrician" | "Plumber" | "AC Repair" | "Cleaning" | "Tutor" | "Beautician" | "General",
  "description": string (concise, clear English title of the problem),
  "urgency": "High" | "Normal",
  "location": string,
  "timeLabel": string,
  "language": "Urdu" | "Roman Urdu" | "English",
  "confidence": number (between 0.0 and 1.0),
  "userBudget": number | null,
  "reasoning": string (brief summary explaining the categorization and linguistic signals)
}`;

/**
 * Built-in Heuristic Fallback Engine.
 * Used when GEMINI_API_KEY is not configured or in case of network/quota interruptions.
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

/**
 * Callable Cloud Function: extractServiceIntent
 * 
 * Invoked by client via Firebase Functions SDK:
 *   FirebaseFunctions.instance.httpsCallable('extractServiceIntent').call({
 *     problemText: '...',
 *     location: '...',
 *     initialOffer: 500,
 *   });
 */
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

    const apiKey = process.env.GEMINI_API_KEY || data.apiKey || "";

    // If Gemini API Key is available, use Gemini 2.5 Flash for nuanced code-switching extraction
    if (apiKey) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const userPrompt = `Analyze the following user service request:\nUser Request: "${problemText}"\nUser Location: "${location}"\nExplicit Initial Offer (if any): ${initialOffer ? initialOffer + ' PKR' : 'None'}\n\nReturn the structured JSON intent.`;

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

          const validRoles = [
            "Electrician", "Plumber", "AC Repair", "Cleaning",
            "Tutor", "Beautician", "General"
          ];
          const finalRole = validRoles.includes(parsed.role) ? parsed.role : "General";
          const finalUrgency = parsed.urgency === "High" ? "High" : "Normal";
          const finalLang = ["Urdu", "Roman Urdu", "English"].includes(parsed.language)
            ? parsed.language
            : "English";

          return {
            role: finalRole,
            description: parsed.description || `${finalRole} Service`,
            urgency: finalUrgency,
            location: parsed.location || location,
            timeLabel: parsed.timeLabel || "Next available slot",
            language: finalLang,
            confidence: typeof parsed.confidence === "number" ? Math.min(1.0, Math.max(0.0, parsed.confidence)) : 0.94,
            userBudget: initialOffer || (typeof parsed.userBudget === "number" ? parsed.userBudget : null),
            reasoning: parsed.reasoning || "Analyzed via Gemini 2.5 Flash Cloud Logic with multilingual code-switching.",
            source: "gemini-cloud",
          };
        }
      } catch (err) {
        console.warn("Gemini API call failed or timed out; falling back to cloud heuristic:", err.message || err);
      }
    }

    // High-reliability cloud heuristic fallback
    const fallback = heuristicExtractIntent(problemText, location, initialOffer);
    return {
      ...fallback,
      source: "cloud-heuristic",
    };
  }
);
