--zadanie 1
SELECT  CAST (avg(arr_delay_new) AS varchar(16)) AS "avg_delay"
FROM    "Flight_delays";

--zadanie 2
SELECT  max(arr_delay)  AS "max_delay"
FROM    "Flight_delays";

--zadanie 3
SELECT  carrier,
        origin_city_name,
        dest_city_name,
        fl_date,
        arr_delay_new
FROM    "Flight_delays"
WHERE   arr_delay_new IN    (SELECT max(arr_delay_new)
                            FROM    "Flight_delays");
                            
--zadanie 4
SELECT  W.weekday_name,
        CAST (avg(F.arr_delay_new) AS varchar(16)) AS "avg_delay"
FROM    "Weekdays" W 
        INNER JOIN  "Flight_delays" F
                ON  W.weekday_id = F.day_of_week
GROUP BY W.weekday_name
ORDER BY avg(F.arr_delay_new) DESC;

--zadanie 5
SELECT  A.airline_name,
        avg(D.arr_delay_new)   AS "avg_delay"
FROM    "Airlines" A 
        INNER JOIN  "Flight_delays" F 
                ON  A.airline_id = F.airline_id 
                AND origin = 'SFO'
        INNER JOIN "Flight_delays" D 
                    ON  A.airline_id = D.airline_id 
GROUP BY A.airline_name 
ORDER BY avg(D.arr_delay_new) DESC;

--zadanie 6 
SELECT  CAST(count(DISTINCT carrier) AS float) / cast((SELECT count(DISTINCT carrier) 
        FROM "Flight_delays") AS float)  AS "late_proportion"
FROM    "Flight_delays" 
WHERE   carrier IN (SELECT  carrier
                    FROM    "Flight_delays" 
                    GROUP BY carrier 
                    HAVING avg(dep_delay_new) >= 10);

--zadanie 7 
SELECT (avg(dep_delay_new * arr_delay_new) - avg(dep_delay_new) * avg(arr_delay_new))
/ (STDDEV(dep_delay_new) * STDDEV(arr_delay_new)) AS "Pearsons r"
FROM "Flight_delays";

--zadanie 8 
SELECT  R.airline_name,
        avg(B.arr_delay_new) - avg(A.arr_delay_new) AS "delay_increase"
FROM    "Flight_delays" A
        INNER JOIN  "Airlines" R 
                ON  A.airline_id = R.airline_id
                AND A.day_of_month <= 23
        INNER JOIN  "Flight_delays" B
                on  A.airline_id = B.airline_id
                AND B.day_of_month > 23
GROUP BY R.airline_name      
ORDER BY "delay increase" DESC
LIMIT 1;
             
--zadanie 9
SELECT DISTINCT airline_name
FROM    "Airlines" R 
        INNER JOIN  "Flight_delays" F 
                ON  R.airline_id = F.airline_id
                AND F.origin = 'SFO'
                AND F.dest = 'PDX'
        INNER JOIN  "Flight_delays" F2
                ON  F.airline_id = F2.airline_id 
                AND F2.origin = 'SFO'
                AND F2.dest = 'EUG';

--zadanie 10 
SELECT  origin,
        dest,
        avg(arr_delay_new) AS "avg_delay"
FROM    "Flight_delays"
WHERE   (origin = 'MDW' OR origin = 'ORD') 
        AND (dest = 'SFO' OR dest = 'SJC' OR dest = 'OAK') 
        AND (crs_dep_time > 1400)
GROUP BY origin, dest 
ORDER BY "avg_delay" DESC;





