# Avaliacao comum para os grafos do projeto
# Requer o pacote bnlearn e um data.frame com tipos corretamente definidos.

analisar_grafo <- function(grafo, dados, nome = "G1") {

  if (!requireNamespace("bnlearn", quietly = TRUE))
    stop("Instale o pacote bnlearn antes de executar a analise.")

  nos <- bnlearn::nodes(grafo)
  if (!setequal(nos, names(dados)))
    stop("O grafo e os dados precisam conter exatamente as mesmas variaveis.")

  dados <- dados[, nos, drop = FALSE]
  if (anyNA(dados)) stop("Existem dados ausentes na base de modelagem.")
  if (!bnlearn::acyclic(grafo) || !bnlearn::directed(grafo))
    stop("O grafo precisa ser direcionado e aciclico (DAG).")

  tipos_validos <- vapply(dados, function(x) is.factor(x) || is.numeric(x), logical(1))
  if (!all(tipos_validos))
    stop("Converta variaveis categoricas (Nozzle e Orifice) em factor.")

  # Verifica se a estrutura e compativel com uma rede condicional gaussiana
  for (no in nos) {
    pais <- bnlearn::parents(grafo, no)
    if (is.factor(dados[[no]]) && any(vapply(dados[pais], is.numeric, logical(1))))
      stop(paste("O no categorico", no, "nao pode ter pais continuos no modelo CG."))
  }

  # Confere se ha observacoes suficientes para as regressoes locais
  problemas <- character(0)
  for (no in nos) {
    if (!is.numeric(dados[[no]])) next

    pais <- bnlearn::parents(grafo, no)
    pais_cat <- pais[vapply(dados[pais], is.factor, logical(1))]
    pais_num <- pais[vapply(dados[pais], is.numeric, logical(1))]

    grupo <- if (length(pais_cat) > 0) {
      do.call(interaction, c(unname(as.list(dados[pais_cat])), list(drop = TRUE)))
    } else {
      factor(rep("todos", nrow(dados)))
    }

    frequencias <- table(grupo)
    insuficientes <- sum(frequencias <= length(pais_num) + 1)

    if (insuficientes > 0) {
      problemas <- c(problemas, sprintf(
        "%s: %d grupos com poucas observacoes (minimo = %d).",
        no, insuficientes, min(frequencias)
      ))
    }
  }

  # BIC-CG so e apresentado quando a verificacao basica passa
  bic <- NA_real_
  if (length(problemas) == 0) {
    bic <- tryCatch(
      bnlearn::score(grafo, dados, type = "bic-cg"),
      error = function(e) {
        message("Falha no calculo do BIC-CG: ", conditionMessage(e))
        NA_real_
      }
    )
    if (!is.finite(bic)) bic <- NA_real_
  }

  resultado <- data.frame(
    grafo = nome, nos = bnlearn::nnodes(grafo),
    arestas = bnlearn::narcs(grafo), bic_cg = bic,
    situacao = if (length(problemas) > 0) "ajuste insuficiente" else
      if (is.na(bic)) "BIC indisponivel" else "BIC calculado"
  )

  cat("\n=== AVALIACAO:", nome, "===\n")
  print(resultado, row.names = FALSE)
  if (length(problemas) > 0) cat(paste(problemas, collapse = "\n"), "\n")
  return(resultado)
}
