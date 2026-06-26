#!/usr/bin/env node

import { Command } from '@commander-js/extra-typings';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs-extra';
import ora from 'ora';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { getVersion, getVersionInfo } from './version.js';
import { PluginManager } from './plugins/manager.js';
import { ensureProjectRoot, getProjectInfo } from './utils/project.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const program = new Command();

// แสดงแบนเนอร์ต้อนรับ
function displayBanner(): void {
  const banner = `
╔═══════════════════════════════════════╗
║  📚  Novel Writer Skills  📝          ║
║  เครื่องมือสร้างสรรค์นิยายสำหรับ Claude Code  ║
╚═══════════════════════════════════════╝
`;
  console.log(chalk.cyan(banner));
  console.log(chalk.gray(`  ${getVersionInfo()}\n`));
}

displayBanner();

program
  .name('novelwrite')
  .description(chalk.cyan('Novel Writer Skills - เครื่องมือสร้างสรรค์นิยายสำหรับ Claude Code โดยเฉพาะ'))[cite: 4]
  .version(getVersion(), '-v, --version', 'แสดงหมายเลขเวอร์ชัน')[cite: 4]
  .helpOption('-h, --help', 'แสดงข้อมูลช่วยเหลือ');[cite: 4]

// คำสั่ง init - เริ่มต้นสร้างโปรเจกต์นิยาย
program
  .command('init')
  .argument('[name]', 'ชื่อโปรเจกต์นิยาย')[cite: 4]
  .option('--here', 'เริ่มต้นโปรเจกต์ในไดเรกทอรีปัจจุบัน')[cite: 4]
  .option('--plugins <names>', 'ปลั๊กอินที่จะติดตั้งไว้ล่วงหน้า (คั่นด้วยเครื่องหมายจุลภาค ,)')[cite: 4]
  .option('--no-git', 'ข้ามการตั้งค่าเริ่มต้น Git')[cite: 4]
  .description('เริ่มต้นสร้างโปรเจกต์นิยายใหม่')[cite: 4]
  .action(async (name, options) => {
    const spinner = ora('กำลังเริ่มต้นสร้างโปรเจกต์นิยาย...').start();[cite: 4]

    try {
      // กำหนดเส้นทางโปรเจกต์ (Project Path)
      let projectPath: string;
      if (options.here) {
        projectPath = process.cwd();
        name = path.basename(projectPath);
      } else {
        if (!name) {
          spinner.fail('กรุณาระบุชื่อโปรเจกต์ หรือใช้พารามิเตอร์ --here');[cite: 4]
          process.exit(1);
        }
        projectPath = path.join(process.cwd(), name);
        if (await fs.pathExists(projectPath)) {
          spinner.fail(`ไดเรกทอรีโปรเจกต์ "${name}" มีอยู่แล้วในระบบ`);[cite: 4]
          process.exit(1);
        }
        await fs.ensureDir(projectPath);
      }

      // สร้างโครงสร้างพื้นฐานของโปรเจกต์
      const baseDirs = [
        '.specify',
        '.specify/memory',
        '.specify/templates',
        '.claude',
        '.claude/commands',
        '.claude/skills',
        'stories',
        'spec',
        'spec/tracking',
        'spec/knowledge'
      ];

      for (const dir of baseDirs) {
        await fs.ensureDir(path.join(projectPath, dir));
      }

      // สร้างไฟล์กำหนดค่าพื้นฐาน (Configuration File)
      const config = {
        name,
        type: 'novel',
        ai: 'claude',
        created: new Date().toISOString(),
        version: getVersion()
      };

      await fs.writeJson(path.join(projectPath, '.specify', 'config.json'), config, { spaces: 2 });

      // คัดลอกไฟล์เทมเพลตจากแพ็กเกจ novel-writer-skills
      const packageRoot = path.resolve(__dirname, '..');

      // คัดลอกไฟล์คำสั่ง (Commands)
      const commandsSource = path.join(packageRoot, 'templates', 'commands');
      const commandsDest = path.join(projectPath, '.claude', 'commands');
      if (await fs.pathExists(commandsSource)) {
        await fs.copy(commandsSource, commandsDest);
        spinner.text = 'ติดตั้ง Slash Commands เรียบร้อยแล้ว...';[cite: 4]
      }

      // คัดลอกไฟล์ทักษะ (Skills)
      const skillsSource = path.join(packageRoot, 'templates', 'skills');
      const skillsDest = path.join(projectPath, '.claude', 'skills');
      if (await fs.pathExists(skillsSource)) {
        await fs.copy(skillsSource, skillsDest);
        spinner.text = 'ติดตั้ง Agent Skills เรียบร้อยแล้ว...';[cite: 4]
      }

      // คัดลอกไฟล์เทมเพลตไปยัง .specify/templates
      const fullTemplatesDir = path.join(packageRoot, 'templates');
      if (await fs.pathExists(fullTemplatesDir)) {
        const userTemplatesDir = path.join(projectPath, '.specify', 'templates');
        await fs.copy(fullTemplatesDir, userTemplatesDir, { overwrite: false });
      }

      // คัดลอกไฟล์ความจำ (Memory)
      const memoryDir = path.join(packageRoot, 'templates', 'memory');
      if (await fs.pathExists(memoryDir)) {
        const userMemoryDir = path.join(projectPath, '.specify', 'memory');
        await fs.copy(memoryDir, userMemoryDir);
      }

      // คัดลอกเทมเพลตไฟล์ติดตามผล (Tracking)
      const trackingTemplatesDir = path.join(packageRoot, 'templates', 'tracking');
      if (await fs.pathExists(trackingTemplatesDir)) {
        const userTrackingDir = path.join(projectPath, 'spec', 'tracking');
        await fs.copy(trackingTemplatesDir, userTrackingDir);
      }

      // คัดลอกเทมเพลตคลังความรู้ (เจาะจงเฉพาะโปรเจกต์)
      const knowledgeTemplatesDir = path.join(packageRoot, 'templates', 'knowledge');
      if (await fs.pathExists(knowledgeTemplatesDir)) {
        const userKnowledgeDir = path.join(projectPath, 'spec', 'knowledge');
        await fs.copy(knowledgeTemplatesDir, userKnowledgeDir);
      }

      // คัดลอกระบบคลังความรู้ส่วนกลาง (เพิ่มเข้ามาใน v1.0)
      const knowledgeBaseDir = path.join(packageRoot, 'templates', 'knowledge-base');
      if (await fs.pathExists(knowledgeBaseDir)) {
        const claudeKnowledgeBaseDir = path.join(projectPath, '.claude', 'knowledge-base');
        await fs.copy(knowledgeBaseDir, claudeKnowledgeBaseDir);
        spinner.text = 'ติดตั้งระบบคลังความรู้เรียบร้อยแล้ว...';[cite: 4]
      }

      // ติดตั้งปลั๊กอินหากมีการระบุพารามิเตอร์ --plugins
      if (options.plugins) {
        spinner.text = 'กำลังติดตั้งปลั๊กอิน...';[cite: 4]
        const pluginNames = options.plugins.split(',').map((p: string) => p.trim());
        const pluginManager = new PluginManager(projectPath);

        for (const pluginName of pluginNames) {
          const builtinPluginPath = path.join(packageRoot, 'plugins', pluginName);
          if (await fs.pathExists(builtinPluginPath)) {
            await pluginManager.installPlugin(pluginName, builtinPluginPath);
          } else {
            console.log(chalk.yellow(`\nคำเตือน: ไม่พบปลั๊กอิน "${pluginName}"`));[cite: 4]
          }
        }
      }

      // ตั้งค่าเริ่มต้น Git (Git Initialization)
      if (options.git !== false) {
        try {
          execSync('git init', { cwd: projectPath, stdio: 'ignore' });

          const gitignore = `# ไฟล์ชั่วคราว
*.tmp
*.swp
.DS_Store

# การตั้งค่าสำหรับ Editor
.vscode/
.idea/

# แคชของ AI
.ai-cache/

# โฟลเดอร์โมดูล Node
node_modules/
`;
          await fs.writeFile(path.join(projectPath, '.gitignore'), gitignore);
          execSync('git add .', { cwd: projectPath, stdio: 'ignore' });
          execSync('git commit -m "เริ่มต้นสร้างโปรเจกต์นิยาย"', { cwd: projectPath, stdio: 'ignore' });[cite: 4]
        } catch {
          console.log(chalk.yellow('\nคำแนะนำ: การตั้งค่าเริ่มต้น Git ล้มเหลว แต่โปรเจกต์ถูกสร้างสำเร็จเรียบร้อยแล้ว'));[cite: 4]
        }
      }

      spinner.succeed(chalk.green(`สร้างโปรเจกต์นิยาย "${name}" สำเร็จเรียบร้อยแล้ว!`));[cite: 4]

      // แสดงขั้นตอนการดำเนินการต่อไป
      console.log('\n' + chalk.cyan('ขั้นตอนต่อไป:'));[cite: 4]
      console.log(chalk.gray('─────────────────────────────'));

      if (!options.here) {
        console.log(`  1. ${chalk.white(`cd ${name}`)} - เข้าสู่ไดเรกทอรีโปรเจกต์`);[cite: 4]
      }

      console.log(`  2. ${chalk.white('เปิดโปรเจกต์นี้ใน Claude Code')}`);[cite: 4]
      console.log(`  3. เริ่มต้นสร้างสรรค์โดยใช้ Slash Commands เหล่านี้:`);[cite: 4]

      console.log('\n' + chalk.yellow('     📝 ระเบียบวิธีคิด 7 ขั้นตอน (Seven-step Methodology):'));[cite: 4]
      console.log(`     ${chalk.cyan('/constitution')} - สร้างธรรมนูญการเขียน เพื่อกำหนดหลักการสำคัญ`);[cite: 4]
      console.log(`     ${chalk.cyan('/specify')}      - กำหนดรายละเอียดของเรื่อง ระบุสิ่งที่จะสร้างให้ชัดเจน`);[cite: 4]
      console.log(`     ${chalk.cyan('/clarify')}      - คลี่คลายจุดตัดสินใจสำคัญและจุดที่ยังคลุมเครือ`);[cite: 4]
      console.log(`     ${chalk.cyan('/plan')}         - วางแผนทางเทคนิค กำหนดแนวทางการสร้างสรรค์`);[cite: 4]
      console.log(`     ${chalk.cyan('/tasks')}        - แยกย่อยงานปฏิบัติการ สร้างรายการที่ลงมือทำได้จริง`);[cite: 4]
      console.log(`     ${chalk.cyan('/write')}        - ใช้ AI ช่วยเขียนเนื้อหาในแต่ละบท`);[cite: 4]
      console.log(`     ${chalk.cyan('/analyze')}      - วิเคราะห์และตรวจสอบภาพรวม เพื่อรักษาคุณภาพให้สอดคล้องกัน`);[cite: 4]

      console.log('\n' + chalk.yellow('     📊 คำสั่งจัดการและติดตามผล (Tracking Management):'));[cite: 4]
      console.log(`     ${chalk.cyan('/track-init')}  - เริ่มต้นระบบติดตามผล`);[cite: 4]
      console.log(`     ${chalk.cyan('/track')}       - อัปเดตการติดตามภาพรวม`);[cite: 4]
      console.log(`     ${chalk.cyan('/plot-check')}  - ตรวจสอบความสอดคล้องของพล็อตเรื่อง`);[cite: 4]
      console.log(`     ${chalk.cyan('/timeline')}    - จัดการเส้นเวลา (Timeline) ของเรื่อง`);[cite: 4]

      console.log('\n' + chalk.gray('Agent Skills จะเปิดใช้งานโดยอัตโนมัติ ไม่จำเป็นต้องเรียกใช้ด้วยตนเอง'));[cite: 4]
      console.log(chalk.dim('คำแนะนำ: Slash Commands มีไว้ใช้ภายใน Claude Code ไม่ใช่บนเทอร์มินัลปกติ'));[cite: 4]

    } catch (error) {
      spinner.fail(chalk.red('การเริ่มต้นสร้างโปรเจกต์ล้มเหลว'));[cite: 4]
      console.error(error);
      process.exit(1);
    }
  });

// คำสั่ง check - ตรวจสอบสภาพแวดล้อมระบบ
program
  .command('check')
  .description('ตรวจสอบสภาพแวดล้อมระบบและ Claude Code')[cite: 4]
  .action(() => {
    console.log(chalk.cyan('กำลังตรวจสอบสภาพแวดล้อมระบบ...\n'));[cite: 4]

    const checks = [
      { name: 'Node.js', command: 'node --version', installed: false },
      { name: 'Git', command: 'git --version', installed: false }
    ];

    checks.forEach(check => {
      try {
        const version = execSync(check.command, { encoding: 'utf-8' }).trim();
        check.installed = true;
        console.log(chalk.green('✓') + ` ${check.name} ติดตั้งแล้ว (${version})`);[cite: 4]
      } catch {
        console.log(chalk.yellow('⚠') + ` ${check.name} ยังไม่ได้ติดตั้ง`);[cite: 4]
      }
    });

    console.log('\n' + chalk.cyan('การตรวจหา Claude Code:'));[cite: 4]
    console.log(chalk.gray('โปรดตรวจสอบให้แน่ใจว่าได้ติดตั้ง Claude Code และสามารถใช้งานได้ตามปกติ'));[cite: 4]
    console.log(chalk.gray('ลิงก์ดาวน์โหลด: https://claude.ai/download'));[cite: 4]

    console.log('\n' + chalk.green('ตรวจสอบสภาพแวดล้อมเสร็จสิ้น!'));[cite: 4]
  });

// คำสั่ง plugin - การจัดการปลั๊กอิน
program
  .command('plugin')
  .description('จัดการปลั๊กอิน (โปรดใช้คำสั่ง plugin:list, plugin:add, plugin:remove)')[cite: 4]
  .action(() => {
    console.log(chalk.cyan('\n📦 คำสั่งจัดการปลั๊กอิน:\n'));[cite: 4]
    console.log('  novelwrite plugin:list              - แสดงรายการปลั๊กอินที่ติดตั้งแล้ว');[cite: 4]
    console.log('  novelwrite plugin:add <name>        - ติดตั้งปลั๊กอิน');[cite: 4]
    console.log('  novelwrite plugin:remove <name>     - ลบปลั๊กอินออก');[cite: 4]
    console.log('\n' + chalk.gray('ปลั๊กอินที่พร้อมใช้งาน:'));[cite: 4]
    console.log('  authentic-voice   - ปลั๊กอินสำหรับการเขียนด้วยน้ำเสียงมนุษย์ที่สมจริง (Authentic Voice)');[cite: 4]
  });

program
  .command('plugin:list')
  .description('แสดงรายการปลั๊กอินที่ติดตั้งแล้ว')[cite: 4]
  .action(async () => {
    try {
      const projectPath = await ensureProjectRoot();
      const projectInfo = await getProjectInfo(projectPath);

      if (!projectInfo) {
        console.log(chalk.red('❌ ไม่สามารถอ่านข้อมูลโปรเจกต์ได้'));[cite: 4]
        process.exit(1);
      }

      const pluginManager = new PluginManager(projectPath);
      const plugins = await pluginManager.listPlugins();

      console.log(chalk.cyan('\n📦 ปลั๊กอินที่ติดตั้งแล้ว\n'));[cite: 4]
      console.log(chalk.gray(`โปรเจกต์: ${path.basename(projectPath)}\n`));[cite: 4]

      if (plugins.length === 0) {
        console.log(chalk.yellow('ยังไม่มีปลั๊กอินติดตั้งอยู่'));[cite: 4]
        console.log(chalk.gray('\nใช้งาน "novelwrite plugin:add <name>" เพื่อติดตั้งปลั๊กอิน'));[cite: 4]
        console.log(chalk.gray('ปลั๊กอินที่พร้อมใช้งาน: authentic-voice\n'));[cite: 4]
        return;
      }

      for (const plugin of plugins) {
        console.log(chalk.yellow(`  ${plugin.name}`) + ` (v${plugin.version})`);[cite: 4]
        console.log(chalk.gray(`    ${plugin.description}`));[cite: 4]

        if (plugin.commands && plugin.commands.length > 0) {
          console.log(chalk.gray(`    คำสั่ง: ${plugin.commands.map(c => `/${c.id}`).join(', ')}`));[cite: 4]
        }

        if (plugin.skills && plugin.skills.length > 0) {
          console.log(chalk.gray(`    Skills: ${plugin.skills.map(s => s.id).join(', ')}`));[cite: 4]
        }
        console.log('');
      }
    } catch (error: any) {
      if (error.message === 'NOT_IN_PROJECT') {
        console.log(chalk.red('\n❌ ไดเรกทอรีปัจจุบันไม่ใช่โปรเจกต์ของ novelwrite'));[cite: 4]
        console.log(chalk.gray('   กรุณารันคำสั่งนี้ที่โฟลเดอร์หลักของโปรเจกต์ (Root Directory)\n'));[cite: 4]
        process.exit(1);
      }

      console.error(chalk.red('❌ แสดงรายการปลั๊กอินล้มเหลว:'), error);[cite: 4]
      process.exit(1);
    }
  });

program
  .command('plugin:add <name>')
  .description('ติดตั้งปลั๊กอิน')[cite: 4]
  .action(async (name) => {
    try {
      const projectPath = await ensureProjectRoot();
      const projectInfo = await getProjectInfo(projectPath);

      if (!projectInfo) {
        console.log(chalk.red('❌ ไม่สามารถอ่านข้อมูลโปรเจกต์ได้'));[cite: 4]
        process.exit(1);
      }

      console.log(chalk.cyan('\n📦 การติดตั้งปลั๊กอิน NovelWrite\n'));[cite: 4]
      console.log(chalk.gray(`เวอร์ชันโปรเจกต์: ${projectInfo.version}\n`));[cite: 4]

      const packageRoot = path.resolve(__dirname, '..');
      const builtinPluginPath = path.join(packageRoot, 'plugins', name);

      if (!await fs.pathExists(builtinPluginPath)) {
        console.log(chalk.red(`❌ ไม่พบปลั๊กอินชื่อ ${name}\n`));[cite: 4]
        console.log(chalk.gray('ปลั๊กอินที่พร้อมใช้งาน:'));[cite: 4]
        console.log(chalk.gray('  - authentic-voice (ปลั๊กอินเสียงมนุษย์ที่สมจริง)'));[cite: 4]
        process.exit(1);
      }

      const spinner = ora('กำลังติดตั้งปลั๊กอิน...').start();[cite: 4]
      const pluginManager = new PluginManager(projectPath);

      await pluginManager.installPlugin(name, builtinPluginPath);
      spinner.succeed(chalk.green('ติดตั้งปลั๊กอินสำเร็จเรียบร้อยแล้ว!\n'));[cite: 4]

    } catch (error: any) {
      if (error.message === 'NOT_IN_PROJECT') {
        console.log(chalk.red('\n❌ ไดเรกทอรีปัจจุบันไม่ใช่โปรเจกต์ของ novelwrite'));[cite: 4]
        console.log(chalk.gray('   กรุณารันคำสั่งนี้ที่โฟลเดอร์หลักของโปรเจกต์ (Root Directory)\n'));[cite: 4]
        process.exit(1);
      }

      console.log(chalk.red('\n❌ ติดตั้งปลั๊กอินล้มเหลว'));[cite: 4]
      console.error(chalk.gray(error.message || error));
      console.log('');
      process.exit(1);
    }
  });

program
  .command('plugin:remove <name>')
  .description('ลบปลั๊กอินออก')[cite: 4]
  .action(async (name) => {
    try {
      const projectPath = await ensureProjectRoot();
      const pluginManager = new PluginManager(projectPath);

      console.log(chalk.cyan('\n📦 การลบปลั๊กอิน NovelWrite\n'));[cite: 4]
      console.log(chalk.gray(`เตรียมการลบปลั๊กอิน: ${name}\n`));[cite: 4]

      const spinner = ora('กำลังลบปลั๊กอิน...').start();[cite: 4]
      await pluginManager.removePlugin(name);
      spinner.succeed(chalk.green('ลบปลั๊กอินสำเร็จเรียบร้อยแล้ว!\n'));[cite: 4]
    } catch (error: any) {
      if (error.message === 'NOT_IN_PROJECT') {
        console.log(chalk.red('\n❌ ไดเรกทอรีปัจจุบันไม่ใช่โปรเจกต์ของ novelwrite'));[cite: 4]
        console.log(chalk.gray('   กรุณารันคำสั่งนี้ที่โฟลเดอร์หลักของโปรเจกต์ (Root Directory)\n'));[cite: 4]
        process.exit(1);
      }

      console.log(chalk.red('\n❌ ลบปลั๊กอินล้มเหลว'));[cite: 4]
      console.error(chalk.gray(error.message || error));
      console.log('');
      process.exit(1);
    }
  });

// คำสั่ง upgrade - อัปเกรดโปรเจกต์ปัจจุบัน
program
  .command('upgrade')
  .option('--commands', 'อัปเดตไฟล์คำสั่ง')[cite: 4]
  .option('--skills', 'อัปเดตไฟล์ทักษะ (Skills)')[cite: 4]
  .option('--knowledge-base', 'อัปเดตระบบคลังความรู้')[cite: 4]
  .option('--all', 'อัปเดตเนื้อหาทั้งหมด')[cite: 4]
  .option('-y, --yes', 'ข้ามขั้นตอนการกดยืนยัน')[cite: 4]
  .description('อัปเกรดโปรเจกต์ปัจจุบันเป็นเวอร์ชันล่าสุด处理')[cite: 4]
  .action(async (options) => {
    const projectPath = process.cwd();
    const packageRoot = path.resolve(__dirname, '..');

    try {
      const configPath = path.join(projectPath, '.specify', 'config.json');
      if (!await fs.pathExists(configPath)) {
        console.log(chalk.red('❌ ไดเรกทอรีปัจจุบันไม่ใช่โปรเจกต์ของ novel-writer-skills'));[cite: 4]
        process.exit(1);
      }

      const config = await fs.readJson(configPath);
      const projectVersion = config.version || 'ไม่ระบุ';[cite: 4]

      console.log(chalk.cyan('\n📦 การอัปเกรดโปรเจกต์ NovelWrite\n'));[cite: 4]
      console.log(chalk.gray(`เวอร์ชันปัจจุบัน: ${projectVersion}`));[cite: 4]
      console.log(chalk.gray(`เวอร์ชันเป้าหมาย: ${getVersion()}\n`));[cite: 4]

      let updateCommands = options.all || options.commands || false;
      let updateSkills = options.all || options.skills || false;
      let updateKnowledgeBase = options.all || options.knowledgeBase || false;

      if (!updateCommands && !updateSkills && !updateKnowledgeBase) {
        updateCommands = true;
        updateSkills = true;
        updateKnowledgeBase = true;
      }

      if (!options.yes) {
        const inquirer = (await import('inquirer')).default;
        const answers = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'proceed',
            message: 'คุณยืนยันที่จะดำเนินการอัปเกรดหรือไม่?',[cite: 4]
            default: true
          }
        ]);

        if (!answers.proceed) {
          console.log(chalk.yellow('\nยกเลิกการอัปเกรดแล้ว'));[cite: 4]
          process.exit(0);
        }
      }

      const spinner = ora('กำลังอัปเกรดโปรเจกต์...').start();[cite: 4]

      if (updateCommands) {
        spinner.text = 'กำลังอัปเดต Slash Commands...';[cite: 4]
        const commandsSource = path.join(packageRoot, 'templates', 'commands');
        const commandsDest = path.join(projectPath, '.claude', 'commands');
        if (await fs.pathExists(commandsSource)) {
          await fs.copy(commandsSource, commandsDest, { overwrite: true });
        }
      }

      if (updateSkills) {
        spinner.text = 'กำลังอัปเดต Agent Skills...';[cite: 4]
        const skillsSource = path.join(packageRoot, 'templates', 'skills');
        const skillsDest = path.join(projectPath, '.claude', 'skills');
        if (await fs.pathExists(skillsSource)) {
          await fs.copy(skillsSource, skillsDest, { overwrite: true });
        }
      }

      if (updateKnowledgeBase) {
        spinner.text = 'กำลังอัปเดตระบบคลังความรู้...';[cite: 4]
        const knowledgeBaseSource = path.join(packageRoot, 'templates', 'knowledge-base');
        const knowledgeBaseDest = path.join(projectPath, '.claude', 'knowledge-base');
        if (await fs.pathExists(knowledgeBaseSource)) {
          await fs.copy(knowledgeBaseSource, knowledgeBaseDest, { overwrite: true });
        }
      }

      config.version = getVersion();
      await fs.writeJson(configPath, config, { spaces: 2 });

      spinner.succeed(chalk.green('อัปเกรดเสร็จสิ้นเรียบร้อยแล้ว!\n'));[cite: 4]

      console.log(chalk.cyan('✨ รายการอัปเกรด:'));[cite: 4]
      if (updateCommands) console.log('  • อัปเดต Slash Commands เรียบร้อยแล้ว');[cite: 4]
      if (updateSkills) console.log('  • อัปเดต Agent Skills เรียบร้อยแล้ว');[cite: 4]
      if (updateKnowledgeBase) console.log('  • อัปเดตระบบคลังความรู้เรียบร้อยแล้ว (รวมถึงโฟลเดอร์ styles/ และ requirements/)');[cite: 4]
      console.log(`  • หมายเลขเวอร์ชันเปลี่ยนจาก: ${projectVersion} → ${getVersion()}`);[cite: 4]

    } catch (error) {
      console.error(chalk.red('\n❌ การอัปเกรดล้มเหลว:'), error);[cite: 4]
      process.exit(1);
    }
  });

// กำหนดข้อความช่วยเหลือเพิ่มเติม (Custom Help Information)
program.on('--help', () => {
  console.log('');
  console.log(chalk.yellow('ตัวอย่างการใช้งาน:'));[cite: 4]
  console.log('');
  console.log('  $ novelwrite init my-story      # สร้างโปรเจกต์ใหม่');[cite: 4]
  console.log('  $ novelwrite init --here        # เริ่มต้นโปรเจกต์ในไดเรกทอรีปัจจุบัน');[cite: 4]
  console.log('  $ novelwrite check              # ตรวจสอบสภาพแวดล้อมระบบ');[cite: 4]
  console.log('  $ novelwrite plugin:list        # แสดงรายการปลั๊กอิน');[cite: 4]
  console.log('');
  console.log(chalk.gray('ดูข้อมูลเพิ่มเติมได้ที่: https://github.com/wordflowlab/novel-writer-skills'));[cite: 4]
});

// ประมวลผลอาร์กิวเมนต์จากบรรทัดคำสั่ง
program.parse(process.argv);

// หากไม่มีคำสั่งใดๆ ระบุเข้ามา ให้แสดงข้อความช่วยเหลือ
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
