import { GoogleGenerativeAI } from "@google/generative-ai";
import { OLLAMA_CONFIG } from "../config";

const apiKey = process.env.GEMINI_API_KEY || "";
const genAI = new GoogleGenerativeAI(apiKey);

interface ExerciseInput {
  name: string;
  targetSets: number;
  lastWeekWeight?: number | null;
  lastWeekReps?: number | null;
  isPlateaued?: boolean;
}

interface WorkoutSessionInput {
  splitName: string;
  todayDayName: string;
  exercises: ExerciseInput[];
  isOverridden?: boolean;
  isSkipped?: boolean;
  streakDays?: number;
  highFatigueRisk?: boolean;
}

interface WeightTrendInput {
  totalDelta?: number;
  minWeight?: number;
  maxWeight?: number;
  avgWeight?: number;
  trend?: "losing" | "gaining" | "stable";
  goal?: string;
}

// ── Helper: Ollama Response Metadata & Call Options ────────

export interface OllamaResult<T> {
  value: T;
  source: "model" | "timeout" | "error";
  elapsedMs: number;
  evalCount?: number;
}

export interface OllamaCallOptions {
  callerName?: string;
  timeoutMs?: number;
  numPredict?: number;
}

// ── Helper: Ollama Circuit Breaker State ────────────────────
let isOllamaOffline = false;
let lastOllamaCheck = 0;
const OLLAMA_OFFLINE_COOLDOWN_MS = 60000; // 1 min cooldown before retrying Ollama connection

function isOllamaCurrentlyOffline(): boolean {
  if (isOllamaOffline && (Date.now() - lastOllamaCheck < OLLAMA_OFFLINE_COOLDOWN_MS)) {
    return true;
  }
  return false;
}

function resolveGeminiModelName(): string {
  const envModel = process.env.GEMINI_MODEL || "gemini-1.5-flash";
  if (envModel === "gemini-1.5-flash") {
    return "gemini-flash-latest";
  }
  return envModel;
}

// ── Helper: Ollama Chat Call with Timeout, Logging & Source Metadata ──────

async function callOllamaChatDetailed(
  systemPrompt: string,
  userPrompt: string,
  fallback: string,
  options?: OllamaCallOptions
): Promise<OllamaResult<string>> {
  const provider = process.env.AI_PROVIDER ?? "gemini";
  const callerName = options?.callerName ?? "callOllamaChat";
  const timeoutMs = options?.timeoutMs ?? 8000;
  const numPredict = options?.numPredict ?? 80;
  const startTime = Date.now();

  if (provider === "gemini" || provider === "google") {
    try {
      const modelName = resolveGeminiModelName();
      const model = genAI.getGenerativeModel({ model: modelName });
      const prompt = `${systemPrompt}\n\nUser Question/Context:\n${userPrompt}`;
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      const cleaned = text.replace(/```[a-z]*|```/g, "").replace(/^["']|["']$/g, "").replace(/\s+/g, " ").trim();
      return {
        value: cleaned || fallback,
        source: "model",
        elapsedMs: Date.now() - startTime,
      };
    } catch (err: any) {
      console.warn(`⚠️ [Gemini Coach Error] '${callerName}' failed: ${err.message}`);
      return { value: fallback, source: "error", elapsedMs: Date.now() - startTime };
    }
  }

  if (provider === "none" || isOllamaCurrentlyOffline()) {
    return { value: fallback, source: "error", elapsedMs: 0 };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

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
          num_predict: numPredict,
        },
      }),
    });

    clearTimeout(timeoutId);
    const elapsedMs = Date.now() - startTime;

    if (!response.ok) {
      isOllamaOffline = true;
      lastOllamaCheck = Date.now();
      console.warn(`⚠️ [Ollama Error] '${callerName}' failed with HTTP ${response.status} after ${elapsedMs}ms.`);
      return { value: fallback, source: "error", elapsedMs };
    }

    const data = (await response.json()) as any;
    const content = data.message?.content?.trim();
    const evalCount = data.eval_count;

    if (!content) {
      console.warn(`⚠️ [Ollama Error] '${callerName}' returned empty content after ${elapsedMs}ms.`);
      return { value: fallback, source: "error", elapsedMs, evalCount };
    }

    isOllamaOffline = false;
    const cleaned = content.replace(/```[a-z]*|```/g, "").replace(/^["']|["']$/g, "").replace(/\s+/g, " ").trim();
    return { value: cleaned || fallback, source: "model", elapsedMs, evalCount };
  } catch (err: any) {
    clearTimeout(timeoutId);
    isOllamaOffline = true;
    lastOllamaCheck = Date.now();
    const elapsedMs = Date.now() - startTime;
    if (err?.name === "AbortError") {
      console.warn(`⚠️ [Ollama Timeout] '${callerName}' timed out after ${elapsedMs}ms (limit: ${timeoutMs}ms).`);
      return { value: fallback, source: "timeout", elapsedMs };
    }
    console.warn(`⚠️ [Ollama Error] '${callerName}' failed with error: ${err?.message ?? err} after ${elapsedMs}ms.`);
    return { value: fallback, source: "error", elapsedMs };
  }
}

async function callOllamaChat(
  systemPrompt: string,
  userPrompt: string,
  fallback: string,
  options?: OllamaCallOptions
): Promise<string> {
  const res = await callOllamaChatDetailed(systemPrompt, userPrompt, fallback, options);
  return res.value;
}

// ── Helper: Ollama Chat Call (JSON Mode) ───────────────────

async function callOllamaJsonChatDetailed<T>(
  systemPrompt: string,
  userPrompt: string,
  fallback: T,
  options?: OllamaCallOptions
): Promise<OllamaResult<T>> {
  const provider = process.env.AI_PROVIDER ?? "gemini";
  const callerName = options?.callerName ?? "callOllamaJsonChat";
  const timeoutMs = options?.timeoutMs ?? 8000;
  const numPredict = options?.numPredict ?? 140;
  const startTime = Date.now();

  if (provider === "gemini" || provider === "google") {
    try {
      const modelName = resolveGeminiModelName();
      const model = genAI.getGenerativeModel({ model: modelName });
      const prompt = `${systemPrompt}\n\nUser Prompt:\n${userPrompt}\n\nIMPORTANT: Respond ONLY with valid JSON. Do not include markdown codeblocks or extra text.`;
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      const cleaned = text.replace(/```[a-z]*|```/g, "").replace(/^["']|["']$/g, "").trim();
      const parsed = JSON.parse(cleaned) as T;
      return {
        value: parsed || fallback,
        source: "model",
        elapsedMs: Date.now() - startTime,
      };
    } catch (err: any) {
      console.warn(`⚠️ [Gemini Coach JSON Error] '${callerName}' failed: ${err.message}`);
      return { value: fallback, source: "error", elapsedMs: Date.now() - startTime };
    }
  }

  if (provider === "none" || isOllamaCurrentlyOffline()) {
    return { value: fallback, source: "error", elapsedMs: 0 };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

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
        format: "json",
        options: {
          temperature: 0.2,
          num_predict: numPredict,
        },
      }),
    });

    clearTimeout(timeoutId);
    const elapsedMs = Date.now() - startTime;

    if (!response.ok) {
      console.warn(`⚠️ [Ollama Error] '${callerName}' failed with HTTP ${response.status} after ${elapsedMs}ms.`);
      return { value: fallback, source: "error", elapsedMs };
    }

    const data = (await response.json()) as any;
    const content = data.message?.content?.trim();
    const evalCount = data.eval_count;

    if (!content) {
      console.warn(`⚠️ [Ollama Error] '${callerName}' returned empty content after ${elapsedMs}ms.`);
      return { value: fallback, source: "error", elapsedMs, evalCount };
    }

    const parsed = JSON.parse(content) as T;
    return { value: parsed || fallback, source: "model", elapsedMs, evalCount };
  } catch (err: any) {
    clearTimeout(timeoutId);
    const elapsedMs = Date.now() - startTime;
    if (err?.name === "AbortError") {
      console.warn(`⚠️ [Ollama Timeout] '${callerName}' timed out after ${elapsedMs}ms (limit: ${timeoutMs}ms).`);
      return { value: fallback, source: "timeout", elapsedMs };
    }
    console.warn(`⚠️ [Ollama Error] '${callerName}' failed with error: ${err?.message ?? err} after ${elapsedMs}ms.`);
    return { value: fallback, source: "error", elapsedMs };
  }
}

async function callOllamaJsonChat<T>(
  systemPrompt: string,
  userPrompt: string,
  fallback: T,
  options?: OllamaCallOptions
): Promise<T> {
  const res = await callOllamaJsonChatDetailed<T>(systemPrompt, userPrompt, fallback, options);
  return res.value;
}

// ── 1. Workout Session Coach Note ────────────────────────────

export async function generateWorkoutCoachNote(session: WorkoutSessionInput): Promise<string> {
  if (session.isSkipped) {
    const systemPrompt = `You are an encouraging strength coach. Produce 1 short sentence (maximum 25 words) acknowledging that the user marked today's workout as skipped. Be supportive and emphasize recovery and resuming next session. No markdown, no quotes.`;
    const userPrompt = `User skipped today's ${session.todayDayName} session. Give a brief supportive note.`;
    const fallback = `Marked as skipped — no problem, we'll pick right back up next session. Focus on rest and recovery today.`;
    return callOllamaChat(systemPrompt, userPrompt, fallback);
  }

  if (session.highFatigueRisk) {
    const systemPrompt = `You are a proactive strength & recovery coach. The user has completed 3+ consecutive days of workouts without rest and is training today. Produce 1-2 short sentences (maximum 30 words) cautioning them on fatigue and suggesting a lighter intensity session or taking an extra rest day. No markdown, no quotes.`;
    const userPrompt = `User has trained 3+ consecutive days without rest. Today is ${session.todayDayName}. Give a fatigue caution tip.`;
    const fallback = `You've worked out 3+ days in a row. Listen closely to your body today — consider dropping intensity slightly or taking an extra rest day if fatigue sets in.`;
    return callOllamaChat(systemPrompt, userPrompt, fallback);
  }

  if (session.isOverridden) {
    const systemPrompt = `You are an expert strength coach. The user manually swapped today's session to ${session.todayDayName}. Produce 1-2 short sentences (maximum 30 words) acknowledging the swap and advising them to listen to their body and adjust recovery. No markdown, no quotes.`;
    const userPrompt = `User swapped today's session to ${session.todayDayName} on routine ${session.splitName}. Give a short coach tip acknowledging the swap.`;
    const fallback = `You swapped in ${session.todayDayName} today — make sure you are adequately recovered, and listen to your body throughout the session.`;
    return callOllamaChat(systemPrompt, userPrompt, fallback);
  }

  if (!session.exercises || session.exercises.length === 0) {
    return "Today is a dedicated rest day. Focus on hydration, mobility, and high-quality recovery.";
  }

  const exListStr = session.exercises
    .map((e) => `${e.name} (${e.lastWeekWeight ? `${e.lastWeekWeight}kg × ${e.lastWeekReps}` : "no history"})`)
    .join(", ");

  const streak = session.streakDays ?? 0;
  let streakContext = "";
  if (streak >= 3) {
    streakContext = `User is on a strong ${streak}-day active workout streak! Explicitly praise their ${streak}-day streak and consistency.`;
  } else if (streak <= 1) {
    streakContext = `User has 0-1 recent streak days. Encourage them to ease back in cleanly without rushing intensity.`;
  } else {
    streakContext = `User has a ${streak}-day workout streak. Encourage solid execution.`;
  }

  const systemPrompt = `You are an elite, encouraging strength coach. Produce 1-2 short, plain-language sentences max (maximum 35 words total). Explain what to focus on for today's session and why exercise sequence matters. ${streakContext} Do NOT use markdown, bullet points, or quotes. Speak directly to the lifter.`;
  const userPrompt = `Routine: ${session.splitName} - ${session.todayDayName}. Exercises today: ${exListStr}. Streak: ${streak} days. Give a short 1-2 sentence coach tip.`;

  let fallback = `Focus on clean execution today. Prioritize your heavy compound lifts first before moving to accessory movements.`;
  if (streak >= 3) {
    fallback = `Incredible ${streak}-day streak! Keep this powerful momentum going today by prioritizing clean execution on compound lifts first.`;
  } else if (streak <= 1) {
    fallback = `Welcome back! Ease into today's session with clean form and controlled reps — building consistency is your top priority.`;
  }

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 2. Swap Suggestion Coach Note ────────────────────────────

interface SwapSuggestionInput {
  splitName: string;
  completedDaysThisWeek: string[];
  availableOptions: string[];
}

export async function generateSwapSuggestionNote(input: SwapSuggestionInput): Promise<string> {
  const systemPrompt = `You are a smart strength coach offering a quick 1-sentence recommendation for a workout session swap. Produce exactly ONE short sentence (maximum 22 words). No markdown, no quotes.`;
  const userPrompt = `Routine: ${input.splitName}. Sessions completed this week: ${input.completedDaysThisWeek.join(", ") || "none"}. Available swap options: ${input.availableOptions.join(", ")}. Recommend the single best option to swap today.`;

  const recommendedOption = input.availableOptions[0] ?? "Legs";
  const fallback = input.completedDaysThisWeek.length > 0
    ? `Given your recent sessions this week, ${recommendedOption} is likely your best swap choice today.`
    : `Selecting ${recommendedOption} keeps your training balanced and recovery on track today.`;

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 3. Exercise Specific Coach Note ──────────────────────────

export async function generateExerciseCoachNote(exercise: ExerciseInput): Promise<string> {
  if (exercise.isPlateaued) {
    const systemPrompt = `You are an expert strength coach. The user has plateaued on ${exercise.name} across their last 3 completed sessions (${exercise.lastWeekWeight ?? 0}kg × ${exercise.lastWeekReps ?? 0} reps). Produce exactly ONE short sentence (maximum 22 words) giving a concrete adjustment like a 10% deload or changing rep targets. No markdown, no quotes.`;
    const userPrompt = `Exercise: ${exercise.name} is plateaued. Last stats: ${exercise.lastWeekWeight}kg x ${exercise.lastWeekReps}. Give a concrete deload or rep adjustment tip.`;
    const fallback = `Plateau detected on ${exercise.name}: try a 10% deload or adjust rep ranges to spark new adaptation.`;
    return callOllamaChat(systemPrompt, userPrompt, fallback);
  }

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

// ── 4. Weight Progress Coach Note ───────────────────────────

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

// ── 5. Routine Recommendation Coach Note ─────────────────────

interface RoutineRecommendInput {
  days: number;
  trainingExperience: string;
  goal: string;
  splitName: string;
}

export async function generateRoutineRecommendationNote(input: RoutineRecommendInput): Promise<string> {
  const expLabel = input.trainingExperience === "new"
    ? "beginner"
    : input.trainingExperience === "experienced"
    ? "experienced"
    : "intermediate";

  const systemPrompt = `You are an expert strength coach explaining why a specific routine split is recommended for a user. Write 1-2 short sentences max (maximum 35 words total). Explicitly reference their ${input.days}-day schedule, ${expLabel} experience, and ${input.goal} goal. No markdown, no quotes.`;
  const userPrompt = `Split: ${input.splitName}. User context: ${input.days} days/week, ${expLabel} experience, goal is ${input.goal}. Explain why this split is best fit.`;

  const fallback = `As a ${expLabel} lifter training ${input.days} days per week, ${input.splitName} provides the optimal balance of muscle frequency and recovery capacity for your ${input.goal} goal.`;
  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 6. Post-Workout Summary Coach Note ───────────────────────

interface FinishedWorkoutSessionInput {
  sessionName: string;
  exercisesLogged: number;
  totalSetsCompleted: number;
  prsAchieved?: string[];
}

export async function generateWorkoutSummaryNote(input: FinishedWorkoutSessionInput): Promise<string> {
  const prText = input.prsAchieved && input.prsAchieved.length > 0
    ? `Personal Records set today: ${input.prsAchieved.join(", ")}.`
    : "No new PRs set today, but execution and consistency were solid.";

  const systemPrompt = `You are an enthusiastic strength coach providing a 1-2 sentence post-workout summary (maximum 30 words). If the user set a PR today, celebrate it explicitly! Otherwise, praise their effort and consistency. No markdown, no quotes.`;
  const userPrompt = `Finished workout: ${input.sessionName}. Exercises completed: ${input.exercisesLogged}, Total sets: ${input.totalSetsCompleted}. ${prText} Give a short post-workout summary note.`;

  const fallback = input.prsAchieved && input.prsAchieved.length > 0
    ? `Outstanding workout! You smashed a new PR today on ${input.prsAchieved[0]}. Keep this momentum going!`
    : `Great job completing your ${input.sessionName} session today! Consistency is where true strength gains are forged.`;

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 7. Overtraining Caution Coach Note ───────────────────────

interface OvertrainingInput {
  consecutiveDays: number;
  splitMaxAllowed: number;
}

export async function generateOvertrainingNote(input: OvertrainingInput): Promise<string> {
  const systemPrompt = `You are a strength and recovery coach. The user has logged ${input.consecutiveDays} consecutive training days, exceeding their plan's scheduled maximum (${input.splitMaxAllowed} days in a row). Produce ONE short sentence (maximum 22 words) advising them to schedule a rest day soon. No markdown, no quotes.`;
  const userPrompt = `User trained ${input.consecutiveDays} days straight when split allows max ${input.splitMaxAllowed}. Give a short recovery rest day advice.`;

  const fallback = `You've trained ${input.consecutiveDays} days in a row — consider scheduling a rest day soon to allow muscle recovery and prevent overtraining.`;
  return callOllamaChat(systemPrompt, userPrompt, fallback);
}

// ── 8. Natural Language Session Intent Interpreter ───────────

export interface InterpretContext {
  splitName: string;
  availableDayTypes: string[];
  todayDayName: string;
  exercises: { id?: string; workoutExerciseId?: string; name: string; muscleGroup: string }[];
}

export interface InterpretResult {
  intent: "override_day" | "swap_exercise" | "add_exercise" | "remove_exercise" | "lighter_intensity" | "question" | "change_plan" | "unrecognized";
  dayType?: string;
  exerciseName?: string;
  replacementExercise?: string;
  targetSets?: number;
  reason?: string;
  proposedDays?: number;       // for change_plan: day count extracted (null = keep current)
  proposedSplitName?: string; // for change_plan: split name mentioned (null = recommend by days)
  reply: string;
}

export async function interpretSessionRequest(
  message: string,
  context: InterpretContext
): Promise<InterpretResult> {
  const countReductionMatch = message.match(/(?:make|reduce|limit|set|cut|just|too much)\s*(?:it|today|session)?\s*(?:to|for|is)?\s*(\d+)\s*(?:ex|exs|exercise|exercises)/i)
    || (message.toLowerCase().includes("too much") && message.match(/(\d+)\s*(?:ex|exs|exercise|exercises)/i));

  if (countReductionMatch && !message.toLowerCase().includes("add") && !message.toLowerCase().includes("swap")) {
    const targetNum = parseInt(countReductionMatch[1], 10);
    if (targetNum > 0 && targetNum <= 15) {
      return {
        intent: "lighter_intensity",
        reply: `Got it! Trimming today's session to your top ${targetNum} main exercises.`,
      };
    }
  }

  const systemPrompt = `You are an expert AI fitness coach & workout session controller. Classify user message into 1 of 8 intents:
1. "add_exercise": user wants to add a new exercise to today's workout (e.g., "add 3 sets of incline dumbbell curls"). Extract "exerciseName" and "targetSets" (default 3 if omitted).
2. "remove_exercise": user wants to remove an exercise from today's workout (e.g., "remove leg press", "delete cable flyes"). Extract "exerciseName".
3. "swap_exercise": user wants to replace an exercise or body part today (e.g., "swap bench press for dumbbell press", "replace leg curl"). Extract "exerciseName" (the target exercise to replace) and "replacementExercise" (the specific replacement requested or recommended).
4. "override_day": change/skip today's split day. "dayType" in [${availableDaysStr}] or "skip".
5. "lighter_intensity": request easier/lighter session, reduce volume, or limit exercise count (e.g., "too much for me", "make it 5 exercises", "reduce to 4 exercises", "make it lighter").
6. "question": coaching/training question (exercise, form, recovery, general fitness).
7. "change_plan": switch entire training split going forward (e.g. "switch to Upper/Lower", "Arnold split", "3 days a week"). Extract "proposedSplitName" if split name mentioned, and "proposedDays" (number) if days mentioned.
8. "unrecognized": ambiguous, incoherent, or off-topic.

Respond ONLY with JSON:
{
  "intent": "add_exercise" | "remove_exercise" | "swap_exercise" | "override_day" | "lighter_intensity" | "question" | "change_plan" | "unrecognized",
  "dayType": string | null,
  "exerciseName": string | null,
  "replacementExercise": string | null,
  "targetSets": number | null,
  "proposedDays": number | null,
  "proposedSplitName": string | null,
  "reason": string | null,
  "reply": "Short natural confirmation line or answer (1-2 sentences)."
}`;

  const userPrompt = `Routine: ${context.splitName}. Today: ${context.todayDayName}. Exercises: ${currentExercisesStr}. Message: "${message}"`;

  const fallback: InterpretResult = {
    intent: "unrecognized",
    reply: "I wasn't sure what you meant by that — try asking to add, swap, or remove an exercise, or change your routine split.",
  };

  const detailedRes = await callOllamaJsonChatDetailed<InterpretResult>(
    systemPrompt,
    userPrompt,
    fallback,
    { callerName: "interpretSessionRequest", timeoutMs: 25000, numPredict: 140 }
  );

  if (detailedRes.source === "timeout" || detailedRes.source === "error") {
    console.warn(`⏱️ [Ollama] interpretSessionRequest failed/timed out after ${detailedRes.elapsedMs}ms (${detailedRes.evalCount ?? 0} tokens, source: ${detailedRes.source})`);
    return {
      intent: "unrecognized",
      reply: "Still thinking that one over — mind trying again in a second?",
    };
  }

  const res = detailedRes.value;
  console.log(`⏱️ [Ollama] interpretSessionRequest finished in ${detailedRes.elapsedMs}ms (${detailedRes.evalCount ?? 0} tokens generated, source: ${detailedRes.source}, intent: ${res.intent})`);

  if (!res.intent || !["add_exercise", "remove_exercise", "override_day", "swap_exercise", "lighter_intensity", "question", "change_plan", "unrecognized"].includes(res.intent)) {
    return fallback;
  }

  if (!res.reply || typeof res.reply !== "string" || !res.reply.trim()) {
    res.reply = fallback.reply;
  }

  return res;
}

// ── 9. Weekly AI Recap Coach Note ────────────────────────────

export interface WeeklyRecapSummaryInput {
  splitName: string;
  completedDaysCount: number;
  missedDaysCount: number;
  restDaysCount: number;
  streakDays: number;
  prsAchieved: string[];
}

export async function generateWeeklyRecapNote(summary: WeeklyRecapSummaryInput): Promise<string> {
  const prsText = summary.prsAchieved.length > 0
    ? `PRs smashed: ${summary.prsAchieved.join(", ")}.`
    : "No new PRs set this week, but consistency was maintained.";

  const systemPrompt = `You are an elite, supportive strength coach writing a weekly workout recap. Produce ONE short paragraph (3-4 sentences max, maximum 60 words total). Summarize what got done, constructively mention missed days if any (no guilt-tripping), and provide 1 concrete focus for next week. Speak directly to the user. No markdown, no quotes.`;

  const userPrompt = `Routine: ${summary.splitName}. Week stats: ${summary.completedDaysCount} sessions completed, ${summary.missedDaysCount} missed, ${summary.restDaysCount} rest/skipped days. Streak: ${summary.streakDays} days. ${prsText} Write the weekly recap paragraph.`;

  const fallback = summary.completedDaysCount > 0
    ? `Solid effort this past week with ${summary.completedDaysCount} completed workout sessions! ${summary.prsAchieved.length > 0 ? `You achieved great progress on ${summary.prsAchieved[0]}.` : "You maintained consistent execution across your routine."} For next week, focus on progressive overload and hitting all scheduled sessions cleanly.`
    : `Your routine is ready for a fresh start. Focus on locking in your first scheduled workout session this upcoming week to build momentum!`;

  return callOllamaChat(systemPrompt, userPrompt, fallback, { callerName: "generateWeeklyRecapNote" });
}

// ── 10. AI Exercise Alternatives Generator ───────────────────

export interface ExerciseAlternativeSuggestion {
  name: string;
  reason: string;
  muscleGroup: string;
}

export async function generateExerciseAlternatives(exercise: {
  name: string;
  muscleGroup: string;
}): Promise<ExerciseAlternativeSuggestion[]> {
  const systemPrompt = `You are a certified strength coach. Given an exercise name and its target muscle group, suggest 2-3 alternative exercises that train the same primary muscle group using different equipment or body positioning. Respond ONLY with this exact JSON schema:
{
  "alternatives": [
    { "name": "Exercise Name", "reason": "One short sentence why this is a good swap.", "muscleGroup": "same muscle group" }
  ]
}
Produce exactly 2 to 3 entries. No markdown, no extra keys.`;

  const userPrompt = `Exercise: ${exercise.name}. Muscle group: ${exercise.muscleGroup}. Suggest 2-3 gym-practical alternatives.`;

  const fallback: { alternatives: ExerciseAlternativeSuggestion[] } = {
    alternatives: [
      { name: `${exercise.muscleGroup} Machine Press`, reason: `Machine variation for ${exercise.muscleGroup} with guided path and reduced stabilizer demand.`, muscleGroup: exercise.muscleGroup },
      { name: `${exercise.muscleGroup} Cable Fly`, reason: `Cable variation provides constant tension through the full range of motion.`, muscleGroup: exercise.muscleGroup },
    ],
  };

  const result = await callOllamaJsonChat<{ alternatives: ExerciseAlternativeSuggestion[] }>(
    systemPrompt,
    userPrompt,
    fallback,
    { callerName: "generateExerciseAlternatives", timeoutMs: 10000 }
  );

  const list = result?.alternatives;
  if (!Array.isArray(list) || list.length === 0) return fallback.alternatives;
  return list.slice(0, 3).filter(
    (a) => typeof a.name === "string" && a.name.trim().length > 0
  );
}

// ── 11. AI Session Exercise Recommendations Generator ────────

export interface ExerciseRecommendation {
  name: string;
  reason: string;
  muscleGroup: string;
}

export async function generateSessionRecommendations(input: {
  splitName: string;
  todayDayName: string;
  exercises: string[];
}): Promise<ExerciseRecommendation[]> {
  const currentStr = input.exercises.join(", ");
  const systemPrompt = `You are a world-class strength & conditioning coach. Analyze the user's workout session for today and suggest 3-4 complementary exercise additions that fill missing muscle groups or provide ideal accessory work.

Respond ONLY with this exact JSON schema:
{
  "recommendations": [
    { "name": "Exercise Name", "reason": "One concise sentence explaining why this is a great addition.", "muscleGroup": "Target Muscle Group" }
  ]
}
Produce exactly 3 to 4 recommendations. No markdown formatting, no intro text.`;

  const userPrompt = `Routine: ${input.splitName}. Day: ${input.todayDayName}. Current exercises in session: [${currentStr}]. Recommend 3-4 complementary exercise additions.`;

  const fallback = {
    recommendations: [
      { name: "Face Pulls", reason: "Adds essential rear delt and upper back posture balance.", muscleGroup: "Rear Delts" },
      { name: "Cable Flyes", reason: "Isolates chest with continuous cable tension.", muscleGroup: "Chest" },
      { name: "Standing Calf Raises", reason: "Builds lower leg volume and ankle stability.", muscleGroup: "Calves" },
      { name: "Hanging Leg Raises", reason: "Strengthens lower abs and core stability.", muscleGroup: "Core" },
    ],
  };

  const result = await callOllamaJsonChat<{ recommendations: ExerciseRecommendation[] }>(
    systemPrompt,
    userPrompt,
    fallback,
    { callerName: "generateSessionRecommendations", timeoutMs: 10000 }
  );

  const list = result?.recommendations;
  if (!Array.isArray(list) || list.length === 0) return fallback.recommendations;
  return list.slice(0, 4).filter(
    (r) => typeof r.name === "string" && r.name.trim().length > 0
  );
}
