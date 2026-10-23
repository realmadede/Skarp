#!/usr/bin/env node

/**
 * scripts/test.js — Regression test suite for Node CLI (bin/skarp.js)
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const CLI_PATH = path.resolve(__dirname, '../bin/skarp.js');

function runCli(args, options = {}) {
  try {
    const stdout = execFileSync(process.execPath, [CLI_PATH, ...args], {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      ...options,
    });
    return { status: 0, stdout, stderr: '' };
  } catch (err) {
    return {
      status: err.status || 1,
      stdout: err.stdout ? err.stdout.toString() : '',
      stderr: err.stderr ? err.stderr.toString() : err.message,
    };
  }
}

function assert(condition, message) {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    process.exit(1);
  }
}

console.log('Running Skarp CLI test suite...');

// Test 1: Help flag
const helpRes = runCli(['--help']);
assert(helpRes.status === 0, 'CLI --help should exit with 0');
assert(helpRes.stdout.includes('Universal Karpathy Guidelines'), 'Help should display banner');

// Test 2: Invalid agent exits non-zero
const badAgentRes = runCli(['--agents', 'nonexistent_agent']);
assert(badAgentRes.status !== 0, 'Invalid agent name must exit non-zero');
assert(badAgentRes.stderr.includes('Unknown agent'), 'Error must specify unknown agent');

// Test 3: Missing option value exits non-zero
const missingValRes = runCli(['--agents']);
assert(missingValRes.status !== 0, 'Missing --agents value must exit non-zero');

// Test 4: Default install into temp dir
const tmpDir1 = fs.mkdtempSync(path.join(os.tmpdir(), 'skarp-test-'));
const installRes = runCli(['--dir', tmpDir1]);
assert(installRes.status === 0, 'Default install should succeed');
assert(fs.existsSync(path.join(tmpDir1, 'AGENTS.md')), 'AGENTS.md must exist');
assert(fs.existsSync(path.join(tmpDir1, 'CLAUDE.md')), 'CLAUDE.md must exist');
assert(fs.existsSync(path.join(tmpDir1, 'EXAMPLES.md')), 'EXAMPLES.md must exist');

// Test 5: User file protection during uninstall
const tmpDir2 = fs.mkdtempSync(path.join(os.tmpdir(), 'skarp-user-test-'));
const userClaude = path.join(tmpDir2, 'CLAUDE.md');
fs.writeFileSync(userClaude, '# Custom Team Rules\n', 'utf8');

// Install with skip
runCli(['--dir', tmpDir2, '--agents', 'claude']);
// Uninstall
runCli(['--dir', tmpDir2, '--uninstall']);
assert(fs.existsSync(userClaude), 'User CLAUDE.md must survive uninstall');
assert(fs.readFileSync(userClaude, 'utf8') === '# Custom Team Rules\n', 'User content must remain intact');

// Test 6: Append then check single block
runCli(['--dir', tmpDir2, '--agents', 'claude', '--append']);
runCli(['--dir', tmpDir2, '--agents', 'claude', '--append']);
const appendedContent = fs.readFileSync(userClaude, 'utf8');
const startMatches = appendedContent.match(/<!-- SKARP_GUIDELINES_START -->/g) || [];
assert(startMatches.length === 1, 'Should contain exactly one START marker after repeated appends');

// Clean up
fs.rmSync(tmpDir1, { recursive: true, force: true });
fs.rmSync(tmpDir2, { recursive: true, force: true });

console.log('All CLI tests passed successfully!');
