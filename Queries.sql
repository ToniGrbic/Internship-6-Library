-- ime, prezime, spol (ispisati ‘MUŠKI’, ‘ŽENSKI’, ‘NEPOZNATO’, ‘OSTALO’;), ime države i  prosječna plaća u toj državi svakom autoru
SELECT 
	FirstName, 
	LastName,
	CASE WHEN Gender = '' THEN 'NEPOZNATO'
	ELSE Gender END,
	(SELECT DISTINCT CountryName FROM Countries c WHERE c.CountryID = a.CountryID)
	AS Country,
	(SELECT DISTINCT AverageSalary FROM Countries c WHERE c.CountryID = a.CountryID)
	AS AverageSalary
FROM Authors a

-- naziv i datum objave svake znanstvene knjige zajedno s imenima glavnih autora koji su na njoj radili, 
--pri čemu imena autora moraju biti u jednoj ćeliji i u obliku Prezime, I.; 
--npr. Puljak, I.; Godinović, N.; Bilušić, A.
SELECT 
    Title,
    PublishDate,
    (SELECT STRING_AGG(CONCAT(LastName, ', ', LEFT(FirstName, 1), '.'))
FROM Authors a
INNER JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
WHERE ba.BookID = b.BookID AND ba.AuthorType = 'glavni')
AS Authors

SELECT 
    Title,
    PublishDate,
    (SELECT DISTINCT CONCAT(a.LastName, ', ', LEFT(a.FirstName, 1))
	 FROM Authors a
	 JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
	 WHERE ba.AuthorType = 'glavni')
	 AS AuthorName
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
WHERE b.BookID = ba.BookID

