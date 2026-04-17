# Workflow Recipes

Step-by-step guides for common development tasks to ensure consistency and quality.

## 📦 Recipe: Adding a New Backend Resource
1.  **Define Model/Schema**: Create the data model and any required validation schemas.
2.  **Logic Layer**: Implement the business logic (CRUD, services, utilities).
3.  **Endpoint**: Expose the logic via a RESTful or GraphQL endpoint.
    - Apply security/RBAC dependencies.
    - Ensure standard naming conventions (e.g., plural nouns).
4.  **Verification**: Test the endpoint with various inputs (valid, invalid, unauthorized).
5.  **Documentation**: Update relevant Design Docs or Knowledge Base entries.

## 🎨 Recipe: Implementing a New UI Feature
1.  **Component Structure**: Create the UI components using the project's design system.
2.  **State Integration**: Connect the component to relevant state management or data fetching hooks.
3.  **Interaction Polish**: Add transitions, hover effects, and loading states.
4.  **Hydration Check**: Ensure the feature works correctly under SSR/Client-side rendering conditions.
5.  **Audit**: Verify responsiveness and accessibility.

## 🚀 Recipe: Feature Lifecycle & Milestones
1.  **Preparation**: Sync with the latest main/production branch.
2.  **Milestone Summary**: Add a new entry to `docs/design_docs/00_milestone_summary.md`.
3.  **Design Doc**: Create/Update a specific milestone file in `docs/design_docs/`.
4.  **Development**: Build the feature following the `Plan -> Approve -> Execute` loop.
5.  **Lessons Learned**: If significant hurdles occurred, document them in `docs/knowledge_base/`.
6.  **Walkthrough**: Provide a functional description and verification results in the milestone doc.

## 🛠 Recipe: Troubleshooting & Knowledge Capture
1.  **Identify**: Debug the issue and find the root cause.
2.  **Resolve**: Implement the fix and verify it doesn't break existing functionality.
3.  **Document**: Create a new entry in `docs/knowledge_base/` if:
    - The resolution was non-obvious.
    - It involves a project-specific constraint (e.g., CORS, Auth logic).
    - It's a "Lesson Learned" to prevent future regressions.
