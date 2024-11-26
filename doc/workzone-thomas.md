# WORKZONE 

TODO: Look at the database. 

TODO: Look at all Supabase interactions on the current app. 

TODO: Test new database functions. 

TODO: Add new database functions. 


Tables: 
- users
  - (types of users)
    - lenders
    - borrowers
    - contractors
    - inspectors
- construction_loans
- cost_categories
- draw_requests
  - ()
    - draw_request_line_items



- USERS: 
  - `users`
  - `lenders`
  - `borrowers`
  - `contractors`
  - `inspectors`
- INSPECTIONS: 
  - `inspection_reports`
  - `inspection_categories`
- DRAW REQUESTS: 
  - `draw_requests`
  - `draw_request_line_items`
- CONSTRUCTION_LOANS
  - construction_loans
  - `cost_categories`



Chretien Banza - contractor
Miles Morales - lender
Donald Trump - BORROWER. 
Allan Pinkerton - inspector
Caspar Weinberger 
Paul Warburg
claude
israel 


There are foreign key relations in the definition of the table on Supabase. 




-------------

Essential RLS Policies for Construction Loan App

```sql
-- 1. Users can only view loans they're involved with
ALTER TABLE construction_loans ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_involved_loans ON construction_loans
    FOR SELECT
    USING (
        -- Check if current user is the lender, contractor, borrower, or inspector for this loan
        loan_id IN (
            SELECT loan_id 
            FROM construction_loans
            WHERE 
                lender_id IN (SELECT lender_id FROM lenders WHERE user_id = auth.uid())
                OR contractor_id IN (SELECT contractor_id FROM contractors WHERE user_id = auth.uid())
                OR borrower_id IN (SELECT borrower_id FROM borrowers WHERE user_id = auth.uid())
                OR inspector_id IN (SELECT inspector_id FROM inspectors WHERE user_id = auth.uid())
        )
    );

-- 2. Only contractors can create draw requests, and only for their loans
ALTER TABLE draw_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY contractor_create_draw_requests ON draw_requests
    FOR INSERT
    WITH CHECK (
        loan_id IN (
            SELECT loan_id 
            FROM construction_loans 
            WHERE contractor_id = (
                SELECT contractor_id 
                FROM contractors 
                WHERE user_id = auth.uid()
            )
        )
    );

-- 3. Only lenders can approve/reject draw requests, and only for their loans
CREATE POLICY lender_update_draw_requests ON draw_requests
    FOR UPDATE
    USING (
        loan_id IN (
            SELECT loan_id 
            FROM construction_loans 
            WHERE lender_id = (
                SELECT lender_id 
                FROM lenders 
                WHERE lender_id = auth.uid()
            )
        )
    );

-- 4. Only inspectors can create inspection reports, and only for their assigned loans
ALTER TABLE inspection_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY inspector_create_reports ON inspection_reports
    FOR INSERT
    WITH CHECK (
        loan_id IN (
            SELECT loan_id 
            FROM construction_loans 
            WHERE inspector_id = (
                SELECT inspector_id 
                FROM inspectors 
                WHERE user_id = auth.uid()
            )
        )
    );
```