# Open classrooms Data Analyst - P6
# ---------------------------------

# - Détection de faux billets avec un modèle de régression linéaire
# - projection parmis les individus d'apprentissages sur le 1er plan factoriel

#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# -----------------------------------
#       ARGUMENTS DU SCRIPT
# -----------------------------------

# args 1 : chemin du fichier contenant la liste des billets à tester 
# args 2 : chemin du fichier de l'acp a enregistrer (au format svg)
#          par défaut, enregistré dans le répertoire du script, sous le nom 'acp.svg'

if (length(args)==0) {
  stop("Il faut au moins entrer en argument le chemin du fichier des billets à tester", call.=FALSE)
} else if (length(args)==1) {
  billets.test.path = args[1]
  acp.path = paste(getwd(), 'acp.svg', sep = '/')
} else {
  billets.test.path = args[1]
  acp.path = args[2]
}

# -----------------------------------
#         import des libs
# -----------------------------------

cat('\n', 'Import des librairies', '\n',
          '---------------------', '\n\n')

require(MASS)
library("FactoMineR")
library("factoextra")

# ----------- CONSTANTES ------------

# Variables qui sont utilisées pour caractériser les dimensions du billets
billet.var.dim = c('length', 'height_left', 'height_right', 'margin_low', 'margin_up', 'diagonal')

# -----------------------------------
#         CREATION DU MODELE
# -----------------------------------

cat('\n', 'Création du modèle de régression logistique', '\n',
           '------------------------------------------', '\n\n')

# import des billets d'apprentissage
billets.appr = read.csv2('billets_apprentissage.csv', sep=",", dec = '.')

# regression linéaire avec stepwise
rl.formule.cst = '~ 1'
rl.formule.all = '~ length + height_left + height_right + margin_low + margin_up + diagonal'
rl.modele = glm(is_genuine ~ 1, data = billets.appr, family = 'binomial')

rl.modele = stepAIC(rl.modele,
                    data = billets.appr,
                    direction="both",
                    scope = list(lower = rl.formule.cst, upper = rl.formule.all),
                    trace = FALSE)


cat('\n', '** Le modèle a été créé **', '\n\n',
          'Les variables retenues sont :', '\n')

for (coef in names(rl.modele$coefficients)) {
  cat('\t-', coef, '\n')
}

# -----------------------------------
#            PREDICTION
# -----------------------------------

cat('\n', 'Prédiction des billets de tests', '\n',
          '-------------------------------', '\n')

# ouverture du fichier des billets à prédire

billets.test  = read.csv2(billets.test.path, sep=',', dec = '.')
rownames(billets.test) = billets.test$id

cat('\n', ' - Ouverture du fichier', billets.test.path, '\n')

# caclul des probabilités

billet.test.prob.vrai = predict(rl.modele,
                            billets.test[, billet.var.dim],
                            type='response')

billet.test.prob.faux = 1 - billet.test.prob.vrai

cat('\n', " - Prédiction sur l'authenticité des billets faite", '\n\n')

# -----------------------------------
#             OUTPUTS
# -----------------------------------

for (id in billets.test$id) {
  cat('- Billet', id, '\t P(VRAI) = ', billet.test.prob.vrai[id],  '\n')
  if (billet.test.prob.vrai[id] < 0.5) {
    cat("\t\t --> FAUX BILLET\n\n")
  } else {
    cat("\t\t --> VRAI BILLET\n\n")
  }
}

cat('-------------------------------\n\n')

# -----------------------------------
#           OUTPUT : ACP
# -----------------------------------

# prepartion des donnees

pop.acp = rbind(
  billets.appr[, billet.var.dim],
  billets.test[, billet.var.dim]
)

# ACP

pca.result = PCA(X = pop.acp,
                 ind.sup = which(rownames(pop.acp) %in% rownames(billets.test)),
                 graph = FALSE)

fig = fviz_pca_ind(pca.result,
                   pointshape = 19,
                   label='quanti.sup',
                   habillage = billets.appr$is_genuine,
                   palette = c('#f8766d', '#00ba38'),
                   col.ind.sup = 'black',
                   mean.point = FALSE,
                   title='Projection dans le premier plan factoriel',
                   addEllipse=TRUE,
                   legend.title = "vrai billet ?"
)

svg(acp.path, width=16, height=9)
fig
dev.off()

cat( "\nLa projection sur le premier plan factoriel a été enregistrée à l'emplacement :\n", acp.path, '\n\n',
     '-----------------------------', '\n\n')