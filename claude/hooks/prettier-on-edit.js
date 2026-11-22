// Formats React source files with the repo's own Prettier right after Claude edits them,
// because the repo's husky pre-commit hook is not wired up on this machine.
const { spawnSync } = require('child_process');
const fs = require('fs'), path = require('path');

let input = '';
process.stdin.on('data', d => (input += d)).on('end', () => {
  let file = '';
  try { file = JSON.parse(input).tool_input.file_path || ''; } catch {}
  const m = file.match(/^(.*[\\/]optmyzr_react)[\\/]src[\\/].+\.(js|jsx|ts|tsx)$/i);
  if (!m || !fs.existsSync(file)) return;
  const bin = path.join(m[1], 'node_modules', 'prettier', 'bin', 'prettier.cjs');
  if (!fs.existsSync(bin)) return;
  spawnSync(process.execPath, [bin, '--write', '--log-level', 'warn', file], { cwd: m[1], stdio: 'ignore', timeout: 20000 });
});
