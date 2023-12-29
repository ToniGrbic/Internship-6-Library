--PROCEDURA ZA POSUDBU KNJIGE
CREATE OR REPLACE PROCEDURE BorrowBook(copy_id INT, user_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    Loan_date DATE := CURRENT_DATE;
    ReturnDate DATE := loan_date + INTERVAL '20 days';
    last_book_loan_id INT;
    book_loan_id INT;
BEGIN
    SELECT MAX(BookLoanID) INTO last_book_loan_id FROM BookLoans;
    book_loan_id := last_book_loan_id + 1;
    CASE
        WHEN NOT EXISTS (SELECT * FROM BookCopies WHERE CopyID = copy_id) THEN
            RAISE EXCEPTION 'Specified book does not exist';
        WHEN NOT EXISTS (SELECT * FROM Users WHERE UserID = user_id) THEN
            RAISE EXCEPTION 'Specified user does not exist';
        WHEN EXISTS (SELECT * FROM BookLoans WHERE CopyID = copy_id AND IsReturned = false) THEN
            RAISE EXCEPTION 'Book is already borrowed';
        WHEN (SELECT COUNT(*) FROM BookLoans WHERE UserID = user_id AND IsReturned = false) >= 3 THEN
            RAISE EXCEPTION 'User has already borrowed 3 books';
        ELSE
            INSERT INTO BookLoans (BookLoanID, loan_date, return_date, CopyID, UserID, IsExtendedLoan, IsReturned, CostOfFine)
            VALUES (book_loan_id, Loan_date, ReturnDate, copy_id, user_id, false, false, 0);
    END CASE;
END;
$$;

--PROCEDURA KOJA AŽURIRA CIJENU KAŠNJENJA ZA ODREĐENU POSUDBU
CREATE OR REPLACE PROCEDURE CheckLoanExpiryAndUpdateFine(book_loan_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    copy_id INT;
    ReturnDate DATE;
    CurrentDate DATE := CURRENT_DATE;
    genre VARCHAR(50);
    fine NUMERIC := 0;
    days INT;
BEGIN
    SELECT CopyID, return_date, Genre INTO copy_id, ReturnDate, genre FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF ReturnDate >= CurrentDate THEN
        RETURN;
    END IF;

    days := CurrentDate - ReturnDate;

    FOR i IN 1..days LOOP
        IF EXTRACT(MONTH FROM ReturnDate + i) BETWEEN 6 AND 9 THEN --ljeto
            IF EXTRACT(DOW FROM ReturnDate + i) BETWEEN 1 AND 5 THEN 
                fine := fine + 0.3; --radni dani
            ELSE
                fine := fine + 0.2; --vikend
            END IF;
        ELSE -- ostatak godine
            IF genre = 'lektira' THEN
                fine := fine + 0.5;
            ELSE
                IF EXTRACT(DOW FROM ReturnDate + i) BETWEEN 1 AND 5 THEN
                    fine := fine + 0.4; -- radni dani
                ELSE
                    fine := fine + 0.2; -- vikend
                END IF;
            END IF;
        END IF;
    END LOOP;

    UPDATE BookLoans SET CostOfFine = fine WHERE BookLoanID = book_loan_id;
END;
$$;

-- PROCEDURA KOJA POZIVA PRETHODNU PROCEDURU ZA SVAKU POSUDBU
CREATE OR REPLACE FUNCTION UpdateEachBookLoan() RETURNS VOID 
LANGUAGE plpgsql
AS $$
DECLARE 
   t_row BookLoans%rowtype;
BEGIN
 FOR t_row in (SELECT * FROM BookLoans) LOOP
 	CALL CheckLoanExpiryAndUpdateFine(t_row.BookLoanID);
 END LOOP;
END;
$$; -- SELECT UpdateEachBookLoan(); -> poziv procedure

--PROCEDURA ZA PRODUŽENJE POSUDBE
CREATE OR REPLACE PROCEDURE ExtendLoan(book_loan_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    ReturnDate DATE;
    current_date DATE := CURRENT_DATE;
BEGIN
    SELECT return_date INTO ReturnDate FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF ReturnDate < current_date THEN
        RAISE EXCEPTION 'Loan has expired';
    END IF;

    UPDATE BookLoans SET return_date = ReturnDate + INTERVAL '40 days', IsExtendedLoan = true WHERE BookLoanID = book_loan_id;
END;
$$;