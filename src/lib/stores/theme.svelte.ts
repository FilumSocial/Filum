class ThemeStore {
  mode = $state<'dark' | 'light'>('dark');

  init() {
    const stored = typeof localStorage !== 'undefined' ? localStorage.getItem('theme') : null;
    if (stored === 'light' || stored === 'dark') {
      this.mode = stored;
    } else {
      this.mode = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
    }
    document.body.classList.toggle('light', this.mode === 'light');
  }

  toggle() {
    this.mode = this.mode === 'dark' ? 'light' : 'dark';
    localStorage.setItem('theme', this.mode);
    document.body.classList.toggle('light', this.mode === 'light');
  }
}

export const theme = new ThemeStore();
