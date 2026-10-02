---
name: jira-create-ticket
description: When user asks to create a task or a ticket in Jira. 
---

# General

- Use defaults unless the user explicitly asks for something else.
- Use jira-ticket-filler to fill the ticket.
- If the user asks you to create a ticket for a task that already has a PR and you are about to create one, move the created task to 'In Progress'.

# Defaults

- https://aviasales.atlassian.net/jira/software/c/projects/DL
- Assignee: Vsevolod Bazhan
- Component: DE: Data Forge Team

# Epics

Some projects have epics associated with them. For example,

- Rivendell
- Spire
- Sam

If you are asked to create a ticket while working on such a project, attach the created ticket to the epic. If you find no associated epic, leave the field empty.
