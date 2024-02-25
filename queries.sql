create table customer 
(
    customer_id int4,
    first_name varchar(50),
    last_name varchar(50),
    gender varchar(30),
    dob varchar(50),
    job_title varchar(50),
    job_industry_category varchar(50),
    wealth_segment varchar(50),
    deceased_indicator varchar(50),
    owns_car varchar(30),
    address varchar(50),
    postcode varchar(30),
    state varchar(30),
    country varchar(30),
    property_valuation int4,
    constraint customer_pk primary key (customer_id)
);

create table "transaction"
(
    transaction_id int4,
    product_id int4,
    customer_id int4,
    transaction_date varchar(30),
    online_order varchar(30),
    order_status varchar(30),
    brand varchar(30),
    product_line varchar(30),
    product_class varchar(30),
    product_size varchar(30),
    list_price float4,
    standard_cost float4,
    constraint transaction_pk primary key (transaction_id)
);

-- Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества.
-- Количество строк: 10

select
	job_industry_category,
	count(*)
from
	customer c
group by
	job_industry_category
order by
	count desc;

-- Найти сумму транзакций за каждый месяц по сферам деятельности, отсортировав по месяцам и по сфере деятельности.
-- Количество строк: 120

select
	date_trunc('month', transaction_date::date) as transaction_month,
	c.job_industry_category,
	sum(list_price)
from
	"transaction" t
inner join customer c on
	t.customer_id = c.customer_id
group by
	transaction_month,
	c.job_industry_category
order by
	transaction_month,
	c.job_industry_category;

-- Вывести количество онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT.
-- Количество строк: 7

select
	t.brand,
	count(*)
from
	"transaction" t
inner join customer c on
	t.customer_id = c.customer_id
where
	t.online_order = 'True'
	and t.order_status = 'Approved'
	and c.job_industry_category = 'IT'
group by
	t.brand;

-- Найти по всем клиентам сумму всех транзакций (list_price), максимум, минимум и количество транзакций, отсортировав результат по убыванию суммы транзакций и количества клиентов.
-- Выполните двумя способами: используя только group by и используя только оконные функции. Сравните результат.
-- Количество строк: 3494

select
	t.customer_id,
	sum(t.list_price) as tr_sum,
	max(t.list_price) as tr_max,
	min(t.list_price) as tr_min,
	count(*) as tr_count
from
	"transaction" t
group by
	customer_id
order by
	tr_sum desc,
	tr_count desc;

select distinct
    t.customer_id,
	sum(t.list_price) over (partition by t.customer_id) as tr_sum,
	max(t.list_price) over (partition by t.customer_id) as tr_max,
	min(t.list_price) over (partition by t.customer_id) as tr_min,
	count(*) over (partition by t.customer_id) as tr_count
from
	"transaction" t
order by
	tr_sum desc,
	tr_count desc;


-- Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций за весь период (сумма транзакций не может быть null).
-- Напишите отдельные запросы для минимальной и максимальной суммы.
-- Количество строк: 120

select
	c.first_name, 
	c.last_name,
	sub.tr_sum
from
	(
	select
		t.customer_id,
		sum(t.list_price) as tr_sum,
		rank() over (
		order by sum(t.list_price) desc) as rnk
	from
		"transaction" t
	group by
		t.customer_id
   ) sub
inner join customer c on sub.customer_id = c.customer_id
where
	sub.rnk = 1;

select
	c.first_name, 
	c.last_name,
	sub.tr_sum
from
	(
	select
		t.customer_id,
		sum(t.list_price) as tr_sum,
		rank() over (
		order by sum(t.list_price) asc) as rnk
	from
		"transaction" t
	group by
		t.customer_id
   ) sub
inner join customer c on sub.customer_id = c.customer_id
where
	sub.rnk = 1;

-- Вывести только самые первые транзакции клиентов. Решить с помощью оконных функций.
-- Количество строк: 3494

select
	t.*
from
	(
	select
		customer_id,
		transaction_id,
		rank() over (partition by t.customer_id order by t.transaction_date::date asc, t.transaction_id asc) as rnk
	from
		"transaction" t) sub
inner join "transaction" t on
	sub.transaction_id = t.transaction_id
where
	rnk = 1
order by
	customer_id;

-- Вывести имена, фамилии и профессии клиентов, между транзакциями которых был максимальный интервал (интервал вычисляется в днях).
-- Количество строк: 1

select
	c.first_name,
	c.last_name,
	c.job_title,
	sub2.tr_interval_days
from
	(
	select
		sub1.customer_id,
		sub1.tr_interval_days,
		rank() over (
		order by sub1.tr_interval_days desc) rnk
	from
		(
		select
			t.customer_id,
			transaction_date::date - lag(transaction_date::date) over (order by customer_id,transaction_date::date) as tr_interval_days
		from
			"transaction" t) sub1
	where
		tr_interval_days is not null) sub2
inner join customer c on sub2.customer_id = c.customer_id
where
	sub2.rnk = 1;
