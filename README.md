# HTTA v1.4 — Fee Ledger + Editable Coaches + Monthly Dashboard

## IMPORTANT: run the SQL migration first

Before uploading the new `index.html` to GitHub:

1. Open Supabase.
2. Go to **SQL Editor**.
3. Open `SUPABASE_V1_4_MIGRATION.sql` from this ZIP.
4. Copy the whole file into Supabase.
5. Click **Run**.
6. Make sure it completes without an error.
7. Only then replace the GitHub `index.html`.

## Fixes in v1.4

### 1. Coach names are properly editable
Settings now has individual coach rows.
- Rename a coach.
- Add coaches.
- Remove coaches.
- When an existing coach is renamed, students assigned to the old name are updated too.

### 2. Payments no longer double-count when a fee is adjusted
The app now uses a `fee_cycles` ledger.
Every fee cycle stores:
- cycle start/end
- number of months
- fee amount
- amount paid

Payments are applied to the oldest unpaid fee cycle first.
Changing the current cycle's fee changes only that cycle and keeps previous payments intact.

### 3. No fixed monthly fee
When adding/editing a student, enter:
- Number of months
- Total fee amount for that plan

The app does not calculate `monthly fee × months`.

### 4. Number of months is not a dropdown
Any whole number from 1 to 60 can be entered.

### 5. Monthly dashboard
Choose a month on the Dashboard to see:
- New students
- Number of payment transactions
- Fees collected
- Value of fee cycles that started that month

The existing overall KPIs remain as well.

### Fee deadline rule
Still unchanged:
- Fee is due within the first 3 calendar days of each cycle.
- Example: cycle starts 1 Jan -> pay by 3 Jan.

## GitHub files
Upload/keep at repository root:
- index.html
- .nojekyll
- README.md

`SUPABASE_V1_4_MIGRATION.sql` does not need to be hosted publicly after you have run it.
