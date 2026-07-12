# SERIOS — Claude Code Project Guide

SERIOS is a mobile strategy PvP game. **Godot 4.6**, **Mobile renderer**, **2532×1170** viewport.
Team: Jaber (lead — programming, design, docs, audio, business, production), Saeed (art), Khalifa (programming/AI/infrastructure).

## Commands
- **Open / run:** launch Godot 4.6, open `project.godot`, press **F5** to run the project (**F6** runs the current scene).
- **Tests / lint:** none configured yet — no GDScript linter set up in this project. Update here if that changes.
- **Export:** uses Godot's export presets, run headless:
  `<godot-executable> --headless --export-release "<PresetName>" <output-path>`
  The `<PresetName>` values live in `export_presets.cfg` — read that file for the current ones rather than guessing.

## Layout & node setups
- Viewport is fixed **2532x1170**, origin **top-left**. All positions are **absolute** within it.
- **Never use negative values** for sizes or positions.
- When specifying node setups, present them in **tables**, **sizes before positions**, using **X and Y exactly as the editor shows**.
- Give **one step at a time** for editor/setup tasks. Don't stack unrelated steps unless I ask for the full list.

## Naming & structure
- **`Btn` suffix** on every clickable overlay node (e.g. `PlayBtn`, `SettingsBtn`).
- Follow the **existing node/scene** and **NavigationManager** patterns already in the repo — match them, don't reinvent.
- Prefer editing existing scenes/scripts over adding new ones unless the established pattern calls for it.

## Workflow
- **Shell-first:** gray-box placeholders before art. Don't mass-produce assets before art direction is locked.

## UI conventions
- **Tier labels** use tier + sub-stage roman numerals — e.g. "Epic III", "Rare II" — shown with a tier-pip row. Never show a hero level number or power percentage on these labels.
- The **Generals screen** is the hero hub. Its right panel has exactly two tabs: **Overview** (which holds the Commanders, Gear, and Skills sections, each with its own Manage button) and **Attributes**. Skills and Gear are sections inside Overview, not tabs.

## Out of scope for code sessions
- The **GDD** (`SERIOS_GDD_vX.docx`) is the single source of truth for design, but it's a docs deliverable — **don't edit it from a code session** unless I explicitly ask. GDD edits follow their own tracked-changes workflow (accept prior changes → new edits as tracked changes, author "Jaber" → validate).
- Only touch other members' lanes (art assets, Khalifa's infra) when I ask.

