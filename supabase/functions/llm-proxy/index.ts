// Supabase Edge Function: LLM Backend Proxy for Ustaad Agentic App
// Shields OpenRouter and Gemini API keys behind a secure backend edge runtime.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-title, http-referer",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const openRouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    const body = await req.json();

    // Check if the request is an OpenAI-compatible /chat/completions request
    const messages = body.messages;
    const model = body.model || Deno.env.get("OPENROUTER_MODEL") || "deepseek/deepseek-chat";
    const responseFormat = body.response_format;
    const temperature = body.temperature ?? 0.2;

    // Route 1: If OpenRouter key is set, proxy to OpenRouter securely
    if (openRouterApiKey && openRouterApiKey.trim().length > 0) {
      const openRouterResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${openRouterApiKey.trim()}`,
          "HTTP-Referer": "https://ustaad.app",
          "X-Title": "Ustaad Agentic Proxy",
        },
        body: JSON.stringify({
          model,
          messages,
          ...(responseFormat ? { response_format: responseFormat } : {}),
          temperature,
        }),
      });

      const responseData = await openRouterResponse.text();
      return new Response(responseData, {
        status: openRouterResponse.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Route 2: Fallback to Google Gemini if GEMINI_API_KEY is configured
    if (geminiApiKey && geminiApiKey.trim().length > 0) {
      const lastUserMsg = Array.isArray(messages)
        ? [...messages].reverse().find((m: { role: string }) => m.role === "user")?.content || ""
        : body.prompt || "";

      const systemMsg = Array.isArray(messages)
        ? messages.find((m: { role: string }) => m.role === "system")?.content || ""
        : "";

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey.trim()}`;
      const geminiResponse = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `${systemMsg ? systemMsg + "\n\n" : ""}${lastUserMsg}` }] }],
          generationConfig: {
            temperature,
            ...(responseFormat?.type === "json_object" ? { responseMimeType: "application/json" } : {}),
          },
        }),
      });

      const geminiData = await geminiResponse.json();
      const textOutput = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text || "";

      // Adapt to OpenAI format for consistent client consumption
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                role: "assistant",
                content: textOutput,
              },
            },
          ],
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Neither key is configured on backend
    return new Response(
      JSON.stringify({
        error: "Backend proxy has no AI API keys configured. Set OPENROUTER_API_KEY or GEMINI_API_KEY in Supabase secrets.",
      }),
      {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: "Backend proxy error: " + (error instanceof Error ? error.message : String(error)) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
