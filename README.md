# Projeto de IaC com Azure Bicep

Este projeto demonstra conceitos de Infraestrutura como Código (IaC) usando Azure Bicep com uma abordagem modular. Ele implanta uma arquitetura de aplicação web moderna com:

- Aplicativo frontend Next.js (Node.js)
- Backend .NET 9 WebAPI
- Plano de Serviço de Aplicativo compartilhado para ambas as aplicações
- Application Insights para monitoramento (conectado ao backend)
- Conta de Armazenamento para armazenamento de arquivos
- Banco de Dados PostgreSQL para persistência de dados
- Key Vault para gerenciamento seguro de segredos com geração automática de senhas

## Estrutura do Projeto

```
.azure/
  └── infrastructure/
      ├── main.bicep                    # Arquivo de orquestração principal que importa módulos
      ├── main.parameters.dev.json      # Parâmetros para ambiente de desenvolvimento
      └── modules/                      # Diretório contendo módulos reutilizáveis
          ├── appInsights.bicep         # Módulo de Application Insights
          ├── appServicePlan.bicep      # Módulo de Plano de Serviço de Aplicativo
          ├── keyVault.bicep            # Módulo de Key Vault com geração de senha aleatória
          ├── postgresql.bicep          # Módulo de banco de dados PostgreSQL
          ├── storageAccount.bicep      # Módulo de Conta de Armazenamento
          └── webApp.bicep              # Módulo de Aplicativo Web com suporte para diferentes stacks de runtime
```

## Arquitetura da Aplicação

Este projeto implementa uma arquitetura de aplicação web moderna:

1. **Frontend Next.js**:
   - Runtime: Node.js 18 LTS
   - Conectado à API do backend
   - Servido a partir de um Serviço de Aplicativo Linux
   - Usa identidade gerenciada para acessar segredos do Key Vault

2. **API Backend .NET 9**:
   - Runtime: .NET 9
   - Conectado ao Application Insights para monitoramento
   - Conectado ao banco de dados PostgreSQL para persistência de dados
   - Conectado à Conta de Armazenamento para armazenamento de arquivos
   - Usa identidade gerenciada para conexões seguras
   - Servido a partir de um Serviço de Aplicativo Linux

3. **Infraestrutura Compartilhada**:
   - Plano de Serviço de Aplicativo (Linux)
   - Application Insights
   - Servidor Flexível PostgreSQL
   - Conta de Armazenamento
   - Key Vault

## Entendendo a Estrutura Modular do Bicep

Este projeto segue uma arquitetura modular para melhorar a manutenção e reutilização:

1. **Arquivo de Orquestração Principal**: `main.bicep`
   - Contém definições de parâmetros
   - Referencia e configura os módulos
   - Configura configurações específicas para aplicativos frontend e backend
   - Define saídas da implantação

2. **Módulos Reutilizáveis**: Arquivos no diretório `modules/`
   - Cada módulo se concentra em um tipo específico de recurso Azure
   - Os módulos aceitam parâmetros para personalização
   - Os módulos exportam saídas que podem ser usadas por outros módulos

## Recursos de Segurança

- **Identidade Gerenciada**: Ambos os aplicativos web usam identidade gerenciada atribuída pelo sistema
- **TLS**: Versão mínima TLS 1.2 aplicada
- **Strings de Conexão Seguras**: Adicionadas como configurações de aplicativo
- **Dados Privados**: Acesso público ao blob desativado na conta de armazenamento
- **Key Vault**: Armazenamento seguro de segredos com geração automática de senhas
- **Senha Aleatória**: Senha do administrador PostgreSQL gerada aleatoriamente e armazenada no Key Vault

## Como Implantar

### Pré-requisitos

- [Azure CLI](https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli)
- Assinatura do Azure

### Passos

1. **Faça login no Azure**

   ```bash
   az login
   ```

2. **Selecione a assinatura apropriada**

   ```bash
   az account set --subscription "Seu Nome ou ID de Assinatura"
   ```

3. **Crie um Grupo de Recursos** (se não existir)

   ```bash
   az group create --name MeuGrupoDeRecursos --location eastus
   ```

4. **Atualize os Valores de Parâmetros**

   Edite `.azure/infrastructure/main.parameters.dev.json` e atualize valores conforme necessário:
   - Não é mais necessário definir senha de administrador (gerada automaticamente no Key Vault)
   - Atualize outros parâmetros conforme necessário

5. **Implante o Template Bicep**

   ```bash
   az deployment group create \
     --resource-group MeuGrupoDeRecursos \
     --template-file .azure/infrastructure/main.bicep \
     --parameters .azure/infrastructure/main.parameters.dev.json
   ```

## Gerenciamento de Senhas e Segredos

Este projeto demonstra boas práticas de segurança do Azure:

1. **Geração Automática de Senhas**:
   - Uma senha segura e aleatória é gerada automaticamente durante a implantação
   - A senha é armazenada como um segredo no Key Vault
   - A senha é usada para o administrador do PostgreSQL

2. **Acesso a Segredos**:
   - Aplicativos usam identidades gerenciadas para acessar o Key Vault
   - Não há senhas hardcoded em arquivos de configuração
   - Acesso baseado no princípio de privilégio mínimo

## Recursos de Aprendizado

- [Documentação do Azure Bicep](https://docs.microsoft.com/pt-br/azure/azure-resource-manager/bicep/)
- [Documentação do Serviço de Aplicativo](https://docs.microsoft.com/pt-br/azure/app-service/)
- [Next.js no Serviço de Aplicativo do Azure](https://docs.microsoft.com/pt-br/azure/app-service/quickstart-nodejs)
- [.NET no Serviço de Aplicativo do Azure](https://docs.microsoft.com/pt-br/azure/app-service/quickstart-dotnetcore)
- [Application Insights para .NET](https://docs.microsoft.com/pt-br/azure/azure-monitor/app/asp-net-core)
- [Key Vault do Azure](https://docs.microsoft.com/pt-br/azure/key-vault/)
