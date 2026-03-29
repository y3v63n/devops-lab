// app.js — main application logic

// Escape server-data strings before interpolating into HTML templates.
function esc(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Render parsed markdown HTML into an element using DOMParser (no innerHTML).
// Content comes from local exercise files served by our own API, not end-user input.
function setMarkdown(el, htmlString) {
  const doc = new DOMParser().parseFromString(htmlString, 'text/html');
  el.replaceChildren(...doc.body.childNodes);
}

// Build a stat card element via DOM methods.
function makeStatCard(label, value, color) {
  const card = document.createElement('div');
  card.className = 'stat-card';
  const lDiv = document.createElement('div');
  lDiv.className = 'label';
  lDiv.textContent = label;
  const vDiv = document.createElement('div');
  vDiv.className = 'value';
  if (color) vDiv.style.color = color;
  vDiv.textContent = value;
  card.append(lDiv, vDiv);
  return card;
}

// Build a module progress card element via DOM methods.
function makeModuleCard(mod) {
  const stats = Progress.moduleStats(mod);
  const card = document.createElement('div');
  card.className = 'module-progress-card';

  const h3 = document.createElement('h3');
  h3.textContent = mod.title;

  const text = document.createElement('div');
  text.className = 'progress-text';
  text.textContent = `${stats.completed} / ${stats.total} exercises (${stats.percent}%)`;

  const bar = document.createElement('div');
  bar.className = 'progress-bar';
  const fill = document.createElement('div');
  fill.className = 'progress-bar-fill';
  fill.style.width = `${stats.percent}%`;
  bar.appendChild(fill);

  card.append(h3, text, bar);
  return card;
}

let appState = {
  modules: [],
  currentExercise: null,
  allExercises: [],
};

// --- Initialization ---

async function init() {
  const res = await fetch('/api/modules');
  const { modules, progress } = await res.json();
  appState.modules = modules;
  Progress.data = progress;

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

function makeNavItem(text, onClick, classes = [], style = '') {
  const div = document.createElement('div');
  div.className = ['nav-exercise', ...classes].join(' ');
  if (style) div.setAttribute('style', style);
  div.onclick = onClick;
  return div;
}

function renderSidebar() {
  const nav = document.getElementById('module-nav');
  const total = Progress.totalExercises(appState.modules);
  const done = Progress.completedExercises(appState.modules);
  const pct = total ? (done / total * 100) : 0;

  // Progress summary — all values are numbers, built via DOM
  const summaryEl = document.getElementById('progress-summary');
  summaryEl.replaceChildren();
  summaryEl.appendChild(document.createTextNode(`${done} / ${total} exercises completed`));
  const bar = document.createElement('div');
  bar.className = 'progress-bar';
  const fill = document.createElement('div');
  fill.className = 'progress-bar-fill';
  fill.style.width = `${pct}%`;
  bar.appendChild(fill);
  summaryEl.appendChild(bar);

  // Build sidebar nav via DOM
  const nodes = [];

  // Dashboard link
  const dashLink = document.createElement('div');
  dashLink.className = 'nav-exercise';
  dashLink.setAttribute('style', 'padding-left:20px;color:var(--accent-blue)');
  dashLink.textContent = 'Dashboard';
  dashLink.onclick = () => { window.location.hash = '/'; };
  nodes.push(dashLink);

  for (const mod of appState.modules) {
    const modDiv = document.createElement('div');
    modDiv.className = 'nav-module';

    const titleDiv = document.createElement('div');
    titleDiv.className = 'nav-module-title';
    titleDiv.textContent = mod.title + ' ';
    const pctSpan = document.createElement('span');
    pctSpan.textContent = `${Progress.moduleStats(mod).percent}%`;
    titleDiv.appendChild(pctSpan);

    const sectionsDiv = document.createElement('div');
    sectionsDiv.className = 'nav-sections';
    titleDiv.onclick = () => sectionsDiv.classList.toggle('collapsed');

    for (const sec of mod.sections) {
      const secDiv = document.createElement('div');
      secDiv.className = 'nav-section';

      const secTitle = document.createElement('div');
      secTitle.className = 'nav-section-title';
      secTitle.textContent = sec.title;

      const exDiv = document.createElement('div');
      exDiv.className = 'nav-exercises';
      secTitle.onclick = () => exDiv.classList.toggle('collapsed');

      for (const ex of sec.exercises) {
        const completed = Progress.isCompleted(ex.id);
        const active = appState.currentExercise?.id === ex.id;
        const exEl = document.createElement('div');
        exEl.className = ['nav-exercise', completed ? 'completed' : '', active ? 'active' : ''].join(' ').trim();
        exEl.onclick = () => navigateTo(ex.id);

        const dot = document.createElement('span');
        dot.className = 'status-dot';
        dot.textContent = completed ? '✓' : '○';

        const label = document.createElement('span');
        label.textContent = ex.title;

        exEl.append(dot, label);
        exDiv.appendChild(exEl);
      }

      secDiv.append(secTitle, exDiv);
      sectionsDiv.appendChild(secDiv);
    }

    modDiv.append(titleDiv, sectionsDiv);
    nodes.push(modDiv);
  }

  nav.replaceChildren(...nodes);
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
  const pct = total ? Math.round(done / total * 100) : 0;

  document.getElementById('dashboard-stats').replaceChildren(
    makeStatCard('Completed', done, 'var(--accent-green)'),
    makeStatCard('Total', total, null),
    makeStatCard('Progress', `${pct}%`, 'var(--accent-blue)'),
    makeStatCard('Remaining', total - done, 'var(--accent-orange)')
  );

  document.getElementById('dashboard-modules').replaceChildren(
    ...appState.modules.map(makeModuleCard)
  );

  const nextEl = document.getElementById('next-exercise');
  const next = Progress.nextIncomplete(appState.modules);
  nextEl.replaceChildren();
  if (next) {
    const strong = document.createElement('strong');
    strong.textContent = 'Up next: ';
    nextEl.appendChild(strong);
    nextEl.appendChild(document.createTextNode(next.title));
    nextEl.onclick = () => navigateTo(next.id);
    nextEl.style.display = '';
  } else {
    const strong = document.createElement('strong');
    strong.textContent = 'All exercises completed!';
    nextEl.appendChild(strong);
    nextEl.onclick = null;
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

  const mod = appState.modules.find(m => m.dirName === moduleId);
  document.getElementById('no-ai-banner').style.display = mod?.noAiRule === true ? '' : 'none';

  // Loading placeholder via DOM
  const lessonEl = document.getElementById('lesson-content');
  const loadingP = document.createElement('p');
  loadingP.className = 'loading';
  loadingP.textContent = 'Loading...';
  lessonEl.replaceChildren(loadingP);

  const res = await fetch(`/api/exercise/${moduleId}/${sectionId}/${exId}/lesson`);
  const data = await res.json();

  // Configure marked with highlight.js syntax highlighting
  const renderer = new marked.Renderer();
  renderer.code = function({ text, lang }) {
    let highlighted;
    if (lang && hljs.getLanguage(lang)) {
      highlighted = hljs.highlight(text, { language: lang }).value;
    } else {
      highlighted = hljs.highlightAuto(text).value;
    }
    return `<pre><code class="hljs language-${esc(lang || '')}">${highlighted}</code></pre>`;
  };
  marked.use({ renderer });

  let html = marked.parse(data.content);

  // Transform interview question blockquotes into styled callouts
  html = html.replace(/<blockquote>\s*<p><strong>Interview Q[^<]*<\/strong>/g, (match) => {
    return match.replace('<blockquote>', '<blockquote class="interview-q">');
  });

  // Render markdown from our own server-side exercise files
  setMarkdown(lessonEl, html);

  if (ex.hasHint) {
    document.getElementById('hint-section').style.display = '';
    document.getElementById('hint-content').style.display = 'none';
    document.getElementById('hint-content').dataset.loaded = '';
    document.getElementById('hint-toggle').textContent = 'Show Hint';
  } else {
    document.getElementById('hint-section').style.display = 'none';
  }

  document.getElementById('btn-verify').style.display = ex.hasVerify ? '' : 'none';
  document.getElementById('btn-reset').style.display = ex.hasReset ? '' : 'none';

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

  const resultEl = document.getElementById('verify-result');
  resultEl.style.display = '';
  resultEl.className = data.success ? 'pass' : 'fail';
  resultEl.textContent = data.output;

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
      // Render markdown from our own server-side hint files
      setMarkdown(contentEl, marked.parse(data.content));
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
  // Render markdown from our own server-side cheatsheet files
  setMarkdown(document.getElementById('cheatsheet-content'), marked.parse(data.content));
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
