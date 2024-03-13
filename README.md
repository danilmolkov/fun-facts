# Fun-facts with Terraform and Yandex Cloud

## Description

This project by me to learn how to work with Terraform. I took Yandex Cloud as cloud provider because I like Yandex :blush:

The Service is a web application which gives random fun facts. It has a server
and redis database. Both instances based on VM.

## YC setup

```bash
yc init
yc iam key create --service-account-id=<service-account-id> --folder-name=<folder-id> --output key.json
yc config profile create fun-facts
yc config set service-account-key key.json
yc config set cloud-id '<cloud-id>'
yc config set folder-id '<folder-id>'

export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

## Roadmap

- [x] First commit, setup is working locally, basic tf file is created.
- [x] Creating and starting server via "null_resource".
- [ ] Creating and starting redis via "null_resource".
- [ ] Creating and starting server and redis via "ansible".
- [ ] Add second server replica and load-balancer.
- [ ] Create server package to remove properly start execution
