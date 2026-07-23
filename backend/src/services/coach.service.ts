// ============================================================
//  src/services/coach.service.ts
//  Aura — Local Ollama AI Personal Coach Service
// ============================================================

import { OLLAMA_CONFIG } from "../config";

interface ExerciseInput {
  name: string;
  targetSets: number;
  lastWeekWeight?: number | null;
  lastWeekReps?: number | null;
}

interface WorkoutSessionInput {
  splitName: string;
  todayDayName: string;
  exercises: ExerciseInput[];
}

interface WeightTrendInput {
  totalDelta?: number;
  minWeight?: number;
  maxWeight?: number;
  avgWeight?: number;
  trend?: "losing" | "gaining" | "stable";
  goal?: string;
}

// ── Helper: Ollama Chat Call with Timeout & Fallback ───────

async function callOllamaChat(systemPrompt: string, userPrompt: string, fallback: string): Promise<string> {
  const provider = process.env.AI_PROVIDER ?? "ollama";
  if (provider === "none") {
    return fallback;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3500); // 3.5s safety cap

  try {
    const response = await fetch(`${OLLAMA_CONFIG.baseUrl}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      body: JSON.stringify({
        model: OLLAMA_CONFIG.model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        stream: false,
        options: {
          temperature: OLLAMA_CONFIG.temperature ?? 0.7,
          num_predict: 80, // Cap output token count for fast UI captions
        },
      }),
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return fallback;
    }

    const data = (await response.json()) as any;
    const content = data.message?.content?.trim();

    if (!content) {
      return fallback;
    }

    // Strip markdown formatting, quotes, or newlines
    const cleaned = content.replace(/```[a-z]*|```/g, "").replace(/^["']|["']$/g, "").replace(/\s+/g, " ").trim();
    return cleaned || fallback;
  } catch (err) {
    clearTimeout(timeoutId);
    return fallback;
  }
}

// ── 1. Workout Session Coach Note ────────────────────────────

export async function generateWorkoutCoachNote(session: WorkoutSessionInput): Promise<string> {
  if (!session.exercises || session.exercises.length === 0) {
    return "Today is a dedicated rest day. Focus on hydration, mobility, and high-quality recovery.";
  }

  const exListStr = session.exercises
    .map((e) => `${e.name} (${e.lastWeekWeight ? `${e.lastWeekWeight}kg × ${e.lastWeekReps}` : "no history"})`)
    .join(", ");

  const systemPrompt = `You are an elite, encouraging strength coach. Produce 1-2 short, plain-language sentences max (maximum 35 words total). Explain what to focus on for today's session and why exercise sequence matters. Do NOT use markdown, bullet points, or quotes. Speak directly to the lifter.`;
  const userPrompt = `Routine: ${session.splitName} - ${session.todayDayName}. Exercises today: ${exListStr}. Give a short 1-2 sentence coach tip.`;

  const fallback = `Focus on clean execution today. Prioritize your heavy compound lifts first before moving to accessory movements.`;
  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 2. Exercise Specific Coach Note ──────────────────────────

export async function generateExerciseCoachNote(exercise: ExerciseInput): Promise<string> {
  const hasHistory = exercise.lastWeekWeight != null && exercise.lastWeekWeight > 0;
  const historyText = hasHistory
    ? `Last performance: ${exercise.lastWeekWeight}kg × ${exercise.lastWeekReps} reps.`
    : "No previous history recorded.";

  const systemPrompt = `You are a fitness coach. Produce exactly ONE short sentence (maximum 20 words) explaining what to aim for on this exercise today. No markdown, no quotes.`;
  const userPrompt = `Exercise: ${exercise.name}. ${historyText} Give one concise tip.`;

  const fallback = hasHistory
    ? `Target matching or exceeding ${exercise.lastWeekWeight}kg × ${exercise.lastWeekReps} with controlled reps.`
    : `First time on this exercise — start conservative and prioritize form.`;

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 3. Weight Progress Coach Note ───────────────────────────

export async function generateWeightCoachNote(trendData: WeightTrendInput): Promise<string> {
  const trend = trendData.trend ?? "stable";
  const delta = trendData.totalDelta ?? 0;
  const goal = trendData.goal ?? "maintain";

  const systemPrompt = `You are an empathetic, data-driven weight coach. Produce exactly ONE short, encouraging sentence (maximum 20 words) interpreting the user's weight trend. Stay strictly aligned with the trend direction (${trend}). Never contradict a losing or gaining trend. No markdown, no quotes.`;
  const userPrompt = `Goal: ${goal}, Trend: ${trend}, Weight Delta: ${delta}kg. Give one short supportive sentence.`;

  let fallback = "Holding steady over recent logs — consistency with your nutrition is key.";
  if (trend === "losing") {
    fallback = `Down ${Math.abs(delta)}kg — your pace is steady and right on track.`;
  } else if (trend === "gaining") {
    fallback = `Trending upward by ${Math.abs(delta)}kg — supporting muscle gain and strength progress.`;
  }

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}
