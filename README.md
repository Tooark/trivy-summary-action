# Action Github para resumo trivy-summary-action

Action feita para criar um summary do Scan de imagens Docker - Trivy(aquasecurity/trivy-action@0.28.0)

## Inputs

- Nome do arquivo JSON da action Trivy
- Imagem Docker a ser utilizada

## How to use:

```yaml
name: Example Trivy Summary

on:
  push:
    branches:
      - main

jobs:
  test:
      runs-on: ubuntu-latest
      steps:
        - name: Checkout code
          uses: actions/checkout@v4

        - name: build dockerfile
          run: |
            docker build -t myapp:latest .

        - name: Run Trivy vulnerability scanner and save report
          uses: aquasecurity/trivy-action@0.28.0
          with:
            image-ref: 'myapp:latest'
            format: 'json'
            exit-code: '0'
            ignore-unfixed: true
            vuln-type: 'os,library'
            severity: 'CRITICAL,HIGH,MEDIUM,LOW'
            output: 'trivy-results.json'
        
        - name: Trivy Summary e Notificação Teams
          uses: Tooark/trivy-summary-action@v1
          id: trivy-summary-generator
          with:
            trivy-json: trivy-results.json
            docker-image: myapp:latest
```
