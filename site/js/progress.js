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
