/* Project Database: healthrecords */
/* Group Members: Nick Tedesco, Emily Connor, Yicheng Zhang */

USE healthrecords;

# Standalone Tables

DROP TABLE IF EXISTS patients;
CREATE TABLE IF NOT EXISTS patients(
	patient_ID INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(100) NOT NULL,
    dob DATE NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS addresses;
CREATE TABLE IF NOT EXISTS addresses(
	address_ID INT PRIMARY KEY NOT NULL,
	address_line_1 VARCHAR(50) NOT NULL,
    address_line_2 VARCHAR(50) NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NULL,
    zip VARCHAR(15) NULL
)engine=InnoDB;

DROP TABLE IF EXISTS practices;
CREATE TABLE IF NOT EXISTS practices(
	practice_ID INT PRIMARY KEY NOT NULL,
    practice_name VARCHAR(150) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS insurance;
CREATE TABLE IF NOT EXISTS insurance(
	insurance_ID INT PRIMARY KEY NOT NULL,
    policy_num VARCHAR(20) NOT NULL,
    deductible INT,
    deductible_met ENUM("yes", "no"),
    plan VARCHAR(50)
)engine=InnoDB;

DROP TABLE IF EXISTS companies;
CREATE TABLE IF NOT EXISTS companies(
	company_ID INT PRIMARY KEY NOT NULL,
	company_name VARCHAR(150) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS doctors;
CREATE TABLE IF NOT EXISTS doctors(
	doctor_ID INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	type VARCHAR(50) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS procedures;
CREATE TABLE IF NOT EXISTS procedures(
	procedure_ID INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS invoices;
CREATE TABLE IF NOT EXISTS invoices(
	invoice_ID INT PRIMARY KEY NOT NULL,
	amount DOUBLE NOT NULL,
    is_paid BOOLEAN NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS pharmacies;
CREATE TABLE IF NOT EXISTS pharmacies(
	pharmacy_ID INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS medications;
CREATE TABLE IF NOT EXISTS medications(
	medication_ID INT PRIMARY KEY NOT NULL,
    med_name VARCHAR(100) NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS payments;
CREATE TABLE IF NOT EXISTS payments(
	payment_ID INT PRIMARY KEY NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
	amount DOUBLE NOT NULL,
    time_stamp DATETIME NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS doctorNotes;
CREATE TABLE IF NOT EXISTS doctorNotes(
	doctorNote_ID INT PRIMARY KEY NOT NULL,
    note VARCHAR(5000) NOT NULL
)engine=InnoDB;

# Simple Junction Tables (Two Connections)

DROP TABLE IF EXISTS insurance_companies;
CREATE TABLE IF NOT EXISTS insurance_companies(
	ic_ID INT PRIMARY KEY NOT NULL,
    fk_insurance_ID INT NOT NULL,
		FOREIGN KEY(fk_insurance_ID)
        REFERENCES insurance(insurance_ID),
	fk_company_ID INT NOT NULL,
		FOREIGN KEY(fk_company_id)
        REFERENCES companies(company_ID)
)engine=InnoDB;

DROP TABLE IF EXISTS patients_insurance;
CREATE TABLE IF NOT EXISTS patients_insurance(
	pi_ID INT PRIMARY KEY NOT NULL,
    fk_patient_ID INT NOT NULL,
		FOREIGN KEY(fk_patient_ID)
        REFERENCES patients(patient_ID),
	fk_insurance_ID INT NOT NULL,
		FOREIGN KEY(fk_insurance_ID)
        REFERENCES insurance(insurance_ID)
)engine=InnoDB;

DROP TABLE IF EXISTS invoices_payments;
CREATE TABLE IF NOT EXISTS invoices_payments(
	ip_ID INT PRIMARY KEY NOT NULL,
	fk_invoice_ID INT NOT NULL,
		FOREIGN KEY(fk_invoice_ID)
        REFERENCES invoices(invoice_ID),
	fk_payment_ID INT NOT NULL,
		FOREIGN KEY(fk_payment_ID)
        REFERENCES payments(payment_ID)
)engine=InnoDB;

# Complex Junction Tables (More than Two Connections, or Reference Another Junction Table)

DROP TABLE IF EXISTS visit_info;
CREATE TABLE IF NOT EXISTS visit_info(
	visit_ID INT PRIMARY KEY NOT NULL,
    fk_patient_ID INT NOT NULL,
		FOREIGN KEY(fk_patient_ID)
        REFERENCES patients(patient_ID),
	fk_doctor_ID INT NOT NULL,
		FOREIGN KEY(fk_doctor_ID)
        REFERENCES doctors(doctor_ID),
	fk_practice_ID INT NOT NULL,
		FOREIGN KEY(fk_practice_ID)
        REFERENCES practices(practice_ID),
	fk_invoice_ID INT NOT NULL,
		FOREIGN KEY(fk_invoice_ID)
        REFERENCES invoices(invoice_ID),
	visit_date DATE NOT NULL
)engine=InnoDB;

DROP TABLE IF EXISTS prescription_info;
CREATE TABLE IF NOT EXISTS prescription_info(
	prescription_ID INT PRIMARY KEY NOT NULL,
    fk_medication_ID INT NOT NULL,
		FOREIGN KEY(fk_medication_ID)
        REFERENCES medications(medication_ID),
	fk_pharmacy_ID INT NOT NULL,
		FOREIGN KEY(fk_pharmacy_ID)
        REFERENCES pharmacies(pharmacy_ID),
	fk_visit_ID INT NOT NULL,
		FOREIGN KEY(fk_visit_ID)
        REFERENCES visit_info(visit_ID),
	fk_doctor_ID INT NOT NULL,
		FOREIGN KEY(fk_doctor_ID)
        REFERENCES doctors(doctor_ID)
)engine=InnoDB;

DROP TABLE IF EXISTS address_info;
CREATE TABLE IF NOT EXISTS address_info(
	relation_ID INT PRIMARY KEY NOT NULL,
    fk_address_ID INT NOT NULL,
		FOREIGN KEY(fk_address_ID)
        REFERENCES addresses(address_ID),
    fk_patient_ID INT NULL,
		FOREIGN KEY(fk_patient_id)
        REFERENCES patients(patient_id),
	fk_company_ID INT NULL,
		FOREIGN KEY(fk_company_ID)
        REFERENCES companies(company_ID),
	fk_practice_ID INT NULL,
		FOREIGN KEY(fk_practice_ID)
        REFERENCES practices(practice_ID),
	fk_pharmacy_ID INT NULL,
		FOREIGN KEY(fk_pharmacy_ID)
        REFERENCES pharmacies(pharmacy_ID)
)engine=InnoDB;

DROP TABLE IF EXISTS visits_procedures;
CREATE TABLE IF NOT EXISTS visits_procedures(
	vp_ID INT PRIMARY KEY NOT NULL,
    fk_visit_ID INT NOT NULL,
		FOREIGN KEY(fk_visit_ID)
        REFERENCES visit_info(visit_ID),
	fk_procedure_ID INT NOT NULL,
		FOREIGN KEY(fk_procedure_ID)
        REFERENCES procedures(procedure_ID)
)engine=InnoDB;

# Transactions

DROP PROCEDURE IF EXISTS sp_create_new_patient;
DELIMITER $$
CREATE PROCEDURE sp_create_new_patient(IN firstName VARCHAR(50), IN lastName VARCHAR(50), IN input_phone VARCHAR(30), IN input_email VARCHAR(100), IN input_dob DATE, IN addLine1 VARCHAR(50), IN addLine2 VARCHAR(50), IN input_city VARCHAR(50), IN input_state VARCHAR(50), IN input_zip VARCHAR(15))
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @do_rollback := 1;
		SET autocommit = 0;
		SET @do_rollback := 0;

		START TRANSACTION;
		
        IF ((SELECT MAX(patient_ID) FROM patients) IS NULL)
			THEN SET @patient_ID = 1;
		ELSE
			SELECT @patient_ID := MAX(patient_ID) FROM patients;
			SET @patient_ID = @patient_ID + 1;
		END IF;

		INSERT INTO patients(patient_ID, first_name, last_name, phone, email, dob)
        VALUES(@patient_ID, firstName, lastName, input_phone, input_email, input_dob);
        
        IF ((SELECT MAX(address_ID) FROM addresses) IS NULL)
			THEN SET @address_ID = 1;
		ELSE
			SELECT @address_ID := MAX(address_ID) FROM addresses;
			SET @address_ID = @address_ID + 1;
		END IF;
        
        INSERT INTO addresses(address_ID, address_line_1, address_line_2, city, state, zip)
        VALUES(@address_ID, addLine1, addLine2, input_city, input_state, input_zip);
        
        IF ((SELECT MAX(relation_ID) FROM address_info) IS NULL)
			THEN SET @relation_ID = 1;
		ELSE
			SELECT @relation_ID := MAX(relation_ID) FROM address_info;
			SET @relation_ID = @relation_ID + 1;
		END IF;
        
        INSERT INTO address_info(relation_ID, fk_address_ID, fk_patient_ID)
        VALUES(@relation_ID, @address_ID, @patient_ID);
        
        IF (@do_rollback = 1) THEN
			ROLLBACK;
		ELSE
			COMMIT;
		END IF;
	END $$
    

DROP PROCEDURE IF EXISTS sp_create_new_company;
DELIMITER $$
CREATE PROCEDURE sp_create_new_company(IN companyName VARCHAR(150), IN addLine1 VARCHAR(50), IN addLine2 VARCHAR(50), IN input_city VARCHAR(50), IN input_state VARCHAR(50), IN input_zip VARCHAR(15))
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @do_rollback2 := 1;
		SET autocommit = 0;
		SET @do_rollback2 := 0;

		START TRANSACTION;
		
        IF ((SELECT MAX(company_ID) FROM companies) IS NULL)
			THEN SET @company_ID = 1;
		ELSE
			SELECT @company_ID := MAX(company_ID) FROM companies;
			SET @company_ID = @company_ID + 1;
		END IF;

		INSERT INTO companies(company_ID, company_name)
        VALUES(@company_ID, companyName);
        
        IF ((SELECT MAX(address_ID) FROM addresses) IS NULL)
			THEN SET @address_ID = 1;
		ELSE
			SELECT @address_ID := MAX(address_ID) FROM addresses;
			SET @address_ID = @address_ID + 1;
		END IF;
        
        INSERT INTO addresses(address_ID, address_line_1, address_line_2, city, state, zip)
        VALUES(@address_ID, addLine1, addLine2, input_city, input_state, input_zip);
        
        IF ((SELECT MAX(relation_ID) FROM address_info) IS NULL)
			THEN SET @relation_ID = 1;
		ELSE
			SELECT @relation_ID := MAX(relation_ID) FROM address_info;
			SET @relation_ID = @relation_ID + 1;
		END IF;
        
        INSERT INTO address_info(relation_ID, fk_address_ID, fk_company_ID)
        VALUES(@relation_ID, @address_ID, @company_ID);
        
        IF (@do_rollback2 = 1) THEN
			ROLLBACK;
		ELSE
			COMMIT;
		END IF;
	END $$
    
DROP PROCEDURE IF EXISTS sp_create_new_company;
DELIMITER $$
CREATE PROCEDURE sp_create_new_company(IN companyName VARCHAR(150), IN addLine1 VARCHAR(50), IN addLine2 VARCHAR(50), IN input_city VARCHAR(50), IN input_state VARCHAR(50), IN input_zip VARCHAR(15))
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @do_rollback2 := 1;
		SET autocommit = 0;
		SET @do_rollback2 := 0;

		START TRANSACTION;
		
        IF ((SELECT MAX(company_ID) FROM companies) IS NULL)
			THEN SET @company_ID = 1;
		ELSE
			SELECT @company_ID := MAX(company_ID) FROM companies;
			SET @company_ID = @company_ID + 1;
		END IF;

		INSERT INTO companies(company_ID, company_name)
        VALUES(@company_ID, companyName);
        
        IF ((SELECT MAX(address_ID) FROM addresses) IS NULL)
			THEN SET @address_ID = 1;
		ELSE
			SELECT @address_ID := MAX(address_ID) FROM addresses;
			SET @address_ID = @address_ID + 1;
		END IF;
        
        INSERT INTO addresses(address_ID, address_line_1, address_line_2, city, state, zip)
        VALUES(@address_ID, addLine1, addLine2, input_city, input_state, input_zip);
        
        IF ((SELECT MAX(relation_ID) FROM address_info) IS NULL)
			THEN SET @relation_ID = 1;
		ELSE
			SELECT @relation_ID := MAX(relation_ID) FROM address_info;
			SET @relation_ID = @relation_ID + 1;
		END IF;
        
        INSERT INTO address_info(relation_ID, fk_address_ID, fk_company_ID)
        VALUES(@relation_ID, @address_ID, @company_ID);
        
        IF (@do_rollback2 = 1) THEN
			ROLLBACK;
		ELSE
			COMMIT;
		END IF;
	END $$
    
DROP PROCEDURE IF EXISTS sp_create_new_practice;
DELIMITER $$
CREATE PROCEDURE sp_create_new_practice(IN practiceName VARCHAR(150), IN addLine1 VARCHAR(50), IN addLine2 VARCHAR(50), IN input_city VARCHAR(50), IN input_state VARCHAR(50), IN input_zip VARCHAR(15))
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @do_rollback3 := 1;
		SET autocommit = 0;
		SET @do_rollback3 := 0;

		START TRANSACTION;
		
        IF ((SELECT MAX(practice_ID) FROM practices) IS NULL)
			THEN SET @practice_ID = 1;
		ELSE
			SELECT @practice_ID := MAX(practice_ID) FROM practices;
			SET @practice_ID = @practice_ID + 1;
		END IF;

		INSERT INTO practices(practice_ID, practice_name)
        VALUES(@practice_ID, practiceName);
        
        IF ((SELECT MAX(address_ID) FROM addresses) IS NULL)
			THEN SET @address_ID = 1;
		ELSE
			SELECT @address_ID := MAX(address_ID) FROM addresses;
			SET @address_ID = @address_ID + 1;
		END IF;
        
        INSERT INTO addresses(address_ID, address_line_1, address_line_2, city, state, zip)
        VALUES(@address_ID, addLine1, addLine2, input_city, input_state, input_zip);
        
        IF ((SELECT MAX(relation_ID) FROM address_info) IS NULL)
			THEN SET @relation_ID = 1;
		ELSE
			SELECT @relation_ID := MAX(relation_ID) FROM address_info;
			SET @relation_ID = @relation_ID + 1;
		END IF;
        
        INSERT INTO address_info(relation_ID, fk_address_ID, fk_practice_ID)
        VALUES(@relation_ID, @address_ID, @practice_ID);
        
        IF (@do_rollback3 = 1) THEN
			ROLLBACK;
		ELSE
			COMMIT;
		END IF;
	END $$

DROP PROCEDURE IF EXISTS sp_create_new_invoice;
DELIMITER $$
CREATE PROCEDURE sp_create_new_invoice(IN input_amount INT, IN input_is_paid BOOLEAN, IN input_patient_ID INT, IN input_doctor_ID INT, IN input_practice_ID INT, IN input_visit_date DATE)
	BEGIN
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @do_rollback4 := 1;
		SET autocommit = 0;
		SET @do_rollback4 := 0;

		START TRANSACTION;
		
        IF ((SELECT MAX(invoice_ID) FROM invoices) IS NULL)
			THEN SET @invoice_ID = 1;
		ELSE
			SELECT @invoice_ID := MAX(invoice_ID) FROM invoices;
			SET @invoice_ID = @invoice_ID + 1;
		END IF;

		INSERT INTO invoices(invoice_ID, amount, is_paid)
        VALUES(@invoice_ID, input_amount, input_is_paid);
        
        IF ((SELECT MAX(visit_ID) FROM visit_info) IS NULL)
			THEN SET @visit_ID = 1;
		ELSE
			SELECT @visit_ID := MAX(visit_ID) FROM visit_info;
			SET @visit_ID = @visit_ID + 1;
		END IF;
        
        INSERT INTO visit_info(visit_ID, fk_patient_ID, fk_doctor_ID, fk_practice_ID, fk_invoice_ID, visit_date)
        VALUES(@visit_ID, input_patient_ID, input_doctor_ID, input_practice_ID, @invoice_ID, input_visit_date);
        
        IF (@do_rollback4 = 1) THEN
			ROLLBACK;
		ELSE
			COMMIT;
		END IF;
	END $$
    
    
