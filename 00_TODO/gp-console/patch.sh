#!/bin/bash
BASEDIR=$(dirname "$0")
OC_CONSOLE_HOSTNAME="${CUSTOM_CONSOLE_URL-play.gepaplexx.com}"

# logo
oc create configmap -n openshift-config console-custom-logo --from-file=${BASEDIR}/console-custom-logo.png || true

# certificate
MANAGED_SECRET=$(oc get certificate console-tls -n openshift-config --ignore-not-found)
if [[ $MANAGED_SECRET ]]; then
    # TODO: wait for certificate?
    echo "certificate is managed by cert-manager"
else
    echo "No cert manager detected - generating self signed cert"
    openssl req -x509 -nodes -newkey rsa:4096 -keyout ${BASEDIR}/privkey.pem -out ${BASEDIR}/cert.pem -days 365 -subj "/C=AT/ST=Austria/O=gepaplexx/CN=${OC_CONSOLE_HOSTNAME}"
    oc create secret tls console-tls --key=${BASEDIR}/privkey.pem --cert=${BASEDIR}/cert.pem -n openshift-config || true
fi

oc patch consoles.operator.openshift.io cluster \
    --patch "{\"spec\":{\"route\":{\"hostname\":\"${OC_CONSOLE_HOSTNAME}\", \"secret\":{\"name\":\"console-tls\"}}, \"customization\":{\"customProductName\": \"gepaPLEXX\", \"customLogoFile\": {\"key\": \"console-custom-logo.png\", \"name\": \"console-custom-logo\"}}}}" --type=merge 

exit 0