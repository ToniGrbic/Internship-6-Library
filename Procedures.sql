CREATE OR REPLACE PROCEDURE BorrowBook(book_id INT, user_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    loan_date DATE := CURRENT_DATE;
    return_date DATE := loan_date + INTERVAL '20 days';
BEGIN
    CASE
        WHEN NOT EXISTS (SELECT * FROM Books WHERE BookID = book_id) THEN
            RAISE EXCEPTION 'Specified book does not exist';
        WHEN NOT EXISTS (SELECT * FROM Users WHERE UserID = user_id) THEN
            RAISE EXCEPTION 'Specified user does not exist';
        WHEN EXISTS (SELECT * FROM BookLoans WHERE BookID = book_id AND IsReturned = false) THEN
            RAISE EXCEPTION 'Book is already borrowed';
        WHEN (SELECT COUNT(*) FROM BookLoans WHERE UserID = user_id AND IsReturned = false) >= 3 THEN
            RAISE EXCEPTION 'User has already borrowed 3 books';
        ELSE
            INSERT INTO BookLoans (LoanDate, ReturnDate, BookID, UserID, IsExtendedLoan, IsReturned, CostOfFine)
            VALUES (loan_date, return_date, book_id, user_id, false, false, 0);
    END CASE;
END;
$$;

CREATE OR REPLACE PROCEDURE CheckLoanExpiryAndUpdateFine(book_loan_id INT)
AS $$
DECLARE
    book_id INT;
    return_date DATE;
    current_date DATE := CURRENT_DATE;
    genre VARCHAR(50);
    fine INT := 0;
    days INT;
BEGIN
    SELECT BookID, ReturnDate, Genre INTO book_id, return_date, genre FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF return_date >= current_date THEN
        RETURN;
    END IF;

    days := current_date - return_date;

    FOR i IN 1..days LOOP
        IF EXTRACT(MONTH FROM return_date + i) BETWEEN 6 AND 9 THEN --ljeto
            IF EXTRACT(DOW FROM return_date + i) BETWEEN 1 AND 5 THEN 
                fine := fine + 30; --radni dani
            ELSE
                fine := fine + 20; --vikend
            END IF;
        ELSE -- ostatak godine
            IF genre = 'lektira' THEN
                fine := fine + 50;
            ELSE
                IF EXTRACT(DOW FROM return_date + i) BETWEEN 1 AND 5 THEN
                    fine := fine + 40; -- radni dani
                ELSE
                    fine := fine + 20; -- vikend
                END IF;
            END IF;
        END IF;
    END LOOP;

    UPDATE BookLoans SET CostOfFine = fine WHERE BookLoanID = book_loan_id;
END;
$$;
