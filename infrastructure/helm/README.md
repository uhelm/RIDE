# WebApp Chart

A chart to provision the RIDE WebApp.

## Configuration

### Django Options

| Parameter             | Description                         | Default                                |
| --------------------- | ----------------------------------- | -------------------------------------- |
| `fullnameOverride`     | Instance Name if other than default | `webapp`                               |
| `nameOverride`         | Instance Name if other than default | `webapp`                               |
| `replicaCount`         | Number of replicas to run           | `1`                                    |
| `repository`           | Image source                        | `ghcr.io/bcgov/ride-webapp`            |
| `tag`                  | Image tag                           | `latest`                               |
| `CPU Request`          | CPU request amount                  | `50m`                                  |
| `Memory Request`       | Memory request amount               | `250Mi`                                |
| `postgresSecret`       | The pguser secret name              | `ride-db-pguser-ride-db`               |
| `routeHost`            | Hostname for the route              | `ride.apps.gold.devops.gov.bc.ca`     |
| `ipRestricted`         | Should it be IP restricted?         | `false`                                |
| `ipAllowList`          | List of IPs allowed to connect      | `142.34.53.0/24 142.22.0.0/15 142.24.0.0/13 142.32.0.0/13 208.181.128.46/32` |
| `podDisruptionBudget`  | Pod disruption budget               | Not set                                |
| `enabled`              | Enable if more than one replica     | `false`                                |
| `minAvailable`         | Minimum number of pods available    | `1`                                    |

### Prometheus

| Parameter             | Description                         | Default        |
| --------------------- | ----------------------------------- | -------------- |
| `enabled`             | Enable Prometheus monitoring        | `false`        |

### Vault

| Parameter             | Description                         | Default        |
| --------------------- | ----------------------------------- | -------------- |
| `licenceplate`        | Licence plate identifier            | `f4dbc3`       |
| `environment`         | Environment (nonprod or prod)       | `nonprod`      |
| `authPath`            | Vault authentication path          | `auth/k8s-gold` |
| `secretName`          | Vault secret name                   | `webapp-secret` |

## Components

### OpenShift

- **Deployment**: Deployment resource that ensures the webapp is running with the desired replica count and resource requests/limits.
- **Service**: Exposes the webapp internally within the cluster.
- **Route**: Exposes the webapp externally with an optional IP restriction list.
- **Network Policy**: Configures network policies for securing communication between services.
- **Pod Disruption Budget**: Ensures availability by controlling voluntary disruptions to pods.
