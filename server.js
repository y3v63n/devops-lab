const express = require('express');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const app = express();
const PORT = 3333;
const MODULES_DIR = path.join(__dirname, 'modules');
const PROGRESS_FILE = path.join(__dirname, 'progress.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'site')));

// --- Helper functions ---

function readProgress() {
  try {
    return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf-8'));
  } catch {
    return { exercises: {}, started_at: null, last_activity: null };
  }
}

function writeProgress(data) {
  data.last_activity = new Date().toISOString();
  if (!data.started_at) data.started_at = data.last_activity;
  fs.writeFileSync(PROGRESS_FILE, JSON.stringify(data, null, 2));
}

function sanitizeParam(p) {
  if (!p || p.includes('..') || p.includes('/') || p.includes('\\')) return null;
  return p;
}

function getExercisePath(moduleId, sectionId, exerciseId) {
  const m = sanitizeParam(moduleId);
  const s = sanitizeParam(sectionId);
  const e = sanitizeParam(exerciseId);
  if (!m || !s || !e) return null;
  const resolved = path.resolve(MODULES_DIR, m, s, e);
  if (!resolved.startsWith(MODULES_DIR + path.sep)) return null;
  return resolved;
}

function scanModules() {
  const modules = [];
  if (!fs.existsSync(MODULES_DIR)) return modules;

  const moduleDirs = fs.readdirSync(MODULES_DIR)
    .filter(d => fs.statSync(path.join(MODULES_DIR, d)).isDirectory())
    .sort();

  for (const moduleDir of moduleDirs) {
    const modulePath = path.join(MODULES_DIR, moduleDir);
    const moduleJson = path.join(modulePath, 'module.json');
    let moduleMeta = { title: moduleDir, description: '' };
    if (fs.existsSync(moduleJson)) {
      moduleMeta = JSON.parse(fs.readFileSync(moduleJson, 'utf-8'));
    }

    const sections = [];
    const sectionDirs = fs.readdirSync(modulePath)
      .filter(d => fs.statSync(path.join(modulePath, d)).isDirectory())
      .sort();

    for (const sectionDir of sectionDirs) {
      const sectionPath = path.join(modulePath, sectionDir);
      const sectionJson = path.join(sectionPath, 'section.json');
      let sectionMeta = { title: sectionDir, description: '' };
      if (fs.existsSync(sectionJson)) {
        sectionMeta = JSON.parse(fs.readFileSync(sectionJson, 'utf-8'));
      }

      const exercises = [];
      const exerciseDirs = fs.readdirSync(sectionPath)
        .filter(d => fs.statSync(path.join(sectionPath, d)).isDirectory())
        .sort();

      for (const exDir of exerciseDirs) {
        const exPath = path.join(sectionPath, exDir);
        const hasLesson = fs.existsSync(path.join(exPath, 'lesson.md'));
        const hasVerify = fs.existsSync(path.join(exPath, 'verify.sh'));
        if (hasLesson) {
          exercises.push({
            id: `${moduleDir}/${sectionDir}/${exDir}`,
            dirName: exDir,
            title: exDir.replace(/^\d+-/, '').replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
            hasVerify,
            hasReset: fs.existsSync(path.join(exPath, 'reset.sh')),
            hasHint: fs.existsSync(path.join(exPath, 'hint.md')),
          });
        }
      }

      if (exercises.length > 0) {
        sections.push({ dirName: sectionDir, ...sectionMeta, exercises });
      }
    }

    modules.push({ dirName: moduleDir, ...moduleMeta, noAiRule: moduleMeta.noAiRule || false, sections });
  }

  return modules;
}

// --- API Routes ---

app.get('/api/modules', (req, res) => {
  const modules = scanModules();
  const progress = readProgress();
  res.json({ modules, progress });
});

app.get('/api/exercise/:moduleId/:sectionId/:exerciseId/lesson', (req, res) => {
  const { moduleId, sectionId, exerciseId } = req.params;
  const exDir = getExercisePath(moduleId, sectionId, exerciseId);
  if (!exDir) return res.status(400).json({ error: 'Invalid parameters' });
  const lessonPath = path.join(exDir, 'lesson.md');
  if (!fs.existsSync(lessonPath)) return res.status(404).json({ error: 'Lesson not found' });
  res.json({ content: fs.readFileSync(lessonPath, 'utf-8') });
});

app.get('/api/exercise/:moduleId/:sectionId/:exerciseId/hint', (req, res) => {
  const { moduleId, sectionId, exerciseId } = req.params;
  const exDir = getExercisePath(moduleId, sectionId, exerciseId);
  if (!exDir) return res.status(400).json({ error: 'Invalid parameters' });
  const hintPath = path.join(exDir, 'hint.md');
  if (!fs.existsSync(hintPath)) return res.status(404).json({ error: 'No hints available' });
  res.json({ content: fs.readFileSync(hintPath, 'utf-8') });
});

app.post('/api/exercise/:moduleId/:sectionId/:exerciseId/verify', (req, res) => {
  const { moduleId, sectionId, exerciseId } = req.params;
  const exDir = getExercisePath(moduleId, sectionId, exerciseId);
  if (!exDir) return res.status(400).json({ error: 'Invalid parameters' });
  const verifyPath = path.join(exDir, 'verify.sh');
  if (!fs.existsSync(verifyPath)) return res.status(404).json({ error: 'No verification script' });

  execFile('bash', [verifyPath], { timeout: 30000, env: { ...process.env, LAB_DIR: path.join(__dirname) } }, (error, stdout, stderr) => {
    const passed = !error;
    if (passed) {
      const progress = readProgress();
      const exercisePath = `${moduleId}/${sectionId}/${exerciseId}`;
      progress.exercises[exercisePath] = { completed: true, completed_at: new Date().toISOString() };
      writeProgress(progress);
    }
    res.json({ passed, output: stdout || stderr || (passed ? 'All checks passed!' : 'Verification failed.') });
  });
});

app.post('/api/exercise/:moduleId/:sectionId/:exerciseId/reset', (req, res) => {
  const { moduleId, sectionId, exerciseId } = req.params;
  const exDir = getExercisePath(moduleId, sectionId, exerciseId);
  if (!exDir) return res.status(400).json({ error: 'Invalid parameters' });
  const resetPath = path.join(exDir, 'reset.sh');
  if (!fs.existsSync(resetPath)) return res.status(404).json({ error: 'No reset script' });

  execFile('bash', [resetPath], { timeout: 30000, env: { ...process.env, LAB_DIR: path.join(__dirname) } }, (error, stdout, stderr) => {
    if (!error) {
      const progress = readProgress();
      const exercisePath = `${moduleId}/${sectionId}/${exerciseId}`;
      delete progress.exercises[exercisePath];
      writeProgress(progress);
    }
    res.json({ success: !error, output: stdout || stderr || 'Reset complete.' });
  });
});

app.get('/api/progress', (req, res) => {
  res.json(readProgress());
});

app.post('/api/progress/*', (req, res) => {
  const exercisePath = req.params[0];
  if (!exercisePath || exercisePath.includes('..')) return res.status(400).json({ error: 'Invalid path' });
  const progress = readProgress();
  const completed = req.body.completed === true;
  if (completed) {
    progress.exercises[exercisePath] = { completed: true, completed_at: new Date().toISOString() };
  } else {
    delete progress.exercises[exercisePath];
  }
  writeProgress(progress);
  res.json({ ok: true });
});

app.get('/api/cheatsheet/:moduleId', (req, res) => {
  const m = sanitizeParam(req.params.moduleId);
  if (!m) return res.status(400).json({ error: 'Invalid parameters' });
  const cheatPath = path.resolve(MODULES_DIR, m, 'cheatsheet.md');
  if (!cheatPath.startsWith(MODULES_DIR + path.sep)) return res.status(400).json({ error: 'Invalid parameters' });
  if (!fs.existsSync(cheatPath)) return res.status(404).json({ error: 'No cheatsheet' });
  res.json({ content: fs.readFileSync(cheatPath, 'utf-8') });
});

// SPA fallback
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'site', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n  🔧 DevOps Lab running at http://localhost:${PORT}\n`);
});
