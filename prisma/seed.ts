// ============================================================
//  prisma/seed.ts
//  Database seeding: pre-populate with Egyptian restaurants
//  Run with: npm run db:seed
// ============================================================

import "dotenv/config";
import process from "process";
import prisma from "../src/services/prisma.service";

async function main() {
  console.log("🌱  Seeding database with Egyptian restaurants...");

  const restaurants = [
    { name: "Buffalo Burger", category: "fast-food", rating: 4.6 },
    { name: "McDonald's", category: "fast-food", rating: 4.3 },
    { name: "KFC", category: "fast-food", rating: 4.5 },
    { name: "Hardee's", category: "fast-food", rating: 4.4 },
    { name: "Popeyes", category: "fast-food", rating: 4.2 },
    { name: "Cook Door", category: "fast-food", rating: 4.5 },
    { name: "Mo'men", category: "fast-food", rating: 4.4 },
    { name: "Gad", category: "fast-food", rating: 4.3 },
    { name: "Abou Tarek", category: "koshary", rating: 4.7 },
    { name: "Koshary El Tahrir", category: "koshary", rating: 4.6 },
    { name: "Kazouza", category: "koshary", rating: 4.5 },
    { name: "Arab", category: "grills", rating: 4.6 },
    { name: "Kababgy", category: "grills", rating: 4.5 },
  ];

  for (const restaurant of restaurants) {
    const created = await prisma.restaurant.upsert({
      where:  { name: restaurant.name },
      update: { rating: restaurant.rating },
      create: restaurant,
    });
    console.log(`✅  ${created.name} (${created.category})`);
  }

  console.log("✅  Database seeded successfully!");
}

main()
  .catch((e) => {
    console.error("❌  Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
