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
  codex:     { target: 'CODEX.md', adapter: 'adapters/codex/CODEX.md' },
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
                        Available: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, codex, all
  -d, --dir <path>      Target directory (default: current directory .)
  -s, --symlink         Create symlinks instead of copying (requires local cloned repo)
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

async function installFile(targetDir, relTarget, adapterPath, { force, append, symlink = false }) {
  const fullTarget = path.join(targetDir, relTarget);
  const parentDir = path.dirname(fullTarget);
  if (!fs.existsSync(parentDir)) {
    fs.mkdirSync(parentDir, { recursive: true });
  }

  try {
    const stat = fs.lstatSync(fullTarget);
    if (stat.isSymbolicLink() && append) {
      console.error(`Error: Cannot --append to symlinked file: ${relTarget}`);
      process.exit(1);
    }
  } catch {}

  if (symlink) {
    const localFile = path.join(REPO_ROOT, adapterPath);
    if (!fs.existsSync(localFile)) {
      console.error(`Error: --symlink requires local repository files, but ${adapterPath} was not found.`);
      process.exit(1);
    }
    try {
      const exists = fs.existsSync(fullTarget) || fs.lstatSync(fullTarget).isSymbolicLink();
      if (exists) {
        if (force) {
          fs.unlinkSync(fullTarget);
        } else {
          console.log(`  [SKIP]    ${relTarget} already exists. Use --force.`);
          return;
        }
      }
    } catch {}
    fs.symlinkSync(path.resolve(localFile), fullTarget);
    console.log(`  [LINK]    ${relTarget} -> ${localFile}`);
    return;
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
        const updated = existingText.replace(regex, () => block);
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

  const wrapped = wrapSkarpContent(content);
  fs.writeFileSync(fullTarget, wrapped, 'utf8');
  console.log(`  [OK]      ${relTarget}`);
}

function wrapSkarpContent(content) {
  const startMarker = '<!-- SKARP_GUIDELINES_START -->';
  const endMarker = '<!-- SKARP_GUIDELINES_END -->';
  if (content.includes(startMarker)) return content;

  const match = content.match(/^(---\r?\n[\s\S]*?\r?\n---\r?\n)([\s\S]*)$/);
  if (match) {
    const frontmatter = match[1];
    const body = match[2].trim();
    return `${frontmatter}\n${startMarker}\n${body}\n${endMarker}\n`;
  } else {
    return `${startMarker}\n${content.trim()}\n${endMarker}\n`;
  }
}

function uninstallFile(targetDir, relTarget) {
  const fullTarget = path.join(targetDir, relTarget);
  if (!fs.existsSync(fullTarget)) return;

  const startMarker = '<!-- SKARP_GUIDELINES_START -->';
  const endMarker = '<!-- SKARP_GUIDELINES_END -->';
  const existingText = fs.readFileSync(fullTarget, 'utf8');

  if (!existingText.includes(startMarker)) {
    console.log(`  [SKIP]    ${relTarget} not installed by Skarp`);
    return;
  }

  const regex = new RegExp(`\\n*${escapeRegex(startMarker)}[\\s\\S]*?${escapeRegex(endMarker)}\\n*`, 'g');
  const remaining = existingText.replace(regex, '').trim();
  const bodyWithoutFm = remaining.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/, '').trim();

  if (remaining === '' || bodyWithoutFm === '') {
    fs.unlinkSync(fullTarget);
    console.log(`  [REMOVED] ${relTarget}`);
  } else {
    fs.writeFileSync(fullTarget, remaining + '\n', 'utf8');
    console.log(`  [CLEANED] ${relTarget} (removed Skarp block)`);
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
  let symlink = false;
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
    } else if (arg === '-s' || arg === '--symlink') {
      symlink = true;
    } else if (arg === '-A' || arg === '--append') {
      append = true;
    } else if (arg === '-u' || arg === '--uninstall') {
      uninstall = true;
    } else if (arg === '--no-examples') {
      withExamples = false;
    } else if (arg === '-d' || arg === '--dir') {
      if (i + 1 >= args.length || args[i + 1].startsWith('-')) {
        console.error('Error: Missing value for --dir option.');
        process.exit(1);
      }
      targetDir = path.resolve(process.cwd(), args[++i]);
    } else if (arg === '-a' || arg === '--agents') {
      if (i + 1 >= args.length || args[i + 1].startsWith('-')) {
        console.error('Error: Missing value for --agents option.');
        process.exit(1);
      }
      agentsList = args[++i].split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
    } else {
      console.error(`Error: Unknown argument: ${arg}`);
      console.error('Run with -h or --help for usage information.');
      process.exit(1);
    }
  }

  if (symlink && append) {
    console.error('Error: Cannot combine --symlink and --append.');
    process.exit(1);
  }

  const validAgents = Object.keys(AGENT_MAPPINGS);
  if (agentsList.length === 0) {
    console.error('Error: No agents specified.');
    process.exit(1);
  }

  let selectedKeys = [];
  if (agentsList.includes('all')) {
    selectedKeys = validAgents;
  } else {
    const invalidAgents = agentsList.filter(a => !AGENT_MAPPINGS[a]);
    if (invalidAgents.length > 0) {
      console.error(`Error: Unknown agent(s): ${invalidAgents.join(', ')}`);
      console.error(`Valid agents: ${validAgents.join(', ')}, all`);
      process.exit(1);
    }
    selectedKeys = agentsList;
  }

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
    await installFile(targetDir, target, adapter, { force, append, symlink });
  }

  if (withExamples) {
    await installFile(targetDir, 'EXAMPLES.md', 'EXAMPLES.md', { force, append, symlink });
  }

  console.log('\nInstallation complete! Skarp guidelines are now active.');
}

main().catch(err => {
  console.error('\nError:', err.message);
  process.exit(1);
});
