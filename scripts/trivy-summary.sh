#!/bin/bash
TRIVY_JSON="$1"
IMAGE_TAG="$2"

sudo apt-get update && sudo apt-get install -y jq

if [ ! -s "$TRIVY_JSON" ]; then
  echo "Arquivo json de ouput do Trivy não encontrado ou está vazio. As contagens serão zero."
  CRITICAL_COUNT=0
  HIGH_COUNT=0
  MEDIUM_COUNT=0
  LOW_COUNT=0
  UNKNOWN_COUNT=0
  TOTAL_COUNT=0
else
  IMAGE_TAG="$IMAGE_TAG"

  CRITICAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$TRIVY_JSON")
  HIGH_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$TRIVY_JSON")
  MEDIUM_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$TRIVY_JSON")
  LOW_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$TRIVY_JSON")
  UNKNOWN_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "UNKNOWN")] | length' "$TRIVY_JSON")
  TOTAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$TRIVY_JSON")
fi

echo "DEBUG: IMAGE_DOCKER=$IMAGE_TAG"
echo "DEBUG: CRITICAL_COUNT=$CRITICAL_COUNT"
echo "DEBUG: HIGH_COUNT=$HIGH_COUNT"
echo "DEBUG: MEDIUM_COUNT=$MEDIUM_COUNT"
echo "DEBUG: LOW_COUNT=$LOW_COUNT"
echo "DEBUG: UNKNOWN_COUNT=$UNKNOWN_COUNT"
echo "DEBUG: TOTAL_COUNT=$TOTAL_COUNT"

echo "critical_count=$CRITICAL_COUNT" >> $GITHUB_OUTPUT
echo "high_count=$HIGH_COUNT" >> $GITHUB_OUTPUT
echo "medium_count=$MEDIUM_COUNT" >> $GITHUB_OUTPUT
echo "low_count=$LOW_COUNT" >> $GITHUB_OUTPUT
echo "unknown_count=$UNKNOWN_COUNT" >> $GITHUB_OUTPUT
echo "total_count=$TOTAL_COUNT" >> $GITHUB_OUTPUT

{
  echo "### Sumário de Vulnerabilidades da Imagem"
  echo ""
  echo "Scan para: \`${IMAGE_TAG}\`"
  echo ""
  echo "| Categoria | Contagem |"
  echo "|---|---|"
  echo "| **Críticas** | **$CRITICAL_COUNT** |"
  echo "| Altas | $HIGH_COUNT |"
  echo "| Médias | $MEDIUM_COUNT |"
  echo "| Baixas | $LOW_COUNT |"
  echo "| Desconhecidas | $UNKNOWN_COUNT |"
  echo "| **Total** | **$TOTAL_COUNT** |"
  echo ""
  echo "---"
  echo "### Detalhes das Vulnerabilidades"
  echo ""
  
  if [ -s "$TRIVY_JSON" ]; then
    jq -c '.Results[]?.Vulnerabilities[]? | select(.VulnerabilityID != null)' "$TRIVY_JSON" | while read -r vuln; do
      VULN_ID=$(echo "$vuln" | jq -r '.VulnerabilityID')
      SEVERITY=$(echo "$vuln" | jq -r '.Severity')
      PKG_NAME=$(echo "$vuln" | jq -r '.PkgName')
      INSTALLED_VER=$(echo "$vuln" | jq -r '.InstalledVersion')
      FIXED_VER=$(echo "$vuln" | jq -r '.FixedVersion // "N/A"') # Use N/A se não houver FixedVersion
      STATUS=$(echo "$vuln" | jq -r '.Status // "N/A"') # Status da correção
      TITLE=$(echo "$vuln" | jq -r '.Title // "N/A"')
      DESCRIPTION=$(echo "$vuln" | jq -r '.Description // "N/A" | .[:200] + (if (. | length) > 200 then "..." else "" end)') # Limita a descrição a 200 caracteres

      echo "#### $VULN_ID"
      echo "- **Severidade:** $SEVERITY"
      echo "- **Pacote Afetado:** \`$PKG_NAME\` (\`$INSTALLED_VER\`)"
      echo "- **Versão de Correção:** \`$FIXED_VER\`"
      echo "- **Status da Correção:** \`$STATUS\`"
      echo "- **Título:** $TITLE"
      echo "- **Descrição:** $DESCRIPTION"
      echo ""
    done
  else
    echo "Nenhuma vulnerabilidade detalhada para exibir ("$TRIVY_JSON" estava vazio ou não encontrado)."
  fi
  echo "---"
  echo "Para ver o relatório completo e mais detalhes, verifique os logs deste passo."
} >> "$GITHUB_STEP_SUMMARY"

echo "Sumário de vulnerabilidades adicionado ao GITHUB_STEP_SUMMARY."