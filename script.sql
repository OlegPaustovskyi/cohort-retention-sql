with cleaned_userdate_CTE as (				--очищення дат у cohort_users_raw
	select
		user_id,
		full_name,
		email,
		country,
		signup_source,
		signup_device,
		promo_signup_flag,
		replace(
 			replace(
 				split_part(
 					ltrim(signup_datetime),' ',1),
 					'.', '/')
 					,'-','/') as dt
	from cohort_users_raw),
cohort_users_CTE as (select 
	user_id,
	full_name,
	email,
	country,
	signup_source,
	signup_device,
	promo_signup_flag,
	CASE
		when length(split_part(dt, '/', 3)) = 2
			then to_date(dt, 'DD/MM/YY')
		when length(split_part(dt, '/', 3)) = 4
			then to_date(dt, 'DD/MM/YYYY')
		else null
	end AS date_user
from cleaned_userdate_CTE),
cleaned_dateevents_CTE as (				-- очищення дат у cohort_events_raw		
	select 
	event_id,
	user_id,
	event_type,
	revenue,
 		replace(
 			replace(
 				split_part(
 					ltrim(event_datetime),' ',1),'.', '/'),'-','/') as dt
	from cohort_events_raw),
cohort_events_CTE as (select 			-- приведення до одного вигляду дат
	event_id,
	user_id,
	event_type,
	revenue,
    CASE
		when length(split_part(dt, '/', 3)) = 2
            then to_date(dt, 'DD/MM/YY')
		when length(split_part(dt, '/', 3)) = 4
            then to_date(dt, 'DD/MM/YYYY')
       ELSE null		
	end as event_date  
	from cleaned_dateevents_CTE),
join_data_CTE as (select 
	cde.event_id,
	cde.user_id,
	cde.event_type,
	cde.revenue, 
	cud.full_name,
	cud.email,
	cud.country,
	cud.signup_source,
	cud.signup_device,
	cud.promo_signup_flag,
	date_trunc('month',cud.date_user) as date_registration,
	date_trunc('month', cde.event_date) as event_date
from cohort_users_CTE as cud
join cohort_events_CTE as cde  on  cde.user_id = cud.user_id)
select 										-- остаточна вирбырка
	count(distinct user_id) as count_users,
	promo_signup_flag,
	date_registration as cohort_month,
	case 
		when event_type = 'registration' then 0
		else 
			(extract(year from event_date) - extract(year from date_registration))*12 +
			(extract(month from event_date) - extract(month from date_registration))	
	end as month_ofset	
from join_data_CTE
where 
	date_registration is not null 
	and event_date is not null 
	and event_type is not  null
	and event_type != 'test_event'
	and event_date BETWEEN '2025/01/01' AND '2025/06/30'
group by promo_signup_flag, date_registration, month_ofset
order by promo_signup_flag, date_registration, month_ofset