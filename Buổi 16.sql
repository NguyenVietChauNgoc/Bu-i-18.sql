EX1 
WITH FirstOrders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM 
        delivery
    GROUP BY 
        customer_id
),
FirstOrderDetails AS (
    SELECT 
        f.customer_id,
        f.first_order_date,
        d.delivery_id,
        d.customer_pref_delivery_date,
        CASE 
            WHEN d.order_date = d.customer_pref_delivery_date THEN 1
            ELSE 0
        END AS is_immediate
    FROM 
        FirstOrders f
    JOIN 
        delivery d
    ON 
        f.customer_id = d.customer_id AND f.first_order_date = d.order_date
)
SELECT 
    ROUND(AVG(is_immediate) * 100, 2) AS immediate_percentage
FROM 
    FirstOrderDetails;
EX2
WITH Dangnhapdautien AS (
    SELECT
        player_id,
        MIN(event_date) AS dang_nhap_dau_tien
    FROM
        Activity
    GROUP BY
        player_id ),

Danhnhapthuhai AS (
    SELECT
        a.player_id,
        a.event_date
    FROM
        Activity a
    JOIN
       Dangnhapdautien fl
    ON
        a.player_id = fl.player_id
    WHERE
        a.event_date = DATE_ADD(fl.dang_nhap_dau_tien, INTERVAL 1 DAY))

SELECT
    ROUND(
        (SELECT COUNT(DISTINCT player_id) FROM Dangnhapthuhai) / 
        (SELECT COUNT(DISTINCT player_id) FROM Activity),
        2
    ) AS fraction;
EX3
WITH NumberedSeats AS (
    SELECT
        id,
        student,
        ROW_NUMBER() OVER (ORDER BY id) AS row_num
    FROM
        Seat
),
SwappedSeats AS (
    SELECT
        id,
        CASE
            WHEN MOD(row_num, 2) = 1 THEN LEAD(student) OVER (ORDER BY id)
            WHEN MOD(row_num, 2) = 0 THEN LAG(student) OVER (ORDER BY id)
            ELSE student
        END AS student
    FROM
        NumberedSeats
)
SELECT
    id,
    student
FROM
    SwappedSeats
ORDER BY
    id;
ex4
WITH trungbinhphim AS (
    SELECT
        visited_on,
        SUM(amount) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS sum_amount,
        COUNT(*) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS count_days
    FROM
        Customer
)
SELECT
    visited_on,
    sum_amount AS amount,
    ROUND(sum_amount / count_days, 2) AS average_amount
FROM
    trungbinhphim
WHERE
    count_days = 7
ORDER BY
    visited_on;
ex5 
WITH RankedSalaries AS (
    SELECT
        e.id,
        e.name AS Employee,
        e.salary,
        e.departmentId,
        d.name AS Department,
        DENSE_RANK() OVER (
            PARTITION BY e.departmentId
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM
        Employee e
    JOIN
        Department d
    ON
        e.departmentId = d.id
)
SELECT
    Department,
    Employee,
    salary AS Salary
FROM
    RankedSalaries
WHERE
    salary_rank <= 3
ORDER BY
    Department, Salary DESC;
EX5
WITH SharedTiv2015 AS (
    SELECT
        tiv_2015
    FROM
        Insurance
    GROUP BY
        tiv_2015
    HAVING
        COUNT(*) > 1
),
thanhphoduynhat AS (
    SELECT
        lat,
        lon
    FROM
        Insurance
    GROUP BY
        lat, lon
    HAVING
        COUNT(*) = 1
),
dudieukien AS (
    SELECT
        i.tiv_2016
    FROM
        Insurance i
    JOIN
        SharedTiv2015 s
    ON
        i.tiv_2015 = s.tiv_2015
    JOIN
        thanhphoduynhat u
    ON
        i.lat = u.lat AND i.lon = u.lon
)
SELECT
    ROUND(SUM(tiv_2016), 2) AS tiv_2016
FROM
    dudieukien;
EX7
WITH newtable AS (
    SELECT
        person_name,
        weight,
        turn
    FROM
        Queue
    ORDER BY
        turn
),

tongtrongluong AS (
    SELECT
        person_name,
        weight,
        turn,
        SUM(weight) OVER (ORDER BY turn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS tong_trong_luong 
    FROM
       newtable
)
SELECT
    person_name
FROM
    tongtrongluong
WHERE
   tong_trong_luong <= 1000
ORDER BY
    turn DESC
LIMIT 1;
ex8 
WITH LatestPrices AS (
    SELECT
        product_id,
        new_price,
        change_date
    FROM
        Products
    WHERE
        change_date <= '2019-08-16'
    QUALIFY
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY change_date DESC) = 1
),
FinalPrices AS (
    SELECT
        product_id,
        COALESCE(LatestPrices.new_price, 10) AS price
    FROM
        (SELECT DISTINCT product_id FROM Products) AS AllProducts
    LEFT JOIN
        LatestPrices
    ON
        AllProducts.product_id = LatestPrices.product_id
)
SELECT
    product_id,
    price
FROM
    FinalPrices
ORDER BY
    product_id;
ex6 Buổi 17 
WITH thanhtoanlaplai AS (
    SELECT
        t1.transaction_id AS t1_id,
        t2.transaction_id AS t2_id,
        t1.merchant_id,
        t1.credit_card_id,
        t1.amount
    FROM
        transactions t1
    JOIN
        transactions t2
    ON
        t1.merchant_id = t2.merchant_id
        AND t1.credit_card_id = t2.credit_card_id
        AND t1.amount = t2.amount
        AND t1.transaction_id < t2.transaction_id
        AND ABS(TIMESTAMPDIFF(MINUTE, t1.transaction_timestamp, t2.transaction_timestamp)) <= 10
),
demthanhtoanlaplai AS (
    SELECT DISTINCT
        t1_id
    FROM
        thanhtoanlaplai
)

SELECT
    COUNT(*) AS payment_count
FROM
    demthanhtoanlaplai;
