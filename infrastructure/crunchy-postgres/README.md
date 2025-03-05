# CrunchyDB Postgres

This chart was based on https://github.com/bcgov/quickstart-openshift/tree/main/charts/crunchy with a number of changes



helm template dev-ride-db -f .\crunchy-postgres\values.yaml .\crunchy-postgres --output-dir .\yaml-crunchy
helm install dev-ride-db -f .\crunchy-postgres\values.yaml .\crunchy-postgres


ALTER DATABASE "dev-ride-db" OWNER TO "dev-ride-db";


## First Setup
1. Login to `oc` in Powershell
1. Set all the values including `bucket`, `accessKey`, `secretKey`, `password` (if required)
1. Confirm you are in the correct namespace by entering `oc project`
1. Run `cd C:\Data\RIDE\infrastructure`
1. Run `helm install dev-ride-db -f .\crunchy-postgres\values.yaml .\crunchy-postgres`
1. Confirm everything has installed as expected
1. Run these commands to set DB owner in the primary pod, `psql` then `ALTER DATABASE "dev-ride-db" OWNER TO "dev-ride-db";`


If you are setting up the Gold DR cluster as well then you will need to:

NOTE: Once you set the `accessKey`, `secretKey`, `password` the first time the secrets that have those values for access and secret key will not be updated again to make it simpler to do deployments, otherwise you must add `--set` each time you want to make a change. This also means that if you ever need to update those values you must make them in OpenShift manually, but that should be very unlikely.

For `password` if you need to update it, just add a new value and it should work.


## Changes
If you are upgrading the crunchy instance with new values follow these steps
1. Login to `oc` in Powershell
1. Set all the values you want to change. Ensure you change it in both the Gold and GoldDR files for that environment
    - NOTE: You *do not need* to set `accessKey`, `secretKey`, `password`. If they are blank (which they should be if saved to Github), then leaving them blank will just keep the last value in OpenShift
1. Run `helm upgrade dev-ride-db -f .\crunchy-postgres\values-dev-gold.yaml .\crunchy-postgres --set crunchy.pgBackRest.s3.bucket=tran_api_dbc_backup_dev`
1. Confirm the changes worked as expected.