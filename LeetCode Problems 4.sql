LeetCode Problems 4


Type: Multiple Conditions

1. Customers Who Bought Products A and B but Not C

SELECT
    c.customer_id,
    c.customer_name
FROM customers c, orders o
WHERE c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING SUM(o.product_name = "A") > 0 AND SUM(o.product_name = "B") > 0 AND SUM(o.product_name = "C") = 0
ORDER BY c.customer_id;

2. Evaluate Boolean Expression

SELECT
    e.left_operand,
    e.operator,
    e.right_operand,
    (CASE
        WHEN e.operator = ">" AND v1.value > v2.value THEN "true"
        WHEN e.operator = "<" AND v1.value < v2.value THEN "true"
        WHEN e.operator = "=" AND v1.value = v2.value THEN "true"
        ELSE "false"
    END) AS value
FROM expressions e
JOIN variables v1 
ON e.left_operand = v1.name
JOIN variables v2 
ON e.right_operand = v2.name;


3. Page Recommendations

SELECT 
    DISTINCT page_id AS recommended_page
FROM likes
WHERE user_id IN (
    SELECT 
        CASE
            WHEN user1_id = 1 THEN user2_id
            WHEN user2_id = 1 THEN user1_id
        END AS friends1
    FROM friendship
    WHERE user1_id = 1 OR user2_id = 1
)
AND 
page_id NOT IN (
    SELECT
        page_id
    FROM likes
    WHERE user_id = 1
) 
;


#Same Query using join

SELECT 
    DISTINCT page_id AS recommended_page
FROM
    (SELECT 
        CASE
            WHEN user1_id = 1 THEN user2_id
            WHEN user2_id = 1 THEN user1_id
        END AS friends1
    FROM friendship) AS friends 
JOIN likes l
ON friends.friends1 = l.user_id
WHERE page_id NOT IN (SELECT page_id FROM likes WHERE user_id = 1)     
;


Type: Window Function (Partitiom by)

1. Find the Team Size

SELECT
    employee_id,
    COUNT(team_id) OVER (PARTITION BY team_id) AS team_size
FROM employee;

#Same query can be written as a join statement

SELECT
    e.employee_id,
    t.team_size
FROM employee e
LEFT JOIN (
    SELECT
        team_id,
        COUNT(team_id) AS team_size
    FROM employee
    GROUP BY team_id
) t
ON e.team_id = t.team_id;

2. Department Highest Salary

WITH salary_table AS(
    SELECT 
        name,
        departmentid,
        salary,
        RANK() OVER (PARTITION BY departmentid ORDER BY salary DESC) AS rank_salary
    FROM employee
)
SELECT
    d.name AS department,
    s.name AS employee,
    salary
FROM salary_table s
JOIN department d 
ON departmentid = d.id AND rank_salary = 1;


Type: Multiple joins in a single query

1. Students and Examinations

SELECT
    s1.student_id,
    s1.student_name,
    s2.subject_name,
    IFNULL(COUNT(e.subject_name),0) AS attended_exams
FROM students s1
CROSS JOIN subjects s2 -- just JOIN keyword will also work
LEFT JOIN examinations e
ON s1.student_id = e.student_id 
AND s2.subject_name = e.subject_name
GROUP BY e.student_id, e.subject_name
ORDER BY e.student_id, e.subject_name
;


Type: Multiple joins to filter result based on calculation

1. Countries You Can Safely Invest In

Please note - the query below is not the solution, but a first step in getting the feel of data in shape for calculation, actual queries are below

WITH country_calls AS (

    SELECT
    p.id,
    c1.name,
    COUNT(*) as num_calls,
    SUM(c2.duration) AS duration
FROM person p
JOIN country c1
ON LEFT(p.phone_number,3) = c1.country_code
JOIN calls c2
ON p.id= c2.caller_id
GROUP BY p.id

UNION ALL

SELECT
    p.id,
    c1.name,
    COUNT(*) as num_calls,
    SUM(c2.duration) AS duration
FROM person p
JOIN country c1
ON LEFT(p.phone_number,3) = c1.country_code
JOIN calls c2
ON p.id= c2.callee_id
GROUP BY p.id
)

SELECT
    name,
    SUM(num_calls) AS tot_calls,
    SUM(duration) AS tot_duration,
    SUM(duration) / SUM(num_calls) AS avg_duration
FROM country_calls
GROUP BY name
ORDER BY avg_duration DESC
;

# Using Having clause

SELECT
    c1.name AS country
FROM person p
JOIN country c1
ON LEFT(phone_number,3) = country_code
JOIN calls c2
ON id IN (caller_id,callee_id)
GROUP BY c1.name
HAVING AVG(duration) > (SELECT AVG(duration) FROM calls);

# Using Window Functions

SELECT
    DISTINCT name AS country
FROM (
    SELECT 
        c1.name,
        AVG(duration) OVER (PARTITION BY c1.name) AS avg_duration,
        AVG(duration) OVER () AS tot_avg_duration
    FROM person 
    JOIN country c1
    ON SUBSTR(phone_number,1,3) = country_code
    JOIN calls    
    ON id IN (caller_id, callee_id)
) AS country
WHERE avg_duration > tot_avg_duration;



Type: Aggregate Function and Join

1. Department Highest Salary

SELECT
    d.name AS department,
    e.name AS employee,
    salary
FROM employee e
JOIN department d
ON departmentid = d.id
WHERE (departmentid, salary) IN (
    SELECT
        departmentid,
        MAX(salary)
    FROM employee
    GROUP BY departmentid
)
;

# Same query using Window function

WITH salary_table AS(
    SELECT 
        name,
        departmentid,
        salary,
        RANK() OVER (PARTITION BY departmentid ORDER BY salary DESC) AS rank_salary
    FROM employee
)
SELECT
    d.name AS department,
    s.name AS employee,
    salary
FROM salary_table s
JOIN department d 
ON departmentid = d.id AND rank_salary = 1;

Type: CTE and Join

1. Count Student Number in Departments

WITH summary AS (
    SELECT
        dept_id,
        COUNT(*) AS student_number
    FROM student
    GROUP BY dept_id
)
SELECT
    dept_name,
    IFNULL(student_number,0) AS student_number
FROM department d
LEFT JOIN summary s
ON d.dept_id = s.dept_id
ORDER BY student_number DESC, dept_name;

# Same query using simple join keyword

SELECT
    dept_name,
    COUNT(student_id) AS student_number
FROM department d
LEFT JOIN student s
ON d.dept_id = s.dept_id
GROUP BY dept_name
ORDER BY student_number DESC, dept_name;

# Please make note of COUNT() - COUNT(student_id) is used instead of COUNT(*) because COUNT(expression) it does not take account if expression is null

# Same query using Sub query

SELECT
    dept_name,
    IFNULL(t.student_number,0) AS student_number
FROM department d
LEFT JOIN (
    SELECT 
        dept_id,
        COUNT(*) AS student_number
    FROM student 
    GROUP BY dept_id
) t
ON  d.dept_id = t.dept_id
ORDER BY student_number DESC, dept_name;

Type: Pivot and Join

1. 

WITH grand_slam_table AS (
    SELECT
        year,
        wimbledon AS player
    FROM championships

    UNION ALL

    SELECT
        year,
        fr_open AS player
    FROM championships

    UNION ALL

    SELECT
        year,
        us_open AS player
    FROM championships

    UNION ALL

    SELECT
        year,
        au_open AS player
    FROM championships
)

SELECT
    g.player AS player_id,
    p.player_name,
    COUNT(*) AS grand_slams_count
FROM grand_slam_table g
LEFT JOIN players p
ON g.player = p.player_id
GROUP BY g.player;


# Same query with a shorter code

SELECT
    player_id,
    player_name,
    SUM(player_id = wimbledon) + SUM(player_id = fr_open) + SUM(player_id = us_open) + SUM(player_id = au_open) AS grand_slams_count
FROM players
JOIN championships
ON player_id = wimbledon OR player_id = fr_open OR player_id = us_open OR player_id = au_open
GROUP BY player_id



Type: Subquery, Join and Conditions

1. Product Price at a Given Date

SELECT
    p.product_id,
    new_price AS price
FROM products p
JOIN (
    SELECT
        product_id,
        MAX(change_date) AS latest_date
    FROM products
    WHERE change_date <= '2019-08-16'
    GROUP BY product_id
)   AS l
ON p.product_id = l.product_id 
AND p.change_date = l.latest_date

UNION

SELECT
    DISTINCT product_id,
    10 AS price
FROM products
GROUP BY product_id
HAVING MIN(change_date) > '2019-08-16';

# Can also be written as

SELECT
    DISTINCT p.product_id,
    IFNULL(t.new_price,10) AS price
FROM products p
LEFT JOIN (
    SELECT
        *
    FROM products
    WHERE (product_id, change_date) IN (
        SELECT
            product_id,
            MAX(change_date) AS latest_date
        FROM products
        WHERE change_date <= '2019-08-16'
        GROUP BY product_id
        )
)   AS t
ON p.product_id = t.product_id 


Type: Conditional Based on Comparison between values from 2 different tables

1. Find Cutoff Score for Each School

SELECT
    s.school_id,
    IFNULL(MIN(e.score),-1) AS score
FROM schools s
LEFT JOIN exam e
ON s.capacity >= e.student_count
GROUP BY s.school_id;

Type: Moving Averages

1. Restaurant Growth

SELECT
    MAX(b.visited_on) AS visited_on,
    SUM(b.sum_amount) AS amount,
    ROUND(AVG(b.sum_amount),2) AS average_amount
FROM
(SELECT visited_on, SUM(amount) AS sum_amount FROM customer GROUP BY visited_on) AS a,
(SELECT visited_on, SUM(amount) AS sum_amount FROM customer GROUP BY visited_on) AS b
WHERE DATEDIFF(b.visited_on, a.visited_on) BETWEEN 0 AND 6
GROUP BY a.visited_on
HAVING COUNT(*) = 7
ORDER BY a.visited_on;


-- OR 

SELECT
    a.visited_on AS visited_on,
    SUM(b.sum_amount) AS amount,
    ROUND(AVG(b.sum_amount),2) AS average_amount
FROM
(SELECT visited_on, SUM(amount) AS sum_amount FROM customer GROUP BY visited_on) AS a,
(SELECT visited_on, SUM(amount) AS sum_amount FROM customer GROUP BY visited_on) AS b
WHERE DATEDIFF(a.visited_on, b.visited_on) BETWEEN 0 AND 6
GROUP BY a.visited_on
HAVING COUNT(*) = 7
ORDER BY a.visited_on;


Type: Union and Limit

1. Movie Rating


(
SELECT
    u.name AS results  
FROM movierating m
JOIN users u
ON u.user_id = m.user_id
GROUP BY m.user_id
ORDER BY COUNT(*) DESC, u.name
LIMIT 1
)


UNION 

(
SELECT
    m1.title AS results
FROM movierating m
JOIN movies m1
ON m.movie_id = m1.movie_id
WHERE LEFT(m.created_at,7) = "2020-02"
GROUP BY m.movie_id
ORDER BY AVG(m.rating) DESC, m1.title
LIMIT 1
)
;
