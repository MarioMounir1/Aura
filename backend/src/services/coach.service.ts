import { GoogleGenerativeAI } from "@google/generative-ai";
import { resolveGeminiModelName } from "../config";

function getGenAI(): GoogleGenerativeAI {
  const apiKey = process.env.GEMINI_API_KEY || "";
  return new GoogleGenerativeAI(apiKey);
}

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

// ── Helper: AI Chat Call with Gemini ──────────────────────────────────────

async function callOllamaChatDetailed(
  systemPrompt: string,
  userPrompt: string,
  fallback: string,
  options?: OllamaCallOptions
): Promise<OllamaResult<string>> {
  const callerName = options?.callerName ?? "callCoachChat";
  const startTime = Date.now();

  try {
    const modelName = resolveGeminiModelName();
    const model = getGenAI().getGenerativeModel({ model: modelName });
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
  const callerName = options?.callerName ?? "callCoachJsonChat";
  const startTime = Date.now();

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey.trim() === "") {
      console.warn(`⚠️ [Gemini Coach] GEMINI_API_KEY is not set in environment variables!`);
    }
    let modelName = resolveGeminiModelName();
    let model = getGenAI().getGenerativeModel({
      model: modelName,
      systemInstruction: systemPrompt,
    });
    const generationConfig = {
      responseMimeType: "application/json",
      temperature: 0.7,
    };
    let text = "";
    try {
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: userPrompt }] }],
        generationConfig,
      });
      text = result.response.text().trim();
    } catch (geminiErr: any) {
      console.warn(`⚠️ [Gemini Model Retry] ${modelName} failed (${geminiErr.message}), retrying with gemini-1.5-flash...`);
      model = getGenAI().getGenerativeModel({
        model: "gemini-1.5-flash",
        systemInstruction: systemPrompt,
      });
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: userPrompt }] }],
        generationConfig,
      });
      text = result.response.text().trim();
    }
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    const cleaned = jsonMatch ? jsonMatch[0] : text.replace(/```[a-z]*|```/g, "").replace(/^["']|["']$/g, "").trim();
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
  intent: "override_day" | "swap_exercise" | "add_exercise" | "remove_exercise" | "lighter_intensity" | "question" | "change_plan" | "setup_routine" | "chat" | "unrecognized";
  dayType?: string | null;
  exerciseName?: string | null;
  replacementExercise?: string | null;
  targetSets?: number | null;
  targetCount?: number | null;
  reason?: string | null;
  proposedDays?: number | null;
  proposedSplitName?: string | null;
  reply: string;
}

export function extractPlanInfoFromMessage(msg: string): { proposedDays: number | undefined; proposedSplitName: string | undefined } {
  const lower = msg.toLowerCase().trim();
  let proposedDays: number | undefined = undefined;
  let proposedSplitName: string | undefined = undefined;

  const numberWords: Record<string, number> = { three: 3, four: 4, five: 5, six: 6 };
  if (/^[3-6]$/.test(lower)) {
    proposedDays = parseInt(lower, 10);
  } else if (numberWords[lower]) {
    proposedDays = numberWords[lower];
  } else {
    const daysMatch = lower.match(/(\d+)\s*(?:days?|d|times?|x|\/wk|a week|per week|-day)?/i);
    if (daysMatch) {
      const parsed = parseInt(daysMatch[1], 10);
      if (parsed >= 3 && parsed <= 6) {
        proposedDays = parsed;
      }
    }
  }

  const isPpl = lower.includes("ppl") || lower.includes("push pull") || lower.includes("push/pull") || lower.includes("push leg");
  const isArnold = lower.includes("arnold") || lower.includes("aronld") || lower.includes("aronlod") || lower.includes("arnolod");

  if (isPpl && isArnold) {
    proposedSplitName = "PPL / Arnold Split";
    if (!proposedDays) proposedDays = 6;
  } else if (isArnold) {
    proposedSplitName = "Arnold Split";
    if (!proposedDays) proposedDays = 6;
  } else if (isPpl) {
    proposedSplitName = "Push / Pull / Legs";
  } else if (lower.includes("upper lower") || lower.includes("upper/lower") || lower.includes("upper & lower")) {
    proposedSplitName = "Upper / Lower Split";
    if (!proposedDays) proposedDays = 4;
  } else if (lower.includes("bro split") || lower.includes("bodypart")) {
    proposedSplitName = "Bro Split";
  } else if (lower.includes("full body") || lower.includes("fullbody")) {
    proposedSplitName = "Full Body Split";
    if (!proposedDays) proposedDays = 3;
  }

  return { proposedDays, proposedSplitName };
}

export async function interpretSessionRequest(
  message: string,
  context: InterpretContext
): Promise<InterpretResult> {
  const isFirstTimeSetup = !context.splitName || context.availableDayTypes.length === 0;

  // ── Fast-path plan change / setup shortcut ──────────────────
  const planInfo = extractPlanInfoFromMessage(message);
  if (planInfo.proposedDays !== undefined || planInfo.proposedSplitName !== undefined) {
    const targetIntent = isFirstTimeSetup ? "setup_routine" : "change_plan";
    const desc = planInfo.proposedSplitName
      ? `${planInfo.proposedSplitName}${planInfo.proposedDays ? ` (${planInfo.proposedDays} days/week)` : ""}`
      : `${planInfo.proposedDays} days per week`;
    return {
      intent: targetIntent,
      proposedDays: planInfo.proposedDays,
      proposedSplitName: planInfo.proposedSplitName,
      reply: `Got it! Setting your workout routine to ${desc}...`,
    };
  }

  // ── First-time onboarding path ─────────────────────────────
  if (isFirstTimeSetup) {
    const setupSystemPrompt = `You are a friendly AI fitness coach helping a brand-new user set up their first workout plan.
Your job is to collect two pieces of information: (1) how many days per week they want to train (3–6), and (2) which training split they prefer.
Available splits: Full Body Split (3d), Push/Pull/Legs (3d or 6d), Upper/Lower Split (4d), Bro Split 4-Day (4d), Hybrid PPL Split (5d), 5-Day Bodypart Split (5d), Arnold Split (6d).

Classify the user message into one of:
- "setup_routine": the user has provided enough info to configure a plan (days mentioned and/or split named). Extract "proposedDays" (integer 3–6) and "proposedSplitName" (closest matching split name, or null if not mentioned).
- "question": they are asking a general fitness question unrelated to setup.
- "unrecognized": greeting, vague, or totally off-topic — respond warmly and guide them to share their training frequency.

Respond ONLY with valid JSON:
{
  "intent": "setup_routine" | "question" | "unrecognized",
  "proposedDays": number | null,
  "proposedSplitName": string | null,
  "reply": "1–2 sentence friendly response."
}`;

    const setupUserPrompt = `New user message: "${message}"`;

    const setupFallback: InterpretResult = {
      intent: "unrecognized",
      reply: "I'm here to help you set up your training plan! How many days a week are you looking to train — 3, 4, 5, or 6?",
    };

    const setupRes = await callOllamaJsonChatDetailed<InterpretResult>(
      setupSystemPrompt,
      setupUserPrompt,
      setupFallback,
      { callerName: "interpretSessionRequest:setup", timeoutMs: 25000, numPredict: 140 }
    );

    if (setupRes.source === "timeout" || setupRes.source === "error") {
      return setupFallback;
    }

    const sr = setupRes.value;
    console.log(`⏱️ [Coach] setup intent: ${sr.intent}, days: ${sr.proposedDays}, split: ${sr.proposedSplitName}`);

    if (!sr.reply || typeof sr.reply !== "string" || !sr.reply.trim()) {
      sr.reply = setupFallback.reply;
    }
    if (!sr.intent || !["setup_routine", "question", "unrecognized"].includes(sr.intent)) {
      return setupFallback;
    }
    return sr;
  }

  // ── Gemini AI classification & dynamic response ──────────────
  const availableDaysStr = context.availableDayTypes.join(", ") || "(none)";
  const currentExercisesStr = context.exercises.map((e) => `${e.name} (${e.muscleGroup})`).join(", ") || "(none)";

  const systemPrompt = `You are Aura AI — a warm, friendly, highly intelligent AI Personal Fitness & Health Assistant powered by Google Gemini. You engage in open, natural conversation on ANY topic (fitness, workouts, health, recovery, general chat, questions, life).

Analyze the user's message and determine if they are asking to modify their workout, or simply chatting/asking a question:
1. "add_exercise": user wants to add an exercise (e.g. "add incline dumbbell press"). Extract "exerciseName" and "targetSets" (default 3).
2. "remove_exercise": user wants to remove an exercise (e.g. "remove leg press"). Extract "exerciseName".
3. "swap_exercise": user wants to replace an exercise (e.g. "swap bench press for incline press"). Extract "exerciseName" and "replacementExercise".
4. "override_day": change/skip today's split day. "dayType" in [${availableDaysStr}] or "skip".
5. "lighter_intensity": user wants fewer exercises, lower volume, or an easier session (e.g. "make it 5 exercises", "reduce exc to 5 only", "cut to 4"). Extract "targetCount" (number of exercises) or "targetSets".
6. "change_plan": switch training split going forward (e.g. "switch to Upper/Lower", "Arnold split", "4 days a week"). Extract "proposedSplitName" and "proposedDays".
7. "chat": any general conversation, question, greeting, or statement (e.g. "how are you", "what is protein", "tell me a joke", "I feel great").

Respond ONLY with valid JSON:
{
  "intent": "add_exercise" | "remove_exercise" | "swap_exercise" | "override_day" | "lighter_intensity" | "change_plan" | "chat",
  "dayType": string | null,
  "exerciseName": string | null,
  "replacementExercise": string | null,
  "targetSets": number | null,
  "targetCount": number | null,
  "proposedDays": number | null,
  "proposedSplitName": string | null,
  "reason": string | null,
  "reply": "Your natural, warm, intelligent AI response to the user's message. Answer any question, chat warmly, or confirm their workout change naturally."
}`;

  const userPrompt = `Routine: ${context.splitName}. Today: ${context.todayDayName}. Exercises: ${currentExercisesStr}. User Message: "${message}"`;

  const fallback: InterpretResult = {
    intent: "chat",
    reply: "I'm right here with you! What's on your mind today?",
  };

  const detailedRes = await callOllamaJsonChatDetailed<InterpretResult>(
    systemPrompt,
    userPrompt,
    fallback,
    { callerName: "interpretSessionRequest", timeoutMs: 25000, numPredict: 200 }
  );

  if (detailedRes.source === "timeout" || detailedRes.source === "error") {
    console.warn(`⏱️ [Coach AI Direct Fallback] generating direct Gemini AI chat response...`);
    
    try {
      const model = getGenAI().getGenerativeModel({ model: "gemini-2.5-flash-lite" });
      const promptText = `You are Aura AI, a warm and intelligent AI personal trainer. Answer this user message naturally: "${message}"`;
      const res = await model.generateContent(promptText);
      const text = res.response.text().trim();

      const numMatch = message.match(/(\d+)/);
      const isReduce = message.toLowerCase().includes("reduce") || message.toLowerCase().includes("exc") || message.toLowerCase().includes("exercise") || message.toLowerCase().includes("only") || message.toLowerCase().includes("make") || message.toLowerCase().includes("limit") || message.toLowerCase().includes("cut");
      const targetCount = (numMatch && isReduce) ? parseInt(numMatch[1], 10) : null;

      return {
        intent: targetCount ? "lighter_intensity" : "chat",
        targetCount,
        reply: text || "I'm right here with you! Ready to help with your workout or answer any questions.",
      };
    } catch (directErr) {
      const lower = message.toLowerCase().trim();
      const numMatch = message.match(/(\d+)/);
      const isReduce = lower.includes("reduce") || lower.includes("exc") || lower.includes("exercise") || lower.includes("only") || lower.includes("make") || lower.includes("limit") || lower.includes("cut");
      const targetCount = (numMatch && isReduce) ? parseInt(numMatch[1], 10) : null;

      let replyText = "I'm right here with you! Tell me what's on your mind — whether you want to adjust today's workout, ask a fitness question, or switch your routine.";

      if (targetCount) {
        replyText = `Got it! Adjusted today's workout to focus on your top ${targetCount} main exercises.`;
      } else if (lower.includes("name")) {
        replyText = "I'm Aura AI — your intelligent personal fitness coach & health companion!";
      } else if (lower.includes("how are you") || lower.includes("how r u") || lower.includes("how's it going")) {
        replyText = "I'm feeling great and ready to crush today's training session with you! How are you feeling today?";
      } else if (lower.includes("who are you") || lower.includes("what are you")) {
        replyText = "I'm your intelligent AI fitness coach. I can adjust your workout routine, answer fitness & nutrition questions, and guide your training!";
      } else if (lower.includes("protein") || lower.includes("macro") || lower.includes("carbs") || lower.includes("fat") || lower.includes("diet")) {
        replyText = "For optimal muscle growth and recovery, aim for around 1.6–2.2g of protein per kg of bodyweight daily, paired with complex carbs around your workouts!";
      } else if (lower.includes("sore") || lower.includes("pain") || lower.includes("hurt") || lower.includes("fatigue") || lower.includes("tired")) {
        replyText = "If you're feeling overtrained or unusually sore, prioritize light movement, hydration, and extra sleep. Never push through sharp pain — rest is where muscle grows!";
      } else if (lower.includes("swap") || lower.includes("change") || lower.includes("replace")) {
        replyText = "You can swap any exercise by opening its details card or letting me know which exercise you'd like to replace!";
      } else if (lower.includes("cardio") || lower.includes("run") || lower.includes("treadmill")) {
        replyText = "Adding 15–20 minutes of moderate cardio after strength sessions is great for cardiovascular health without impairing muscle gains.";
      } else if (lower.includes("joke")) {
        replyText = "Why did the barbell go to college? To improve its bench strength!";
      } else if (lower === "hi" || lower === "hello" || lower === "hey" || lower.startsWith("hi ") || lower.startsWith("hello ")) {
        replyText = "Hey there! Ready to get after it today? Ask me any question or tell me how to adjust your session.";
      }

      return {
        intent: targetCount ? "lighter_intensity" : "chat",
        targetCount,
        reply: replyText,
      };
    }
  }

  const res = detailedRes.value;
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

export interface FormGuideResult {
  instructions: string;
  tips: string;
  commonMistakes: string;
}

export async function generateExerciseFormGuide(
  exerciseName: string,
  muscleGroup: string
): Promise<FormGuideResult> {
  const systemPrompt = `You are a certified master fitness coach and biomechanics expert. Generate a detailed, professional exercise form guide for "${exerciseName}" targeting "${muscleGroup}".
Respond ONLY with a valid JSON object matching this schema:
{
  "instructions": "4 numbered bullet steps covering setup, grip, movement path, and lockout.",
  "tips": "2-3 high-yield coaching cues for maximum target muscle activation and joint safety.",
  "commonMistakes": "2-3 critical form errors to avoid."
}`;

  const userPrompt = `Generate a form guide for ${exerciseName} (${muscleGroup}).`;

  const fallback: FormGuideResult = {
    instructions: `1. Set up with feet shoulder-width apart.\n2. Engage your core and keep your chest proud.\n3. Control the eccentric phase for 2-3 seconds.\n4. Drive powerfully through the full range of motion.`,
    tips: `• Squeeze the target muscle at peak contraction for 1 second.\n• Retract shoulder blades and maintain tension.`,
    commonMistakes: `• Arching lower back excessively.\n• Cutting range of motion short.\n• Rushing tempo without control.`,
  };

  const res = await callOllamaJsonChat<FormGuideResult>(
    systemPrompt,
    userPrompt,
    fallback,
    { callerName: "generateExerciseFormGuide", timeoutMs: 12000 }
  );

  return res ?? fallback;
}

// ── 15. Daily Ecosystem Holistic Briefing ────────────────────────

export interface DailyBriefingInput {
  userName?: string;
  calorieTarget: number;
  caloriesConsumedToday: number;
  proteinTarget: number;
  proteinConsumedToday: number;
  todaysWorkoutSplit?: string;
  streakDays: number;
  weightTrend?: string;
}

export interface DailyBriefingResult {
  headline: string;
  message: string;
  focusArea: string;
}

export async function generateDailyEcosystemBriefing(
  input: DailyBriefingInput
): Promise<DailyBriefingResult> {
  const remainingCals = Math.max(0, input.calorieTarget - input.caloriesConsumedToday);

  if (input.todaysWorkoutSplit && input.todaysWorkoutSplit !== "Rest Day") {
    return {
      headline: `${input.todaysWorkoutSplit} Day 🔥`,
      message: `Today's session is ${input.todaysWorkoutSplit}. Fuel up with clean energy and prioritize hitting your ${input.proteinTarget}g protein target!`,
      focusArea: "Strength & Power",
    };
  }

  if (input.streakDays >= 3) {
    return {
      headline: `${input.streakDays}-Day Streak Strong ⚡`,
      message: `Impressive consistency with ${input.streakDays} active days! Focus on nutrient-dense meals and clean hydration today.`,
      focusArea: "Active Recovery",
    };
  }

  if (input.caloriesConsumedToday > 0) {
    return {
      headline: `${remainingCals} kcal Remaining 🎯`,
      message: `You've logged ${input.caloriesConsumedToday} of ${input.calorieTarget} kcal today. Keep meals balanced to hit your daily target.`,
      focusArea: "Nutrition Balance",
    };
  }

  return {
    headline: "Daily Nutrition Focus 🎯",
    message: `Your daily target is ${input.calorieTarget} kcal and ${input.proteinTarget}g protein. Log your meals to track progress.`,
    focusArea: "Consistency",
  };
}

// ── 16. Weekly Insights Report ─────────────────────────────────

export interface WeeklyInsightsInput {
  totalCaloriesLogged: number;
  avgDailyCalories: number;
  calorieTarget: number;
  totalWorkouts: number;
  weightDeltaKg?: number;
  daysLoggedCount: number;
}

export interface WeeklyInsightsResult {
  consistencyScore: number;
  headline: string;
  summary: string;
  keyWin: string;
  nextWeekFocus: string;
}

export async function generateWeeklyInsightsReport(
  input: WeeklyInsightsInput
): Promise<WeeklyInsightsResult> {
  const consistencyScore = Math.min(100, Math.round((input.daysLoggedCount / 7) * 100));

  if (input.daysLoggedCount === 0 && input.totalWorkouts === 0) {
    return {
      consistencyScore: 0,
      headline: "Start Your Weekly Journey 🚀",
      summary: "Log your daily meals and workout sessions to track consistency and hit your goals.",
      keyWin: "Dashboard ready to record your progress",
      nextWeekFocus: "Log your first meal and workout today",
    };
  }

  if (consistencyScore >= 70) {
    return {
      consistencyScore,
      headline: "Phenomenal Consistency! 🏆",
      summary: `You logged ${input.daysLoggedCount} of 7 days and crushed ${input.totalWorkouts} workouts with ${input.avgDailyCalories} kcal daily average.`,
      keyWin: `${input.totalWorkouts} workout sessions completed`,
      nextWeekFocus: "Maintain this top-tier training and nutrition rhythm",
    };
  }

  return {
    consistencyScore,
    headline: "Building Weekly Momentum 📈",
    summary: `You logged ${input.daysLoggedCount} days this week with ${input.totalWorkouts} workouts completed.`,
    keyWin: `${input.daysLoggedCount} active tracking days`,
    nextWeekFocus: `Aim for ${Math.min(7, input.daysLoggedCount + 2)} logged days next week`,
  };
}
