# Draft Before Create: Story Creation and Push Guard

> This is a scrubbed excerpt from a real Claude Code session demonstrating
> the draft-before-create pattern and the push-guard hook. Names, paths,
> and project details have been genericized.

---

**You:** create a story for the new onboarding flow

**Claude:** Drafting it first for your review before anything goes into the tracker.

---

**DRAFT: Linear Story**

**Title:** Build new user onboarding flow

**Description:**
New users currently land on the dashboard with no guidance. This story covers building a
step-by-step onboarding flow that runs on first login and helps users complete their initial
setup before reaching the main product.

**Acceptance Criteria:**
- [ ] Onboarding flow triggers automatically on first login (not on subsequent logins)
- [ ] Flow covers three steps: profile setup, invite teammates, connect first integration
- [ ] Users can skip any step and return to it later from account settings
- [ ] Progress persists across sessions (user can close browser and resume)
- [ ] Flow is skippable in its entirety via a "Skip setup" link on step 1
- [ ] Completion triggers a welcome email via the existing email service

**Labels:** `onboarding`, `growth`
**Estimate:** 3 points
**Team:** Product

---

Let me know if anything needs adjusting before I create it.

---

**You:** two things: it's 5 points not 3, and add a criteria that it works on mobile

**Claude:** Updated:

---

**DRAFT: Linear Story (revised)**

**Title:** Build new user onboarding flow

**Description:**
New users currently land on the dashboard with no guidance. This story covers building a
step-by-step onboarding flow that runs on first login and helps users complete their initial
setup before reaching the main product.

**Acceptance Criteria:**
- [ ] Onboarding flow triggers automatically on first login (not on subsequent logins)
- [ ] Flow covers three steps: profile setup, invite teammates, connect first integration
- [ ] Users can skip any step and return to it later from account settings
- [ ] Progress persists across sessions (user can close browser and resume)
- [ ] Flow is skippable in its entirety via a "Skip setup" link on step 1
- [ ] Completion triggers a welcome email via the existing email service
- [ ] All steps are fully functional on mobile viewports (320px and up)

**Labels:** `onboarding`, `growth`
**Estimate:** 5 points
**Team:** Product

---

Ready to create this?

---

**You:** yes create it

**Claude:** `[Creating Linear story via API...]`

Created: **LIN-892** "Build new user onboarding flow" (5 pts, onboarding/growth)
Link: linear.app/acme/issue/LIN-892

---

**You:** ok push this branch

**Claude:** `[Push guard hook fired]`

Before I push, confirming the details:

- **Branch:** `feature/onboarding-flow`
- **Remote:** `origin`
- **Commits to push:** 4 commits not yet on remote

The branch has not been pushed before, so this will create a new remote branch. Do you want
to proceed?

---

**You:** yes go ahead

**Claude:** `[Running: git push -u origin feature/onboarding-flow]`

Pushed. Remote branch is live at `origin/feature/onboarding-flow`.

You can open a PR from there whenever ready. Want me to draft one?
