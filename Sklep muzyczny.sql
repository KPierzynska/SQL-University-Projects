--Katarzyna Pierzyńska - Projekt 3: sklep muzyczny

/*
Zad 1.
Podaj listę artystów [kol 1 - "wykonawca_name"] wraz z ilością uprawianych przez nich 
gatunków muzycznych [kol 2 - "liczba_gatunków_muzycznych"], 
posortowaną malejąco względem gatunków muzycznych oraz rosnąco względem nazw artystów. 
Dodatkowo w kolumnie [kol 3 - "Ranking"] podaj miejsce w rankingu gęstym w porządku malejącym.
*/
DROP VIEW Artists_genres;

CREATE OR REPLACE VIEW Artists_genres as
SELECT DISTINCT AR.name AS  "wykonawca_name",
        G.name AS "gatunek"
FROM album A
        LEFT JOIN track T
        ON A.albumid = T.albumid
        JOIN artist AR
        ON A.artistid = AR.artistid
        JOIN genre G
        ON T.genreid = G.genreid 
ORDER BY    G.name DESC, AR.name;

SELECT wykonawca_name, COUNT(gatunek) AS "liczba_gatunków_muzycznych", DENSE_RANK() OVER (ORDER BY COUNT(gatunek) DESC) AS Ranking
FROM Artists_genres AR
GROUP BY wykonawca_name
ORDER BY COUNT(gatunek) DESC, wykonawca_name;


/*
 * Zad 2.
 * Jak się ma średnia sprzedaż w danym miesiącu względem średniej sprzedaży z zeszłego miesiąca?
 * Utwórz zestawienie wykorzystując odpowiednią funkcję okna odczytującą poprzedni wiersz:
 */
SELECT 
EXTRACT(YEAR FROM i.invoicedate) AS ROK,
EXTRACT(MONTH FROM i.invoicedate) AS "miesiąc",
ROUND(AVG(i.total), 6) AS "średnia sprzedaż",
CASE
    WHEN EXTRACT(MONTH FROM i.invoicedate) = 1 THEN NULL
    ELSE ROUND(LAG(AVG(i.total)) OVER (ORDER BY EXTRACT(YEAR FROM i.invoicedate), EXTRACT(MONTH FROM i.invoicedate)), 6) 
    END AS "poprzedni miesiąc"
FROM invoice i
GROUP BY EXTRACT(YEAR FROM i.invoicedate), EXTRACT(MONTH FROM i.invoicedate)
ORDER BY EXTRACT(YEAR FROM i.invoicedate), EXTRACT(MONTH FROM i.invoicedate)


/*
 * Zad 3.
 * Podaj dziesięciu klientów, którzy wydali najwięcej w tym sklepie.
 */
SELECT c.firstname AS imię, c.lastname AS nazwisko, sum(total) AS kwota_total
FROM invoice i
JOIN customer c
ON c.customerid = i.customerid 
GROUP BY c.customerid 
ORDER BY sum(total) DESC
LIMIT 10;


/*
 * Zad 4.
 * Podaj rozkład sumy wydanych pieniędzy z podziałem na kraje klientów w procentach z dokładnością do jednego promila.
 * Wynik posortuj od największego udziału.
 */
DROP VIEW countries_totals

CREATE OR REPLACE VIEW countries_totals as
SELECT c.country AS kraj, sum(i.total) AS "%"
FROM customer c
LEFT JOIN invoice i 
ON c.customerid = i.customerid 
GROUP BY c.country 
ORDER BY sum(i.total) DESC

SELECT kraj, ROUND("%"/(SELECT SUM("%") FROM countries_totals)*100, 1) AS "%"
FROM countries_totals


/*
 * Zad 5.
 * Podaj procentowy (z dokładnością do dwóch miejsc po przecinku) udział rodzajów formatów kupionych plików muzycznych - 
 * z całego zbioru danych oraz dodatkowo z podziałem na gatunki muzyczne. 
 * Jakiego gatunku muzycznego nikt nie kupił?
 */

DROP VIEW format_ile2;

--CREATE OR REPLACE VIEW format_ile2 AS
--SELECT mt."name", count(mt."name") AS ilość_utworów_format
--FROM track t
--JOIN mediatype mt ON mt.mediatypeid = t.mediatypeid 
--JOIN album a ON a.albumid = t.albumid 
--GROUP BY mt."name", a.albumid;

CREATE OR REPLACE VIEW format_ile2 AS
SELECT mt."name", count(mt."name") AS ilość_utworów_format
FROM track t
JOIN mediatype mt ON mt.mediatypeid = t.mediatypeid 
GROUP BY mt."name";

DROP VIEW suma_format;
CREATE OR REPLACE VIEW suma_format AS 
SELECT SUM(ilość_utworów_format) AS suma
FROM format_ile2;

SELECT g."name" AS "nazwa_gatunek",
fi2."name" AS "nazwa_format",
max(fi2.ilość_utworów_format) AS ilość_utworów_format, 
round(max(fi2.ilość_utworów_format)/(SELECT suma FROM suma_format)*100, 2) AS "%_format",
count(*) AS ilość_utworów_format_gatunek,
round(100*(count(*)/cast(max(fi2.ilość_utworów_format) AS numeric)), 2) AS "%_format_gatunek"
FROM track t
FULL JOIN genre g ON t.genreid = g.genreid 
JOIN mediatype mt ON mt.mediatypeid = t.mediatypeid 
JOIN format_ile2 fi2 ON mt."name" = fi2."name"
GROUP BY g."name", fi2."name"
ORDER BY max(fi2.ilość_utworów_format) DESC, count(*) DESC


/*
 * Zad 7.
 * Napisz funkcję sprawdzającą, czy dwie listy utworów z tabeli Playlist zawierają te same utwory (ten sam zbiór utworów). 
 * Funkcja przyjmuje dwa parametry wejściowe - identyfikator listy pierwszej i drugiej, a jej wartością zwracaną jest wartość logiczna.
 */
CREATE OR REPLACE FUNCTION ComparePlaylists(plid1 INT, plid2 INT)
RETURNS BOOLEAN AS 
$$
DECLARE 
    count1 DECIMAL;
    count2 DECIMAL;
BEGIN 

    SELECT COUNT(*) INTO count1 FROM playlisttrack WHERE PlaylistId = plid1;

    SELECT COUNT(*) INTO count2 FROM playlisttrack WHERE PlaylistId = plid2;

    IF count1 = 0 AND count2 = 0 THEN
        RETURN TRUE;
    END IF;

    IF EXISTS (
        SELECT *
        FROM playlisttrack ps1
        LEFT JOIN playlisttrack ps2 ON ps1.trackid  = ps2.trackid AND ps2.PlaylistId = plid2
        WHERE ps1.PlaylistId = plid1
        AND ps2.trackid IS NULL
    ) THEN

        RETURN FALSE;
    
    ELSIF EXISTS (
        SELECT *
        FROM playlisttrack ps1
        LEFT JOIN playlisttrack ps2 ON ps1.trackid  = ps2.trackid AND ps2.PlaylistId = plid1
        WHERE ps1.PlaylistId = plid2
        AND ps2.trackid IS NULL
    ) THEN

        RETURN FALSE;
    ELSE

        RETURN TRUE;
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT p1.PlaylistId AS PlaylistId1, p2.PlaylistId AS PlaylistId2
FROM Playlist p1
CROSS JOIN Playlist p2
WHERE p1.PlaylistId < p2.PlaylistId
AND ComparePlaylists(p1.PlaylistId, p2.PlaylistId) = TRUE;


/*
 * Zad 8
 * Jakiego artystę kupują najczęściej te osoby, które kupiły również płyty Miles Davis'a (pomijając Miles Davis'a oraz Various Artists)
 */
SELECT ar."name", count(t.trackid) AS "ile_utworow"
FROM album al
JOIN artist ar ON al.artistid = ar.artistid 
JOIN track t ON al.albumid = t.albumid 
JOIN invoiceline il ON il.trackid = t.trackid 
JOIN invoice i ON i.invoiceid = il.invoiceid 
WHERE i.customerid IN (SELECT i.customerid
    FROM Invoice i 
    JOIN InvoiceLine il ON i.invoiceid = il.invoiceid
    JOIN Track t ON il.trackid = t.trackid
    JOIN Album al ON t.albumid = al.albumid
    JOIN Artist a ON al.artistid = a.artistid
    WHERE al.albumid IN (
        SELECT albumid
        FROM Album
        WHERE artistid = (
            SELECT artistid
            FROM Artist
            WHERE name = 'Miles Davis'
        )
    )
    GROUP BY i.customerid)
AND ar."name" != 'Miles Davis' AND ar."name" != 'Various Artists'
GROUP BY ar."name" 
ORDER BY count(al.albumid) DESC
LIMIT 1;


/*
 * Zad 11.
 * Dla każdego kraju podaj trzech najbardziej popularnych (najczęściej kupowanych) artystów z informacją o miejscu pierwszym, 
 * drugim bądź trzecim w osobnej kolumnie.
 * (w razie miejsc ex aequo weź pod uwagę kolejność alfabetyczną nazw zespołów).
 */
WITH ArtysciTop3 AS (
SELECT   
        c.country AS kraj,
        a."name" AS arysta,
        ROW_NUMBER() OVER (PARTITION BY  c.country ORDER BY COUNT(*) DESC, a."name") AS Rank
    FROM
        invoice i
    JOIN
        customer c ON i.customerid = c.customerid
    JOIN
        invoiceline il ON i.invoiceid = il.invoiceid
    JOIN
        track t ON il.trackid = t.trackId
    JOIN
        album al ON t.albumId = al.albumId
    JOIN
        artist a ON al.artistId = a.artistId
    GROUP BY 
        c.country,
        a."name" 
)
SELECT
    at1.kraj AS kraj,
    at1.arysta AS miejsce_pierwsze,
    at2.arysta AS miejsce_drugie,
    at3.arysta AS miejsce_trzecie
FROM
    ArtysciTop3 at1
JOIN
    ArtysciTop3 at2 ON at1.kraj = at2.kraj AND at2.Rank = 2
JOIN
    ArtysciTop3 at3 ON at1.kraj = at3.kraj AND at3.Rank = 3
WHERE
    at1.Rank = 1
ORDER BY
    at1.kraj; 


