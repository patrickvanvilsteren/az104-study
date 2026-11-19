# Prompt reference — AZ-104 study sessions with Claude

The Project instructions and skills hold the stable rules. What you type in a chat only needs to add what changes per session.

## Start a session

```
Today: <hours>. Topic: <domain → objective>.
Where I am: <read / labs done / stuck on X>.
Goal: <labs / quiz / teach-back>.
```

Example:

```
Today: ~3 hours. Topic: Compute → virtual machines (availability zones vs sets).
Where I am: read the concepts, no labs yet.
Goal: 2 labs, then a short quiz.
```

## Pick a mode

| Say | What happens |
|---|---|
| "Build labs for …" | az104-lab-builder: goal + hints, check command, cleanup |
| "Quiz me on …" / "Drill me on …" | The quiz skill for that domain |
| "Look at this with systems thinking" | systems-thinking skill |

## Control the help you get

- "Hint 1 only."
- "I'm stuck, give me hint 2."
- "I tried X and Y. What am I missing? Don't give me the answer."
- "Show the solution and explain why each step is needed."

## Give evidence, not descriptions

Paste the real output instead of "it doesn't work":

- the full error message
- the check command output, e.g. `az vm show ... -o table`
- what's deployed: `az resource list --tag purpose=az104-lab -o table`

## Make Claude check itself

- "Check that against Microsoft Learn."
- "How sure are you? What could make this wrong?"
- "Is this the exam answer or how it works in practice — are those different?"

## Teach it back

```
Let me explain <concept> in my own words — tell me what's wrong or missing.
```

## One topic per chat

New topic → new chat inside the Project. Instructions, skills and the study plan come along automatically.

## Wrap up

```
Wrap up
```

Claude then: summarizes what you learned, proposes gaps-list additions, asks you to confirm nothing is left running, and commits the gaps list and Bicep files to this repo after you approve.

## Improve the setup

Labs too easy, hints too revealing, quizzes too long? Say so — the skill or Project instructions get adjusted once, instead of correcting it every chat.

---

These habits map to Anthropic's AI Fluency 4Ds: **Delegation** (pick a mode and hint level), **Description** (state your situation, paste evidence), **Discernment** (make Claude check itself), **Diligence** (wrap up, clean up, commit).
