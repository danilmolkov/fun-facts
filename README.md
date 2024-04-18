# Fun-facts with Terraform and Yandex Cloud

## Description

This project by me to learn how to work with Terraform. I took Yandex Cloud as cloud provider because I like Yandex :blush:

The Service is a web application which gives random fun facts. It has a server
and redis database. Both instances based on VM.

**Note**: This setup doesn't represent the best effort, optimization or economy.
Every particular way of realization has been chosen by means of my personal desire
to try this exact way.

## YC setup

For the additional info how to install yc see [YC setup][YC setup].

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
- [x] Creating and starting redis via "null_resource".
- [x] Initiating DB provided deployment is wokring,
- [ ] Create a separate disk to store data.
- [ ] Creating and starting server and redis via "ansible".
- [ ] Add second server replica and load-balancer.
- [ ] Create server package to remove properly start execution

[YC setup]: https://cloud.yandex.com/en/docs/tutorials/infrastructure-management/terraform-quickstart
