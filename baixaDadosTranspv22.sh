#!/bin/bash
# estive aqui Andre 
# Verifica se o número correto de parâmetros foi passado
if [ "$#" -ne 4 ]; then
    echo "Uso: ./baixaDadosTransp.sh diaIni diaFim mes ano"
    exit 1
fi

# Parâmetros
diaIni=$1
diaFim=$2
mes=$3
ano=$4

# URL base
base_url="https://portaldatransparencia.gov.br/download-de-dados/despesas/"

# Diretórios que serão utilizados para baixar os dados
infra_dir=~/infra/tmpDir # preferir colocar dentro de um diretório
mkdir -p $infra_dir

# Configuração de localidade
export LC_ALL=pt_BR.UTF-8

# Loop para baixar os arquivos
for (( dia=$diaIni; dia<=$diaFim; dia++ ))
do
  dia_formatado=$(printf "%02d" $dia)
  arquivo="${ano}${mes}${dia_formatado}"
  url="${base_url}${arquivo}"
  zip_file="${infra_dir}/${arquivo}_Despesas.zip"

  wget $url -O $zip_file
  if [ $? -eq 0 ]; then
    echo "Arquivo ${arquivo} baixado com sucesso e armazenado em ${zip_file}."
  else
    echo "Falha ao baixar o arquivo ${arquivo}."
    rm -f $zip_file
  fi
done

# Extrai os arquivos necessários
tempDir=$(mktemp -d)
for (( dia=$diaIni; dia<=$diaFim; dia++ ))
do
  dia_formatado=$(printf "%02d" $dia)
  zipFile="${infra_dir}/${ano}${mes}${dia_formatado}_Despesas.zip"
  if [ -f "$zipFile" ]; then
    unzip -j "$zipFile" "${ano}${mes}${dia_formatado}_Despesas_Empenho.csv" -d "$tempDir"
    unzip -j "$zipFile" "${ano}${mes}${dia_formatado}_Despesas_Pagamento.csv" -d "$tempDir"
  else
    echo "Arquivo $zipFile não encontrado."
  fi
done

set -x  # Ativa a depuração

# Função para remover cabeçalhos duplicados
remove_duplicate_headers() {
  input_file=$1
  output_file=$2
  awk 'NR==1 || !/^header/' $input_file > $output_file
}

# Processa os arquivos de empenho
output_empenho="${ano}${mes}${diaIni}-${diaFim}_Despesas_Empenho.csv"
first_file=true
for file in ${tempDir}/*_Despesas_Empenho.csv; do
  if [ "$first_file" = true ]; then
    cat "$file" > "$output_empenho"
    first_file=false
  else
    tail -n +2 "$file" >> "$output_empenho"
  fi
done

# Processa os arquivos de pagamento
output_pagamento="${ano}${mes}${diaIni}-${diaFim}_Despesas_Pagamento.csv"
first_file=true
for file in ${tempDir}/*_Despesas_Pagamento.csv; do
  if [ "$first_file" = true ]; then
    cat "$file" > "$output_pagamento"
    first_file=false
  else
    tail -n +2 "$file" >> "$output_pagamento"
  fi
done

# Remove o diretório temporário
rm -rf "$tempDir"

# Resolvi manter o diretório com arquivos que fiz o download *.zip
# Assim posso manipular outras informações sem a necessidade de novo download

echo "Arquivos concatenados criados com sucesso!"

# Aprendi bastante fazendo esse script. Abraços!
