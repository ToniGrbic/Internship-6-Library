-- ime, prezime, spol (ispisati ‘MUŠKI’, ‘ŽENSKI’, ‘NEPOZNATO’, ‘OSTALO’;), ime države i  prosječna plaća u toj državi svakom autoru
SELECT 
	a.FirstName, 
	a.LastName,
	COALESCE(NULLIF(Gender, ''), 'NEPOZNATO') AS Gender,
	c.CountryName,
	c.AverageSalary
FROM Authors a
JOIN Countries c ON c.CountryID = a.CountryID 


-- naziv i datum objave svake znanstvene knjige zajedno s imenima glavnih autora koji su na njoj radili, 
--pri čemu imena autora moraju biti u jednoj ćeliji i u obliku Prezime, I.; 
--npr. Puljak, I.; Godinović, N.; Bilušić, A.
SELECT 
    b.Title,
    b.PublishDate,
    CONCAT(CONCAT(a.LastName, ' ', LEFT(a.FirstName, 1)),'','.') 
	as Authors
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
WHERE ba.AuthorType = 'glavni'


-- sve kombinacije (naslova) knjiga i posudbi istih u prosincu 2023.; 
--u slučaju da neka nije ni jednom posuđena u tom periodu, prikaži je samo jednom 
--(a na mjestu posudbe neka piše null)
SELECT 
    b.Title,
    (CASE 
        WHEN DATE_PART('year', bl.loan_date) = 2023 AND DATE_PART('month', bl.loan_date) = 12
        THEN bl.loan_date
        ELSE NULL 
     END) as loan_date
FROM Books b
JOIN BookCopies bc ON b.BookID = bc.BookID
JOIN BookLoans bl ON bc.CopyID = bl.CopyID
ORDER BY bl.loan_date DESC;


--top 3 knjižnice s najviše primjeraka knjiga
SELECT l.LibraryID, COUNT(*) as NumberOfBooks FROM BookCopies bc
JOIN Libraries l ON bc.LibraryID = l.LibraryID
GROUP BY bc.LibraryID, l.LibraryID
limit 3


--po svakoj knjizi broj ljudi koji su je pročitali (korisnika koji posudili bar jednom)
SELECT 
    b.Title, 
    COUNT(DISTINCT bl.UserID) as NumberOfReaders 
FROM Books b
JOIN BookCopies bc ON b.BookID = bc.BookID
JOIN BookLoans bl ON bc.CopyID = bl.CopyID
GROUP BY b.BookID, b.Title
ORDER BY NumberOfReaders DESC;

--imena svih korisnika koji imaju trenutno posuđenu knjigu
SELECT DISTINCT u.FirstName, u.LastName
FROM Users u
JOIN BookLoans bl ON u.UserID = bl.UserID
WHERE bl.isReturned = false

--sve autore kojima je bar jedna od knjiga izašla između 2019. i 2022.
SELECT DISTINCT a.FirstName, a.LastName
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
WHERE b.PublishDate BETWEEN '2019-01-01' AND '2022-12-31'

--ime države i broj umjetničkih knjiga po svakoj (ako su dva autora iz iste države, 
--računa se kao jedna knjiga), gdje su države sortirane po broju živih autora od najveće ka najmanjoj
SELECT DISTINCT c.CountryName, COUNT(*) as NumberOfArtBooks
FROM Authors a
JOIN Countries c ON a.CountryID = c.CountryID
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
WHERE b.Genre = 'umjetnička'
GROUP BY c.CountryName
ORDER BY (SELECT COUNT(*) FROM Authors a WHERE a.IsAlive = true) DESC

--po svakoj kombinaciji autora i žanra (ukoliko postoji) broj posudbi knjiga tog autora u tom žanru
SELECT 
    a.FirstName, 
    a.LastName, 
    b.Genre, 
    COUNT(*) as NumberOfLoans
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
JOIN BookCopies bc ON b.BookID = bc.BookID
JOIN BookLoans bl ON bc.CopyID = bl.CopyID
GROUP BY a.FirstName, a.LastName, b.Genre
ORDER BY NumberOfLoans DESC;

--po svakom članu koliko trenutno duguje zbog kašnjenja; u slučaju da ne duguje ispiši “ČISTO”
SELECT DISTINCT u.FirstName, u.LastName,
COALESCE(CAST(NULLIF(CostOfFine, 0) AS VARCHAR), 'ČISTO') as TotalFine,
ROUND(CAST(bl.CostOfFine AS NUMERIC),2) as FineAprox
FROM Users u
JOIN BookLoans bl ON u.UserID = bl.UserID
WHERE bl.IsReturned = false
GROUP BY u.FirstName, u.LastName, TotalFine, FineAprox
ORDER BY FineAprox

--autora i ime prve objavljene knjige istog
SELECT a.FirstName, a.LastName, b.Title, MIN(b.PublishDate) as FirstPublishedBook
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
GROUP BY a.FirstName, a.LastName, b.Title
ORDER BY FirstPublishedBook

--državu i ime druge objavljene knjige iste
SELECT c.CountryName, b.Title, MIN(b.PublishDate) as SecondPublishedBook
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
JOIN Countries c ON a.CountryID = c.CountryID
WHERE b.PublishDate > (SELECT MIN(b.PublishDate) FROM Books b)
GROUP BY c.CountryName, b.Title

--knjige i broj aktivnih posudbi, gdje se one s manje od 10 aktivnih ne prikazuju
SELECT 
    b.Title, 
    COUNT(*) as NumberOfActiveLoans
FROM Books b
JOIN BookCopies bc ON b.BookID = bc.BookID
JOIN BookLoans bl ON bc.CopyID = bl.CopyID
WHERE bl.IsReturned = false
GROUP BY b.Title
HAVING COUNT(*) > 10 
ORDER BY NumberOfActiveLoans DESC;

--prosječan broj posudbi po primjerku knjige po svakoj državi
-- pomogao chatGPT, vjerovatno moze bolje 
SELECT 
    c.CountryName, 
    COUNT(bl.CopyID) / COUNT(DISTINCT bc.CopyID) as AverageLoansPerCopy
FROM Countries c
JOIN Authors a ON c.CountryID = a.CountryID
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
JOIN BookCopies bc ON b.BookID = bc.BookID
JOIN BookLoans bl ON bc.CopyID = bl.CopyID
GROUP BY c.CountryName
ORDER BY AverageLoansPerCopy DESC;

--select query za broj autora koji su objavili više od 5 knjiga po struci, desetljeću rođenja i spolu, u slučaju da je broj autora manji od 10, 
--ne prikazuj kategoriju; poredaj prikaz po desetljeću rođenja
SELECT DISTINCT b.Genre, COUNT(*) as NumberOfAuthors, EXTRACT(DECADE FROM a.DateOfBirth) as DecadeOfBirth
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
GROUP BY b.Genre, DecadeOfBirth
HAVING COUNT(*) > 5

--10 najbogatijih autora, ako po svakoj knjizi dobije: sqrt(brojPrimjeraka)/brojAutoraPoKnjizi €
--pomogao chatgpt, nakon dodavanja 10k redova u BookCopies TotalMoney se povecava ali ne drasticno jer sam insertao 1000 Autora
SELECT 
    a.AuthorID, 
    a.FirstName, 
    a.LastName, 
    (SUM(SQRT(bc.NumCopies)/ba.NumAuthors)) as TotalMoney
FROM Authors a
JOIN (
    SELECT AuthorID, BookID, COUNT(*) as NumAuthors
    FROM BookAuthors
    GROUP BY AuthorID, BookID
) ba ON a.AuthorID = ba.AuthorID
JOIN (
    SELECT BookID, COUNT(*) as NumCopies
    FROM BookCopies
    GROUP BY BookID
) bc ON ba.BookID = bc.BookID
GROUP BY a.AuthorID, a.FirstName, a.LastName
ORDER BY TotalMoney DESC

