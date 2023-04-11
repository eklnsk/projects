/*расчет количества вопросов, которые набрали больше 300 очков 
или как минимум 100 раз были добавлены в «Закладки»*/
SELECT COUNT(p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
WHERE pt.type = 'Question'
AND (score > 300
  OR favorites_count >= 100);

--расчет среднего количества вопросов в день с 1 по 18 ноября 2008 включительно
 WITH q AS (SELECT p.creation_date::date AS dt,
                  COUNT(p.id) AS cnt
           FROM stackoverflow.posts AS p
           JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
           WHERE pt.type = 'Question'
             AND p.creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
           GROUP BY dt)
SELECT ROUND(AVG(cnt)) AS avg_cnt
FROM q;

--расчет количества пользователей, которые получили значки сразу в день регистрации
WITH dates AS (SELECT u.id,
                      u.creation_date::date AS reg_dt,
                      b.creation_date::date AS badge_dt
               FROM stackoverflow.users AS u
               JOIN stackoverflow.badges AS b ON u.id = b.user_id)
SELECT COUNT(DISTINCT id)
FROM dates
WHERE reg_dt = badge_dt;

--расчет количества уникальных постов пользователя с именем Joel Coehoorn 
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id = p.user_id
JOIN stackoverflow.votes AS v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn';

--добавление в таблицу с типами голосов поля с рангом, в которое войдут номера записей в обратном порядке
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

/*вывод идентификатора пользователя и количества голосов для 10 пользователей, 
которые поставили больше всего голосов типа "Close"*/
SELECT v.user_id,
       COUNT(v.id) AS vt_cnt    
FROM stackoverflow.votes AS v        
JOIN stackoverflow.vote_types AS vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
GROUP BY v.user_id
ORDER BY vt_cnt DESC,
         v.user_id DESC
LIMIT 10;


/*вывод идентификатора пользователя, числа значков, места в рейтинге (чем больше значков, тем выше рейтинг)
для 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно*/
WITH b_cnt AS (SELECT u.id,
                      COUNT(b.id) AS b_amt
               FROM stackoverflow.users AS u
               JOIN stackoverflow.badges AS b ON u.id = b.user_id
               WHERE b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
               GROUP BY u.id)
SELECT id,
       b_amt,
       DENSE_RANK() OVER (ORDER BY b_amt DESC)
FROM b_cnt
ORDER BY b_amt DESC,
         id
LIMIT 10;

/*вывод заголовка поста, идентификатора пользователя, числа очков поста, среднего числа
очков пользователя за пост, округлённого до целого числа, без учета постов без заголовка и с нулевым количеством очков*/
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id)) AS avg_amt
FROM stackoverflow.posts
WHERE title <> ' '
  AND score <> 0;
  
/*вывод заголовков постов, которые были написаны пользователями, получившими более 1000 значков, 
без учета постов без заголовков*/
SELECT title
FROM stackoverflow.posts
WHERE title <> ' '
  AND user_id IN (SELECT user_id
                  FROM stackoverflow.badges
                  GROUP BY user_id
                  HAVING COUNT(id) > 1000);
                  
/*вывод идентификатора пользователя, количества просмотров профиля и определение группы (в зависимости 
от количества просмотров их профилей) среди пользователей из США с ненулевым количеством просмотров*/                 
SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 100 THEN 3
           ELSE 2
       END
FROM stackoverflow.users
WHERE location LIKE '%United States%'
  AND views <> 0;
  
--вывод лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе
WITH pr AS (SELECT id,
                   views,
                   CASE
                       WHEN views >= 350 THEN 1
                       WHEN views < 100 THEN 3
                       ELSE 2
                   END AS category
            FROM stackoverflow.users
            WHERE location LIKE '%United States%'
              AND views <> 0),
max_views AS (SELECT *,
              MAX(views) OVER (PARTITION BY category) AS max_views
              FROM pr)
SELECT id,
       category,
       views
FROM max_views
WHERE views = max_views
ORDER BY views DESC,
         id;
         
--расчет ежедневного прироста новых пользователей в ноябре 2008 года 
WITH daily_users AS (SELECT EXTRACT(DAY FROM creation_date) AS n_day,
                            COUNT(id) AS users_amt
                     FROM stackoverflow.users 
                     WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
                     GROUP BY n_day)
SELECT n_day,
       users_amt,
       SUM(users_amt) OVER (ORDER BY n_day) AS cum_amt
FROM daily_users;


/*расчет интервала между регистрацией и временем создания первого поста для каждого пользователя, 
который написал хотя бы один пост*/
WITH dates AS (SELECT DISTINCT u.id,
                      u.creation_date AS reg_dt,
               FIRST_VALUE(p.creation_date) OVER (PARTITION BY u.id ORDER BY p.creation_date) AS post_dt
               FROM stackoverflow.users AS u
               JOIN stackoverflow.posts AS p ON u.id = p.user_id)
SELECT id,
       post_dt - reg_dt AS dt_diff
FROM dates;

--подсчет общей суммы просмотров постов за каждый месяц 2008 года 
SELECT DATE_TRUNC('month', creation_date)::date AS month_dt,
       SUM(views_count) AS total_views
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date) = 2008
GROUP BY month_dt
ORDER BY total_views DESC;

/*вывод имен самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) 
дали больше 100 ответов, подсчет уникальных значений user_id для каждого имени*/
SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id = u.id
JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id 
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month')
   AND pt.type LIKE '%Answer%'
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name;

/*вывод количества постов за 2008 год по месяцам среди пользователей, которые зарегистрировались 
в сентябре 2008 года и сделали хотя бы один пост в декабре того же года*/
SELECT DATE_TRUNC('month', creation_date)::date AS dt,
       COUNT(id)
FROM stackoverflow.posts
WHERE user_id IN (SELECT DISTINCT u.id
                  FROM stackoverflow.users AS u
                  JOIN stackoverflow.posts AS p ON u.id = p.user_id
                  WHERE u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
                    AND p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31')
GROUP BY dt
ORDER BY dt DESC;

/*вывод идентификатора пользователя, который написал пост, даты создания поста, количества просмотров у текущего поста
и суммы просмотров постов автора с накоплением*/
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY user_id;

/*подсчет среднего количества дней, в которые пользователи публиковали хотя бы один пост,
в период с 1 по 7 декабря 2008 года включительно*/ 
WITH pr AS (SELECT user_id,
                   COUNT(DISTINCT creation_date::date) AS days_cnt
            FROM stackoverflow.posts
            WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
            GROUP BY user_id)
SELECT ROUND(AVG(days_cnt))
FROM pr;

/*для периода с 1 сентября по 31 декабря 2008 года вывод номера месяца, количества постов за месяц, 
процента, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим*/ 
WITH posts AS (SELECT EXTRACT(MONTH FROM creation_date) AS month_dt,
                      COUNT(id) AS posts_cnt
               FROM stackoverflow.posts
               WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
               GROUP BY month_dt)
SELECT month_dt,
       posts_cnt,
       ROUND((posts_cnt::numeric / LAG(posts_cnt) OVER () - 1) * 100, 2) AS perc
FROM posts;   

/*вывод номера недели в октябре 2008 года и даты и времени последнего поста, опубликованного на этой неделе,
для пользователя, который опубликовал больше всего постов за всё время*/
WITH 
u AS (SELECT user_id,
                  COUNT(id) AS posts_cnt
           FROM stackoverflow.posts
           GROUP BY user_id),
p AS (SELECT user_id,
             creation_date,
             EXTRACT(WEEK FROM creation_date) AS week_num
      FROM stackoverflow.posts
      WHERE user_id IN (SELECT user_id
                        FROM u
                        WHERE posts_cnt = (SELECT MAX(posts_cnt)
                                           FROM u))
                          AND creation_date::date BETWEEN '2008-10-01' AND '2008-10-31')
SELECT DISTINCT week_num,
       MAX(creation_date) OVER (PARTITION BY week_num)
FROM p
ORDER BY week_num;