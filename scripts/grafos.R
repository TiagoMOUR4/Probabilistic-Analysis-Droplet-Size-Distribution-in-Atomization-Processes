
library(bnlearn)

#Grafo 1, variaveis ndependentes #########################
grafo1 <- function(features, targets) {

  #Criando a estrutura
  G1 <- empty.graph(c(features, targets))

  #Adicionando as conexoes
  arcs(G1) <- as.matrix(expand.grid(
    from = features, to = targets
  ))

  return(G1)
}

#Grafo 2, usando hill climbing ####################
grafo2 <- function(dados, features, targets) {

  #Restricoes de direcao
  categoricas <- c("Nozzle", "Orifice")
  continuas <- setdiff(c(features, targets), categoricas)

  restricoes <- unique(rbind(
    expand.grid(from = targets, to = features, stringsAsFactors = FALSE),
    expand.grid(from = continuas, to = categoricas, stringsAsFactors = FALSE),
    data.frame(from = "Orifice", to = "Nozzle")
  ))

  #Aprendizagem do grafo sem limite de pais
  set.seed(123)
  G2 <- hc(dados, score = "bic-cg",
           blacklist = restricoes,
           maxp = Inf, restart = 3)

  return(G2)
}

#Grafo 3, proposto a partir da fisica #############
grafo3 <- function(features, targets) {

  #Criando o grafo proposto
  G3 <- empty.graph(c(features, targets))

  #Geometria: Nozzle, Orifice e Orientation
  #Operacao: Airspeed e Pressure
  #Distribuicao: DV10, DV50 e DV90
  #Variaveis Less: Less100 e Less200
  conexoes <- matrix(c(
    #Dependencias dentro da geometria
    "Nozzle",      "Orifice",

    #Dependencias dentro da operacao
    "Airspeed",    "Pressure",
    "Orientation", "Pressure",

    #Dependencias dentro das variaveis DV
    "DV10",        "DV50",
    "DV50",        "DV90",

    #Dependencias dentro das variaveis Less
    "Less100",     "Less200",

    #Ligacoes entre os grupos
    "Orifice",     "DV10",
    "Pressure",    "Less100",
    "DV10",        "Less100"
  ), ncol = 2, byrow = TRUE)

  colnames(conexoes) <- c("from", "to")
  arcs(G3) <- conexoes

  return(G3)
}


#Grafo 4, Hill Climbing iniciado a partir do G3 #########
grafo4 <- function(dados, features, targets, G3) {

  #Mesmas restricoes utilizadas no G2
  categoricas <- c("Nozzle", "Orifice")
  continuas <- setdiff(c(features, targets), categoricas)

  restricoes <- unique(rbind(
    expand.grid(from = targets, to = features, stringsAsFactors = FALSE),
    expand.grid(from = continuas, to = categoricas, stringsAsFactors = FALSE),
    data.frame(from = "Orifice", to = "Nozzle")
  ))

  #Aprendizagem iniciada na estrutura do G3
  set.seed(123)
  G4 <- hc(dados, start = G3, score = "bic-cg",
           blacklist = restricoes,
           maxp = Inf, restart = 3)

  return(G4)
}


#Salvando as imagens dos grafos ###################
salvar_grafo <- function(grafo, nome) {

  dir.create("resultados", showWarnings = FALSE, recursive = TRUE)
  arestas <- bnlearn::arcs(grafo)

  if (nome == "G1") {
    arquivo_dot <- "resultados/grafo1.dot"
    arquivo_svg <- "resultados/grafo1.svg"

    dot <- c(
      "digraph G1 {",
      'graph [rankdir=NS, margin=0, pad=0.02, nodesep=0.20, ranksep=0.50];',
      'node [shape=circle, fontsize=11, margin="0.08,0.05"];',
      'edge [color=gray60, arrowsize=0.45];',
      sprintf('"%s";', bnlearn::nodes(grafo)),
      sprintf('"%s" -> "%s";', arestas[, 1], arestas[, 2]),
      "}"
    )
  } else {
    arquivo_dot <- paste0("resultados/", nome, ".dot")
    arquivo_svg <- paste0("resultados/", nome, ".svg")

    dot <- c(
      paste0("digraph ", nome, " {"),
      if (nome == "G3") "rankdir=LR;" else "rankdir=LR;",
      "graph [pad=0.03];",
      "node [shape=circle, style=rounded];",
      sprintf('"%s";', bnlearn::nodes(grafo))
    )

    #Grupos do grafo proposto
    if (nome == "G3") {
      dot <- c(dot,
        'subgraph cluster_geometria { label="Geometria"; style=rounded; color="#94A3B8"; "Nozzle"; "Orifice"; "Orientation"; }',
        'subgraph cluster_operacao { label="Operacao"; style=rounded; color="#94A3B8"; "Airspeed"; "Pressure"; }',
        'subgraph cluster_dv { label="Distribuicao DV"; style=rounded; color="#94A3B8"; "DV10"; "DV50"; "DV90"; }',
        'subgraph cluster_less { label="Variaveis Less"; style=rounded; color="#94A3B8"; "Less100"; "Less200"; }'
      )
    }

    dot <- c(dot,
      sprintf('"%s" -> "%s";', arestas[, 1], arestas[, 2]),
      "}"
    )
  }

  writeLines(dot, arquivo_dot)

  graphviz <- "C:/Program Files/Graphviz/bin/dot.exe"
  if (!file.exists(graphviz)) graphviz <- Sys.which("dot")

  if (length(graphviz) == 0 || !nzchar(graphviz)) {
    warning("Graphviz nao localizado. Arquivo .dot salvo em: ", arquivo_dot)
  } else {
    system2(graphviz, c("-Tsvg", arquivo_dot, "-o", arquivo_svg))
    cat("Grafo salvo em ", arquivo_svg, "\n", sep = "")
  }
}

#Criacao, impressao e salvamento dos grafos ######
criar_grafos <- function(dados_modelo, features, targets) {

  G1 <- grafo1(features, targets)
  G2 <- grafo2(dados_modelo, features, targets)
  G3 <- grafo3(features, targets)
  G4 <- grafo4(dados_modelo, features, targets, G3)

  cat("\n========== GRAFO 1 ==========\n")
  cat("As features sao:", paste(features, collapse = ", "), "\n")
  cat("Os targets sao:", paste(targets, collapse = ", "), "\n")

  cat("\n========== CONEXOES DO G2 ==========\n")
  print(bnlearn::arcs(G2))

  cat("\n========== CONEXOES DO G3 ==========\n")
  print(bnlearn::arcs(G3))

  cat("\n========== CONEXOES DO G4 ==========\n")
  print(bnlearn::arcs(G4))

  cat("\n========== IMAGENS DOS GRAFOS ==========\n")
  salvar_grafo(G1, "G1")
  salvar_grafo(G2, "G2")
  salvar_grafo(G3, "G3")
  salvar_grafo(G4, "G4")

  return(list(G1 = G1, G2 = G2, G3 = G3, G4 = G4))
}
