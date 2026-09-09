// Only assign HTML generated from trusted repository Markdown.
class BlogContent extends HTMLElement {
  set html(value) {
    if (value !== this._html) {
      this._html = value;
      this.innerHTML = value;
    }
  }
}
customElements.define('blog-content', BlogContent);
