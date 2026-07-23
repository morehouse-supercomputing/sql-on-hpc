# Roadmap

Future enhancements to make this template easier for other instructors to adopt.

## Priority

### Interactive setup script

Add a `bash setup.sh` (or Python equivalent) that prompts the instructor for:

- TACC username
- Allocation ID (e.g., 10539)
- Project folder name
- Path to shared database

The script then either:
- Writes a personalized `LESSON_PLAN_<username>.md` and `STUDENT_INSTRUCTIONS.md` with the values filled in, OR
- Generates a `.env` file that all docs reference via templating

Goal: an instructor cloning this repo can run one command and walk away with all paths and IDs already substituted into their materials.

Ready by: summer 2026 cohorts (NAIRR Accelerator).

## Other ideas

- Lesson plan template that mirrors LESSON_PLAN.md structure (5 phases, customizable analyst question)
- Homework question bank with several pre-written prompts an instructor can pick from
- Slide deck template (PPTX or Reveal) with brand-neutral styling
- Pre-warm script that runs a `COUNT(*)` to load the DB into page cache before class
