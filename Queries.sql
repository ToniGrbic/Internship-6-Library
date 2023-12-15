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
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
WHERE ba.AuthorType = 'glavni'


-- sve kombinacije (naslova) knjiga i posudbi istih u prosincu 2023.; 
--u slučaju da neka nije ni jednom posuđena u tom periodu, prikaži je samo jednom 
--(a na mjestu posudbe neka piše null)
SELECT b.Title,
(CASE 
	WHEN DATE_PART('year',bl.LoanDate) = 2023 AND DATE_PART('month',bl.LoanDate) = 12
	THEN bl.LoanDate
	ELSE NULL 
 END) as LoanDate
FROM BookLoans bl
JOIN Books b on bl.BookID = b.BookID
ORDER BY bl.LoanDate DESC


--top 3 knjižnice s najviše primjeraka knjiga
SELECT COUNT(*) FROM Books b
GROUP BY b.LibraryID
limit 3

--po svakoj knjizi broj ljudi koji su je pročitali (korisnika koji posudili bar jednom)
SELECT b.Title, COUNT(*) as NumberOfReaders 
FROM BookLoans bl
JOIN Books b ON bl.BookID = b.BookID
GROUP BY b.BookID
ORDER BY NumberOfReaders DESC	

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
SELECT c.CountryName, COUNT(*) as NumberOfArtBooks
FROM Authors a
JOIN Countries c ON a.CountryID = c.CountryID
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
WHERE b.Genre = 'umjetnička'
GROUP BY c.CountryName
ORDER BY (SELECT COUNT(*) FROM Authors a WHERE a.IsAlive = true) DESC

--po svakoj kombinaciji autora i žanra (ukoliko postoji) broj posudbi knjiga tog autora u tom žanru
SELECT a.FirstName, a.LastName, b.Genre, COUNT(*) as NumberOfLoans
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
JOIN BookLoans bl ON b.BookID = bl.BookID
GROUP BY a.FirstName, a.LastName, b.Genre
ORDER BY NumberOfLoans DESC

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

--knjige i broj aktivnih posudbi, gdje se one s manje od 10 aktivnih ne prikazuju
SELECT b.Title, COUNT(*) as NumberOfActiveLoans
FROM Books b
JOIN BookLoans bl ON b.BookID = bl.BookID
WHERE bl.IsReturned = false
GROUP BY b.Title
HAVING COUNT(*) > 10
ORDER BY NumberOfActiveLoans DESC

--prosječan broj posudbi po primjerku knjige po svakoj državi
SELECT DISTINCT b.Title, c.CountryName, COUNT(*) as NumberOfLoans
FROM BookLoans bl
JOIN Books b ON bl.BookID = b.BookID
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
JOIN Countries c ON a.CountryID = c.CountryID
GROUP BY c.CountryName
ORDER BY NumberOfLoans DESC


--broj autora koji su objavili više od 5 knjiga po struci, desetljeću rođenja i spolu; 
--u slučaju da je broj autora manji od 10, ne prikazuj kategoriju; poredaj prikaz po desetljeću rođenja



--10 najbogatijih autora, ako po svakoj knjizi dobije: sqrt(brojPrimjeraka)/brojAutoraPoKnjizi €

SELECT 
    a.AuthorID, 
    a.FirstName, 
    a.LastName, 
    SUM(sqrt(bc.Number_Of_Copies) / COUNT(ba.AuthorID)) AS Earnings
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
JOIN (SELECT BookID, COUNT(*) as Number_Of_Copies FROM BookCopies 
	  GROUP BY BookID) bc ON b.BookID = bc.BookID
GROUP BY a.AuthorID, a.FirstName, a.LastName
ORDER BY 
    Earnings DESC
LIMIT 10;
