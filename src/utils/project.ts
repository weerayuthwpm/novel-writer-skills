import fs from 'fs-extra';
import path from 'path';

export interface ProjectInfo {
  name: string;
  version: string;
  hasClaudeDir: boolean;
  hasSpecifyDir: boolean;
  hasStoriesDir: boolean;
}

/**
 * ตรวจสอบว่าไดเรกทอรีปัจจุบันเป็นโฟลเดอร์หลัก (Root) ของโปรเจกต์ novel-writer-skills หรือไม่
 */
export async function isProjectRoot(dir: string): Promise<boolean> {
  const configPath = path.join(dir, '.specify', 'config.json');
  return await fs.pathExists(configPath);
}

/**
 * ค้นหาโฟลเดอร์หลัก (Root) ของโปรเจกต์ โดยไล่หาขึ้นไปตามลำดับชั้นของไดเรกทอรี
 */
export async function findProjectRoot(startDir: string = process.cwd()): Promise<string | null> {
  let currentDir = startDir;
  
  while (true) {
    if (await isProjectRoot(currentDir)) {
      return currentDir;
    }
    
    const parentDir = path.dirname(currentDir);
    
    // ค้นหาจนถึงบนสุดของระบบไฟล์ (File System Root) แล้ว
    if (parentDir === currentDir) {
      return null;
    }
    
    currentDir = parentDir;
  }
}

/**
 * ตรวจสอบให้แน่ใจว่าทำงานอยู่ในโฟลเดอร์หลักของโปรเจกต์ หากไม่ใช่จะทำการโยนข้อผิดพลาด (Throw Error) ออกไป
 */
export async function ensureProjectRoot(): Promise<string> {
  const projectRoot = await findProjectRoot();
  
  if (!projectRoot) {
    throw new Error('NOT_IN_PROJECT');
  }
  
  return projectRoot;
}

/**
 * ดึงข้อมูลรายละเอียดของโปรเจกต์
 */
export async function getProjectInfo(projectPath: string): Promise<ProjectInfo | null> {
  try {
    const configPath = path.join(projectPath, '.specify', 'config.json');
    
    if (!await fs.pathExists(configPath)) {
      return null;
    }
    
    const config = await fs.readJson(configPath);
    
    return {
      name: config.name || path.basename(projectPath),
      version: config.version || 'unknown',
      hasClaudeDir: await fs.pathExists(path.join(projectPath, '.claude')),
      hasSpecifyDir: await fs.pathExists(path.join(projectPath, '.specify')),
      hasStoriesDir: await fs.pathExists(path.join(projectPath, 'stories'))
    };
  } catch {
    return null;
  }
}
