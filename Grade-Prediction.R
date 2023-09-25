# Liner regression
# Problem definition: Predict student grades based on multiple metrics
# https://archive.ics.uci.edu/ml/datasets/Student+Performance
# Dataset with data of the students
# Let's predict the final grade of the students

# Loading dataset
df <- read.csv2('estudantes.csv')

# Exploring data 
head(df)
summary(df)
str(df)
any(is.na(df))

# install.packages("ggplot2")
# install.packages("ggthemes")
# install.packages("dplyr")
library(ggplot2)
library(ggthemes)
library(dplyr)

#Corverting and searching for the correlation of data 

any(is.character(df))
char <- sapply(df, is.character)
num <- sapply(df, is.numeric)
df[,char] <- lapply(df[,char], as.factor)
cor(df[,num])
corrplot(cor(df[,num]), method = "color")

#Creating test and study samples
set.seed(101)
sampl <- sample.split(df$age, SplitRatio = 0.7)
test <- filter(df, sampl == F)
study <- filter(df, sampl == T)
# Creating linear regression model to see the performance of the model
# For the currente problem, we want to predict the grade of the sudents based on multi variables,
#so we set "G3" as the dependent variable, and the rest of the variables on the data set as the independet variables

mod1 <- lm(G3 ~ ., data = study)

#We're gonna see how the model see the relationship between the varibles

summary(mod1)

#Based on the model, we see statistic significancy between G1, G2, absences and famrel. The model show us an R=squared of 0,83
# Let's create another model considering just the variables above and see if the performance increases or decreases 

mod2 <- lm(G3 ~ G1 + G2 + absences + famrel, data = study)

summary(mod2)

#lets test the created models utilizing data test 

prev1 <- predict(mod1, test)
prev2 <- predict(mod2, test)

#Visualizing the predicted values  

results1 <- data.frame(prev1, test$G3)
View(results1)
colnames(results1) <- c("Previsao","Real")
results2 <- data.frame(prev2, test$G3)
colnames(results2) <- c("Previsao","Real")
View(results2)

#As we see the results, some of the values were predicted as negative values, but
#for a grade, we can't accept that type of result, so we're gonna do a convertion of this type of data to zero

zeros <- function(x) {
  if (x < 0) {
    return(0)}
  else{
    return(x)
  }
}
results1$Previsao <- sapply(results1$Previsao, zeros)
View(results1)
results2$Previsao <- sapply(results2$Previsao, zeros)
View(results2)

#Calculating mean standard error 

mse1 <- mean((results1$Real - results1$Previsao)^2)
mse2 <- mean((results2$Real - results2$Previsao)^2)

# RMSE
rmse1 <- mse1^0.5
rmse2 <- mse2^0.5

# Calculating R Squared
SSE1 = sum((results1$Previsao - results1$Real)^2)
SST1 = sum((mean(df$G3) - results1$Real)^2)
SSE2 = sum((results2$Previsao - results2$Real)^2)
SST2 = sum((mean(df$G3) - results2$Real)^2)

R2_1 = 1 - (SSE1/SST1)
R2_2 = 1 - (SSE2/SST2)
R2_1 # 0.8563
R2_2 # 0.8622

#The chosen model was the model 2, that uses G1, G2, absenses and famrel to predict G3 
#instead of the model 1 that uses all variables in the main data set
