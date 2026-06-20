# Getting started — the gentle version

Never opened a terminal? Never installed a developer tool? **You're in the right place.**
This page walks you through your very first website with website-builder, in plain
language. You won't need to understand the whole toolchain — your AI assistant handles the
technical parts and explains each step as it goes.

If you get stuck at any point, you can always type **"what does this do?"** or **"I'm
confused, can you explain that more simply?"** to your assistant. That's allowed, and it
works.

---

## What you need first

Just three things to begin:

1. **An AI coding assistant.** Pick one:
   - **Claude Code** (recommended) — see the [setup guide](https://code.claude.com/docs/en/setup).
   - **OpenAI Codex** or **Google Antigravity** also work.
2. **A GitHub account** (free) — this is where your website's files will live safely.
   You'll make one at [github.com](https://github.com) if you don't have it; your assistant
   will point you there when it's time.
3. **Your computer.** macOS, Linux, or Windows are all fine.

You do **not** need to install anything else right now. Tools like Node, git, or image
helpers get installed later — only if and when your site actually needs them, and your
assistant will offer to do it for you.

A **Cloudflare account** (also free) comes up later, when you're ready to publish your site
to the internet. You don't need it on day one.

---

## Step by step

### 1. Open your AI assistant

Start the assistant you installed (for example, Claude Code). You'll get a chat box where
you type to it in normal language — like texting a knowledgeable friend.

### 2. Make a new, empty folder for your website

A "folder" is just like a folder on your desktop — a container for your website's files.
Make a fresh, empty one so your new site starts clean and nothing gets mixed up. You can
ask your assistant: *"Help me make a new empty folder for my website and open it."*

### 3. Paste the starter prompt

Copy this into the chat and send it:

> I want to use the website-builder skill suite (https://github.com/karero/website-builder)
> to create a new website. Please guide me step by step in plain language.
> First, check which required tools this computer already has.
> Explain every command before you run it, and install missing tools only when they're
> actually needed. Then install the website-builder skills, restart yourself so they load,
> and start a fresh site by running `new website` in a new, empty folder.

The assistant will take it from there: it checks what's on your computer, installs the
website-builder skills, and asks your approval before doing anything that changes your
system.

### 4. Answer its questions

Once it runs **`new website`**, the assistant interviews you about the site you want. These
are *decisions*, not commands — things like:

- What is this website for? Who is it for?
- What should it be called?
- Roughly what pages do you want?

Answer in your own words. There are no wrong answers, and you can change your mind.

### 5. Let it build

From your answers, the assistant creates the site, drafts the pages, adds the behind-the-
scenes things that make a site fast and findable (SEO, accessibility checks, structured
data), and runs its own quality tests. It'll show you what it made and help you adjust.

### 6. Publish when you're ready

When the site looks good, the assistant helps you put it online (this is where the free
Cloudflare account comes in). Again — it walks you through it.

---

## A few reassurances

- **Nothing happens without your say-so.** The assistant asks before installing anything or
  making changes.
- **You can stop and ask anytime.** "Slow down", "explain that", "what just happened" all
  work.
- **You own everything.** The website's code, its repository, and its domain are yours —
  this isn't a rented platform you can be locked out of.

---

## Want the technical details?

If you're comfortable with a terminal, or you're curious what the assistant is actually
running under the hood, see the **[Manual install & technical reference](../README.md#manual-install--technical-reference)**
section of the README — every exact command is listed there.
