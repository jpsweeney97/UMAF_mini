// scripts/run-envelopes.mjs
import { spawn } from "node:child_process";
import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");

function findCli() {
  // 1) Explicit override
  if (process.env.UMAF_CLI) {
    const p = process.env.UMAF_CLI;
    if (fs.existsSync(p)) return p;
    console.warn(`UMAF_CLI is set to ${p}, but it does not exist on disk.`);
  }

  // 2) SwiftPM builds (preferred in CI)
  const candidates = [
    path.join(projectRoot, ".build", "release", "umaf-mini"),
    path.join(projectRoot, ".build", "debug", "umaf-mini"),

    // 3) Xcode build (local dev only)
    path.join(projectRoot, "build", "Products", "Debug", "UMAFMiniCLI"),
  ];

  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }

  throw new Error(
    `Could not find umaf-mini CLI. Tried:\n` +
      candidates.map((c) => `  - ${c}`).join("\n") +
      `\nSet UMAF_CLI=/full/path/to/umaf-mini to override.`
  );
}

async function runOnce(cliPath, inputPath, outputPath) {
  console.log(`→ Generating JSON for ${inputPath} → ${outputPath}`);

  await fsp.mkdir(path.dirname(outputPath), { recursive: true });

  await new Promise((resolve, reject) => {
    const child = spawn(
      cliPath,
      ["--input", inputPath, "--json", "--output", outputPath],
      { stdio: "inherit" }
    );

    child.on("error", (err) => reject(err));
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`CLI exited with code ${code}`));
    });
  });
}

async function main() {
  const cliPath = findCli();

  const crucibleDir = path.join(projectRoot, "crucible");
  const outDir = path.join(projectRoot, ".build", "envelopes");

  const entries = fs.existsSync(crucibleDir)
    ? fs.readdirSync(crucibleDir, { withFileTypes: true })
    : [];

  const inputs = entries
    .filter((d) => d.isFile() && d.name.endsWith(".md"))
    .map((d) => path.join(crucibleDir, d.name));

  if (inputs.length === 0) {
    console.warn(
      `No .md files found under ${crucibleDir}; nothing to validate.`
    );
    return;
  }

  for (const inputPath of inputs) {
    const base = path.basename(inputPath, ".md");
    const outPath = path.join(outDir, `${base}__envelope_pass1.json`);
    await runOnce(cliPath, inputPath, outPath);
  }
}

main().catch((err) => {
  console.error("❌ Build validation failed:", err);
  process.exit(1);
});
