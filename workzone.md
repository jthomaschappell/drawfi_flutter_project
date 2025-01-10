Thomas's Notes while writing code: 
- when I submit this, I anticipate that a new loan will show up in the database. WORKS. 
- additionally, each of the construction loan line items will show up. 




Finished 1.9.24 Finished "the error messages on submission of Invitation Screen. "
Finished 1.9.24 "#10.92 On the lender screen, connect the project card to the correct loan dashboard."
And pushed. 


Finished "Connect contractor loan dashboard screen to DB"



#11.4 Connect contractor loan dashboard screen to DB 1.10.24. 



Changes made: 
- There is now a construction_draws table, which looks like: 
- It's got a loan_id, a category_id, draw number, etc. 
- That tells you: 
- loan_id -- what loan it goes under. 

TODO: I think we need drawCells



TODO: Revert your changes. 

TODO: Make the table construction_loan_line_items look like: 
- draw1_amount
- draw2_amount
- draw3_amount
- draw4_amount
- draw1_status
- draw2_status
- draw3_status
- draw4_status


```
create table
  public.construction_loan_draws (
    draw_id uuid not null default extensions.uuid_generate_v4 (),
    loan_id uuid not null,
    category_id uuid not null,
    draw_number integer not null,
    amount numeric(12, 2) not null default 0,
    status text not null default 'pending'::text,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint construction_loan_draws_pkey primary key (draw_id),
    constraint construction_loan_draws_category_id_fkey foreign key (category_id) references construction_loan_line_items (category_id),
    constraint construction_loan_draws_loan_id_fkey foreign key (loan_id) references construction_loans (loan_id)
  ) tablespace pg_default;

create index if not exists idx_construction_loan_draws_lookup on public.construction_loan_draws using btree (loan_id, category_id, draw_number) tablespace pg_default;
```
