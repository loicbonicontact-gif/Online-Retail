SELECT COUNT(*) FROM online_retail;

SELECT * FROM online_retail;

-- Chiffre d'affaires :

SELECT SUM(quantity * Unitprice) AS CA FROM online_retail;

-- Chiffre d'affaires par pays : 

SELECT country, SUM(quantity * Unitprice) AS CA_pays FROM online_retail 
GROUP BY Country 
ORDER BY CA_pays DESC;

-- Annulation :
SELECT SUM(quantity * Unitprice) AS CA_annulation 
FROM online_retail
WHERE invoiceNo LIKE 'C%';

-- TOP PRODUIT :

SELECT stockcode, description, SUM(quantity) AS quantite_total
FROM online_retail
WHERE quantity > 0
GROUP BY StockCode, Description
ORDER BY quantite_total DESC
LIMIT 10;

-- Evolution mensuelle du CA : 

SELECT STRFTIME('%Y-%m', invoiceDate) AS mois,
SUM(quantity*Unitprice) AS CA_mensuel
FROM online_retail 
WHERE quantity > 0
GROUP BY mois 
ORDER BY mois;

-- TOP clients
SELECT customerID, SUM(quantity * Unitprice) AS CA_client
FROM online_retail 
GROUP BY CustomerID 
ORDER BY CA_client DESC
LIMIT 10;

-- recherche de doublons (= NONE)

SELECT InvoiceNo,
     COUNT(InvoiceNo) as doublons
FROM online_retail
GROUP BY InvoiceNo
HAVING(doublons > 1)

-- Panier moyen

SELECT AVG(total_facture) AS panier_moyen
FROM ( SELECT invoiceNo, SUM(quantity * unitprice) AS total_facture
FROM online_retail
GROUP BY invoiceNo);

-- Taux d'annulation

SELECT
    COUNT(DISTINCT CASE WHEN InvoiceNo LIKE 'C%' THEN InvoiceNo END) AS nb_annulations,
    COUNT(DISTINCT InvoiceNo) AS nb_factures_total
FROM online_retail;


-- Les dates :

SELECT invoicedate, DATETIME(invoicedate) AS date
FROM online_retail;

-- separation de dates et heures :

SELECT invoiceno,
DATE(Invoicedate) AS date,
TIME(Invoicedate) AS Hour
FROM online_retail;

-- Stockcode : 

SELECT StockCode, COUNT(*) AS frequence
FROM online_retail 
WHERE StockCode NOT GLOB '[0-9]*'
GROUP BY StockCode 
ORDER BY frequence DESC;

-- Nettoyage Stockcode :

SELECT DISTINCT stockcode FROM online_retail
WHERE stockcode IN ('POST', 'DOT', 'M', 'C2', 'D','S','BANK CHARGES','AMAZONFEE','CRUK');




-- Valeur NULL :
-- Client : 
SELECT COUNT(*) AS customerid_clean
FROM online_retail
WHERE customerid IS NULL;

-- description :

SELECT COUNT(*) AS description_clean
FROM online_retail
WHERE description IS NULL;


-- Creation table propre :

DROP TABLE IF EXISTS online_retail_clean;
CREATE TABLE online_retail_clean AS
SELECT 
InvoiceNo,
Stockcode,
Description,
Quantity,
DATE(InvoiceDate) AS InvoiceDate,
TIME(InvoiceDate) AS invoiceHour,
Unitprice,
CustomerID,
Country,
InvoiceNo LIKE 'C%' AS CancelInvoice
FROM online_retail
WHERE stockcode NOT IN ('POST', 'DOT', 'M', 'C2', 'D','S','BANK CHARGES','AMAZONFEE','CRUK')
AND UnitPrice > 0
AND Description IS NOT NULL;




-- Remplacer les cases vides :

Update online_retail_clean
SET CustomerID = NULL
WHERE CustomerID = '';

SELECT * FROM online_retail_clean;

-- Taux de CustomerID NULL sur le CA :
SELECT
    SUM(CASE WHEN CustomerID IS NULL THEN Quantity * UnitPrice ELSE 0 END) AS ca_sans_client,
    SUM(Quantity * UnitPrice) AS ca_total,
    ROUND(
        100.0 * SUM(CASE WHEN CustomerID IS NULL THEN Quantity * UnitPrice ELSE 0 END)
        / SUM(Quantity * UnitPrice), 2
    ) AS pourcentage_ca_sans_client
FROM online_retail_clean;

 -- Client :

DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers AS
SELECT DISTINCT CustomerID, Country
FROM online_retail_clean
WHERE CustomerID IS NOT NULL;

SELECT *FROM Customers;

-- Commande :

DROP TABLE IF EXISTS commande;
CREATE TABLE  commande AS 
SELECT DISTINCT CustomerID, invoiceno, invoicedate, Invoicehour, invoiceNo LIKE 'C%' AS annuler 
FROM online_retail_clean;

SELECT * FROM commande;

-- Ligne commande :

DROP TABLE IF EXISTS LigneCommande;
CREATE TABLE LigneCommande AS
SELECT InvoiceNo, StockCode, Quantity, UnitPrice
FROM online_retail_clean;

SELECT * FROM LigneCommande;

-- Non-Produit (charges):

DROP TABLE IF EXISTS no_Products;
CREATE TABLE no_Products AS 
SELECT DISTINCT stockcode, description 
FROM online_retail_clean
WHERE StockCode NOT GLOB '[0-9]*';

SELECT * FROM no_Products;

-- Produit :

DROP TABLE IF EXISTS Product;
CREATE TABLE Product AS
SELECT DISTINCT StockCode, Description
FROM online_retail_clean
WHERE StockCode NOT IN (SELECT StockCode FROM no_Products);


SELECT * FROM Product;



