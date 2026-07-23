// ============================================================
//  src/services/coach.service.ts
//  Aura — Local Ollama AI Personal Coach Service
// ============================================================

import { OLLAMA_CONFIG } from "../config";interface ExerciseInput {
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
  } catch (err) {
    clearTimeout(timeoutId);
    return fallback;
  }
}

// ── Helper: Ollama Chat Call (JSON Mode) ───────────────────

async function callOllamaJsonChat<T>(systemPrompt: string, userPrompt: string, fallback: T): Promise<T> {
  const provider = process.env.AI_PROVIDER ?? "ollama";
  if (provider === "none") {
    return fallback;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4000);

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
          num_predict: 160,
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

    const parsed = JSON.parse(content) as T;
    return parsed || fallback;
  } catch (err) {
    clearTimeout(timeoutId);
    return fallback;
  }
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
  intent: "override_day" | "swap_exercise" | "lighter_intensity" | "unrecognized";
  dayType?: string;
  exerciseName?: string;
  reason?: string;
  confirmationMessage: string;
}

export async function interpretSessionRequest(
  message: string,
  context: InterpretContext
): Promise<InterpretResult> {
  const availableDaysStr = Array.from(new Set(context.availableDayTypes)).join(", ");
  const currentExercisesStr = context.exercises.map((e) => e.name).join(", ");

  const systemPrompt = `You are a natural-language workout session controller. Classify the user's message into ONE of these 4 intents:
1. "override_day": user wants to change or skip today's workout split day type. "dayType" MUST be one of: [${availableDaysStr}] or "skip".
2. "swap_exercise": user wants to replace an exercise or target a body part. "exerciseName" is the exercise or muscle group to replace.
3. "lighter_intensity": user is fatigued, sore, or asking to make today lighter/easier.
4. "unrecognized": fallback if request is ambiguous, gibberish, or not actionable.

Respond ONLY with a single JSON object. Schema:
{
  "intent": "override_day" | "swap_exercise" | "lighter_intensity" | "unrecognized",
  "dayType": string or null,
  "exerciseName": string or null,
  "reason": string or null,
  "confirmationMessage": "Short 1-sentence response explaining what action was performed or why unrecognized"
}`;

  const userPrompt = `Active routine: ${context.splitName}. Today's day: ${context.todayDayName}. Today's exercises: ${currentExercisesStr}. Available day types: ${availableDaysStr}. User message: "${message}"`;

  const fallback: InterpretResult = {
    intent: "unrecognized",
    confirmationMessage: "I wasn't sure what you meant by that — try naming a specific day type (e.g. Legs A) or exercise to swap.",
  };

  const res = await callOllamaJsonChat<InterpretResult>(systemPrompt, userPrompt, fallback);
  if (!res.intent || !["override_day", "swap_exercise", "lighter_intensity", "unrecognized"].includes(res.intent)) {
    return fallback;
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

  return callOllamaChat(systemPrompt, userPrompt, fallback);
}
