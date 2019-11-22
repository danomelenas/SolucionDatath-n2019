# 1er paso:  poner la direcci�n donde se tiene guardada la base de datos de trabajo
renal.ordenado.numerico.vacio <- read.delim("C:/Users/Daniel Cervantes/Desktop/Datathon2019-master/renal ordenado numerico vacio.txt") 

##cargamos o instalamos las librer�as que se utilizar�n
library(galgo)
library(mice)
library(randomForest)
library(caret)


##2do paso: creamos un dataframe para imputar los valores
data<- renal.ordenado.numerico.vacio
#View(data)

data.na <-data

for (i in 1:4) data.na[sample(150, sample(50)), i]<- NA
#imputamos usando randomForest para tener un m�todo de imputaci�n imparcial que no altere estad�sticamente a nuestro dataset
data.imputed <- rfImpute(class ~.,data.na)

IndicesEntrenamiento <- createDataPartition(y = data.imputed$class,
                                            p = 0.7,
                                            list = FALSE)
Entrenamiento <- data.imputed[IndicesEntrenamiento,]
Test <- data.imputed[-IndicesEntrenamiento,]

#transponemos nuestras bases de datos para poder realizar un forward selection por algoritmos gen�ticos

ALL.classes<-data.imputed$class
ALL <- data.imputed[,c(2:23)]
ALL<- t(ALL)
ALL.classes <- t(ALL.classes)

##Tercer paso: iniciamos a correr el algoritmo gen�tico por discriminaci�n lineal. Podemos cambiar en el apartado de 
# "classification method" por el m�todo de clasificaci�n de nuestra preferencia
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

#matrices de confusi�n
plot(bb.nearcent, type = "confusion")

fsm<-forwardSelectionModels(bb.nearcent)

fsm$models[1]

mode<-unlist(fsm$models[1])

rownames(ALL)[mode]

#modelado usando m�quina de soporte de vectores, en caso de desear un m�todo de modelado distinto, elegimos el 
#m�todo de nuestra preferencia
modelosop <- svm(Entrenamiento$class ~Entrenamiento$pcv + Entrenamiento$appet + Entrenamiento$al)


modelosop


pred <- predict(modelosop, data=Test)

fitted.results <- pred

fitted.results
##graficamos su curva ROC para evaluar su eficiencia de predicci�n
curvas <- roc(Entrenamiento$class, predictor = as.numeric(fitted.results))
plot(curvas)
lines(curvas, col="blue")
curvas

###punto ideal de corte

cor(Entrenamiento)

  puntodecorte <- coords(curvas,
                       "best",
                       ret="threshold")

puntodecorte

##realizamos la matriz de confusi�n para tener una m�trica m�s de evaluaci�n de calidad
fitted.results <- ifelse(pred>puntodecorte,1,0)
matrizgalgo <- confusionMatrix(data=as.factor(fitted.results),reference = as.factor(Entrenamiento$class))
matrizgalgo