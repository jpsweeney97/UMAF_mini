// scripts/run-envelopes.mjs
import { promisify } from 'node:util';
import { execFile as execFileCb } from 'node:child_process';
import { glob } from 'glob';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs/promises';

const execFile = promisify(execFileCb);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PROJECT_ROOT = path.resolve(__dirname, '..');
const CRUCIBLE_DIR = path.join(PROJECT_ROOT, 'crucible');
const OUT_DIR = path.join(PROJECT_ROOT, '.build', 'envelopes'); // temp output

const DEFAULT_CLI = path.join(PROJECT_ROOT, 'build', 'Products', 'Debug', 'UMAFMiniCLI');

// Use env override if present; otherwise default to the repo-local build.
const CLI = process.env.UMAF_CLI_PATH || DEFAULT_CLI;
async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

async function runCliOnFile(inputPath, outputPath, format = 'json') {
  console.log(`→ Generating ${format.toUpperCase()} for ${inputPath} → ${outputPath}`);
  const args = [];

  // Input path
  args.push('--input', inputPath);

  // Output format
  if (format === 'json') {
    args.push('--json');
  } else if (format === 'markdown') {
    args.push('--markdown');
  }

  // Output path
  args.push('--output', outputPath);

  await execFile(CLI, args, {
    stdio: 'inherit',
  });
}

async function main() {
  const pattern = path.join(CRUCIBLE_DIR, '**', '*.*'); // all crucible files
  const inputs = await glob(pattern, { nodir: true });

  if (inputs.length === 0) {
    console.error(`No crucible inputs found under ${CRUCIBLE_DIR}`);
    process.exit(1);
  }

  await ensureDir(OUT_DIR);

  const outPaths = [];

  for (const input of inputs) {
    const base = path.basename(input).replace(/\.[^.]+$/, ''); // drop extension

    const envPass1 = path.join(OUT_DIR, `${base}__envelope_pass1.json`);
    const normPass1 = path.join(OUT_DIR, `${base}__norm_pass1.md`);
    const envPass2 = path.join(OUT_DIR, `${base}__envelope_pass2.json`);
    const normPass2 = path.join(OUT_DIR, `${base}__norm_pass2.md`);

    // Pass 1: original input → envelope + normalized markdown
    await runCliOnFile(input, envPass1, 'json');
    await runCliOnFile(input, normPass1, 'markdown');

    // Pass 2: run again on normalized markdown
    await runCliOnFile(normPass1, envPass2, 'json');
    await runCliOnFile(normPass1, normPass2, 'markdown');

    // Idempotence check: normalized markdown should be stable
    const [norm1, norm2] = await Promise.all([
      fs.readFile(normPass1, 'utf8'),
      fs.readFile(normPass2, 'utf8'),
    ]);

    if (norm1 !== norm2) {
      console.error(`❌ Non-idempotent Markdown for ${input}`);
      console.error(`First normalized: ${normPass1}`);
      console.error(`Second normalized: ${normPass2}`);
      process.exit(1);
    } else {
      console.log(`✅ Idempotent Markdown for ${input}`);
    }

    // Collect both envelopes for schema validation
    outPaths.push(envPass1, envPass2);
  }

  // Now validate all generated envelopes with your validator
  const validateScript = path.join(PROJECT_ROOT, 'scripts', 'validate2020.mjs');
  const env = { ...process.env };

  const args = [
    validateScript,
    '--schema',
    path.join(PROJECT_ROOT, 'schemas', 'umaf-mini-envelope-v0.4.1.schema.json'),
    '--data',
    path.join(OUT_DIR, '*.json'),
    '--strict',
  ];

  console.log('→ Validating generated envelopes against schema…');
  await execFile('node', args, {
    stdio: 'inherit',
    env,
  });

  console.log('✅ All generated envelopes are schema-valid');
}

main().catch((err) => {
  console.error('❌ Build validation failed:', err);
  process.exit(1);
});
