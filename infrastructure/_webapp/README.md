# WebApp Chart

A chart to provision the RIDE WebApp

## Configuration

### Django Options

| Parameter             | Description                         | Default                                |
| --------------------- | ----------------------------------- | -------------------------------------- |
| `fullnameOverride`    | Instance Name if other than default | `django`                               |
| `nameOverride`        | Instance Name if other than default | `django`                               |
| `replicaCount`        | Number of replicas to run           | `1`                                    |
| `repository`          | Image source                        | `ghcr.io/bcgov/ride-webapp`            |
| `tag`                 | Image tag                           | `latest`                               |
| `CPU Request`         | CPU request amount                  | `100m`                                 |
| `Memory Request`      | Memory request amount               | `256Mi`                                |
| `postgresSecret`      | The pguser secret name              | `ride-pguser`                          |
| `djangoConfigMap`     | The name of the Django Config Map   | `ride-django-config`                   |
| `djangoSecret`        | The name of the Django Secret       | `ride-django-secret`                   |
| `routeHost`           | Hostname for the route              | `ride.apps.silver.devops.gov.bc.ca`    |
| `ipRestricted`        | Should it be IP restricted?         | `false`                                |
| `ipAllowList`         | List of IPs allowed to connect      |                                        |
| `podDisruptionBudget` | Pod disruption budget               |                                        |
| `enabled`             | Enable if more than one replica     | `false`                                |
| `minAvailable`        | Minimum number of pods available    | `1`                                    |

Notes:
- This will create the ConfigMap and Secret the first time it runs and will not delete them after.

## Components

### OpenShift
- Deployment
- Service
- Route
- Network Policy
- Pod Distruption Budget
- Configmap (intial)
- Secret (initial)