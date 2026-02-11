# Product Requirements Document (PRD)
## Product: Mobile PDF + AI Suite (React Native)

- Version: 1.0
- Date: 2026-02-11
- Author: Product/Engineering

## 1) Product Summary
Build a cross-platform mobile app (iOS + Android) in React Native that provides full PDF workflow coverage inspired by iLovePDF and iHatePDF, including:
- Full PDF tool suite (organize, optimize, convert, edit, security)
- Mobile-native workflows (scan, annotate, share, file manager)
- eSignature (self-sign + request signatures)
- AI document workflows (chat, summary, research extraction)
- Free + Premium + Business monetization

## 2) Competitive Analysis (What to Replicate and Improve)

### iLovePDF strengths
- Very broad PDF tool coverage across web/mobile/desktop.
- Mature pricing/limits model (free vs premium/business).
- Strong trust signals: security page, ISO 27001, GDPR messaging, 2FA, retention policies.
- Mobile messaging emphasizes scan/edit/share, annotations, signing, and file management.

### iHatePDF strengths
- Simple, aggressive positioning: no-account experience, speed, lightweight UX.
- Includes AI-first tools (PDF summary, chat with PDF, research analyzer).
- Referral/credit growth loop.

### Opportunities for our app
- Best-of-both: iLovePDF breadth + iHatePDF simplicity and AI velocity.
- Clearer security language (avoid contradictory claims).
- Better mobile UX for large files, offline queueing, and cloud handoff.

## 3) Goals and Non-Goals

### Goals
1. Achieve feature parity with both competitors' publicly listed PDF + AI toolsets.
2. Deliver fast, reliable mobile document processing at scale.
3. Support both guest mode (no account) and full account workflows.
4. Monetize via subscription + AI credits + team/business controls.

### Non-Goals (V1)
1. Full desktop app.
2. Custom on-prem deployments.
3. Advanced legal eSignature jurisdictions beyond standard SES/AES scope.

## 4) User Personas
1. Student: compress/convert/scan/sign assignments.
2. Professional: redact, protect, compare, workflow automation.
3. Operations/Admin: batch processing, templates, team controls.
4. Research user: summarize papers, chat with PDF, extract sections.

## 5) Full Feature Scope (All Features)

### A. Organize PDF
1. Merge PDF
2. Split PDF
3. Remove pages
4. Extract pages
5. Organize/reorder pages
6. Scan to PDF

### B. Optimize PDF
1. Compress PDF (multiple quality levels)
2. Repair PDF
3. OCR PDF (searchable text extraction)

### C. Convert to PDF
1. JPG to PDF
2. Word to PDF
3. PowerPoint to PDF
4. Excel to PDF
5. HTML/URL to PDF

### D. Convert from PDF
1. PDF to JPG
2. PDF to Word
3. PDF to PowerPoint
4. PDF to Excel
5. PDF to PDF/A

### E. Edit PDF
1. Rotate PDF
2. Add page numbers
3. Add watermark (text/image)
4. Crop PDF
5. Edit PDF (text/image/shape/annotation)

### F. PDF Security
1. Unlock PDF
2. Protect PDF (password/encryption)
3. Sign PDF (self-sign)
4. Signature request workflow
5. Redact PDF
6. Compare PDF

### G. AI Tool Box
1. PDF to Summary
2. Chat with PDF
3. Research Analyzer (extract abstract/methods/results/conclusion)

### H. Mobile Productivity Features
1. Document scanner (camera -> PDF)
2. PDF reader
3. Annotation/comments/markup
4. Mobile file manager (folders, recent, favorites)
5. Share/export to apps
6. Cloud import/export (Google Drive, Dropbox)
7. Optional offline/local processing queue where feasible

### I. Account, Billing, and Growth
1. Guest mode (no signup required for core tools)
2. Email/social auth for synced experience
3. Subscription tiers (Free, Premium, Business)
4. AI credits and purchase flows
5. Referral credits
6. In-app restore purchases
7. Team management (Business)

### J. Business Features
1. Team/workspace management
2. Shared defaults/templates
3. Workflows presets
4. SSO (Business tier)
5. Regional processing controls
6. Audit trail for signature requests
7. Custom branding for signature requests/templates

## 6) Functional Requirements

### FR-1 File Intake
1. User can import files from local storage, camera scan, Google Drive, Dropbox, and share sheet.
2. User can upload one or multiple files based on tool constraints.
3. Drag-reorder must be supported where sequencing matters (merge/organize).

### FR-2 Job Processing
1. Every operation runs as a trackable job with statuses: queued, processing, done, failed.
2. Large jobs must support background handling and resumable uploads.
3. Retriable failures must surface actionable errors.

### FR-3 Output & Delivery
1. Users can preview outputs before saving/sharing where applicable.
2. Users can save to device, cloud storage, or share to external apps.
3. Output history available for signed-in users; temporary for guest users.

### FR-4 AI
1. AI tools must support citations/page references for answers and summaries.
2. AI responses must include confidence + regenerate.
3. Credit burn and balance visibility required before confirm.

### FR-5 Signing
1. Self-sign and request-sign flows.
2. Reminder notifications, status tracking, and downloadable signed copy.
3. Signed document retention policy configurable by legal requirements.

### FR-6 Security
1. TLS in transit and encryption at rest.
2. Auto-deletion policy for temporary files (configurable by plan).
3. PII/data handling controls and consent screens.
4. Optional 2FA for accounts.

### FR-7 Plans & Limits
1. Free plan: limited tool quotas and file sizes.
2. Premium plan: expanded limits + ad-free + full mobile features.
3. Business plan: team, SSO, regional processing, advanced support.
4. Separate AI credits ledger with top-up packs.

## 7) UX Requirements
1. One-tap tool entry from home with category filters.
2. Persist last used tools and “Recent actions”.
3. Minimal-friction guest flow (no forced signup for core actions).
4. Clear progress UI for long-running jobs.
5. Accessible UI (dynamic type, screen reader labels, contrast compliance).

## 8) Technical Architecture (React Native)

### Mobile App
1. React Native + TypeScript.
2. State/data: Redux Toolkit or Zustand + React Query.
3. Navigation: React Navigation.
4. Storage: secure token storage + encrypted local cache.
5. Uploads/downloads: background transfer support.

### Backend
1. API Gateway + Auth service.
2. Document processing orchestration service.
3. Worker pools:
- PDF core workers (merge/split/compress/etc.)
- OCR workers
- Conversion workers (office/image/html)
- Signature workers
- AI workers (RAG/chat/summarization)
4. Object storage (temporary + durable tiers).
5. Queue/event bus for async jobs.
6. Billing + subscription + credit ledger services.

### AI Architecture
1. Document chunking + embedding index.
2. Retrieval-augmented generation with source-grounded responses.
3. Prompt templates per AI tool (summary/chat/research sections).
4. Safety filters + abuse controls + token/cost governance.

## 9) Data Model (Core)
1. User
2. Workspace/Team
3. Document
4. ProcessingJob
5. OutputArtifact
6. Subscription
7. CreditWallet + CreditTransaction
8. SignatureRequest + Signer + AuditEvent

## 10) Non-Functional Requirements
1. P95 API latency (job create): < 600 ms.
2. P95 completion for small jobs: < 12 s.
3. Crash-free sessions: > 99.5%.
4. Service uptime: 99.9% monthly.
5. GDPR-ready data lifecycle and deletion workflows.

## 11) Analytics and KPIs
1. Activation: first successful processed file within 10 minutes.
2. D1/D7 retention by persona.
3. Conversion: free -> premium.
4. AI attach rate and credit purchase rate.
5. Signature request completion rate.
6. Average processing time per tool.

## 12) Release Plan

### Phase 1 (MVP Core PDF)
1. Intake, merge/split/compress, JPG<->PDF, Word/Excel/PPT basic flows, viewer, share.

### Phase 2 (Advanced PDF)
1. OCR, repair, organize, watermark/page numbers, protect/unlock, crop, rotate.

### Phase 3 (Sign + Business)
1. Self-sign, request signatures, templates, reminders, team basics.

### Phase 4 (AI)
1. Summary, chat with PDF, research analyzer, credits.

### Phase 5 (Enterprise)
1. SSO, regional processing, advanced audit/compliance controls.

## 13) Risks and Mitigations
1. Conversion fidelity variance.
- Mitigation: golden-file regression tests per format pair.
2. High compute costs for AI/OCR.
- Mitigation: queue shaping, caching, credit gating, model routing.
3. Security trust gaps from unclear data policy.
- Mitigation: single transparent retention statement and in-app deletion controls.
4. App-store policy risk for signing/billing claims.
- Mitigation: legal review and compliant purchase messaging.

## 14) Acceptance Criteria (Launch)
1. All features in Section 5 available on iOS and Android.
2. End-to-end success rate > 98% for top 15 tools.
3. Measured security controls in place (encryption, deletion jobs, audit logs).
4. Premium purchase and restoration working on both platforms.
5. AI tools show citations and consume credits correctly.

## 15) Source Notes (Competitor Inputs)
1. iLovePDF home/tools/features/pricing/mobile/security/faq pages used to map tool inventory, plans, limits, and security posture.
2. iHatePDF home/legal/our-story and indexed tool snippets used to map AI features, referral model, no-account positioning, and messaging.

