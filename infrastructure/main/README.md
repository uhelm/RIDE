# Helm Charts for RIDE


To install:
First lint
helm lint

For initial install

1. Login to the cluster
1. Ensure you are on the right namespace
1. `helm dependency update .\main`
1. `helm install dev-ride -f .\main\values-dev.yaml .\main`


These helm charts were structured in a way that allows for future expansion if adding other components such as nginx, redis, etc.
You would just create another _component folder under infrastructure and update Chart.yaml with the new dependency.