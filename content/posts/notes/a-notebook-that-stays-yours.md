---
title: "A notebook that stays yours"
description: "Writing in Obsidian, publishing with Markdown, and keeping the distance between a thought and a page pleasantly short."
date: 2026-09-02
tags: [obsidian, notes]
status: published
---

Open the `content` directory as an Obsidian vault. The posts are ordinary Markdown files, and the attachments sit beside them in a predictable folder.

## Write first

Create a note in a category folder such as `posts/notes/` with a URL-friendly filename such as `a-small-idea.md`. Use the note template to add its properties:

```yaml
title: A small idea
description: A sentence that tells a reader why to open the note.
date: 2026-09-08
tags: [notes]
status: draft
```

The first folder below `posts/` determines the note’s single category. Only notes with `status: published` appear in the generated website. Changing a draft to published is an explicit editorial step.

## Connect ideas

Use Obsidian's wiki links to connect notes. For example, this link opens [[plain-text-to-a-small-web#One source, two outputs|the publishing pipeline]]. Aliases and heading links become ordinary HTML links during the build.

Images in `attachments/` can be embedded with Obsidian's image syntax. Put only public assets in that folder: its contents are copied to the website.

## Publish deliberately

Run `just check` from the project root. Inspect the site with `just dev`, then publish the generated `_site` directory using the Cloudflare Pages workflow.

The build rejects links to missing or unpublished notes. This keeps a private draft from quietly turning into a broken public link.
