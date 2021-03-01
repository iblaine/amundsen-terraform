# Terrafrom Amundsen Deployment

This stack deploys [Amundsen](https://www.amundsen.io/) solution and consist of tree Terraform modules:

* [VPC](./vpc) - baseline infrastructure stack
* [Elasticsearch](./elasticsearch) - single instance (dev) of AWS Elasticsearch deployment
* [ECS](./ecs) - ECS Fargate cluster deployment which deploys tree Amundsen services:
  * Search
  * Metadata
  * Frontend
  * Neo4j

All Amundsen componenets are deployed using docker-compose files form official Amundsen [GitHub repository](https://github.com/amundsen-io/amundsen).

## Deployment

Terrafrom stacks need to be deployed in the following order:

* VPC
* Elasticsearch
* ECS

### Prerequisites

Create a versioned S3 bucket in your AWS account.

Modify `provider.tf` file and replace S3 bucket in Terraform backend configuration with the one you just created. This will allow Terraform to store stacks deployment state in remote S3 bucket in your account.

### VPC

To deploy a baseline VPC use the following commands:

```sh
cd vpc
terraform init
terraform apply
```

### Elasticsearch

```sh
cd elasticsearch
terraform init
terraform apply
```

### ECS

ECS stack consists of the following services:

* Search
* Metadata
* Frontend
* Neo4j

Search, Metadata and Frontend are independent containers which are configured automatically.

Neo4j database configuration defaults to the following folder structure which needs to be created at EFS filesystem:

* `/neo4j/data`
* `/backup`
* `/conf`

To create this folder structure, create an Amazon Linux 2 EC2 instances, set the Network to amundsen-prod-vpc, set subnet to amundsen-prod-vpc-public-subnet-001.  After launch, edit security group, add amundsen-prod-sg-amundsen.

SSH to the instance host and mount EFS share.  The efs file_system_id is taken from your efs_file_system_id.  You can find that by going to [Amazon EFS](https://console.aws.amazon.com/efs/home?region=us-east-1#/file-systems) then replacing that id with the one below:

```sh
sudo su -
yum install -y amazon-efs-utils
mkdir efs
mount -t efs fs-12345678:/ efs
mkdir -p efs/conf
mkdir -p efs/backup
mkdir -p efs/neo4j/data
```

Place [neo4j.conf](https://github.com/amundsen-io/amundsen/blob/master/example/docker/neo4j/conf/neo4j.conf) file to `efs/conf/neo4j.conf`.

Change ownership for all created folders and files to `UID=1000` and `GUID=1000`:

```sh
chown -R 1000:1000 efs/*
```

Now you can deploy ECS cluster:

```sh
cd ecs
terraform init
terraform apply
```

## Test data upload

From the same EC2 instance clone Amundsen repository:

```sh
yum install git
git clone --recursive https://github.com/amundsen-io/amundsen
cd amundsen/amundsendatabuilder/
```

Deploy required Python libs:

```sh
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip
pip3 install -r requirements.txt
python3 setup.py install
```

Now, you need to patch `example/scripts/sample_data_loader.py` file. Modify Elasticsearch client:

```py
es = Elasticsearch([
    {'host': es_host, 'port': 443, 'scheme': 'https'},
])
```

```

Now, you can upload test data, update your ES endpoint in the command, which you can find [here](https://console.aws.amazon.com/es/home?region=us-east-1#domain:resource=amundsen-prod-es;action=dashboard;tab=undefined):

```sh
python example/scripts/sample_data_loader.py vpc-amundsen-prod-es-addshp7cgl2jt66zg5flg33zge.us-east-1.es.amazonaws.com neo4j.prod.amundsen.local
```

Now you can connect to Frontend service using ALB and [play with the data](https://www.amundsen.io/amundsen/installation/).
