/**
 * G2B0 — the Cloud Run deploy script must bind every current frozen model
 * contract and must never use a replace-semantics env/secret mechanism that
 * could silently delete reading-durability, billing/Apple IAP or
 * review-access configuration it never lists. A prior version omitted the
 * Coffee/Palm/Tarot/Yıldızname bindings and used --env-vars-file/--set-secrets
 * (full replace), which would have wiped those keys on the next real update.
 */
import { execFileSync, spawnSync } from 'node:child_process';
import {
  appendFileSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

const scriptPath = fileURLToPath(
  new URL('../scripts/deploy-cloud-run.sh', import.meta.url),
);
const script = readFileSync(scriptPath, 'utf8');

describe('deploy-cloud-run.sh contract', () => {
  it('adds gpt-5.6-sol to the allowed-models list', () => {
    expect(script).toMatch(/OPENAI_ALLOWED_MODELS=gpt-4o,gpt-4o-mini,gpt-5\.6-sol/);
  });

  it('binds the Coffee/Palm reading model contract', () => {
    expect(script).toMatch(/OPENAI_READING_VISION_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_READING_WRITER_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_READING_REASONING_EFFORT=low/);
  });

  it('binds the frozen Tarot Narrative V2 writer contract', () => {
    expect(script).toMatch(/OPENAI_TAROT_NARRATIVE_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_TAROT_NARRATIVE_REASONING_EFFORT=none/);
  });

  it('binds the frozen Yıldızname narrative writer contract', () => {
    expect(script).toMatch(/OPENAI_YILDIZNAME_NARRATIVE_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT=none/);
  });

  it('binds the frozen Dream writer contract', () => {
    expect(script).toMatch(/OPENAI_DREAM_MODEL=gpt-6-astra/);
    expect(script).toMatch(/OPENAI_DREAM_REASONING_EFFORT=medium/);
  });

  it('defaults to no-traffic for an update deploy', () => {
    expect(script).toMatch(/NO_TRAFFIC="\$\{NO_TRAFFIC:-true\}"/);
    expect(script).toContain('DEPLOY_ARGS+=(--no-traffic)');
  });

  it('never uses a replace-semantics env/secret mechanism', () => {
    // These would silently delete any existing key this script doesn't list
    // (reading durability, billing/Apple IAP, review access). Only the
    // merge-semantics flags may be used as actual gcloud arguments — the
    // replace-semantics flag names may still appear in prose explaining why
    // they were replaced, so this checks for `=` (real usage), not the bare
    // substring.
    expect(script).not.toMatch(/--set-env-vars=/);
    expect(script).not.toMatch(/--env-vars-file=/);
    expect(script).not.toMatch(/--set-secrets=/);
    expect(script).toMatch(/--update-env-vars="\$ENV_UPDATES"/);
    expect(script).toMatch(/--update-secrets="OPENAI_API_KEY=\$\{SECRET_NAME\}:latest"/);
  });

  it('embeds no plaintext provider secret', () => {
    expect(script).not.toMatch(/sk-[A-Za-z0-9_-]{10,}/);
    // The key is sourced from Secret Manager only, and the script actively
    // refuses to run if OPENAI_API_KEY is exported into its own environment.
    expect(script).toMatch(/Do not export OPENAI_API_KEY into deploy; use Secret Manager/);
    expect(script).toMatch(/\[\[ -n "\$\{OPENAI_API_KEY:-\}" \]\] && fail/);
  });

  it('never echoes or logs a secret value', () => {
    expect(script).toMatch(/Never echo secrets/);
  });
});

/**
 * iOS Build 6 regression — a deploy enforcing an Android-only App Check
 * allowlist made the verifier reject every valid app.oracly iOS token (401 on
 * all protected routes) while Android kept working. The production allowlist
 * is exactly the two registered app.oracly Firebase apps.
 */
describe('deploy-cloud-run.sh App Check allowlist', () => {
  const ANDROID_APP_ID = '1:1075374196330:android:200bc15b1e43a8a2ef2c13';
  const IOS_APP_ID = '1:1075374196330:ios:5b526f23f001847eef2c13';
  const lines = script.split(/\r?\n/);

  it('contains the exact Android and iOS app.oracly Firebase App IDs', () => {
    expect(script).toContain(ANDROID_APP_ID);
    expect(script).toContain(IOS_APP_ID);
  });

  it('pins the canonical allowlist to exactly Android then iOS', () => {
    expect(lines).toContain(
      `EXPECTED_FIREBASE_APP_CHECK_APP_IDS="${ANDROID_APP_ID},${IOS_APP_ID}"`,
    );
  });

  it('defaults FIREBASE_APP_CHECK_APP_IDS to the canonical value', () => {
    expect(lines).toContain(
      'FIREBASE_APP_CHECK_APP_IDS="${FIREBASE_APP_CHECK_APP_IDS:-$EXPECTED_FIREBASE_APP_CHECK_APP_IDS}"',
    );
  });

  it('fails the deploy unless the allowlist equals the canonical value', () => {
    expect(lines).toContain(
      '[[ "$FIREBASE_APP_CHECK_APP_IDS" == "$EXPECTED_FIREBASE_APP_CHECK_APP_IDS" ]] || fail "Firebase App Check allowlist must be exactly the verified app.oracly Android and iOS apps"',
    );
  });

  it('no longer treats an Android-only allowlist as the accepted state', () => {
    expect(script).not.toContain('only the verified app.oracly Android app');
    expect(script).not.toContain(
      `[[ "$FIREBASE_APP_CHECK_APP_IDS" == "${ANDROID_APP_ID}" ]]`,
    );
    expect(script).not.toContain(
      `FIREBASE_APP_CHECK_APP_IDS:-${ANDROID_APP_ID}}`,
    );
  });

  it('keeps App Check enforced and binds the allowlist via merge semantics', () => {
    expect(script).toContain('ENV_UPDATES+="@AI_APP_CHECK_BYPASS=false"');
    expect(script).not.toMatch(/AI_APP_CHECK_BYPASS=true/);
    expect(script).toContain(
      'ENV_UPDATES+="@FIREBASE_APP_CHECK_APP_IDS=${FIREBASE_APP_CHECK_APP_IDS}"',
    );
    expect(script).toMatch(/--update-env-vars="\$ENV_UPDATES"/);
    expect(script).not.toMatch(/--set-env-vars=/);
    expect(script).not.toMatch(/--env-vars-file=/);
  });
});

/**
 * Revision lineage — Cloud Run copies labels from the previous revision
 * template, so a deploy that omits them labels a new image with an old
 * commit (seen on oracly-api-00091-kex: source_commit=aa735bcb on a 02a7153c
 * image). Every deploy must stamp source_commit / release_head / oracly_phase
 * from the checkout being built, with merge semantics, and reject bad lineage
 * before any gcloud, docker build, push or deploy.
 */
describe('deploy-cloud-run.sh revision lineage labels (static)', () => {
  const lines = script.split(/\r?\n/);
  // Executable lines only: comments may mention commands they precede.
  const lineOf = (needle: string) =>
    lines.findIndex((l) => !l.trimStart().startsWith('#') && l.includes(needle));

  it('stamps all three lineage labels with merge semantics', () => {
    expect(script).toContain(
      '--update-labels="source_commit=${SOURCE_COMMIT},release_head=${RELEASE_HEAD},oracly_phase=${ORACLY_PHASE}"',
    );
  });

  it('never clears or replaces the whole label set', () => {
    expect(script).not.toMatch(/--clear-labels/);
    expect(script).not.toMatch(/(^|\s)--labels=/m);
    expect(script).not.toMatch(/--remove-labels/);
  });

  it('derives SOURCE_COMMIT from the checkout and RELEASE_HEAD from it', () => {
    expect(script).toContain(
      `CHECKOUT_COMMIT="$(git -C "$BACKEND_DIR" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)"`,
    );
    expect(lines).toContain('SOURCE_COMMIT="${SOURCE_COMMIT-$CHECKOUT_COMMIT}"');
    expect(lines).toContain('RELEASE_HEAD="${RELEASE_HEAD-$SOURCE_COMMIT}"');
  });

  it('defaults the phase to a generic value, never a fixed release', () => {
    expect(lines).toContain('ORACLY_PHASE="${ORACLY_PHASE-manual-deploy}"');
    expect(script).not.toMatch(/ORACLY_PHASE[^\n]*premium-p1/);
  });

  it('validates lineage before any gcloud call, docker build, push or deploy', () => {
    const validated = lineOf('echo "Lineage: source_commit=');
    expect(validated).toBeGreaterThan(0);
    for (const sideEffect of [
      'command -v gcloud',
      'gcloud secrets describe',
      'docker build',
      'docker push',
      'gcloud run deploy',
    ]) {
      expect(lineOf(sideEffect)).toBeGreaterThan(validated);
    }
  });

  it('routes every deploy path through the labelled DEPLOY_ARGS', () => {
    const deploys = lines.filter((l) => l.includes('gcloud run deploy'));
    expect(deploys.length).toBeGreaterThanOrEqual(3);
    for (const call of deploys) {
      expect(call).toContain('"${DEPLOY_ARGS[@]}"');
    }
  });
});

/** Git for Windows' bash on win32 (never WSL); plain `bash` elsewhere. */
function resolveBash(): string {
  if (process.platform !== 'win32') return 'bash';
  const gitExec = execFileSync('git', ['--exec-path'], { encoding: 'utf8' }).trim();
  return join(dirname(dirname(dirname(gitExec))), 'bin', 'bash.exe');
}

const posix = (p: string) => p.replace(/\\/g, '/');

describe('deploy-cloud-run.sh revision lineage labels (behaviour)', () => {
  const bash = resolveBash();
  let repo: string;
  let head: string;
  let runIndex = 0;

  const git = (...args: string[]) =>
    execFileSync('git', ['-C', repo, ...args], { encoding: 'utf8' }).trim();

  beforeAll(() => {
    repo = mkdtempSync(join(tmpdir(), 'deploy-lineage-'));
    writeFileSync(join(repo, 'Dockerfile'), 'FROM scratch\n');
    writeFileSync(join(repo, 'package-lock.json'), '{}\n');
    git('init', '-q');
    git('-c', 'user.name=t', '-c', 'user.email=t@t', 'add', '.');
    git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'fixture');
    head = git('rev-parse', 'HEAD');
  });

  afterAll(() => {
    rmSync(repo, { recursive: true, force: true });
  });

  /**
   * Runs the real script with gcloud/docker replaced by exported bash
   * functions that only record their arguments. Nothing leaves the machine.
   */
  function run(overrides: Record<string, string | undefined> = {}) {
    const log = join(tmpdir(), `deploy-lineage-calls-${process.pid}-${runIndex++}.log`);
    writeFileSync(log, '');
    const env: Record<string, string> = {};
    for (const [k, v] of Object.entries(process.env)) {
      if (
        v !== undefined &&
        !/^(OPENAI_API_KEY|SOURCE_COMMIT|RELEASE_HEAD|ORACLY_PHASE|BASH_FUNC_)/.test(k)
      ) {
        env[k] = v;
      }
    }
    Object.assign(env, {
      BACKEND_DIR: posix(repo),
      IMAGE: 'example.invalid/oracly-api:test',
      STUB_LOG: posix(log),
      'BASH_FUNC_gcloud%%':
        '() { printf "gcloud %s\\n" "$*" >> "$STUB_LOG"; if [ "$1 $2 $3" = "run services describe" ] && [ -n "${STUB_NEW_SERVICE:-}" ]; then return 1; fi; return 0; }',
      'BASH_FUNC_docker%%': '() { printf "docker %s\\n" "$*" >> "$STUB_LOG"; return 0; }',
    });
    for (const [k, v] of Object.entries(overrides)) {
      if (v === undefined) delete env[k];
      else env[k] = v;
    }
    const result = spawnSync(bash, [posix(scriptPath)], {
      cwd: repo,
      env,
      encoding: 'utf8',
    });
    const calls = readFileSync(log, 'utf8').split('\n').filter(Boolean);
    rmSync(log, { force: true });
    const deploy = calls.find((c) => c.startsWith('gcloud run deploy')) ?? '';
    return { status: result.status, stderr: result.stderr ?? '', calls, deploy };
  }

  const labels = (source: string, release: string, phase: string) =>
    `--update-labels=source_commit=${source},release_head=${release},oracly_phase=${phase}`;

  function expectRejectedBeforeSideEffects(
    result: ReturnType<typeof run>,
    message: RegExp,
  ) {
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(message);
    // Not even a read-only gcloud call: nothing ran after the lineage guard.
    expect(result.calls).toEqual([]);
  }

  it('defaults source_commit and release_head to the checkout HEAD', () => {
    const result = run();
    expect(result.status, result.stderr).toBe(0);
    expect(head).toMatch(/^[0-9a-f]{40}$/);
    expect(result.deploy).toContain(labels(head, head, 'manual-deploy'));
    expect(result.deploy).not.toMatch(/--clear-labels|\s--labels=/);
    expect(result.calls.some((c) => c.startsWith('docker build'))).toBe(true);
    expect(result.calls.some((c) => c.startsWith('docker push'))).toBe(true);
  }, 30_000);

  it('accepts a matching SOURCE_COMMIT, a valid RELEASE_HEAD and a phase', () => {
    const release = 'a'.repeat(40);
    const result = run({
      SOURCE_COMMIT: head,
      RELEASE_HEAD: release,
      ORACLY_PHASE: 'premium-p1',
    });
    expect(result.status, result.stderr).toBe(0);
    expect(result.deploy).toContain(labels(head, release, 'premium-p1'));
  }, 30_000);

  it('stamps labels on the promote and first-create deploy paths too', () => {
    const promote = run({ NO_TRAFFIC: 'false' });
    expect(promote.status, promote.stderr).toBe(0);
    expect(promote.deploy).not.toContain('--no-traffic');
    expect(promote.deploy).toContain(labels(head, head, 'manual-deploy'));

    const create = run({ STUB_NEW_SERVICE: '1' });
    expect(create.status, create.stderr).toBe(0);
    expect(create.deploy).toContain(labels(head, head, 'manual-deploy'));
  }, 30_000);

  it('rejects a SOURCE_COMMIT that differs from the checkout', () => {
    const other = head.startsWith('b') ? 'c'.repeat(40) : 'b'.repeat(40);
    expectRejectedBeforeSideEffects(
      run({ SOURCE_COMMIT: other }),
      /SOURCE_COMMIT does not match the checkout being built/,
    );
  }, 30_000);

  it('rejects a malformed SOURCE_COMMIT', () => {
    for (const bad of ['', head.slice(0, 12), head.toUpperCase(), 'HEAD', `${head}0`]) {
      expectRejectedBeforeSideEffects(
        run({ SOURCE_COMMIT: bad }),
        /SOURCE_COMMIT must be a full 40-character lowercase git SHA/,
      );
    }
  }, 60_000);

  it('rejects a malformed RELEASE_HEAD', () => {
    for (const bad of ['', 'main', head.slice(0, 7), 'G'.repeat(40)]) {
      expectRejectedBeforeSideEffects(
        run({ RELEASE_HEAD: bad }),
        /RELEASE_HEAD must be a full 40-character lowercase git SHA/,
      );
    }
  }, 60_000);

  it('rejects an empty or label-unsafe ORACLY_PHASE', () => {
    for (const bad of ['', 'Premium-P1', 'premium_p1', 'premium p1', 'g2d,x=y', 'a'.repeat(64)]) {
      expectRejectedBeforeSideEffects(
        run({ ORACLY_PHASE: bad }),
        /ORACLY_PHASE must be 1-63 characters/,
      );
    }
  }, 60_000);

  it('rejects a checkout whose backend differs from its commit', () => {
    appendFileSync(join(repo, 'Dockerfile'), '# local edit\n');
    try {
      expectRejectedBeforeSideEffects(run(), /Uncommitted or untracked changes/);
    } finally {
      git('checkout', '--', 'Dockerfile');
    }
    writeFileSync(join(repo, 'stray.txt'), 'untracked\n');
    try {
      expectRejectedBeforeSideEffects(run(), /Uncommitted or untracked changes/);
    } finally {
      rmSync(join(repo, 'stray.txt'));
    }
  }, 30_000);

  it('rejects a build directory that is not a git checkout', () => {
    const loose = mkdtempSync(join(tmpdir(), 'deploy-lineage-nogit-'));
    try {
      writeFileSync(join(loose, 'Dockerfile'), 'FROM scratch\n');
      writeFileSync(join(loose, 'package-lock.json'), '{}\n');
      expectRejectedBeforeSideEffects(
        run({ BACKEND_DIR: posix(loose) }),
        /Cannot resolve the git HEAD/,
      );
    } finally {
      rmSync(loose, { recursive: true, force: true });
    }
  }, 30_000);
});
