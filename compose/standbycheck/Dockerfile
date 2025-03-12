FROM registry.access.redhat.com/ubi9/ubi-minimal

EXPOSE 8080

RUN touch /run/nginx.pid

#RUN apk add bash
RUN microdnf -y install nginx-core tar gzip

COPY ./nginx/* /etc/nginx
#RUN chmod -R 777 /run/nginx.pid /var/log/nginx /etc/nginx/conf.d
WORKDIR /opt/app-root/src/
RUN curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux-amd64-rhel9.tar.gz
RUN tar xvzf ./openshift-client-linux-amd64-rhel9.tar.gz

USER root
RUN mv oc /usr/local/bin

ARG DEBUG_BUILD=true

# Add debugging tools into builds if enabled
RUN if [ ${DEBUG_BUILD} = true ]; then \
  microdnf -y install jq vim procps less; \
fi

ADD --chmod=755 ./lbcheck.sh /lbcheck.sh
ADD --chmod=755 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]