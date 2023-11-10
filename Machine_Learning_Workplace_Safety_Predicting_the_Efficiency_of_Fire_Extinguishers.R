library(DataExplorer)
library(SmartEDA)
library(dataMaid)
library(readxl)
library(dplyr)
library(corrgram)
library(corrplot)
library(h2o)
??DataExplorer
df <- read_xlsx('Acoustic_Extinguisher_Fire_Dataset.xlsx', sheet = 1)
View(df)

#Realizando análise exploratória automatizada com os pacotes "DataExplorer", "SmartEDA" e "DataMaid".
#EN: Performing automated exploratory analysis with the "DataExplorer", "SmartEDA" and "DataMaid" packages.

#DataMaid
makeDataReport(df, output = "html", replace = TRUE)

#Em uma análise preliminar, foram reconhecidos outliers para o DESIBEL, porém estes valores realmente fazem parte do estudo, portanto não serão retirados da análise.
#Inicialmente nenhum problema foi encontrado no dataframe (falta de dados).

#EN:In a preliminary analysis, outliers were recognized for DESIBEL, but these values are actually part of the study, therefore they will not be removed from the analysis.
#Initially no problems were found in the dataframe (missing data).

#SmartEDA
ExpReport(df, op_file = 'SmartEDA_df.html')

#Q-Q plot das variáveis demonstram uma distribuição normal, sendo explicado ao se aproximarem da reta.
#Scatterplot bivariado entre as variáveis preditoras apresentam valores discretos e não continuos, em sua maioria, devido o estudo ter sido conduzido com 
#valores específicos para testes de extinção ou não extinção de incêndio.
#Para nossa variável alvo, é observado um balanço de classes representado por barplot das variáveis categóricas, não sendo necessário fazer um balanceamento de classes no dataframe,
#tendo em vista que o desbalanceamento de classes pode ocasionar um viés na predição em regressão logística, gerando imprecisão.

#EN: Q-Q plot of variables demonstrate a normal distribution, being explained as they approach the straight line.
#Bivariate scatterplot between the predictor variables presents discrete and non-continuous values, mostly, due to the study being conducted with
#specific values for fire extinguishing or non-extinguishing tests.
#For our target variable, a class balance represented by barplot of categorical variables is observed, making it not necessary to balance classes in the dataframe,
#bearing in mind that class imbalance can cause a bias in the prediction in logistic regression, generating inaccuracy.

#DataExplorer
create_report(dummify(df, maxcat = 10))

#Para essa análise, todos os valores foram representados numericamente, afim de analisar possíveis relações das variáveis categóricas com as numéricas.
#Pela análise de correlação, as variáveis que mais apresentaram um coeficiente de correlação alto com a variável "STATUS" foram: AIRFLOW e DISTANCE.

#EN: For this analysis, all values were represented numerically, in order to analyze possible relationships between categorical and numerical variables.
#Based on the correlation analysis, the variables that most showed a high correlation coefficient with the "STATUS" variable were: AIRFLOW and DISTANCE.

summary(df)
lapply(df, unique)
str(df)

#Visualizando se existem dados ausentes 

#EN: Viewing if there is missing data
any(is.na(df))
any(complete.cases(df))

#Ao visualizar os dados, percebe-se que as variáveis "FUEL" e "STATUS" são variáveis categóricas, sendo assim, serão convertidas em fator.

#EN:When viewing the data, it is clear that the variables "FUEL" and "STATUS" are categorical variables, therefore, they will be converted into a factor 

fac_names <- names(df)[c(2,7)]
df <- df %>% mutate(across(all_of(fac_names), as.factor))

#Gerando modelo simples de regressão logística para visualizar a importância das variáveis preditoras explicarem a variável alvo.

#EN: Generating a simple logistic regression model to visualize the importance of the predictor variables in explaining the target variable.

mod1 <- glm(STATUS ~ ., data = df, family = binomial)
summary(mod1)

#Gerando modelo random forest para visualizar a importância das variáveis preditivas no ponto de vista do algoritmo.

#EN: Generating random forest model to visualize the importance of predictive variables from the algorithm's point of view.

modrand <- randomForest(STATUS ~ . ,data = df)
varImpPlot(modrand)

#Ao realizar um modelo de regressão logística simples, é observado que todas as variáveis preditivas tem impacto para prever a variável alvo,
#e ao criar um modelo Random Forest e analisando quais as variáveis são mais importantes no ponto de vista do modelo, obtem-se: AIRFLOW, DISTANCE e FREQUENCY.

#EN: When performing a simple logistic regression model, it is observed that all predictive variables have an impact on predicting the target variable,
#and when creating a Random Forest model and analyzing which variables are most important from the model's point of view, we obtain: AIRFLOW, DISTANCE and FREQUENCY.

#Criaremos vários modelos automatizados e extrairemos o melhor modelo a partir do pacote H2o.
#Iniciando a API. 

#EN: We will create several automated models and extract the best model from the H2o package.
#Starting the API.
h2o.init()

# O H2O requer que os dados estejam no formato de dataframe do H2O

#EN: H2O requires data to be in H2O dataframe format
h2o_frame <- as.h2o(df)
class(h2o_frame)
head(h2o_frame)

# Split dos dados em treino (70%), validação (20%) e teste (10%).

#EN: Split data into training (70%), validation (20%) and testing (10%).

h2o.splitFrame
h2o_frame_split <- h2o.splitFrame(h2o_frame, ratios = c(0.7,0.2))
head(h2o_frame_split)

# Modelo AutoML

#EN: AutoML model

?h2o.automl
modelo_automl <- h2o.automl(y = 'STATUS',
                            balance_classes = FALSE,
                            training_frame = h2o_frame_split[[1]],
                            nfolds = 4,
                            leaderboard_frame = h2o_frame_split[[3]],
                            validation_frame = h2o_frame_split[[2]],
                            max_runtime_secs = 360 * 2,
                            max_models = 100,
                            sort_metric = "AUC")


leaderboard_automl <- as.data.frame(modelo_automl@leaderboard)
View(leaderboard_automl)
modelo_automl


# Extrai o líder (modelo com melhor performance)

#EN: Extracts the leader (model with best performance)

lider_automl <- modelo_automl@leader
View(lider_automl)
bmod <-h2o.get_best_model(modelo_automl,criterion = "AUC")

predictions <- h2o.predict(bmod, h2o_frame_split[[3]])
h2o.performance(bmod, h2o_frame_split[[3]])

#Para o modelo criado, obteve-se uma alta precisão utilizando o algoritmo GBM, com R² 0.93 e AUC de 0.99

#EN: For the model created, high precision was obtained using the GBM algorithm, with R² 0.93 and AUC of 0.99

#Afim de generalizar o modelo, realizaremos uma análise com o pacote H2o, fazendo com que ele apresente as variáveis preditivas com maior peso 
#para realizar o estudo, e então criaremos um novo modelo a partir destas variáveis. 

#EN: In order to generalize the model, we will carry out an analysis with the H2o package, making it present the predictive variables with greater weight
#to carry out the study, and then we will create a new model from these variables.

ig <- h2o.infogram(y= 'STATUS', training_frame = h2o_frame_split[[1]])
plot(ig)
ig@admissible_features

#Para o algoritmo, as variáveis com mais importância são: "SIZE", "FREQUENCY" e "DISTANCE". Como sabemos que o algoritmo GBM foi o que teve uma melhor performance,
#realizaremos um treinamento específico com este algoritmo, alterando alguns hiperparâmetros.

#EN:For the algorithm, the most important variables are: "SIZE", "FREQUENCY" and "DISTANCE". As we know that the GBM algorithm performed best,
#We will carry out specific training with this algorithm, changing some hyperparameters.

gbm_params1 <- list(learn_rate = c(0.1, 0.4, 0.5),
                    max_depth = c(3, 5, 9, 15),
                    sample_rate = c(0.4, 0.8, 1.0),
                    col_sample_rate = c(0.2, 0.5),
                    ntrees = c(200,300,400,500),
                    max_runtime_secs = 700)
?h2o.gbm
GBM_grid <- h2o.grid(algorithm = "gbm",
                     x = ig@admissible_features,
                     y = "STATUS",
                     grid_id = "GBM_grid",
                     training_frame = h2o_frame_split[[1]],
                     validation_frame = h2o_frame_split[[2]],
                     hyper_params = gbm_params1)

gbm_gridperf1 <- h2o.getGrid(grid_id = "GBM_grid",
                             sort_by = "auc",
                             decreasing = TRUE)
print(gbm_gridperf1)
GBM_grid@model_ids[[1]]

# Recolhe o melhor modelo GBM com base em sua AUC.

#EN: Collects the best GBM model based on its AUC.

best_gbm1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])
h2o.performance(best_gbm1, newdata = h2o_frame_split[[3]])
best_gbm1@model

#Ao refazer o modelo com vários hiperparâmetros, o melhor modelo generalizado encontrado possui uma AUC de 0.99 e R² de 0.85, apresentando uma diferença relativamente 
#alta em comparação com o modelo criado levando em consideração todas as variáveis preditivas do data frame.
#Podemos ir mais a fundo, recolhendo os hiperparâmetros que geraram o modelo com maior precisão, e alterar demais parâmetros, afim de aumentar ainda mais 
#a eficácia do modelo.

#EN: When redoing the model with several hyperparameters, the best generalized model found has an AUC of 0.99 and R² of 0.85, presenting a relatively
#high compared to the model created taking into account all the predictive variables of the data frame.
#We can go deeper, collecting the hyperparameters that generated the model with greater precision, and change other parameters, in order to increase it even further
#the effectiveness of the model.

gbm_params2 <- list(learn_rate = seq(0.1, 0.6, 0.1),
                    max_depth = seq(3,10,1),
                    sample_rate = seq(0.2, 1, 0.2),
                    col_sample_rate = seq(0.2, 0.8, 0.2),
                    ntrees = seq(200,1000,100),
                    max_runtime_secs = 1000)

search_criteria <- search_criteria <- list(strategy = "RandomDiscrete", max_models = 250)

?h2o.gbm
GBM_grid2 <- h2o.grid(algorithm = "gbm",
                     x = ig@admissible_features,
                     y = "STATUS",
                     grid_id = "GBM_grid2",
                     training_frame = h2o_frame_split[[1]],
                     validation_frame = h2o_frame_split[[2]],
                     hyper_params = gbm_params2,
                     search_criteria = search_criteria)

gbm_gridperf2 <- h2o.getGrid(grid_id = "GBM_grid2",
                             sort_by = "auc",
                             decreasing = TRUE)

best_gbm2 <- h2o.getModel(gbm_gridperf2@model_ids[[1]])
h2o.performance(best_gbm2, newdata = h2o_frame_split[[3]])
best_gbm2@parameters

#Ao realizar uma segunda análise afim de aumentar a eficiência do modelo, se obteve um resultado muito parecido com o modelo anterior, tendo uma menor performance do
#que anteriormente. Poderiamos aumentar o número de hiperparâmetros e tempo de treinamento para desenvolvimento de mais modelos, mas para a necessidade atual, utilizaremos 
#o modelo com maior eficiência que foi gerado a partir do "GBM_grid". 

#EN: When carrying out a second analysis in order to increase the efficiency of the model, a result very similar to the previous model was obtained, with a lower performance than the previous model.
#than previously. We could increase the number of hyperparameters and training time to develop more models, but for the current need, we will use
#the model with the highest efficiency that was generated from "GBM_grid".

# Salvando o modelo 

#EN: Saving model 

model_path <- h2o.saveModel(object = best_gbm1, path = getwd(), force = TRUE)
print(model_path)

# Carregando modelo 

#EN: Loading model

setted_model <- h2o.loadModel(model_path)

#Realizando predições com novos dados (dados de teste criados a partir do dataframe principal)
#criando um dataframe com 10% dos dados de forma aleatória a partir do dataframe original. 

#EN: Performing predictions with new data (test data created from the main dataframe)
#creating a dataframe with 10% of the data randomly from the original dataframe

new_data <- h2o.splitFrame(h2o_frame, ratios = 0.1)
new_predictions <- h2o.predict(setted_model,new_data[[1]])
h2o.performance(setted_model, new_data[[1]])
comparacao <- h2o.cbind(new_predictions$predict,new_data[[1]][,7])

#Para o resultado de "new_predictions", são fornecidos as probabilidades da variável alvo ser "0" ou "1" para cada linha fornecida do data frame "new_data".
#Para os dados testados, houve um acerto de 1663 e 77 erros.

#EN;For the "new_predictions" result, the probabilities of the target variable being "0" or "1" for each given row of the "new_data" data frame are given.
#For the tested data, there was a hit of 1663 and 77 errors.
