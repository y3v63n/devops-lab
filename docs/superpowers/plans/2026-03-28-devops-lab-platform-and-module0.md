# DevOps Learning Lab — Platform & Module 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a self-hosted, interactive DevOps learning platform with a web UI, CLI tool, and the complete Module 0 (Foundations Bootcamp — 25 exercises covering Linux, Bash, Docker, Git, and Terraform/OpenTofu).

**Architecture:** Node.js Express server renders markdown-based lesson content with a vanilla HTML/CSS/JS frontend. Progress is tracked in a local JSON file. A `lab-cli` bash script wraps verification/reset/hint operations. Each exercise lives in its own directory with `lesson.md`, `verify.sh`, `reset.sh`, and `hint.md`. Each lesson ends with a "What Just Happened" section explaining the concepts practiced. The web UI uses marked.js for markdown rendering and highlight.js for code blocks — no build step, no framework.

**Tech Stack:** Node.js 22 + Express, vanilla HTML/CSS/JS, marked.js, highlight.js, Bash scripts for CLI/verification

**Scope note:** This plan covers the platform infrastructure and Module 0 only. Modules 1-5 will be separate follow-up plans.

---

## File Structure

```
~/devops-lab/
├── setup.sh                          # One-command installer
├── README.md                         # Overview and getting started
├── lab-cli                           # CLI tool (bash script)
├── package.json                      # Node.js dependencies
├── progress.json                     # Exercise progress tracking
├── server.js                         # Express server (main entry)
├── site/
│   ├── index.html                    # Main SPA shell
│   ├── css/
│   │   └── style.css                 # All styles
│   ├── js/
│   │   ├── app.js                    # Main app logic (routing, rendering)
│   │   ├── progress.js               # Progress tracking client
│   │   └── vendor/
│   │       ├── marked.min.js         # Markdown renderer (bundled)
│   │       └── highlight.min.js      # Code highlighting (bundled)
│   └── assets/
│       └── highlight-github.css      # Highlight.js theme
├── modules/
│   └── 00-foundations/
│       ├── module.json               # Module metadata (title, description, sections)
│       ├── cheatsheet.md             # Quick reference for this module
│       ├── 0A-linux-sysadmin/
│       │   ├── section.json          # Section metadata
│       │   ├── 01-process-management/
│       │   │   ├── lesson.md         # Theory + task + interview questions
│       │   │   ├── verify.sh         # Verification script
│       │   │   ├── reset.sh          # Reset script
│       │   │   └── hint.md           # Collapsible hints
│       │   ├── 02-disk-storage/
│       │   │   ├── lesson.md
│       │   │   ├── verify.sh
│       │   │   ├── reset.sh
│       │   │   └── hint.md
│       │   └── ... (03-08)
│       ├── 0B-bash-scripting/
│       │   ├── section.json
│       │   ├── 01-variables-arguments/
│       │   │   ├── lesson.md
│       │   │   ├── verify.sh
│       │   │   ├── reset.sh
│       │   │   └── hint.md
│       │   └── ... (02-06)
│       ├── 0C-docker-deep-dive/
│       │   ├── section.json
│       │   └── ... (01-05)
│       ├── 0D-git-beyond-push-pull/
│       │   ├── section.json
│       │   └── ... (01-03)
│       └── 0E-terraform-opentofu/
│           ├── section.json
│           └── ... (01-03)
├── capstone-templates/
│   └── server-health-checker/        # Module 0 capstone starter
│       ├── README.md
│       └── health-check.sh           # Starter script skeleton
└── docs/
    └── superpowers/
        └── plans/                    # This plan lives here
```

## Key Design Decisions

1. **No build step.** The frontend is vanilla HTML/JS with vendor libs bundled as files. This keeps it offline-capable and simple.
2. **Express API.** The server provides REST endpoints for listing modules/exercises, reading lesson content, checking/updating progress, and running verify/reset scripts.
3. **Markdown-first content.** All lesson content is `.md` files rendered client-side with marked.js. Easy to edit.
4. **Progress as JSON.** A single `progress.json` maps exercise IDs to completion status. Both web UI and CLI read/write it.
5. **Verification scripts are bash.** Each `verify.sh` returns exit code 0 for pass, non-zero for fail, and prints human-readable output. The Express server executes them and returns results.
6. **Exercise IDs** follow the pattern `00-foundations/0A-linux-sysadmin/01-process-management`. This is also the filesystem path.

---

## Phase 1: Platform Infrastructure

### Task 1: Project Scaffolding and Package Setup

**Files:**
- Create: `~/devops-lab/package.json`
- Create: `~/devops-lab/progress.json`
- Create: `~/devops-lab/.gitignore`

- [ ] **Step 1: Create project directory and initialize**

```bash
cd ~/devops-lab
```

```json
// package.json
{
  "name": "devops-lab",
  "version": "1.0.0",
  "description": "Self-hosted interactive DevOps learning platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "express": "^4.21.0"
  }
}
```

- [ ] **Step 2: Create initial progress.json**

```json
{
  "exercises": {},
  "started_at": null,
  "last_activity": null
}
```

- [ ] **Step 3: Create .gitignore**

```
node_modules/
*.log
```

- [ ] **Step 4: Install dependencies**

Run: `cd ~/devops-lab && npm install`
Expected: `node_modules/` created with express installed

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab && git init && git add package.json package-lock.json progress.json .gitignore
git commit -m "feat: initialize devops-lab project with express"
```

---

### Task 2: Express Server with API Routes

**Files:**
- Create: `~/devops-lab/server.js`

- [ ] **Step 1: Write the Express server**

The server needs these endpoints:
- `GET /api/modules` — list all modules with sections and exercises
- `GET /api/exercise/:moduleId/:sectionId/:exerciseId/lesson` — read lesson.md content
- `GET /api/exercise/:moduleId/:sectionId/:exerciseId/hint` — read hint.md content
- `POST /api/exercise/:moduleId/:sectionId/:exerciseId/verify` — run verify.sh, return result
- `POST /api/exercise/:moduleId/:sectionId/:exerciseId/reset` — run reset.sh, return result
- `GET /api/progress` — return progress.json
- `POST /api/progress/:exercisePath` — mark exercise complete/incomplete
- `GET /api/cheatsheet/:moduleId` — return module cheatsheet
- Static files served from `site/`

```javascript
// server.js
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
  // Reject path traversal attempts
  if (!p || p.includes('..') || p.includes('/') || p.includes('\\')) return null;
  return p;
}

function getExercisePath(moduleId, sectionId, exerciseId) {
  const m = sanitizeParam(moduleId);
  const s = sanitizeParam(sectionId);
  const e = sanitizeParam(exerciseId);
  if (!m || !s || !e) return null;
  return path.join(MODULES_DIR, m, s, e);
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
  const cheatPath = path.join(MODULES_DIR, req.params.moduleId, 'cheatsheet.md');
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
```

- [ ] **Step 2: Test the server starts**

Run: `cd ~/devops-lab && timeout 3 node server.js 2>&1 || true`
Expected: Output contains "DevOps Lab running at http://localhost:3333"

- [ ] **Step 3: Commit**

```bash
git add server.js && git commit -m "feat: add Express server with module/exercise/progress API"
```

---

### Task 3: Web Interface — HTML Shell

**Files:**
- Create: `~/devops-lab/site/index.html`

- [ ] **Step 1: Create the SPA shell**

Single HTML file with:
- Sidebar for module/section/exercise navigation
- Main content area for lesson rendering
- Top bar with progress dashboard
- Action buttons (Verify, Reset, Hint, Mark Complete)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DevOps Lab</title>
  <link rel="stylesheet" href="/css/style.css">
  <link rel="stylesheet" href="/assets/highlight-github.css">
</head>
<body>
  <div id="app">
    <nav id="sidebar">
      <div class="sidebar-header">
        <h1>DevOps Lab</h1>
        <div id="progress-summary"></div>
      </div>
      <div id="module-nav"></div>
    </nav>

    <main id="content">
      <div id="dashboard-view" class="view">
        <h2>Dashboard</h2>
        <div id="dashboard-stats"></div>
        <div id="dashboard-modules"></div>
        <div id="next-exercise"></div>
      </div>

      <div id="exercise-view" class="view" style="display:none">
        <div id="exercise-header">
          <div id="breadcrumb"></div>
          <h2 id="exercise-title"></h2>
        </div>
        <div id="no-ai-banner" style="display:none">
          <strong>⚠ NO AI RULE:</strong> Do not use Claude, ChatGPT, or any AI assistant for this exercise. Use <code>man</code> pages, <code>--help</code> flags, and the cheatsheet. Build your recall.
        </div>
        <div id="lesson-content"></div>
        <div id="hint-section" style="display:none">
          <button id="hint-toggle" onclick="toggleHint()">Show Hint</button>
          <div id="hint-content" style="display:none"></div>
        </div>
        <div id="exercise-actions">
          <button id="btn-verify" onclick="verifyExercise()">Verify</button>
          <button id="btn-reset" onclick="resetExercise()">Reset</button>
          <button id="btn-cheatsheet" onclick="showCheatsheet()">Cheatsheet</button>
        </div>
        <div id="verify-result" style="display:none"></div>
        <div id="exercise-nav">
          <button id="btn-prev" onclick="navigatePrev()">← Previous</button>
          <button id="btn-next" onclick="navigateNext()">Next →</button>
        </div>
      </div>

      <div id="cheatsheet-view" class="view" style="display:none">
        <button onclick="hideCheatsheet()">← Back to Exercise</button>
        <div id="cheatsheet-content"></div>
      </div>
    </main>
  </div>

  <script src="/js/vendor/marked.min.js"></script>
  <script src="/js/vendor/highlight.min.js"></script>
  <script src="/js/progress.js"></script>
  <script src="/js/app.js"></script>
</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add site/index.html && git commit -m "feat: add HTML shell for web interface"
```

---

### Task 4: Download Vendor Libraries

**Files:**
- Create: `~/devops-lab/site/js/vendor/marked.min.js`
- Create: `~/devops-lab/site/js/vendor/highlight.min.js`
- Create: `~/devops-lab/site/assets/highlight-github.css`

- [ ] **Step 1: Download marked.js, highlight.js, and highlight CSS**

```bash
mkdir -p ~/devops-lab/site/js/vendor ~/devops-lab/site/assets
cd ~/devops-lab/site/js/vendor

# Download marked.js
curl -sL https://cdn.jsdelivr.net/npm/marked@12.0.1/marked.min.js -o marked.min.js

# Download highlight.js
curl -sL https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js -o highlight.min.js

# Download highlight.js GitHub theme
curl -sL https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css -o ../../assets/highlight-github.css
```

If `curl` fails (no internet), use `npm install marked highlight.js` and copy the built files from `node_modules/`.

- [ ] **Step 2: Verify files downloaded**

Run: `ls -la ~/devops-lab/site/js/vendor/ ~/devops-lab/site/assets/`
Expected: `marked.min.js`, `highlight.min.js`, and `highlight-github.css` all exist with non-zero sizes

- [ ] **Step 3: Commit**

```bash
cd ~/devops-lab && git add site/js/vendor/ site/assets/ && git commit -m "feat: add vendor libraries (marked.js, highlight.js)"
```

---

### Task 5: Web Interface — CSS

**Files:**
- Create: `~/devops-lab/site/css/style.css`

- [ ] **Step 1: Write styles**

Clean, dark-themed interface suitable for terminal-oriented learners. Key design:
- Dark background (#1a1a2e, #16213e), light text
- Sidebar: fixed left, 280px wide, scrollable module tree
- Main content: fluid, max-width 900px, good reading width
- Code blocks: styled with highlight.js theme
- Exercise status indicators: green checkmark for done, circle for pending
- Buttons: clear action colors (green for verify, orange for reset, blue for hint)
- Responsive: sidebar collapses on narrow screens
- No-AI banner: yellow warning bar

```css
/* Reset */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg-primary: #0d1117;
  --bg-secondary: #161b22;
  --bg-sidebar: #0d1117;
  --bg-card: #161b22;
  --bg-code: #1c2128;
  --text-primary: #e6edf3;
  --text-secondary: #8b949e;
  --text-muted: #6e7681;
  --border: #30363d;
  --accent-green: #3fb950;
  --accent-blue: #58a6ff;
  --accent-orange: #d29922;
  --accent-red: #f85149;
  --accent-purple: #bc8cff;
  --sidebar-width: 300px;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
}

#app {
  display: flex;
  min-height: 100vh;
}

/* Sidebar */
#sidebar {
  width: var(--sidebar-width);
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  overflow-y: auto;
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  z-index: 10;
}

.sidebar-header {
  padding: 20px;
  border-bottom: 1px solid var(--border);
}

.sidebar-header h1 {
  font-size: 1.3rem;
  color: var(--accent-blue);
  margin-bottom: 8px;
}

#progress-summary {
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.progress-bar {
  height: 6px;
  background: var(--border);
  border-radius: 3px;
  margin-top: 8px;
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  background: var(--accent-green);
  border-radius: 3px;
  transition: width 0.3s;
}

#module-nav {
  padding: 10px 0;
}

.nav-module {
  padding: 0;
}

.nav-module-title {
  padding: 10px 20px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-module-title:hover {
  color: var(--text-primary);
}

.nav-section {
  padding-left: 10px;
}

.nav-section-title {
  padding: 6px 20px;
  font-size: 0.8rem;
  color: var(--text-muted);
  font-weight: 600;
  cursor: pointer;
}

.nav-section-title:hover {
  color: var(--text-secondary);
}

.collapsed {
  display: none;
}

.nav-exercise {
  padding: 5px 20px 5px 35px;
  font-size: 0.85rem;
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  border-left: 2px solid transparent;
  transition: all 0.15s;
}

.nav-exercise:hover {
  color: var(--text-primary);
  background: var(--bg-secondary);
}

.nav-exercise.active {
  color: var(--accent-blue);
  border-left-color: var(--accent-blue);
  background: var(--bg-secondary);
}

.nav-exercise.completed .status-dot {
  color: var(--accent-green);
}

.status-dot {
  font-size: 0.7rem;
  flex-shrink: 0;
}

/* Main content */
#content {
  margin-left: var(--sidebar-width);
  flex: 1;
  padding: 30px 40px;
  max-width: calc(100% - var(--sidebar-width));
}

.view { max-width: 900px; }

/* Dashboard */
#dashboard-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin: 20px 0;
}

.stat-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 20px;
}

.stat-card .label {
  font-size: 0.8rem;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.stat-card .value {
  font-size: 2rem;
  font-weight: 700;
  margin-top: 4px;
}

.module-progress-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 20px;
  margin: 12px 0;
}

.module-progress-card h3 {
  font-size: 1rem;
  margin-bottom: 8px;
}

.module-progress-card .progress-text {
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-bottom: 6px;
}

#next-exercise {
  margin-top: 24px;
  padding: 20px;
  background: var(--bg-card);
  border: 1px solid var(--accent-blue);
  border-radius: 8px;
  cursor: pointer;
}

#next-exercise:hover {
  background: #161b22cc;
}

/* Exercise view */
#breadcrumb {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-bottom: 8px;
}

#exercise-title {
  margin-bottom: 20px;
  font-size: 1.5rem;
}

#no-ai-banner {
  background: #d299221a;
  border: 1px solid var(--accent-orange);
  border-radius: 6px;
  padding: 12px 16px;
  margin-bottom: 20px;
  font-size: 0.9rem;
  color: var(--accent-orange);
}

/* Lesson content (rendered markdown) */
#lesson-content h1, #cheatsheet-content h1 { font-size: 1.4rem; margin: 24px 0 12px; }
#lesson-content h2, #cheatsheet-content h2 { font-size: 1.2rem; margin: 20px 0 10px; color: var(--accent-blue); }
#lesson-content h3, #cheatsheet-content h3 { font-size: 1.05rem; margin: 16px 0 8px; color: var(--accent-purple); }

#lesson-content p, #cheatsheet-content p {
  margin: 10px 0;
  color: var(--text-primary);
}

#lesson-content code, #cheatsheet-content code {
  background: var(--bg-code);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.9em;
  font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
}

#lesson-content pre, #cheatsheet-content pre {
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 16px;
  overflow-x: auto;
  margin: 12px 0;
}

#lesson-content pre code, #cheatsheet-content pre code {
  background: none;
  padding: 0;
}

#lesson-content ul, #lesson-content ol,
#cheatsheet-content ul, #cheatsheet-content ol {
  margin: 10px 0 10px 24px;
}

#lesson-content li, #cheatsheet-content li {
  margin: 4px 0;
}

#lesson-content blockquote, #cheatsheet-content blockquote {
  border-left: 3px solid var(--accent-blue);
  padding: 8px 16px;
  margin: 12px 0;
  color: var(--text-secondary);
  background: var(--bg-secondary);
  border-radius: 0 6px 6px 0;
}

#lesson-content table, #cheatsheet-content table {
  width: 100%;
  border-collapse: collapse;
  margin: 12px 0;
}

#lesson-content th, #lesson-content td,
#cheatsheet-content th, #cheatsheet-content td {
  padding: 8px 12px;
  border: 1px solid var(--border);
  text-align: left;
}

#lesson-content th, #cheatsheet-content th {
  background: var(--bg-secondary);
  font-weight: 600;
}

/* Interview question callout */
.interview-q {
  background: #bc8cff1a;
  border: 1px solid var(--accent-purple);
  border-radius: 6px;
  padding: 12px 16px;
  margin: 16px 0;
}

/* Hint section */
#hint-section { margin: 20px 0; }

#hint-toggle {
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  color: var(--accent-orange);
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
}

#hint-toggle:hover { background: var(--bg-card); }

#hint-content {
  margin-top: 12px;
  padding: 16px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 6px;
}

/* Action buttons */
#exercise-actions {
  display: flex;
  gap: 10px;
  margin: 24px 0;
  flex-wrap: wrap;
}

#exercise-actions button {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  transition: opacity 0.2s;
}

#exercise-actions button:hover { opacity: 0.85; }

#btn-verify { background: var(--accent-green); color: #000; }
#btn-reset { background: var(--accent-orange); color: #000; }
#btn-cheatsheet { background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border) !important; }

/* Verify result */
#verify-result {
  padding: 16px;
  border-radius: 6px;
  margin: 16px 0;
  font-family: monospace;
  font-size: 0.9rem;
  white-space: pre-wrap;
}

#verify-result.pass {
  background: #3fb9501a;
  border: 1px solid var(--accent-green);
  color: var(--accent-green);
}

#verify-result.fail {
  background: #f851491a;
  border: 1px solid var(--accent-red);
  color: var(--accent-red);
}

/* Exercise navigation */
#exercise-nav {
  display: flex;
  justify-content: space-between;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid var(--border);
}

#exercise-nav button {
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  color: var(--text-primary);
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
}

#exercise-nav button:hover {
  background: var(--bg-card);
}

#exercise-nav button:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

/* Loading state */
.loading {
  color: var(--text-muted);
  font-style: italic;
}

/* Responsive */
@media (max-width: 768px) {
  #sidebar { width: 100%; position: relative; border-right: none; border-bottom: 1px solid var(--border); max-height: 40vh; }
  #content { margin-left: 0; padding: 20px; }
  #app { flex-direction: column; }
  :root { --sidebar-width: 0px; }
}
```

- [ ] **Step 2: Commit**

```bash
git add site/css/style.css && git commit -m "feat: add dark-themed CSS for web interface"
```

---

### Task 6: Web Interface — JavaScript (Progress Module)

**Files:**
- Create: `~/devops-lab/site/js/progress.js`

- [ ] **Step 1: Write progress tracking module**

```javascript
// progress.js — client-side progress management

const Progress = {
  data: { exercises: {} },

  async load() {
    const res = await fetch('/api/progress');
    this.data = await res.json();
    return this.data;
  },

  isCompleted(exerciseId) {
    return !!this.data.exercises[exerciseId]?.completed;
  },

  totalExercises(modules) {
    let count = 0;
    for (const mod of modules) {
      for (const sec of mod.sections) {
        count += sec.exercises.length;
      }
    }
    return count;
  },

  completedExercises(modules) {
    let count = 0;
    for (const mod of modules) {
      for (const sec of mod.sections) {
        for (const ex of sec.exercises) {
          if (this.isCompleted(ex.id)) count++;
        }
      }
    }
    return count;
  },

  moduleStats(module) {
    let total = 0, completed = 0;
    for (const sec of module.sections) {
      for (const ex of sec.exercises) {
        total++;
        if (this.isCompleted(ex.id)) completed++;
      }
    }
    return { total, completed, percent: total ? Math.round(completed / total * 100) : 0 };
  },

  nextIncomplete(modules) {
    for (const mod of modules) {
      for (const sec of mod.sections) {
        for (const ex of sec.exercises) {
          if (!this.isCompleted(ex.id)) return ex;
        }
      }
    }
    return null;
  }
};
```

- [ ] **Step 2: Commit**

```bash
git add site/js/progress.js && git commit -m "feat: add client-side progress tracking module"
```

---

### Task 7: Web Interface — JavaScript (Main App)

**Files:**
- Create: `~/devops-lab/site/js/app.js`

- [ ] **Step 1: Write main application logic**

Handles: routing (hash-based), module/exercise loading, sidebar rendering, verify/reset/hint actions, dashboard view.

```javascript
// app.js — main application logic

let appState = {
  modules: [],
  currentExercise: null,
  allExercises: [],  // flat list for prev/next navigation
};

// --- Initialization ---

async function init() {
  const res = await fetch('/api/modules');
  const { modules, progress } = await res.json();
  appState.modules = modules;
  Progress.data = progress;

  // Build flat exercise list
  appState.allExercises = [];
  for (const mod of modules) {
    for (const sec of mod.sections) {
      for (const ex of sec.exercises) {
        appState.allExercises.push({ ...ex, moduleTitle: mod.title, sectionTitle: sec.title, moduleDirName: mod.dirName });
      }
    }
  }

  renderSidebar();
  handleRoute();
  window.addEventListener('hashchange', handleRoute);
}

// --- Routing ---

function handleRoute() {
  const hash = window.location.hash.slice(1);
  if (!hash || hash === '/') {
    showDashboard();
  } else if (hash.startsWith('/exercise/')) {
    const exerciseId = hash.replace('/exercise/', '');
    loadExercise(exerciseId);
  }
}

function navigateTo(exerciseId) {
  window.location.hash = `/exercise/${exerciseId}`;
}

// --- Sidebar ---

function renderSidebar() {
  const nav = document.getElementById('module-nav');
  const total = Progress.totalExercises(appState.modules);
  const done = Progress.completedExercises(appState.modules);

  document.getElementById('progress-summary').innerHTML = `
    ${done} / ${total} exercises completed
    <div class="progress-bar"><div class="progress-bar-fill" style="width:${total ? (done/total*100) : 0}%"></div></div>
  `;

  let html = `<div class="nav-exercise" style="padding-left:20px;color:var(--accent-blue)" onclick="window.location.hash='/'">Dashboard</div>`;

  for (const mod of appState.modules) {
    html += `<div class="nav-module">`;
    html += `<div class="nav-module-title" onclick="this.nextElementSibling.classList.toggle('collapsed')">${mod.title} <span>${Progress.moduleStats(mod).percent}%</span></div>`;
    html += `<div class="nav-sections">`;
    for (const sec of mod.sections) {
      html += `<div class="nav-section">`;
      html += `<div class="nav-section-title" onclick="this.nextElementSibling.classList.toggle('collapsed')">${sec.title}</div>`;
      html += `<div class="nav-exercises">`;
      for (const ex of sec.exercises) {
        const completed = Progress.isCompleted(ex.id);
        const active = appState.currentExercise?.id === ex.id;
        html += `<div class="nav-exercise ${completed ? 'completed' : ''} ${active ? 'active' : ''}" onclick="navigateTo('${ex.id}')">
          <span class="status-dot">${completed ? '✓' : '○'}</span>
          <span>${ex.title}</span>
        </div>`;
      }
      html += `</div></div>`;
    }
    html += `</div></div>`;
  }
  nav.innerHTML = html;
}

// --- Dashboard ---

function showDashboard() {
  appState.currentExercise = null;
  document.getElementById('dashboard-view').style.display = '';
  document.getElementById('exercise-view').style.display = 'none';
  document.getElementById('cheatsheet-view').style.display = 'none';
  renderSidebar();

  const total = Progress.totalExercises(appState.modules);
  const done = Progress.completedExercises(appState.modules);

  document.getElementById('dashboard-stats').innerHTML = `
    <div class="stat-card"><div class="label">Completed</div><div class="value" style="color:var(--accent-green)">${done}</div></div>
    <div class="stat-card"><div class="label">Total</div><div class="value">${total}</div></div>
    <div class="stat-card"><div class="label">Progress</div><div class="value" style="color:var(--accent-blue)">${total ? Math.round(done/total*100) : 0}%</div></div>
    <div class="stat-card"><div class="label">Remaining</div><div class="value" style="color:var(--accent-orange)">${total - done}</div></div>
  `;

  let modulesHtml = '';
  for (const mod of appState.modules) {
    const stats = Progress.moduleStats(mod);
    modulesHtml += `
      <div class="module-progress-card">
        <h3>${mod.title}</h3>
        <div class="progress-text">${stats.completed} / ${stats.total} exercises (${stats.percent}%)</div>
        <div class="progress-bar"><div class="progress-bar-fill" style="width:${stats.percent}%"></div></div>
      </div>`;
  }
  document.getElementById('dashboard-modules').innerHTML = modulesHtml;

  const next = Progress.nextIncomplete(appState.modules);
  if (next) {
    document.getElementById('next-exercise').innerHTML = `<strong>Up next:</strong> ${next.title}`;
    document.getElementById('next-exercise').onclick = () => navigateTo(next.id);
    document.getElementById('next-exercise').style.display = '';
  } else {
    document.getElementById('next-exercise').innerHTML = '<strong>All exercises completed! 🎉</strong>';
    document.getElementById('next-exercise').onclick = null;
  }
}

// --- Exercise Loading ---

async function loadExercise(exerciseId) {
  const parts = exerciseId.split('/');
  if (parts.length !== 3) return;
  const [moduleId, sectionId, exId] = parts;

  const ex = appState.allExercises.find(e => e.id === exerciseId);
  if (!ex) return;

  appState.currentExercise = ex;

  document.getElementById('dashboard-view').style.display = 'none';
  document.getElementById('exercise-view').style.display = '';
  document.getElementById('cheatsheet-view').style.display = 'none';
  document.getElementById('verify-result').style.display = 'none';

  document.getElementById('breadcrumb').textContent = `${ex.moduleTitle} / ${ex.sectionTitle}`;
  document.getElementById('exercise-title').textContent = ex.title;

  // Show no-AI banner if module has noAiRule flag
  const mod = appState.modules.find(m => m.dirName === moduleId);
  const hasNoAiRule = mod?.noAiRule === true;
  document.getElementById('no-ai-banner').style.display = hasNoAiRule ? '' : 'none';

  // Load lesson
  document.getElementById('lesson-content').innerHTML = '<p class="loading">Loading...</p>';
  const res = await fetch(`/api/exercise/${moduleId}/${sectionId}/${exId}/lesson`);
  const data = await res.json();

  // Configure marked with highlight.js via custom renderer
  const renderer = new marked.Renderer();
  renderer.code = function({ text, lang }) {
    let highlighted;
    if (lang && hljs.getLanguage(lang)) {
      highlighted = hljs.highlight(text, { language: lang }).value;
    } else {
      highlighted = hljs.highlightAuto(text).value;
    }
    return `<pre><code class="hljs language-${lang || ''}">${highlighted}</code></pre>`;
  };
  marked.use({ renderer });

  let html = marked.parse(data.content);

  // Transform interview question blockquotes into styled callouts
  html = html.replace(/<blockquote>\s*<p><strong>Interview Q[^<]*<\/strong>/g, (match) => {
    return match.replace('<blockquote>', '<blockquote class="interview-q">');
  });

  document.getElementById('lesson-content').innerHTML = html;

  // Hints
  if (ex.hasHint) {
    document.getElementById('hint-section').style.display = '';
    document.getElementById('hint-content').style.display = 'none';
    document.getElementById('hint-toggle').textContent = 'Show Hint';
  } else {
    document.getElementById('hint-section').style.display = 'none';
  }

  // Verify/Reset buttons
  document.getElementById('btn-verify').style.display = ex.hasVerify ? '' : 'none';
  document.getElementById('btn-reset').style.display = ex.hasReset ? '' : 'none';

  // Prev/Next
  const idx = appState.allExercises.findIndex(e => e.id === exerciseId);
  document.getElementById('btn-prev').disabled = idx <= 0;
  document.getElementById('btn-next').disabled = idx >= appState.allExercises.length - 1;

  renderSidebar();
}

// --- Actions ---

async function verifyExercise() {
  if (!appState.currentExercise) return;
  const [moduleId, sectionId, exId] = appState.currentExercise.id.split('/');
  const resultEl = document.getElementById('verify-result');
  resultEl.style.display = '';
  resultEl.className = '';
  resultEl.textContent = 'Running verification...';

  const res = await fetch(`/api/exercise/${moduleId}/${sectionId}/${exId}/verify`, { method: 'POST' });
  const data = await res.json();

  resultEl.className = data.passed ? 'pass' : 'fail';
  resultEl.textContent = data.output;

  if (data.passed) {
    await Progress.load();
    renderSidebar();
  }
}

async function resetExercise() {
  if (!appState.currentExercise) return;
  if (!confirm('Reset this exercise? This will undo your work for this exercise.')) return;
  const [moduleId, sectionId, exId] = appState.currentExercise.id.split('/');

  const res = await fetch(`/api/exercise/${moduleId}/${sectionId}/${exId}/reset`, { method: 'POST' });
  const data = await res.json();

  document.getElementById('verify-result').style.display = '';
  document.getElementById('verify-result').className = data.success ? 'pass' : 'fail';
  document.getElementById('verify-result').textContent = data.output;

  await Progress.load();
  renderSidebar();
}

async function toggleHint() {
  const contentEl = document.getElementById('hint-content');
  const toggleEl = document.getElementById('hint-toggle');

  if (contentEl.style.display === 'none') {
    if (!contentEl.dataset.loaded) {
      const [moduleId, sectionId, exId] = appState.currentExercise.id.split('/');
      const res = await fetch(`/api/exercise/${moduleId}/${sectionId}/${exId}/hint`);
      const data = await res.json();
      contentEl.innerHTML = marked.parse(data.content);
      contentEl.dataset.loaded = 'true';
    }
    contentEl.style.display = '';
    toggleEl.textContent = 'Hide Hint';
  } else {
    contentEl.style.display = 'none';
    toggleEl.textContent = 'Show Hint';
  }
}

async function showCheatsheet() {
  if (!appState.currentExercise) return;
  const moduleId = appState.currentExercise.id.split('/')[0];

  document.getElementById('exercise-view').style.display = 'none';
  document.getElementById('cheatsheet-view').style.display = '';

  const res = await fetch(`/api/cheatsheet/${moduleId}`);
  const data = await res.json();
  document.getElementById('cheatsheet-content').innerHTML = marked.parse(data.content);
}

function hideCheatsheet() {
  document.getElementById('cheatsheet-view').style.display = 'none';
  document.getElementById('exercise-view').style.display = '';
}

function navigatePrev() {
  const idx = appState.allExercises.findIndex(e => e.id === appState.currentExercise?.id);
  if (idx > 0) navigateTo(appState.allExercises[idx - 1].id);
}

function navigateNext() {
  const idx = appState.allExercises.findIndex(e => e.id === appState.currentExercise?.id);
  if (idx < appState.allExercises.length - 1) navigateTo(appState.allExercises[idx + 1].id);
}

// --- Boot ---
init();
```

- [ ] **Step 2: Smoke test — start server and verify the page loads**

Run: `cd ~/devops-lab && node server.js &` then `curl -s http://localhost:3333/ | head -5`
Expected: HTML containing `<title>DevOps Lab</title>`
Clean up: `kill %1`

- [ ] **Step 3: Commit**

```bash
git add site/js/app.js && git commit -m "feat: add main app logic with routing, exercise loading, and dashboard"
```

---

### Task 8: CLI Tool (`lab-cli`)

**Files:**
- Create: `~/devops-lab/lab-cli`

- [ ] **Step 1: Write the CLI tool**

Bash script with subcommands: `status`, `verify`, `reset`, `hint`, `next`, `list`.

```bash
#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$LAB_DIR/modules"
PROGRESS_FILE="$LAB_DIR/progress.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

usage() {
  cat <<EOF
${BOLD}DevOps Lab CLI${NC}

Usage: lab <command> [args]

Commands:
  status              Show progress across all modules
  list                List all exercises
  verify <id>         Run verification for an exercise
  reset <id>          Reset an exercise to starting state
  hint <id>           Show hint for an exercise
  next                Show the next incomplete exercise
  cheatsheet <module> Show the cheatsheet for a module
  start               Start the web server

Exercise IDs use the format: section/exercise
  Example: 0A-linux-sysadmin/01-process-management

EOF
}

ensure_progress() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    echo '{"exercises":{},"started_at":null,"last_activity":null}' > "$PROGRESS_FILE"
  fi
}

find_exercise_dir() {
  local id="$1"
  # Search across all modules for a matching section/exercise
  for module_dir in "$MODULES_DIR"/*/; do
    local full_path="$module_dir$id"
    if [[ -d "$full_path" ]]; then
      echo "$full_path"
      return 0
    fi
  done
  # Try with full path including module
  if [[ -d "$MODULES_DIR/$id" ]]; then
    echo "$MODULES_DIR/$id"
    return 0
  fi
  return 1
}

get_module_for_exercise() {
  local id="$1"
  for module_dir in "$MODULES_DIR"/*/; do
    if [[ -d "$module_dir$id" ]]; then
      basename "$module_dir"
      return 0
    fi
  done
  echo ""
}

cmd_status() {
  ensure_progress
  echo -e "${BOLD}DevOps Lab — Progress${NC}\n"

  local total=0
  local completed=0

  for module_dir in "$MODULES_DIR"/*/; do
    [[ -d "$module_dir" ]] || continue
    local module_name
    module_name=$(basename "$module_dir")
    local mod_title
    mod_title=$(jq -r '.title // "'"$module_name"'"' "$module_dir/module.json" 2>/dev/null || echo "$module_name")
    local mod_total=0
    local mod_done=0

    for section_dir in "$module_dir"*/; do
      [[ -d "$section_dir" ]] || continue
      for ex_dir in "$section_dir"*/; do
        [[ -f "$ex_dir/lesson.md" ]] || continue
        local ex_id="$module_name/$(basename "$section_dir")/$(basename "$ex_dir")"
        mod_total=$((mod_total + 1))
        total=$((total + 1))
        if jq -e ".exercises[\"$ex_id\"].completed" "$PROGRESS_FILE" &>/dev/null; then
          mod_done=$((mod_done + 1))
          completed=$((completed + 1))
        fi
      done
    done

    local pct=0
    [[ $mod_total -gt 0 ]] && pct=$((mod_done * 100 / mod_total))
    local bar_filled=$((pct / 5))
    local bar_empty=$((20 - bar_filled))
    local bar="${GREEN}$(printf '█%.0s' $(seq 1 $bar_filled 2>/dev/null) || true)${NC}$(printf '░%.0s' $(seq 1 $bar_empty 2>/dev/null) || true)"

    echo -e "  ${BOLD}$mod_title${NC}"
    echo -e "  $bar ${mod_done}/${mod_total} (${pct}%)\n"
  done

  echo -e "${BOLD}Total: ${completed}/${total} exercises completed${NC}"
}

cmd_list() {
  ensure_progress
  for module_dir in "$MODULES_DIR"/*/; do
    [[ -d "$module_dir" ]] || continue
    local module_name
    module_name=$(basename "$module_dir")
    echo -e "\n${BOLD}$(jq -r '.title // "'"$module_name"'"' "$module_dir/module.json" 2>/dev/null || echo "$module_name")${NC}"

    for section_dir in "$module_dir"*/; do
      [[ -d "$section_dir" ]] || continue
      local section_name
      section_name=$(basename "$section_dir")
      echo -e "  ${BLUE}$(jq -r '.title // "'"$section_name"'"' "$section_dir/section.json" 2>/dev/null || echo "$section_name")${NC}"

      for ex_dir in "$section_dir"*/; do
        [[ -f "$ex_dir/lesson.md" ]] || continue
        local ex_name
        ex_name=$(basename "$ex_dir")
        local ex_id="$module_name/$section_name/$ex_name"
        local status="○"
        if jq -e ".exercises[\"$ex_id\"].completed" "$PROGRESS_FILE" &>/dev/null; then
          status="${GREEN}✓${NC}"
        fi
        echo -e "    $status  ${section_name}/${ex_name}"
      done
    done
  done
}

cmd_verify() {
  local id="$1"
  local ex_dir
  ex_dir=$(find_exercise_dir "$id") || { echo -e "${RED}Exercise not found: $id${NC}"; exit 1; }

  if [[ ! -f "$ex_dir/verify.sh" ]]; then
    echo -e "${YELLOW}No verification script for this exercise.${NC}"
    exit 1
  fi

  echo -e "${BLUE}Running verification...${NC}\n"
  if LAB_DIR="$LAB_DIR" bash "$ex_dir/verify.sh"; then
    echo -e "\n${GREEN}${BOLD}✓ PASSED${NC}"
    # Update progress
    local module_name
    module_name=$(get_module_for_exercise "$id")
    local full_id="$module_name/$id"
    [[ -n "$module_name" ]] || full_id="$id"
    ensure_progress
    local tmp
    tmp=$(jq --arg id "$full_id" --arg ts "$(date -Iseconds)" \
      '.exercises[$id] = {completed: true, completed_at: $ts} | .last_activity = $ts | .started_at //= $ts' \
      "$PROGRESS_FILE")
    echo "$tmp" > "$PROGRESS_FILE"
  else
    echo -e "\n${RED}${BOLD}✗ FAILED${NC}"
    echo -e "${YELLOW}Review the output above and try again.${NC}"
    exit 1
  fi
}

cmd_reset() {
  local id="$1"
  local ex_dir
  ex_dir=$(find_exercise_dir "$id") || { echo -e "${RED}Exercise not found: $id${NC}"; exit 1; }

  if [[ ! -f "$ex_dir/reset.sh" ]]; then
    echo -e "${YELLOW}No reset script for this exercise.${NC}"
    exit 1
  fi

  echo -e "${BLUE}Resetting exercise...${NC}"
  if LAB_DIR="$LAB_DIR" bash "$ex_dir/reset.sh"; then
    echo -e "${GREEN}Reset complete.${NC}"
    # Remove from progress
    local module_name
    module_name=$(get_module_for_exercise "$id")
    local full_id="$module_name/$id"
    [[ -n "$module_name" ]] || full_id="$id"
    ensure_progress
    local tmp
    tmp=$(jq --arg id "$full_id" 'del(.exercises[$id])' "$PROGRESS_FILE")
    echo "$tmp" > "$PROGRESS_FILE"
  else
    echo -e "${RED}Reset failed.${NC}"
    exit 1
  fi
}

cmd_hint() {
  local id="$1"
  local ex_dir
  ex_dir=$(find_exercise_dir "$id") || { echo -e "${RED}Exercise not found: $id${NC}"; exit 1; }

  if [[ ! -f "$ex_dir/hint.md" ]]; then
    echo -e "${YELLOW}No hints available for this exercise.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}${BOLD}Hint:${NC}\n"
  cat "$ex_dir/hint.md"
}

cmd_next() {
  ensure_progress
  for module_dir in "$MODULES_DIR"/*/; do
    [[ -d "$module_dir" ]] || continue
    local module_name
    module_name=$(basename "$module_dir")
    for section_dir in "$module_dir"*/; do
      [[ -d "$section_dir" ]] || continue
      for ex_dir in "$section_dir"*/; do
        [[ -f "$ex_dir/lesson.md" ]] || continue
        local section_name
        section_name=$(basename "$section_dir")
        local ex_name
        ex_name=$(basename "$ex_dir")
        local ex_id="$module_name/$section_name/$ex_name"
        if ! jq -e ".exercises[\"$ex_id\"].completed" "$PROGRESS_FILE" &>/dev/null; then
          echo -e "${BOLD}Next exercise:${NC} ${section_name}/${ex_name}"
          echo -e "${BLUE}Run:${NC} lab verify ${section_name}/${ex_name}"
          echo -e "\nOpen in browser: ${BLUE}http://localhost:3333/#/exercise/${ex_id}${NC}"
          return 0
        fi
      done
    done
  done
  echo -e "${GREEN}All exercises completed! 🎉${NC}"
}

cmd_start() {
  echo -e "${BLUE}Starting DevOps Lab server...${NC}"
  cd "$LAB_DIR" && node server.js
}

# --- Main ---

case "${1:-}" in
  status)     cmd_status ;;
  list)       cmd_list ;;
  verify)     [[ -n "${2:-}" ]] || { echo "Usage: lab verify <exercise-id>"; exit 1; }; cmd_verify "$2" ;;
  reset)      [[ -n "${2:-}" ]] || { echo "Usage: lab reset <exercise-id>"; exit 1; }; cmd_reset "$2" ;;
  hint)       [[ -n "${2:-}" ]] || { echo "Usage: lab hint <exercise-id>"; exit 1; }; cmd_hint "$2" ;;
  next)       cmd_next ;;
  cheatsheet) [[ -n "${2:-}" ]] && cat "$MODULES_DIR/$2/cheatsheet.md" 2>/dev/null || echo "Usage: lab cheatsheet <module-id>" ;;
  start)      cmd_start ;;
  help|--help|-h|"") usage ;;
  *)          echo -e "${RED}Unknown command: $1${NC}"; usage; exit 1 ;;
esac
```

- [ ] **Step 2: Make executable and symlink**

```bash
chmod +x ~/devops-lab/lab-cli
ln -sf ~/devops-lab/lab-cli ~/bin/lab 2>/dev/null || mkdir -p ~/bin && ln -sf ~/devops-lab/lab-cli ~/bin/lab
```

- [ ] **Step 3: Verify CLI runs**

Run: `~/devops-lab/lab-cli help`
Expected: Usage text displayed without errors

- [ ] **Step 4: Commit**

```bash
git add lab-cli && git commit -m "feat: add lab-cli tool with status/verify/reset/hint/next commands"
```

---

### Task 9: Setup Script

**Files:**
- Create: `~/devops-lab/setup.sh`

- [ ] **Step 1: Write the installer**

```bash
#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BOLD}Setting up DevOps Lab...${NC}\n"

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "Error: Node.js is required. Install it first."
  exit 1
fi

echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "  Installing jq..."
  sudo apt-get install -y jq >/dev/null 2>&1 || { echo "Error: Could not install jq. Install it manually."; exit 1; }
fi
echo -e "  ${GREEN}✓${NC} jq installed"

# Install npm dependencies
echo "  Installing dependencies..."
cd "$LAB_DIR" && npm install --silent
echo -e "  ${GREEN}✓${NC} npm dependencies installed"

# Download vendor libraries if missing
if [[ ! -f "$LAB_DIR/site/js/vendor/marked.min.js" ]]; then
  echo "  Downloading vendor libraries..."
  mkdir -p "$LAB_DIR/site/js/vendor" "$LAB_DIR/site/assets"
  curl -sL "https://cdn.jsdelivr.net/npm/marked@12.0.1/marked.min.js" -o "$LAB_DIR/site/js/vendor/marked.min.js"
  curl -sL "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js" -o "$LAB_DIR/site/js/vendor/highlight.min.js"
  curl -sL "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css" -o "$LAB_DIR/site/assets/highlight-github.css"
  echo -e "  ${GREEN}✓${NC} vendor libraries downloaded"
else
  echo -e "  ${GREEN}✓${NC} vendor libraries present"
fi

# Make lab-cli executable and create symlink
chmod +x "$LAB_DIR/lab-cli"
mkdir -p "$HOME/bin"
ln -sf "$LAB_DIR/lab-cli" "$HOME/bin/lab"
echo -e "  ${GREEN}✓${NC} lab CLI linked to ~/bin/lab"

# Initialize progress
if [[ ! -f "$LAB_DIR/progress.json" ]]; then
  echo '{"exercises":{},"started_at":null,"last_activity":null}' > "$LAB_DIR/progress.json"
fi

# Make all verify/reset scripts executable
find "$LAB_DIR/modules" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}Setup complete!${NC}\n"
echo -e "Start the web server:  ${BLUE}lab start${NC}"
echo -e "                  or:  ${BLUE}cd $LAB_DIR && npm start${NC}"
echo -e "Then open:             ${BLUE}http://localhost:3333${NC}\n"
echo -e "CLI commands:          ${BLUE}lab help${NC}"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x ~/devops-lab/setup.sh
```

- [ ] **Step 3: Commit**

```bash
git add setup.sh && git commit -m "feat: add one-command setup script"
```

---

### Task 10: README

**Files:**
- Create: `~/devops-lab/README.md`

- [ ] **Step 1: Write the README**

```markdown
# DevOps Lab

A self-hosted, interactive DevOps learning platform with hands-on exercises, automated verification, and progress tracking.

## Quick Start

```bash
./setup.sh        # Install dependencies and set up the CLI
lab start          # Start the web server
# Open http://localhost:3333
```

## CLI Usage

```bash
lab status              # Show progress across all modules
lab list                # List all exercises
lab next                # Show next incomplete exercise
lab verify <id>         # Verify an exercise (e.g., lab verify 0A-linux-sysadmin/01-process-management)
lab reset <id>          # Reset an exercise
lab hint <id>           # Show hints
lab cheatsheet <module> # Show module cheatsheet (e.g., lab cheatsheet 00-foundations)
lab start               # Start web server
```

## Modules

| Module | Exercises | Focus |
|--------|-----------|-------|
| 0. Foundations | 25 | Linux, Bash, Docker, Git, Terraform |
| 1. Kubernetes | 20 | Pods, Deployments, Services, Helm |
| 2. CI/CD | 10 | GitHub Actions |
| 3. Networking | 10 | TCP/IP, DNS, sockets |
| 4. Ansible | 8 | Playbooks, roles, vault |
| 5. Grafana/Prometheus | 8 | PromQL, dashboards, alerting |

## Structure

Each exercise has:
- **Theory** — short, learn-by-doing focused
- **Task** — what to do on the server
- **Verification** — automated pass/fail checking
- **Hints** — when you're stuck
- **Interview questions** — relevant interview prep
```

- [ ] **Step 2: Commit**

```bash
git add README.md && git commit -m "docs: add README with quick start and module overview"
```

---

## Phase 2: Module 0 — Foundations Bootcamp

### Task 11: Module 0 Metadata and Cheatsheet

**Files:**
- Create: `~/devops-lab/modules/00-foundations/module.json`
- Create: `~/devops-lab/modules/00-foundations/cheatsheet.md`
- Create: `~/devops-lab/modules/00-foundations/0A-linux-sysadmin/section.json`
- Create: `~/devops-lab/modules/00-foundations/0B-bash-scripting/section.json`
- Create: `~/devops-lab/modules/00-foundations/0C-docker-deep-dive/section.json`
- Create: `~/devops-lab/modules/00-foundations/0D-git-beyond-push-pull/section.json`
- Create: `~/devops-lab/modules/00-foundations/0E-terraform-opentofu/section.json`

- [ ] **Step 1: Create module.json**

```json
{
  "title": "Module 0: Foundations Bootcamp",
  "description": "Strengthen the tools you already use but don't fully command. Build muscle memory without AI assistance.",
  "duration": "1 week",
  "noAiRule": true
}
```

- [ ] **Step 2: Create section.json files for all 5 sections**

`0A-linux-sysadmin/section.json`:
```json
{ "title": "0A: Linux Sysadmin Essentials", "description": "Process management, disk, permissions, networking, firewalls, logs, SSH" }
```

`0B-bash-scripting/section.json`:
```json
{ "title": "0B: Bash Scripting", "description": "Variables, loops, functions, file processing, error handling" }
```

`0C-docker-deep-dive/section.json`:
```json
{ "title": "0C: Docker Deep Dive", "description": "Images, Dockerfiles, networking, Compose, troubleshooting" }
```

`0D-git-beyond-push-pull/section.json`:
```json
{ "title": "0D: Git Beyond Push/Pull", "description": "Branching, rebasing, cherry-pick, stash, bisect, reflog" }
```

`0E-terraform-opentofu/section.json`:
```json
{ "title": "0E: Terraform/OpenTofu", "description": "Reading configs, writing resources, plan and apply" }
```

- [ ] **Step 3: Write the comprehensive cheatsheet**

`cheatsheet.md` — a quick reference covering the most common commands for each section. This should be a real cheatsheet the user can reference during exercises (since they can't use AI for Module 0).

The cheatsheet should cover:
- Linux: ps, top, kill, systemctl, df, du, chmod, chown, find, grep, ss, ufw, journalctl, ssh
- Bash: variables, conditionals, loops, functions, set -e, trap
- Docker: build, run, ps, logs, exec, compose, network
- Git: branch, merge, rebase, cherry-pick, stash, bisect, reflog
- Terraform: init, plan, apply, destroy, fmt, validate

(Full content to be written — approximately 200 lines of quick-reference material)

- [ ] **Step 4: Commit**

```bash
git add modules/00-foundations/ && git commit -m "feat: add Module 0 metadata, section configs, and cheatsheet"
```

---

### Task 12-36: Module 0 Exercises

**Each exercise follows the same pattern. I'll detail the first exercise fully, then summarize the rest with their key content.**

---

### Task 12: Exercise 0A-01 — Process Management

**Files:**
- Create: `modules/00-foundations/0A-linux-sysadmin/01-process-management/lesson.md`
- Create: `modules/00-foundations/0A-linux-sysadmin/01-process-management/verify.sh`
- Create: `modules/00-foundations/0A-linux-sysadmin/01-process-management/reset.sh`
- Create: `modules/00-foundations/0A-linux-sysadmin/01-process-management/hint.md`

- [ ] **Step 1: Write lesson.md**

Content should cover:
- Brief theory: processes, PIDs, process states, signals
- Task 1: Use `ps aux` to find the process using the most CPU. Write the PID to `/tmp/devops-lab/0A-01/highest-cpu.txt`
- Task 2: Start a background process with `sleep 3600 &`, find its PID with `ps`, write it to `/tmp/devops-lab/0A-01/sleep-pid.txt`, then kill it
- Task 3: Use `systemctl` to check the status of the `ssh` service, write "active" or "inactive" to `/tmp/devops-lab/0A-01/ssh-status.txt`
- Interview Q: "What's the difference between SIGTERM and SIGKILL? When would you use each?"
- What Just Happened: explain that you just practiced the core process inspection/management cycle that every sysadmin uses daily — from finding what's running, to starting background work, to cleanly stopping processes, to checking service health via systemd

- [ ] **Step 2: Write verify.sh**

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-01"
PASS=0
FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying: Process Management"
echo ""

# Check 1: highest-cpu.txt exists and contains a valid PID
if [[ -f "$WORK_DIR/highest-cpu.txt" ]]; then
  pid=$(cat "$WORK_DIR/highest-cpu.txt" | tr -d '[:space:]')
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    check "highest-cpu.txt contains a valid PID ($pid)" "pass"
  else
    check "highest-cpu.txt should contain a numeric PID, got: '$pid'" "fail"
  fi
else
  check "highest-cpu.txt exists" "fail"
fi

# Check 2: sleep process was started and killed
if [[ -f "$WORK_DIR/sleep-pid.txt" ]]; then
  pid=$(cat "$WORK_DIR/sleep-pid.txt" | tr -d '[:space:]')
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    if ! kill -0 "$pid" 2>/dev/null; then
      check "sleep process ($pid) was started and killed" "pass"
    else
      check "sleep process ($pid) is still running — you need to kill it" "fail"
    fi
  else
    check "sleep-pid.txt should contain a numeric PID" "fail"
  fi
else
  check "sleep-pid.txt exists" "fail"
fi

# Check 3: ssh-status.txt
if [[ -f "$WORK_DIR/ssh-status.txt" ]]; then
  status=$(cat "$WORK_DIR/ssh-status.txt" | tr -d '[:space:]')
  actual=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo "unknown")
  if [[ "$status" == "$actual" ]]; then
    check "SSH service status correctly identified as '$status'" "pass"
  else
    check "SSH status is '$actual', but you wrote '$status'" "fail"
  fi
else
  check "ssh-status.txt exists" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

```bash
#!/usr/bin/env bash
rm -rf /tmp/devops-lab/0A-01
mkdir -p /tmp/devops-lab/0A-01
echo "Exercise reset. Work directory: /tmp/devops-lab/0A-01"
```

- [ ] **Step 4: Write hint.md**

```markdown
## Hints

### Finding the highest-CPU process
- `ps aux --sort=-%cpu | head -5` sorts by CPU usage
- The PID is in the second column
- `awk '{print $2}'` extracts the second column

### Starting and killing a background process
- `sleep 3600 &` starts it in the background
- `$!` gives you the PID of the last background process
- `kill <pid>` sends SIGTERM

### Checking service status
- `systemctl is-active ssh` prints "active" or "inactive"
- Some systems use `sshd` instead of `ssh`
```

- [ ] **Step 5: Commit**

```bash
git add modules/00-foundations/0A-linux-sysadmin/01-process-management/
git commit -m "feat: add exercise 0A-01 process management"
```

---

### Exercise Content Guidelines (applies to ALL exercises, Tasks 12-36)

Every exercise MUST follow this structure in `lesson.md`:

1. **Theory** — 2-3 paragraphs max. Short, practical. Include a diagram if helpful (ASCII art).
2. **Task** — Numbered steps. Clear instructions for what to do on the server. Specify exact file paths for output (always under `/tmp/devops-lab/<exercise-id>/`).
3. **Interview Q** — A blockquote starting with `> **Interview Q:**` — a question that might come up in a DevOps interview about this topic.
4. **What Just Happened** — A `## What Just Happened` section at the end. 3-5 sentences explaining what concepts were practiced and why they matter. Connect to real-world scenarios (e.g., "You just used `ss` to find a rogue process holding port 8080 — this is exactly what you'd do in production when a deployment fails to bind to its port.")

Every `verify.sh` MUST:
- Use the same `check()` pattern from Task 12
- Check actual system state, not just file existence
- Print clear pass/fail output with helpful error messages
- Exit 0 only if ALL checks pass

Every `reset.sh` MUST:
- Clean up the exercise work directory
- Recreate it fresh with `mkdir -p`
- Undo any system changes the exercise made (stop containers, remove users, etc.)

Every `hint.md` MUST:
- Have separate hints per task (not one big reveal)
- Give progressive hints (direction first, then command syntax)

The executing agent should write full, complete content for every exercise. Task 12 (0A-01) serves as the reference implementation. Match its quality and detail level for all exercises.

---

### Tasks 13-19: Remaining 0A Exercises (Linux Sysadmin)

Each follows the same pattern as Task 12. Summary of exercise content:

**Task 13: 0A-02 Disk and Storage**
- Theory: filesystems, inodes, mount points
- Tasks: check disk usage with `df -h`, find largest directories with `du`, identify block devices with `lsblk`, write results to work directory files
- Verify: checks that output files contain valid disk/directory info
- Interview Q: "What's an inode? What happens when you run out of inodes?"

**Task 14: 0A-03 Users and Permissions**
- Tasks: create a user, set specific permissions on files using octal notation, configure sudo access, identify permission bits
- Verify: checks user exists, file permissions match expected values
- Interview Q: "Explain the sticky bit. Where do you commonly see it?"

**Task 15: 0A-04 Finding Things**
- Tasks: use `find` to locate files by type/size/time, use `grep` to search log content, extract fields with `awk`, transform text with `sed`
- Verify: checks output files contain correct search results
- Interview Q: "Explain the difference between grep, egrep, and fgrep"

**Task 16: 0A-05 Networking Commands**
- Tasks: identify listening ports with `ss`, check IP addresses with `ip addr`, examine routing table, identify what process is using a specific port
- Verify: checks answers match actual system state
- Interview Q: "A service isn't reachable. Walk me through your debugging steps."

**Task 17: 0A-06 Firewall**
- Tasks: list current firewall rules, add a rule to allow a specific port, add a rule to deny a specific IP, check rule ordering
- Verify: checks `ufw` or `iptables` rules match expected state
- Interview Q: "Why does firewall rule ordering matter?"

**Task 18: 0A-07 System Logs**
- Tasks: use `journalctl` to find recent SSH login attempts, filter logs by time range, find error-level entries, follow logs in real-time
- Verify: checks output files contain correct log excerpts
- Interview Q: "How would you debug a service that crashed overnight?"

**Task 19: 0A-08 SSH Hardening**
- Tasks: generate SSH key pair, configure key-based auth, identify insecure SSH config options in a sample config file
- Verify: checks key exists, config changes are correct
- Note: Uses a sample sshd_config (not the real one) for safety
- Interview Q: "Explain the SSH connection process. What happens at each step?"

---

### Tasks 20-25: Section 0B — Bash Scripting

**Task 20: 0B-01 Variables and Arguments**
- Tasks: write a script that accepts arguments, uses variables, returns appropriate exit codes
- Verify: runs the script with test inputs, checks outputs and exit codes

**Task 21: 0B-02 Conditionals and Loops**
- Tasks: write a script with if/elif/else, [[ ]] tests, for and while loops processing a list of servers
- Verify: runs script, checks output matches expected

**Task 22: 0B-03 Functions**
- Tasks: write a script with multiple functions, local variables, return values
- Verify: sources the script, calls functions, checks results

**Task 23: 0B-04 File Processing**
- Tasks: process a CSV file using while read/cut/awk/pipes, extract and transform data
- Verify: checks output matches expected transformation

**Task 24: 0B-05 Error Handling**
- Tasks: write a script using set -euo pipefail, trap for cleanup, checking command success
- Verify: tests script handles both success and failure cases correctly

**Task 25: 0B-06 Server Health Checker (Capstone)**
- Tasks: write a complete health-check.sh script that reports CPU, memory, disk, open ports, and running services in a formatted report
- Verify: runs the script, checks output contains all required sections
- This is also the Module 0 capstone — goes on GitHub

---

### Tasks 26-30: Section 0C — Docker Deep Dive

**Task 26: 0C-01 Mental Model**
- Tasks: answer questions about image vs container vs volume, run containers, inspect state, write answers
- Verify: checks answers are correct, verifies container operations were performed

**Task 27: 0C-02 Dockerfile from Scratch**
- Tasks: write a multi-stage Dockerfile for a simple Go or Python app
- Verify: builds the image, checks it runs, verifies multi-stage (smaller final image)

**Task 28: 0C-03 Docker Networking**
- Tasks: create custom network, run two containers on it, verify they can communicate by name
- Verify: checks network exists, containers can ping each other

**Task 29: 0C-04 Docker Compose**
- Tasks: write a compose file with web + redis + postgres, volumes, healthchecks, depends_on
- Verify: runs `docker compose up`, checks all services are healthy

**Task 30: 0C-05 Docker Troubleshooting**
- Tasks: fix a deliberately broken container setup (wrong port, missing env var, bad network)
- Verify: checks all containers are running and reachable

---

### Tasks 31-33: Section 0D — Git Beyond Push/Pull

**Task 31: 0D-01 Branching and Merging**
- Tasks: create branches, merge, resolve a deliberately created merge conflict
- Verify: checks merge history, conflict was resolved

**Task 32: 0D-02 Rebasing**
- Tasks: interactive rebase to squash commits, rebase a branch onto main
- Verify: checks commit history reflects squash and rebase

**Task 33: 0D-03 Advanced Git**
- Tasks: cherry-pick a commit, use stash with named stashes, recover a "lost" commit with reflog
- Verify: checks cherry-picked commit exists, stash operations were performed, "lost" commit was recovered

---

### Tasks 34-36: Section 0E — Terraform/OpenTofu

**Task 34: 0E-01 Reading .tf Files**
- Tasks: annotate a sample Terraform config file — identify providers, resources, variables, outputs, data sources
- Verify: checks annotation file contains correct identifications

**Task 35: 0E-02 Writing Config from Scratch**
- Tasks: write a Terraform config that uses the `local` provider to create files (uses local provider instead of AWS to avoid credential requirements during learning — the lesson should note that the same patterns apply to `aws_instance` and include an example of what the AWS equivalent would look like)
- Verify: runs `terraform init && terraform plan`, checks output

**Task 36: 0E-03 Modify, Plan, Apply, Destroy**
- Tasks: modify the config from 0E-02, run plan to see diff, apply, then destroy
- Verify: checks state file shows correct operations were performed

---

### Task 37: Capstone Template

**Files:**
- Create: `~/devops-lab/capstone-templates/server-health-checker/README.md`
- Create: `~/devops-lab/capstone-templates/server-health-checker/health-check.sh`

- [ ] **Step 1: Write capstone starter README**

Instructions for turning the 0B-06 health checker into a GitHub portfolio piece: add a README, usage examples, CI badge, etc.

- [ ] **Step 2: Write skeleton script**

A commented skeleton with function stubs that the user fills in.

- [ ] **Step 3: Commit**

```bash
git add capstone-templates/ && git commit -m "feat: add server health checker capstone template"
```

---

### Task 38: Final Integration Test

- [ ] **Step 1: Run setup.sh**

```bash
cd ~/devops-lab && bash setup.sh
```
Expected: All steps pass

- [ ] **Step 2: Start server and test API**

```bash
cd ~/devops-lab && node server.js &
sleep 1
curl -s http://localhost:3333/api/modules | jq '.modules[0].title'
```
Expected: `"Module 0: Foundations Bootcamp"`

- [ ] **Step 3: Test CLI**

```bash
lab status
lab list
lab next
```
Expected: All commands work, show Module 0 exercises

- [ ] **Step 4: Test first exercise verify (should fail — work not done yet)**

```bash
lab reset 0A-linux-sysadmin/01-process-management
lab verify 0A-linux-sysadmin/01-process-management
```
Expected: Verification fails with clear error messages

- [ ] **Step 5: Kill test server**

```bash
kill %1
```

- [ ] **Step 6: Commit any fixes**

---

## Summary

**Total tasks:** 38
**Estimated effort:** Platform (Tasks 1-10) is ~1 hour of agent work. Module 0 content (Tasks 11-37) is ~2-3 hours. Integration (Task 38) is ~15 min.

**What this plan produces:**
- Fully functional web interface at http://localhost:3333
- CLI tool (`lab`) for terminal-based workflow
- 25 exercises in Module 0 with lessons, verification, hints, and reset scripts
- Cheatsheet for Module 0
- Capstone template for the server health checker

**What comes next (separate plans):**
- Plan 2: Module 1 — Kubernetes (minikube setup + 20 exercises)
- Plan 3: Module 2 — CI/CD with GitHub Actions (10 exercises)
- Plan 4: Module 3 — Networking (10 exercises)
- Plan 5: Module 4 — Ansible (8 exercises)
- Plan 6: Module 5 — Grafana/Prometheus (8 exercises)
