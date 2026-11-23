-- ==========================================================
-- 03_triggers.sql
-- Business Rule Enforcement & Audit Triggers
-- ==========================================================

-- 1. Reject loans for customers with credit score below 650
CREATE OR REPLACE TRIGGER trg_validate_credit_score
BEFORE INSERT ON loans
FOR EACH ROW
DECLARE
    v_score customers.credit_score%TYPE;
BEGIN
    SELECT credit_score INTO v_score
    FROM customers
    WHERE cust_id = :NEW.cust_id;

    IF v_score < 650 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Loan rejected: Credit score (' || v_score || ') is below minimum threshold of 650.');
    END IF;
END;
/

-- 2. Log every newly approved loan in the audit table
CREATE OR REPLACE TRIGGER trg_audit_new_loan
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (action_desc)
    VALUES ('Loan ID ' || :NEW.loan_id || ' approved for Customer ID ' || :NEW.cust_id || ' | Principal: ' || :NEW.principal);
END;
/
