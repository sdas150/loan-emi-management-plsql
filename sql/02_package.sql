-- ==========================================================
-- 02_package.sql
-- PL/SQL Package Specification and Body
-- ==========================================================

CREATE OR REPLACE PACKAGE pkg_loan_mgmt AS
    FUNCTION calc_emi(
        p_principal   NUMBER,
        p_annual_rate NUMBER,
        p_months      NUMBER
    ) RETURN NUMBER;

    PROCEDURE create_loan_with_schedule(
        p_cust_id   NUMBER,
        p_principal NUMBER,
        p_rate      NUMBER,
        p_months    NUMBER
    );

    PROCEDURE pay_emi(
        p_emi_id NUMBER
    );

    PROCEDURE apply_overdue_penalties;
END pkg_loan_mgmt;
/

CREATE OR REPLACE PACKAGE BODY pkg_loan_mgmt AS

    FUNCTION calc_emi(
        p_principal   NUMBER,
        p_annual_rate NUMBER,
        p_months      NUMBER
    ) RETURN NUMBER IS
        v_monthly_rate NUMBER;
        v_emi          NUMBER;
    BEGIN
        v_monthly_rate := (p_annual_rate / 12) / 100;
        v_emi := (p_principal * v_monthly_rate * POWER(1 + v_monthly_rate, p_months)) /
                 (POWER(1 + v_monthly_rate, p_months) - 1);
        RETURN ROUND(v_emi, 2);
    END calc_emi;

    PROCEDURE create_loan_with_schedule(
        p_cust_id   NUMBER,
        p_principal NUMBER,
        p_rate      NUMBER,
        p_months    NUMBER
    ) IS
        v_loan_id NUMBER;
        v_emi     NUMBER;
    BEGIN
        INSERT INTO loans (cust_id, principal, interest_rate, tenure_months)
        VALUES (p_cust_id, p_principal, p_rate, p_months)
        RETURNING loan_id INTO v_loan_id;

        v_emi := calc_emi(p_principal, p_rate, p_months);

        FOR i IN 1..p_months LOOP
            INSERT INTO emi_schedule (loan_id, installment_no, due_date, emi_amount)
            VALUES (v_loan_id, i, ADD_MONTHS(TRUNC(SYSDATE), i), v_emi);
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Loan ID ' || v_loan_id || ' created with monthly EMI: ' || v_emi);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Loan creation failed: ' || SQLERRM);
    END create_loan_with_schedule;

    PROCEDURE pay_emi(
        p_emi_id NUMBER
    ) IS
        v_loan_id       NUMBER;
        v_pending_count NUMBER;
    BEGIN
        UPDATE emi_schedule
        SET payment_status = 'PAID',
            paid_date = SYSDATE
        WHERE emi_id = p_emi_id
          AND payment_status IN ('PENDING', 'OVERDUE')
        RETURNING loan_id INTO v_loan_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'EMI ID not found or already paid.');
        END IF;

        SELECT COUNT(*)
        INTO v_pending_count
        FROM emi_schedule
        WHERE loan_id = v_loan_id
          AND payment_status != 'PAID';

        IF v_pending_count = 0 THEN
            UPDATE loans
            SET status = 'CLOSED'
            WHERE loan_id = v_loan_id;
        END IF;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('EMI ID ' || p_emi_id || ' marked as PAID.');
    END pay_emi;

    PROCEDURE apply_overdue_penalties IS
        CURSOR c_overdue IS
            SELECT emi_id, emi_amount
            FROM emi_schedule
            WHERE payment_status = 'PENDING'
              AND due_date < TRUNC(SYSDATE)
            FOR UPDATE;
    BEGIN
        FOR rec IN c_overdue LOOP
            UPDATE emi_schedule
            SET payment_status = 'OVERDUE',
                penalty_fee = ROUND(rec.emi_amount * 0.02, 2)
            WHERE CURRENT OF c_overdue;
        END LOOP;
        COMMIT;
    END apply_overdue_penalties;

END pkg_loan_mgmt;
/
