CREATE TABLE Libraries (
    LibraryID SERIAL NOT NULL PRIMARY KEY,
    LibraryName VARCHAR(50) NOT NULL,
    WorkingHoursID INT REFERENCES WorkingHours(WorkingHoursID)
);

CREATE TABLE WorkingHours (
    WorkingHoursID SERIAL NOT NULL PRIMARY KEY,
    DayOfWeek INT NOT NULL,
    OpenTime TIME NOT NULL,
    CloseTime TIME NOT NULL
);

CREATE TABLE Librarians (
    LibrarianID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    LibraryID INT REFERENCES Library(LibraryID)
);

CREATE TABLE Authors (
    AuthorID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    IsAlive BOOLEAN NOT NULL,
    Gender VARCHAR(50) NOT NULL,
    CountryID INT REFERENCES Country(CountryID) 
);

ADD CONSTRAINT CHK_Gender CHECK
(Gender IN ('MUŠKI', 'ŽENSKI', 'NEPOZNATO', 'OSTALO'));

CREATE TABLE Countries (
    CountryID SERIAL NOT NULL PRIMARY KEY,
    CountryName VARCHAR(50) NOT NULL,
    Population INT NOT NULL,
    AverageSalary INT NOT NULL
);

CREATE TABLE Books (
    BookID SERIAL NOT NULL PRIMARY KEY,
    Title VARCHAR(50) NOT NULL,
    Genre VARCHAR(50) NOT NULL,
    Author VARCHAR(50) NOT NULL,
    ISBN VARCHAR(50) NOT NULL,
    LibraryID INT NOT NULL,
    FOREIGN KEY (LibraryID) REFERENCES Library(LibraryID)
);

ALTER TABLE Books
    ADD CONSTRAINT CHK_Genre CHECK 
    (Genre IN 
    ('lektira', 'umjetnička', 'znanstvena', 'biografija', 'stručna'));

CREATE TABLE BookAuthors (
    AuthorType VARCHAR(50) NOT NULL,
    BookID INT REFERENCES Book(BookID),
    AuthorID INT REFERENCES Author(AuthorID)
    PRIMARY KEY (BookID, AuthorID)
);

ALTER TABLE ADD CONSTRAINT CHK_AuthorType CHECK 
    (AuthorType IN 
    ('glavni', 'sporedni'));

CREATE TABLE Users (
    UserID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL
)

CREATE TABLE BookLoans (
    BookLoanID SERIAL NOT NULL PRIMARY KEY,
    LoanDate DATE NOT NULL,
    ReturnDate DATE NOT NULL,
    BookID INT REFERENCES Book(BookID),
    UserID INT REFERENCES User(UserID),
    IsExtendedLoan BOOLEAN NOT NULL,
    IsReturned BOOLEAN NOT NULL,
    CostOfFine INT NOT NULL
)