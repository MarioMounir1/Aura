// ============================================================
//  src/controllers/workout.controller.ts
//  Aura — Workout Routine Setup & Session endpoints
//
//  POST /api/v1/workouts/setup   — save user's chosen split
//  GET  /api/v1/workouts/routine — get active routine + currentSession
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";
import { WorkoutService } from "../services/workout.service";
import { generateWorkoutCoachNote, generateExerciseCoachNote, generateRoutineRecommendationNote, generateSwapSuggestionNote, generateWorkoutSummaryNote, generateOvertrainingNote, interpretSessionRequest, generateWeeklyRecapNote, generateExerciseAlternatives, generateSessionRecommendations, generateExerciseFormGuide } from "../services/coach.service";

// ── Types ──────────────────────────────────────────────────

interface SessionExercise {
  id?: string;
  workoutExerciseId?: string;
  name: string;
  targetSets: number;
  muscleGroup: string;
  videoUrl?: string | null;
  thumbnailUrl?: string | null;
  instructions?: string | null;
  tips?: string | null;
  commonMistakes?: string | null;
  lastWeekWeight?: number | null;
  lastWeekReps?: number | null;
  isPlateaued?: boolean;
  coachNote?: string;
}

interface CurrentSession {
  routineName: string;
  todayDayName: string;
  exercises: SessionExercise[];
  isSkipped?: boolean;
  isOverridden?: boolean;
  isTodayCompleted?: boolean;
  coachNote?: string;
  topHistoricalSet: {
    exerciseName: string;
    weight: number;
    reps: number;
    progressionDelta: string;
  } | null;
}

// ── Zod Schemas ────────────────────────────────────────────

const SetupSchema = z.object({
  daysPerWeek: z.number().int().min(3).max(6),
  splitType:   z.string().min(1).max(80),
  splitName:   z.string().min(1).max(120),
});

const StartSessionSchema = z.object({ 
  name: z.string().min(1),
  exercises: z.array(z.object({
    id: z.string().nullish(), // Exercise DB id
    name: z.string(),
    targetSets: z.number().int(),
    muscleGroup: z.string().nullish(),
    lastWeekWeight: z.number().nullish(),
    lastWeekReps: z.number().nullish()
  })).nullish()
});
const AddExerciseSchema = z.object({ sessionId: z.string(), exerciseId: z.string(), order: z.number().int(), notes: z.string().optional() });
const LogSetSchema = z.object({ workoutExerciseId: z.string(), setNumber: z.number().int(), reps: z.number().int().optional(), weightKg: z.number().optional(), rpe: z.number().optional() });

// ── Static exercise catalogue per day type (7-8 Exercises Per Session) ──
const DAY_EXERCISES: Record<string, SessionExercise[]> = {
  "Push": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest · Triceps", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Incline Dumbbell Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 32, lastWeekReps: 10 },
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Front Delts", lastWeekWeight: 55, lastWeekReps: 8 },
    { name: "Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Cable Chest Flyes", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 20, lastWeekReps: 12 },
    { name: "Dips", targetSets: 3, muscleGroup: "Triceps · Chest", lastWeekWeight: 0, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 12 },
    { name: "Overhead Rope Tricep Extension", targetSets: 3, muscleGroup: "Long Head Triceps", lastWeekWeight: 25, lastWeekReps: 12 },
  ],
  "Push A": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest · Triceps", lastWeekWeight: 80, lastWeekReps: 5 },
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 55, lastWeekReps: 8 },
    { name: "Incline Dumbbell Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 30, lastWeekReps: 10 },
    { name: "Dumbbell Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Pec Deck Flyes", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 45, lastWeekReps: 12 },
    { name: "Dips", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 0, lastWeekReps: 12 },
    { name: "Skull Crushers", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 30, lastWeekReps: 10 },
    { name: "Cable Single-Arm Tricep Extension", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 12, lastWeekReps: 15 },
  ],
  "Push B": [
    { name: "Dumbbell Bench Press", targetSets: 3, muscleGroup: "Chest · Triceps", lastWeekWeight: 36, lastWeekReps: 10 },
    { name: "Arnold Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 24, lastWeekReps: 10 },
    { name: "Incline Barbell Bench Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 65, lastWeekReps: 8 },
    { name: "Standing Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Cable Lower-Chest Crossovers", targetSets: 3, muscleGroup: "Lower Chest", lastWeekWeight: 18, lastWeekReps: 15 },
    { name: "Close-Grip Bench Press", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 60, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 12 },
    { name: "Seated Dumbbell Overhead Extension", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 28, lastWeekReps: 12 },
  ],
  "Pull": [
    { name: "Pull-Ups", targetSets: 3, muscleGroup: "Back · Biceps", lastWeekWeight: 0, lastWeekReps: 10 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 75, lastWeekReps: 8 },
    { name: "Lat Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 70, lastWeekReps: 10 },
    { name: "Seated Cable Row", targetSets: 3, muscleGroup: "Lower Back · Lats", lastWeekWeight: 65, lastWeekReps: 12 },
    { name: "Face Pulls", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 20, lastWeekReps: 15 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 40, lastWeekReps: 10 },
    { name: "Dumbbell Hammer Curl", targetSets: 3, muscleGroup: "Brachialis", lastWeekWeight: 18, lastWeekReps: 12 },
    { name: "Preacher Curl", targetSets: 3, muscleGroup: "Short Head Biceps", lastWeekWeight: 30, lastWeekReps: 12 },
  ],
  "Pull A": [
    { name: "Weighted Pull-Ups", targetSets: 3, muscleGroup: "Back · Biceps", lastWeekWeight: 20, lastWeekReps: 6 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Wide-Grip Lat Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 75, lastWeekReps: 10 },
    { name: "Cable Row", targetSets: 3, muscleGroup: "Lower Back", lastWeekWeight: 65, lastWeekReps: 12 },
    { name: "Rear Delt Dumbbell Flyes", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Incline Dumbbell Curl", targetSets: 3, muscleGroup: "Long Head Biceps", lastWeekWeight: 16, lastWeekReps: 12 },
    { name: "Cable Rope Bicep Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 25, lastWeekReps: 12 },
    { name: "Reverse Barbell Wrist Curl", targetSets: 3, muscleGroup: "Forearms", lastWeekWeight: 20, lastWeekReps: 15 },
  ],
  "Pull B": [
    { name: "Lat Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 70, lastWeekReps: 10 },
    { name: "Single-Arm Dumbbell Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 32, lastWeekReps: 10 },
    { name: "Cable Row", targetSets: 3, muscleGroup: "Lower Back", lastWeekWeight: 65, lastWeekReps: 12 },
    { name: "Straight-Arm Cable Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 30, lastWeekReps: 15 },
    { name: "Face Pulls", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 22, lastWeekReps: 15 },
    { name: "Hammer Curl", targetSets: 3, muscleGroup: "Brachialis", lastWeekWeight: 20, lastWeekReps: 12 },
    { name: "EZ-Bar Spider Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 28, lastWeekReps: 12 },
    { name: "Barbell Shrugs", targetSets: 3, muscleGroup: "Traps", lastWeekWeight: 90, lastWeekReps: 12 },
  ],
  "Legs": [
    { name: "Hack Squats", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 180, lastWeekReps: 6 },
    { name: "Smith Squats", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 100, lastWeekReps: 10 },
    { name: "Leg Press", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 200, lastWeekReps: 12 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 90, lastWeekReps: 10 },
    { name: "Lying Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 50, lastWeekReps: 12 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 65, lastWeekReps: 15 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 120, lastWeekReps: 15 },
    { name: "Bulgarian Split Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 20, lastWeekReps: 10 },
  ],
  "Legs A": [
    { name: "Back Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 110, lastWeekReps: 5 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 90, lastWeekReps: 8 },
    { name: "Leg Press", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 200, lastWeekReps: 12 },
    { name: "Lying Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 50, lastWeekReps: 12 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 70, lastWeekReps: 15 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 110, lastWeekReps: 15 },
    { name: "Seated Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 55, lastWeekReps: 15 },
    { name: "Dumbbell Walking Lunges", targetSets: 3, muscleGroup: "Glutes · Quads", lastWeekWeight: 18, lastWeekReps: 12 },
  ],
  "Legs B": [
    { name: "Front Squat", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Hack Squats", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 160, lastWeekReps: 8 },
    { name: "Stiff-Leg Deadlift", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 80, lastWeekReps: 10 },
    { name: "Bulgarian Split Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 24, lastWeekReps: 10 },
    { name: "Seated Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 55, lastWeekReps: 12 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 65, lastWeekReps: 15 },
    { name: "Seated Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 60, lastWeekReps: 15 },
    { name: "Hanging Leg Raises", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 0, lastWeekReps: 15 },
  ],
  "Upper": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 75, lastWeekReps: 8 },
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 55, lastWeekReps: 8 },
    { name: "Incline Dumbbell Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 32, lastWeekReps: 10 },
    { name: "Lat Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 70, lastWeekReps: 10 },
    { name: "Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 42, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 38, lastWeekReps: 12 },
  ],
  "Upper (Heavy)": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 85, lastWeekReps: 5 },
    { name: "Weighted Pull-Ups", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 20, lastWeekReps: 6 },
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 60, lastWeekReps: 5 },
    { name: "Incline Barbell Bench Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 70, lastWeekReps: 8 },
    { name: "Seated Cable Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 75, lastWeekReps: 8 },
    { name: "Dumbbell Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 14, lastWeekReps: 12 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 45, lastWeekReps: 8 },
    { name: "Skull Crushers", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 8 },
  ],
  "Upper (Volume)": [
    { name: "Dumbbell Bench Press", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 36, lastWeekReps: 10 },
    { name: "Lat Pulldown", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 70, lastWeekReps: 12 },
    { name: "Dumbbell Shoulder Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 28, lastWeekReps: 12 },
    { name: "Cable Chest Flyes", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 18, lastWeekReps: 15 },
    { name: "Single-Arm Cable Row", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 25, lastWeekReps: 12 },
    { name: "Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Incline Dumbbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 16, lastWeekReps: 12 },
    { name: "Tricep Overhead Rope Extension", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 22, lastWeekReps: 15 },
  ],
  "Lower": [
    { name: "Back Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 100, lastWeekReps: 8 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 85, lastWeekReps: 8 },
    { name: "Leg Press", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 180, lastWeekReps: 12 },
    { name: "Lying Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 50, lastWeekReps: 12 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 65, lastWeekReps: 15 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 100, lastWeekReps: 15 },
    { name: "Bulgarian Split Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 20, lastWeekReps: 10 },
    { name: "Hanging Leg Raises", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 0, lastWeekReps: 15 },
  ],
  "Lower (Heavy)": [
    { name: "Back Squat", targetSets: 3, muscleGroup: "Quads · Glutes", lastWeekWeight: 110, lastWeekReps: 5 },
    { name: "Deadlift", targetSets: 3, muscleGroup: "Posterior Chain", lastWeekWeight: 140, lastWeekReps: 5 },
    { name: "Leg Press", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 200, lastWeekReps: 10 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 95, lastWeekReps: 8 },
    { name: "Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 55, lastWeekReps: 10 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 75, lastWeekReps: 12 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 120, lastWeekReps: 12 },
    { name: "Weighted Ab Wheel Rollouts", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 0, lastWeekReps: 12 },
  ],
  "Lower (Volume)": [
    { name: "Front Squat", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 75, lastWeekReps: 10 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 85, lastWeekReps: 10 },
    { name: "Hack Squats", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 140, lastWeekReps: 12 },
    { name: "Seated Leg Curl", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 50, lastWeekReps: 15 },
    { name: "Leg Extension", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 60, lastWeekReps: 15 },
    { name: "Seated Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 65, lastWeekReps: 15 },
    { name: "Dumbbell Walking Lunges", targetSets: 3, muscleGroup: "Glutes", lastWeekWeight: 16, lastWeekReps: 12 },
    { name: "Cable Crunch", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 35, lastWeekReps: 15 },
  ],
  "Chest": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 85, lastWeekReps: 5 },
    { name: "Incline Dumbbell Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 34, lastWeekReps: 10 },
    { name: "Dumbbell Bench Press", targetSets: 3, muscleGroup: "Mid Chest", lastWeekWeight: 32, lastWeekReps: 10 },
    { name: "Cable Flyes", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 20, lastWeekReps: 15 },
    { name: "Pec Deck Machine", targetSets: 3, muscleGroup: "Inner Chest", lastWeekWeight: 45, lastWeekReps: 12 },
    { name: "Dips", targetSets: 3, muscleGroup: "Lower Chest", lastWeekWeight: 0, lastWeekReps: 12 },
    { name: "Incline Cable Crossovers", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 16, lastWeekReps: 15 },
    { name: "Push-Ups", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 0, lastWeekReps: 20 },
  ],
  "Back": [
    { name: "Deadlift", targetSets: 3, muscleGroup: "Posterior Chain", lastWeekWeight: 140, lastWeekReps: 5 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Pull-Ups", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 0, lastWeekReps: 10 },
    { name: "Wide-Grip Lat Pulldown", targetSets: 3, muscleGroup: "Upper Back", lastWeekWeight: 70, lastWeekReps: 10 },
    { name: "Seated Cable Row", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 65, lastWeekReps: 12 },
    { name: "Face Pulls", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 22, lastWeekReps: 15 },
    { name: "Straight-Arm Cable Pulldown", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 28, lastWeekReps: 12 },
    { name: "Barbell Shrugs", targetSets: 3, muscleGroup: "Traps", lastWeekWeight: 95, lastWeekReps: 12 },
  ],
  "Shoulders": [
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Front Delts", lastWeekWeight: 60, lastWeekReps: 8 },
    { name: "Dumbbell Shoulder Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 28, lastWeekReps: 10 },
    { name: "Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Dumbbell Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Rear Delt Flyes", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 16, lastWeekReps: 15 },
    { name: "Face Pulls", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 22, lastWeekReps: 15 },
    { name: "Upright Row", targetSets: 3, muscleGroup: "Traps · Side Delts", lastWeekWeight: 45, lastWeekReps: 12 },
    { name: "Dumbbell Shrugs", targetSets: 3, muscleGroup: "Traps", lastWeekWeight: 32, lastWeekReps: 15 },
  ],
  "Arms + Abs": [
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 45, lastWeekReps: 8 },
    { name: "Skull Crushers", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 10 },
    { name: "Incline Dumbbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 18, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 38, lastWeekReps: 12 },
    { name: "Hammer Curl", targetSets: 3, muscleGroup: "Brachialis", lastWeekWeight: 22, lastWeekReps: 12 },
    { name: "Overhead Rope Tricep Extension", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 25, lastWeekReps: 12 },
    { name: "Cable Crunch", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 40, lastWeekReps: 15 },
    { name: "Hanging Leg Raises", targetSets: 3, muscleGroup: "Lower Abs", lastWeekWeight: 0, lastWeekReps: 15 },
  ],
  "Legs + Arms": [
    { name: "Back Squat", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 100, lastWeekReps: 8 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 85, lastWeekReps: 8 },
    { name: "Leg Press", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 180, lastWeekReps: 12 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 42, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 38, lastWeekReps: 12 },
    { name: "Hammer Curl", targetSets: 3, muscleGroup: "Brachialis", lastWeekWeight: 20, lastWeekReps: 12 },
    { name: "Skull Crushers", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 30, lastWeekReps: 10 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 100, lastWeekReps: 15 },
  ],
  "Chest + Back": [
    { name: "Barbell Bench Press", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 85, lastWeekReps: 6 },
    { name: "Weighted Pull-Ups", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 20, lastWeekReps: 8 },
    { name: "Incline Dumbbell Press", targetSets: 3, muscleGroup: "Upper Chest", lastWeekWeight: 70, lastWeekReps: 10 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Mid Back", lastWeekWeight: 75, lastWeekReps: 8 },
    { name: "Cable Flyes", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 20, lastWeekReps: 15 },
    { name: "Seated Cable Row", targetSets: 3, muscleGroup: "Lats", lastWeekWeight: 65, lastWeekReps: 12 },
    { name: "Dips", targetSets: 3, muscleGroup: "Lower Chest", lastWeekWeight: 0, lastWeekReps: 12 },
    { name: "Face Pulls", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 20, lastWeekReps: 15 },
  ],
  "Shoulders + Arms": [
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Front Delts", lastWeekWeight: 60, lastWeekReps: 8 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 45, lastWeekReps: 8 },
    { name: "Close-Grip Bench Press", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 65, lastWeekReps: 10 },
    { name: "Cable Lateral Raises", targetSets: 3, muscleGroup: "Side Delts", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Incline Dumbbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 16, lastWeekReps: 10 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 38, lastWeekReps: 12 },
    { name: "Rear Delt Flyes", targetSets: 3, muscleGroup: "Rear Delts", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Hammer Curl", targetSets: 3, muscleGroup: "Brachialis", lastWeekWeight: 20, lastWeekReps: 12 },
  ],
  "Full Body (Heavy)": [
    { name: "Back Squat", targetSets: 5, muscleGroup: "Quads", lastWeekWeight: 110, lastWeekReps: 5 },
    { name: "Barbell Bench Press", targetSets: 4, muscleGroup: "Chest", lastWeekWeight: 85, lastWeekReps: 5 },
    { name: "Deadlift", targetSets: 3, muscleGroup: "Posterior Chain", lastWeekWeight: 140, lastWeekReps: 3 },
    { name: "Overhead Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 60, lastWeekReps: 5 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 75, lastWeekReps: 6 },
    { name: "Barbell Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 40, lastWeekReps: 8 },
    { name: "Skull Crushers", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 8 },
    { name: "Standing Calf Raises", targetSets: 3, muscleGroup: "Calves", lastWeekWeight: 100, lastWeekReps: 12 },
  ],
  "Full Body (Moderate)": [
    { name: "Front Squat", targetSets: 4, muscleGroup: "Quads", lastWeekWeight: 80, lastWeekReps: 8 },
    { name: "Dumbbell Bench Press", targetSets: 4, muscleGroup: "Chest", lastWeekWeight: 36, lastWeekReps: 10 },
    { name: "Romanian Deadlifts", targetSets: 3, muscleGroup: "Hamstrings", lastWeekWeight: 90, lastWeekReps: 8 },
    { name: "Barbell Row", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 75, lastWeekReps: 8 },
    { name: "Cable Lateral Raises", targetSets: 4, muscleGroup: "Side Delts", lastWeekWeight: 12, lastWeekReps: 15 },
    { name: "Hammer Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 18, lastWeekReps: 12 },
    { name: "Tricep Pushdown", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 35, lastWeekReps: 12 },
    { name: "Hanging Leg Raises", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 0, lastWeekReps: 15 },
  ],
  "Full Body (Light)": [
    { name: "Goblet Squat", targetSets: 3, muscleGroup: "Quads", lastWeekWeight: 32, lastWeekReps: 12 },
    { name: "Push-Ups", targetSets: 3, muscleGroup: "Chest", lastWeekWeight: 0, lastWeekReps: 15 },
    { name: "Dumbbell Row", targetSets: 3, muscleGroup: "Back", lastWeekWeight: 28, lastWeekReps: 12 },
    { name: "Lunges", targetSets: 3, muscleGroup: "Glutes", lastWeekWeight: 20, lastWeekReps: 12 },
    { name: "Dumbbell Shoulder Press", targetSets: 3, muscleGroup: "Shoulders", lastWeekWeight: 22, lastWeekReps: 12 },
    { name: "Dumbbell Bicep Curl", targetSets: 3, muscleGroup: "Biceps", lastWeekWeight: 14, lastWeekReps: 15 },
    { name: "Bench Dips", targetSets: 3, muscleGroup: "Triceps", lastWeekWeight: 0, lastWeekReps: 15 },
    { name: "Plank", targetSets: 3, muscleGroup: "Core", lastWeekWeight: 0, lastWeekReps: 60 },
  ],
  "Rest": [],
};

// ── Static routine catalogue ───────────────────────────────
const ROUTINE_CATALOGUE: Record<string, { description: string; days: string[] }> = {
  full_body:    { description: "3 full-body sessions — all major muscle groups each day", days: ["Full Body (Heavy)", "Rest", "Full Body (Moderate)", "Rest", "Full Body (Light)", "Rest", "Rest"] },
  ppl_1x:      { description: "Classic PPL hit once per week — 3 dedicated sessions",    days: ["Push", "Pull", "Legs", "Rest", "Rest", "Rest", "Rest"] },
  upper_lower: { description: "Each muscle group 2× per week — optimal frequency",       days: ["Upper (Heavy)", "Lower (Heavy)", "Rest", "Upper (Volume)", "Lower (Volume)", "Rest", "Rest"] },
  bro_split:   { description: "One muscle group per day — high volume focus",             days: ["Chest", "Back", "Shoulders", "Legs + Arms", "Rest", "Rest", "Rest"] },
  ul_ppl:      { description: "Hybrid 5-day — upper/lower + push/pull/legs",             days: ["Upper", "Lower", "Push", "Pull", "Legs", "Rest", "Rest"] },
  bro_split_5: { description: "Full coverage — arms get dedicated session",               days: ["Chest", "Back", "Shoulders", "Legs", "Arms + Abs", "Rest", "Rest"] },
  ppl_2x:      { description: "Each muscle group 2× per week — king of hypertrophy",    days: ["Push A", "Pull A", "Legs A", "Rest", "Push B", "Pull B", "Legs B"] },
  arnold_split:{ description: "Arnold's 6-day blueprint — antagonist supersets",         days: ["Chest + Back", "Shoulders + Arms", "Legs", "Chest + Back", "Shoulders + Arms", "Legs", "Rest"] },
  ppl_arnold:  { description: "Hybrid 6-Day — 3 days Push/Pull/Legs + 3 days Arnold Split", days: ["Push", "Pull", "Legs", "Chest + Back", "Shoulders + Arms", "Legs", "Rest"] },
};

// Friendly display names for each splitType key
const ROUTINE_DISPLAY_NAMES: Record<string, string> = {
  full_body:    "Full Body Split",
  ppl_1x:       "Push / Pull / Legs",
  upper_lower:  "Upper / Lower Split",
  bro_split:    "Bro Split (4-Day)",
  ul_ppl:       "Hybrid PPL Split",
  bro_split_5:  "5-Day Bodypart Split",
  ppl_2x:       "Push / Pull / Legs (2×/wk)",
  arnold_split: "Arnold Split (6-Day)",
  ppl_arnold:   "PPL / Arnold Split",
};

// Number of active training days for each split
const SPLIT_DAY_COUNT: Record<string, number> = {
  full_body: 3, ppl_1x: 3, upper_lower: 4, bro_split: 4,
  ul_ppl: 5, bro_split_5: 5, ppl_2x: 6, arnold_split: 6, ppl_arnold: 6,
};

// Rank-1 recommendation per day count (deterministic, no Ollama needed)
const RANK1_BY_DAYS: Record<number, string> = { 3: "full_body", 4: "upper_lower", 5: "ul_ppl", 6: "ppl_2x" };

/**
 * Resolves a proposed plan change from AI-extracted fields.
 * Returns { splitType, splitName, daysPerWeek, description } or null if unresolvable.
 */
function resolveSplitForChangePlan(
  proposedSplitName: string | undefined | null,
  proposedDays: number | undefined | null,
  currentDays: number
): { splitType: string; splitName: string; daysPerWeek: number; description: string } | null {
  // 1. Split name mentioned → fuzzy-match against catalogue
  if (proposedSplitName) {
    const query = proposedSplitName.toLowerCase().replace(/[^a-z0-9 ]/g, "");

    // Direct check for hybrid PPL / Arnold requests
    if ((query.includes("ppl") || query.includes("push")) && (query.includes("arnold") || query.includes("aronld") || query.includes("aronlod"))) {
      return {
        splitType: "ppl_arnold",
        splitName: ROUTINE_DISPLAY_NAMES["ppl_arnold"],
        daysPerWeek: 6,
        description: ROUTINE_CATALOGUE["ppl_arnold"].description,
      };
    }

    const tokens = query.split(/\s+/).filter(Boolean);
    let bestKey: string | null = null;
    let bestScore = 0;
    for (const [key, meta] of Object.entries(ROUTINE_CATALOGUE)) {
      const displayName = (ROUTINE_DISPLAY_NAMES[key] ?? key).toLowerCase();
      const score = tokens.filter(t => displayName.includes(t) || key.includes(t)).length;
      if (score > bestScore) { bestScore = score; bestKey = key; }
    }
    if (bestKey && bestScore > 0) {
      const days = proposedDays ?? SPLIT_DAY_COUNT[bestKey] ?? currentDays;
      return {
        splitType: bestKey,
        splitName: ROUTINE_DISPLAY_NAMES[bestKey] ?? bestKey,
        daysPerWeek: days,
        description: ROUTINE_CATALOGUE[bestKey].description,
      };
    }
  }

  // 2. Only days mentioned → pick rank-1 for that day count
  const targetDays = proposedDays ?? null;
  if (targetDays && RANK1_BY_DAYS[targetDays]) {
    const key = RANK1_BY_DAYS[targetDays];
    return {
      splitType: key,
      splitName: ROUTINE_DISPLAY_NAMES[key] ?? key,
      daysPerWeek: targetDays,
      description: ROUTINE_CATALOGUE[key].description,
    };
  }

  return null;
}


// ── Fetch user's performance history for plateau detection ────
async function getRecentPerformanceTrend(
  userId: string,
  exerciseId: string,
  weeks: number = 3
): Promise<{ isPlateaued: boolean; history: { weight: number; reps: number; loggedAt: Date }[] }> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - weeks * 7);

  const completedSets = await prisma.exerciseSet.findMany({
    where: {
      workoutExercise: {
        exerciseId,
        session: {
          userId,
          endedAt: { not: null },
        },
      },
      isCompleted: true,
      createdAt: { gte: cutoffDate },
      weightKg: { not: null },
      reps: { not: null },
    },
    orderBy: { createdAt: "desc" },
    take: weeks,
  });

  const history = completedSets.map((s) => ({
    weight: s.weightKg!,
    reps: s.reps!,
    loggedAt: s.createdAt!,
  }));

  if (history.length < 3) {
    return { isPlateaued: false, history };
  }

  const [s1, s2, s3] = history;
  const isPlateaued = s1.weight <= s2.weight && s2.weight <= s3.weight && s1.reps <= s2.reps && s2.reps <= s3.reps;

  return { isPlateaued, history };
}

// ── Fetch Session Data with historical context & overrides ────
async function fetchSessionData(
  userId: string,
  splitType: string,
  splitName: string,
  dateStr?: string,
  configuredAt?: Date | null
): Promise<CurrentSession> {
  const meta = ROUTINE_CATALOGUE[splitType];
  const days = meta?.days ?? [];

  const targetDateStr = dateStr ?? new Date().toISOString().split("T")[0];

  const override = await prisma.sessionOverride.findUnique({
    where: {
      userId_date: {
        userId,
        date: targetDateStr,
      },
    },
  });

  const todayStart = new Date(targetDateStr + "T00:00:00Z");
  const todayEnd = new Date(targetDateStr + "T23:59:59Z");
  const completedToday = await prisma.workoutSession.findFirst({
    where: {
      userId,
      startedAt: { gte: todayStart, lte: todayEnd },
      endedAt: { not: null },
    },
  });
  const isTodayCompleted = !!completedToday;

  let todayDayName: string;
  let isOverridden = false;
  let isSkipped = false;

  if (override) {
    isOverridden = true;
    if (override.dayType === "skip") {
      isSkipped = true;
      todayDayName = "Skipped";
    } else {
      todayDayName = override.dayType;
    }
  } else if (configuredAt && days.length > 0) {
    const targetDate = new Date(targetDateStr + "T00:00:00Z");
    const configDateStr = configuredAt.toISOString().split("T")[0];
    const configDate = new Date(configDateStr + "T00:00:00Z");
    let diffDays = Math.max(0, Math.floor((targetDate.getTime() - configDate.getTime()) / 86400000));
    if (isTodayCompleted) {
      diffDays += 1;
    }
    todayDayName = days[diffDays % days.length] ?? "Rest";
  } else {
    const targetDate = new Date(targetDateStr + "T00:00:00Z");
    let todayIndex = (targetDate.getDay() + 6) % 7;
    if (isTodayCompleted) {
      todayIndex += 1;
    }
    todayDayName = days[todayIndex % days.length] ?? "Rest";
  }

  if (isSkipped) {
    return {
      routineName: splitName,
      todayDayName: "Skipped",
      exercises: [],
      isSkipped: true,
      isOverridden: true,
      isTodayCompleted: false,
      coachNote: "Today is marked as skipped. Focus on rest and recovery.",
      topHistoricalSet: null,
    };
  }

  const activeSession = await prisma.workoutSession.findFirst({
    where: { userId, endedAt: null },
    include: {
      exercises: {
        include: { exercise: true },
        orderBy: { order: "asc" },
      },
    },
  });

  let rawList: { name: string; targetSets: number; muscleGroup: string; dbId?: string }[] = [];

  if (activeSession && activeSession.exercises.length > 0) {
    rawList = activeSession.exercises.map((we) => ({
      name: we.exercise.name,
      targetSets: 3,
      muscleGroup: we.exercise.muscleGroup,
      dbId: we.exercise.id,
    }));
  } else {
    rawList = (DAY_EXERCISES[todayDayName] ?? []).map((e) => ({ ...e }));
  }

  const exercises = await Promise.all(
    rawList.map(async (ex) => {
      let dbEx = ex.dbId
        ? await prisma.exercise.findUnique({ where: { id: ex.dbId } })
        : await prisma.exercise.findFirst({ where: { name: { equals: ex.name, mode: "insensitive" } } });

      if (!dbEx) {
        console.warn(`⚠️ [Workout] Exercise "${ex.name}" has no matching DB Exercise record! Auto-creating DB record...`);
        try {
          dbEx = await prisma.exercise.create({
            data: {
              name: ex.name,
              muscleGroup: ex.muscleGroup,
              description: `Auto-seeded exercise record for ${ex.name}`,
            },
          });
        } catch (e) {
          dbEx = (await prisma.exercise.findFirst({ where: { name: { equals: ex.name, mode: "insensitive" } } })) ?? null;
        }
      }

      if (!dbEx) {
        return {
          name: ex.name,
          targetSets: ex.targetSets,
          muscleGroup: ex.muscleGroup,
          id: undefined,
          lastWeekWeight: undefined,
          lastWeekReps: undefined,
          isPlateaued: false,
        };
      }

      const trend = await getRecentPerformanceTrend(userId, dbEx.id, 3);
      const lastPerf = trend.history[0] ?? null;
      return {
        name: ex.name,
        targetSets: ex.targetSets,
        muscleGroup: ex.muscleGroup,
        id: dbEx.id,
        lastWeekWeight: lastPerf ? lastPerf.weight : null,
        lastWeekReps: lastPerf ? lastPerf.reps : null,
        isPlateaued: trend.isPlateaued,
      };
    })
  );

  const first = exercises[0];
  const topHistoricalSet = (first && first.lastWeekWeight && first.lastWeekReps)
    ? {
        exerciseName: first.name,
        weight: first.lastWeekWeight,
        reps: first.lastWeekReps,
        progressionDelta: "+2.5 kg",
      }
    : null;

  return {
    routineName: splitName,
    todayDayName,
    exercises,
    isSkipped: false,
    isOverridden,
    isTodayCompleted,
    coachNote: undefined,
    topHistoricalSet,
  };
}

// ── Attach Ollama Coach Notes (Only for full display rendering) ─
async function attachSessionCoachNotes(
  session: CurrentSession,
  splitName: string,
  streakDays?: number
): Promise<CurrentSession> {
  if (session.isSkipped) {
    const note = await generateWorkoutCoachNote({
      splitName,
      todayDayName: "Skipped",
      exercises: [],
      isSkipped: true,
      isOverridden: true,
      streakDays,
    });
    return { ...session, coachNote: note };
  }

  const exercisesWithCoachNotes = await Promise.all(
    session.exercises.map(async (ex) => {
      const coachNote = await generateExerciseCoachNote(ex);
      return {
        ...ex,
        coachNote,
      };
    })
  );

  const highFatigueRisk = (streakDays ?? 0) >= 3 && session.todayDayName !== "Rest" && !session.isSkipped;

  const sessionCoachNote = await generateWorkoutCoachNote({
    splitName,
    todayDayName: session.todayDayName,
    exercises: exercisesWithCoachNotes,
    isOverridden: session.isOverridden,
    isSkipped: false,
    streakDays,
    highFatigueRisk,
  });

  return {
    ...session,
    exercises: exercisesWithCoachNotes,
    coachNote: sessionCoachNote,
  };
}

// ── Build currentSession from configured date + routine ────
async function buildCurrentSession(
  userId: string,
  splitType: string,
  splitName: string,
  dateStr?: string,
  configuredAt?: Date | null,
  streakDays?: number
): Promise<CurrentSession> {
  const data = await fetchSessionData(userId, splitType, splitName, dateStr, configuredAt);
  return attachSessionCoachNotes(data, splitName, streakDays);
}

// ── POST /api/v1/workouts/setup ────────────────────────────

export async function setupWorkoutRoutine(req: Request, res: Response): Promise<void> {
  const parsed = SetupSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ success: false, error: "Validation failed", details: parsed.error.flatten().fieldErrors });
    return;
  }

  const { daysPerWeek, splitType, splitName } = parsed.data;
  const userId = req.user!.id;

  const meta = ROUTINE_CATALOGUE[splitType] ?? {
    description: `${daysPerWeek}-day custom split`,
    days: Array(daysPerWeek).fill("Training Day"),
  };

  try {
    const configuredAt = new Date();
    console.log(`⏳ [Workout] Setting up routine for user ${userId}: ${splitName} (${daysPerWeek}d/${splitType})`);
    await prisma.user.update({
      where: { id: userId },
      data: {
        workoutDays: daysPerWeek,
        workoutSplitType: splitType,
        workoutSplitName: splitName,
        workoutConfiguredAt: configuredAt,
      },
    });

    // Clear stale session overrides from today onward for a fresh plan baseline
    const todayStr = new Date().toISOString().split("T")[0];
    await prisma.sessionOverride.deleteMany({
      where: { userId, date: { gte: todayStr } },
    });

    console.log(`✅ [Workout] Routine setup by user ${userId}: ${splitName} (${daysPerWeek}d/${splitType})`);

    const currentSession = await buildCurrentSession(userId, splitType, splitName, undefined, configuredAt);

    res.status(200).json({
      success: true,
      data: {
        routine: {
          splitType,
          splitName,
          daysPerWeek,
          description: meta.description,
          weekSchedule: meta.days,
          configuredAt: configuredAt.toISOString(),
        },
        currentSession,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [Workout] setup error:", msg);
    res.status(500).json({ success: false, error: "Failed to save routine configuration." });
  }
}

// ── GET /api/v1/workouts/routine ───────────────────────────

export async function getWorkoutRoutine(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.age || !user.weightKg || !user.workoutSplitType || !user.workoutDays) {
      res.status(200).json({
        success: true,
        data: { routine: null, currentSession: null },
      });
      return;
    }

    const targetDateStr = (req.query.date as string) || new Date().toISOString().split("T")[0];
    const splitType = user.workoutSplitType;
    const splitName = user.workoutSplitName ?? user.workoutSplitType;
    const daysPerWeek = user.workoutDays;
    const meta = ROUTINE_CATALOGUE[splitType];

    // Compute workout streak ONLY from completed/finished sessions
    let streakDays = 0;
    const allSessions = await prisma.workoutSession.findMany({
      where: { userId, endedAt: { not: null } },
      select: { startedAt: true },
      orderBy: { startedAt: 'desc' },
    });

    if (allSessions.length > 0) {
      const sessionDates = new Set(
        allSessions.map((s) => new Date(s.startedAt).toISOString().split('T')[0])
      );
      
      let checkDate = new Date();
      checkDate.setHours(0, 0, 0, 0);
      let checkStr = checkDate.toISOString().split('T')[0];

      if (!sessionDates.has(checkStr)) {
        checkDate.setDate(checkDate.getDate() - 1);
        checkStr = checkDate.toISOString().split('T')[0];
      }

      while (sessionDates.has(checkStr)) {
        streakDays++;
        checkDate.setDate(checkDate.getDate() - 1);
        checkStr = checkDate.toISOString().split('T')[0];
      }
    }

    const currentSession = await buildCurrentSession(userId, splitType, splitName, targetDateStr, user.workoutConfiguredAt, streakDays);

    // Compute real weekly completion from DB (ONLY completed sessions with endedAt != null)
    const now = new Date(targetDateStr + "T12:00:00Z");
    const startOfWeek = new Date(now);
    const dayOfWeek = (now.getDay() + 6) % 7; // Mon = 0, Sun = 6
    startOfWeek.setDate(now.getDate() - dayOfWeek);
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    const startOfWeekStr = startOfWeek.toISOString().split("T")[0];
    const endOfWeekMinus1Str = new Date(endOfWeek.getTime() - 86400000).toISOString().split("T")[0];

    const [thisWeekSessions, weekOverrides] = await Promise.all([
      prisma.workoutSession.findMany({
        where: {
          userId,
          endedAt: { not: null },
          startedAt: {
            gte: startOfWeek,
            lt: endOfWeek,
          },
        },
        select: { startedAt: true },
      }),
      prisma.sessionOverride.findMany({
        where: {
          userId,
          date: {
            gte: startOfWeekStr,
            lte: endOfWeekMinus1Str,
          },
        },
      }),
    ]);

    const overrideMap = new Map(weekOverrides.map((o) => [o.date, o.dayType]));
    const completedDateStrs = new Set(
      thisWeekSessions.map((s) => new Date(s.startedAt).toISOString().split("T")[0])
    );

    const completedDaysThisWeek = [false, false, false, false, false, false, false];
    thisWeekSessions.forEach((session) => {
      const sessDay = (new Date(session.startedAt).getDay() + 6) % 7;
      if (sessDay >= 0 && sessDay < 7) {
        completedDaysThisWeek[sessDay] = true;
      }
    });

    const todayStr = targetDateStr;
    const dayNamesShort = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const daysArr = meta?.days ?? [];
    // Bug-fix: if workoutConfiguredAt is null, fall back to today so that
    // no day before today is ever flagged as isMissed for a brand-new plan.
    if (!user.workoutConfiguredAt) {
      console.warn(`⚠️ [Workout] workoutConfiguredAt is null for user ${userId} — defaulting isBeforePlan baseline to today to prevent false missed-day flags.`);
    }
    const configDateStr = user.workoutConfiguredAt
      ? user.workoutConfiguredAt.toISOString().split("T")[0]
      : targetDateStr;  // treat "configured right now" as the safe default

    const weekScheduleDetails = Array.from({ length: 7 }, (_, i) => {
      const d = new Date(startOfWeek);
      d.setDate(startOfWeek.getDate() + i);
      const dateStr = d.toISOString().split("T")[0];

      const overrideType = overrideMap.get(dateStr);
      let dayType: string;
      let isOverridden = false;
      let isSkipped = false;

      if (overrideType) {
        isOverridden = true;
        if (overrideType === "skip") {
          isSkipped = true;
          dayType = "skip";
        } else {
          dayType = overrideType;
        }
      } else {
        const configDate = new Date(configDateStr + "T00:00:00Z");
        const curDate = new Date(dateStr + "T00:00:00Z");
        const diffDays = Math.floor((curDate.getTime() - configDate.getTime()) / 86400000);
        dayType = diffDays >= 0 ? (daysArr[diffDays % daysArr.length] ?? "Rest") : "Rest";
      }

      // configDateStr is always set (falls back to today when DB field is null)
      const isBeforePlan = dateStr < configDateStr;
      const isRest = dayType === "Rest";
      const isCompleted = completedDateStrs.has(dateStr);
      const isToday = dateStr === todayStr;
      const isPast = dateStr < todayStr;
      const isFuture = dateStr > todayStr;
      const isMissed = isPast && !isBeforePlan && !isCompleted && !isRest && !isSkipped;

      return {
        dayName: dayNamesShort[i],
        dateStr,
        dayType,
        isBeforePlan,
        isRest,
        isSkipped,
        isOverridden,
        isCompleted,
        isMissed,
        isFuture,
        isToday,
      };
    });

    const uniqueTypes = Array.from(new Set(daysArr)).filter(t => t !== "Rest");
    const completedSessionNames = Array.from(completedDateStrs);
    const swapSuggestionNote = await generateSwapSuggestionNote({
      splitName,
      completedDaysThisWeek: completedSessionNames,
      availableOptions: uniqueTypes,
    });

    // Compute overtraining risk: compare actual consecutive completed days against split's max consecutive
    let splitMaxConsecutive = 0;
    let currentConsec = 0;
    for (const d of daysArr) {
      if (d !== "Rest") {
        currentConsec++;
        if (currentConsec > splitMaxConsecutive) splitMaxConsecutive = currentConsec;
      } else {
        currentConsec = 0;
      }
    }
    if (splitMaxConsecutive === 0) splitMaxConsecutive = 3;

    let actualConsecutive = 0;
    let tempConsecutive = 0;
    completedDaysThisWeek.forEach((done) => {
      if (done) {
        tempConsecutive++;
        if (tempConsecutive > actualConsecutive) actualConsecutive = tempConsecutive;
      } else {
        tempConsecutive = 0;
      }
    });

    const overtrainingRisk = actualConsecutive > splitMaxConsecutive || streakDays > (splitMaxConsecutive + 1);

    let overtrainingNote: string | null = null;
    if (overtrainingRisk) {
      overtrainingNote = await generateOvertrainingNote({
        consecutiveDays: Math.max(actualConsecutive, streakDays),
        splitMaxAllowed: splitMaxConsecutive,
      });
    }

    res.status(200).json({
      success: true,
      data: {
        routine: {
          splitType,
          splitName,
          daysPerWeek,
          description: meta.description,
          weekSchedule: meta.days,
          weekScheduleDetails,
          configuredAt: (user.workoutConfiguredAt ?? user.updatedAt).toISOString(),
          overtrainingRisk,
          overtrainingNote,
        },
        currentSession,
        streakDays,
        completedDaysThisWeek,
        swapSuggestionNote,
      },
    });
  } catch (err: unknown) {
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── GET /api/v1/workouts/exercises ─────────────────────────────
export async function getAvailableExercises(req: Request, res: Response): Promise<void> {
  try {
    const exercises = await prisma.exercise.findMany({
      select: { id: true, name: true, muscleGroup: true },
      orderBy: { name: 'asc' },
    });
    res.status(200).json({ success: true, data: exercises });
  } catch (err) {
    console.error("❌ [Workout] getAvailableExercises error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/start ────────────────────────────
export async function startSession(req: Request, res: Response): Promise<void> {
  try {
    const parsed = StartSessionSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: parsed.error.flatten() });
      return;
    }
    
    const userId = req.user!.id;
    const session = await WorkoutService.startWorkoutSession(userId, parsed.data.name, parsed.data.exercises ?? undefined);
    res.status(200).json({ success: true, data: session });
  } catch (err) {
    console.error("❌ [Workout] startSession error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/exercise ────────────────────────────
export async function addExercise(req: Request, res: Response): Promise<void> {
  try {
    const parsed = AddExerciseSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: parsed.error.flatten() });
      return;
    }
    
    const exercise = await WorkoutService.addExerciseToSession(
      parsed.data.sessionId, parsed.data.exerciseId, parsed.data.order, parsed.data.notes
    );
    res.status(200).json({ success: true, data: exercise });
  } catch (err) {
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/set ────────────────────────────
export async function logSet(req: Request, res: Response): Promise<void> {
  try {
    const parsed = LogSetSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: parsed.error.flatten() });
      return;
    }
    
    const set = await WorkoutService.logSet(
      parsed.data.workoutExerciseId, parsed.data.setNumber, parsed.data.reps, parsed.data.weightKg, parsed.data.rpe
    );
    res.status(200).json({ success: true, data: set });
  } catch (err) {
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/:id/finish ────────────────────────────
export async function finishSession(req: Request, res: Response): Promise<void> {
  try {
    const sessionId = req.params.id;
    const session = await WorkoutService.finishSession(sessionId, req.body.notes);

    // Fetch full session details with completed exercises and sets
    const fullSession = await prisma.workoutSession.findUnique({
      where: { id: sessionId },
      include: {
        exercises: {
          include: {
            exercise: true,
            sets: true,
          },
        },
      },
    });

    let prsAchieved: string[] = [];
    let exercisesLogged = 0;
    let totalSetsCompleted = 0;

    if (fullSession) {
      for (const we of fullSession.exercises) {
        const completedSets = we.sets.filter((s) => s.isCompleted && s.weightKg != null && s.reps != null);
        if (completedSets.length > 0) {
          exercisesLogged++;
          totalSetsCompleted += completedSets.length;

          // Find top set in this session
          completedSets.sort((a, b) => (b.weightKg! * b.reps!) - (a.weightKg! * a.reps!));
          const sessionTopSet = completedSets[0];

          // Check historical best set before this session
          const previousBest = await prisma.exerciseSet.findFirst({
            where: {
              isCompleted: true,
              weightKg: { not: null },
              reps: { not: null },
              workoutExercise: {
                exerciseId: we.exerciseId,
                sessionId: { not: sessionId },
                session: { userId: fullSession.userId },
              },
            },
            orderBy: [{ weightKg: "desc" }, { reps: "desc" }],
          });

          if (previousBest && previousBest.weightKg != null && previousBest.reps != null) {
            if (
              sessionTopSet.weightKg! > previousBest.weightKg ||
              (sessionTopSet.weightKg! === previousBest.weightKg && sessionTopSet.reps! > previousBest.reps)
            ) {
              prsAchieved.push(`${we.exercise.name}: ${sessionTopSet.weightKg}kg × ${sessionTopSet.reps} reps`);
            }
          } else if (sessionTopSet.weightKg! > 0) {
            // First time logging this exercise
            prsAchieved.push(`${we.exercise.name}: ${sessionTopSet.weightKg}kg × ${sessionTopSet.reps} reps`);
          }
        }
      }
    }

    const summaryNote = await generateWorkoutSummaryNote({
      sessionName: session.name || "Workout",
      exercisesLogged,
      totalSetsCompleted,
      prsAchieved,
    });

    res.status(200).json({
      success: true,
      data: {
        ...session,
        summaryNote,
        prsAchieved,
      },
    });
  } catch (err) {
    console.error("❌ [Workout] finishSession error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── In-memory alternatives cache (5-min TTL per exerciseId) ─
const _altCache = new Map<string, { data: { name: string; reason: string; muscleGroup: string }[]; expiresAt: number }>();
const ALT_CACHE_TTL_MS = 5 * 60 * 1000;

// ── GET /api/v1/workouts/exercises/:id/alternatives ────────────────
export async function getExerciseAlternatives(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  try {
    const exercise = await prisma.exercise.findUnique({ where: { id } });
    if (!exercise) {
      res.status(404).json({ success: false, error: "Exercise not found" });
      return;
    }

    // Check in-memory cache first
    const cached = _altCache.get(id);
    if (cached && Date.now() < cached.expiresAt) {
      console.log(`✅ [Workout] getExerciseAlternatives cache hit for exerciseId=${id}`);
      res.status(200).json({ success: true, data: cached.data, source: "cache" });
      return;
    }

    // Generate AI alternatives
    console.log(`🤖 [Workout] Generating AI alternatives for exercise: ${exercise.name} (${exercise.muscleGroup})`);
    const suggestions = await generateExerciseAlternatives({ name: exercise.name, muscleGroup: exercise.muscleGroup });
    const data = suggestions.map(s => ({ name: s.name, reason: s.reason, muscleGroup: s.muscleGroup }));

    // Store in cache
    _altCache.set(id, { data, expiresAt: Date.now() + ALT_CACHE_TTL_MS });

    res.status(200).json({ success: true, data, source: "ai" });
  } catch (err) {
    console.error("❌ [Workout] getExerciseAlternatives error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/swap ────────────────────────────
export async function swapSessionExercise(req: Request, res: Response): Promise<void> {
  const { workoutExerciseId, newExerciseId } = req.body;
  if (!workoutExerciseId || !newExerciseId) {
    res.status(400).json({ success: false, error: "Missing workoutExerciseId or newExerciseId" });
    return;
  }

  try {
    // 1. Perform Swap
    const updated = await prisma.workoutExercise.update({
      where: { id: workoutExerciseId },
      data: { exerciseId: newExerciseId },
      include: { exercise: true }
    });

    // 2. Clear any logged sets for this exercise log since the movement has changed
    await prisma.exerciseSet.deleteMany({
      where: { workoutExerciseId }
    });

    res.status(200).json({ success: true, data: updated });
  } catch (err) {
    console.error("❌ [Workout] swapSessionExercise error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── GET /api/v1/workouts/session/recommendations ──────────────────
export async function getSessionRecommendations(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.workoutSplitType) {
      res.status(400).json({ success: false, error: "No active routine found" });
      return;
    }
    const splitType = user.workoutSplitType;
    const splitName = user.workoutSplitName ?? user.workoutSplitType;
    const targetDateStr = new Date().toISOString().split("T")[0];

    const currentSession = await fetchSessionData(userId, splitType, splitName, targetDateStr, user.workoutConfiguredAt);
    const exerciseNames = currentSession.exercises.map((e) => e.name);

    const recommendations = await generateSessionRecommendations({
      splitName,
      todayDayName: currentSession.todayDayName,
      exercises: exerciseNames,
    });

    res.status(200).json({
      success: true,
      data: recommendations,
    });
  } catch (err) {
    console.error("❌ [Workout] getSessionRecommendations error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── POST /api/v1/workouts/session/override ────────────────────────
const OverrideSessionSchema = z.object({
  date: z.string().optional(), // YYYY-MM-DD
  dayType: z.string().min(1).max(80),
});

export async function overrideSessionType(req: Request, res: Response): Promise<void> {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const parsed = OverrideSessionSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid data", details: parsed.error.format() });
      return;
    }

    const targetDate = parsed.data.date ?? new Date().toISOString().split("T")[0];
    const dayType = parsed.data.dayType;

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      res.status(404).json({ success: false, error: "User not found" });
      return;
    }

    let splitType = "upper_lower";
    let splitName = "Upper / Lower Split";
    if (user.activityLevel === "sedentary") {
      splitType = "full_body";
      splitName = "Full Body Split";
    } else if (user.activityLevel === "lightly_active") {
      splitType = "ppl_1x";
      splitName = "Push / Pull / Legs";
    } else if (user.activityLevel === "moderate") {
      splitType = "upper_lower";
      splitName = "Upper / Lower Split";
    } else if (user.activityLevel === "very_active") {
      splitType = "ul_ppl";
      splitName = "Hybrid PPL Split";
    }

    await prisma.sessionOverride.upsert({
      where: { userId_date: { userId, date: targetDate } },
      update: { dayType },
      create: { userId, date: targetDate, dayType },
    });

    const currentSession = await buildCurrentSession(userId, splitType, splitName, targetDate);

    res.status(200).json({
      success: true,
      message: "Session type overridden successfully",
      data: {
        date: targetDate,
        dayType,
        currentSession,
      },
    });
  } catch (error) {
    console.error("❌ [Workout] overrideSessionType error:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── GET /api/v1/workouts/recommend ─────────────────────────────
export async function recommendWorkoutRoutine(req: Request, res: Response): Promise<void> {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const rawDays = parseInt(req.query.days as string, 10);
    const days = isNaN(rawDays) ? 4 : Math.min(Math.max(rawDays, 3), 6);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        trainingExperience: true,
        goal: true,
        activityLevel: true,
      },
    });

    const exp = (user?.trainingExperience ?? "new") as "new" | "consistent" | "experienced";
    const goal = (user?.goal ?? "maintain") as "lose" | "maintain" | "gain";

    interface SplitItem {
      name: string;
      splitType: string;
      tagline: string;
      breakdown: string[];
      reasonTag: string;
      rank: number;
    }

    let items: SplitItem[] = [];

    if (days === 3) {
      if (exp === "new") {
        items = [
          {
            name: "Full Body Split",
            splitType: "full_body",
            tagline: "3 full-body sessions — all major muscle groups each day",
            breakdown: ROUTINE_CATALOGUE["full_body"].days,
            reasonTag: "Best Fit: Optimal frequency for beginners",
            rank: 1,
          },
          {
            name: "Push / Pull / Legs",
            splitType: "ppl_1x",
            tagline: "Classic PPL hit once per week — 3 dedicated sessions",
            breakdown: ROUTINE_CATALOGUE["ppl_1x"].days,
            reasonTag: "Lower frequency per muscle group",
            rank: 2,
          },
        ];
      } else {
        items = [
          {
            name: "Push / Pull / Legs",
            splitType: "ppl_1x",
            tagline: "Classic PPL hit once per week — 3 dedicated sessions",
            breakdown: ROUTINE_CATALOGUE["ppl_1x"].days,
            reasonTag: "Best Fit: High per-session focus",
            rank: 1,
          },
          {
            name: "Full Body Split",
            splitType: "full_body",
            tagline: "3 full-body sessions — all major muscle groups each day",
            breakdown: ROUTINE_CATALOGUE["full_body"].days,
            reasonTag: "Higher per-session systemic fatigue",
            rank: 2,
          },
        ];
      }
    } else if (days === 4) {
      items = [
        {
          name: "Upper / Lower Split",
          splitType: "upper_lower",
          tagline: "Each muscle group 2× per week — optimal frequency",
          breakdown: ROUTINE_CATALOGUE["upper_lower"].days,
          reasonTag: "Best Fit: Balanced 2x weekly muscle frequency",
          rank: 1,
        },
        {
          name: "Bro Split (4-Day)",
          splitType: "bro_split",
          tagline: "One muscle group per day — high volume focus",
          breakdown: ROUTINE_CATALOGUE["bro_split"].days,
          reasonTag: "High volume — lower weekly frequency per muscle group",
          rank: 2,
        },
      ];
    } else if (days === 5) {
      items = [
        {
          name: "Hybrid PPL Split",
          splitType: "ul_ppl",
          tagline: "Hybrid 5-day — upper/lower + push/pull/legs",
          breakdown: ROUTINE_CATALOGUE["ul_ppl"].days,
          reasonTag: "Best Fit: Combines heavy strength & hypertrophy",
          rank: 1,
        },
        {
          name: "5-Day Bodypart Split",
          splitType: "bro_split_5",
          tagline: "Full coverage — arms get dedicated session",
          breakdown: ROUTINE_CATALOGUE["bro_split_5"].days,
          reasonTag: "High isolation volume — long recovery window",
          rank: 2,
        },
      ];
    } else if (days === 6) {
      if (exp === "experienced" && goal !== "lose") {
        items = [
          {
            name: "Arnold Split (6-Day)",
            splitType: "arnold_split",
            tagline: "Arnold's 6-day blueprint — antagonist supersets",
            breakdown: ROUTINE_CATALOGUE["arnold_split"].days,
            reasonTag: "Best Fit: Peak volume for experienced lifters",
            rank: 1,
          },
          {
            name: "Push / Pull / Legs (2x/wk)",
            splitType: "ppl_2x",
            tagline: "Each muscle group 2× per week — king of hypertrophy",
            breakdown: ROUTINE_CATALOGUE["ppl_2x"].days,
            reasonTag: "High frequency hypertrophy blueprint",
            rank: 2,
          },
        ];
      } else {
        items = [
          {
            name: "Push / Pull / Legs (2x/wk)",
            splitType: "ppl_2x",
            tagline: "Each muscle group 2× per week — king of hypertrophy",
            breakdown: ROUTINE_CATALOGUE["ppl_2x"].days,
            reasonTag: "Best Fit: Gold standard for 6-day hypertrophy & recovery",
            rank: 1,
          },
          {
            name: "Arnold Split (6-Day)",
            splitType: "arnold_split",
            tagline: "Arnold's 6-day blueprint — antagonist supersets",
            breakdown: ROUTINE_CATALOGUE["arnold_split"].days,
            reasonTag: "Extremely high volume — heavy recovery demand",
            rank: 2,
          },
        ];
      }
    }

    const top = items[0];
    const reasonNote = await generateRoutineRecommendationNote({
      days,
      trainingExperience: exp,
      goal,
      splitName: top.name,
    });

    const recommended = {
      ...top,
      reasonNote,
      reasonTag: "Best Fit for Your Profile",
    };

    const otherOptions = items.slice(1);

    res.status(200).json({
      success: true,
      data: {
        days,
        userProfile: { trainingExperience: exp, goal },
        recommended,
        otherOptions,
      },
    });
  } catch (error) {
    console.error("❌ [Workout] recommendWorkoutRoutine error:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── Interpret Natural Language Session Request ───────────────

export async function interpretWorkoutSessionRequest(req: Request, res: Response): Promise<void> {
  try {
    const { message } = req.body;
    if (!message || typeof message !== "string" || !message.trim()) {
      res.status(400).json({ success: false, error: "Message is required" });
      return;
    }

    const userId = req.user!.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      res.status(401).json({ success: false, error: "User not found." });
      return;
    }

    const targetDateStr = new Date().toISOString().split("T")[0];
    const isFirstTimeUser = !user.workoutSplitType;

    // ── First-time users: route to onboarding mode in interpretSessionRequest ──
    if (isFirstTimeUser) {
      const interpretation = await interpretSessionRequest(message.trim(), {
        splitName: "",
        availableDayTypes: [],
        todayDayName: "",
        exercises: [],
      });

      let actionExecuted = false;
      let confirmationMessage = interpretation.reply;

      if (interpretation.intent === "setup_routine") {
        const resolved = resolveSplitForChangePlan(
          interpretation.proposedSplitName ?? null,
          typeof interpretation.proposedDays === "number" ? interpretation.proposedDays : null,
          4 // default days when no current plan
        );

        if (resolved) {
          const configuredAt = new Date();
          await prisma.user.update({
            where: { id: userId },
            data: {
              workoutDays: resolved.daysPerWeek,
              workoutSplitType: resolved.splitType,
              workoutSplitName: resolved.splitName,
              workoutConfiguredAt: configuredAt,
            },
          });
          actionExecuted = true;
          confirmationMessage = interpretation.reply?.trim()
            || `Your routine is set to ${resolved.splitName} (${resolved.daysPerWeek} days/week). Let's get started — today's session is ready!`;

          const updatedSession = await fetchSessionData(userId, resolved.splitType, resolved.splitName, targetDateStr, configuredAt);
          res.status(200).json({
            success: true,
            data: {
              intent: "setup_routine",
              actionExecuted: true,
              confirmationMessage,
              currentSession: updatedSession,
            },
          });
          return;
        } else {
          // Couldn't resolve — ask for more info
          confirmationMessage = "I'd love to help you set up! Which routine would you prefer (e.g. Push/Pull/Legs, Upper/Lower) and how many days per week do you want to train?";
        }
      }

      // For question / unrecognized in first-time mode: return no session
      res.status(200).json({
        success: true,
        data: {
          intent: interpretation.intent,
          actionExecuted,
          confirmationMessage,
          currentSession: null,
        },
      });
      return;
    }

    // ── Existing-user path ───────────────────────────────────
    const splitType = user.workoutSplitType!;
    const splitName = user.workoutSplitName ?? user.workoutSplitType!;

    const currentSession = await fetchSessionData(userId, splitType, splitName, targetDateStr, user.workoutConfiguredAt);
    const meta = ROUTINE_CATALOGUE[splitType];
    const availableDayTypes = meta?.days ?? [];

    const interpretation = await interpretSessionRequest(message.trim(), {
      splitName,
      availableDayTypes,
      todayDayName: currentSession.todayDayName,
      exercises: currentSession.exercises,
    });

    let actionExecuted = false;
    let swappedFrom: string | undefined;
    let swappedTo: string | undefined;
    let activeSplitType = splitType;
    let activeSplitName = splitName;
    let activeConfiguredAt = user.workoutConfiguredAt;
    let confirmationMessage = interpretation.reply;

    if (interpretation.intent === "override_day" && interpretation.dayType) {
      const rawChosen = interpretation.dayType.trim();
      const chosenType = rawChosen.toLowerCase() === "skip" ? "skip" : rawChosen;
      await prisma.sessionOverride.upsert({
        where: { userId_date: { userId, date: targetDateStr } },
        update: { dayType: chosenType },
        create: { userId, date: targetDateStr, dayType: chosenType },
      });
      actionExecuted = true;
    } else if (interpretation.intent === "add_exercise" && interpretation.exerciseName) {
      const addName = interpretation.exerciseName.trim();
      const targetSets = interpretation.targetSets && interpretation.targetSets > 0 ? interpretation.targetSets : 3;

      let dbEx = await prisma.exercise.findFirst({
        where: { name: { equals: addName, mode: "insensitive" } },
      });
      if (!dbEx) {
        dbEx = await prisma.exercise.create({
          data: {
            name: addName,
            muscleGroup: "Accessories",
            description: `Auto-created exercise record for ${addName}`,
          },
        });
      }

      let activeSession = await prisma.workoutSession.findFirst({
        where: { userId, endedAt: null },
      });

      if (!activeSession) {
        activeSession = await prisma.workoutSession.create({
          data: {
            userId,
            name: currentSession.todayDayName,
            startedAt: new Date(),
          },
        });
        for (let i = 0; i < currentSession.exercises.length; i++) {
          const ex = currentSession.exercises[i];
          if (ex.id) {
            await prisma.workoutExercise.create({
              data: {
                sessionId: activeSession.id,
                exerciseId: ex.id,
                order: i + 1,
              },
            });
          }
        }
      }

      const existingCount = await prisma.workoutExercise.count({ where: { sessionId: activeSession.id } });
      await prisma.workoutExercise.create({
        data: {
          sessionId: activeSession.id,
          exerciseId: dbEx.id,
          order: existingCount + 1,
        },
      });

      actionExecuted = true;
      if (!confirmationMessage || confirmationMessage.includes("wasn't sure")) {
        confirmationMessage = `Added ${dbEx.name} (${targetSets} sets) to today's session.`;
      }
    } else if (interpretation.intent === "remove_exercise" && interpretation.exerciseName) {
      const remQuery = interpretation.exerciseName.trim().toLowerCase();
      let activeSession: any = await prisma.workoutSession.findFirst({
        where: { userId, endedAt: null },
        include: { exercises: { include: { exercise: true } } },
      });

      if (!activeSession) {
        const createdSess = await prisma.workoutSession.create({
          data: {
            userId,
            name: currentSession.todayDayName,
            startedAt: new Date(),
          },
        });
        for (let i = 0; i < currentSession.exercises.length; i++) {
          const ex = currentSession.exercises[i];
          if (ex.id) {
            await prisma.workoutExercise.create({
              data: {
                sessionId: createdSess.id,
                exerciseId: ex.id,
                order: i + 1,
              },
            });
          }
        }
        activeSession = await prisma.workoutSession.findFirst({
          where: { id: createdSess.id },
          include: { exercises: { include: { exercise: true } } },
        });
      }

      if (activeSession && activeSession.exercises.length > 0) {
        const targetWe = activeSession.exercises.find((we: any) =>
          we.exercise.name.toLowerCase().includes(remQuery)
        ) ?? activeSession.exercises[0];

        if (targetWe) {
          await prisma.exerciseSet.deleteMany({ where: { workoutExerciseId: targetWe.id } });
          await prisma.workoutExercise.delete({ where: { id: targetWe.id } });
          actionExecuted = true;
          if (!confirmationMessage || confirmationMessage.includes("wasn't sure")) {
            confirmationMessage = `Removed ${targetWe.exercise.name} from today's workout.`;
          }
        }
      }
    } else if (interpretation.intent === "swap_exercise") {
      const queryName = (interpretation.exerciseName ?? "").toLowerCase();
      const targetEx = currentSession.exercises.find(
        (e) => queryName && (e.name.toLowerCase().includes(queryName) || e.muscleGroup.toLowerCase().includes(queryName))
      ) ?? currentSession.exercises[0];

      if (targetEx && targetEx.id) {
        let altName: string | null = interpretation.replacementExercise ?? null;
        let altReason: string | null = interpretation.reason ?? null;

        if (!altName) {
          const cached = _altCache.get(targetEx.id);
          if (cached && Date.now() < cached.expiresAt && cached.data.length > 0) {
            altName = cached.data[0].name;
            altReason = cached.data[0].reason;
          } else {
            const suggestions = await generateExerciseAlternatives({ name: targetEx.name, muscleGroup: targetEx.muscleGroup });
            if (suggestions.length > 0) {
              const cacheData = suggestions.map(s => ({ name: s.name, reason: s.reason, muscleGroup: s.muscleGroup }));
              _altCache.set(targetEx.id, { data: cacheData, expiresAt: Date.now() + ALT_CACHE_TTL_MS });
              altName = suggestions[0].name;
              altReason = suggestions[0].reason;
            }
          }
        }

        let alt = altName ? await prisma.exercise.findFirst({ where: { name: { equals: altName, mode: "insensitive" } } }) : null;
        if (!alt && altName) {
          alt = await prisma.exercise.create({
            data: { name: altName, muscleGroup: targetEx.muscleGroup, description: `AI-suggested alternative for ${targetEx.name}` },
          });
        }
        if (!alt) {
          const fallbacks = await prisma.exercise.findMany({
            where: { muscleGroup: targetEx.muscleGroup, id: { not: targetEx.id } },
            take: 1,
          });
          if (fallbacks.length > 0) alt = fallbacks[0];
        }

        if (alt) {
          swappedFrom = targetEx.name;
          swappedTo = alt.name;

          let activeSession: any = await prisma.workoutSession.findFirst({
            where: { userId, endedAt: null },
            include: { exercises: true },
          });

          if (!activeSession) {
            const createdSess = await prisma.workoutSession.create({
              data: {
                userId,
                name: currentSession.todayDayName,
                startedAt: new Date(),
              },
            });
            for (let i = 0; i < currentSession.exercises.length; i++) {
              const ex = currentSession.exercises[i];
              if (ex.id) {
                await prisma.workoutExercise.create({
                  data: {
                    sessionId: createdSess.id,
                    exerciseId: ex.id,
                    order: i + 1,
                  },
                });
              }
            }
            activeSession = await prisma.workoutSession.findFirst({
              where: { id: createdSess.id },
              include: { exercises: true },
            });
          }

          if (activeSession) {
            const we = activeSession.exercises.find((e: any) => e.exerciseId === targetEx.id) ?? activeSession.exercises[0];
            if (we) {
              await prisma.workoutExercise.update({
                where: { id: we.id },
                data: { exerciseId: alt.id },
              });
              await prisma.exerciseSet.deleteMany({ where: { workoutExerciseId: we.id } });
              actionExecuted = true;
            }
          } else {
            actionExecuted = true;
          }

          if (swappedFrom && swappedTo) {
            const reasonClause = altReason ? ` (${altReason})` : "";
            if (!confirmationMessage.toLowerCase().includes(swappedTo.toLowerCase())) {
              confirmationMessage = `Swapped ${swappedFrom} for ${swappedTo}${reasonClause}.`;
            }
          }
        }
      }
    } else if (interpretation.intent === "lighter_intensity") {
      const countMatch = message.match(/(\d+)/);
      const parsedMatch = countMatch ? parseInt(countMatch[1], 10) : null;
      const targetCount = interpretation.targetCount ?? (parsedMatch && parsedMatch > 0 && parsedMatch <= 15 ? parsedMatch : null);

      let activeSession: any = await prisma.workoutSession.findFirst({
        where: { userId, endedAt: null },
        include: { exercises: { include: { exercise: true } } },
      });

      if (!activeSession) {
        const createdSess = await prisma.workoutSession.create({
          data: {
            userId,
            name: currentSession.todayDayName,
            startedAt: new Date(),
          },
        });
        for (let i = 0; i < currentSession.exercises.length; i++) {
          const ex = currentSession.exercises[i];
          if (ex.id) {
            await prisma.workoutExercise.create({
              data: {
                sessionId: createdSess.id,
                exerciseId: ex.id,
                order: i + 1,
              },
            });
          }
        }
        activeSession = await prisma.workoutSession.findFirst({
          where: { id: createdSess.id },
          include: { exercises: { include: { exercise: true } } },
        });
      }

      if (interpretation.targetSets && interpretation.targetSets > 0 && activeSession) {
        const targetSetsNum = interpretation.targetSets;
        actionExecuted = true;
        confirmationMessage = `Got it! Adjusted target volume for today's workout to ${targetSetsNum} sets.`;
      } else if (activeSession && targetCount && targetCount > 0 && activeSession.exercises.length > targetCount) {
        const toRemove = activeSession.exercises.slice(targetCount);
        for (const r of toRemove) {
          await prisma.exerciseSet.deleteMany({ where: { workoutExerciseId: r.id } });
          await prisma.workoutExercise.delete({ where: { id: r.id } });
        }
        actionExecuted = true;
        confirmationMessage = `Got it! Reduced today's workout to your top ${targetCount} main exercises.`;
      } else {
        actionExecuted = true;
        if (!confirmationMessage || confirmationMessage.includes("wasn't sure")) {
          confirmationMessage = `Lightened today's intensity. Focus on clean form and lower overall volume today!`;
        }
      }
    } else if (interpretation.intent === "change_plan" || interpretation.intent === "setup_routine") {
      const currentDays = user.workoutDays ?? 4;
      const resolved = resolveSplitForChangePlan(
        interpretation.proposedSplitName,
        typeof interpretation.proposedDays === "number" ? interpretation.proposedDays : null,
        currentDays
      );

      if (resolved) {
        const configuredAt = new Date();
        console.log(`⏳ [Workout] Executing change_plan via chat for user ${userId}: ${resolved.splitName} (${resolved.daysPerWeek}d/${resolved.splitType})`);

        await prisma.user.update({
          where: { id: userId },
          data: {
            workoutDays: resolved.daysPerWeek,
            workoutSplitType: resolved.splitType,
            workoutSplitName: resolved.splitName,
            workoutConfiguredAt: configuredAt,
          },
        });

        await prisma.sessionOverride.deleteMany({
          where: { userId, date: { gte: targetDateStr } },
        });

        actionExecuted = true;
        activeSplitType = resolved.splitType;
        activeSplitName = resolved.splitName;
        activeConfiguredAt = configuredAt;

        if (!confirmationMessage || confirmationMessage.includes("tap Confirm")) {
          confirmationMessage = `Switched your routine to ${resolved.splitName} (${resolved.daysPerWeek} days/week). Today's session is now updated.`;
        }
      } else {
        actionExecuted = false;
        if (!confirmationMessage || confirmationMessage.toLowerCase().includes("switched")) {
          confirmationMessage = "I'd be happy to change your workout plan! Which routine would you like to switch to (e.g. Upper/Lower, PPL, Arnold split) or how many days a week would you like to train?";
        }
      }
    }

    // Fetch updated session data using effective split type
    const updatedSession = await fetchSessionData(userId, activeSplitType, activeSplitName, targetDateStr, activeConfiguredAt);

    res.status(200).json({
      success: true,
      data: {
        intent: interpretation.intent,
        actionExecuted,
        confirmationMessage,
        currentSession: updatedSession,
      },
    });

  } catch (err) {
    console.error("❌ [Workout] interpretWorkoutSessionRequest error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

// ── Weekly AI Recap ──────────────────────────────────────────

export async function getWeeklyRecap(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.workoutSplitType) {
      res.status(200).json({
        success: true,
        data: { recapNote: "No active routine split found. Setup a routine to receive weekly recaps." },
      });
      return;
    }

    const now = new Date();
    const startOfWeek = new Date(now);
    const dayOfWeek = (now.getDay() + 6) % 7;
    startOfWeek.setDate(now.getDate() - dayOfWeek);
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    const sessions = await prisma.workoutSession.findMany({
      where: {
        userId,
        startedAt: { gte: startOfWeek, lt: endOfWeek },
        endedAt: { not: null },
      },
      include: {
        exercises: {
          include: { exercise: true, sets: true },
        },
      },
    });

    const completedDaysCount = new Set(sessions.map((s) => new Date(s.startedAt).toISOString().split("T")[0])).size;
    const splitType = user.workoutSplitType;
    const splitName = user.workoutSplitName ?? user.workoutSplitType;
    const meta = ROUTINE_CATALOGUE[splitType];
    const daysArr = meta?.days ?? [];
    const scheduledTrainingDays = daysArr.filter((d) => d !== "Rest").length;

    const missedDaysCount = Math.max(0, Math.min(dayOfWeek + 1, scheduledTrainingDays) - completedDaysCount);
    const restDaysCount = (dayOfWeek + 1) - completedDaysCount;

    let prsAchieved: string[] = [];
    for (const session of sessions) {
      for (const we of session.exercises) {
        const completedSets = we.sets.filter((s) => s.isCompleted && s.weightKg != null && s.reps != null);
        if (completedSets.length > 0) {
          completedSets.sort((a, b) => (b.weightKg! * b.reps!) - (a.weightKg! * a.reps!));
          const topSet = completedSets[0];

          const previousBest = await prisma.exerciseSet.findFirst({
            where: {
              isCompleted: true,
              weightKg: { not: null },
              reps: { not: null },
              workoutExercise: {
                exerciseId: we.exerciseId,
                session: { userId, startedAt: { lt: startOfWeek } },
              },
            },
            orderBy: [{ weightKg: "desc" }, { reps: "desc" }],
          });

          if (previousBest && previousBest.weightKg != null) {
            if (topSet.weightKg! > previousBest.weightKg || (topSet.weightKg! === previousBest.weightKg && topSet.reps! > previousBest.reps!)) {
              prsAchieved.push(`${we.exercise.name}: ${topSet.weightKg}kg × ${topSet.reps} reps`);
            }
          }
        }
      }
    }

    let streakDays = 0;
    const allSessions = await prisma.workoutSession.findMany({
      where: { userId },
      select: { startedAt: true },
      orderBy: { startedAt: "desc" },
    });

    if (allSessions.length > 0) {
      const sessionDates = new Set(allSessions.map((s) => new Date(s.startedAt).toISOString().split("T")[0]));
      let checkDate = new Date();
      checkDate.setHours(0, 0, 0, 0);
      let checkStr = checkDate.toISOString().split("T")[0];
      if (!sessionDates.has(checkStr)) {
        checkDate.setDate(checkDate.getDate() - 1);
        checkStr = checkDate.toISOString().split("T")[0];
      }
      while (sessionDates.has(checkStr)) {
        streakDays++;
        checkDate.setDate(checkDate.getDate() - 1);
        checkStr = checkDate.toISOString().split("T")[0];
      }
    }

    const recapNote = await generateWeeklyRecapNote({
      splitName,
      completedDaysCount,
      missedDaysCount,
      restDaysCount,
      streakDays,
      prsAchieved: Array.from(new Set(prsAchieved)),
    });

    res.status(200).json({
      success: true,
      data: {
        splitName,
        completedDaysCount,
        missedDaysCount,
        restDaysCount,
        streakDays,
        prsAchieved: Array.from(new Set(prsAchieved)),
        recapNote,
      },
    });
  } catch (err) {
    console.error("❌ [Workout] getWeeklyRecap error:", err);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
}

export async function getExerciseFormGuide(req: Request, res: Response): Promise<void> {
  try {
    const name = String(req.query.name || "Exercise");
    const muscleGroup = String(req.query.muscleGroup || "Target Muscle");

    const guide = await generateExerciseFormGuide(name, muscleGroup);

    res.status(200).json({
      success: true,
      data: guide,
    });
  } catch (err: unknown) {
    res.status(500).json({
      success: false,
      message: err instanceof Error ? err.message : "Failed to generate exercise form guide",
    });
  }
}
