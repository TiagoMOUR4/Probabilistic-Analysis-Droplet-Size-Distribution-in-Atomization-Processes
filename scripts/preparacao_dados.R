#Preparacao dos dados para modelagem

preparar_dados <- function() {

  dados <- read.csv("./dados/Dataset.csv")

  features <- c("Nozzle", "Orifice", "Airspeed", "Pressure", "Orientation")
  targets <- c("DV10", "DV50", "DV90", "Less100", "Less200")
  identificadores <- c("Rep", "Run")

  #Resumo dos dados
  cat("\n========== RESUMO DOS DADOS ==========\n")
  print(summary(dados))

  #dados categorizados
  tipo_bico <- table(dados$Nozzle)
  tipo_orificio <- table(dados$Orifice)

  #Criando a pasta para os arquivos
  dir.create("./dados/bicos", showWarnings = FALSE, recursive = TRUE)

  #dados por bico
  csv_bico <- list()

  for (i in names(tipo_bico)) {

    csv_bico[[i]] <- dados[dados$Nozzle == i, ]

    #Nome do arquivo
    nome <- gsub("[^a-zA-Z0-9_-]", "_", i)

    #Salvar CSV
    write.csv(csv_bico[[i]],
              file = paste0("./dados/bicos/", nome, ".csv"),
              row.names = FALSE)
  }

  cat("\n========== OBSERVACOES POR BICO ==========\n")
  print(sapply(csv_bico, nrow))

  #Preparacao dos dados para o modelo
  dados_modelo <- dados[c(features, targets)]

  #Variaveis categoricas
  dados_modelo$Nozzle <- factor(dados_modelo$Nozzle)
  dados_modelo$Orifice <- factor(dados_modelo$Orifice)

  #Variaveis numericas
  numericas <- setdiff(names(dados_modelo), c("Nozzle", "Orifice"))
  dados_modelo[numericas] <- lapply(dados_modelo[numericas], as.numeric)

  cat("\n========== TIPOS DAS VARIAVEIS ==========\n")
  print(sapply(dados_modelo, class))

  return(list(
    dados = dados,
    dados_modelo = dados_modelo,
    features = features,
    targets = targets,
    identificadores = identificadores
  ))
}
