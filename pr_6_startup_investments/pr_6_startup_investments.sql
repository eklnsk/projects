--подсчет количества закрывшихся компаний
SELECT COUNT(status)
FROM company
WHERE status = 'closed';

--подсчет количества привлечённых средств для новостных компаний США 
SELECT SUM(funding_total) AS funding_total
FROM company
WHERE category_code = 'news'
  AND country_code = 'USA'
GROUP BY name
ORDER BY funding_total DESC;

/*расчет общей суммы сделок по покупке одних компаний другими, 
которые осуществлялись только за наличные с 2011 по 2013 год включительно*/
SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
  AND EXTRACT(YEAR FROM CAST(acquired_at AS timestamp)) BETWEEN 2011 AND 2013;

/*вывод имени, фамилии и названия аккаунтов людей в твиттере, 
у которых названия аккаунтов начинаются на 'Silver'*/
SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

/*вывод всей информацию о людях, у которых названия аккаунтов в твиттере 
содержат подстроку 'money', а фамилия начинается на 'K'*/
SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
  AND last_name LIKE 'K%';

/*расчет общей суммы привлечённых инвестиций, которые получили компании, 
зарегистрированные в каждой стране*/
SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

/*составление таблицы с датой проведения раунда, а также минимальным и максимальным
значением суммы инвестиций, привлечённых в эту дату*/
SELECT funded_at,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) <> 0
  AND MIN(raised_amount) <> MAX(raised_amount);

/*создание поля с категориями, определяемыми по количеству инвестируемых фондами компаний*/
SELECT *,
       CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies >= 20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund;

/*расчет среднего количества инвестиционных раундов, в которых фонд принимал участие,
для каждой из категорий*/
SELECT 
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds)) AS avg_number
FROM fund
GROUP BY activity
ORDER BY avg_number;

/*расчет для каждой страны минимального, максимального и среднего числа компаний, 
в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно
кроме страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю,
вывод топ-10 стран-инвесторов*/
SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS timestamp)) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) <> 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;

--вывод имени, фамилии и названия учебного заведения, которое окончил сотрудник
SELECT p.first_name,
       p.last_name,
       e.instituition 
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id;

/*расчет количества учебных заведений, которые окончили сотрудники каждой компании,
вывод топ-5 компаний по количеству университетов*/
SELECT c.name, 
       COUNT(DISTINCT e.instituition) AS ed_count
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
INNER JOIN education AS e ON p.id = e.person_id
GROUP BY name
ORDER BY ed_count DESC
LIMIT 5;

--вывод названий закрывшихся компаний, для которых первый раунд финансирования оказался последним
WITH
i AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
        AND is_last_round = 1),
j AS (SELECT id,
             name
      FROM company
      WHERE status = 'closed')
SELECT DISTINCT j.name
FROM i 
JOIN j ON j.id = i.company_id;

/*вывод id сотрудников, работавших в теперь уже закрывшихся компаниях, для которых первый раунд 
финансирования оказался последним*/
WITH
i AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
        AND is_last_round = 1),
j AS (SELECT id,
             name
      FROM company
      WHERE status = 'closed')
SELECT p.id
FROM people AS p
WHERE company_id IN (SELECT DISTINCT j.id
                     FROM i 
                     JOIN j ON j.id = i.company_id);

/*вывод id сотрудников, работавших в теперь уже закрывшихся компаниях, для которых первый раунд 
финансирования оказался последним, а также названий учебных заведений, которые эти сотрудники закончили*/
WITH
i AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
        AND is_last_round = 1),
j AS (SELECT id,
             name
      FROM company
      WHERE status = 'closed')
SELECT p.id,
       e.instituition
FROM people AS p
JOIN education AS e ON p.id = e.person_id
WHERE company_id IN (SELECT DISTINCT j.id
                     FROM i 
                     JOIN j ON j.id = i.company_id)
GROUP BY p.id, e.instituition;

/*вывод id сотрудников, работавших в теперь уже закрывшихся компаниях, для которых первый раунд 
финансирования оказался последним, а также количества учебных заведений, которые эти сотрудники закончили*/
WITH
i AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
        AND is_last_round = 1),
j AS (SELECT id,
             name
      FROM company
      WHERE status = 'closed')
SELECT p.id,
       COUNT(e.instituition)
FROM people AS p
JOIN education AS e ON p.id = e.person_id
WHERE company_id IN (SELECT DISTINCT j.id
                     FROM i 
                     JOIN j ON j.id = i.company_id)
GROUP BY p.id;

/*расчет среднего число учебных заведений, которые окончили сотрудники закрывшихся компаний,
для которых первый раунд финансирования оказался последним*/
WITH
i AS (SELECT company_id
      FROM funding_round
      WHERE is_first_round = 1
        AND is_last_round = 1),
j AS (SELECT id,
             name
      FROM company
      WHERE status = 'closed')
SELECT AVG(i_count)
FROM
  (SELECT p.id,
          COUNT(e.instituition) AS i_count
   FROM people AS p
   JOIN education AS e ON p.id = e.person_id
   WHERE company_id IN (SELECT DISTINCT j.id
                        FROM i 
                        JOIN j ON j.id = i.company_id)
                        GROUP BY p.id) AS id_count;

--вывод среднего числа учебных заведений, которые окончили сотрудники Facebook
SELECT AVG(f_count)
FROM
  (SELECT p.id,
          COUNT(e.instituition) AS f_count
   FROM people AS p
   JOIN company AS c ON p.company_id = c.id
   JOIN education AS e ON p.id = e.person_id
   WHERE c.name = 'Facebook'
   GROUP BY p.id) AS f_data;

/*составление таблицы с названием фонда, названием компании и суммой инвестиций, 
которую привлекла компания в раунде (учитывались только компании, в истории которых 
было больше 6 важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно*/
SELECT f.name,
       name_of_company,
       amount
FROM (SELECT fr.id,
             c.name AS name_of_company,
             fr.raised_amount AS amount
      FROM funding_round AS fr
      JOIN company AS c ON c.id = fr.company_id
      WHERE EXTRACT(YEAR FROM CAST(funded_at AS timestamp)) BETWEEN 2012 AND 2013 
        AND milestones > 6) AS frc
JOIN investment AS i ON i.funding_round_id = frc.id
JOIN fund AS f ON f.id = i.fund_id;

/*составление таблицы с названием компании-покупателя, суммой сделки, названием компании, которую купили,
суммой инвестиций, вложенных в купленную компанию, долей, которая отображает, во сколько раз 
сумма покупки превысила сумму вложенных в компанию инвестиций*/ 
WITH
a AS (SELECT acquiring_company_id,
             acquired_company_id,
             price_amount
      FROM acquisition
      WHERE price_amount > 0),
f AS (SELECT id,
             funding_total
      FROM company
      WHERE funding_total > 0)
SELECT c.name AS acquiring_company_name,
       a.price_amount,
       com.name AS acquired_company_name,
       f.funding_total,
       ROUND(a.price_amount / f.funding_total) AS share
FROM a
LEFT JOIN f ON a.acquired_company_id = f.id
JOIN company AS c ON a.acquiring_company_id = c.id
JOIN company AS com ON a.acquired_company_id = com.id
WHERE f.funding_total IS NOT NULL
ORDER BY price_amount DESC, acquired_company_name
LIMIT 10;

/*составление таблицы с названиями компаний из категории social, получивших финансирование 
с 2010 по 2013 год включительно, а также номерами месяцев, в которых проходили раунды финансирования*/
WITH
a AS (SELECT company_id,
             EXTRACT(MONTH FROM CAST(funded_at AS timestamp)) AS month
      FROM funding_round
      WHERE EXTRACT(YEAR FROM CAST(funded_at AS timestamp)) BETWEEN 2010 AND 2013
        AND raised_amount > 0),
b AS (SELECT id,
             name
      FROM company
      WHERE category_code = 'social')
SELECT b.name,
       a.month
FROM a 
JOIN b ON a.company_id = b.id;

/*составление таблицы с номером месяца, в котором проходили раунды, количеством уникальных названий
фондов из США, которые инвестировали в этом месяце, количеством компаний, купленных за этот месяц,
общей суммой сделок по покупкам в этом месяце (использовались данные с 2010 по 2013 год)*/
WITH
f AS (SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS timestamp)) AS month,
             COUNT(DISTINCT i.fund_id) AS fund_count
      FROM funding_round AS fr
      JOIN investment AS i ON fr.id = i.funding_round_id
      WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS timestamp)) BETWEEN 2010 AND 2013
        AND i.fund_id IN (SELECT id
                          FROM fund
                          WHERE country_code = 'USA')
      GROUP BY month),
a AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS timestamp)) AS month,
             COUNT(acquired_company_id) AS total_count,
             SUM(price_amount) AS total_price
      FROM acquisition
      WHERE EXTRACT(YEAR FROM CAST(acquired_at AS timestamp)) BETWEEN 2010 AND 2013
      GROUP BY month)
 SELECT f.month,
        f.fund_count,
        a.total_count,
        a.total_price
FROM f
JOIN a ON f.month = a.month;

/*составление таблицы со средним значением суммы инвестиций для стран, в которых есть стартапы, 
зарегистрированные в 2011, 2012 и 2013 годах*/
WITH
y_2011 AS (SELECT country_code,
                  AVG(funding_total) AS avg_2011
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS timestamp)) = 2011
           GROUP BY country_code),
y_2012 AS (SELECT country_code,
                  AVG(funding_total) AS avg_2012
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS timestamp)) = 2012
           GROUP BY country_code),
y_2013 AS (SELECT country_code,
                  AVG(funding_total) AS avg_2013
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS timestamp)) = 2013
           GROUP BY country_code)
SELECT y_2011.country_code,
       y_2011.avg_2011,
       y_2012.avg_2012,
       y_2013.avg_2013
FROM y_2011
JOIN y_2012 ON y_2011.country_code = y_2012.country_code
JOIN y_2013 ON y_2011.country_code = y_2013.country_code
ORDER BY avg_2011 DESC;