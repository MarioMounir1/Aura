// ============================================================
//  src/middleware/upload.middleware.ts
//  Multer configuration for secure meal screenshot uploads
// ============================================================

import multer, { FileFilterCallback } from "multer";
import { Request } from "express";

const MAX_SIZE_MB = parseInt(process.env.UPLOAD_MAX_SIZE_MB ?? "10", 10);
const MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024;

const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/webp",
]);

/**
 * Memory storage — keeps file in buffer (no disk write).
 * Buffer is passed directly to Gemini API for analysis.
 */
const storage = multer.memoryStorage();

/**
 * File filter — only allows image MIME types.
 */
function fileFilter(
  _req: Request,
  file: Express.Multer.File,
  callback: FileFilterCallback
): void {
  if (ALLOWED_MIME_TYPES.has(file.mimetype)) {
    callback(null, true);
  } else {
    callback(
      new Error(
        `Invalid file type: "${file.mimetype}". Allowed types: JPEG, PNG, WEBP.`
      )
    );
  }
}

/**
 * Main upload middleware for single meal image.
 * Field name: "image"
 */
export const uploadMealImage = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: MAX_SIZE_BYTES,
    files: 1,
  },
}).single("image");

/**
 * Wraps Multer in a promise for async/await usage in controllers.
 */
export function processUpload(
  req: Request,
  res: import("express").Response
): Promise<void> {
  return new Promise((resolve, reject) => {
    uploadMealImage(req, res, (err: unknown) => {
      if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
          reject(
            new Error(
              `File too large. Maximum allowed size is ${MAX_SIZE_MB}MB.`
            )
          );
        } else {
          reject(new Error(`Upload error: ${err.message}`));
        }
      } else if (err instanceof Error) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
}
