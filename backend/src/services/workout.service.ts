import prisma from "./prisma.service";

export class WorkoutService {
  /**
   * Start a new gym workout session
   */
  static async startWorkoutSession(userId: string, name: string, exercises?: any[]) {
    // Determine the data to create
    return prisma.workoutSession.create({
      data: {
        userId,
        name,
        ...(exercises && exercises.length > 0 && {
          exercises: {
            create: exercises.map((ex, index) => ({
              // if ex.id exists, it's the Exercise template DB id
              exerciseId: ex.id,
              order: index,
            }))
          }
        })
      },
      include: {
        exercises: true,
      }
    });
  }

  /**
   * Add an exercise to an ongoing session
   */
  static async addExerciseToSession(sessionId: string, exerciseId: string, order: number, notes?: string) {
    return prisma.workoutExercise.create({
      data: {
        sessionId,
        exerciseId,
        order,
        notes,
      },
    });
  }

  /**
   * Log a single set (weight, reps, rpe)
   */
  static async logSet(workoutExerciseId: string, setNumber: number, reps?: number, weightKg?: number, rpe?: number) {
    return prisma.exerciseSet.create({
      data: {
        workoutExerciseId,
        setNumber,
        reps,
        weightKg,
        rpe,
        isCompleted: true,
      },
    });
  }

  /**
   * Finish the workout session
   */
  static async finishSession(sessionId: string, notes?: string) {
    return prisma.workoutSession.update({
      where: { id: sessionId },
      data: {
        endedAt: new Date(),
        notes,
      },
    });
  }
}
