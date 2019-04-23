## IS590 Methods for Data Science
## To Build or Not To Build
## An Analysis of the Residential Building Dataset with Support Vector Machine
## 4/30/2018




### Packages Required
library('e1071')
library('readxl')
library('ROCR')



### import data from excel

# for PC
Residential_Building_Data_Set <- read_excel("C:/Users/rital/Google_Drive/IS_590MD/finalproject/Residential-Building-Data-Set.xlsx")
# for Mac
# Residential_Building_Data_Set <- read_excel("~/Google_Drive/IS_590MD/finalproject/Residential-Building-Data-Set.xlsx")

mydata = Residential_Building_Data_Set 



### Data Manipulation / Data Cleaning

# Check for null
sum( is.na(mydata) ) > 0

# Reset colomn names
colnames(mydata) = mydata[1,]
mydata = mydata[-1,]

names(mydata)

# We will exam only the first lag for this project
# Remove Lag 2 to Lag 5
mydata = mydata[, c(seq(5,31),108, 109)]
names(mydata)
mydata = apply(mydata, 2, as.numeric )
mydata = data.frame(mydata)
class(mydata)

# Explore the dataset
# Actual sales prices - Preliminary estimated construction cost based on the prices at the beginning of the project
mydata$V.10 - mydata$V.5
# Price of the unit at the beginning of the project per m2 - Preliminary estimated construction cost based on the prices at the beginning of the project
mydata$V.8 - mydata$V.5

##  Create Response

# Generate a new response based on the Actual sales prices (V.9) and the Actual construction costs(V.10)
# Response Profitability is a binary variable. 
# It has value of 1 if the the Actual construction costs is more than five times of the construction price;
# It has value of 0 if the the Actual construction costs is less than five times of the construction price.

profitability.5 = ifelse(mydata$V.9/mydata$V.10 >5, 'Y','N')
sum(profitability.5 == 'Y')
sum(profitability.5 == 'N')
mydata$prof = as.factor(profitability.5)
names(mydata)

# drop V.9 and V.10
mydata = mydata[ , !(names(mydata) %in% c('V.9', 'V.10'))]

# After cleaning
str(mydata)




## Support Vector Machine - non-linear kernel


set.seed(100)
train = sample(372, 200, replace = FALSE)
train = sort(train, decreasing = FALSE)


# ROC Curve
rocplot = function(pred, truth, ...){
  predob = prediction(pred, truth)
  perf = performance(predob,'tpr', 'fpr')
  plot(perf, ...)
}



## radial kernel


# use tune on training data set to find the best cost and gamma
tune.out = tune(svm, prof~., data = mydata[train, ], kernel ='radial',
                ranges = 
                  list(cost = c(0.1, 1, 10, 100, 1000),
                       gamma = c(0.5, 1, 2, 3, 4)),
                decision.values = TRUE)
summary(tune.out)

# the model with the lowest error
bestmod.radial = tune.out$best.model
summary(bestmod.radial)
bestmod.radial$index

par(mfrow =c(1,1))
# ROC curve - training data
fitted = attributes(predict(bestmod.radial, mydata[train, ], decision.values = TRUE))$decision.values
#rocplot(fitted, mydata[train, 'prof'], main = "Training Data - Radial Kernel of SVM")

# roc curve step by step

predob = prediction(fitted, mydata[train, 'prof'])
perf = performance(predob,'tpr', 'fpr')
plot(perf, main = "Training Data - Radial Kernel of SVM")





# predict on the test data with the best model
bestmod.rad.pred = predict(bestmod.radial, mydata[-train, ],  decision.values = TRUE)
table1 = table(predict = bestmod.rad.pred, truth = mydata[-train,]$prof )
table1

# accuracy rate
(table1[1,1] + table1[2,2])/sum(table1)
# percentage of obs that are misclassified by this svm
(table1[1,2] + table1[2,1])/sum(table1)

# ROC curve - test data
fitted = attributes(bestmod.rad.pred)$decision.values
#rocplot(fitted, mydata[-train, ], 
#        main = "Test Data - Radial Kernel of SVM", col = 'red')

predob = prediction(fitted, mydata[-train, 'prof'])
perf = performance(predob,'tpr', 'fpr')
plot(perf, main = 'Test Data - Radial Kernel of SVM', col = 'red')


## polynomial kernel 




# use tune on training data set to find the best cost and gamma
tune.out = tune(svm, prof~., data = mydata[train,], kernel = 'polynomial',
                ranges = 
                  list(degree =c(1, 2, 3, 4, 5), 
                       cost = c(0.1, 1, 10, 100, 1000)),
                decision.values = TRUE)
summary(tune.out)

# the model with the lowest error
bestmod.poly = tune.out$best.model
summary(bestmod.poly)
bestmod.poly$index

# ROC curve - training data
fitted = attributes(predict(bestmod.poly, mydata[train, ], decision.values = TRUE))$decision.values
#rocplot(fitted, mydata[train, "prof"], 
 #       main = "Training Data - Polynomial Kernel of SVM")

predob = prediction(fitted, mydata[train, 'prof'])
perf = performance(predob,'tpr', 'fpr')
plot(perf, main = 'Training Data - Polynomial Kernel of SVM')



# predict on the test data with the best model
bestmod.poly.pred = predict(bestmod.poly, mydata[-train,], decision.values = TRUE)
table2 = table(predict = bestmod.poly.pred, truth = mydata[-train,]$prof )
table2

# accuracy rate
(table2[1,1] + table2[2,2])/sum(table2)
# percentage of obs that are misclassified by this svm
(table2[1,2] + table2[2,1])/sum(table2)

# ROC curve - test data
fitted = attributes(bestmod.poly.pred)$decision.values
#rocplot(fitted, mydata[order(mydata$prof,decreasing = TRUE), ][-train, "prof"], 
#        main = "Test Data - Polynomial Kernel of SVM", col ='red')
predob = prediction(fitted, mydata[-train, 'prof'])
perf = performance(predob,'tpr', 'fpr')
plot(perf, main = 'Test Data - Polynomial Kernel of SVM', col = 'red')

