
library(readxl)
df <- read_xlsx("FEV-data-Excel.xlsx")
View(df)
names(df)
dim(df)

#Alterando Nome das variáveis
n_names <- names(df)
n_names[1] <- "NomeCompleto"
n_names[2] <- "Fabricante"
n_names[3] <- "Modelo"
n_names[4] <- "PrecoMin_PLN"
n_names[5] <- "PotenciaMotor_KM"
n_names[6] <- "TorqueMaximo_Nm"
n_names[7] <- "TipodeFreio"
n_names[8] <- "TipodeDirecao"
n_names[9] <- "CapacidadeBateria_kWh"
n_names[10] <- "Autonomia_km"
n_names[11] <- "DistanciaEixos_cm"
n_names[12] <- "Comprimento_cm"
n_names[13] <- "Largura_cm"
n_names[14] <- "Altura_cm"
n_names[15] <- "PesoBruto_kg"
n_names[16] <- "PesoTotalPermitido_kg"
n_names[17] <- "CapacidadeMaxCarga_kg"
n_names[18] <- "NumerodeAssentos"
n_names[19] <- "NumerodePortas"
n_names[20] <- "TamanhoPneu_in"
n_names[21] <- "VelocidadeMax_kph"
n_names[22] <- "CapacidadeInicializacao_VDA_l"
n_names[23] <- "Aceleracao_0_100_kph_s"
n_names[24] <- "CarregamentoMaxDC_kW"
n_names[25] <- "ConsumoEnergiaMedio"

colnames(df) <- n_names
summary(df)
is.numeric(df)

#è observado que existem valores NA nas seguintes variáveis: PesoTotalPermitido_kg, CapacidadeMaxCarga_kg, CapacidadeInicialização, Aceleracao_0-100 e consumo médio de energia 

n_df <- df %>% na.omit()
col_chr <- df %>% select_if(is.character) %>% names()
str(n_df)
n_df[, col_chr] <- lapply(n_df[, col_chr], as.factor)
col_num <- n_df %>% select_if(is.numeric)
str(col_num)
cor(col_num)
corrplot(corr = cor(col_num), method = "circle", type = "upper", addCoef.col = "green", tl.cex = 0.6,cl.cex = 0.8,number.cex = 0.7)

#Ao realizar a análise de correlação, percebe-se uma relação relativamente forte (acima de 0.7) entre o consumo energético e as variáveis:
#PrecoMin_PLN, PotenciaMotor_KM, TorqueMaximo_Nm, CapacidadeBateria_kWh, DistanciaEixos_cm, Comprimento_cm, PesoBruto_kg, PesoTotalPermitido_kg, VelocidadeMax_kph, CapacidadeInicializacao_VDA_l, CarregamentoMaxDC_kW
#Analisando o problema, esse tipo de relação condiz com a realidade, devido a fatores como o dimensionamento do veículo (peso, comprimento), influenciam diretamente em quanto será exigido do motor,
#além de que, ao utilizar o veículo próximo do seu rendimento máximo, exigirá um maior consumo também, se tornando clara a relação de potência e torque do motor com o consumo,
#todos esses fatores acabam que encarecendo o produto final, tornando essa relação positiva, pois a medida que o valor do produto aumenta, valores relacionado à sua performance aumentam, gerando um maior consumo energético.


hist(n_df$ConsumoEnergiaMedio)
ConMed <- n_df %>% group_by(Fabricante) %>% summarize(ConsumoEnergia = mean(ConsumoEnergiaMedio))

#analisando se o consumo médio varia entre as fabricantes 
hist(ConMed$ConsumoEnergia)

shapiro.test(ConMed$ConsumoEnergia)
#Ao realizar uma análise sobre a média de consumo dos veículos por fabricante, percebe-se que não há uma distribuição normal, podendo se tornar tendenciosa 
# a avalição desta forma, onde uma fabricante será mais favorecida que a outra, podendo ter vários outros fatores influenciando nessa oscilação, como 
# a diferenciação da "linha" do veículo, sendo os mais caros com tecnlogia mais desenvolvida, tendo consumo aumentando ou reduzido de acordo com a potência do motor.


#Criando um modelo para visualizar a importancia de cada variável

mod_var_sel <- randomForest(ConsumoEnergiaMedio ~ .,data = n_df, ntree = 1000)
varImpPlot(mod_var_sel,sort = T)
summary(mod_var_sel)

#Ao realizar um modelo Random Forest para deixar que a maquina selecione as variáveis mais importantes, percebe-se que o Modelo e fabricante do veículo tem uma alta importância 
#na relação com o consumo. Para efeitos de predição com base em características presentes no veículo, não iremos considerar modelo nem fabricante do veículo.
#Portanto, realizaremos um modelo de regressão para analisar a relação entre o consumo e outras variáveis relacionadas as características do veículo.

any(is.na(n_df))
num_df <- n_df %>% select_if(is.numeric)
mod1 <- lm(ConsumoEnergiaMedio ~ .,data = num_df)
summary(mod1)

anova(mod1)
#Criando modelo de acordo com significancia estatistica utilizando a ANOVA no modelo de regressão linear 
mod2 <- lm(ConsumoEnergiaMedio ~ PrecoMin_PLN + PotenciaMotor_KM + TorqueMaximo_Nm + Autonomia_km + CapacidadeBateria_kWh + DistanciaEixos_cm + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod2)

#Criando modelo de acordo com a importancia imposta pelo random forest 
mod3 <- lm(ConsumoEnergiaMedio ~ DistanciaEixos_cm + PesoTotalPermitido_kg + PrecoMin_PLN + Comprimento_cm + PesoBruto_kg + PotenciaMotor_KM  ,data = num_df)
summary(mod3)

#Ao analisar o R-squared de ambos os modelos, percebe-se uma melhor performance do modelo 2 (criado a partir da significância estatística da ANOVA) do que o modelo 3 (Criado a partir do Random Forest).
#Criaremos mais alguns modelos, visando a generalização 

mod4 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh + DistanciaEixos_cm + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod4)

#Ao retirar variáveis como: Potência, torque e preço; Não se observou alteração significativa no R-squared do modelo. Retiraremos também a distância entre eixos e avaliaremos o modelo.

mod5 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod5)

mod6 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh +PesoTotalPermitido_kg ,data = num_df)
summary(mod6)

#Foi selecionado o modelo 6 para avaliação devido sua performance com um número reduzido de variáveis preditoras, apresentando ser um modelo com maior generalização 

#Dividindo os dados em dados de teste e validação 

sub_dados <- sample.split(n_df$ConsumoEnergiaMedio, SplitRatio = 0.7)
dados_treino <- n_df[sub_dados,]
dados_teste <- n_df[!sub_dados,]

mod7 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh +PesoTotalPermitido_kg ,data = dados_treino)
summary(mod7)

previsao <- predict(mod7, newdata = dados_teste)
resultado <- data.frame(Real = dados_teste$ConsumoEnergiaMedio, Previsao = previsao)

#Calcule o Erro Médio Quadrático (MSE)
mse <- mean((resultado$Previsao - resultado$Real)^2)

# Calcule o Coeficiente de Determinação (R²)
r_squared <- cor(resultado$Previsao, resultado$Real)^2

#O modelo possui um MSE de 0.75 e R² de 0.95, ou seja, uma baixo MSE e um alto R² indicam que o modelo possuia uma baixa taxa de erro 
# e que as variáveis independentes (Autonomia, Capacidade da bateria e Peso total permitido) explicam 95% da variabilidade da variável dependente, 
# além de serem variáveis importantes para uma empresa de logistica, devido a necessidade de tranpostar cargas. Outras variáveis que podem ser inclusas 
# para uma melhor escolha da empresa, seriam as dimensões dos veículos, podendo escolher a melhor opção para transporte dos produtos. 

library(readxl)
df <- read_xlsx("FEV-data-Excel.xlsx")
View(df)
names(df)
dim(df)

#Alterando Nome das variáveis
n_names <- names(df)
n_names[1] <- "NomeCompleto"
n_names[2] <- "Fabricante"
n_names[3] <- "Modelo"
n_names[4] <- "PrecoMin_PLN"
n_names[5] <- "PotenciaMotor_KM"
n_names[6] <- "TorqueMaximo_Nm"
n_names[7] <- "TipodeFreio"
n_names[8] <- "TipodeDirecao"
n_names[9] <- "CapacidadeBateria_kWh"
n_names[10] <- "Autonomia_km"
n_names[11] <- "DistanciaEixos_cm"
n_names[12] <- "Comprimento_cm"
n_names[13] <- "Largura_cm"
n_names[14] <- "Altura_cm"
n_names[15] <- "PesoBruto_kg"
n_names[16] <- "PesoTotalPermitido_kg"
n_names[17] <- "CapacidadeMaxCarga_kg"
n_names[18] <- "NumerodeAssentos"
n_names[19] <- "NumerodePortas"
n_names[20] <- "TamanhoPneu_in"
n_names[21] <- "VelocidadeMax_kph"
n_names[22] <- "CapacidadeInicializacao_VDA_l"
n_names[23] <- "Aceleracao_0_100_kph_s"
n_names[24] <- "CarregamentoMaxDC_kW"
n_names[25] <- "ConsumoEnergiaMedio"

colnames(df) <- n_names
summary(df)
is.numeric(df)

#è observado que existem valores NA nas seguintes variáveis: PesoTotalPermitido_kg, CapacidadeMaxCarga_kg, CapacidadeInicialização, Aceleracao_0-100 e consumo médio de energia 

n_df <- df %>% na.omit()
col_chr <- df %>% select_if(is.character) %>% names()
str(n_df)
n_df[, col_chr] <- lapply(n_df[, col_chr], as.factor)
col_num <- n_df %>% select_if(is.numeric)
str(col_num)
cor(col_num)
corrplot(corr = cor(col_num), method = "circle", type = "upper", addCoef.col = "green", tl.cex = 0.6,cl.cex = 0.8,number.cex = 0.7)

#Ao realizar a análise de correlação, percebe-se uma relação relativamente forte (acima de 0.7) entre o consumo energético e as variáveis:
#PrecoMin_PLN, PotenciaMotor_KM, TorqueMaximo_Nm, CapacidadeBateria_kWh, DistanciaEixos_cm, Comprimento_cm, PesoBruto_kg, PesoTotalPermitido_kg, VelocidadeMax_kph, CapacidadeInicializacao_VDA_l, CarregamentoMaxDC_kW
#Analisando o problema, esse tipo de relação condiz com a realidade, devido a fatores como o dimensionamento do veículo (peso, comprimento), influenciam diretamente em quanto será exigido do motor,
#além de que, ao utilizar o veículo próximo do seu rendimento máximo, exigirá um maior consumo também, se tornando clara a relação de potência e torque do motor com o consumo,
#todos esses fatores acabam que encarecendo o produto final, tornando essa relação positiva, pois a medida que o valor do produto aumenta, valores relacionado à sua performance aumentam, gerando um maior consumo energético.


hist(n_df$ConsumoEnergiaMedio)
ConMed <- n_df %>% group_by(Fabricante) %>% summarize(ConsumoEnergia = mean(ConsumoEnergiaMedio))

#analisando se o consumo médio varia entre as fabricantes 
hist(ConMed$ConsumoEnergia)

shapiro.test(ConMed$ConsumoEnergia)
#Ao realizar uma análise sobre a média de consumo dos veículos por fabricante, percebe-se que não há uma distribuição normal, podendo se tornar tendenciosa 
# a avalição desta forma, onde uma fabricante será mais favorecida que a outra, podendo ter vários outros fatores influenciando nessa oscilação, como 
# a diferenciação da "linha" do veículo, sendo os mais caros com tecnlogia mais desenvolvida, tendo consumo aumentando ou reduzido de acordo com a potência do motor.


#Criando um modelo para visualizar a importancia de cada variável

mod_var_sel <- randomForest(ConsumoEnergiaMedio ~ .,data = n_df, ntree = 1000)
varImpPlot(mod_var_sel,sort = T)
summary(mod_var_sel)

#Ao realizar um modelo Random Forest para deixar que a maquina selecione as variáveis mais importantes, percebe-se que o Modelo e fabricante do veículo tem uma alta importância 
#na relação com o consumo. Para efeitos de predição com base em características presentes no veículo, não iremos considerar modelo nem fabricante do veículo.
#Portanto, realizaremos um modelo de regressão para analisar a relação entre o consumo e outras variáveis relacionadas as características do veículo.

any(is.na(n_df))
num_df <- n_df %>% select_if(is.numeric)
mod1 <- lm(ConsumoEnergiaMedio ~ .,data = num_df)
summary(mod1)

anova(mod1)
#Criando modelo de acordo com significancia estatistica utilizando a ANOVA no modelo de regressão linear 
mod2 <- lm(ConsumoEnergiaMedio ~ PrecoMin_PLN + PotenciaMotor_KM + TorqueMaximo_Nm + Autonomia_km + CapacidadeBateria_kWh + DistanciaEixos_cm + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod2)

#Criando modelo de acordo com a importancia imposta pelo random forest 
mod3 <- lm(ConsumoEnergiaMedio ~ DistanciaEixos_cm + PesoTotalPermitido_kg + PrecoMin_PLN + Comprimento_cm + PesoBruto_kg + PotenciaMotor_KM  ,data = num_df)
summary(mod3)

#Ao analisar o R-squared de ambos os modelos, percebe-se uma melhor performance do modelo 2 (criado a partir da significância estatística da ANOVA) do que o modelo 3 (Criado a partir do Random Forest).
#Criaremos mais alguns modelos, visando a generalização 

mod4 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh + DistanciaEixos_cm + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod4)

#Ao retirar variáveis como: Potência, torque e preço; Não se observou alteração significativa no R-squared do modelo. Retiraremos também a distância entre eixos e avaliaremos o modelo.

mod5 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh + Comprimento_cm +PesoTotalPermitido_kg ,data = num_df)
summary(mod5)

mod6 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh +PesoTotalPermitido_kg ,data = num_df)
summary(mod6)

#Foi selecionado o modelo 6 para avaliação devido sua performance com um número reduzido de variáveis preditoras, apresentando ser um modelo com maior generalização 

#Dividindo os dados em dados de teste e validação 

sub_dados <- sample.split(n_df$ConsumoEnergiaMedio, SplitRatio = 0.7)
dados_treino <- n_df[sub_dados,]
dados_teste <- n_df[!sub_dados,]

mod7 <- lm(ConsumoEnergiaMedio ~ Autonomia_km + CapacidadeBateria_kWh +PesoTotalPermitido_kg ,data = dados_treino)
summary(mod7)

previsao <- predict(mod7, newdata = dados_teste)
resultado <- data.frame(Real = dados_teste$ConsumoEnergiaMedio, Previsao = previsao)

#Calcule o Erro Médio Quadrático (MSE)
mse <- mean((resultado$Previsao - resultado$Real)^2)

# Calcule o Coeficiente de Determinação (R²)
r_squared <- cor(resultado$Previsao, resultado$Real)^2

#O modelo possui um MSE de 0.75 e R² de 0.95, ou seja, uma baixo MSE e um alto R² indicam que o modelo possuia uma baixa taxa de erro 
# e que as variáveis independentes (Autonomia, Capacidade da bateria e Peso total permitido) explicam 95% da variabilidade da variável dependente, 
# além de serem variáveis importantes para uma empresa de logistica, devido a necessidade de tranpostar cargas. Outras variáveis que podem ser inclusas 
# para uma melhor escolha da empresa, seriam as dimensões dos veículos, podendo escolher a melhor opção para transporte dos produtos. 

