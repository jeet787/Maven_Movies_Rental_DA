-- DATA ANALYSIS PROJECT FOR RENTAL MOVIES BUSINESS
-- THE STEPS INVOLVED ARE EDA, UNDERSTANDING THR SCHEMA AND ANSWERING THE AD-HOC QUESTIONS
-- BUSINESS QUESTIONS LIKE EXPANDING MOVIES COLLECTION AND FETCHING EMAIL IDS FOR MARKETING ARE INCLUDED
-- HELPING COMPANY KEEP A TRACK OF INVENTORY AND HELP MANAGE IT.

USE MAVENMOVIES;

-- EXPLORATORY DATA ANALYSIS --

-- UNDERSTANDING THE SCHEMA --

SELECT * FROM RENTAL;

SELECT CUSTOMER_ID, RENTAL_DATE
FROM RENTAL;

SELECT * FROM INVENTORY;

SELECT * FROM FILM;

SELECT * FROM CUSTOMER;

-- You need to provide customer firstname, lastname and email id to the marketing team --

SELECT FIRST_NAME,LAST_NAME,EMAIL
FROM CUSTOMER ;

-- How many movies are with rental rate of $0.99? --

SELECT COUNT(RENTAL_RATE) AS CHEAPEST_RENT
FROM FILM 
WHERE RENTAL_RATE=0.99;

-- We want to see rental rate and how many movies are in each rental category --

SELECT RENTAL_RATE,COUNT(FILM_ID) AS TOTAL_MOVIES
FROM FILM
GROUP BY RENTAL_RATE;

-- Which rating has the most films? --

SELECT RATING,COUNT(FILM_ID) AS TOTAL_RATING
FROM FILM
GROUP BY RATING
ORDER BY TOTAL_RATING DESC;

-- Which rating is most prevalant in each store? --

SELECT I.STORE_ID,F.RATING,COUNT(F.RATING) AS TOTAL_MOVIES
FROM INVENTORY AS I LEFT JOIN FILM AS F
ON I.FILM_ID=F.FILM_ID
GROUP BY I.STORE_ID,F.RATING
ORDER BY TOTAL_MOVIES DESC;

-- List of films by Film Name, Category, Language --

SELECT F.TITLE AS FILM_NAME,C.NAME AS CATEGORY_NAME,L.NAME AS LANGUAGE_NAME
FROM FILM_CATEGORY AS FC LEFT JOIN CATEGORY AS C
ON FC.CATEGORY_ID=C.CATEGORY_ID LEFT JOIN FILM AS F
ON FC.FILM_ID = F.FILM_ID LEFT JOIN LANGUAGE AS L
ON F.LANGUAGE_ID=L.LANGUAGE_ID;

-- How many times each movie has been rented out?

select f.film_id,f.title,count(*) as count_of_movies
from rental as r left join inventory as i
on r.inventory_id=i.inventory_id left join film as f
on i.film_id=f.film_id
group by i.film_id
order by count_of_movies desc;

-- REVENUE PER FILM (TOP 10 GROSSERS)

select f.title,sum(p.amount) as film_grossing
from payment as P left join rental as R
on p.rental_id = r.rental_id left join inventory as inv
on r.inventory_id=inv.inventory_id left join film as f
on inv.film_id=f.film_id
group by f.title
order by film_grossing desc
limit 10;

-- Most Spending Customer so that we can send him/her rewards or debate points

select *
from customer
where(customer_id in(select x.customer_id
from(
select customer_id,sum(amount) as revenue
from payment 
group by customer_id
order by revenue desc
limit 10) as x));

select c.customer_id,c.first_name,c.last_name,c.email,sum(p.amount) as revenue
from payment as p left join customer as c
on p.customer_id=c.customer_id
group by customer_id 
order by revenue desc
limit 1;

-- Which Store has historically brought the most revenue?

select st.store_id,sum(p.amount) as revenue 
from payment as p left join staff as st
on p.staff_id = st.staff_id
group by st.store_id
order by revenue desc ;

-- How many rentals we have for each month

select extract(month from rental_date)as month_number,extract(year from rental_date) as year_name,count(*) as number_of_rentals
from rental
group by extract(year from rental_date),extract(month from rental_date);

-- Reward users who have rented at least 30 times (with details of customers)

select customer_id,count(rental_id) as number_of_rentals
from rental
group by customer_id
having number_of_rentals >=30 
order by number_of_rentals desc;

select c.customer_id,c.first_name,c.last_name,c.email,count(r.rental_id) as number_of_rentals
from rental as r left join customer as c
on r.customer_id = c.customer_id
group by c.customer_id
having number_of_rentals >= 30
order by number_of_rentals desc;

-- We need to understand the special features in our films. Could you pull a list of films which
-- include a Behind the Scenes special feature?

select *
from film
where special_features like "%Behind the Scenes%";

-- unique movie ratings and number of movies

select rating , count(*) as count_of_movies
from film
group by rating
order by count_of_movies desc ;

-- Could you please pull a count of titles sliced by rental duration?

select rental_duration,count(film_id) as number_of_films
from film
group by rental_duration;

-- RATING, COUNT_MOVIES,LENGTH OF MOVIES AND COMPARE WITH RENTAL DURATION

select rating , count(*) as count_of_movies,min(length),round(avg(length),0) as average_film_length,max(length), round(avg(rental_duration),0)as average_of_rental_duration
from film
group by rating
order by count_of_movies desc ;

-- I’m wondering if we charge more for a rental when the replacement cost is higher.
-- Can you help me pull a count of films, along with the average, min, and max rental rate,
-- grouped by replacement cost?

select replacement_cost,count(film_id)as number_of_films,avg(rental_rate),min(rental_rate),max(rental_rate)
from film
group by replacement_cost
order by replacement_cost asc;

-- “I’d like to talk to customers that have not rented much from us to understand if there is something
-- we could be doing better. Could you pull a list of customer_ids with less than 15 rentals all-time?”



select c.customer_id,c.first_name,c.last_name,c.email,count(r.rental_id) as number_of_rentals
from rental as r left join customer as c
on r.customer_id = c.customer_id
group by c.customer_id
having number_of_rentals <= 15
order by number_of_rentals desc;

-- CATEGORIZE MOVIES AS PER LENGTH

select length,title,
case
when length < 60 then "short movie"
when length between 60 and 90 then "medium length movie"
when length > 90 then "long length movie"
else "error"
end as movie_lenght_bucket 
from film 
;

-- CATEGORIZING MOVIES TO RECOMMEND VARIOUS AGE GROUPS AND DEMOGRAPHIC

SELECT DISTINCT TITLE,
	CASE
		WHEN RENTAL_DURATION <= 4 THEN 'RENTAL TOO SHORT'
        WHEN RENTAL_RATE >= 3.99 THEN 'TOO EXPENSIVE'
        WHEN RATING IN ('NC-17','R') THEN 'TOO ADULT'
        WHEN LENGTH NOT BETWEEN 60 AND 90 THEN 'TOO SHORT OR TOO LONG'
        WHEN DESCRIPTION LIKE '%Shark%' THEN 'NO_NO_HAS_SHARKS'
        ELSE 'GREAT_RECOMMENDATION_FOR_CHILDREN'
	END AS FIT_FOR_RECOMMENDATTION
FROM FILM;

select *
 from film;

-- “I’d like to know which store each customer goes to, and whether or
-- not they are active. Could you pull a list of first and last names of all customers, and
-- label them as either ‘store 1 active’, ‘store 1 inactive’, ‘store 2 active’, or ‘store 2 inactive’?”

select customer_id,first_name,last_name,
case
when store_id=1 and active =1 then "store_1_active"
when store_id=1 and active =0 then "store_1_inactive"
when store_id=2 and active =1 then "store_2_active"
when store_id=2 and active =0 then "store_2_inactive"
else 'erroe'
end as active_inactive_customers
from customer;

-- “Can you pull for me a list of each film we have in inventory?
-- I would like to see the film’s title, description, and the store_id value
-- associated with each item, and its inventory_id. Thanks!”

select inv.inventory_id,f.title,inv.store_id,inv.film_id,f.description
from inventory as inv inner join film as f
on inv.film_id=f.film_id;

-- Actor first_name, last_name and number of movies

select a.actor_id,a.first_name,a.last_name,count(fa.film_id) as total_movies
from actor as a left join film_actor as fa 
on a.actor_id = fa.actor_id
group by a.actor_id;

-- “One of our investors is interested in the films we carry and how many actors are listed for each
-- film title. Can you pull a list of all titles, and figure out how many actors are
-- associated with each title?”

select f.film_id,f.title,count(fa.actor_id) as actors_count
from film as f left join film_actor as fa 
on f.film_id = fa.film_id
group by f.film_id;

-- “Customers often ask which films their favorite actors appear in. It would be great to have a list of
-- all actors, with each title that they appear in. Could you please pull that for me?”

select a.actor_id,a.first_name,a.last_name,f.title
from actor as a left join film_actor as fa
on a.actor_id = fa.actor_id left join film as f
on fa.film_id = f.film_id;

-- “The Manager from Store 2 is working on expanding our film collection there.
-- Could you pull a list of distinct titles and their descriptions, currently available in inventory at store 2?”

select  distinct f.title,f.description
from film as f inner join inventory as inv
on f.film_id = inv.film_id
where inv.store_id = 2;

-- “We will be hosting a meeting with all of our staff and advisors soon. Could you pull one list of all staff
-- and advisor names, and include a column noting whether they are a staff member or advisor? Thanks!”

(select first_name,last_name ,"staff_member" as designation from staff 
union
select first_name,last_name,"advisor" as designation from advisor)