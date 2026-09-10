export function registerClipboard(program) {
  if (!program) return;
  customElements.define(
    'code-copy',
    class extends HTMLElement {
      connectedCallback() {
        // Defer nested Elm initialization until the parent program finishes its effects.
        queueMicrotask(() => {
          if (!this.isConnected || this.mounted) return;
          this.mounted = true;
          const mount = document.createElement('span');
          this.replaceChildren(mount);
          const app = program.init({ node: mount, flags: null });
          app.ports.copyCode.subscribe(() => {
            try {
              const text = this.closest('.code-block').querySelector('pre code').textContent;
              navigator.clipboard.writeText(text).then(
                () => app.ports.copyCompleted.send(true),
                () => app.ports.copyCompleted.send(false),
              );
            } catch {
              app.ports.copyCompleted.send(false);
            }
          });
          this.dataset.ready = '';
        });
      }
    },
  );
}
