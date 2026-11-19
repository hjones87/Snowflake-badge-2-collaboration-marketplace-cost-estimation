---- LESSON 4: SAHRING DATA WITH OTHER ACCOUNTS -----

--enables global sharing privileges to the World Data Emporium account - required to by pass the 'Cannot set replication schedule for listing 'INTERNATIONAL_CURRENCIES': account not set up for auto-fulfillment' error when attempting to assign the refresh schedule to on demand only on the listing 

USE ROLE ORGADMIN;
SELECT SYSTEM$IS_GLOBAL_DATA_SHARING_ENABLED_FOR_ACCOUNT('TRB44511');

CALL SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('TRB44511');

--2) convert regular views to secure views and add to outbound share

ALTER VIEW intl_db.public.NATIONS_SAMPLE_PLUS_ISO
SET SECURE;

ALTER VIEW intl_db.public.SIMPLE_CURRENCY
SET SECURE;