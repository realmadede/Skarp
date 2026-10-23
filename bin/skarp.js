#!/usr/bin/env node

/**
 * skarp — Universal Karpathy Guidelines CLI
 * https://github.com/realmadede/Skarp
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const readline = require('readline');

const REPO_RAW_URL = 'https://raw.githubusercontent.com/realmadede/Skarp/main';
const REPO_ROOT = path.resolve(__dirname, '..');

const AGENT_MAPPINGS = {
  universal: { target: 'AGENTS.md', adapter: 'adapters/universal/AGENTS.md' },
  claude:    { target: 'CLAUDE.md', adapter: 'adapters/claude/CLAUDE.md' },
  cursor:    { target: '.cursor/rules/karpathy-guidelines.mdc', adapter: 'adapters/cursor/karpathy-guidelines.mdc' },
  copilot:   { target: '.github/copilot-instructions.md', adapter: 'adapters/copilot/copilot-instructions.md' },
  windsurf:  { target: '.windsurfrules', adapter: 'adapters/windsurf/.windsurfrules' },
  cline:     { target: '.clinerules', adapter: 'adapters/cline/.clinerules' },
  aider:     { target: 'CONVENTIONS.md', adapter: 'adapters/aider/CONVENTIONS.md' },
  gemini:    { target: 'GEMINI.md', adapter: 'adapters/gemini/GEMINI.md' },
};

function printBanner() {
  console.log(`
   _____ _                      
  / ____| |                     
 | (___ | | ____ _ _ __ _ __    
  \___ \\| |/ / _\` | '__| '_ \\   
  ____) |   < (_| | |  | |_) |  
 |_____/|_|\\_\\__,_|_|  | .__/   
                       | |      
                       |_|      
  Universal Karpathy Guidelines for AI Coding Agents
`);
}

function printHelp() {
  printBanner();
  console.log(`
Usage:
  npx skarp [options]

Options:
  -a, --agents <list>   Comma-separated list of agents to install (default: all)
                        Available: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, all
  -d, --dir <path>      Target directory (default: current directory .)
  -A, --append          Append/merge guidelines into existing files instead of skipping
  -u, --uninstall       Uninstall guidelines from target directory (cleans merged blocks)
  -f, --force           Overwrite existing files without prompting
  --no-examples         Skip copying EXAMPLES.md reference file (installed by default)
  -l, --list            List all supported agents and their target files
  -h, --help            Show this help message

Examples:
  npx skarp
  npx skarp --agents cursor,claude
  npx skarp --dir ./my-project --append
`);
}

function fetchRemote(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(fetchRemote(res.headers.location));
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} while fetching ${url}`));
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

async function getContent(adapterPath) {
  const localFile = path.join(REPO_ROOT, adapterPath);
  if (fs.existsSync(localFile)) {
    return fs.readFileSync(localFile, 'utf8');
  }
  const url = `${REPO_RAW_URL}/${adapterPath}`;
  return await fetchRemote(url);
}

async function installFile(targetDir, relTarget, adapterPath, { force, append }) {
  const fullTarget = path.join(targetDir, relTarget);
  const parentDir = path.dirname(fullTarget);
  if (!fs.existsSync(parentDir)) {
    fs.mkdirSync(parentDir, { recursive: true });
  }

  const content = await getContent(adapterPath);

  if (fs.existsSync(fullTarget)) {
    if (append && relTarget !== 'EXAMPLES.md') {
      const startMarker = '<!-- SKARP_GUIDELINES_START -->';
      const endMarker = '<!-- SKARP_GUIDELINES_END -->';
      const existingText = fs.readFileSync(fullTarget, 'utf8');

      if (existingText.includes(startMarker)) {
        const regex = new RegExp(`${escapeRegex(startMarker)}[\\s\\S]*?${escapeRegex(endMarker)}`, 'g');
        const block = `${startMarker}\n${content}\n${endMarker}`;
        const updated = existingText.replace(regex, block);
        fs.writeFileSync(fullTarget, updated, 'utf8');
        console.log(`  [UPDATED] ${relTarget} (refreshed existing Skarp block)`);
        return;
      } else {
        const appended = `${existingText}\n\n${startMarker}\n${content}\n${endMarker}\n`;
        fs.writeFileSync(fullTarget, appended, 'utf8');
        console.log(`  [MERGED]  ${relTarget} (appended to existing file)`);
        return;
      }
    } else if (!force) {
      console.log(`  [SKIP]    ${relTarget} already exists. Use --force or --append.`);
      return;
    }
  }

  fs.writeFileSync(fullTarget, content, 'utf8');
  console.log(`  [OK]      ${relTarget}`);
}

function uninstallFile(targetDir, relTarget) {
  const fullTarget = path.join(targetDir, relTarget);
  if (!fs.existsSync(fullTarget)) return;

  const startMarker = '<!-- SKARP_GUIDELINES_START -->';
  const endMarker = '<!-- SKARP_GUIDELINES_END -->';
  const existingText = fs.readFileSync(fullTarget, 'utf8');

  if (existingText.includes(startMarker)) {
    const regex = new RegExp(`\\n*${escapeRegex(startMarker)}[\\s\\S]*?${escapeRegex(endMarker)}\\n*`, 'g');
    const updated = existingText.replace(regex, '').trim() + '\n';
    fs.writeFileSync(fullTarget, updated, 'utf8');
    console.log(`  [CLEANED] ${relTarget} (removed Skarp block)`);
  } else {
    fs.unlinkSync(fullTarget);
    console.log(`  [REMOVED] ${relTarget}`);
  }

  const parentDir = path.dirname(fullTarget);
  if (parentDir !== targetDir && parentDir.startsWith(targetDir)) {
    try {
      if (fs.readdirSync(parentDir).length === 0) {
        fs.rmdirSync(parentDir);
        const grandParent = path.dirname(parentDir);
        if (grandParent !== targetDir && grandParent.startsWith(targetDir) && fs.readdirSync(grandParent).length === 0) {
          fs.rmdirSync(grandParent);
        }
      }
    } catch {}
  }
}

function escapeRegex(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function main() {
  const args = process.argv.slice(2);

  let targetDir = process.cwd();
  let agentsList = ['all'];
  let force = false;
  let append = false;
  let uninstall = false;
  let withExamples = true;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '-h' || arg === '--help') {
      printHelp();
      process.exit(0);
    }
    if (arg === '-l' || arg === '--list') {
      console.log('Supported agents:\n' + Object.keys(AGENT_MAPPINGS).map(k => `  ${k.padEnd(12)} -> ${AGENT_MAPPINGS[k].target}`).join('\n'));
      process.exit(0);
    }
    if (arg === '-f' || arg === '--force') {
      force = true;
    } else if (arg === '-A' || arg === '--append') {
      append = true;
    } else if (arg === '-u' || arg === '--uninstall') {
      uninstall = true;
    } else if (arg === '--no-examples') {
      withExamples = false;
    } else if (arg === '-d' || arg === '--dir') {
      targetDir = path.resolve(process.cwd(), args[++i]);
    } else if (arg === '-a' || arg === '--agents') {
      agentsList = args[++i].split(',').map(s => s.trim().toLowerCase());
    }
  }

  const selectedKeys = agentsList.includes('all')
    ? Object.keys(AGENT_MAPPINGS)
    : agentsList.filter(k => AGENT_MAPPINGS[k]);

  if (uninstall) {
    console.log(`Uninstalling Skarp guidelines from: ${targetDir}`);
    for (const key of selectedKeys) {
      const { target } = AGENT_MAPPINGS[key];
      uninstallFile(targetDir, target);
    }
    uninstallFile(targetDir, 'EXAMPLES.md');
    console.log('\nUninstall complete!');
    return;
  }

  console.log(`Installing Skarp guidelines into: ${targetDir}`);

  for (const key of selectedKeys) {
    const { target, adapter } = AGENT_MAPPINGS[key];
    await installFile(targetDir, target, adapter, { force, append });
  }

  if (withExamples) {
    await installFile(targetDir, 'EXAMPLES.md', 'EXAMPLES.md', { force, append });
  }

  console.log('\nInstallation complete! Skarp guidelines are now active.');
}

main().catch(err => {
  console.error('\nError:', err.message);
  process.exit(1);
});
