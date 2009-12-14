-- Run ./manage.py syncdb to setup django_lobbyist DB
-- Setup lobbyist DB from http://data.sunlightlabs.com/sunlightapi/api_lobbyists.sql.gz
use django_lobbyist;

-- Setup mainsite_client (69160 unique clients from 418898 rows in lobbyist.filing, but there are 5249 unique client_senate_id
-- This table has an autoincrement id column
insert into mainsite_client (
    client_senate_id,
    client_name,
    client_country,
    client_state,
    client_ppb_country,
    client_ppb_state,
    client_description,
    client_contact_firstname,
    client_contact_middlename,
    client_contact_lastname,
    client_contact_suffix,
    client_raw_contact_name 
) select 
    client_senate_id,
    client_name,
    client_country,
    client_state,
    client_ppb_country,
    client_ppb_state,
    client_description,
    client_contact_firstname,
    client_contact_middlename,
    client_contact_lastname,
    client_contact_suffix,
    client_raw_contact_name 
from 
    lobbyist.lobbyists_filing
where
    client_senate_id is not NULL
group by 
    client_senate_id,
    client_name,
    client_country,
    client_state,
    client_ppb_country,
    client_ppb_state,
    client_description,
    client_contact_firstname,
    client_contact_middlename,
    client_contact_lastname,
    client_contact_suffix,
    client_raw_contact_name ;

-- Use this query to see the variation in "clients"
 -- select 
 --    client_senate_id,
 --    count(client_senate_id),
 --    count(distinct(client_name)),
 --    count(distinct(client_country)),
 --    count(distinct(client_state)),
 --    count(distinct(client_ppb_country)),
 --    count(distinct(client_ppb_state)),
 --    count(distinct(client_description)),
 --    count(distinct(client_contact_firstname)),
 --    count(distinct(client_contact_middlename)),
 --    count(distinct(client_contact_lastname)),
 --    count(distinct(client_contact_suffix)),
 --    count(distinct(client_raw_contact_name))
 -- from 
 --    lobbyist.lobbyists_filing
 --    group by client_senate_id
 
-- Setup registrants
-- This table has an autoincrement id column
insert into mainsite_registrant (
    registrant_senate_id,
    registrant_name,
    registrant_description,
    registrant_address,
    registrant_country,
    registrant_ppb_country
)
select
    registrant_senate_id,
    registrant_name,
    registrant_description,
    registrant_address,
    registrant_country,
    registrant_ppb_country
from 
    lobbyist.lobbyists_filing
where
    registrant_senate_id is not null
group by
    registrant_senate_id,
    registrant_name,
    registrant_description,
    registrant_address,
    registrant_country,
    registrant_ppb_country;

-- Setup the filings,
-- Join to clients and registrants, unfortunately by having to join on all their columns
-- since both of them have non-distinct values in all their columns
insert into mainsite_filing (
    filing_id,
    filing_period,
    filing_date,
    filing_amount,
    filing_year,
    filing_type,
    client_id,
    registrant_id
)
select
    filing_id,
    filing_period,
    filing_date,
    filing_amount,
    filing_year,
    filing_type,
    mainsite_client.id,
    mainsite_registrant.id
from lobbyist.lobbyists_filing
join mainsite_client
on
    lobbyist.lobbyists_filing.client_senate_id          = mainsite_client.client_senate_id              AND
    lobbyist.lobbyists_filing.client_name               = mainsite_client.client_name                   AND
    lobbyist.lobbyists_filing.client_country            = mainsite_client.client_country                AND
    lobbyist.lobbyists_filing.client_state              = mainsite_client.client_state                  AND
    lobbyist.lobbyists_filing.client_ppb_country        = mainsite_client.client_ppb_country            AND
    lobbyist.lobbyists_filing.client_ppb_state          = mainsite_client.client_ppb_state              AND
--    lobbyist.lobbyists_filing.client_description        = mainsite_client.client_description            AND
    lobbyist.lobbyists_filing.client_contact_firstname  = mainsite_client.client_contact_firstname      AND
    lobbyist.lobbyists_filing.client_contact_middlename = mainsite_client.client_contact_middlename     AND
    lobbyist.lobbyists_filing.client_contact_lastname   = mainsite_client.client_contact_lastname      -- AND
--    lobbyist.lobbyists_filing.client_contact_suffix     = mainsite_client.client_contact_suffix         AND
--    lobbyist.lobbyists_filing.client_raw_contact_name   = mainsite_client.client_raw_contact_name
join mainsite_registrant
on
    lobbyist.lobbyists_filing.registrant_senate_id      = mainsite_registrant.registrant_senate_id      AND
    lobbyist.lobbyists_filing.registrant_name           = mainsite_registrant.registrant_name           AND
--    lobbyist.lobbyists_filing.registrant_description    = mainsite_registrant.registrant_description    AND
    lobbyist.lobbyists_filing.registrant_address        = mainsite_registrant.registrant_address        AND
    lobbyist.lobbyists_filing.registrant_country        = mainsite_registrant.registrant_country        AND
    lobbyist.lobbyists_filing.registrant_ppb_country    = mainsite_registrant.registrant_ppb_country
;

-- Setup the issues
insert into mainsite_issue (
    issue_id,
    code,
    specific_issue
)
select
    id,
    code,
    specific_issue
from lobbyist.lobbyists_issue;

-- Setup the lobbyists
insert into mainsite_lobbyist (
    lobbyist_id,
    firstname,
    middlename,
    lastname,
    suffix,
    official_position,
    raw_name
)
select
    id,
    firstname,
    middlename,
    lastname,
    suffix,
    official_position,
    raw_name
from lobbyist.lobbyists_lobbyist;

-- Setup many to many join table between filings and issues
insert into mainsite_filing_issues(
    filing_id,
    issue_id
)
select
    lobbyist.lobbyists_issue.filing_id,
    lobbyist.lobbyists_issue.id
from lobbyist.lobbyists_issue;

-- Setup many to many join table between lobbyists and filings
insert into mainsite_lobbyist_filings(
    lobbyist_id,
    filing_id
)
select
    lobbyist.lobbyists_lobbyist.id,
    lobbyist.lobbyists_lobbyist.filing_id    
from lobbyist.lobbyists_lobbyist;