-- ==========================================================
-- 01_schema.sql
-- Database Tables & Constraints for Loan Management System
-- ==========================================================

CREATE TABLE customers (
    cust_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    VARCHAR2(100) NOT NULL,
    email        VARCHAR2(100) UNIQUE NOT NULL,
    credit_score NUMBER(3) NOT NULL CHECK (credit_score BETWEEN 300 AND 900),
    created_at   DATE DEFAULT SYSDATE
);

CREATE TABLE loans (
    loan_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cust_id       NUMBER NOT NULL REFERENCES customers(cust_id),
    principal     NUMBER(12, 2) NOT NULL CHECK (principal > 0),
    interest_rate NUMBER(5, 2) NOT NULL CHECK (interest_rate > 0),
    tenure_months NUMBER(3) NOT NULL CHECK (tenure_months > 0),
    status        VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED', 'DEFAULTED')),
    created_at    DATE DEFAULT SYSDATE
);

CREATE TABLE emi_schedule (
    emi_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id        NUMBER NOT NULL REFERENCES loans(loan_id),
    installment_no NUMBER(3) NOT NULL,
    due_date       DATE NOT NULL,
    emi_amount     NUMBER(10, 2) NOT NULL,
    penalty_fee    NUMBER(8, 2) DEFAULT 0,
    payment_status VARCHAR2(15) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'OVERDUE')),
    paid_date      DATE
);

CREATE TABLE audit_log (
    log_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_desc VARCHAR2(255) NOT NULL,
    logged_at   TIMESTAMP DEFAULT SYSTIMESTAMP
);
