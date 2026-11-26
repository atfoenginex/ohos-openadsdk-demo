'use strict';

/**
 * ATFOHAdSDK hvigor wrapper.
 *
 * 说明：DevEco Studio 打开工程执行 Sync 时会按 IDE 版本重新生成规范版本；
 * 此文件为仓库内可用的最小实现，负责从本地依赖解析 @ohos/hvigor CLI 并转发参数。
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');

function resolveHvigorCli() {
  const candidates = [
    path.join(projectRoot, 'oh_modules', '@ohos', 'hvigor', 'bin', 'hvigor.js'),
    path.join(projectRoot, 'oh_modules', '@ohos', 'hvigor', 'hvigor.js'),
    path.join(projectRoot, 'node_modules', '@ohos', 'hvigor', 'bin', 'hvigor.js')
  ];
  for (const p of candidates) {
    try {
      if (fs.existsSync(p)) {
        return p;
      }
    } catch (e) {
      // ignore
    }
  }
  try {
    return require.resolve('@ohos/hvigor/bin/hvigor.js', { paths: [projectRoot] });
  } catch (e) {
    return null;
  }
}

const cli = resolveHvigorCli();
if (!cli) {
  console.error(
    '[hvigorw] 未找到 @ohos/hvigor CLI。请在 DevEco Studio 中打开本工程并 Sync ' +
    '(IDE 会生成 hvigor-wrapper.js 并安装依赖)。'
  );
  process.exit(1);
}

const child = spawn(process.execPath, [cli].concat(process.argv.slice(2)), {
  stdio: 'inherit',
  cwd: projectRoot
});
child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code === null ? 1 : code);
  }
});