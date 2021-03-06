# 1er paso:  poner la dirección donde se tiene guardada la base de datos que se encuentra en este repositorio.
renal.ordenado.numerico.vacio <- read.delim("C:/Users/Daniel Cervantes/Desktop/Datathon2019-master/renal ordenado numerico vacio.txt") 

##cargamos o instalamos las librerías que se utilizarán
install.packages("galgo")
install.packages("caret")

library(galgo)
library(proc)
library(randomForest)
library(caret)


##2do paso: creamos un dataframe para imputar los valores
data<- renal.ordenado.numerico.vacio
#View(data)

data.na <-data

for (i in 1:4) data.na[sample(150, sample(50)), i]<- NA
#imputamos usando randomForest para tener un método de imputación imparcial que no altere estadísticamente a nuestro dataset
data.imputed <- rfImpute(class ~.,data.na)

#se hace la partición de 70-Training, 30-Testing
IndicesEntrenamiento <- createDataPartition(y = data.imputed$class,
                                            p = 0.7,
                                            list = FALSE)
Entrenamiento <- data.imputed[IndicesEntrenamiento,]
Test <- data.imputed[-IndicesEntrenamiento,]

#transponemos nuestras bases de datos para poder realizar un forward selection por algoritmos genéticos

ALL.classes<-data.imputed$class
ALL <- data.imputed[,c(2:23)]
ALL<- t(ALL)
ALL.classes <- t(ALL.classes)

##Tercer paso: iniciamos a correr el algoritmo genético por discriminación lineal. Podemos cambiar en el apartado de 
# "classification method" por el método de clasificación de nuestra preferencia
bb.nearcent<-configBB.VarSel(data = ALL,
                             classes = ALL.classes,
                             classification.method = "mlhd",
                             chromosomeSize = 5,
                             maxSolutions = 500,
                             goalFitness = 0.9,
                             main = "Galgo",
                             saveVariable = "bb.nearcent",
                             saveFrequency = 5,
                             saveFile = "bb.nearcent.Rdata",
)
blast(bb.nearcent)

#curvas de aprendizaje de los modelos

plot(bb.nearcent, type = "fitness")

#matrices de confusión
plot(bb.nearcent, type = "confusion")

fsm<-forwardSelectionModels(bb.nearcent)

fsm$models[1]

mode<-unlist(fsm$models[1])

rownames(ALL)[mode]

#modelado usando máquina de soporte de vectores, en caso de desear un método de modelado distinto, elegimos el método de nuestra preferencia
#En las líneas 70, 73 y 76 ELEGIR SOLO UN MODELO DE CLASIFICACIÓN PARA EVALUAR Y VALIDAR EN LOS PRÓXIMOS PASOS, es decir, correr solo una de las líneas
modelosop <- svm(Entrenamiento$class ~Entrenamiento$pcv + Entrenamiento$appet + Entrenamiento$al)

#probamos el modelo como regresión logística
modelosop <- glm(Entrenamiento$class ~ Entrenamiento$sg)

#se tiene que repetir el análisis para cada propuesta
modelosop <- svm(Entrenamiento$class ~ Entrenamiento$sg + class ~Entrenamiento$pcv)


#modelosop
#Predecimos usando nuestro modelo los datos de Testing que partimos anteriormente
pred <- predict(modelosop, data=Test)


fitted.results <- pred
fitted.results
##graficamos su curva ROC para evaluar su eficiencia de predicción
curvas <- roc(Entrenamiento$class, predictor = as.numeric(fitted.results))
plot(curvas)
lines(curvas, col="blue")
#imprimimos el área bajo la curva ROC
curvas

###punto ideal de corte de la curva ROC

cor(Entrenamiento)

  puntodecorte <- coords(curvas,
                       "best",
                       ret="threshold")

puntodecorte

##realizamos la matriz de confusión para tener una métrica más de evaluación de calidad
fitted.results <- ifelse(pred>puntodecorte,1,0)
matrizgalgo <- confusionMatrix(data=as.factor(fitted.results),reference = as.factor(Entrenamiento$class))
matrizgalgo
