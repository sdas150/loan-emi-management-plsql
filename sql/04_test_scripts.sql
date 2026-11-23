-- ==========================================================
-- 04_test_scripts.sql
-- Sample Data, Execution & Verification Queries
-- ==========================================================

SET SERVEROUTPUT ON;

-- 1. Insert sample customers
INSERT INTO customers (full_name, email, credit_score) VALUES ('Aarav Sharma', 'aarav.sharma@example.com', 780);
INSERT INTO customers (full_name, email, credit_score) VALUES ('Priya Nair', 'priya.nair@example.com', 610);
COMMIT;

-- 2. Create a valid loan (100,000 at 10.5% annual interest for 6 months)
BEGIN
    pkg_loan_mgmt.create_loan_with_schedule(
        p_cust_id   => 1,
        p_principal => 100000,
        p_rate      => 10.5,
        p_months    => 6
    );
END;
/

-- 3. Pay the first EMI
BEGIN
    pkg_loan_mgmt.pay_emi(p_emi_id => 1);
END;
/

-- 4. Simulate an overdue EMI and run penalty batch job
UPDATE emi_schedule
SET due_date = TRUNC(SYSDATE) - 5
WHERE emi_id = 2;
COMMIT;

BEGIN
    pkg_loan_mgmt.apply_overdue_penalties;
END;
/

-- 5. Verify results
SELECT * FROM loans;
SELECT * FROM emi_schedule ORDER BY installment_no;
SELECT * FROM audit_log;
