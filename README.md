# Client certificate authentication

Trying to get client certificate authentication working using ASP.NET Core application running Alpine based Docker container and nginx as reverse proxy.

>What the client really wants is mTLS and Bearer-token (JWT), but the current infrastructure setup doesn't allow for it.
>Request path is Internet -> IIS (terminates and forwards cert) -> nginx (forwards cert) -> app

Steps performed:
1. Configure `AddCertificate` to allow for self-signed certificates and no recovation
1. `UseCertificateForwarding`
1. Create self-signed root and client certificate

Running Windows 10, version 1809 (build 17763.1039)

## Kestrel

Works after configured client certificate on Kestrel and installed root and client certificate in Windows under Root and My respectively.

>Is it possible to control which root the client certificate must be signed by in Kestrel?

## Docker

Error _PartialChain unable to get local issuer certificate_ can be seen in logs and `ClientCertificateValidation`. Adding the root to Docker:
```
ADD cca_root_ca.cer /usr/local/share/ca-certificates/cca_root_ca.crt
RUN update-ca-certificates
```
The certificate has property `Copy Always` so it'll be publshed along with binaries.

## nginx

Just says the the authorization for scheme Certificate failed. Can't see any other in the logs.
