# DevFitCheck — Project Roadmap

A developer job-matching platform that scores fit based on responsibilities and tech stack, not just job titles. Built as a hands-on learning project.

> **Note on planning depth:** Phase 1 is broken down in full detail since it's the immediate next step. Phases 2–5 are kept high-level and will be elaborated closer to when work on them begins — requirements and design will naturally evolve once earlier phases are built and tested.

---

## Phase 0 — Planning & Setup ✅

- [x] Define feature scope and core user journeys
- [x] Choose tech stack
- [x] Setup monorepo structure with Turborepo
- [x] Setup GitHub repo, branch strategy, PR template
- [x] Write initial README with architecture diagram

---

## Phase 1 — Core MVP (React + Node)

**Goal:** Ship a working end-to-end flow (auth, job posting, application) before adding the Go matching engine, Redis, or async processing.

### Backend — Node.js + Fastify + TypeScript
- [ ] Setup Fastify + TypeScript project structure in `apps/api`
- [ ] Design PostgreSQL schema: `users`, `jobs`, `applications`, `tech_stacks`
- [ ] Implement Auth — register endpoint with bcrypt password hashing
- [ ] Implement Auth — login endpoint with JWT access + refresh tokens
- [ ] Build User profile CRUD API
- [ ] Build Job posting CRUD API
- [ ] Build Application CRUD API (apply to job / view applicants)
- [ ] Add input validation with Zod + centralized error handling middleware
- [ ] Write unit tests for auth flow and core business logic

### Frontend — Next.js + TypeScript + Tailwind
- [ ] Setup Next.js + TypeScript + Tailwind in `apps/frontend`
- [ ] Build Landing page
- [ ] Build Register / Login forms
- [ ] Build Job listing page with basic tech-stack filter
- [ ] Build Job detail page + Apply button
- [ ] Build Developer dashboard (view applied jobs)
- [ ] Build Company dashboard (view applicants)

### DevOps
- [ ] Write Dockerfile for `apps/api`
- [ ] Write Dockerfile for `apps/frontend`
- [ ] Write `docker-compose.yml` to run all services together

**Definition of done:** A developer can register, browse jobs, and apply. A company can register, post a job, and view applicants — all running locally via `docker compose up`.

---

## Phase 2 — Go Matching Engine

**Goal:** Introduce a second service to practice cross-service communication and offload CPU-heavy work.

- [ ] Learn Go fundamentals (structs, goroutines, channels, error handling)
- [ ] Scaffold Go service with its own Dockerfile
- [ ] Build resume parser (start with keyword extraction, upgrade to AI later)
- [ ] Build matching algorithm (weighted score based on tech-stack overlap)
- [ ] Connect Node ↔ Go via gRPC (define `.proto` contracts)
- [ ] Write integration tests across both services

**Definition of done:** When a developer applies to a job, the system calculates and displays a match score.

---

## Phase 3 — Redis, Queue & Async Processing

**Goal:** Move from a fully synchronous system to an async architecture.

- [ ] Add Redis caching for frequently-queried job listings
- [ ] Add Redis-backed session store
- [ ] Add Redis-based rate limiting on write endpoints
- [ ] Set up a message queue (RabbitMQ or Redis Streams) for async jobs
- [ ] Make resume upload async: upload → publish event → Go worker parses → writes result
- [ ] Add real-time notification (WebSocket or SSE) when parsing completes

**Definition of done:** Resume upload doesn't block the user; a background worker processes it and the UI updates in real time.

---

## Phase 4 — CI/CD, Third-Party & AI Integration

**Goal:** Make the project deployable and add real third-party integrations.

- [ ] GitHub Actions: lint + test on every PR
- [ ] GitHub Actions: build & push Docker images
- [ ] Auto-deploy to staging on merge to `dev`
- [ ] Manual-approve deploy to production on merge to `main`
- [ ] Integrate Claude/OpenAI API for resume analysis and skill-gap suggestions
- [ ] Integrate GitHub API to verify claimed tech stack against real repos
- [ ] Integrate email provider (Resend/SendGrid) for job-match notifications
- [ ] (Optional) Integrate Stripe for a "boost profile" premium feature

**Definition of done:** The app is live at a public URL with an automated deploy pipeline and at least one working AI feature.

---

## Phase 5 — Production Hardening & Observability

**Goal:** Push the project toward production-grade quality — this is what separates a portfolio project from a tutorial clone.

- [ ] Add Prometheus + Grafana for metrics dashboards
- [ ] Add structured, centralized logging
- [ ] Document the API with OpenAPI/Swagger
- [ ] Load test with k6 or Locust
- [ ] Apply OWASP basics (SQLi, XSS, rate limiting, CORS)
- [ ] Optimize database indexes based on load-test results
- [ ] (Advanced) Explore Kubernetes for orchestration

---

## Guiding Principle

Don't perfect one phase before moving to the next — get a full loop working end-to-end early (even if simple), then layer in complexity. This keeps a working demo available at all times instead of several half-finished phases with nothing to show.