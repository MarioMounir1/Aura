// lib/features/calorie_tracker/data/services/exercise_media_service.dart
// Aura — Exercise Media Resolver & CDN Catalog
// Provides animated GIFs & high-res demonstration thumbnails for exercises

class ExerciseMediaInfo {
  final String name;
  final String gifUrl;
  final String thumbnailUrl;
  final List<String> frames;

  const ExerciseMediaInfo({
    required this.name,
    required this.gifUrl,
    required this.thumbnailUrl,
    this.frames = const [],
  });
}

class ExerciseMediaService {
  ExerciseMediaService._();

  static const String _yuhonasBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';
  static const String _gifsBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos';
  static const String _thumbsBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/images';

  /// Pre-mapped high-precision exercise animations and thumbnails
  static final Map<String, ExerciseMediaInfo> _catalog = {
    // ── Chest ──────────────────────────────────────────────────────────
    'bench_press': const ExerciseMediaInfo(
      name: 'Barbell Bench Press',
      gifUrl: '$_gifsBase/0025-EIeI8Vf.gif',
      thumbnailUrl: '$_yuhonasBase/Barbell_Bench_Press_-_Medium_Grip/0.jpg',
      frames: [
        '$_yuhonasBase/Barbell_Bench_Press_-_Medium_Grip/0.jpg',
        '$_yuhonasBase/Barbell_Bench_Press_-_Medium_Grip/1.jpg',
      ],
    ),
    'incline_press': const ExerciseMediaInfo(
      name: 'Incline Dumbbell Press',
      gifUrl: '$_gifsBase/0314-8xW140L.gif',
      thumbnailUrl: '$_yuhonasBase/Incline_Dumbbell_Press/0.jpg',
      frames: [
        '$_yuhonasBase/Incline_Dumbbell_Press/0.jpg',
        '$_yuhonasBase/Incline_Dumbbell_Press/1.jpg',
      ],
    ),
    'dumbbell_bench': const ExerciseMediaInfo(
      name: 'Dumbbell Bench Press',
      gifUrl: '$_gifsBase/0289-5G78wYq.gif',
      thumbnailUrl: '$_yuhonasBase/Dumbbell_Bench_Press/0.jpg',
      frames: [
        '$_yuhonasBase/Dumbbell_Bench_Press/0.jpg',
        '$_yuhonasBase/Dumbbell_Bench_Press/1.jpg',
      ],
    ),
    'cable_fly': const ExerciseMediaInfo(
      name: 'Cable Flyes',
      gifUrl: '$_gifsBase/0160-v2Yw7Yw.gif',
      thumbnailUrl: '$_yuhonasBase/Cable_Crossover/0.jpg',
      frames: [
        '$_yuhonasBase/Cable_Crossover/0.jpg',
        '$_yuhonasBase/Cable_Crossover/1.jpg',
      ],
    ),
    'pushups': const ExerciseMediaInfo(
      name: 'Push-Ups',
      gifUrl: '$_gifsBase/0662-fK8rV41.gif',
      thumbnailUrl: '$_yuhonasBase/Pushups/0.jpg',
      frames: [
        '$_yuhonasBase/Pushups/0.jpg',
        '$_yuhonasBase/Pushups/1.jpg',
      ],
    ),
    'dips': const ExerciseMediaInfo(
      name: 'Dips',
      gifUrl: '$_gifsBase/0251-Zl0X24n.gif',
      thumbnailUrl: '$_yuhonasBase/Dips_-_Chest_Version/0.jpg',
      frames: [
        '$_yuhonasBase/Dips_-_Chest_Version/0.jpg',
        '$_yuhonasBase/Dips_-_Chest_Version/1.jpg',
      ],
    ),

    // ── Shoulders ──────────────────────────────────────────────────────
    'overhead_press': const ExerciseMediaInfo(
      name: 'Overhead Press',
      gifUrl: '$_gifsBase/0091-k7YgV6D.gif',
      thumbnailUrl: '$_yuhonasBase/Standing_Military_Press/0.jpg',
      frames: [
        '$_yuhonasBase/Standing_Military_Press/0.jpg',
        '$_yuhonasBase/Standing_Military_Press/1.jpg',
      ],
    ),
    'lateral_raises': const ExerciseMediaInfo(
      name: 'Cable Lateral Raises',
      gifUrl: '$_gifsBase/0179-8dE8J5V.gif',
      thumbnailUrl: '$_yuhonasBase/Side_Lateral_Raise/0.jpg',
      frames: [
        '$_yuhonasBase/Side_Lateral_Raise/0.jpg',
        '$_yuhonasBase/Side_Lateral_Raise/1.jpg',
      ],
    ),
    'arnold_press': const ExerciseMediaInfo(
      name: 'Arnold Press',
      gifUrl: '$_gifsBase/0011-NlX4X4w.gif',
      thumbnailUrl: '$_yuhonasBase/Arnold_Dumbbell_Press/0.jpg',
      frames: [
        '$_yuhonasBase/Arnold_Dumbbell_Press/0.jpg',
        '$_yuhonasBase/Arnold_Dumbbell_Press/1.jpg',
      ],
    ),
    'face_pull': const ExerciseMediaInfo(
      name: 'Face Pulls',
      gifUrl: '$_gifsBase/0164-3xW9q1G.gif',
      thumbnailUrl: '$_yuhonasBase/Face_Pull/0.jpg',
      frames: [
        '$_yuhonasBase/Face_Pull/0.jpg',
        '$_yuhonasBase/Face_Pull/1.jpg',
      ],
    ),

    // ── Back ───────────────────────────────────────────────────────────
    'pullups': const ExerciseMediaInfo(
      name: 'Pull-Ups',
      gifUrl: '$_gifsBase/0652-lBDjFxJ.gif',
      thumbnailUrl: '$_yuhonasBase/Pullups/0.jpg',
      frames: [
        '$_yuhonasBase/Pullups/0.jpg',
        '$_yuhonasBase/Pullups/1.jpg',
      ],
    ),
    'lat_pulldown': const ExerciseMediaInfo(
      name: 'Lat Pulldown',
      gifUrl: '$_gifsBase/0150-Zq4o9Wq.gif',
      thumbnailUrl: '$_yuhonasBase/Wide-Grip_Lat_Pulldown/0.jpg',
      frames: [
        '$_yuhonasBase/Wide-Grip_Lat_Pulldown/0.jpg',
        '$_yuhonasBase/Wide-Grip_Lat_Pulldown/1.jpg',
      ],
    ),
    'barbell_row': const ExerciseMediaInfo(
      name: 'Barbell Row',
      gifUrl: '$_gifsBase/0027-t7yqV4G.gif',
      thumbnailUrl: '$_yuhonasBase/Bent_Over_Barbell_Row/0.jpg',
      frames: [
        '$_yuhonasBase/Bent_Over_Barbell_Row/0.jpg',
        '$_yuhonasBase/Bent_Over_Barbell_Row/1.jpg',
      ],
    ),
    'cable_row': const ExerciseMediaInfo(
      name: 'Cable Row',
      gifUrl: '$_gifsBase/0237-7xW9P2L.gif',
      thumbnailUrl: '$_yuhonasBase/Seated_Cable_Rows/0.jpg',
      frames: [
        '$_yuhonasBase/Seated_Cable_Rows/0.jpg',
        '$_yuhonasBase/Seated_Cable_Rows/1.jpg',
      ],
    ),
    'deadlift': const ExerciseMediaInfo(
      name: 'Deadlift',
      gifUrl: '$_gifsBase/0032-ila4NZS.gif',
      thumbnailUrl: '$_yuhonasBase/Barbell_Deadlift/0.jpg',
      frames: [
        '$_yuhonasBase/Barbell_Deadlift/0.jpg',
        '$_yuhonasBase/Barbell_Deadlift/1.jpg',
      ],
    ),

    // ── Legs ───────────────────────────────────────────────────────────
    'squat': const ExerciseMediaInfo(
      name: 'Back Squat',
      gifUrl: '$_gifsBase/0043-qXTaZnJ.gif',
      thumbnailUrl: '$_yuhonasBase/Barbell_Full_Squat/0.jpg',
      frames: [
        '$_yuhonasBase/Barbell_Full_Squat/0.jpg',
        '$_yuhonasBase/Barbell_Full_Squat/1.jpg',
      ],
    ),
    'leg_press': const ExerciseMediaInfo(
      name: 'Leg Press',
      gifUrl: '$_gifsBase/0739-1j5F540.gif',
      thumbnailUrl: '$_yuhonasBase/Leg_Press/0.jpg',
      frames: [
        '$_yuhonasBase/Leg_Press/0.jpg',
        '$_yuhonasBase/Leg_Press/1.jpg',
      ],
    ),
    'rdl': const ExerciseMediaInfo(
      name: 'Romanian Deadlifts',
      gifUrl: '$_gifsBase/0085-f5V6nBv.gif',
      thumbnailUrl: '$_yuhonasBase/Romanian_Deadlift/0.jpg',
      frames: [
        '$_yuhonasBase/Romanian_Deadlift/0.jpg',
        '$_yuhonasBase/Romanian_Deadlift/1.jpg',
      ],
    ),
    'leg_curl': const ExerciseMediaInfo(
      name: 'Leg Curl',
      gifUrl: '$_gifsBase/0599-4jW9K1L.gif',
      thumbnailUrl: '$_yuhonasBase/Lying_Leg_Curls/0.jpg',
      frames: [
        '$_yuhonasBase/Lying_Leg_Curls/0.jpg',
        '$_yuhonasBase/Lying_Leg_Curls/1.jpg',
      ],
    ),
    'calf_raise': const ExerciseMediaInfo(
      name: 'Standing Calf Raises',
      gifUrl: '$_gifsBase/0816-5jW8K9P.gif',
      thumbnailUrl: '$_yuhonasBase/Standing_Calf_Raises/0.jpg',
      frames: [
        '$_yuhonasBase/Standing_Calf_Raises/0.jpg',
        '$_yuhonasBase/Standing_Calf_Raises/1.jpg',
      ],
    ),

    // ── Arms ───────────────────────────────────────────────────────────
    'bicep_curl': const ExerciseMediaInfo(
      name: 'Barbell / Dumbbell Curl',
      gifUrl: '$_gifsBase/0294-NbVPDMW.gif',
      thumbnailUrl: '$_yuhonasBase/Dumbbell_Bicep_Curl/0.jpg',
      frames: [
        '$_yuhonasBase/Dumbbell_Bicep_Curl/0.jpg',
        '$_yuhonasBase/Dumbbell_Bicep_Curl/1.jpg',
      ],
    ),
    'tricep_pushdown': const ExerciseMediaInfo(
      name: 'Tricep Pushdown',
      gifUrl: '$_gifsBase/0241-eL7k2qM.gif',
      thumbnailUrl: '$_yuhonasBase/Triceps_Pushdown/0.jpg',
      frames: [
        '$_yuhonasBase/Triceps_Pushdown/0.jpg',
        '$_yuhonasBase/Triceps_Pushdown/1.jpg',
      ],
    ),
    'hammer_curl': const ExerciseMediaInfo(
      name: 'Hammer Curl',
      gifUrl: '$_gifsBase/0313-2kL8P3M.gif',
      thumbnailUrl: '$_yuhonasBase/Hammer_Curls/0.jpg',
      frames: [
        '$_yuhonasBase/Hammer_Curls/0.jpg',
        '$_yuhonasBase/Hammer_Curls/1.jpg',
      ],
    ),
    'skull_crusher': const ExerciseMediaInfo(
      name: 'Skull Crushers',
      gifUrl: '$_gifsBase/0055-6pL9K4W.gif',
      thumbnailUrl: '$_yuhonasBase/Decline_EZ_Bar_Triceps_Extension/0.jpg',
      frames: [
        '$_yuhonasBase/Decline_EZ_Bar_Triceps_Extension/0.jpg',
        '$_yuhonasBase/Decline_EZ_Bar_Triceps_Extension/1.jpg',
      ],
    ),

    // ── Core ───────────────────────────────────────────────────────────
    'cable_crunch': const ExerciseMediaInfo(
      name: 'Cable Crunch',
      gifUrl: '$_gifsBase/0175-9jW4K2M.gif',
      thumbnailUrl: '$_yuhonasBase/Cable_Crunch/0.jpg',
      frames: [
        '$_yuhonasBase/Cable_Crunch/0.jpg',
        '$_yuhonasBase/Cable_Crunch/1.jpg',
      ],
    ),
  };

  /// Resolves Exercise Media Info based on exercise name with fuzzy keyword matching
  static ExerciseMediaInfo? resolve(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ');

    // 1. Direct or partial key matching
    if (lower.contains('incline') && (lower.contains('press') || lower.contains('dumbbell'))) {
      return _catalog['incline_press'];
    }
    if (lower.contains('bench') && (lower.contains('dumbbell') || lower.contains('db'))) {
      return _catalog['dumbbell_bench'];
    }
    if (lower.contains('bench') || (lower.contains('chest') && lower.contains('press'))) {
      return _catalog['bench_press'];
    }
    if (lower.contains('fly') || lower.contains('crossover')) {
      return _catalog['cable_fly'];
    }
    if (lower.contains('push up') || lower.contains('pushup')) {
      return _catalog['pushups'];
    }
    if (lower.contains('dip')) {
      return _catalog['dips'];
    }
    if (lower.contains('overhead') || lower.contains('military') || lower.contains('shoulder press')) {
      return _catalog['overhead_press'];
    }
    if (lower.contains('arnold')) {
      return _catalog['arnold_press'];
    }
    if (lower.contains('lateral') || lower.contains('side delt')) {
      return _catalog['lateral_raises'];
    }
    if (lower.contains('face pull')) {
      return _catalog['face_pull'];
    }
    if (lower.contains('pull up') || lower.contains('pullup') || lower.contains('chin up')) {
      return _catalog['pullups'];
    }
    if (lower.contains('pulldown') || lower.contains('lat pull')) {
      return _catalog['lat_pulldown'];
    }
    if (lower.contains('barbell row') || lower.contains('bent over') || (lower.contains('row') && !lower.contains('cable'))) {
      return _catalog['barbell_row'];
    }
    if (lower.contains('cable row') || lower.contains('seated row')) {
      return _catalog['cable_row'];
    }
    if (lower.contains('rdl') || lower.contains('romanian')) {
      return _catalog['rdl'];
    }
    if (lower.contains('deadlift')) {
      return _catalog['deadlift'];
    }
    if (lower.contains('squat')) {
      return _catalog['squat'];
    }
    if (lower.contains('leg press')) {
      return _catalog['leg_press'];
    }
    if (lower.contains('leg curl') || lower.contains('hamstring curl')) {
      return _catalog['leg_curl'];
    }
    if (lower.contains('calf')) {
      return _catalog['calf_raise'];
    }
    if (lower.contains('hammer')) {
      return _catalog['hammer_curl'];
    }
    if (lower.contains('bicep') || lower.contains('curl')) {
      return _catalog['bicep_curl'];
    }
    if (lower.contains('pushdown') || lower.contains('tricep')) {
      return _catalog['tricep_pushdown'];
    }
    if (lower.contains('skull') || lower.contains('crusher')) {
      return _catalog['skull_crusher'];
    }
    if (lower.contains('crunch') || lower.contains('ab')) {
      return _catalog['cable_crunch'];
    }

    // 2. Default fallback: synthesize yuhonas image URL from normalized name
    final formatted = name.trim().replaceAll(RegExp(r'\s+'), '_');
    return ExerciseMediaInfo(
      name: name,
      gifUrl: '$_yuhonasBase/$formatted/0.jpg',
      thumbnailUrl: '$_yuhonasBase/$formatted/0.jpg',
      frames: [
        '$_yuhonasBase/$formatted/0.jpg',
        '$_yuhonasBase/$formatted/1.jpg',
      ],
    );
  }

  /// Get optimal thumbnail (prefer direct URL, then resolved catalog thumbnail)
  static String? getThumbnailUrl(String exerciseName, {String? overrideUrl}) {
    if (overrideUrl != null && overrideUrl.isNotEmpty) return overrideUrl;
    final info = resolve(exerciseName);
    return info?.thumbnailUrl;
  }

  /// Get optimal GIF/media URL (prefer direct URL, then resolved catalog GIF)
  static String? getGifUrl(String exerciseName, {String? overrideUrl}) {
    if (overrideUrl != null && overrideUrl.isNotEmpty) return overrideUrl;
    final info = resolve(exerciseName);
    return info?.gifUrl ?? info?.thumbnailUrl;
  }
}
