CREATE TABLE Libraries (
    LibraryID SERIAL NOT NULL PRIMARY KEY,
    LibraryName VARCHAR(50) NOT NULL
);

CREATE TABLE WorkingHours (
    WorkingHoursID SERIAL NOT NULL PRIMARY KEY,
    DayOfWeek INT NOT NULL,
    OpenTime TIME NOT NULL,
    CloseTime TIME NOT NULL,
    LibraryID INT REFERENCES Libraries(LibraryID)
);

ALTER TABLE WorkingHours
    ADD CONSTRAINT CHK_DayOfWeek 
    CHECK (DayOfWeek BETWEEN 1 AND 7);

CREATE TABLE Librarians (
    LibrarianID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    LibraryID INT REFERENCES Libraries(LibraryID)
);

CREATE TABLE Countries (
    CountryID SERIAL NOT NULL PRIMARY KEY,
    CountryName VARCHAR(50) NOT NULL,
    Population INT NOT NULL,
    AverageSalary INT NOT NULL
);

CREATE TABLE Authors (
    AuthorID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    IsAlive BOOLEAN NOT NULL,
    Gender VARCHAR(50),
    CountryID INT REFERENCES Countries(CountryID) 
);

ALTER TABLE Authors
    ADD CONSTRAINT CHK_Gender CHECK
    (Gender IN ('MUŠKO', 'ŽENSKO', 'OSTALO'));

CREATE TABLE Books (
    BookID SERIAL NOT NULL PRIMARY KEY,
    Title VARCHAR(120) NOT NULL,
    Genre VARCHAR(50) NOT NULL,
    ISBN VARCHAR(50) NOT NULL,
    PublishDate DATE NOT NULL
);

ALTER TABLE Books
    ADD CONSTRAINT CHK_Genre CHECK 
    (Genre IN 
    ('lektira', 'umjetnička', 'znanstvena', 'biografija', 'stručna'));

CREATE TABLE BookAuthors (
    AuthorType VARCHAR(50) NOT NULL,
    BookID INT REFERENCES Books(BookID),
    AuthorID INT REFERENCES Authors(AuthorID),
    PRIMARY KEY (BookID, AuthorID)
);

CREATE TABLE BookCopies (
    CopyID SERIAL NOT NULL PRIMARY KEY,
    BookID INT REFERENCES Books(BookID),
    LibraryID INT REFERENCES Libraries(LibraryID)
);

--index da bi ubrzalo querije za BookID na BookCopies, ima ih puno u odnosu na ostale tablice
CREATE INDEX BookIDs on BookCopies(BookID)

ALTER TABLE BookAuthors
    ADD CONSTRAINT CHK_AuthorType CHECK 
    (AuthorType IN 
    ('glavni', 'sporedni'));

CREATE TABLE Users (
    UserID SERIAL NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL
);

CREATE TABLE BookLoans (
    BookLoanID SERIAL NOT NULL PRIMARY KEY,
    LoanDate DATE NOT NULL,
    ReturnDate DATE NOT NULL,
    CopyID INT REFERENCES BookCopies(CopyID),
    UserID INT REFERENCES Users(UserID),
    IsExtendedLoan BOOLEAN NOT NULL,
    IsReturned BOOLEAN NOT NULL,
    CostOfFine FLOAT
);

--index za ubrzavanje querija za CopyID na BookLoans
CREATE INDEX CopyIDs on BookLoans(CopyID)






