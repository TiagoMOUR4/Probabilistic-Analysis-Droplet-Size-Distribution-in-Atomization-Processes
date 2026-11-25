
#Projeto final da disciplina

#Preparacao dos dados ########################################
source("scripts/preparacao_dados.R")
preparacao <- preparar_dados()

dados <- preparacao$dados
dados_modelo <- preparacao$dados_modelo
features <- preparacao$features
targets <- preparacao$targets
identificadores <- preparacao$identificadores

#Criando os grafos ###########################################
source("scripts/grafos.R")
grafos <- criar_grafos(dados_modelo, features, targets)

G1 <- grafos$G1
G2 <- grafos$G2
G3 <- grafos$G3
G4 <- grafos$G4

#############################################
#           analise dos grafos              #
#############################################
source("scripts/analisar_grafo.R")

resultado_G1 <- analisar_grafo(G1, dados_modelo, nome = "G1")
resultado_G2 <- analisar_grafo(G2, dados_modelo, nome = "G2")
resultado_G3 <- analisar_grafo(G3, dados_modelo, nome = "G3")
resultado_G4 <- analisar_grafo(G4, dados_modelo, nome = "G4")

#Comparando as metricas ######################################
metricas <- rbind(resultado_G1, resultado_G2,
                 resultado_G3, resultado_G4)
metricas$loglik_cg <- NA_real_

if (!is.na(resultado_G2$bic_cg)) {
  metricas$loglik_cg[metricas$grafo == "G2"] <-
    bnlearn::score(G2, dados_modelo, type = "loglik-cg")
}

if (!is.na(resultado_G3$bic_cg)) {
  metricas$loglik_cg[metricas$grafo == "G3"] <-
    bnlearn::score(G3, dados_modelo, type = "loglik-cg")
}

if (!is.na(resultado_G4$bic_cg)) {
  metricas$loglik_cg[metricas$grafo == "G4"] <-
    bnlearn::score(G4, dados_modelo, type = "loglik-cg")
}

cat("\n========== COMPARACAO DOS GRAFOS ==========\n")
print(metricas, row.names = FALSE)

cat("Distancia estrutural entre G2 e G3 (SHD):",
    bnlearn::shd(G2, G3), "\n")

cat("Distancia estrutural entre G2 e G4 (SHD):",
    bnlearn::shd(G2, G4), "\n")

cat("Distancia estrutural entre G3 e G4 (SHD):",
    bnlearn::shd(G3, G4), "\n")

write.csv(metricas, "resultados/metricas_grafos.csv", row.names = FALSE)
