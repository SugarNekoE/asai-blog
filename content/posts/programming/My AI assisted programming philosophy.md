---
title: My AI assisted programming philosophy
description: My approach to AI-assisted programming
date: 2026-09-13
tags:
  - philosophy
  - ai
  - programming
  - skills
status: published
---

## First of all

> AI agents should be treated as tools that assist humans, not as magical workers that instantly finish a job for you.
>
> Instead of spending excessive time repeatedly prompting an agent until its output looks acceptable, it is often more productive to inspect the code it generates, understand how it works, and learn from it.
>
> The complexity of the task has not disappeared. It has simply been rearranged.

---

## Tools I use, or have used before

- OpenAI Codex
- Claude Code
- Pi
- Qwen Code
- Gemini CLI
- Copilot CLI

---

## The common problems

### Heavy harnesses

Heavy agent harnesses such as Codex and Claude Code are highly optimized around certain categories of work, especially software engineering.

They provide repository indexing, tool calling, planning, patching, testing, context management, and many other layers around the underlying model.

For the workflows they are designed for, this can make them extremely capable.

But that optimization also means the harness itself influences how the model behaves.

### Lightweight harnesses

Lightweight tools such as Pi allow the model to respond in a much more raw form, with less orchestration between the user and the model.

For specialized tasks, lightweight harnesses often struggle to compete with heavily engineered systems. Sometimes you can even notice that certain models appear to work significantly better inside the harnesses they were trained or optimized around.

### Context management is still unsolved

Once a long coding session reaches the context limit, most existing tools still do not have a truly satisfying way to compact the conversation while preserving all the important architectural decisions, constraints, mistakes, and reasoning accumulated during the session.

Summaries help, but information is inevitably lost.

### Full hand-off produces code for AI, not humans

Giving too much work to AI without intervention often produces code that technically works but becomes increasingly difficult for humans to understand.

The structure becomes inconsistent, abstractions appear where they are unnecessary, files grow too large, comments explain obvious things while important architectural decisions remain undocumented, patterns get copied simply because they already exist somewhere else in the repository.

Eventually, the project starts looking like something designed for the next AI agent rather than the next human maintainer.

But the application is still built for humans, The code should be too.

---

# My approach

## Rule No. 1: Do not vibe-code prod programs

Yes, AI can absolutely create demos.

Give it a prompt, an idea, or a rough description, and it can often produce something impressive very quickly.

That is useful.

But for me, that is where full autonomous generation stops.

Once the demo exists, I review it manually.

I check whether the original idea actually works, whether the interaction makes sense, and whether the implementation proves the concept.

Then I start the real project again, Usually from scratch, or at least as a clean subproject.

At that point I may ask AI to research better libraries, frameworks, architectural patterns, or implementation approaches, but I make the major technical decisions myself.

Then I use the strongest coding harness available to inspect the project and produce something closer to an engineering checklist:

what needs to be implemented, which modules should exist, which decisions need to be made, what dependencies are required, what assumptions are being made and what should be verified afterward.

I review that checklist first. The AI implements what I approve. It does not implement what I reject.

I strongly prefer building module by module rather than asking an agent to "implement everything." Small, understandable modules are much easier to review than a single generated file containing thousands or tens of thousands of lines.

When possible, I also give the agent references from projects with architectures I consider good.

Instead of saying:

> I want you to do something, do it for me.

I say:

> This is a project for something, you can ref from somewhere, the structure should be something, and heres a list of things you need to check before working. Then there is a list for you to do.

That gives the model a much more concrete target.

### The QA round

Once the implementation appears complete, I start another review cycle.

I let the AI create a checklist covering every important function, implementation choice, architectural decision, and dependency introduced during development. Then I verify them manually. One by one. If the project contains a UI, I open it in the development environment and inspect it closely.

I look for details that AI frequently gets wrong. Unnecessary absolute positioning, strange spacing, broken responsive behavior, incorrect component hierarchy, duplicated styling, inaccessible interactions, inconsistent implementations that happen to work without actually being correct.

"Looks right" is not the same as "is right."

---

## Rule No. 2: Use skills and rules aggressively

Models have habits.

Without constraints, they often produce things I do not want.

Useless comments, excessively verbose documentation, badly formatted commit messages, unsigned commits headings subheadings sub-subheadings, unnecessary summaries, unnecessary abstractions and sometimes the infamous `Co-Authored-By` footer.

So I use explicit rules to suppress it. In my experience, repository-level instructions can override many of these tendencies surprisingly well.

For example, I can define rules about formatting, comments, architecture, commit style, testing, dependency selection, file size, naming conventions and things the agent must never modify automatically

I also like having a dedicated **human-review skill**.

The repository's `AGENTS.md` can instruct the agent that after completing a meaningful task, it must invoke that skill.

The skill tells the agent to stop after one goal and produce a human-readable checklist explaining everything including whats changed, what does a function do, why does it should write like this.

At that point I can decide whether something is over-engineered, unnecessary, incorrect, or simply stupid.

Automatic AI review is useful, but AI reviewing AI often converges toward the same assumptions that produced the code in the first place. It becomes another form of vibe coding.

---

## Rule No. 3: Keep a transcript, not just a summary

One of the most useful things I have added to my workflow is a transcript skill.

For every interaction, I record all the user requests and ai responses with decisions, corrections and rejections. But to exclude raw tool calls.

Before starting the next major context window, I ask the agent to read that transcript first. On a large project, sometimes it costs a lot of context but I consider that trade-off worthwhile.

Those details prevent the next context window from reopening already-settled decisions or repeating old mistakes.

The result is a much more persistent and fluent context.

For some projects, context itself even becomes part of the project infrastructure.

---

## Rule No. 4: Write the commits myself

I consider committing part of engineering, committing means something.

A task is complete, module has been implemented, bug has been fixed, refactor has reached a coherent state.

That is why I usually write commits myself.

I inspect the diff, decide which files and lines belong together, determine the correct scope, and decide what type of change actually happened.

I generally use Conventional Commits, if more explanation is necessary, I add it below the summary. For breaking changes, I use `!` and describe the consequences clearly.

---

# So, finally

AI is an assistant, not a replacement for engineering. It can save time, automate repetitive work, accelerate research, generate boilerplate, and help catch mistakes, but it does not remove the complexity of the work itself.

The decisions, responsibility, and understanding still belong to humans. AI simply shifts part of the effort from **writing code** to **directing, reviewing, preserving context, and validating it**.

The entropy is still there. It just changed form.
