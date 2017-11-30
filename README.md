# azure-provisioning
Provisionando o GitLab e um cluster AKS com Terraform

## Instalação
### Azure CLI
#### Windows
```shell
C:\> choco install azure-cli
```

#### Mac
```shell
$ brew install azure-cli
```

### Terraform
#### Mac 
```shell
$ brew install terraform
```

#### Windows 
```shell
C:\> choco install terraform
```

## Provisionamento
### Configurar as credenciais
```shell
az login

az account set --subscription="${SUBSCRIPTION_ID}"

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
```

Após criar a entidade de serviço do Azure AD ajuste os valores no arquivo de variáveis (*.tfvars).

Mais detalhes [aqui](https://docs.microsoft.com/pt-br/azure/virtual-machines/linux/terraform-install-configure).

### Inicializar o ambiente
```shell
cd terraform
terraform init
terraform apply -var-file=production.tfvars
```

### Configurando o GitLab CI
```shell
gitlab-runner register -n \
  --url http://gitlab-srv/ \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --docker-image "docker:latest" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```

Mais detalhes [aqui](https://docs.gitlab.com/runner/).