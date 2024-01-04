--Our SUD Counselors needed a way to be alerted about any needs that the client sitting in front of them had an also deliver a quick way for them to meet the need without requiring too many clicks
--Created a SQL virtual view that added to our EHR Individual Therapy Note form -- Only client's whose opened chart matches the people_id will display the alert.
--This SQL view supports alerts towards a measure the agency is required to report on for our CCBHC SAMHSA Grant. Filters to existing Outpatient Clients under the age of 18 who do not have an existing Alcohol Use Diagnosis 
--based on ICD 10 codes and have not had an CCBHC ASC Alcohol Use Assessment in the last year.


-- Skills Used:  Select, Where, CTE, Group BY, Joins, concatonation

--Output: people_id, Alert Category, Alert Description, HTML URL to form


--Client Alert for CCBHC ASC Measure --
--Clients with AUD diagnosis
with customer_aud_diag as 
	(
	select distinct
			 el.people_id
		  from event_log el
		  join event_definition ed
			on el.event_definition_id = ed.event_definition_id
		  join diagnosis_data dd
			on dd.event_log_id = el.event_log_id
		  join diagnoses d
			on d.diagnoses_id = dd.diagnoses_id
		  where ed.event_name like 'Diagnosis General'
		  and end_date is null
		  and icd10_code like 'f10%'
	)
--clients who are currently enrolled with a facility placement in OP clinic and active enrollment in CCBHC, OP, or Intake/Reg
, enrolled_clients as
	(
		SELECT distinct
			pe.pe_people_id
		  FROM [program_enrollment] pe
		  join program_info pi
			on pi.program_info_id = pe.program_info_id
		  join enrollment e
			on e.enr_program_enrollment_event_id = pe.program_enrollment_id
		  join group_profile gp
			on e.group_profile_id = gp.group_profile_id
		  where pe.pe_end_date is null
		  and gp.profile_name IN ('Elizabethtown Outpatient','Keeseville Outpatient','Malone Outpatient','Massena Outpatient','saranac lake outpatient','Ticonderoga Outpatient')
		  and pi.program_name IN ('Outpatient','CCBHC','Intake /  Registration')
  )
--clients who have had an ASC assessment in the last 365 days
, clients_with_ASC as
	(
		select
			el.people_id
		from event_log el
		join event_definition ed
			on el.event_definition_id = ed.event_definition_id
		left join form_view fv
			on fv.form_header_id = el.form_header_id
		where ed.event_name = 'CCBHC ASC Alcohol Use Assessment'
		group by 	
			el.event_log_id
			,el.people_id
			,el.form_header_id
			,ed.event_name
		HAVING DATEDIFF(DAY, GETDATE() , max(el.actual_date)) > -365
	)
--Clients born after 2007-01-01 (18 yrs old on or after 1/1/2024)
, clients_over_18 as
	(
	select people_id, agency_id_no, dob
	from people
	where dob < '2007-01-01'
	)
--clients who are enrolled, do not have an AUD diagnosis, and have not had an ASC assessment in the last 365 days
  select
	enrolled_clients.pe_people_id as people_id
	,'Assessment Needed' as category
	,'Client requires an ASC alcohol assessment every 12 months' as description
	,concat(
  '<a href="https://myevolvsjrcxb.netsmartcloud.com/Form.aspx?caller=Listing&', -- begin creating the hyperlink, using your agency's URL
  'key_value=new', -- key value for form is the event_log_id. Also works for any table key that is a copy of the event_log_id (e.g., test_header_id)
  '&parent_value=', enrolled_clients.pe_people_id, -- parent value for the form is people_id. Modify if another parent value is needed
  '&event_id=13311d51-9177-4210-b3ab-7fdf528f56b9', --hopefully event id for the form we need
  '&form_header_id=bcd0d664-ff7f-477b-91ea-aa45ccfff569', --rtav.form_header_id, -- the form to launch, based on the event definition
  '&mode=ADD&is_add_allowed=false&is_edit_allowed=true&is_delete_allowed=true&is_complete_scheduled_event=false" ', -- ensures the form is editable when launched
  'target="_blank" rel="noopener noreferrer">', --and closes the hyperlink tag
  'Open ASC Assessment Form' -- The text to display in the link, event name and date
  ) as html
	from enrolled_clients
	inner join customer_aud_diag
		on customer_aud_diag.people_id = enrolled_clients.pe_people_id
	inner join clients_over_18
		on clients_over_18.people_id = enrolled_clients.pe_people_id
	left join clients_with_ASC
		on clients_with_ASC.people_id = enrolled_clients.pe_people_id
		where clients_with_ASC.people_id is null
