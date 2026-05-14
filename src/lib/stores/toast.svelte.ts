class ToastStore {
  messages = $state<{ id: number; text: string; type: 'success' | 'error' | 'info' }[]>([]);
  #nextId = 0;

  show(text: string, type: 'success' | 'error' | 'info' = 'info') {
    const id = this.#nextId++;
    this.messages = [...this.messages, { id, text, type }];
    setTimeout(() => {
      this.messages = this.messages.filter(m => m.id !== id);
    }, 3500);
  }

  success(text: string) { this.show(text, 'success'); }
  error(text: string) { this.show(text, 'error'); }
}

export const toast = new ToastStore();
