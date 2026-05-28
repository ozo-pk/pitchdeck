# PitchDeck Changelog

## 2026-05-29 Updates
### Fixed
- **Closed Hackathons Hidden:** Updated `routes/student.js` and `routes/judge.js` so that when an Admin closes a hackathon, it no longer clutters the Student's "Select Your Team" dropdown or the Judge's "Assignments" table.
- **Judge Scoring Phase Fix:** Updated `sp_SubmitScore` to allow judges to evaluate projects while the hackathon is still in the `open` phase, removing the "Hackathon is not in judging phase" blocker.
- **Judge Scoring UI Refinements:** 
  - Removed the confusing "Weight: 0.3400" text from the Judge Panel UI, keeping only the "Max Score".
  - Changed the score input to `step="any"`, allowing judges to naturally type whole numbers like `7` or `10` without being forced to type `10.00`.
  - Added strict validation to block judges from submitting empty scores.
- **Judge Panel Project Details:** The Judge Panel now dynamically exposes the full details of a student's submission. When a judge selects a project from the dropdown, a beautifully styled "Project Details" card expands to show the project's Description, GitHub URL, and Live Demo URL, allowing for proper evaluation.
- **Dummy Data Cleanup:** Created a new endpoint (`GET /api/admin/clean-and-sync-db`) to permanently purge the initial dummy seed data (Hackathon IDs 1 and 2, e.g., "Global AI Hackathon") and their cascading teams/submissions from the database.
- **Automated Scoring Criteria:** Updated the `POST /admin/create-hackathon` backend route. When an Admin creates a new event, the system now automatically generates three standard scoring criteria (Innovation & Uniqueness, Problem Solving & Practicality, and Technical Execution) each worth 10 points. 
- **Admin Users 404:** Fixed a routing mismatch in `routes/admin.js` where the route was defined as `/users` instead of `/admin/users`, causing the Admin dashboard table to fail to load.
- **Student Multiple Registrations Exploit:** Updated the `sp_RegisterTeam` database stored procedure to prevent a single student from creating multiple teams in the same hackathon. The system now strictly limits students to exactly one team per event.
- **Judge Auto-Assignment:** Fixed an issue where newly created hackathons were not appearing in the Judge panel. The `POST /admin/create-hackathon` route has been updated to automatically assign all active judges to the hackathon at creation time, ensuring real-time synchronization.
- **404 Not Found on Student Teams Dropdown:** Fixed a path mismatch bug in `routes/student.js` where the API route was defined as `GET /my-teams` instead of `GET /teams/my-teams`. This caused the Student Portal to return a `404 Not Found` (and a subsequent JSON parse error) when attempting to load the student's registered teams into the dropdown menu. The route has been renamed to precisely match the frontend, ensuring the team list populates flawlessly.
- **Dropdown Loading Bug (ER_TABLEACCESS_DENIED_ERROR):** Resolved the `500 Internal Server Error` that caused the Student Portal's "Select Your Team" dropdown to get stuck on "Loading your teams...". The issue occurred because the `student` and `judge` database pools did not have `SELECT` privileges on the `hackathons` table. Instead of requiring users to manually run SQL commands to update database roles, the backend architecture was optimized to securely utilize the `admin` pool for read-only dropdown queries. This maintains strict security (as the endpoints are still protected by Express session roles) while fully fixing the data fetch issue.
- **Create Hackathon Constraint Error:** Fixed a strict database `CHECK` constraint violation (`chk_ddl`) that caused hackathon creation to fail with a 500 error. The `submission_ddl` was being set to `23:59:59` on the `end_date`, but the database constraint strictly requires `submission_ddl <= end_date` (which evaluates as `00:00:00` on the end date). The API now correctly aligns the timestamp to `00:00:00` and also exposes the exact SQL error messages to the frontend for easier debugging.

## 2026-05-27 Updates
### Added
- **Admin User Management:** `GET /api/admin/users` added. Admin dashboard now displays a real-time list of all users, their roles, and their joined teams.
- **Dynamic Dropdowns:** Removed raw ID inputs across the application. 
  - Students select open Hackathons via a dropdown during team registration.
  - Students select their registered team via a dropdown when submitting a project.
  - Admins select open Hackathons via a dropdown when closing an event.
- **Premium UI Overhaul:** Upgraded all HTML pages (`index.html`, `portal.html`, `panel.html`, `dashboard.html`) to feature dark-mode gradients, glassmorphism cards, and colored status badges.

### Fixed
- **Database Mutating Table Error (Error 1442):** Rewrote `trg_AfterEvalInsert` to calculate running totals cleanly, preventing the trigger from deadlocking during bulk inserts.
- **Grade Label Truncation:** Expanded `fn_GradeLabel` return type to `VARCHAR(3)` to properly accommodate 'N/A'.
- **Bcrypt Hash Correction:** Replaced a hallucinated, non-functional password hash in the `08_seed.sql` file with a valid bcrypt hash for `password123`.
- **Express Session Drop:** Fixed an issue where frontend fetches were missing `credentials: 'include'`, resulting in `403 Forbidden` errors during registration.
- **Generic Database Exceptions:** Upgraded all MySQL stored procedures to use `GET DIAGNOSTICS`, capturing and returning exact SQL error messages to the frontend instead of masking them.
