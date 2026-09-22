# The register

Comments are written in ASD-STE100, Simplified Technical English: a controlled language written so that a reader who is not a native speaker, working under time pressure, gets one meaning on the first pass. A comment is read in exactly those conditions — in the middle of an edit, by whoever is about to change the line

The specification is free from `asd-ste100.org` and is not restated here. What follows is only what the specification does not decide for us

## What is taken, and what is not

The **writing rules** are taken. The **dictionary** is not

The dictionary is roughly nine hundred approved words, each with one part of speech and one meaning. It was built for aerospace maintenance and carries no `derivation`, no `socket`, no `milter`. The specification anticipates this: technical names and technical verbs from the subject at hand are allowed beyond the list. The dictionary is also copyrighted by ASD and cannot be redistributed, so no copy of it travels with this skill

One consequence is worth stating, because it does not follow from the rules alone. The dictionary is what forbids a word in a figurative sense, so without it nothing here forbids `the check fires` or `the file holds a fact`. We forbid it anyway: a plain sense reads faster for the reader this register exists for. That is a decision, not a consequence of the standard

## The one deviation

The standard allows the passive in descriptive text when the agent is unknown. For a comment about configuration the agent is known — whoever wrote the line — and irrelevant, which is not the same thing. The passive is allowed here when the agent is unknown **or irrelevant**

Without this, a comment stating an arrangement has to invent an actor for it:

> `reject_unlisted_recipient is stated rather than left implicit: the implicit form runs after this list`

is exact, and rewriting it around a subject would add a person nobody needs

## How it reads on real comments

Length first. Under the register the same facts take more lines, not fewer — that is the price, and it is paid deliberately

Before, one sentence of forty-two words carrying three facts:

> the floor is written twice because Postfix asks two different settings for it — smtpd_tls_protocols answers for "may", which is :25 and the alert intake, and smtpd_tls_mandatory_protocols for "encrypt", which is both submission ports

After, the same three facts as three sentences:

> Postfix asks two settings for the floor, so it is written twice. smtpd_tls_protocols answers for "may": port 25 and the alert intake. smtpd_tls_mandatory_protocols answers for "encrypt": both submission ports

Then the plain sense of a word:

| Instead of | Write |
|---|---|
| the check fires on an unpinned line | the check reports an unpinned line |
| this file holds the fingerprint | this file contains the fingerprint |
| the rule lives in the module that gates it | the rule is defined in the module that gates it |
| the guard stays quiet for a vendored copy | the guard ignores a vendored copy |

And the shapes the rules forbid outright:

| Instead of | Write |
|---|---|
| Disabling the policy clears trust | The disabled policy clears trust |
| We have moved this to the seam | This moved to the seam |
| a node's boot-time secret decryption step | the step that decrypts secrets at boot |

## Where the register does not apply

The prose of a skill — a `SKILL.md`, a page under `references/` — is read whole and without hurry, and a sentence there often carries a condition, its consequence and its exception together. Splitting it into three leaves the reader to reassemble the connection. That prose keeps the denser register; everything a stranger meets once does not
