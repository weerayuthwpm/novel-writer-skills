import fs from 'fs-extra';
import path from 'path';
import yaml from 'js-yaml';
import { logger } from '../utils/logger.js';

interface PluginConfig {
  name: string;
  version: string;
  description: string;
  type: 'feature' | 'expert' | 'workflow';
  commands?: Array<{
    id: string;
    file: string;
    description: string;
  }>;
  skills?: Array<{
    id: string;
    file: string;
    description: string;
  }>;
  dependencies?: {
    core: string;
  };
  installation?: {
    message?: string;
  };
}

export class PluginManager {
  private pluginsDir: string;
  private commandsDir: string;
  private skillsDir: string;

  constructor(projectRoot: string) {
    this.pluginsDir = path.join(projectRoot, 'plugins');
    this.commandsDir = path.join(projectRoot, '.claude', 'commands');
    this.skillsDir = path.join(projectRoot, '.claude', 'skills');
  }

  /**
   * สแกนและโหลดปลั๊กอินทั้งหมด
   */
  async loadPlugins(): Promise<void> {
    try {
      await fs.ensureDir(this.pluginsDir);
      const plugins = await this.scanPlugins();

      if (plugins.length === 0) {
        logger.info('ไม่พบปลั๊กอิน');
        return;
      }

      logger.info(`พบปลั๊กอินทั้งหมด ${plugins.length} ตัว`);

      for (const pluginName of plugins) {
        await this.loadPlugin(pluginName);
      }

      logger.success('โหลดปลั๊กอินทั้งหมดเสร็จสิ้น');
    } catch (error) {
      logger.error('โหลดปลั๊กอินล้มเหลว:', error);
    }
  }

  /**
   * สแกนไดเรกทอรีของปลั๊กอิน
   */
  private async scanPlugins(): Promise<string[]> {
    try {
      if (!await fs.pathExists(this.pluginsDir)) {
        return [];
      }

      const entries = await fs.readdir(this.pluginsDir, { withFileTypes: true });
      const plugins = [];

      for (const entry of entries) {
        if (entry.isDirectory()) {
          const configPath = path.join(this.pluginsDir, entry.name, 'config.yaml');
          if (await fs.pathExists(configPath)) {
            plugins.push(entry.name);
          }
        }
      }

      return plugins;
    } catch (error) {
      logger.error('สแกนไดเรกทอรีปลั๊กอินล้มเหลว:', error);
      return [];
    }
  }

  /**
   * โหลดปลั๊กอินทีละตัว
   */
  private async loadPlugin(pluginName: string): Promise<void> {
    try {
      logger.info(`กำลังโหลดปลั๊กอิน: ${pluginName}`);

      const configPath = path.join(this.pluginsDir, pluginName, 'config.yaml');
      const config = await this.loadConfig(configPath);

      if (!config) {
        logger.warn(`การตั้งค่าของปลั๊กอิน ${pluginName} ไม่ถูกต้อง`);
        return;
      }

      // แทรกคำสั่ง (Inject Commands)
      if (config.commands && config.commands.length > 0) {
        await this.injectCommands(pluginName, config.commands);
      }

      // แทรกทักษะ (Inject Skills)
      if (config.skills && config.skills.length > 0) {
        await this.injectSkills(pluginName, config.skills);
      }

      logger.success(`โหลดปลั๊กอิน ${pluginName} สำเร็จเรียบร้อยแล้ว`);

      if (config.installation?.message) {
        console.log(config.installation.message);
      }
    } catch (error) {
      logger.error(`โหลดปลั๊กอิน ${pluginName} ล้มเหลว:`, error);
    }
  }

  /**
   * อ่านไฟล์ตั้งค่าของปลั๊กอิน
   */
  private async loadConfig(configPath: string): Promise<PluginConfig | null> {
    try {
      const content = await fs.readFile(configPath, 'utf-8');
      const config = yaml.load(content) as PluginConfig;

      if (!config.name || !config.version) {
        return null;
      }

      return config;
    } catch (error) {
      logger.error(`อ่านไฟล์ตั้งค่าล้มเหลว: ${configPath}`, error);
      return null;
    }
  }

  /**
   * แทรกคำสั่งของปลั๊กอิน (Inject Plugin Commands)
   */
  private async injectCommands(
    pluginName: string,
    commands: PluginConfig['commands']
  ): Promise<void> {
    if (!commands) return;

    for (const cmd of commands) {
      try {
        const sourcePath = path.join(this.pluginsDir, pluginName, cmd.file);
        const destPath = path.join(this.commandsDir, `${cmd.id}.md`);

        await fs.ensureDir(this.commandsDir);
        await fs.copy(sourcePath, destPath);
        logger.debug(`แทรกคำสั่งสำเร็จ: /${cmd.id}`);
      } catch (error) {
        logger.error(`แทรกคำสั่ง ${cmd.id} ล้มเหลว:`, error);
      }
    }
  }

  /**
   * แทรกทักษะของปลั๊กอิน (Inject Plugin Skills)
   */
  private async injectSkills(
    pluginName: string,
    skills: PluginConfig['skills']
  ): Promise<void> {
    if (!skills) return;

    for (const skill of skills) {
      try {
        const sourcePath = path.join(this.pluginsDir, pluginName, skill.file);
        const destPath = path.join(this.skillsDir, pluginName, path.basename(skill.file));

        await fs.ensureDir(path.dirname(destPath));
        await fs.copy(sourcePath, destPath);
        logger.debug(`แทรก Skill สำเร็จ: ${skill.id}`);
      } catch (error) {
        logger.error(`แทรก Skill ${skill.id} ล้มเหลว:`, error);
      }
    }
  }

  /**
   * แสดงรายการปลั๊กอินทั้งหมดที่ติดตั้งไว้
   */
  async listPlugins(): Promise<PluginConfig[]> {
    const plugins = await this.scanPlugins();
    const configs: PluginConfig[] = [];

    for (const pluginName of plugins) {
      const configPath = path.join(this.pluginsDir, pluginName, 'config.yaml');
      const config = await this.loadConfig(configPath);
      if (config) {
        configs.push(config);
      }
    }

    return configs;
  }

  /**
   * ติดตั้งปลั๊กอิน
   */
  async installPlugin(pluginName: string, source?: string): Promise<void> {
    try {
      logger.info(`กำลังติดตั้งปลั๊กอิน: ${pluginName}`);

      if (source) {
        const destPath = path.join(this.pluginsDir, pluginName);
        await fs.copy(source, destPath);
      } else {
        logger.warn('ระบบยังไม่รองรับฟังก์ชันการติดตั้งจากระยะไกล (Remote Installation)');
        return;
      }

      await this.loadPlugin(pluginName);
      logger.success(`ติดตั้งปลั๊กอิน ${pluginName} สำเร็จเรียบร้อยแล้ว`);
    } catch (error) {
      logger.error(`ติดตั้งปลั๊กอิน ${pluginName} ล้มเหลว:`, error);
      throw error;
    }
  }

  /**
   * ลบปลั๊กอินออก
   */
  async removePlugin(pluginName: string): Promise<void> {
    try {
      logger.info(`กำลังลบปลั๊กอิน: ${pluginName}`);

      // ลบไดเรกทอรีของปลั๊กอิน
      const pluginPath = path.join(this.pluginsDir, pluginName);
      await fs.remove(pluginPath);

      // ลบคำสั่งที่เคยแทรกไว้
      if (await fs.pathExists(this.commandsDir)) {
        const commandFiles = await fs.readdir(this.commandsDir);
        for (const file of commandFiles) {
          // ส่วนนี้เป็นการประมวลผลแบบย่อ ในความเป็นจริงควรอ่านไฟล์ตั้งค่าของปลั๊กอินเพื่อระบุไฟล์ที่จะลบให้ชัดเจน
          // ชั่วคราวนี้ขอข้ามไปก่อน เนื่องจากจำเป็นต้องทราบว่าคำสั่งใดบ้างที่เป็นของปลั๊กอินตัวนี้
        }
      }

      // ลบทักษะ (Skills) ที่เคยแทรกไว้
      const pluginSkillsDir = path.join(this.skillsDir, pluginName);
      if (await fs.pathExists(pluginSkillsDir)) {
        await fs.remove(pluginSkillsDir);
      }

      logger.success(`ลบปลั๊กอิน ${pluginName} สำเร็จเรียบร้อยแล้ว`);
    } catch (error) {
      logger.error(`ลบปลั๊กอิน ${pluginName} ล้มเหลว:`, error);
      throw error;
    }
  }
}
