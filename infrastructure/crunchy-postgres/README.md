# CrunchyDB Postgres

This chart was based on https://github.com/bcgov/quickstart-openshift/tree/main/charts/crunchy with a number of changes to help support Active-Standby failover scenarios.

Features include
- Backup to PVC and S3
- Ability to setup a Standby Cluster
- Already includes the yaml to easily do a manual backup
- Ability to set a custom password for the default user which is important if you have two clusters with an application reading the standby cluster in read-only mode
- Exporter and Prometheus setup so you can view database stats and setup alerts in Sysdig
- Separate PVC for WAL logs to reduce risk of disk space exhaustion on the main PVC which can lead to data corruption

## Initial Install
The initial setup needs to be done from your local machine. Subsequent updates can be done either via Github actions (based on latest code in Github) or manually.

Assumptions:
- Using Powershell
- Admin access to the OpenShift cluster
- Your folder structure is `C:\Data\DriveBC.ca` and you have the latest version of repo copied to that location (You can use a different location if you like)

1. Login to `oc` 
1. Set all the values including `bucket`, `endpoint`, `accessKey`, `secretKey`, `password` (if required)
1. Confirm you are in the correct namespace and cluster by entering `oc project`
1. Run `cd C:\Data\RIDE\infrastructure`
1. Confirm the values file has all values set inclu
1. Run `helm install ENV-ride-db -f .\crunchy-postgres\values-ENV-gold.yaml .\crunchy-postgres`
1. Confirm everything has installed as expected
1. Run these commands to set DB owner in the primary pod, `psql` then `ALTER DATABASE "ENV-ride-db" OWNER TO "ENV-ride-db";`

If you are setting up Crunchy in Active-Standby configuration you will also need to do these steps:
1. Copy the values file you used for gold
1. Ensure `crunchy.standby.enabled=true` and save
1. Trigger a manual backup on the cluster in Gold using this command `oc annotate -n NAMESPACE postgrescluster ENV-ride-db --overwrite postgres-operator.crunchydata.com/pgbackrest-backup="$(date)"` and wait for the backup to complete
1. Login to the GoldDR cluster using `oc`
1. Run `helm install ENV-ride-db -f .\crunchy-postgres\values-ENV-golddr.yaml .\crunchy-postgres`
1. Check that it's running as a standby.

Due to how the clusters are setup, you will need to update the password for `ccp_monitoring` for the Standby cluster based on this documentation: https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/backups-disaster-recovery/disaster-recovery#monitoring-a-standby-cluster
Here are the steps: https://access.crunchydata.com/documentation/postgres-operator/latest/guides/exporter-configuration#setting-a-custom-ccp_monitoring-password
Essentially:
1. Go to the Primary Cluster
1. Go to secrets and get the password from CLUSTER-monitoring
1. Run `oc edit secret CLUSTER-monitoring` on the Standby Cluster
1. Remove the current data section and add:
```
stringData:
  password: <PASSWORD FROM PRIMARY CLUSTER>
```


## Changes after initial install
Changes can be made easily once the Crunchy Cluster is already installed. Simply run the following commands on the appropriate OpenShift Cluster
- `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-gold.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT>`
- `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-golddr.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT>`

One challenge you may run into is that the Github repo doesn't contain the S3 information or custom password for the default user. Few things to note
- If `crunchy.user.password` is blank, then it won't update it.
- Once `crunchy.pgbackrest.s3.accessKey` and `crunchy.pgbackrest.s3.secretKey` are set in OpenShift it's setup to not change them so they can be blank
- **IMPORTANT** You **must** ensure that `crunchy.pgbackRest.s3.bucket` and `crunchy.pgbackrest.s3.endpoint` have values, otherwise it will break the s3 backups!


# Failovers
At a high level this is how the failover works:
1. Have an active-standby configuration setup
1. Shutdown Cluster A and set `standby: false` on Cluster B
    - If you can't access Cluster A, that is ok, but note these scenarios
        1. If Cluster A tries to startup again after an Openshift issue, the DB pods will not start anymore
        1. If Cluster A lost network connectivity so the pods stayed running, it will look like you can still read/write to the DB, however these changes are **not** being saved and will be list.
To switch back:
1. Delete Cluster A
1. Rebuild Cluster A as a Standby
1. Shutdown Cluster B gracefully
1. Set Cluster A `standby: false`
1. Rebuild Cluster B as a Standby

How this looks with the helm charts is this:
1. Shutdown Cluster A:
    - `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-gold.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.shutdown=true`
1. Set Cluster B as primary:
    - `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-golddr.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.standby.enabled=false`

To revert:
1. Delete Cluster A
    - `helm uninstall ENV-ride-db`
1. Rebuild Cluster A
    - `helm install ENV-ride-db -f .\crunchy-postgres\values-ENV-gold.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.pgbackrest.s3.accessKey=<ACCESS KEY> --set crunchy.pgbackrest.s3.secretKey=<SECRET KEY> --set crunchy.user.password=<PASSWORD> --set crunchy.standby.enabled=true`
1. Wait till it indicates it's up
1. Shutdown Cluster B
    - `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-golddr.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.shutdown=true`
1. Set Cluster A as primary
    - `helm upgrade ENV-ride-db -f .\crunchy-postgres\values-ENV-gold.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.standby.enabled=false`
1. Delete Cluster B
    - `helm uninstall ENV-ride-db`
1. Rebuild Cluster B
    - `helm install ENV-ride-db -f .\crunchy-postgres\values-ENV-golddr.yaml .\crunchy-postgres --set crunchy.pgbackRest.s3.bucket=<BUCKET> --set crunchy.pgbackrest.s3.endpoint=<ENDPOINT> --set crunchy.pgbackrest.s3.accessKey=<ACCESS KEY> --set crunchy.pgbackrest.s3.secretKey=<SECRET KEY> --set crunchy.user.password=<PASSWORD> --set crunchy.standby.enabled=true`

You may also need to do these steps to sync up the ccp_monitoring password:
1. Go to the Primary Cluster
1. Go to secrets and get the password from CLUSTER-monitoring
1. Run `oc edit secret CLUSTER-monitoring` on the Standby Cluster
1. Remove the current data section and add:
```
stringData:
  password: <PASSWORD FROM PRIMARY CLUSTER>
```


# Monitoring
Since Prometheus and the Exporter are setup you can monitor and get alerting through Sysdig. Sysdig has a number of built in dashboards and alerts you can use.
This configuration should have both Clusters show up.

