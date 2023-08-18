



View values of the password:
`kubectl get secret my-external-secrets-values -o jsonpath='{.data.password}' | base64 --decode`{{execute}}