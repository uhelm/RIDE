### Setting up Github

The dev, test, uat, prod workflows need to have environment variables setup in OpenShift

Add these variables like this:
1. In Github go to Settings
1. Click Environments
1. Click New Environment
1. Give it a name (dev, test, uat, prod)
1. Add these Environment and Secret Variables
    1. Variable: `OPENSHIFT_NAMESPACE`
        - Use the project namespace with the `-dev` (ie `abc123-dev`)
    1. Variable: `OPENSHIFT_GOLD_SERVER`
        - This will be the API Server you see when you get your token from OpenShift
    1. Secret: `OPENSHIFT_GOLD_TOKEN`
        - Use the Pipeline Token (From `pipeline-token-xxxxxxxx` secret)
    1. If Applicable:
        1. Variable: `OPENSHIFT_GOLDDR_SERVER`
            - This will be the API Server you see when you get your token from OpenShift
        1. Secret: `OPENSHIFT_GOLDDR_TOKEN`
            - Use the Pipeline Token (From `pipeline-token-xxxxxxxx` secret)


These workflows are designed to push to both OpenShift Gold and GoldDR at the same time. 