#This script downloads the datasets from 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip' 
#into a temp file, analyses the input and produces two tidy datasets: 
#tidy.txt: contains the cleaned raw data whereby the mean and standard deviation features are listed for each subject and activity. 
#tidy2.txt: contains the average of each feature per subject and activity. 

 
#The mean and standard deviation features are identified by those with mean() and -std() in their names. 
#Note: measures like meanfreq() are not considered to be relevant, and are ignored. 

 
#As we use melt and dcast, we need the reshape2 library. 
 if('reshape2' %in% installed.packages() == F){ 
   install.packages('reshape2') 
 } 
 library(reshape2) 
 
 
 
 
 #This is the exposed function, doing the heavy lifting. 
 run_analysis <- function(){ 
 
 
     #We first define some helper functions. 
      
     #This function downloads the data to a temp file, and returns the handle. 
     downloadData <- function(){ 
         fileName <- 'UCI HAR Dataset.zip' 
          
         if(!file.exists('UCI HAR Dataset.zip')){ 
             #download file. Try default method first. If that fails (e.g. for https and linux), try wget. 
             tryCatch( 
                 download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip', destfile=fileName) 
                 , error = function(e){ 
                     download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip', destfile=fileName, method='wget') 
                 } 
             ) 
         } 
          
         fileName 
     } 
      
     #This function loads the relevant data from the zip file into a list of frames.  
     #We avoid the need to extract the folder by using unz. 
     loadData <- function(file){ 
         x_train <- read.table(unz(file, 'UCI HAR Dataset/train/X_train.txt')) 
         x_test <- read.table(unz(file, 'UCI HAR Dataset/test/X_test.txt')) 
          
         y_train <- read.table(unz(file, 'UCI HAR Dataset/train/y_train.txt')) 
         y_test <- read.table(unz(file, 'UCI HAR Dataset/test/y_test.txt')) 
          
         subject_train <- read.table(unz(file, 'UCI HAR Dataset/train/subject_train.txt')) 
         subject_test <- read.table(unz(file, 'UCI HAR Dataset/test/subject_test.txt')) 
          
         features <- read.table(unz(file, "UCI HAR Dataset/features.txt"), header=F, colClasses="character") 
         activities <- read.table(unz(file, "UCI HAR Dataset/activity_labels.txt"), header=F, colClasses="character") 
              
         #return a list enabling easy access. 
         list(x_train = x_train, x_test = x_test,  
              y_train = y_train, y_test = y_test,  
              subject_train = subject_train, subject_test = subject_test, 
              features = features, 
              activities = activities) 
     } 
      
     #This return a list where the X, Y and S elements are got by appending the respective 'train' and 'test' frames from the input. 
     mergeData <- function(l) { 
         list(X = rbind(l$x_train, l$x_test), Y = rbind(l$y_train, l$y_test), S = rbind(l$subject_train, l$subject_test)) 
     } 
      
     #This function returns the input dataset with only the relevant features. 
     extract_mean_std_features = function(X, features) { 
         #only consider features with '-mean()' and '-std()' 
         target_features <- grep("-mean\\(\\)|-std\\(\\)", features[, 2]) 
         #filter out unwanted features 
         X <- X[, target_features] 
         #'prettify' column names 
         names(X) <- features[target_features, 2] 
         names(X) <- gsub("\\(|\\)", "", names(X)) 
         names(X) <- tolower(names(X)) 
         #return filtered frame 
         X 
     } 
      
     #This function replaces the activity indices with their textual names. 
     apply_activity_names <- function(x, activities){ 
         activities[, 2] <- gsub("_", "", tolower(activities[, 2])) 
         x[,1] <- activities[x[,1], 2] 
         names(x) <- "activity" 
         x 
     } 
 
 
     # Helper functions defined...processing steps: 
 
 
     #0: download and load data 
     f <- downloadData() 
     d <- loadData(f) 
      
     #1: merge into one dataset...Keeping X, Y, and S separate for now for easier column naming. Will merge later.  
     #   This is to maintain the sequence of steps outlined in the question. 
     m <- mergeData(d) 
      
     #done with the data sets, but not the features. 
     d <- d[-1:-6] 
      
     #2: Extract the mean and std featrures 
     m$X <- extract_mean_std_features(m$X, d$features) 
      
     #3: apply activity names 
     m$Y <- apply_activity_names(m$Y, d$activities) 
     
     #done with features and activities 
     d <- NULL 
      
     #4: This is likely a typo, as it seems to be like step 3. 
     #   These threads seem to suggest the same: https://class.coursera.org/getdata-002/forum/thread?thread_id=28#post-461  
     #   and https://class.coursera.org/getdata-002/forum/thread?thread_id=137 
     #    
     #   Here, I've merged the columns and output the clean dataset. 
      
     names(m$S) <- "subject" 
      
     #put the columns together to get the tidy data frame. 
     tidy <- cbind(m$S, m$Y, m$X) 
     #write out the csv file. A .txt extension is used to enable upload to the Coursera site. 
     write.csv(tidy, "tidy.txt", row.names=F) 
      
     #5: Create a second, independent tidy data set with the average of each variable for each activity and each subject 
      
     #melt the tidy data using the first two columns as id and the rest as values. 
     melted <- melt(tidy, 1:2) 
     #dcast the metlted data to get the average for each feature per subject per activity. 
     tidy2 <- dcast(melted, subject + activity ~ variable, mean) 
     write.csv(tidy2, "tidy2.txt", row.names=F) 
