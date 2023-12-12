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

