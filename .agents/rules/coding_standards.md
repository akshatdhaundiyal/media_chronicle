---
title: Coding Standards
description: General engineering, UI/UX, security, and performance standards for code maintainability and robustness.
---

# Coding Standards

These standards ensure maintainability, security, and performance across all projects.

## 🛠 Tech Stack Manifest

*   **Runtime/Package Management**: [PLACEHOLDER]
*   **Backend Framework**: [PLACEHOLDER]
*   **Frontend Framework**: [PLACEHOLDER]
*   **Styling Engine**: [PLACEHOLDER]
*   **Database Engine**: [PLACEHOLDER]

---

## 🏗 General Engineering Principles

### 1. Type Integrity
- **Strict Typing**: Use strict type hints and interfaces. Avoid `any` or `dynamic` types unless explicitly justified and documented.
- **Validation**: Every external interface (API, DB, Config) must have a validation layer.

### 2. State Management
- **Modular Design**: Split state by domain or feature. Avoid monolithic global states.
- **Controlled Mutations**: All state changes must be performed via dedicated actions or methods to ensure traceability.

### 3. Separation of Concerns
- **Logic Location**: Business logic belongs in services/actions, UI logic in components, and data logic in models/CRUD utilities.
- **No Leaky Abstractions**: Components should not know about the internals of the database or complex service logic.

---

## 🎨 UI/UX Standards

- **Consistency**: Use a unified design system. Reuse components and styling tokens.
- **Premium Feel**: Use subtle gradients, glassmorphism (where appropriate), and modern typography.
- **Responsiveness**: All features must work seamlessly across multiple breakpoints.
- **Hydration & SSR**: Ensure components are hydration-safe and handle client/server state mismatches (e.g., using `ClientOnly` wrappers).

---

## 🔒 Security Standards

- **Authentication**: All sensitive routes must be protected by a standard authentication layer.
- **Authorization (RBAC)**: Implement role-based access control for both frontend views and backend endpoints.
- **Data Protection**: Ensure all database queries are parameterized to prevent injection attacks.
- **Error Privacy**: Return structured JSON errors for debugging but avoid leaking system internals or stack traces to the end-user.

---

## ⚡ Performance Standards

- **Reactivity Optimization**: Use shallow tracking for large data sets to avoid overhead.
- **Asynchronous Flow**: Handle loading and error states for every network request.
- **Resource Management**: Properly clean up listeners, timers, and subscriptions.
